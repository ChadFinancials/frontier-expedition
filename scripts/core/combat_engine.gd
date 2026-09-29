class_name CombatEngine
extends RefCounted
## Turn-based combat rules. No nodes, no drawing: every call returns a list of event
## dictionaries that the combat screen animates (and tests inspect).
##
## Driving loop:
##   engine.setup(...)
##   while not engine.is_over():
##       var ev = engine.step()              # runs one AI/automatic turn, or stops at a hero
##       if engine.awaiting_input(): ev = engine.hero_skill(...) / hero_swap(...) / hero_pass()

var rng: RandomNumberGenerator
var heroes: Array = []    # Combatant, index 0 = rank 1
var enemies: Array = []
var units: Dictionary = {}
var round_num: int = 0
var queue: Array = []
var current: Combatant = null
var state: String = "running"   # running, await, victory, defeat, fled, scripted
var in_cave: bool = false
var light: int = 100
var tier: int = 1
var boss_fight: bool = false
var surprise: String = ""       # "" / "heroes" (heroes were surprised) / "enemies"
var killed: Array = []          # enemy data ids slain
var fallen: Array = []          # hero uids who died
var story_script: Dictionary = {}     # scripted ending (a boss's first meeting); see _check_script
var _next_id: int = 1
var _fresh_dd: Array = []       # heroes knocked onto Death's Door by the move being resolved


func setup(party: Array, enemy_ids: Array, opts: Dictionary = {}) -> Array:
	rng = opts.get("rng", RandomNumberGenerator.new())
	in_cave = opts.get("in_cave", false)
	light = opts.get("light", 100)
	tier = opts.get("tier", 1)
	boss_fight = opts.get("boss", false)
	surprise = opts.get("surprise", "")
	story_script = opts.get("script", {})
	var wounded: Dictionary = opts.get("wounded", {})
	var ev: Array = []
	for h in party:
		if h.alive and heroes.size() < 4:
			var c := Combatant.from_hero(h, _new_id(), in_cave)
			heroes.append(c)
			units[c.id] = c
	for eid in enemy_ids:
		if enemies.size() < 4 and DB.enemies.has(eid):
			var c := Combatant.from_enemy(eid, _new_id(), tier, in_cave)
			if wounded.has(eid):
				c.hp = maxi(1, int(round(c.max_hp * int(wounded[eid]) / 100.0)))
			enemies.append(c)
			units[c.id] = c
	# Buffs from camp and trail ("for the next fight").
	var start_buffs: Dictionary = opts.get("start_buffs", {})
	for c in heroes:
		for b in start_buffs.get(c.hero.uid, []) + start_buffs.get(0, []):
			c.buffs.append({"stat": b.stat, "value": b.value, "rounds": 99, "name": b.get("name", "Camp")})
	if surprise == "heroes":
		heroes = Stats.shuffled(rng, heroes)
		ev.append({"t": "surprise", "who": "heroes"})
	elif surprise == "enemies":
		enemies = Stats.shuffled(rng, enemies)
		ev.append({"t": "surprise", "who": "enemies"})
	_reindex()
	ev.append({"t": "start"})
	return ev


func _new_id() -> int:
	_next_id += 1
	return _next_id


func is_over() -> bool:
	return state in ["victory", "defeat", "fled", "scripted"]


func awaiting_input() -> bool:
	return state == "await"


func side_of(c: Combatant) -> Array:
	return heroes if c.is_hero() else enemies


func foes_of(c: Combatant) -> Array:
	return enemies if c.is_hero() else heroes


func _reindex() -> void:
	for i in heroes.size():
		heroes[i].rank = i + 1
	for i in enemies.size():
		enemies[i].rank = i + 1


func unit(id: int) -> Combatant:
	return units.get(id, null)


# --- Turn flow ------------------------------------------------------------------------

func step() -> Array:
	var ev: Array = []
	if is_over() or state == "await":
		return ev
	while true:
		if queue.is_empty():
			ev.append_array(_start_round())
		current = queue.pop_front()
		if current == null or current.dead:
			continue
		break
	_check_script(ev)
	if is_over():
		return ev
	ev.append({"t": "turn", "actor": current.id})
	ev.append_array(_start_turn(current))
	_cleanup(ev)
	if is_over():
		return ev
	if current.dead:
		return ev
	if current.stunned:
		current.stunned = false
		current.stun_guard = 1
		ev.append({"t": "stun_skip", "actor": current.id})
		_end_turn(current, ev)
		return ev
	if current.is_hero():
		var acted := _maybe_act_out(current, ev)
		if acted:
			_end_turn(current, ev)
			return ev
		state = "await"
		return ev
	ev.append_array(_ai_turn(current))
	_end_turn(current, ev)
	return ev


func _start_round() -> Array:
	round_num += 1
	queue.clear()
	for c in heroes + enemies:
		if c.dead:
			continue
		c.initiative = int(c.stat("speed")) + rng.randi_range(1, 8)
		if round_num == 1:
			if surprise == "heroes" and not c.is_hero():
				c.initiative += 100
			elif surprise == "enemies" and c.is_hero():
				c.initiative += 100
		queue.append(c)
	queue.sort_custom(func(a, b): return a.initiative > b.initiative)
	var order: Array = []
	for c in queue:
		order.append(c.id)
	return [{"t": "round", "round": round_num, "order": order}]


func _start_turn(c: Combatant) -> Array:
	var ev: Array = []
	# Damage over time.
	var still: Array = []
	for d in c.dots:
		ev.append({"t": "dot", "target": c.id, "kind": d.kind, "amount": d.amount})
		_apply_damage(c, d.amount, null, ev, true)
		d.rounds -= 1
		if d.rounds > 0:
			still.append(d)
		if c.dead:
			break
	c.dots = still
	if c.dead:
		return ev
	# Second Wind boons.
	if c.hero != null and c.hero.is_second_wind():
		var st: Dictionary = DB.fatigue_states.get(c.hero.fatigue_state, {})
		for boon in st.get("turn_start", []):
			if rng.randf() * 100.0 < boon.get("chance", 30):
				ev.append_array(_apply_boon(c, boon))
	return ev


func _apply_boon(c: Combatant, boon: Dictionary) -> Array:
	var ev: Array = []
	var st_name: String = DB.fatigue_states.get(c.hero.fatigue_state, {}).get("name", "")
	match boon.get("type", ""):
		"heal_self_pct":
			var amt := int(ceil(c.max_hp * boon.value / 100.0))
			ev.append({"t": "boon", "actor": c.id, "text": "%s (%s): catches their breath" % [c.display_name, st_name]})
			_heal(c, c, amt, false, ev)
		"party_fatigue":
			ev.append({"t": "boon", "actor": c.id, "text": "%s (%s): \"We can do this!\"" % [c.display_name, st_name]})
			for a in heroes:
				ev.append_array(Fatigue.add(a.hero, int(boon.value), rng))
		"buff_ally":
			var ally: Combatant = Stats.pick(rng, heroes.filter(func(x): return x != c and not x.dead))
			if ally != null:
				ally.buffs.append({"stat": boon.stat, "value": boon.value, "rounds": 2, "name": st_name})
				ev.append({"t": "boon", "actor": c.id, "text": "%s (%s) rallies %s" % [c.display_name, st_name, ally.display_name]})
				ev.append({"t": "buff", "target": ally.id, "stat": boon.stat, "value": boon.value})
	return ev


## Breaking Point heroes sometimes take matters into their own hands.
func _maybe_act_out(c: Combatant, ev: Array) -> bool:
	if not c.hero.is_breaking():
		return false
	var st: Dictionary = DB.fatigue_states.get(c.hero.fatigue_state, {})
	if rng.randf() * 100.0 >= st.get("act_chance", DB.cfg("act_out_chance", 30)):
		return false
	var act: String = Stats.pick(rng, st.get("acts", ["pass"]))
	var lines: Array = st.get("barks", ["..."])
	var line: String = Stats.pick(rng, lines)
	match act:
		"bark":
			ev.append({"t": "act_out", "actor": c.id, "text": "%s: \"%s\"" % [c.display_name, line]})
			var others := heroes.filter(func(x): return x != c and not x.dead)
			var victim: Combatant = Stats.pick(rng, others)
			if victim != null:
				ev.append_array(Fatigue.add(victim.hero, rng.randi_range(5, 9), rng))
				_cleanup(ev)
			return false   # barking doesn't cost the turn
		"pass":
			ev.append({"t": "act_out", "actor": c.id, "text": "%s refuses to act: \"%s\"" % [c.display_name, line]})
			return true
		"move_back", "move_forward":
			var dir := -1 if act == "move_back" else 1
			ev.append({"t": "act_out", "actor": c.id, "text": "%s %s: \"%s\"" % [c.display_name, "backs away" if dir < 0 else "charges ahead", line]})
			_shift(c, dir, ev)
			return true
		"random_skill":
			var opts: Array = []
			for sid in c.skills:
				for t in valid_targets(c, sid):
					opts.append([sid, t])
			if opts.is_empty():
				return false
			var pick: Array = Stats.pick(rng, opts)
			ev.append({"t": "act_out", "actor": c.id, "text": "%s acts on impulse!" % c.display_name})
			ev.append_array(use_skill(c, pick[0], pick[1]))
			return true
	return false


func _end_turn(c: Combatant, ev: Array) -> void:
	if not c.dead:
		var kept: Array = []
		for b in c.buffs:
			if b.rounds >= 99:
				kept.append(b)
				continue
			# A buff the unit gave itself this turn starts counting from its next turn.
			if b.get("fresh", false):
				b.erase("fresh")
				kept.append(b)
				continue
			b.rounds -= 1
			if b.rounds > 0:
				kept.append(b)
		c.buffs = kept
		if c.stun_guard > 0 and not c.stunned:
			c.stun_guard -= 1
		if c.mark > 0:
			c.mark -= 1
		if c.taunt > 0:
			c.taunt -= 1
		if c.guard_rounds > 0:
			c.guard_rounds -= 1
			if c.guard_rounds == 0:
				_clear_guard(c)
	current = null
	if state == "await":
		state = "running"
	_cleanup(ev)


# --- Hero commands --------------------------------------------------------------------

func hero_skill(skill_id: String, target_id: int) -> Array:
	if state != "await":
		return []
	var c := current
	state = "running"
	var ev := use_skill(c, skill_id, target_id)
	_end_turn(c, ev)
	return ev


func hero_swap(direction: int) -> Array:
	if state != "await":
		return []
	var c := current
	state = "running"
	var ev: Array = [{"t": "swap", "actor": c.id}]
	_shift(c, direction, ev)
	_end_turn(c, ev)
	return ev


func hero_pass() -> Array:
	if state != "await":
		return []
	var c := current
	state = "running"
	var ev: Array = [{"t": "pass", "actor": c.id}]
	_end_turn(c, ev)
	return ev


## Dev tool: every enemy drops dead on the spot and the fight is won.
func dev_win() -> Array:
	var ev: Array = []
	for c in enemies:
		if not c.dead:
			c.hp = 0
			c.dead = true
			killed.append(c.data.get("id", ""))
			ev.append({"t": "death", "target": c.id})
	if state == "await":
		state = "running"
	current = null
	_cleanup(ev)
	return ev


func can_retreat() -> bool:
	return not boss_fight


func retreat(rng_override: RandomNumberGenerator = null) -> Array:
	var r := rng_override if rng_override != null else rng
	var ev: Array = [{"t": "retreat"}]
	for c in heroes:
		ev.append_array(Fatigue.add(c.hero, DB.cfg("retreat_fatigue", 12), r))
	state = "fled"
	_cleanup(ev)
	if heroes.is_empty():
		state = "defeat"
	else:
		state = "fled"
	ev.append({"t": "end", "result": state})
	return ev


# --- Skills ---------------------------------------------------------------------------

func is_hostile(sk: Dictionary) -> bool:
	return sk.get("target", "enemy") == "enemy"


func can_use_from_rank(c: Combatant, sid: String) -> bool:
	return c.rank in DB.skill(sid).get("use_ranks", [1, 2, 3, 4])


## Ids of units that the skill may be aimed at (clicking any of them).
func valid_targets(c: Combatant, sid: String) -> Array:
	var sk := DB.skill(sid)
	if sk.is_empty() or not can_use_from_rank(c, sid):
		return []
	var out: Array = []
	match sk.get("target", "enemy"):
		"enemy":
			var ranks: Array = sk.get("target_ranks", [1, 2, 3, 4])
			var pool := foes_of(c).filter(func(x): return not x.dead and x.rank in ranks)
			if not sk.get("aoe", false) and sk.get("random_hits", 0) == 0:
				var taunters := pool.filter(func(x): return x.taunt > 0)
				if not taunters.is_empty():
					pool = taunters
			for x in pool:
				out.append(x.id)
		"ally":
			var ranks: Array = sk.get("target_ranks", [1, 2, 3, 4])
			for x in side_of(c):
				if x.dead or not (x.rank in ranks):
					continue
				if sk.get("no_self", false) and x == c:
					continue
				out.append(x.id)
		"self", "party":
			out.append(c.id)
	# Summons need room.
	for e in sk.get("self_effects", []):
		if e.get("type", "") == "summon" and side_of(c).size() >= 4:
			return []
	return out


func usable_skills(c: Combatant) -> Array:
	var out: Array = []
	for sid in c.skills:
		if DB.skill(sid).get("ai", {}).get("once", false) and sid in c.used_skills:
			continue
		if not valid_targets(c, sid).is_empty():
			out.append(sid)
	return out


func hit_chance(a: Combatant, sid: String, t: Combatant) -> int:
	var sk := DB.skill(sid)
	if not is_hostile(sk):
		return 100
	var acc := float(sk.get("acc", 85)) + a.stat("acc", t)
	acc += DB.cfg("skill_level_acc", 4) * (a.skill_level(sid) - 1)
	var dodge := t.stat("dodge", a)
	return clampi(int(round(acc - dodge)), 5, 95)


func crit_chance(a: Combatant, sid: String, t: Combatant) -> int:
	var sk := DB.skill(sid)
	if sk.get("no_damage", false) and is_hostile(sk):
		return 0
	var cr := a.stat("crit", t) + float(sk.get("crit", 0))
	if in_cave and a.is_hero():
		cr += _light_row().get("hero_crit", 0)
	return clampi(int(round(cr)), 0, 100)


func _light_row() -> Dictionary:
	var rows: Array = DB.cfg("light_levels", [])
	for r in rows:
		if light >= r.get("min", 0):
			return r
	return {}


func dmg_mult(a: Combatant, sid: String, t: Combatant) -> float:
	var sk := DB.skill(sid)
	var m := 1.0 + float(sk.get("dmg", 0.0))
	m += DB.cfg("skill_level_dmg_pct", 8) / 100.0 * (a.skill_level(sid) - 1)
	m += a.stat("dmg_pct", t) / 100.0
	if t != null and t.mark > 0:
		m += float(sk.get("vs_marked", 0.0))
	if a.hp_ratio() < 0.5:
		m += float(sk.get("low_hp_bonus", 0.0))
	if t != null:
		var vt: Dictionary = sk.get("vs_tags", {})
		for tag in vt:
			if tag in t.tags:
				m += float(vt[tag])
	if in_cave and not a.is_hero():
		m += _light_row().get("enemy_dmg", 0) / 100.0
	return maxf(0.0, m)


## [min, max] damage before a crit, after protection. Empty for non-damaging skills.
func dmg_preview(a: Combatant, sid: String, t: Combatant) -> Array:
	var sk := DB.skill(sid)
	if sk.get("no_damage", false) or not is_hostile(sk):
		return []
	var r := skill_dmg_range(a, sid)
	var m := dmg_mult(a, sid, t)
	var flat := a.stat("dmg_flat", t)
	var prot := maxf(0.0, t.stat("prot", a) - a.stat("pierce", t)) / 100.0
	return [maxi(1, int(round(maxf(0.0, r[0] * m + flat) * (1.0 - prot)))), maxi(1, int(round(maxf(0.0, r[1] * m + flat) * (1.0 - prot))))]


## Base damage for a move. A move may set "dmg_range": [lo, hi], its damage as written at
## tier 1 / starting gear (enemy tiers scale it; hero weapons and skill levels add their
## usual bonuses on top); otherwise it uses the attacker's own range.
func skill_dmg_range(a: Combatant, sid: String) -> Array:
	var d: Array = DB.skill(sid).get("dmg_range", [])
	if d.size() < 2:
		return a.dmg_range()
	var mult: float = 1.0 if a.boss or a.is_hero() else 1.0 + DB.cfg("tier_dmg_pct", 30) / 100.0 * (a.tier - 1)
	return [maxi(1, int(round(d[0] * mult))), maxi(1, int(round(d[1] * mult)))]


func effect_chance(a: Combatant, sid: String, e: Dictionary, t: Combatant) -> int:
	var kind: String = e.get("type", "")
	var base := float(e.get("chance", 100))
	if a.is_hero():
		base += DB.cfg("skill_level_effect", 6) * (a.skill_level(sid) - 1)
	else:
		base += DB.cfg("tier_effect", 5) * (a.tier - 1)
	var res_stat := ""
	match kind:
		"stun":
			res_stat = "stun_res"
		"bleed":
			res_stat = "bleed_res"
		"poison":
			res_stat = "poison_res"
		"knockback", "pull":
			res_stat = "move_res"
		"debuff":
			res_stat = "debuff_res"
	if res_stat == "" or t.side == a.side:
		return clampi(int(base), 0, 100)
	return clampi(int(round(base - t.stat(res_stat, a))), 0, 95)


## Run a skill. target_id is the clicked unit (for AoE any valid id).
func use_skill(a: Combatant, sid: String, target_id: int) -> Array:
	var sk := DB.skill(sid)
	var ev: Array = []
	_fresh_dd.clear()
	var valid := valid_targets(a, sid)
	if valid.is_empty():
		ev.append({"t": "pass", "actor": a.id})
		return ev
	if not target_id in valid:
		target_id = valid[0]
	var targets: Array = []
	var tkind: String = sk.get("target", "enemy")
	if tkind == "party":
		targets = side_of(a).filter(func(x): return not x.dead)
	elif sk.get("aoe", false):
		for id in valid:
			targets.append(unit(id))
	elif sk.get("random_hits", 0) > 0:
		for i in int(sk.random_hits):
			targets.append(unit(Stats.pick(rng, valid)))
	else:
		var t := unit(target_id)
		for i in int(sk.get("hits", 1)):
			targets.append(t)
	# Guard: single-target attacks on a guarded unit hit the guardian instead.
	if is_hostile(sk) and not sk.get("aoe", false):
		for i in targets.size():
			var t: Combatant = targets[i]
			if t.guarded_by >= 0:
				var g := unit(t.guarded_by)
				if g != null and not g.dead:
					targets[i] = g
	var ids: Array = []
	for t in targets:
		if not t.id in ids:
			ids.append(t.id)
	a.used_skills.append(sid)
	ev.append({"t": "action", "actor": a.id, "skill": sid, "targets": ids, "anim": sk.get("anim", "melee"),
		"sfx": sk.get("sfx", ""), "hostile": is_hostile(sk)})

	var crit_any := false
	for t in targets:
		if t.dead:
			continue
		if is_hostile(sk):
			crit_any = _resolve_attack(a, sid, sk, t, ev) or crit_any
		else:
			_resolve_support(a, sid, sk, t, ev)
	for e in sk.get("self_effects", []):
		_apply_self_effect(a, sid, e, ev)
	# Fatigue from crits.
	if crit_any and a.is_hero():
		ev.append({"t": "crit_relief", "actor": a.id})
		ev.append_array(Fatigue.add(a.hero, -DB.cfg("crit_relief_self", 4), rng))
		for h in heroes:
			if h != a:
				ev.append_array(Fatigue.add(h.hero, -DB.cfg("crit_relief_party", 2), rng))
	_cleanup(ev)
	return ev


## Returns true on a crit.
func _resolve_attack(a: Combatant, sid: String, sk: Dictionary, t: Combatant, ev: Array) -> bool:
	var chance := hit_chance(a, sid, t)
	if rng.randi_range(1, 100) > chance:
		ev.append({"t": "miss", "actor": a.id, "target": t.id})
		return false
	var crit := false
	if not sk.get("no_damage", false):
		crit = rng.randi_range(1, 100) <= crit_chance(a, sid, t)
		var r := skill_dmg_range(a, sid)
		var dmg := float(rng.randi_range(r[0], r[1])) * dmg_mult(a, sid, t)
		dmg = maxf(0.0, dmg + a.stat("dmg_flat", t))
		var gamble_text := ""
		if sk.get("gamble", false):
			if rng.randf() < 0.5:
				dmg *= 2.0
				gamble_text = "DOUBLE!"
			else:
				dmg *= 0.25
				gamble_text = "Bust..."
		if crit:
			dmg *= DB.cfg("crit_mult", 1.5)
		dmg *= 1.0 - maxf(0.0, t.stat("prot", a) - a.stat("pierce", t)) / 100.0
		var amount := maxi(1, int(round(dmg)))
		ev.append({"t": "hit", "actor": a.id, "target": t.id, "amount": amount, "crit": crit, "note": gamble_text})
		_apply_damage(t, amount, a, ev, false)
		if crit and t.is_hero() and not t.dead:
			ev.append_array(Fatigue.add(t.hero, DB.cfg("crit_taken_fatigue", 8), rng, {"tags": a.tags}))
	else:
		ev.append({"t": "hit", "actor": a.id, "target": t.id, "amount": 0, "crit": false, "note": ""})
	if t.dead:
		return crit
	for e in sk.get("effects", []):
		_apply_effect(a, sid, e, t, ev, crit)
	return crit


func _resolve_support(a: Combatant, sid: String, sk: Dictionary, t: Combatant, ev: Array) -> void:
	# Paranoid heroes and the like may refuse help from others.
	if t != a and t.hero != null and t.hero.is_breaking():
		var st: Dictionary = DB.fatigue_states.get(t.hero.fatigue_state, {})
		if st.get("refuses_help", false) and rng.randf() < 0.5:
			ev.append({"t": "refuse", "target": t.id, "text": "%s: \"Keep your hands off me!\"" % t.display_name})
			return
	for e in sk.get("effects", []):
		_apply_effect(a, sid, e, t, ev, false)


func _apply_effect(a: Combatant, sid: String, e: Dictionary, t: Combatant, ev: Array, crit: bool) -> void:
	var kind: String = e.get("type", "")
	var lvl := a.skill_level(sid)
	match kind:
		"bleed", "poison":
			if _roll_effect(a, sid, e, t, ev):
				var amt := float(e.get("amount", 2))
				if a.is_hero():
					amt *= 1.0 + DB.cfg("skill_level_dot_pct", 15) / 100.0 * (lvl - 1)
				elif not a.boss:
					amt *= 1.0 + DB.cfg("tier_dmg_pct", 30) / 100.0 * (a.tier - 1)
				if crit:
					amt *= 1.5
				t.dots.append({"kind": kind, "amount": maxi(1, int(round(amt))), "rounds": e.get("rounds", 3)})
				ev.append({"t": "status", "target": t.id, "status": kind})
		"stun":
			if _roll_effect(a, sid, e, t, ev):
				t.stunned = true
				ev.append({"t": "status", "target": t.id, "status": "stun"})
		"mark":
			t.mark = maxi(t.mark, int(e.get("rounds", 3)))
			ev.append({"t": "status", "target": t.id, "status": "mark"})
		"debuff":
			if _roll_effect(a, sid, e, t, ev):
				t.buffs.append({"stat": e.stat, "value": e.value, "rounds": e.get("rounds", 3), "name": DB.skill(sid).get("name", ""), "fresh": t == a})
				ev.append({"t": "debuff", "target": t.id, "stat": e.stat, "value": e.value})
		"buff":
			var v: float = e.value
			if a.is_hero() and lvl > 1:
				v *= 1.0 + 0.1 * (lvl - 1)
			t.buffs.append({"stat": e.stat, "value": int(round(v)), "rounds": e.get("rounds", 3), "name": DB.skill(sid).get("name", ""), "fresh": t == a})
			ev.append({"t": "buff", "target": t.id, "stat": e.stat, "value": int(round(v))})
		"random_buff":
			var pool: Array = e.get("pool", [])
			var b: Dictionary = Stats.pick(rng, pool)
			if b != null:
				t.buffs.append({"stat": b.stat, "value": b.value, "rounds": e.get("rounds", 3), "name": DB.skill(sid).get("name", "")})
				ev.append({"t": "buff", "target": t.id, "stat": b.stat, "value": b.value})
		"heal":
			var hmin := float(e.get("min", 3))
			var hmax := float(e.get("max", 6))
			var amt := float(rng.randi_range(int(hmin), int(hmax))) * float(DB.cfg("heal_mult", 1.0))
			amt *= 1.0 + DB.cfg("skill_level_heal_pct", 15) / 100.0 * (lvl - 1)
			var hcrit := a.is_hero() and rng.randi_range(1, 100) <= int(a.stat("crit"))
			if hcrit:
				amt *= 1.5
			_heal(a, t, int(round(amt)), hcrit, ev)
		"heal_pct":
			_heal(a, t, int(ceil(t.max_hp * float(e.get("value", 10)) / 100.0)), false, ev)
		"fatigue":
			if t.hero != null:
				var fa = e.get("amount", 5)
				var amt: int = rng.randi_range(int(fa[0]), int(fa[1])) if fa is Array else int(fa)
				if amt > 0 and not a.is_hero() and not a.boss:
					amt = int(round(amt * (1.0 + 0.2 * (a.tier - 1))))
				if crit and amt > 0:
					amt = int(round(amt * 1.5))
				if amt < 0 and a.is_hero():
					amt = int(round(amt * (1.0 + 0.15 * (lvl - 1))))
				ev.append_array(Fatigue.add(t.hero, amt, rng, {"tags": a.tags}))
		"knockback", "pull":
			if _roll_effect(a, sid, e, t, ev):
				var n := int(e.get("amount", 1))
				_shift(t, -n if kind == "knockback" else n, ev)
		"guard":
			if t != a:
				_clear_guard(a)
				if t.guarded_by >= 0:
					var old := unit(t.guarded_by)
					if old != null:
						old.guarding = -1
				a.guarding = t.id
				a.guard_rounds = int(e.get("rounds", 2))
				t.guarded_by = a.id
				ev.append({"t": "status", "target": t.id, "status": "guard", "by": a.id})
		"taunt":
			t.taunt = maxi(t.taunt, int(e.get("rounds", 2)))
			ev.append({"t": "status", "target": t.id, "status": "taunt"})
		"cure":
			var kinds: Array = e.get("kinds", ["bleed", "poison"])
			t.dots = t.dots.filter(func(d): return not d.kind in kinds)
			if "stun" in kinds:
				t.stunned = false
			if "debuff" in kinds:
				t.buffs = t.buffs.filter(func(b): return float(b.value) >= 0.0)
			ev.append({"t": "cure", "target": t.id})
		"clear_shaken":
			if t.hero != null and t.hero.shaken:
				t.hero.shaken = false
				ev.append({"t": "cure", "target": t.id})
		"clear_mark":
			t.mark = 0


func _roll_effect(a: Combatant, sid: String, e: Dictionary, t: Combatant, ev: Array) -> bool:
	var ch := effect_chance(a, sid, e, t)
	if rng.randi_range(1, 100) <= ch:
		return true
	ev.append({"t": "resist", "target": t.id, "status": e.get("type", "")})
	return false


func _apply_self_effect(a: Combatant, sid: String, e: Dictionary, ev: Array) -> void:
	if a.dead:
		return
	match e.get("type", ""):
		"move":
			_shift(a, int(e.get("amount", 1)), ev)
		"buff_kin":
			# Buffs the user's living allies of the same kind (not itself). Refreshes unless "stack".
			var bname: String = DB.skill(sid).get("name", "")
			for o in side_of(a):
				if o == a or o.dead or o.enemy_id != a.enemy_id:
					continue
				if not e.get("stack", false):
					o.buffs = o.buffs.filter(func(b): return b.get("name", "") != bname)
				for m in e.get("mods", []):
					o.buffs.append({"stat": m.stat, "value": m.value, "rounds": e.get("rounds", 2), "name": bname})
					ev.append({"t": "buff", "target": o.id, "stat": m.stat, "value": m.value})
		"summon":
			for i in int(e.get("count", 1)):
				if side_of(a).size() >= 4:
					break
				var c := Combatant.from_enemy(e.enemy, _new_id(), a.tier if not a.boss else tier, in_cave)
				enemies.append(c)
				units[c.id] = c
				_reindex()
				ev.append({"t": "summon", "actor": a.id, "unit": c.id})
		"heal_self_pct":
			_heal(a, a, int(ceil(a.max_hp * float(e.get("value", 10)) / 100.0)), false, ev)
		"heal_self":
			_heal(a, a, int(e.get("amount", 5)), false, ev)
		"self_damage":
			# Blood price: hurts, but never below 1 HP.
			var sd := mini(int(e.get("amount", 4)), a.hp - 1)
			if sd > 0:
				a.set_hp(a.hp - sd)
				ev.append({"t": "hit", "actor": a.id, "target": a.id, "amount": sd, "crit": false, "note": ""})
		"light":
			if in_cave:
				light = clampi(light + int(e.get("amount", 10)), 0, 100)
				ev.append({"t": "light", "amount": int(e.get("amount", 10)), "light": light})
		_:
			_apply_effect(a, sid, e, a, ev, false)


func _heal(a: Combatant, t: Combatant, amount: int, crit: bool, ev: Array) -> void:
	if t.dead:
		return
	var amt := amount
	if t.hero != null:
		amt = int(round(amt * (1.0 + t.hero.stat("heal_pct") / 100.0)))
	amt = maxi(0, amt)
	var before := t.hp
	t.set_hp(t.hp + amt)
	ev.append({"t": "heal", "actor": a.id, "target": t.id, "amount": t.hp - before, "crit": crit})
	if t.hero != null and t.hero.deaths_door and t.hp > 0:
		t.hero.deaths_door = false
		t.hero.shaken = true
		ev.append({"t": "revived", "target": t.id})


func _apply_damage(t: Combatant, amount: int, source: Combatant, ev: Array, is_dot: bool) -> void:
	if t.dead or amount <= 0:
		return
	if t.hero == null:
		t.set_hp(t.hp - amount)
		if t.hp <= 0:
			t.dead = true
			killed.append(t.data.get("id", ""))
			ev.append({"t": "death", "target": t.id})
		return
	# Heroes: Death's Door. The hit that knocks a hero onto it never kills, and neither do
	# the rest of that same move's hits (a multi-shot volley): the next move rolls Deathblow.
	if t.hero.deaths_door and t.id in _fresh_dd and not is_dot:
		return
	if t.hero.deaths_door:
		var resist := t.hero.stat("deathblow")
		if rng.randf() * 100.0 < resist:
			ev.append({"t": "deathblow_resist", "target": t.id, "chance": int(resist)})
		else:
			t.dead = true
			t.hero.alive = false
			t.hero.hp = 0
			var cause := "Bled out" if is_dot else ("Slain by %s" % source.display_name if source != null else "Fell in battle")
			t.hero.death_note = cause
			ev.append({"t": "death", "target": t.id, "deathblow": true})
		return
	t.set_hp(t.hp - amount)
	if t.hp <= 0:
		t.hero.deaths_door = true
		_fresh_dd.append(t.id)
		ev.append({"t": "deaths_door", "target": t.id})
		for h in heroes:
			if h != t and not h.dead:
				ev.append_array(Fatigue.add(h.hero, DB.cfg("ally_deaths_door_fatigue", 6), rng))


## Move a unit forward (+) or back (-) within its line, swapping with neighbours.
func _shift(c: Combatant, amount: int, ev: Array) -> void:
	var line := side_of(c)
	var idx := line.find(c)
	if idx < 0:
		return
	var target_idx := clampi(idx - amount, 0, line.size() - 1)
	if target_idx == idx:
		return
	line.remove_at(idx)
	line.insert(target_idx, c)
	_reindex()
	ev.append({"t": "moved", "target": c.id, "rank": c.rank})


func _clear_guard(g: Combatant) -> void:
	if g.guarding >= 0:
		var t := unit(g.guarding)
		if t != null and t.guarded_by == g.id:
			t.guarded_by = -1
	g.guarding = -1
	g.guard_rounds = 0


## Remove the dead from the lines, clear stale links, check for the end of battle.
func _cleanup(ev: Array) -> void:
	# Heroes killed by fatigue collapse outside of damage.
	for h in heroes:
		if not h.dead and not h.hero.alive:
			h.dead = true
			if not ev.any(func(e): return e.get("t", "") == "death" and e.get("target", -1) == h.id):
				ev.append({"t": "death", "target": h.id})
	var dead_heroes := heroes.filter(func(x): return x.dead)
	var changed := not dead_heroes.is_empty() or enemies.any(func(x): return x.dead)
	for h in dead_heroes:
		heroes.erase(h)
		fallen.append(h.hero.uid)
		for o in heroes:
			ev.append_array(Fatigue.add(o.hero, DB.cfg("ally_death_fatigue", 15), rng))
	enemies = enemies.filter(func(x): return not x.dead)
	if changed:
		for c in heroes + enemies:
			if c.guarding >= 0 and (unit(c.guarding) == null or unit(c.guarding).dead):
				_clear_guard(c)
			if c.guarded_by >= 0 and (unit(c.guarded_by) == null or unit(c.guarded_by).dead):
				c.guarded_by = -1
		_reindex()
		ev.append({"t": "positions"})
		# Fatigue added above may have killed more heroes.
		if heroes.any(func(x): return not x.hero.alive):
			_cleanup(ev)
			return
	if is_over():
		return
	if heroes.is_empty():
		state = "defeat"
		ev.append({"t": "end", "result": "defeat"})
	elif enemies.is_empty():
		state = "victory"
		ev.append({"t": "end", "result": "victory"})
	else:
		_check_script(ev)


## A scripted ending: once its trigger is met (a round is reached, a hero is at Death's
## Door, or the named enemy is worn down) the fight stops and the story takes over.
func _check_script(ev: Array) -> void:
	if story_script.is_empty() or is_over():
		return
	var fire := round_num >= int(story_script.get("round", 999))
	if story_script.get("deaths_door", false) and heroes.any(func(x): return x.hero.deaths_door):
		fire = true
	for c in enemies:
		if c.data.get("id", "") == story_script.get("unit", "") and c.hp * 100 < c.max_hp * int(story_script.get("hp_pct", 0)):
			fire = true
	if fire:
		state = "scripted"
		ev.append({"t": "scripted", "id": story_script.id})
		ev.append({"t": "end", "result": "scripted"})


# --- Enemy AI -------------------------------------------------------------------------

func _ai_turn(c: Combatant) -> Array:
	var usable := usable_skills(c)
	if usable.is_empty():
		return _ai_out_of_position(c)
	var entries: Array = []
	for sid in usable:
		var ai: Dictionary = DB.skill(sid).get("ai", {})
		# An opener is always the unit's first move, if it can use it then.
		if ai.get("opener", false) and c.used_skills.is_empty():
			entries = [{"id": sid, "weight": 1}]
			break
		var wt: float = ai.get("weight", 1)
		if ai.has("low_hp_weight") and c.hp_ratio() < float(ai.get("low_hp", 0.5)):
			wt = ai.low_hp_weight
		entries.append({"id": sid, "weight": wt})
	var sid: String = Stats.pick_weighted(rng, entries).id
	var targets := valid_targets(c, sid)
	var ai: Dictionary = DB.skill(sid).get("ai", {})
	var target_id: int = _pick_target(targets, ai.get("pref", "random"), int(ai.get("pref_chance", -1)))
	return use_skill(c, sid, target_id)


## No move works from here: step to the nearest rank that has one, else a generic swing.
func _ai_out_of_position(c: Combatant) -> Array:
	var here := c.rank
	var best := 0
	for r in range(1, side_of(c).size() + 1):
		if r == here or (best != 0 and absi(r - here) >= absi(best - here)):
			continue
		c.rank = r
		if not usable_skills(c).is_empty():
			best = r
	c.rank = here
	if best != 0:
		var ev: Array = [{"t": "swap", "actor": c.id}]
		_shift(c, here - best, ev)
		return ev
	var fb: String = DB.cfg("enemy_fallback_skill", "e_fallback_swing")
	var fb_targets := valid_targets(c, fb)
	if not fb_targets.is_empty():
		return use_skill(c, fb, _pick_target(fb_targets, "random"))
	return [{"t": "pass", "actor": c.id}]


## chance: how often the preference wins, in percent (-1 = the preference's default).
func _pick_target(ids: Array, pref: String, chance: int = -1) -> int:
	var units_list: Array = []
	for id in ids:
		units_list.append(unit(id))
	match pref:
		"lowest_hp":
			units_list.sort_custom(func(a, b): return a.hp_ratio() < b.hp_ratio())
			if rng.randf() * 100.0 < (75 if chance < 0 else chance):
				return units_list[0].id
		"marked":
			var marked := units_list.filter(func(x): return x.mark > 0)
			if not marked.is_empty():
				return Stats.pick(rng, marked).id
		"back":
			units_list.sort_custom(func(a, b): return a.rank > b.rank)
			if rng.randf() * 100.0 < (70 if chance < 0 else chance):
				return units_list[0].id
		"front":
			units_list.sort_custom(func(a, b): return a.rank < b.rank)
			if rng.randf() * 100.0 < (70 if chance < 0 else chance):
				return units_list[0].id
		"deaths_door":
			var dd := units_list.filter(func(x): return x.deaths_door())
			if not dd.is_empty() and rng.randf() * 100.0 < (60 if chance < 0 else chance):
				return Stats.pick(rng, dd).id
	return Stats.pick(rng, units_list).id
