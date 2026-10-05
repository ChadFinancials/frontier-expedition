class_name Townsfolk
extends RefCounted
## Townsfolk: the people who staff a settlement's buildings. A separate pool from heroes:
## they never ride out, and heroes never become townsfolk. Each is a plain dictionary in
## Company.townsfolk (saved as is):
##   {uid, name, trade, level 1-3, xp, trait, home (settlement index), post (building id or ""),
##    unpaid (weeks in a row), idle (weeks in a row), off (sleeping it off this week)}
## Rules and numbers are in data/townsfolk.json; Company applies them to the buildings.


static func data() -> Dictionary:
	return DB.townsfolk


static func trade(p: Dictionary) -> Dictionary:
	return data().get("trades", {}).get(str(p.get("trade", "")), {})


static func trait_info(p: Dictionary) -> Dictionary:
	return data().get("traits", {}).get(str(p.get("trait", "")), {})


static func has_trait(p: Dictionary, t: String) -> bool:
	return str(p.get("trait", "")) == t


static func level_name(lvl: int) -> String:
	var names: Array = data().get("levels", ["Greenhorn", "Hand", "Master"])
	return str(names[clampi(lvl, 1, names.size()) - 1])


## The highest level this person can reach (Set in Their Ways stops at Hand).
static func max_level(p: Dictionary) -> int:
	return 2 if has_trait(p, "set_in_ways") else 3


## The level they work at: Hard Worker one up, Lazybones one down (0 = no help at all).
static func work_level(p: Dictionary) -> int:
	var l := int(p.get("level", 1))
	if has_trait(p, "hard_worker"):
		l += 1
	elif has_trait(p, "lazybones"):
		l -= 1
	return clampi(l, 0, 3)


static func wage(p: Dictionary) -> int:
	var w: Array = data().get("wages", [10, 20, 30])
	var base := float(w[clampi(int(p.get("level", 1)), 1, w.size()) - 1])
	if has_trait(p, "thrifty"):
		base *= 0.5
	elif has_trait(p, "grasping"):
		base *= 1.5
	return int(round(base))


## The trade that belongs in a building, or "".
static func trade_for(bid: String) -> String:
	var tr: Dictionary = data().get("trades", {})
	for t in tr:
		if str(tr[t].get("building", "")) == bid:
			return t
	return ""


## Is this person the right trade for the building?
static func fits(p: Dictionary, bid: String) -> bool:
	return str(trade(p).get("building", "-")) == bid


## What one staffer adds in a building, in that building's own unit (relief, percent off,
## materials a week). The right trade gives their level's value; a Laborer gives half a
## Greenhorn's as a Greenhorn and a full Greenhorn's after; anyone else half a Greenhorn's
## (Handy: a full Greenhorn's). Sleeping it off: nothing.
static func value_in(p: Dictionary, bid: String) -> float:
	if p.get("off", false):
		return 0.0
	var own := trade_for(bid)
	if own == "":
		return 0.0
	var vals: Array = data().get("trades", {}).get(own, {}).get("values", [0])
	var wl := work_level(p)
	if wl <= 0:
		return 0.0
	if fits(p, bid):
		return float(vals[mini(wl, vals.size()) - 1])
	var green := float(vals[0])
	if has_trait(p, "handy"):
		return green
	if str(p.get("trade", "")) == "laborer":
		return green if wl >= 2 else green * 0.5
	return green * 0.5


## A Master working in their own trade (for the trade's extra: a side quest, a bed...).
static func is_master_at(p: Dictionary, bid: String) -> bool:
	return not p.get("off", false) and fits(p, bid) and work_level(p) >= 3


## "Hattie Coombs, Hand Barkeep"
static func title(p: Dictionary) -> String:
	return "%s, %s %s" % [p.get("name", "?"), level_name(int(p.get("level", 1))), trade(p).get("name", "?")]


## "★ Thrifty" or "✗ Tippler"
static func trait_text(p: Dictionary) -> String:
	var t := trait_info(p)
	if t.is_empty():
		return ""
	return ("★ " if t.get("good", false) else "✗ ") + str(t.get("name", ""))


## What they'd add in a building, as a short phrase ("+10 Fatigue relief", "-15% chips").
static func value_text(bid: String, v: float) -> String:
	var own := trade_for(bid)
	var kind: String = data().get("trades", {}).get(own, {}).get("kind", "")
	var n := snappedf(v, 0.5)
	var s := str(int(n)) if is_equal_approx(n, roundf(n)) else str(n)
	match kind:
		"relief":
			return "+%s Fatigue shed" % s
		"discount":
			return "-%s%% chips" % s
		"store":
			return "%s%% more off" % s
		"cargo":
			return "+%s wagon slot%s" % [s, "" if s == "1" else "s"]
		"produce":
			var mats: Dictionary = DB.buildings.get(bid, {}).get("produce", {})
			var mat: String = mats.keys()[0] if not mats.is_empty() else "timber"
			return "+%s %s a week" % [s, mat.capitalize()]
	return ""
