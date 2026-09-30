class_name MapView
extends Control
## The expedition's branching trail drawn on parchment. Emits node_clicked(id) for
## reachable nodes.

signal node_clicked(id: int)

var run: RunState
var hover := -1
var enabled := true
var _t := 0.0
const R := 30.0
## The wagon piece: it sits on the current stop and rolls to token_to while travelling
## (the trail screen tweens token_t from 0 to 1).
var token_to := -1
var token_t := 0.0

const INK := Color(0.2, 0.13, 0.08)
const SKETCH := Color(0.35, 0.24, 0.14, 0.38)
const SHEET := Color("#ecdcb8")
const OAK := Color("#d9b47e")
## Sketched terrain per region; anything else gets grass and hills.
const TERRAIN := {"tallgrass": ["grass", "grass", "hill", "tree"], "old_mill_road": ["tree", "grass", "hill", "tree"],
	"crows_nest": ["tree", "tree", "grass", "tree"], "dry_gulch_mine": ["rock", "mesa", "cactus", "grass"],
	"red_canyons": ["mesa", "rock", "cactus", "mesa"], "thunder_peaks": ["peak", "pine", "rock", "pine"]}
var _terrain: Array = []     # [kind, pos, scale], cached per map
var _terrain_key := ""


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _rng(extra: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = extra * 7919 + run.nodes.size() * 131 + hash(run.region_id)
	return rng


func _legend_rect() -> Rect2:
	return Rect2(14, size.y - 44, 650, 32)


func _sign_rect() -> Rect2:
	return Rect2(size.x - 250, size.y - 58, 210, 40)


## The map sheet: worn parchment with a scorched, uneven edge, nailed to the board behind it.
func _draw_sheet() -> void:
	var rng := _rng(1)
	var r := Rect2(Vector2(2, 2), size - Vector2(4, 4))
	var edge := PackedVector2Array()
	var step := 22.0
	var x := r.position.x
	while x < r.end.x:
		edge.append(Vector2(x, r.position.y + rng.randf_range(0, 5)))
		x += step
	var y := r.position.y
	while y < r.end.y:
		edge.append(Vector2(r.end.x - rng.randf_range(0, 5), y))
		y += step
	x = r.end.x
	while x > r.position.x:
		edge.append(Vector2(x, r.end.y - rng.randf_range(0, 5)))
		x -= step
	y = r.end.y
	while y > r.position.y:
		edge.append(Vector2(r.position.x + rng.randf_range(0, 5), y))
		y -= step
	draw_colored_polygon(edge, SHEET)
	# Age: a darker tone creeping in from the edge, and a scorched rim.
	for k in 5:
		var inset := 6.0 + k * 7.0
		draw_rect(Rect2(r.position + Vector2(inset, inset), r.size - Vector2(inset, inset) * 2), Color(0.55, 0.38, 0.18, 0.05), false, 8.0)
	var rim := edge.duplicate()
	rim.append(edge[0])
	draw_polyline(Figure.clean_line(rim), Color(0.36, 0.22, 0.11, 0.55), 3.0, true)
	# Tea stains.
	for k in 4:
		var c := Vector2(rng.randf_range(120, size.x - 120), rng.randf_range(60, size.y - 60))
		var rr := rng.randf_range(30, 60)
		draw_circle(c, rr, Color(0.6, 0.42, 0.2, 0.05))
		draw_arc(c, rr, 0, TAU, 40, Color(0.55, 0.38, 0.18, 0.1), 2.5, true)
	for p in [Vector2(16, 16), Vector2(size.x - 16, 16), Vector2(16, size.y - 60), Vector2(size.x - 16, size.y - 16)]:
		_nail(p)


func _nail(p: Vector2) -> void:
	draw_circle(p + Vector2(1, 1.5), 4.5, Color(0, 0, 0, 0.3))
	draw_circle(p, 4.0, Color("#4a4540"))
	draw_circle(p + Vector2(-1.2, -1.2), 1.6, Color("#a39c92"))


## Little ink sketches of the country between the stops, kept clear of stops and trails.
func _draw_terrain() -> void:
	var key := "%s:%d:%d" % [run.region_id, run.nodes.size(), int(size.x)]
	if key != _terrain_key:
		_terrain_key = key
		_terrain = []
		var kinds: Array = TERRAIN.get(run.region_id, ["grass", "hill", "grass", "tree"])
		var rng := _rng(2)
		var segs: Array = []
		for n in run.nodes:
			for nx in n.next:
				segs.append([node_pos(n), node_pos(run.node(nx))])
		var gx := 60.0
		while gx < size.x - 40:
			var gy := 30.0
			while gy < size.y - 30:
				var p := Vector2(gx + rng.randf_range(-22, 22), gy + rng.randf_range(-16, 16))
				var ok := not _legend_rect().grow(16).has_point(p) and not _sign_rect().grow(20).has_point(p)
				for n in run.nodes:
					if ok and node_pos(n).distance_to(p) < R + 26:
						ok = false
				for sg in segs:
					if ok and Geometry2D.get_closest_point_to_segment(p, sg[0], sg[1]).distance_to(p) < 20:
						ok = false
				if ok and rng.randf() < 0.55:
					_terrain.append([kinds[rng.randi() % kinds.size()], p, rng.randf_range(0.8, 1.25)])
				gy += 52.0
			gx += 66.0
	for t in _terrain:
		_sketch(str(t[0]), t[1], float(t[2]))


func _sketch(kind: String, p: Vector2, s: float) -> void:
	var c := SKETCH
	match kind:
		"grass":
			for k in 4:
				var bx := p.x + (k - 1.5) * 4.0 * s
				draw_line(Vector2(bx, p.y + 5 * s), Vector2(bx + (k - 1.5) * 2.5 * s, p.y - 6 * s - (k % 2) * 3 * s), c, 1.4, true)
		"hill":
			draw_arc(p, 16 * s, PI * 1.08, TAU - 0.08, 12, c, 1.6, true)
			draw_arc(p + Vector2(14, 4) * s, 11 * s, PI * 1.1, TAU - 0.1, 10, c, 1.4, true)
			draw_line(p + Vector2(-6, -8) * s, p + Vector2(-2, -4) * s, Color(c, 0.25), 1.0, true)
		"tree":
			draw_line(p + Vector2(0, 10) * s, p + Vector2(0, -2) * s, c, 1.8, true)
			draw_arc(p + Vector2(0, -8) * s, 9 * s, 0, TAU, 14, c, 1.6, true)
			draw_line(p + Vector2(-4, -8) * s, p + Vector2(2, -3) * s, Color(c, 0.3), 1.0, true)
		"rock":
			draw_polyline(Figure.clean_line(PackedVector2Array([p + Vector2(-10, 6) * s, p + Vector2(-6, -3) * s, p + Vector2(2, -6) * s, p + Vector2(9, 0) * s, p + Vector2(10, 6) * s])), c, 1.6, true)
		"mesa":
			draw_polyline(Figure.clean_line(PackedVector2Array([p + Vector2(-20, 8) * s, p + Vector2(-12, -8) * s, p + Vector2(10, -8) * s, p + Vector2(20, 8) * s])), c, 1.6, true)
			for k in 3:
				draw_line(p + Vector2(-8 + k * 7, -6) * s, p + Vector2(-10 + k * 7, 6) * s, Color(c, 0.25), 1.0, true)
		"cactus":
			draw_line(p + Vector2(0, 10) * s, p + Vector2(0, -10) * s, c, 2.2, true)
			draw_polyline(Figure.clean_line(PackedVector2Array([p + Vector2(0, 0) * s, p + Vector2(-6, 0) * s, p + Vector2(-6, -6) * s])), c, 1.8, true)
			draw_polyline(Figure.clean_line(PackedVector2Array([p + Vector2(0, -3) * s, p + Vector2(5, -3) * s, p + Vector2(5, -9) * s])), c, 1.8, true)
		"pine":
			draw_polyline(Figure.clean_line(PackedVector2Array([p + Vector2(-8, 6) * s, p + Vector2(0, -12) * s, p + Vector2(8, 6) * s, p + Vector2(-8, 6) * s])), c, 1.5, true)
			draw_line(p + Vector2(0, 6) * s, p + Vector2(0, 11) * s, c, 1.5, true)
		"peak":
			draw_polyline(Figure.clean_line(PackedVector2Array([p + Vector2(-20, 10) * s, p + Vector2(0, -14) * s, p + Vector2(20, 10) * s])), c, 1.7, true)
			draw_polyline(Figure.clean_line(PackedVector2Array([p + Vector2(-6, -7) * s, p + Vector2(-2, -4) * s, p + Vector2(2, -7) * s, p + Vector2(6, -6) * s])), c, 1.2, true)


## A hand-inked trail between two stops: a gentle curve, dotted until travelled.
func _trail_pts(a: Vector2, b: Vector2, seed_id: int) -> PackedVector2Array:
	var rng := _rng(100 + seed_id)
	var mid := (a + b) / 2.0 + (b - a).normalized().orthogonal() * rng.randf_range(-12, 12)
	var pts := PackedVector2Array()
	for i in 17:
		var t := i / 16.0
		pts.append(a.lerp(mid, t).lerp(mid.lerp(b, t), t))
	return pts


## Stops are wooden discs with the kind burned in; elites and the boss sit in red wax.
func _disc(p: Vector2, r: float, id: int, tone: Color, wax: bool) -> void:
	var rng := _rng(300 + id)
	var ph := rng.randf() * TAU
	if wax:
		var seal := PackedVector2Array()
		for i in 24:
			var a := TAU * i / 24.0
			seal.append(p + Vector2(cos(a), sin(a)) * (r + 7 + 2.5 * sin(a * 5 + ph)))
		draw_colored_polygon(seal, Color("#8f2a22"))
		draw_arc(p, r + 3, 0, TAU, 32, Color("#6a1c16"), 2.0, true)
	var disc := PackedVector2Array()
	for i in 28:
		var a := TAU * i / 28.0
		disc.append(p + Vector2(cos(a), sin(a)) * (r + 1.2 * sin(a * 3 + ph)))
	draw_colored_polygon(disc, tone)
	draw_arc(p + Vector2(0, -2), r - 3, PI * 1.1, TAU - 0.2, 14, Color(tone.lightened(0.25), 0.8), 2.0, true)
	draw_arc(p, r - 6, 0.3, 2.6, 12, Color(tone.darkened(0.25), 0.6), 1.2, true)
	var ring := disc.duplicate()
	ring.append(disc[0])
	draw_polyline(Figure.clean_line(ring), INK, 2.2, true)


## Unscouted country: a smudged wash over stops nobody has seen yet.
func _draw_fog() -> void:
	for n in run.nodes:
		if MapGen.intel(n) > 0 or n.visited:
			continue
		var rng := _rng(500 + int(n.id))
		var p := node_pos(n)
		for k in 6:
			var o := Vector2(rng.randf_range(-34, 34), rng.randf_range(-26, 26))
			draw_circle(p + o, rng.randf_range(22, 36), Color(SHEET.r, SHEET.g, SHEET.b, 0.34))


func _draw_token() -> void:
	var at := node_pos(run.current_node())
	if token_to >= 0:
		var t := token_t * token_t * (3.0 - 2.0 * token_t)
		at = at.lerp(node_pos(run.node(token_to)), t)
	var bob := absf(sin(_t * 10.0)) * 2.0 if token_to >= 0 else 0.0
	var p := at + Vector2(0, -R - 16 - bob)
	draw_colored_polygon(PackedVector2Array(Figure.ellipse(p + Vector2(2, 14), 20, 4, 12)), Color(0, 0, 0, 0.25))
	draw_rect(Rect2(p + Vector2(-17, 2), Vector2(34, 8)), Color("#7a5232"))
	draw_rect(Rect2(p + Vector2(-17, 2), Vector2(34, 8)), INK, false, 1.5)
	var bonnet := PackedVector2Array(Figure.ellipse(p + Vector2(0, 2), 16, 14, 14, PI, TAU))
	draw_colored_polygon(bonnet, Color("#f3ead6"))
	var bl := bonnet.duplicate()
	bl.append(bonnet[0])
	draw_polyline(Figure.clean_line(bl), INK, 1.5, true)
	for hx in [-7.0, 0.0, 7.0]:
		draw_line(p + Vector2(hx, 2), p + Vector2(hx * 0.9, -10 + absf(hx) * 0.3), Color(INK, 0.5), 1.0, true)
	for wx in [-10.0, 10.0]:
		var wc := p + Vector2(wx, 11)
		draw_circle(wc, 5.0, Color("#3a2618"))
		draw_arc(wc, 5.0, 0, TAU, 12, INK, 1.2, true)
		draw_circle(wc, 1.5, Color("#c9a26a"))


func _draw_legend() -> void:
	var r := _legend_rect()
	draw_rect(Rect2(r.position + Vector2(3, 4), r.size), Color(0, 0, 0, 0.18))
	draw_rect(r, Color("#f6ecd6"))
	draw_rect(r, Color(INK, 0.6), false, 1.5)
	_nail(r.position + Vector2(10, r.size.y / 2))
	_nail(r.end - Vector2(10, r.size.y / 2))
	var f: Font = UI.font_body
	var x := r.position.x + 24
	var y := r.position.y + 22
	for part in [["?", Color(INK, 0.55)], [" unknown    ", INK], ["?", Color("#a8392e")], [" signs of trouble    ", INK],
			["?", Color("#4f7a33")], [" looks quiet    ", INK], ["Hover a stop for details.", Color(INK, 0.75)]]:
		var bold: bool = part[0] == "?"
		var font: Font = UI.font_bold if bold else f
		draw_string(font, Vector2(x, y), part[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, part[1])
		x += font.get_string_size(part[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x


## "Onward": a signpost pointing the way the trail runs.
func _draw_signpost() -> void:
	var r := _sign_rect()
	var post_x := r.position.x + 30
	draw_rect(Rect2(post_x - 4, r.position.y + 8, 9, size.y - r.position.y - 8), Color("#5e3f27"))
	draw_rect(Rect2(post_x - 4, r.position.y + 8, 9, size.y - r.position.y - 8), INK, false, 1.2)
	var board := PackedVector2Array([r.position, Vector2(r.end.x - 22, r.position.y), Vector2(r.end.x, r.position.y + r.size.y / 2),
		Vector2(r.end.x - 22, r.end.y), Vector2(r.position.x, r.end.y)])
	var sh := PackedVector2Array()
	for p in board:
		sh.append(p + Vector2(3, 4))
	draw_colored_polygon(sh, Color(0, 0, 0, 0.25))
	draw_colored_polygon(board, Color("#8a6038"))
	draw_line(r.position + Vector2(4, 8), Vector2(r.end.x - 26, r.position.y + 8), Color("#a47a4c"), 1.0, true)
	draw_line(r.position + Vector2(4, r.size.y - 9), Vector2(r.end.x - 26, r.end.y - 9), Color("#6e4a2c"), 1.0, true)
	var bl := board.duplicate()
	bl.append(board[0])
	draw_polyline(Figure.clean_line(bl), INK, 2.0, true)
	_nail(r.position + Vector2(30, r.size.y / 2))
	draw_string(UI.font_head, r.position + Vector2(50, 29), "ONWARD", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#2a1a10"))


func node_pos(n: Dictionary) -> Vector2:
	var cols := MapGen.column_count(run.nodes) if run != null else MapGen.COLUMNS
	var x := 90.0 + float(n.col) * (size.x - 180.0) / float(cols - 1)
	var y := 40.0 + float(n.y) * (size.y - 80.0)
	return Vector2(x, y)


func _gui_input(event: InputEvent) -> void:
	if run == null:
		return
	if event is InputEventMouseMotion:
		var h := _node_at(event.position)
		if h != hover:
			hover = h
			tooltip_text = _tip(h) if h >= 0 else ""
			var clickable := h >= 0 and enabled and h in run.choices()
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if clickable else Control.CURSOR_ARROW
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var h2 := _node_at(event.position)
		if h2 >= 0 and enabled and h2 in run.choices():
			node_clicked.emit(h2)


func _node_at(p: Vector2) -> int:
	for n in run.nodes:
		if node_pos(n).distance_to(p) <= R + 6:
			return n.id
	return -1


func _tip(id: int) -> String:
	var n := run.node(id)
	var lvl := MapGen.intel(n)
	var go := "\n(Click to travel here)" if id in run.choices() else ""
	if lvl == 0:
		return "Unknown\nToo far to make out. Scouts (the Scout skill, a spyglass, a Trailwise hero) see further and clearer." + go
	if lvl == 1:
		match MapGen.vague_kind(n):
			"danger":
				return "Signs of Trouble\nTracks, smoke, a glint of metal. Probably a fight, but you can't be sure." + go
			"cave":
				return "A Dark Opening\nLooks like a cave in the hillside." + go
		return "Looks Quiet\nNothing obvious this way. Could be anything." + go
	var t: String = MapGen.TYPE_NAMES.get(n.type, n.type)
	match n.type:
		"fight", "elite":
			if lvl >= 3:
				t += "\n" + ", ".join(n.data.enemies.map(func(e): return DB.enemy(e).get("name", e)))
			else:
				t += "\nYou can't tell who's waiting. (A Tracker reads the signs.)"
			if n.data.has("curios"):
				t += "\nSomething worth searching lies nearby, once the fight is done."
		"boss":
			t += ": " + run.region().boss.name + "\nRecommended level " + str(run.region().get("rec_level", "?")) + ". No retreat."
		"crossing":
			t += ": " + run.region().crossing.name
		"cave":
			t += ": " + n.data.get("name", "")
		"event", "homestead":
			t += ": " + DB.events.get(n.data.event, {}).get("title", "")
	return t + go


func _draw() -> void:
	if run == null:
		return
	_draw_sheet()
	_draw_terrain()
	# Trails: dotted ink until travelled, then a solid line. The ways on from here march.
	var choices := run.choices()
	for n in run.nodes:
		for nx in n.next:
			var m := run.node(nx)
			var pts := _trail_pts(node_pos(n), node_pos(m), int(n.id) * 97 + int(nx))
			var travelled: bool = n.visited and m.visited
			if travelled:
				draw_polyline(Figure.clean_line(pts), Color("#4a2f1c"), 4.0, true)
				continue
			var ahead: bool = n.id == run.current and nx in choices and enabled
			var col := Color(0.3, 0.2, 0.12, 0.85) if ahead else Color(0.35, 0.25, 0.16, 0.45)
			var total := 0.0
			var shift := fmod(_t * 18.0, 12.0) if ahead else 0.0
			for i in range(1, pts.size()):
				var a: Vector2 = pts[i - 1]
				var b: Vector2 = pts[i]
				var seg := a.distance_to(b)
				var d := fmod(12.0 - fmod(total - shift, 12.0), 12.0)
				while d < seg:
					draw_circle(a.lerp(b, d / seg), 2.6 if ahead else 2.0, col)
					d += 12.0
				total += seg
	for n in run.nodes:
		var p := node_pos(n)
		var is_choice: bool = n.id in choices and enabled
		var r := R * (1.35 if n.type in ["boss", "crossing"] else 1.0)
		if is_choice:
			var pulse := 0.5 + 0.5 * sin(_t * 4.0)
			draw_circle(p, r + 12 + pulse * 4, Color(1, 0.8, 0.3, 0.35))
		if n.id == hover and is_choice:
			draw_circle(p, r + 10, Color(1, 0.9, 0.5, 0.7))
		draw_circle(p + Vector2(4, 5), r + 1, Color(0, 0, 0, 0.28))
		var lvl := MapGen.intel(n)
		var tone := OAK
		if lvl == 0:
			tone = Color("#e6d5b0")
		if n.visited and n.id != run.current:
			tone = Color("#b59f7e")
		_disc(p, r, int(n.id), tone, lvl >= 2 and n.type in ["elite", "boss"])
		var kind: String = n.type
		if lvl == 0:
			kind = "hidden"
		elif lvl == 1:
			kind = "vague_" + MapGen.vague_kind(n)
		_icon(kind, p, r, n.visited and n.id != run.current)
	_draw_fog()
	_draw_legend()
	_draw_signpost()
	_draw_token()


func _icon(kind: String, p: Vector2, r: float, faded: bool) -> void:
	var ink := Color("#2a1d14") if not faded else Color("#2a1d14", 0.45)
	var red := Color("#a8392e") if not faded else Color("#a8392e", 0.45)
	var s := r / 30.0
	match kind:
		"start":
			draw_circle(p, 14 * s, ink)
			draw_circle(p, 8 * s, Color("#d9c7a0"))
			for i in 6:
				var a := i * TAU / 6
				draw_line(p, p + Vector2(cos(a), sin(a)) * 12 * s, ink, 2)
		"fight":
			draw_line(p + Vector2(-14, -14) * s, p + Vector2(14, 14) * s, red, 5 * s)
			draw_line(p + Vector2(14, -14) * s, p + Vector2(-14, 14) * s, red, 5 * s)
			draw_line(p + Vector2(-16, 8) * s, p + Vector2(-8, 16) * s, ink, 6 * s)
			draw_line(p + Vector2(16, 8) * s, p + Vector2(8, 16) * s, ink, 6 * s)
		"elite", "boss":
			draw_circle(p + Vector2(0, -4) * s, 14 * s, red if kind == "boss" else ink)
			draw_rect(Rect2(p + Vector2(-8, 6) * s, Vector2(16, 8) * s), red if kind == "boss" else ink)
			draw_circle(p + Vector2(-5, -5) * s, 4 * s, Color("#d9c7a0"))
			draw_circle(p + Vector2(5, -5) * s, 4 * s, Color("#d9c7a0"))
			if kind == "boss":
				draw_colored_polygon(PackedVector2Array([p + Vector2(-14, -16) * s, p + Vector2(-10, -30) * s, p + Vector2(-4, -20) * s, p + Vector2(0, -32) * s, p + Vector2(4, -20) * s, p + Vector2(10, -30) * s, p + Vector2(14, -16) * s]), Color("#e0bd4f"))
		"crossing":
			draw_arc(p + Vector2(0, 10) * s, 18 * s, PI, TAU, 16, ink, 5 * s)
			draw_line(p + Vector2(-22, 10) * s, p + Vector2(22, 10) * s, ink, 5 * s)
		"event":
			draw_string(UI.font_head, p + Vector2(-7, 13) * s, "!", HORIZONTAL_ALIGNMENT_LEFT, -1, int(36 * s), ink)
		"hidden":
			draw_string(UI.font_head, p + Vector2(-10, 13) * s, "?", HORIZONTAL_ALIGNMENT_LEFT, -1, int(36 * s), Color(ink, 0.55))
		"vague_danger":
			draw_line(p + Vector2(-12, -12) * s, p + Vector2(12, 12) * s, Color(red, 0.3), 4 * s)
			draw_line(p + Vector2(12, -12) * s, p + Vector2(-12, 12) * s, Color(red, 0.3), 4 * s)
			draw_string(UI.font_head, p + Vector2(-10, 13) * s, "?", HORIZONTAL_ALIGNMENT_LEFT, -1, int(34 * s), red)
		"vague_quiet":
			draw_string(UI.font_head, p + Vector2(-10, 13) * s, "?", HORIZONTAL_ALIGNMENT_LEFT, -1, int(34 * s), Color("#4f7a33"))
		"vague_cave":
			draw_circle(p + Vector2(0, 6) * s, 16 * s, Color(ink, 0.4))
			draw_rect(Rect2(p + Vector2(-16, 6) * s, Vector2(32, 10) * s), Color(ink, 0.4))
			draw_string(UI.font_head, p + Vector2(-8, 10) * s, "?", HORIZONTAL_ALIGNMENT_LEFT, -1, int(26 * s), Color("#f3e9d2"))
		"curio":
			draw_rect(Rect2(p + Vector2(-15, -4) * s, Vector2(30, 18) * s), Color("#8a5a32") if not faded else Color("#8a5a32", 0.5))
			draw_rect(Rect2(p + Vector2(-15, -14) * s, Vector2(30, 10) * s), Color("#6b4426") if not faded else Color("#6b4426", 0.5))
			draw_rect(Rect2(p + Vector2(-3, -6) * s, Vector2(6, 8) * s), Color("#e0bd4f"))
		"cave":
			draw_circle(p + Vector2(0, 6) * s, 16 * s, ink)
			draw_rect(Rect2(p + Vector2(-16, 6) * s, Vector2(32, 10) * s), ink)
		"trading_post":
			draw_circle(p, 15 * s, Color("#b8322a"))
			for i in 6:
				var a := i * TAU / 6.0
				draw_line(p + Vector2(cos(a), sin(a)) * 9 * s, p + Vector2(cos(a), sin(a)) * 15 * s, Color("#f3e9d2"), 3 * s)
			draw_circle(p, 7 * s, Color("#f3e9d2"))
		"homestead":
			draw_colored_polygon(PackedVector2Array([p + Vector2(-16, -2) * s, p + Vector2(0, -18) * s, p + Vector2(16, -2) * s]), red)
			draw_rect(Rect2(p + Vector2(-12, -2) * s, Vector2(24, 18) * s), ink)
		"camp":
			# A campfire: two crossed logs under a flame.
			var logc := Color("#5e3f27") if not faded else Color("#5e3f27", 0.5)
			draw_line(p + Vector2(-15, 14) * s, p + Vector2(13, 5) * s, logc, 6 * s)
			draw_line(p + Vector2(15, 14) * s, p + Vector2(-13, 5) * s, logc, 6 * s)
			var flame := PackedVector2Array([p + Vector2(-9, 8) * s, p + Vector2(-8, -4) * s, p + Vector2(-2, -8) * s, p + Vector2(0, -18) * s,
				p + Vector2(5, -8) * s, p + Vector2(9, -3) * s, p + Vector2(9, 8) * s])
			draw_colored_polygon(flame, Color("#e07a1f") if not faded else Color("#e07a1f", 0.5))
			draw_colored_polygon(PackedVector2Array([p + Vector2(-4, 8) * s, p + Vector2(-3, 0) * s, p + Vector2(1, -8) * s, p + Vector2(4, 0) * s, p + Vector2(4, 8) * s]), Color("#f2c14e") if not faded else Color("#f2c14e", 0.5))
