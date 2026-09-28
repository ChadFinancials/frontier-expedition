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


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func node_pos(n: Dictionary) -> Vector2:
	var cols := MapGen.COLUMNS
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
	if n.hidden:
		return "Unknown\nSomething lies this way. A Scout would know what."
	var t: String = MapGen.TYPE_NAMES.get(n.type, n.type)
	match n.type:
		"fight", "elite":
			t += "\n" + ", ".join(n.data.enemies.map(func(e): return DB.enemy(e).get("name", e)))
		"boss":
			t += ": " + run.region().boss.name
		"crossing":
			t += ": " + run.region().crossing.name
		"cave":
			t += ": " + n.data.get("name", "")
		"event", "homestead":
			t += ": " + DB.events.get(n.data.event, {}).get("title", "")
	if id in run.choices():
		t += "\n(Click to travel here)"
	return t


func _draw() -> void:
	if run == null:
		return
	# Paths.
	for n in run.nodes:
		for nx in n.next:
			var m := run.node(nx)
			var a := node_pos(n)
			var b := node_pos(m)
			var travelled: bool = n.visited and m.visited
			var col := Color("#6b4a2e") if travelled else Color(0.35, 0.25, 0.16, 0.45)
			var dashes := int(a.distance_to(b) / 16)
			for i in dashes:
				if i % 2 == 0:
					draw_line(a.lerp(b, i / float(dashes)), a.lerp(b, (i + 1) / float(dashes)), col, 4.0 if travelled else 3.0)
	var choices := run.choices()
	for n in run.nodes:
		var p := node_pos(n)
		var is_choice: bool = n.id in choices and enabled
		var r := R * (1.35 if n.type in ["boss", "crossing"] else 1.0)
		if is_choice:
			var pulse := 0.5 + 0.5 * sin(_t * 4.0)
			draw_circle(p, r + 10 + pulse * 4, Color(1, 0.8, 0.3, 0.35))
		if n.id == hover and is_choice:
			draw_circle(p, r + 8, Color(1, 0.9, 0.5, 0.7))
		draw_circle(p + Vector2(4, 5), r, Color(0, 0, 0, 0.3))
		draw_circle(p, r + 3, Color("#f3e9d2"))
		var bg := Color("#d9c7a0")
		if n.visited:
			bg = Color("#a89878")
		draw_circle(p, r, bg)
		draw_arc(p, r, 0, TAU, 32, Color("#5e3f27"), 2.5)
		_icon("hidden" if n.hidden else n.type, p, r, n.visited and n.id != run.current)
		if n.id == run.current:
			draw_arc(p, r + 6, 0, TAU, 40, Color("#e0bd4f"), 4.0)
	# Column legend: west arrow.
	draw_string(UI.font_head, Vector2(size.x - 260, size.y - 10), "WEST  →", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.35, 0.25, 0.16, 0.7))


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
			draw_string(UI.font_head, p + Vector2(-10, 13) * s, "?", HORIZONTAL_ALIGNMENT_LEFT, -1, int(36 * s), ink)
		"curio":
			draw_rect(Rect2(p + Vector2(-15, -4) * s, Vector2(30, 18) * s), Color("#8a5a32") if not faded else Color("#8a5a32", 0.5))
			draw_rect(Rect2(p + Vector2(-15, -14) * s, Vector2(30, 10) * s), Color("#6b4426") if not faded else Color("#6b4426", 0.5))
			draw_rect(Rect2(p + Vector2(-3, -6) * s, Vector2(6, 8) * s), Color("#e0bd4f"))
		"cave":
			draw_circle(p + Vector2(0, 6) * s, 16 * s, ink)
			draw_rect(Rect2(p + Vector2(-16, 6) * s, Vector2(32, 10) * s), ink)
		"trading_post":
			draw_string(UI.font_head, p + Vector2(-9, 12) * s, "$", HORIZONTAL_ALIGNMENT_LEFT, -1, int(32 * s), Color("#6b4f10"))
		"homestead":
			draw_colored_polygon(PackedVector2Array([p + Vector2(-16, -2) * s, p + Vector2(0, -18) * s, p + Vector2(16, -2) * s]), red)
			draw_rect(Rect2(p + Vector2(-12, -2) * s, Vector2(24, 18) * s), ink)
		"camp":
			draw_colored_polygon(PackedVector2Array([p + Vector2(-18, 14) * s, p + Vector2(0, -16) * s, p + Vector2(18, 14) * s]), Color("#e8dcc0") if not faded else Color("#e8dcc0", 0.5))
			draw_line(p + Vector2(-18, 14) * s, p + Vector2(0, -16) * s, ink, 2)
			draw_line(p + Vector2(18, 14) * s, p + Vector2(0, -16) * s, ink, 2)
			draw_colored_polygon(PackedVector2Array([p + Vector2(-5, 14) * s, p + Vector2(0, 2) * s, p + Vector2(5, 14) * s]), Color("#e07a1f"))
