class_name Combatant
extends RefCounted
## A unit inside one battle: wraps a Hero (persistent) or an enemy definition.

var id: int = 0
var side: String = "hero"        # "hero" or "enemy"
var hero: Hero = null
var data: Dictionary = {}        # class data (hero) or enemy data
var enemy_id := ""               # enemies.json key (empty for heroes)
var display_name: String = ""
var hp: int = 1
var max_hp: int = 1
var tags: Array = []
var skills: Array = []
var dots: Array = []             # {"kind": "bleed"/"poison", "amount": int, "rounds": int}
var buffs: Array = []            # {"stat", "value", "rounds", "name"}
var stunned: bool = false
var stun_guard: int = 0          # rounds of post-stun resistance
var mark: int = 0
var used_skills: Array = []      # moves this unit has used this fight (for "once" moves)
var guard_rounds: int = 0
var guarding: int = -1           # id of the ally this unit shields
var guarded_by: int = -1
var taunt: int = 0
var dead: bool = false
var corpse: bool = false         # an enemy's bones: holds its rank until destroyed
var momentum: int = 0            # Train Hopper gauge, 0-100; resets every fight
var round_num: int = 0           # the fight's current round (quirks that fire in round 1)
var turn_rank: int = 0           # rank at the start of this unit's turn (-1: turn lost to a stun)
var spent_mega: bool = false     # used its mega move this turn
var initiative: int = 0          # round-1 surprise bonus (+100 for the side that got the jump)
var actions_left: int = 0        # turns still to take this round (heroes 1; some bosses more)
var actions_used: int = 0        # turns taken this round
var tiebreak: float = 0.0        # random each round: settles equal speeds 50/50
var speed_roll: int = 0          # this round's small initiative roll, added to Speed


## Turns per round: 1, or the enemy's "actions" field (bosses can act more than once).
func actions_per_round() -> int:
	if corpse:
		return 0
	return 1 if hero != null else maxi(1, int(data.get("actions", 1)))
var tier: int = 1
var boss: bool = false
var rank: int = 1
var in_cave: bool = false


static func from_hero(h: Hero, uid: int, cave: bool) -> Combatant:
	var c := Combatant.new()
	c.id = uid
	c.side = "hero"
	c.hero = h
	c.data = h.cls()
	c.display_name = h.hero_name
	c.in_cave = cave
	c.max_hp = h.max_hp({"in_cave": cave})
	c.hp = clampi(h.hp, 0, c.max_hp)
	h.hp = c.hp
	c.tags = ["hero"]
	c.skills = h.equipped.duplicate()
	return c


static func from_enemy(eid: String, uid: int, t: int, cave: bool) -> Combatant:
	var c := Combatant.new()
	var d := DB.enemy(eid)
	c.id = uid
	c.side = "enemy"
	c.data = d
	c.enemy_id = eid
	c.display_name = d.get("name", eid)
	c.tier = t
	c.in_cave = cave
	c.boss = d.get("boss", false)
	var hp_mult: float = 1.0 + DB.cfg("tier_hp_pct", 40) / 100.0 * (t - 1)
	if c.boss:
		hp_mult = 1.0
	hp_mult *= float(DB.cfg("enemy_hp_mult", 1.0))
	c.max_hp = maxi(1, int(round(float(d.get("hp", 10)) * hp_mult)))
	c.hp = c.max_hp
	c.tags = d.get("tags", []).duplicate()
	c.skills = d.get("skills", []).duplicate()
	return c


## What a fallen enemy leaves in its rank: bones that block the line (the units behind
## don't step up) until they're destroyed. They never act and shrug off every effect.
static func bones(of: Combatant, uid: int) -> Combatant:
	var c := Combatant.new()
	c.id = uid
	c.side = "enemy"
	c.corpse = true
	c.data = {"id": "bones", "name": "Bones", "title": "What's left of the %s. Clear them to reach whoever's behind." % of.display_name,
		"look": {"body": "bones", "big": of.data.get("look", {}).get("body", "human") in ["giant", "bull", "bear"]}}
	c.display_name = "Bones"
	c.max_hp = maxi(1, int(DB.cfg("bones_hp", 2)))
	c.hp = c.max_hp
	c.tags = ["remains"]
	c.rank = of.rank
	return c


## A trinket's bonus to one move ("skill_mods": {move: {key: value}}), summed over the
## hero's trinkets. Keys: dmg_pct, acc, crit, effect_chance, mark_rounds, dot, heal,
## heal_pct, move.
func skill_mod(sid: String, key: String) -> float:
	if hero == null:
		return 0.0
	var v := 0.0
	for k in hero.keepsakes:
		v += float(DB.keepsakes.get(k, {}).get("skill_mods", {}).get(sid, {}).get(key, 0))
	return v


## Classes with "momentum": true (the Train Hopper) fill a gauge by moving.
func uses_momentum() -> bool:
	return hero != null and data.get("momentum", false)


## Add to the gauge (clamped 0..momentum_max); returns the change actually made.
func add_momentum(n: int) -> int:
	if not uses_momentum():
		return 0
	var before := momentum
	momentum = clampi(momentum + n, 0, int(DB.cfg("momentum_max", 100)))
	return momentum - before


## Full Steam: at half a gauge or more, extra Speed and Dodge.
func full_steam() -> bool:
	return uses_momentum() and momentum >= int(DB.cfg("full_steam_at", 50))


func is_poisoned() -> bool:
	return dots.any(func(d): return d.kind == "poison")


func is_hero() -> bool:
	return side == "hero"


func alive() -> bool:
	return not dead


func hp_ratio() -> float:
	return float(hp) / float(maxi(1, max_hp))


func deaths_door() -> bool:
	return hero != null and hero.deaths_door


func ctx(vs: Combatant = null) -> Dictionary:
	return {"in_cave": in_cave, "rank": rank, "hp_ratio": hp_ratio(),
		"tags": vs.tags if vs != null else [], "marked": mark > 0, "deaths_door": deaths_door(),
		"round": round_num, "vs_marked": vs != null and vs.mark > 0,
		"guarding": guarding >= 0 or taunt > 0, "poisoned": is_poisoned(),
		"vs_vulnerable": vs != null and vs.buff_total("vulnerable") > 0}


## Damage taken multiplier from Vulnerable (+% damage taken, all sources, damage over time
## too). A negative value makes the unit tougher, never below half damage.
func vuln_mult() -> float:
	return maxf(0.5, 1.0 + stat("vulnerable") / 100.0)


func buff_total(s: String) -> float:
	var t := 0.0
	for b in buffs:
		if b.stat == s:
			t += float(b.value)
	return t


func stat(s: String, vs: Combatant = null) -> float:
	var v := 0.0
	if hero != null:
		v = hero.stat(s, ctx(vs))
	else:
		var scale := 0 if boss else tier - 1
		match s:
			"acc":
				v = data.get("acc", 0) + DB.cfg("tier_acc", 5) * scale
			"dodge":
				v = data.get("dodge", 0) + DB.cfg("tier_dodge", 4) * scale
			"prot":
				v = data.get("prot", 0)
			"speed":
				v = data.get("speed", 0) + scale
			"crit":
				v = data.get("crit", 0)
			"stun_res", "bleed_res", "poison_res", "move_res", "debuff_res":
				v = data.get("res", {}).get(s.trim_suffix("_res"), 25) + DB.cfg("tier_res", 5) * scale
	v += buff_total(s)
	if full_steam():
		if s == "speed":
			v += DB.cfg("full_steam_speed", 3)
		elif s == "dodge":
			v += DB.cfg("full_steam_dodge", 5)
	if s == "stun_res" and stun_guard > 0:
		v += DB.cfg("stun_guard_res", 50)
	if s == "prot":
		v = clampf(v, 0, 80)
	return v


func dmg_range() -> Array:
	if hero != null:
		return hero.dmg_range()
	var d: Array = data.get("dmg", [2, 4])
	var mult: float = 1.0 if boss else 1.0 + DB.cfg("tier_dmg_pct", 30) / 100.0 * (tier - 1)
	mult *= float(DB.cfg("enemy_dmg_mult", 1.0))
	return [maxi(1, int(round(d[0] * mult))), maxi(1, int(round(d[1] * mult)))]


func set_hp(v: int) -> void:
	hp = clampi(v, 0, max_hp)
	if hero != null:
		hero.hp = hp


func skill_level(sid: String) -> int:
	return hero.skill_level(sid) if hero != null else 1


## Short status labels for the UI.
func status_chips() -> Array:
	var chips: Array = []
	var bleed := 0
	var poison := 0
	for d in dots:
		if d.kind == "bleed":
			bleed += d.amount
		else:
			poison += d.amount
	if bleed > 0:
		chips.append({"text": "Bleed %d" % bleed, "kind": "bad"})
	if poison > 0:
		chips.append({"text": "Poison %d" % poison, "kind": "bad"})
	if stunned:
		chips.append({"text": "Stun", "kind": "bad"})
	if mark > 0:
		chips.append({"text": "Marked", "kind": "bad"})
	if guarded_by >= 0:
		chips.append({"text": "Guarded", "kind": "good"})
	if guarding >= 0:
		chips.append({"text": "Guarding", "kind": "good"})
	if taunt > 0:
		chips.append({"text": "Taunt", "kind": "good"})
	if hero != null and hero.rattled:
		chips.append({"text": "Rattled", "kind": "bad"})
	# Death's Door has no chip: the HP bar already reads DEATH'S DOOR.
	var totals := {}
	for b in buffs:
		totals[b.stat] = totals.get(b.stat, 0.0) + float(b.value)
	for s in totals:
		if totals[s] != 0:
			var m := {"stat": s, "value": totals[s]}
			chips.append({"text": Stats.mod_short(m), "kind": "good" if Stats.mod_is_good(m) else "bad"})
	return chips
