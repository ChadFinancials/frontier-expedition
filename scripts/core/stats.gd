class_name Stats
extends RefCounted
## Shared helpers for the modifier format used by quirks, keepsakes, fatigue states,
## camp buffs and combat buffs:  {"stat": "acc", "value": 5, "cond": "vs:beast"}
##
## Conditions: always (default), in_cave, on_trail, front (ranks 1-2), back (ranks 3-4),
## low_hp (below 50%), vs:<tag> (the opponent has the tag).

const STAT_NAMES := {
	"max_hp_pct": "Max HP", "acc": "Accuracy", "dodge": "Dodge", "prot": "Protection",
	"speed": "Speed", "crit": "Crit", "dmg_pct": "Damage", "dmg_flat": "Damage per hit", "pierce": "Armor Piercing", "stun_res": "Stun Resist",
	"bleed_res": "Bleed Resist", "poison_res": "Poison Resist", "move_res": "Move Resist",
	"debuff_res": "Debuff Resist", "deathblow": "Deathblow Resist", "fatigue_pct": "Fatigue Taken",
	"heal_pct": "Healing Received", "resolve": "Second Wind Chance", "scout": "Scouting",
	"surprise": "Surprise Chance", "food_pct": "Food Eaten", "loot_pct": "Loot Found",
}
const PERCENT_STATS := ["max_hp_pct", "prot", "pierce", "dmg_pct", "crit", "stun_res", "bleed_res",
	"poison_res", "move_res", "debuff_res", "deathblow", "fatigue_pct", "heal_pct", "resolve",
	"scout", "surprise", "food_pct", "loot_pct"]
## For these stats a positive number is bad for the hero.
const INVERTED_STATS := ["fatigue_pct", "food_pct"]


static func cond_ok(cond: String, ctx: Dictionary) -> bool:
	if cond == "" or cond == "always":
		return true
	if cond == "in_cave":
		return ctx.get("in_cave", false)
	if cond == "on_trail":
		return not ctx.get("in_cave", false)
	if cond == "front":
		return ctx.get("rank", 0) in [1, 2]
	if cond == "back":
		return ctx.get("rank", 0) in [3, 4]
	if cond == "low_hp":
		return ctx.get("hp_ratio", 1.0) < 0.5
	if cond.begins_with("vs:"):
		return cond.substr(3) in ctx.get("tags", [])
	return false


static func sum_mods(mods: Array, stat: String, ctx: Dictionary) -> float:
	var total := 0.0
	for m in mods:
		if m.get("stat", "") == stat and cond_ok(str(m.get("cond", "always")), ctx):
			total += float(m.get("value", 0))
	return total


static func cond_text(cond: String) -> String:
	match cond:
		"", "always":
			return ""
		"in_cave":
			return " in caves"
		"on_trail":
			return " on the trail"
		"front":
			return " in ranks 1-2"
		"back":
			return " in ranks 3-4"
		"low_hp":
			return " below half HP"
	if cond.begins_with("vs:"):
		return " vs %s" % cond.substr(3).capitalize()
	return ""


static func mod_text(m: Dictionary) -> String:
	var stat: String = m.get("stat", "")
	var v: float = float(m.get("value", 0))
	var sign := "+" if v >= 0 else ""
	var unit := "%" if stat in PERCENT_STATS else ""
	return "%s%s%s %s%s" % [sign, str(int(v)) if is_equal_approx(v, round(v)) else str(v), unit,
		STAT_NAMES.get(stat, stat), cond_text(str(m.get("cond", "")))]


## Short labels for the status chips under a unit ("ACC +10"); the unit tooltip has the
## full wording.
const STAT_SHORT := {
	"max_hp_pct": "HP", "acc": "ACC", "dodge": "DODGE", "prot": "PROT", "speed": "SPD",
	"crit": "CRIT", "dmg_pct": "DMG", "dmg_flat": "DMG", "pierce": "PIERCE", "stun_res": "STUN RES",
	"bleed_res": "BLEED RES", "poison_res": "POISON RES", "move_res": "MOVE RES",
	"debuff_res": "DEBUFF RES", "deathblow": "DEATHBLOW", "heal_pct": "HEALING",
}


static func mod_short(m: Dictionary) -> String:
	var stat: String = m.get("stat", "")
	var v: float = float(m.get("value", 0))
	var num := str(int(v)) if is_equal_approx(v, round(v)) else str(v)
	return "%s %s%s%s" % [STAT_SHORT.get(stat, STAT_NAMES.get(stat, stat)), "+" if v >= 0 else "", num,
		"%" if stat in PERCENT_STATS else ""]


## True when the modifier is good for the one who carries it.
static func mod_is_good(m: Dictionary) -> bool:
	var v: float = float(m.get("value", 0))
	if m.get("stat", "") in INVERTED_STATS:
		return v < 0
	return v > 0


static func pick_weighted(rng: RandomNumberGenerator, entries: Array, weight_key := "weight") -> Variant:
	if entries.is_empty():
		return null
	var total := 0.0
	for e in entries:
		total += float(e.get(weight_key, 1)) if e is Dictionary else 1.0
	var r := rng.randf() * total
	for e in entries:
		r -= float(e.get(weight_key, 1)) if e is Dictionary else 1.0
		if r <= 0.0:
			return e
	return entries[entries.size() - 1]


static func pick(rng: RandomNumberGenerator, arr: Array) -> Variant:
	if arr.is_empty():
		return null
	return arr[rng.randi_range(0, arr.size() - 1)]


static func shuffled(rng: RandomNumberGenerator, arr: Array) -> Array:
	var a := arr.duplicate()
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = a[i]
		a[i] = a[j]
		a[j] = t
	return a
