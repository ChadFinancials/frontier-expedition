class_name TownView
extends Control
## The painted settlement street: one clickable building per plot, drawn paper-cutout
## style over the region backdrop. Emits building_clicked(id) ("" = empty plot).

signal building_clicked(bid: String)

const PAPER := Color("#f3e9d2")
const PLOT_W := 250.0

var plots: Array = []      # [{"id": building id or "", "rect": Rect2, "level": int}]
var hover := -1
var street_y := 700.0
var paper := false         # paper-theater street: two staggered depths, props, palisade
var _t := 0.0


func set_buildings(buildings: Dictionary, slots: int, ruins: Array = []) -> void:
	plots.clear()
	var ids: Array = buildings.keys() + ruins.filter(func(r): return not buildings.has(r))
	ids.sort_custom(func(a, b): return DB.buildings[a].get("order", 0) < DB.buildings[b].get("order", 0))
	for i in maxi(slots, ids.size()):
		var bid: String = ids[i] if i < ids.size() else ""
		plots.append({"id": bid, "level": int(buildings.get(bid, 0)) if bid != "" else 0, "ruin": bid != "" and not buildings.has(bid)})
	_layout()
	queue_redraw()


func _layout() -> void:
	if paper:
		_layout_paper()
		return
	var n := plots.size()
	var per_row := mini(n, 6) if n <= 6 else 5
	var rows := int(ceil(n / float(maxi(1, per_row)))) if n > 0 else 1
	var pw := minf(PLOT_W, (size.x - 20) / maxf(1, per_row))
	for i in n:
		var row := i / per_row
		var col := i % per_row
		var count_in_row := mini(per_row, n - row * per_row)
		var total_w := count_in_row * pw
		var x0 := (size.x - total_w) / 2.0
		var y := street_y - (rows - 1 - row) * 250.0
		plots[i].rect = Rect2(x0 + col * pw + 6, y - 230, pw - 12, 230)


## Plots alternate between a back row (smaller, up the street) and a front row, like a
## little diorama town.
func _layout_paper() -> void:
	var n := plots.size()
	for i in n:
		var back := n > 1 and i % 2 == 0
		var s := 0.8 if back else 1.0
		var x := size.x * (i + 0.5) / maxf(1, n)
		var base_y := street_y - (84.0 if back else 0.0)
		plots[i]["scale"] = s
		plots[i]["back"] = back
		plots[i].rect = Rect2(x - 110 * s, base_y - 235 * s, 220 * s, 235 * s)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var h := _plot_at(event.position)
		if h != hover:
			hover = h
			var tip := ""
			if h >= 0:
				var bid: String = plots[h].id
				if bid == "":
					tip = "Empty plot: click to build"
				elif plots[h].ruin:
					tip = "Burned %s: click to rebuild at a discount" % DB.buildings[bid].name
				else:
					tip = "%s (level %d)\n%s" % [DB.buildings[bid].name, plots[h].level, DB.buildings[bid].desc]
			tooltip_text = tip
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if h >= 0 else Control.CURSOR_ARROW
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var h2 := _plot_at(event.position)
		if h2 >= 0:
			Audio.play("click", 0.6)
			building_clicked.emit(plots[h2].id)


func _plot_at(p: Vector2) -> int:
	for i in plots.size():
		if plots[i].rect.has_point(p):
			return i
	return -1


# --- Drawing --------------------------------------------------------------------------

func _poly(pts: Array, c: Color, edge: bool = true) -> void:
	var p := PackedVector2Array(pts)
	var sh := PackedVector2Array()
	for q in p:
		sh.append(q + Vector2(6, 7))
	draw_colored_polygon(sh, Color(0, 0, 0, 0.3))
	if edge:
		var closed := p.duplicate()
		closed.append(p[0])
		draw_polyline(closed, PAPER, 7.0, true)
	draw_colored_polygon(p, c)


func _rect(r: Rect2, c: Color, edge: bool = true) -> void:
	_poly([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)], c, edge)


func _sign(center: Vector2, text: String, w: float, c: Color = Color("#2e2118")) -> void:
	var r := Rect2(center - Vector2(w / 2, 16), Vector2(w, 32))
	_rect(r, c)
	var fs := 20
	var tw := UI.font_head.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	if tw > w - 10:
		fs = int(fs * (w - 10) / tw)
		tw = UI.font_head.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(UI.font_head, Vector2(center.x - tw / 2, center.y + fs * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#f1d38a"))


func _window(p: Vector2, lit: bool = true) -> void:
	draw_rect(Rect2(p, Vector2(26, 32)), Color("#2a1d14"))
	draw_rect(Rect2(p + Vector2(3, 3), Vector2(20, 26)), Color("#f2c46b") if lit else Color("#4a5a6a"))
	draw_line(p + Vector2(13, 3), p + Vector2(13, 29), Color("#2a1d14"), 2)
	draw_line(p + Vector2(3, 16), p + Vector2(23, 16), Color("#2a1d14"), 2)


func _draw() -> void:
	if paper:
		_draw_paper()
		return
	# Boardwalk / street.
	draw_rect(Rect2(0, street_y, size.x, 26), Color("#6b4a2e"))
	for i in int(size.x / 40):
		draw_line(Vector2(i * 40, street_y), Vector2(i * 40, street_y + 26), Color("#4a3322"), 2)
	for i in plots.size():
		var pl: Dictionary = plots[i]
		var r: Rect2 = pl.rect
		if i == hover:
			draw_rect(r.grow(8), Color(1, 0.85, 0.4, 0.18))
		var base := Vector2(r.position.x + r.size.x / 2, r.end.y)
		var bid: String = pl.id
		if bid == "":
			_draw_empty(base)
		elif pl.get("ruin", false):
			_draw_ruin(base, DB.buildings[bid].name, i)
		else:
			_draw_building(DB.buildings[bid].get("art", "store"), base, int(pl.level), DB.buildings[bid].name)
		if i == hover:
			draw_rect(r.grow(8), Color(1, 0.85, 0.4, 0.8), false, 3)


func _draw_plot(i: int) -> void:
	var pl: Dictionary = plots[i]
	var r: Rect2 = pl.rect
	var s: float = pl.get("scale", 1.0)
	var base := Vector2(r.position.x + r.size.x / 2, r.end.y)
	if i == hover:
		draw_rect(r.grow(8), Color(1, 0.85, 0.4, 0.18))
	draw_set_transform(base * (1.0 - s), 0.0, Vector2(s, s))
	var bid: String = pl.id
	if bid == "":
		_draw_empty(base)
	elif pl.get("ruin", false):
		_draw_ruin(base, DB.buildings[bid].name, i)
	else:
		_draw_building(DB.buildings[bid].get("art", "store"), base, int(pl.level), DB.buildings[bid].name)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if i == hover:
		draw_rect(r.grow(8), Color(1, 0.85, 0.4, 0.8), false, 3)


func _draw_paper() -> void:
	var w := size.x
	# The fort's palisade and a few cottonwoods behind the town.
	var pal_y := street_y - 190.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	# One cut sheet for the palisade, with the log seams drawn on it.
	var top_pts: Array = [Vector2(-10, pal_y + 90)]
	var seams: Array = []
	var x := -10.0
	var burnt_spans: Array = []
	while x < w + 20:
		var lw := rng.randf_range(34, 44)
		var lh := rng.randf_range(80, 104)
		top_pts.append(Vector2(x, pal_y + 90 - lh + 14))
		top_pts.append(Vector2(x + lw / 2, pal_y + 90 - lh))
		top_pts.append(Vector2(x + lw, pal_y + 90 - lh + 14))
		seams.append(Vector2(x + lw, pal_y + 90 - lh + 14))
		if rng.randf() < 0.2:
			burnt_spans.append(Rect2(x, pal_y + 90 - lh, lw, lh))
		x += lw
	top_pts.append(Vector2(x, pal_y + 90))
	_poly(top_pts, Color("#6d5236"))
	for sp in seams:
		draw_line(sp, Vector2(sp.x, pal_y + 90), Color("#4f3a26"), 2.5, true)
	for br in burnt_spans:
		draw_rect(br, Color(0.14, 0.1, 0.08, 0.55))
	for k in 5:
		var tx := rng.randf_range(40, w - 40)
		draw_line(Vector2(tx, pal_y + 60), Vector2(tx, pal_y - 20), Color("#5a3f2a"), 9)
		for j in 3:
			_circle_paper(Vector2(tx + (j - 1) * 26, pal_y - 40 - (j % 2) * 20), 34, Color("#5e7440").darkened(rng.randf_range(0, 0.15)))
	# Back row, then a light haze so it sits further away.
	for i in plots.size():
		if plots[i].get("back", false):
			_draw_plot(i)
	draw_rect(Rect2(0, pal_y - 60, w, street_y - pal_y - 10), Color(0.96, 0.9, 0.76, 0.16))
	# The street: packed dirt with wheel ruts, and a boardwalk along the front row.
	_poly([Vector2(-10, street_y - 64), Vector2(w + 10, street_y - 64), Vector2(w + 10, street_y + 40), Vector2(-10, street_y + 40)], Color("#8a6a45"))
	for k in 2:
		var ry := street_y - 40 + k * 22
		draw_line(Vector2(0, ry), Vector2(w, ry + 6), Color("#6b5035"), 3, true)
	for k in 40:
		var px := rng.randf_range(0, w)
		var py := rng.randf_range(street_y - 60, street_y + 30)
		draw_line(Vector2(px, py), Vector2(px + rng.randf_range(8, 22), py), Color("#76593a"), 2, true)
	for i in plots.size():
		if not plots[i].get("back", false):
			_draw_plot(i)
	# Foreground props along the front edge of the stage.
	rng.seed = 29
	var props := ["barrel", "crate", "lamp", "barrel", "trough", "crate", "lamp", "hitch"]
	for k in props.size():
		var fx := w * (k + 0.5) / props.size() + rng.randf_range(-30, 30)
		_prop(props[k], Vector2(fx, street_y + 34))


func _circle_paper(p: Vector2, r: float, c: Color) -> void:
	draw_circle(p + Vector2(4, 5), r, Color(0, 0, 0, 0.22))
	draw_circle(p, r + 3, PAPER)
	draw_circle(p, r, c)


func _prop(kind: String, b: Vector2) -> void:
	match kind:
		"barrel":
			_poly([b + Vector2(-16, 0), b + Vector2(16, 0), b + Vector2(19, -22), b + Vector2(16, -44), b + Vector2(-16, -44), b + Vector2(-19, -22)], Color("#8a5a32"))
			draw_line(b + Vector2(-18, -12), b + Vector2(18, -12), Color("#3c3f44"), 3)
			draw_line(b + Vector2(-18, -32), b + Vector2(18, -32), Color("#3c3f44"), 3)
		"crate":
			_rect(Rect2(b + Vector2(-22, -40), Vector2(44, 40)), Color("#a8834e"))
			draw_line(b + Vector2(-22, -40), b + Vector2(22, 0), Color("#7a5a32"), 3)
			draw_line(b + Vector2(22, -40), b + Vector2(-22, 0), Color("#7a5a32"), 3)
		"lamp":
			draw_line(b, b + Vector2(0, -110), Color("#2e2a26"), 6)
			_rect(Rect2(b + Vector2(-11, -134), Vector2(22, 26)), Color("#f2c46b"))
			var g := 0.5 + 0.5 * sin(_t * 3.0 + b.x)
			draw_circle(b + Vector2(0, -121), 30, Color(1, 0.8, 0.4, 0.08 + 0.05 * g))
		"trough":
			_poly([b + Vector2(-34, 0), b + Vector2(34, 0), b + Vector2(40, -24), b + Vector2(-40, -24)], Color("#7a5a38"))
			draw_rect(Rect2(b + Vector2(-34, -24), Vector2(68, 6)), Color("#6f9fbf"))
		"hitch":
			draw_line(b + Vector2(-40, 0), b + Vector2(-40, -36), Color("#6b4426"), 7)
			draw_line(b + Vector2(40, 0), b + Vector2(40, -36), Color("#6b4426"), 7)
			draw_line(b + Vector2(-46, -32), b + Vector2(46, -32), Color("#7a5232"), 7)


func _draw_empty(b: Vector2) -> void:
	for x in [-70.0, 70.0]:
		draw_line(b + Vector2(x, 0), b + Vector2(x, -40), Color("#7a5232"), 6)
	draw_line(b + Vector2(-70, -34), b + Vector2(70, -34), Color("#c8a46a"), 3)
	_sign(b + Vector2(0, -90), "Empty Plot", 150, Color("#5e3f27"))
	draw_string(UI.font_bold, b + Vector2(-46, -50), "+ Build", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#f3e9d2"))


## A burned-out building: charred posts, a fallen beam, a heap of ash and a thread of smoke.
func _draw_ruin(b: Vector2, bname: String, seed_i: int) -> void:
	var char_c := Color("#2b2320")
	_poly([b + Vector2(-95, 0), b + Vector2(-60, -22), b + Vector2(10, -30), b + Vector2(80, -18), b + Vector2(100, 0)], Color("#3d3530"))
	_rect(Rect2(b + Vector2(-86, -150), Vector2(14, 150)), char_c)
	_poly([b + Vector2(-20, 0), b + Vector2(-18, -118), b + Vector2(-6, -104), b + Vector2(-4, 0)], char_c)
	_rect(Rect2(b + Vector2(66, -96), Vector2(14, 96)), char_c)
	_poly([b + Vector2(-92, -148), b + Vector2(-78, -160), b + Vector2(76, -70), b + Vector2(66, -58)], Color("#3a2c24"))
	for k in 5:
		var e := b + Vector2(-60 + k * 28, -12 - (k % 2) * 6)
		var glow := 0.5 + 0.5 * sin(_t * 2.0 + k * 1.7 + seed_i)
		draw_circle(e, 4, Color(0.95, 0.45, 0.15, 0.35 + glow * 0.4))
	for k in 4:
		var ph := fmod(_t * 0.35 + k * 0.25 + seed_i * 0.13, 1.0)
		var p := b + Vector2(-10 + sin(ph * 6.0 + k) * 16, -60 - ph * 150)
		draw_circle(p, 10 + ph * 22, Color(0.45, 0.42, 0.4, 0.35 * (1.0 - ph)))
	_sign(b + Vector2(0, -190), "Burned " + bname, 200, Color("#4a3a32"))
	draw_rect(Rect2(b + Vector2(-58, -64), Vector2(116, 34)), Color(0.12, 0.08, 0.06, 0.85))
	draw_string(UI.font_bold, b + Vector2(-44, -40), "Rebuild", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#f1d38a"))


func _draw_building(art: String, b: Vector2, level: int, bname: String) -> void:
	var wood := Color("#8a5a32")
	var wood2 := Color("#6b4426")
	var lvl_scale := 0.86 + 0.07 * level
	var w := minf(190.0 * lvl_scale, (plots[0].rect.size.x if not plots.is_empty() else 200.0) - 16)
	var h := 150.0 * lvl_scale
	match art:
		"saloon":
			_rect(Rect2(b.x - w / 2, b.y - h, w, h), Color("#9c5b34"))
			_rect(Rect2(b.x - w / 2 - 6, b.y - h - 40, w + 12, 48), Color("#b56b3a"))
			_sign(b + Vector2(0, -h - 16), "SALOON", w - 30)
			_window(b + Vector2(-w / 2 + 16, -h + 30))
			_window(b + Vector2(w / 2 - 42, -h + 30))
			_rect(Rect2(b.x - 22, b.y - 58, 20, 36), Color("#5a3822"))
			_rect(Rect2(b.x + 2, b.y - 58, 20, 36), Color("#5a3822"))
		"chapel":
			_poly([b + Vector2(-w / 2, 0), b + Vector2(w / 2, 0), b + Vector2(w / 2, -h * 0.75), b + Vector2(0, -h * 1.15), b + Vector2(-w / 2, -h * 0.75)], Color("#e6dfcf"))
			_rect(Rect2(b.x - 20, b.y - h * 1.5, 40, h * 0.4), Color("#e6dfcf"))
			_poly([b + Vector2(-26, -h * 1.5), b + Vector2(26, -h * 1.5), b + Vector2(0, -h * 1.85)], Color("#5e3f27"))
			draw_line(b + Vector2(0, -h * 1.85), b + Vector2(0, -h * 2.05), Color("#2a1d14"), 5)
			draw_line(b + Vector2(-10, -h * 1.98), b + Vector2(10, -h * 1.98), Color("#2a1d14"), 5)
			_rect(Rect2(b.x - 18, b.y - 64, 36, 64), Color("#6b4426"))
			draw_circle(b + Vector2(0, -h * 0.72), 16, Color("#8fb3d9"))
		"doctor":
			_poly([b + Vector2(-w / 2, 0), b + Vector2(w / 2, 0), b + Vector2(w / 2, -h * 0.8), b + Vector2(0, -h * 1.1), b + Vector2(-w / 2, -h * 0.8)], Color("#d8cfc0"))
			_sign(b + Vector2(0, -h * 0.62), "DOCTOR", w * 0.7, Color("#7a2a22"))
			_window(b + Vector2(-w / 2 + 16, -h * 0.45))
			_rect(Rect2(b.x + 20, b.y - 60, 34, 60), Color("#5a3822"))
			draw_rect(Rect2(b.x - 42, b.y - 52, 26, 8), Color("#b8372d"))
			draw_rect(Rect2(b.x - 33, b.y - 61, 8, 26), Color("#b8372d"))
		"smithy":
			_rect(Rect2(b.x - w / 2, b.y - h * 0.8, w, h * 0.8), wood2)
			_poly([b + Vector2(-w / 2 - 14, -h * 0.8), b + Vector2(w / 2 + 14, -h * 0.8), b + Vector2(w / 2, -h * 1.05), b + Vector2(-w / 2, -h * 1.05)], Color("#4a3322"))
			_rect(Rect2(b.x + w / 2 - 44, b.y - h * 1.5, 30, h * 0.7), Color("#6e6660"))
			for k in 3:
				var sy := b.y - h * 1.55 - k * 28 - fmod(_t * 18, 28)
				draw_circle(Vector2(b.x + w / 2 - 29 + sin(_t + k) * 6, sy), 12 + k * 4, Color(0.8, 0.8, 0.8, 0.3 - k * 0.08))
			draw_rect(Rect2(b.x - w / 2 + 16, b.y - h * 0.7, w - 70, h * 0.62), Color("#2a1d14"))
			draw_circle(b + Vector2(-20, -40), 22 + sin(_t * 5) * 2, Color(1, 0.5, 0.15, 0.6))
			_poly([b + Vector2(-60, -24), b + Vector2(0, -24), b + Vector2(-8, -34), b + Vector2(-52, -34)], Color("#3c3f44"))
			_sign(b + Vector2(0, -h * 0.9), "SMITHY", w * 0.6)
		"drill":
			_rect(Rect2(b.x - w / 2, b.y - h * 0.75, w, h * 0.75), Color("#6d7a52"))
			_poly([b + Vector2(-w / 2 - 8, -h * 0.75), b + Vector2(w / 2 + 8, -h * 0.75), b + Vector2(0, -h * 1.05)], Color("#4b5638"))
			draw_line(b + Vector2(w / 2 - 10, -h * 0.75), b + Vector2(w / 2 - 10, -h * 1.7), Color("#3a2618"), 4)
			var wave := sin(_t * 3) * 4
			draw_colored_polygon(PackedVector2Array([b + Vector2(w / 2 - 10, -h * 1.7), b + Vector2(w / 2 + 40, -h * 1.66 + wave), b + Vector2(w / 2 + 40, -h * 1.45 + wave), b + Vector2(w / 2 - 10, -h * 1.5)]), Color("#a8392e"))
			_window(b + Vector2(-w / 2 + 14, -h * 0.55))
			_window(b + Vector2(w / 2 - 40, -h * 0.55))
			_rect(Rect2(b.x - 18, b.y - 56, 36, 56), Color("#3a2618"))
			_sign(b + Vector2(0, -h * 0.85), "DRILL HALL", w * 0.8)
		"store":
			_rect(Rect2(b.x - w / 2, b.y - h, w, h), Color("#b88a4a"))
			_rect(Rect2(b.x - w / 2 - 6, b.y - h - 36, w + 12, 42), Color("#c99a55"))
			_sign(b + Vector2(0, -h - 14), "GENERAL STORE", w - 20)
			_poly([b + Vector2(-w / 2 - 4, -h * 0.55), b + Vector2(w / 2 + 4, -h * 0.55), b + Vector2(w / 2 + 16, -h * 0.4), b + Vector2(-w / 2 - 16, -h * 0.4)], Color("#a8392e"))
			for k in 6:
				draw_rect(Rect2(b.x - w / 2 - 12 + k * (w + 24) / 6.0, b.y - h * 0.55, (w + 24) / 12.0, h * 0.15), Color("#efe3c8"))
			_rect(Rect2(b.x - 20, b.y - 56, 40, 56), Color("#5a3822"))
			_rect(Rect2(b.x - w / 2 + 12, b.y - 30, 30, 30), Color("#7a5232"))
			_rect(Rect2(b.x + w / 2 - 44, b.y - 26, 26, 26), Color("#8a6a45"))
		"board":
			draw_line(b + Vector2(-w / 2 + 20, 0), b + Vector2(-w / 2 + 20, -h), Color("#5a3822"), 10)
			draw_line(b + Vector2(w / 2 - 20, 0), b + Vector2(w / 2 - 20, -h), Color("#5a3822"), 10)
			_rect(Rect2(b.x - w / 2 + 6, b.y - h, w - 12, h * 0.7), wood)
			var rng := RandomNumberGenerator.new()
			rng.seed = 5
			for k in 7:
				var px := b.x - w / 2 + 20 + rng.randf() * (w - 70)
				var py := b.y - h + 12 + rng.randf() * (h * 0.7 - 50)
				draw_rect(Rect2(px, py, 34, 40), Color("#efe3c8"))
				draw_line(Vector2(px + 5, py + 12), Vector2(px + 28, py + 12), Color("#6b5a45"), 2)
				draw_line(Vector2(px + 5, py + 22), Vector2(px + 24, py + 22), Color("#6b5a45"), 2)
			_sign(b + Vector2(0, -h - 14), "HIRING", w * 0.6)
		"stage":
			_rect(Rect2(b.x - w / 2, b.y - h * 0.85, w, h * 0.85), Color("#8a5a32"))
			_poly([b + Vector2(-w / 2 - 10, -h * 0.85), b + Vector2(w / 2 + 10, -h * 0.85), b + Vector2(0, -h * 1.2)], Color("#5e3f27"))
			_rect(Rect2(b.x - w / 2 + 14, b.y - h * 0.62, w * 0.45, h * 0.62), Color("#2a1d14"))
			draw_line(b + Vector2(-w / 2 + 14, -h * 0.62), b + Vector2(-w / 2 + 14 + w * 0.45, 0), Color("#8a5a32"), 5)
			draw_line(b + Vector2(-w / 2 + 14 + w * 0.45, -h * 0.62), b + Vector2(-w / 2 + 14, 0), Color("#8a5a32"), 5)
			draw_circle(b + Vector2(w / 4, -18), 18, Color("#3a2618"))
			draw_circle(b + Vector2(w / 4, -18), 12, Color("#a8392e"))
			_sign(b + Vector2(0, -h * 0.95), "STAGE LINE", w * 0.75)
		"graveyard":
			for k in 5:
				var cx := b.x - w / 2 + 20 + k * (w - 40) / 4.0
				var ch := 50 + (k % 2) * 16
				draw_line(Vector2(cx, b.y), Vector2(cx, b.y - ch), Color("#d9cfb8"), 7)
				draw_line(Vector2(cx - 14, b.y - ch + 16), Vector2(cx + 14, b.y - ch + 16), Color("#d9cfb8"), 7)
			draw_line(b + Vector2(-w / 2, -14), b + Vector2(w / 2, -14), Color("#5a3822"), 3)
			_sign(b + Vector2(0, -110), "BOOT HILL", w * 0.7)
	# Level stars.
	for k in level:
		draw_colored_polygon(PackedVector2Array(Figure.star_pts(b + Vector2(-(level - 1) * 12 + k * 24, 22), 9, 4, 5)), Color("#e0bd4f"))
