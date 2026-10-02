class_name Hero
extends RefCounted
## A member of the company. Persistent between expeditions; saved as a dictionary.

var uid: int = 0
var hero_name: String = ""
var class_id: String = ""
var level: int = 1
var xp: int = 0
var hp: int = 1
var fatigue: int = 0
var fatigue_state: String = ""   # id in fatigue_states.json, or ""
var state_fresh: bool = false    # the state just landed; its on_land boons fire in the next fight turn
var deaths_door: bool = false
var shaken: bool = false         # Death's Door recovery, lasts the expedition
var quirks: Array = []           # quirk ids
var survival: Dictionary = {}    # skill id -> {"rank": int, "xp": int}
var skill_levels: Dictionary = {} # combat skill id -> level 1..4
var equipped: Array = []         # up to 4 combat skill ids
var known: Array = []            # combat skills learned so far (4 at hire; the rest at a Drill Hall)
var weapon_tier: int = 1
var armor_tier: int = 1
var keepsakes: Array = []        # up to 2 keepsake ids
var location: int = 0            # settlement index
var busy_weeks: int = 0          # >0: in a building, sits out expeditions
var busy_reason: String = ""
var transit_to: int = -1         # settlement index while riding the stage line
var transit_weeks: int = 0
var alive: bool = true
var expeditions: int = 0
var kills: int = 0
var death_note: String = ""
var look_seed: int = 0


func cls() -> Dictionary:
	return DB.cls(class_id)


func class_name_text() -> String:
	return cls().get("name", class_id)


# --- Stats ---------------------------------------------------------------------------

func all_mods() -> Array:
	var mods: Array = []
	for q in quirks:
		mods.append_array(DB.quirks.get(q, {}).get("mods", []))
	for k in keepsakes:
		mods.append_array(DB.keepsakes.get(k, {}).get("mods", []))
	if fatigue_state != "":
		mods.append_array(DB.fatigue_states.get(fatigue_state, {}).get("mods", []))
	if shaken:
		mods.append_array(DB.cfg("shaken_mods", []))
	return mods


func max_hp(ctx: Dictionary = {}) -> int:
	var c := cls()
	var base := float(c.get("hp", 20))
	base *= 1.0 + DB.cfg("level_hp_pct", 8) / 100.0 * (level - 1)
	base *= 1.0 + DB.cfg("armor_hp_pct", 8) / 100.0 * (armor_tier - 1)
	base *= 1.0 + Stats.sum_mods(all_mods(), "max_hp_pct", ctx) / 100.0
	return maxi(1, int(round(base)))


func base_stat(s: String) -> float:
	var c := cls()
	match s:
		"acc":
			return c.get("acc", 0) + DB.cfg("level_acc", 2) * (level - 1)
		"crit":
			return c.get("crit", 0) + DB.cfg("level_crit", 1) * (level - 1)
		"dodge":
			return c.get("dodge", 0) + DB.cfg("armor_dodge", 2) * (armor_tier - 1)
		"prot":
			return c.get("prot", 0)
		"speed":
			return c.get("speed", 0)
		"dmg_pct":
			return DB.cfg("weapon_dmg_pct", 12) * (weapon_tier - 1) + DB.cfg("level_dmg_pct", 0) * (level - 1)
		"stun_res", "bleed_res", "poison_res", "move_res", "debuff_res":
			return c.get("res", {}).get(s.trim_suffix("_res"), 30)
		"deathblow":
			return c.get("res", {}).get("deathblow", DB.cfg("deathblow_base", 67))
		"resolve":
			return DB.cfg("second_wind_base", 25) + DB.cfg("second_wind_per_level", 2) * (level - 1)
	return 0.0


func stat(s: String, ctx: Dictionary = {}) -> float:
	var v := base_stat(s) + Stats.sum_mods(all_mods(), s, ctx)
	if s == "deathblow":
		v = minf(v, DB.cfg("deathblow_cap", 87))
	return v


func dmg_range() -> Array:
	var d: Array = cls().get("dmg", [4, 8])
	var m: float = DB.cfg("hero_dmg_mult", 1.0)
	return [maxi(1, int(round(d[0] * m))), maxi(1, int(round(d[1] * m)))]


func knows(sid: String) -> bool:
	return sid in known


## Drops moves the class no longer has (after a rework) and fills in older saves.
func sanitize_skills() -> void:
	var valid: Array = cls().get("skills", [])
	known = known.filter(func(s): return s in valid)
	equipped = equipped.filter(func(s): return s in valid)
	if known.is_empty():
		known = equipped.duplicate()
	for s in equipped:
		if not s in known:
			known.append(s)
	if known.is_empty():
		known = valid.slice(0, 4)
	equipped = equipped.filter(func(s): return s in known)
	if equipped.is_empty():
		equipped = known.slice(0, 4)


func skill_level(sid: String) -> int:
	return int(skill_levels.get(sid, 1))


func survival_rank(sid: String) -> int:
	return int(survival.get(sid, {}).get("rank", 0))


func is_breaking() -> bool:
	return fatigue_state != "" and DB.fatigue_states.get(fatigue_state, {}).get("kind", "") == "breaking"


func is_second_wind() -> bool:
	return fatigue_state != "" and DB.fatigue_states.get(fatigue_state, {}).get("kind", "") == "second_wind"


func available() -> bool:
	return alive and busy_weeks <= 0 and transit_to < 0


func status_text() -> String:
	if not alive:
		return "Fallen"
	if transit_to >= 0:
		return "On the stage (%d wk)" % transit_weeks
	if busy_weeks > 0:
		return busy_reason if busy_reason != "" else "Busy"
	return "Ready"


func positive_quirks() -> Array:
	return quirks.filter(func(q): return DB.quirks.get(q, {}).get("positive", false))


func negative_quirks() -> Array:
	return quirks.filter(func(q): return not DB.quirks.get(q, {}).get("positive", false))


func xp_for_next() -> int:
	var table: Array = DB.cfg("xp_levels", [0, 10, 25, 45, 70])
	if level >= table.size():
		return -1
	return int(table[level])


## Adds XP and returns the number of levels gained.
func add_xp(amount: int) -> int:
	xp += amount
	var gained := 0
	var table: Array = DB.cfg("xp_levels", [0, 10, 25, 45, 70])
	while level < table.size() and xp >= int(table[level]):
		level += 1
		gained += 1
	return gained


# --- Serialization -------------------------------------------------------------------

const FIELDS := ["uid", "hero_name", "class_id", "level", "xp", "hp", "fatigue", "fatigue_state",
	"deaths_door", "shaken", "quirks", "survival", "skill_levels", "equipped", "known", "weapon_tier",
	"armor_tier", "keepsakes", "location", "busy_weeks", "busy_reason", "transit_to",
	"transit_weeks", "alive", "expeditions", "kills", "death_note", "look_seed", "state_fresh"]


func to_dict() -> Dictionary:
	var d := {}
	for f in FIELDS:
		var v = get(f)
		d[f] = v.duplicate(true) if (v is Array or v is Dictionary) else v
	return d


static func from_dict(d: Dictionary) -> Hero:
	var h := Hero.new()
	for f in FIELDS:
		if d.has(f):
			var v = d[f]
			if v is Array or v is Dictionary:
				h.set(f, v.duplicate(true))
			else:
				h.set(f, v)
	h.sanitize_skills()
	return h
