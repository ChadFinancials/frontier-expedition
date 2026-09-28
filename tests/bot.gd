class_name Bot
extends RefCounted
## A simple automatic player used by tests and balance simulations. It plays through the
## same rules layer the UI uses (Company, RunState, CombatEngine) with no nodes involved.

var rng := RandomNumberGenerator.new()
var cautious := false
var stats := {"fights": 0, "wins": 0, "losses": 0, "fled": 0, "rounds": 0, "max_rounds": 0, "deaths": 0,
	"events": 0, "curios": 0, "camps": 0, "caves": 0, "errors": []}


func _init(seed_value: int = 1) -> void:
	rng.seed = seed_value


# --- Combat ---------------------------------------------------------------------------

## Fight a battle to the end. Returns the engine.
func fight(party: Array, enemies: Array, opts: Dictionary) -> CombatEngine:
	var e := CombatEngine.new()
	e.setup(party, enemies, opts)
	var guard := 0
	while not e.is_over():
		guard += 1
		if guard > 2000:
			stats.errors.append("combat did not finish: %s" % [enemies])
			break
		e.step()
		if e.awaiting_input():
			hero_turn(e)
	stats.fights += 1
	stats.rounds += e.round_num
	stats.max_rounds = maxi(stats.max_rounds, e.round_num)
	match e.state:
		"victory":
			stats.wins += 1
		"defeat":
			stats.losses += 1
		"fled":
			stats.fled += 1
	stats.deaths += e.fallen.size()
	return e


func hero_turn(e: CombatEngine) -> void:
	var c: Combatant = e.current
	var usable := e.usable_skills(c)
	# Heal someone badly hurt.
	var hurt: Combatant = null
	for h in e.heroes:
		if h.hp_ratio() < 0.4 and (hurt == null or h.hp_ratio() < hurt.hp_ratio()):
			hurt = h
	if hurt != null:
		for sid in usable:
			var sk := DB.skill(sid)
			if sk.get("target", "") in ["ally", "party"] and sk.get("effects", []).any(func(x): return x.type == "heal"):
				var t := e.valid_targets(c, sid)
				e.hero_skill(sid, hurt.id if hurt.id in t else t[0])
				return
	var attacks := usable.filter(func(s): return e.is_hostile(DB.skill(s)))
	if not attacks.is_empty() and rng.randf() < 0.85:
		var sid: String = Stats.pick(rng, attacks)
		var targets := e.valid_targets(c, sid)
		var best: int = targets[0]
		for t in targets:
			if e.unit(t).hp < e.unit(best).hp:
				best = t
		e.hero_skill(sid, best)
		return
	if not usable.is_empty():
		var sid2: String = Stats.pick(rng, usable)
		e.hero_skill(sid2, Stats.pick(rng, e.valid_targets(c, sid2)))
		return
	# Nothing usable from here: shuffle toward the class's preferred ranks.
	var pref: Array = c.data.get("ranks", [1, 2, 3, 4])
	if c.rank < pref.min() :
		e.hero_swap(-1)
	elif c.rank > pref.max():
		e.hero_swap(1)
	else:
		e.hero_pass()


# --- Expedition -----------------------------------------------------------------------

## Plays one full expedition from settlement i. Returns the finish summary.
func play_expedition(co: Company, i: int) -> Dictionary:
	var avail := co.heroes_at(i).filter(func(h): return h.available())
	avail.sort_custom(func(a, b): return a.hp > b.hp)
	# Order by preferred rank so the formation makes sense.
	var party := avail.slice(0, 4)
	party.sort_custom(func(a, b): return a.cls().get("ranks", [2]).min() < b.cls().get("ranks", [2]).min())
	var uids: Array = []
	for h in party:
		uids.append(h.uid)
	var supplies := {"food": 20, "bandages": 2, "lamp_oil": 3, "wagon_parts": 1, "shovel": 1, "crowbar": 1, "salt": 1}
	while co.supply_cost(i, supplies) > co.money and supplies.food > 0:
		supplies.food = maxi(0, supplies.food - 2)
		for k in ["salt", "crowbar", "shovel", "wagon_parts", "lamp_oil", "bandages"]:
			if co.supply_cost(i, supplies) > co.money:
				supplies.erase(k)
	var r := co.start_run(i, uids, supplies)
	if r == null:
		return {"status": "no_run", "reason": co.can_embark(i, uids, supplies)}
	var guard := 0
	while r.status == "active":
		guard += 1
		if guard > 200:
			stats.errors.append("expedition stuck")
			break
		if r.party_heroes().is_empty():
			r.status = "defeat"
			break
		# Patch up the wounded between stops.
		for h in r.party_heroes():
			if h.hp < h.max_hp() * 0.35 and r.can_use_item("bandages"):
				r.use_item("bandages", h)
		var nxt: Array = r.choices()
		if nxt.is_empty():
			r.status = "victory" if r.boss_won else "abandoned"
			break
		# A prudent player turns back when battered, and only takes on a boss when fresh.
		if cautious:
			var hs := r.party_heroes()
			var hp_ratio := 0.0
			for h in hs:
				hp_ratio += float(h.hp) / h.max_hp()
			hp_ratio /= maxf(1, hs.size())
			var dd := hs.filter(func(h): return h.deaths_door or h.hp <= 0).size()
			var lvl := 0.0
			for h in hs:
				lvl += h.level
			lvl /= maxf(1, hs.size())
			var boss_next := nxt.any(func(id): return r.node(id).type == "boss")
			if dd >= 2 or hp_ratio < 0.35 or hs.size() <= 2 or (boss_next and (hp_ratio < 0.65 or lvl < r.tier() * 1.4)):
				r.status = "abandoned"
				stats.turned_back = stats.get("turned_back", 0) + 1
				break
		r.travel_to(Stats.pick(rng, nxt))
		resolve_node(r)
		if r.party_heroes().is_empty():
			r.status = "defeat"
		elif r.is_final_node() and r.current_node().done:
			r.status = "victory" if r.boss_won else "abandoned"
	return co.finish_run(r.status)


func run_fight(r: RunState, enemies: Array, kind: String, surprise: String = "", reward: Dictionary = {}) -> bool:
	var e := fight(r.party_heroes(), enemies, r.combat_options(kind, surprise))
	var key := "deaths_" + kind + "_t%d" % r.tier()
	stats[key] = stats.get(key, 0) + e.fallen.size()
	stats["fights_" + kind + "_t%d" % r.tier()] = stats.get("fights_" + kind + "_t%d" % r.tier(), 0) + 1
	var res := r.after_combat(e, kind, reward)
	if kind == "boss":
		stats.boss_fights = stats.get("boss_fights", 0) + 1
		if res.result == "victory":
			stats.boss_wins = stats.get("boss_wins", 0) + 1
	return res.result == "victory"


func resolve_node(r: RunState) -> void:
	var n := r.current_node()
	match n.type:
		"fight", "elite", "boss", "crossing":
			var won := run_fight(r, n.data.enemies, n.type)
			if won:
				r.complete_current()
			elif n.type in ["boss", "crossing"]:
				r.status = "abandoned" if not r.party_heroes().is_empty() else "defeat"
			else:
				r.complete_current()
		"event", "homestead":
			stats.events += 1
			var opts := r.event_options(n.data.event).filter(func(o): return o.available)
			var o: Dictionary = Stats.pick(rng, opts)
			var res := r.choose_event_option(n.data.event, o.index)
			if res.fight != null:
				run_fight(r, res.fight.enemies, "fight", res.fight.surprise, res.fight.get("reward", {}))
			r.complete_current()
		"curio":
			for cu in n.data.curios:
				do_curio(r, cu.id)
				cu.done = true
				if r.party_heroes().is_empty():
					return
			r.complete_current()
		"camp":
			stats.camps += 1
			r.camp_start()
			var meal := "full" if int(r.supplies.get("food", 0)) >= 8 else "half"
			r.camp_meal(meal)
			var tries := 0
			while tries < 20:
				tries += 1
				var acts := r.camp_actions().filter(func(a): return a.available)
				if acts.is_empty():
					break
				var a: Dictionary = Stats.pick(rng, acts)
				var tgt: Hero = Stats.pick(rng, r.party_heroes())
				r.camp_act(a.uid, a.action.id, tgt.uid)
			var endres := r.camp_end()
			if endres.ambush:
				var pf := r.pending_fight
				r.pending_fight = {}
				run_fight(r, pf.enemies, "fight", "heroes")
			r.complete_current()
		"cave":
			stats.caves += 1
			r.cave_enter()
			while not r.cave_done() and not r.party_heroes().is_empty():
				var room := r.cave_room()
				if not room.fight.is_empty():
					if not run_fight(r, room.fight, "fight"):
						break
				if room.get("curio", "") != "":
					do_curio(r, room.curio)
				if room.get("treasure", false):
					r.cave_treasure()
				room.done = true
				if int(r.cave.light) < 40 and r.can_use_item("lamp_oil"):
					r.use_item("lamp_oil", null)
				r.cave_advance()
			r.cave_exit()
			r.complete_current()
		"trading_post":
			while int(r.supplies.get("food", 0)) < 10 and r.trade_buy("food"):
				pass
			r.complete_current()
		_:
			r.complete_current()


func do_curio(r: RunState, cid: String) -> void:
	stats.curios += 1
	var hs := r.party_heroes()
	if hs.is_empty():
		return
	var comp := r.compulsion_for(cid)
	var h: Hero = comp.hero if not comp.is_empty() else Stats.pick(rng, hs)
	var item := ""
	for k in DB.curios[cid].get("keys", {}):
		if int(r.supplies.get(k, 0)) > 0:
			item = k
	var res := r.interact_curio(cid, h, item if comp.is_empty() else "")
	if res.fight != null:
		run_fight(r, res.fight.enemies, "fight")
