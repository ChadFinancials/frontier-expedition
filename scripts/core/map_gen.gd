class_name MapGen
extends RefCounted
## Builds the branching trail for one expedition. Columns run east (0) to west (last).
## Every node's content (enemy group, event, curios, cave rooms...) is rolled up front so
## saving and loading mid-expedition is deterministic.

const COLUMNS := 12
const TYPE_NAMES := {
	"start": "Departure", "fight": "Trouble", "elite": "Dangerous Foes", "event": "Trail Event",
	"curio": "Curiosities", "cave": "Cave", "trading_post": "Trading Post", "homestead": "Homestead",
	"camp": "Campsite", "boss": "Boss", "crossing": "The Crossing",
}


static func generate(region_id: String, rng: RandomNumberGenerator, boss_beaten: bool) -> Array:
	var region: Dictionary = DB.regions[region_id]
	if region.has("fixed_map"):
		return _fixed(region)
	# Side adventures are shorter and always end at their mini-boss.
	var cols_n := int(region.get("columns", COLUMNS))
	if region.get("side", false):
		boss_beaten = false
	var mid_camp := cols_n / 2 if cols_n >= 8 and not region.get("side", false) else -1
	var nodes: Array = []
	var columns: Array = []
	var used_events: Array = []
	for c in cols_n:
		var count := 1
		if c > 0 and c < cols_n - 2:
			count = rng.randi_range(2, 4) if c != 1 else rng.randi_range(2, 3)
		var col: Array = []
		for l in count:
			var n := {"id": nodes.size(), "col": c, "lane": l, "y": (l + 0.5) / float(count),
				"type": "", "intel": 0, "decoy": false, "next": [], "visited": false, "done": false, "data": {}}
			nodes.append(n)
			col.append(n)
		columns.append(col)

	# Types.
	for c in cols_n:
		for n in columns[c]:
			if c == 0:
				n.type = "start"
				n.visited = true
				n.done = true
			elif c == cols_n - 1:
				n.type = region.get("final", "crossing" if boss_beaten else "boss")
			elif c == cols_n - 2 and not region.get("side", false):
				n.type = "camp"
			else:
				n.type = _roll_type(c, rng, region.get("node_weights", {}))
		# Guarantee a mid-trail camp and at least one plain fight early.
		if c == mid_camp and not columns[c].any(func(x): return x.type == "camp"):
			Stats.pick(rng, columns[c]).type = "camp"
		if c == 1 and not columns[c].any(func(x): return x.type == "fight"):
			columns[c][0].type = "fight"
	# Not too many caves on one trail: extras become fights or curiosities.
	var caves := Stats.shuffled(rng, nodes.filter(func(x): return x.type == "cave"))
	for k in range(int(region.get("max_caves", DB.cfg("max_caves", 2))), caves.size()):
		caves[k].type = "fight" if rng.randf() < 0.5 else "curio"

	# Edges: each node links to the nearest node(s) in the next column; every node gets
	# at least one incoming link.
	for c in cols_n - 1:
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


## A hand-authored map (the tutorial): columns of nodes, each linking to every node in the
## next column. Node entries carry type, content (enemies / event / curios), and optional
## title, story (shown on arrival) and lane_y. Everything is fully scouted.
static func _fixed(region: Dictionary) -> Array:
	var nodes: Array = []
	var cols: Array = region.fixed_map
	var prev: Array = []
	for c in cols.size():
		var col: Array = cols[c]
		var cur: Array = []
		for l in col.size():
			var src: Dictionary = col[l]
			var n := {"id": nodes.size(), "col": c, "lane": l, "y": float(src.get("lane_y", (l + 0.5) / float(col.size()))),
				"type": src.type, "intel": int(src.get("intel", 3)), "decoy": false, "next": [], "visited": c == 0, "done": c == 0, "data": {}}
			match src.type:
				"fight", "elite":
					n.data = {"enemies": src.enemies.duplicate()}
				"boss":
					n.data = {"enemies": region.boss.enemies.duplicate()}
				"event", "homestead":
					n.data = {"event": src.event}
				"curio":
					var cs: Array = []
					for cid in src.curios:
						cs.append({"id": cid, "done": false})
					n.data = {"curios": cs}
			if src.has("title"):
				n.data["title"] = src.title
			if src.has("story"):
				n.data["story"] = src.story
			nodes.append(n)
			cur.append(n)
		for p in prev:
			for n2 in cur:
				p.next.append(n2.id)
		prev = cur
	return nodes


## Number of map columns (fixed maps can be shorter).
static func column_count(nodes: Array) -> int:
	var m := 0
	for n in nodes:
		m = maxi(m, int(n.col))
	return m + 1


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


## weights: optional per-region overrides ({type: weight}), e.g. a mine full of caves.
static func _roll_type(c: int, rng: RandomNumberGenerator, weights: Dictionary = {}) -> String:
	var w := {"fight": 40, "event": 24, "curio": 14, "homestead": 5, "cave": 7, "elite": 7, "trading_post": 5}
	for k in weights:
		w[k] = int(weights[k])
	var table: Array = []
	for k in ["fight", "event", "curio", "homestead"]:
		table.append({"id": k, "weight": w[k]})
	if c >= 2:
		table.append({"id": "cave", "weight": w.cave})
		table.append({"id": "elite", "weight": w.elite})
	if c >= 3:
		table.append({"id": "trading_post", "weight": w.trading_post})
	return Stats.pick_weighted(rng, table.filter(func(x): return int(x.weight) > 0)).id


static func roll_group(rng: RandomNumberGenerator, groups: Array) -> Array:
	var g = Stats.pick_weighted(rng, groups)
	return g.enemies.duplicate() if g != null else []


## Sometimes a fight leaves something worth searching on the field (looked at afterwards).
static func _battle_curio(n: Dictionary, region: Dictionary, rng: RandomNumberGenerator, chance: float) -> void:
	if region.get("curios", []).is_empty() or rng.randf() * 100.0 >= chance:
		return
	n.data["curios"] = [{"id": Stats.pick(rng, region.curios), "done": false}]


## An event stop draws from layered pools: the common pool (config common_events) and the
## region's own list, plus a side quest's theme list. A layer is picked by weight among those
## with unused events left; no repeats until every layer runs dry.
static func pick_event(region: Dictionary, rng: RandomNumberGenerator, used: Array) -> String:
	var common: Array = DB.cfg("common_events", [])
	var layers: Array = []
	if region.has("theme_events"):
		var qw: Dictionary = DB.cfg("quest_event_weights", {"theme": 40, "region": 30, "common": 30})
		layers = [[region.theme_events, qw.get("theme", 40)], [region.get("events", []), qw.get("region", 30)], [common, qw.get("common", 30)]]
	else:
		var w: Dictionary = DB.cfg("event_pool_weights", {"common": 45, "region": 55})
		layers = [[region.get("events", []), w.get("region", 55)], [common, w.get("common", 45)]]
	var open: Array = []
	var every: Array = []
	for l in layers:
		var left: Array = l[0].filter(func(e): return DB.events.has(e) and not e in used)
		if not left.is_empty() and float(l[1]) > 0:
			open.append({"pool": left, "weight": float(l[1])})
		every.append_array(l[0].filter(func(e): return DB.events.has(e)))
	var ev := ""
	if not open.is_empty():
		ev = Stats.pick(rng, Stats.pick_weighted(rng, open).pool)
	elif not every.is_empty():
		ev = Stats.pick(rng, every)
	if ev != "":
		used.append(ev)
	return ev


static func _fill(n: Dictionary, region: Dictionary, rng: RandomNumberGenerator, used_events: Array) -> void:
	match n.type:
		"fight":
			n.data = {"enemies": roll_group(rng, region.fights)}
			_battle_curio(n, region, rng, DB.cfg("fight_curio_chance", 30))
		"elite":
			n.data = {"enemies": roll_group(rng, region.elites)}
			_battle_curio(n, region, rng, DB.cfg("elite_curio_chance", 50))
		"boss":
			n.data = {"enemies": region.boss.enemies.duplicate()}
		"crossing":
			n.data = {"enemies": region.crossing.enemies.duplicate()}
		"event":
			n.data = {"event": pick_event(region, rng, used_events)}
		"homestead":
			n.data = {"event": Stats.pick(rng, region.homestead_events)}
		"curio":
			var cs: Array = []
			var pool: Array = Stats.shuffled(rng, region.curios)
			cs.append({"id": pool[0], "done": false})
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
			n.data = {"stock": stock, "markup": float(DB.cfg("trade_markup", 2.2))}
		"camp":
			n.data = {}
