class_name MapGen
extends RefCounted
## Builds the branching trail for one expedition. Columns run east (0) to west (last).
## Every node's content (enemy group, event, curios, cave rooms...) is rolled up front so
## saving and loading mid-expedition is deterministic.

const COLUMNS := 9
const TYPE_NAMES := {
	"start": "Departure", "fight": "Trouble", "elite": "Dangerous Foes", "event": "Trail Event",
	"curio": "Curiosities", "cave": "Cave", "trading_post": "Trading Post", "homestead": "Homestead",
	"camp": "Campsite", "boss": "Boss", "crossing": "The Crossing",
}


static func generate(region_id: String, rng: RandomNumberGenerator, boss_beaten: bool) -> Array:
	var region: Dictionary = DB.regions[region_id]
	var nodes: Array = []
	var columns: Array = []
	var used_events: Array = []
	for c in COLUMNS:
		var count := 1
		if c > 0 and c < COLUMNS - 2:
			count = rng.randi_range(2, 4) if c != 1 else rng.randi_range(2, 3)
		var col: Array = []
		for l in count:
			var n := {"id": nodes.size(), "col": c, "lane": l, "y": (l + 0.5) / float(count),
				"type": "", "intel": 0, "decoy": false, "next": [], "visited": false, "done": false, "data": {}}
			nodes.append(n)
			col.append(n)
		columns.append(col)

	# Types.
	for c in COLUMNS:
		for n in columns[c]:
			if c == 0:
				n.type = "start"
				n.visited = true
				n.done = true
			elif c == COLUMNS - 1:
				n.type = "crossing" if boss_beaten else "boss"
			elif c == COLUMNS - 2:
				n.type = "camp"
			else:
				n.type = _roll_type(c, rng)
		# Guarantee a mid-trail camp and at least one plain fight early.
		if c == 4 and not columns[c].any(func(x): return x.type == "camp"):
			Stats.pick(rng, columns[c]).type = "camp"
		if c == 1 and not columns[c].any(func(x): return x.type == "fight"):
			columns[c][0].type = "fight"

	# Edges: each node links to the nearest node(s) in the next column; every node gets
	# at least one incoming link.
	for c in COLUMNS - 1:
		var cur: Array = columns[c]
		var nxt: Array = columns[c + 1]
		for n in cur:
			var best: Dictionary = _closest(nxt, n.y)
			n.next.append(best.id)
			if nxt.size() > 1 and rng.randf() < 0.45:
				var others := nxt.filter(func(x): return x.id != best.id and absf(x.y - n.y) < 0.55)
				if not others.is_empty():
					n.next.append(Stats.pick(rng, others).id)
		for m in nxt:
			var has_in := cur.any(func(x): return m.id in x.next)
			if not has_in:
				_closest(cur, m.y).next.append(m.id)
		for n in cur:
			n.next.sort()

	# Content, and how much the company can see of it from the start. Landmarks (camps,
	# the boss) are visible from afar; everything else must be scouted. Some fights look
	# quiet from a distance until someone gets a proper look.
	for n in nodes:
		_fill(n, region, rng, used_events)
		if n.type in ["start"]:
			n.intel = 3
		elif n.type in ["camp", "boss", "crossing"]:
			n.intel = 2
		if n.type == "fight" and rng.randf() < 0.15:
			n.decoy = true
	return nodes


## 0 unknown, 1 rough idea (trouble / quiet / cave), 2 known type, 3 known details.
static func intel(n: Dictionary) -> int:
	if n.has("intel"):
		return int(n.intel)
	return 0 if n.get("hidden", false) else 2


## What a rough look (intel 1) suggests: "danger", "quiet" or "cave".
static func vague_kind(n: Dictionary) -> String:
	if n.type == "cave":
		return "cave"
	if n.type in ["fight", "elite", "boss", "crossing"] and not n.get("decoy", false):
		return "danger"
	return "quiet"


static func _closest(col: Array, y: float) -> Dictionary:
	var best: Dictionary = col[0]
	for x in col:
		if absf(x.y - y) < absf(best.y - y):
			best = x
	return best


static func _roll_type(c: int, rng: RandomNumberGenerator) -> String:
	var table := [
		{"id": "fight", "weight": 40}, {"id": "event", "weight": 24}, {"id": "curio", "weight": 14},
		{"id": "homestead", "weight": 5},
	]
	if c >= 2:
		table.append({"id": "cave", "weight": 7})
		table.append({"id": "elite", "weight": 7})
	if c >= 3:
		table.append({"id": "trading_post", "weight": 5})
	return Stats.pick_weighted(rng, table).id


static func roll_group(rng: RandomNumberGenerator, groups: Array) -> Array:
	var g = Stats.pick_weighted(rng, groups)
	return g.enemies.duplicate() if g != null else []


static func _fill(n: Dictionary, region: Dictionary, rng: RandomNumberGenerator, used_events: Array) -> void:
	match n.type:
		"fight":
			n.data = {"enemies": roll_group(rng, region.fights)}
		"elite":
			n.data = {"enemies": roll_group(rng, region.elites)}
		"boss":
			n.data = {"enemies": region.boss.enemies.duplicate()}
		"crossing":
			n.data = {"enemies": region.crossing.enemies.duplicate()}
		"event":
			var pool: Array = region.events.filter(func(e): return not e in used_events)
			if pool.is_empty():
				pool = region.events
			var ev: String = Stats.pick(rng, pool)
			used_events.append(ev)
			n.data = {"event": ev}
		"homestead":
			n.data = {"event": Stats.pick(rng, region.homestead_events)}
		"curio":
			var cs: Array = []
			var pool: Array = Stats.shuffled(rng, region.curios)
			for i in rng.randi_range(2, 3):
				cs.append({"id": pool[i], "done": false})
			n.data = {"curios": cs}
		"cave":
			var rooms: Array = []
			var count := rng.randi_range(3, 4)
			for i in count:
				var r := {"fight": [], "curio": "", "done": false, "curio_done": false}
				var roll := rng.randf()
				if roll < 0.55:
					r.fight = roll_group(rng, region.cave_fights)
				if roll >= 0.4:
					r.curio = Stats.pick(rng, region.cave_curios)
				rooms.append(r)
			rooms.append({"fight": roll_group(rng, region.cave_fights) if rng.randf() < 0.5 else [],
				"curio": "", "treasure": true, "done": false, "curio_done": false})
			n.data = {"rooms": rooms, "name": region.get("cave_name", "Cave")}
		"trading_post":
			var stock := {}
			for it in ["food", "bandages", "antivenom", "whiskey", "lamp_oil", "wagon_parts", "rope", "salt"]:
				if it == "food" or rng.randf() < 0.7:
					stock[it] = rng.randi_range(2, 6) if it != "food" else rng.randi_range(8, 16)
			n.data = {"stock": stock, "markup": 1.5}
		"camp":
			n.data = {}
