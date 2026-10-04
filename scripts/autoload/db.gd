extends Node
## Data registry. Loads every content table from res://data/*.json once at startup.
## Content is data-driven: add a class, skill, enemy, quirk, event... by editing JSON.

const DATA_DIR := "res://data/"
const TABLES := [
	"config", "classes", "skills", "enemies", "regions", "settlements",
	"buildings", "survival", "quirks", "keepsakes", "items", "curios", "events",
	"fatigue_states", "names", "quests", "townsfolk",
]

var config: Dictionary = {}
var classes: Dictionary = {}
var skills: Dictionary = {}
var enemies: Dictionary = {}
var regions: Dictionary = {}
var settlements: Dictionary = {}
var buildings: Dictionary = {}
var survival: Dictionary = {}
var quirks: Dictionary = {}
var keepsakes: Dictionary = {}
var items: Dictionary = {}
var curios: Dictionary = {}
var events: Dictionary = {}
var fatigue_states: Dictionary = {}
var names: Dictionary = {}
var quests: Dictionary = {}
var townsfolk: Dictionary = {}

var load_errors: Array = []


func _ready() -> void:
	load_all()


func load_all() -> void:
	load_errors.clear()
	for t in TABLES:
		var d = _load_json(DATA_DIR + t + ".json")
		if d is Dictionary:
			set(t, d)
		else:
			load_errors.append("Missing or invalid table: %s" % t)
	# Every entry gets its own id for convenience.
	for t in TABLES:
		if t in ["config", "names", "quests", "townsfolk"]:
			continue
		var table: Dictionary = get(t)
		for k in table.keys():
			if str(k).begins_with("_"):
				table.erase(k)
			elif table[k] is Dictionary:
				table[k]["id"] = k


func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	var text := f.get_as_text()
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		load_errors.append("%s: line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return null
	return normalize(json.data)


## JSON numbers arrive as floats; integral values become ints so they work as
## indices, in range(), and in == comparisons.
static func normalize(v: Variant) -> Variant:
	if v is float and is_equal_approx(v, round(v)) and abs(v) < 1e15:
		return int(round(v))
	if v is Array:
		var out := []
		for e in v:
			out.append(normalize(e))
		return out
	if v is Dictionary:
		var out := {}
		for k in v.keys():
			out[k] = normalize(v[k])
		return out
	return v


func cfg(key: String, default: Variant = null) -> Variant:
	return config.get(key, default)


func skill(id: String) -> Dictionary:
	return skills.get(id, {})


func cls(id: String) -> Dictionary:
	return classes.get(id, {})


func enemy(id: String) -> Dictionary:
	return enemies.get(id, {})


## Cross-reference check used by tests. Returns a list of human-readable problems.
func validate() -> Array:
	var errs: Array = load_errors.duplicate()
	for cid in classes:
		var c: Dictionary = classes[cid]
		for sid in c.get("skills", []):
			if not skills.has(sid):
				errs.append("class %s: unknown skill %s" % [cid, sid])
		for sid in c.get("default_equipped", []):
			if not sid in c.get("skills", []):
				errs.append("class %s: default skill %s not in pool" % [cid, sid])
	for eid in enemies:
		for s in enemies[eid].get("skills", []):
			if not skills.has(s):
				errs.append("enemy %s: unknown skill %s" % [eid, s])
	for rid in regions:
		var r: Dictionary = regions[rid]
		for key in ["fights", "elites", "cave_fights"]:
			for enc in r.get(key, []):
				for eid in enc.get("enemies", []):
					if not enemies.has(eid):
						errs.append("region %s %s: unknown enemy %s" % [rid, key, eid])
		for eid in r.get("boss", {}).get("enemies", []):
			if not enemies.has(eid):
				errs.append("region %s boss: unknown enemy %s" % [rid, eid])
		for ev in r.get("events", []):
			if not events.has(ev):
				errs.append("region %s: unknown event %s" % [rid, ev])
		for cu in r.get("curios", []):
			if not curios.has(cu):
				errs.append("region %s: unknown curio %s" % [rid, cu])
	for cid in curios:
		for k in curios[cid].get("keys", {}).keys():
			if not items.has(k):
				errs.append("curio %s: unknown key item %s" % [cid, k])
	for sid in skills:
		var s: Dictionary = skills[sid]
		for key in ["use_ranks", "target", "anim"]:
			if not s.has(key):
				errs.append("skill %s: missing %s" % [sid, key])
		for e in s.get("effects", []) + s.get("self_effects", []):
			if e.get("type", "") == "summon" and not enemies.has(e.get("enemy", "")):
				errs.append("skill %s: summons unknown enemy %s" % [sid, e.get("enemy", "")])
	for evid in events:
		for opt in events[evid].get("options", []):
			for oc in opt.get("outcomes", []):
				for eff in oc.get("effects", []):
					if eff.get("type", "") == "fight":
						for eid in eff.get("enemies", []):
							if not enemies.has(eid):
								errs.append("event %s: unknown enemy %s" % [evid, eid])
	return errs
