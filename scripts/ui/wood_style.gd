class_name StyleBoxWood
extends StyleBox
## Drawn wood for the UI (owner's pick: the light wood-and-rope pass, drawn in code).
##   "plank": dark stained planks with grain, knots, nail heads, a frame and iron corner
##            brackets. The top bar and bottom HUD panels. Optional rope along an edge.
##   "sign":  a small wooden signboard with chamfered corners and two nails, for buttons.
##            paint tints it (red for Danger, green for Good) with bare wood at the edges.
## Everything is seeded from the rect size, so a panel keeps the same grain every frame.

const INK := Color("#1e140d")
const IRON := Color("#2f2b28")
const RIVET := Color("#77706a")
const ROPE := Color("#b8976a")

var kind := "plank"
var wood := Color("#3b281a")
var paint := Color(0, 0, 0, 0)       # sign paint; transparent = bare wood
var edge := Color(0, 0, 0, 0)        # sign outline override (gold on hover)
var rope_top := false
var rope_bottom := false
var brackets := true
var nails := true


static func plank(pad: int = 14) -> StyleBoxWood:
	var s := StyleBoxWood.new()
	s.kind = "plank"
	s.set_pads(pad)
	return s


static func sign_board(base: Color, pad: int = 12, paint_c: Color = Color(0, 0, 0, 0), edge_c: Color = Color(0, 0, 0, 0)) -> StyleBoxWood:
	var s := StyleBoxWood.new()
	s.kind = "sign"
	s.wood = base
	s.paint = paint_c
	s.edge = edge_c
	s.set_pads(pad)
	return s


func set_pads(pad: int) -> void:
	content_margin_left = pad
	content_margin_right = pad
	content_margin_top = pad * 0.75
	content_margin_bottom = pad * 0.75


func _draw(ci: RID, rect: Rect2) -> void:
	if rect.size.x < 4 or rect.size.y < 4:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = int(rect.size.x) * 7919 + int(rect.size.y) * 104729 + (1 if kind == "sign" else 0)
	if kind == "sign":
		_draw_sign(ci, rect, rng)
	else:
		_draw_planks(ci, rect, rng)


# --- Planks -----------------------------------------------------------------------------

func _draw_planks(ci: RID, r: Rect2, rng: RandomNumberGenerator) -> void:
	var rs := RenderingServer
	# Frame: a darker border board all round.
	rs.canvas_item_add_rect(ci, r, wood.darkened(0.45))
	var inner := r.grow(-4)
	var n := maxi(1, int(round(inner.size.y / 42.0)))
	var ph := inner.size.y / n
	for i in n:
		var pr := Rect2(inner.position.x, inner.position.y + i * ph, inner.size.x, ph)
		var tone := wood.lightened(rng.randf_range(-0.06, 0.08))
		rs.canvas_item_add_rect(ci, pr, tone)
		# A soft lit band on the top of each plank, a shadow at the bottom.
		rs.canvas_item_add_rect(ci, Rect2(pr.position, Vector2(pr.size.x, 2)), tone.lightened(0.18))
		rs.canvas_item_add_rect(ci, Rect2(pr.position + Vector2(0, pr.size.y - 3), Vector2(pr.size.x, 3)), tone.darkened(0.35))
		# Grain: long, slightly wavy lines, low contrast so text stays readable.
		var lines := 3 + int(ph / 16)
		for g in lines:
			var y0 := pr.position.y + rng.randf_range(5, ph - 5)
			var amp := rng.randf_range(0.6, 2.2)
			var freq := rng.randf_range(0.006, 0.02)
			var ph0 := rng.randf() * TAU
			var pts := PackedVector2Array()
			var x := pr.position.x
			while x <= pr.end.x:
				pts.append(Vector2(x, y0 + sin(x * freq + ph0) * amp))
				x += 24.0
			pts.append(Vector2(pr.end.x, y0 + sin(pr.end.x * freq + ph0) * amp))
			var gc := tone.darkened(0.3) if g % 2 == 0 else tone.lightened(0.1)
			rs.canvas_item_add_polyline(ci, Figure.clean_line(pts), PackedColorArray([Color(gc, 0.45)]), 1.0, true)
		# Now and then a knot.
		if pr.size.x > 300 and rng.randf() < 0.6:
			var kc := Vector2(rng.randf_range(pr.position.x + 80, pr.end.x - 80), pr.position.y + ph * rng.randf_range(0.35, 0.65))
			_ellipse(ci, kc, 7, 3.5, tone.darkened(0.35))
			_ellipse(ci, kc, 4, 2, tone.darkened(0.55))
		# Butt joints: planks are not one board across a wide panel.
		if pr.size.x > 700:
			var jx := pr.position.x + pr.size.x * rng.randf_range(0.3, 0.7)
			rs.canvas_item_add_rect(ci, Rect2(jx, pr.position.y, 2, ph), tone.darkened(0.5))
			if nails:
				_nail(ci, Vector2(jx - 7, pr.position.y + ph / 2))
				_nail(ci, Vector2(jx + 9, pr.position.y + ph / 2))
		if nails:
			_nail(ci, Vector2(pr.position.x + 10, pr.position.y + ph / 2))
			_nail(ci, Vector2(pr.end.x - 10, pr.position.y + ph / 2))
	# Frame edge: a lit line inside the top, a dark line inside the bottom.
	rs.canvas_item_add_rect(ci, Rect2(r.position, Vector2(r.size.x, 1)), wood.lightened(0.25))
	rs.canvas_item_add_rect(ci, Rect2(r.position + Vector2(0, r.size.y - 1), Vector2(r.size.x, 1)), INK)
	if brackets and r.size.y >= 50:
		for corner in 4:
			_bracket(ci, r, corner)
	if rope_top:
		draw_rope(ci, Vector2(r.position.x, r.position.y + 1), Vector2(r.end.x, r.position.y + 1), 9.0)
	if rope_bottom:
		draw_rope(ci, Vector2(r.position.x, r.end.y - 1), Vector2(r.end.x, r.end.y - 1), 9.0)


func _nail(ci: RID, p: Vector2) -> void:
	RenderingServer.canvas_item_add_circle(ci, p + Vector2(0.6, 0.8), 2.8, Color(0, 0, 0, 0.45))
	RenderingServer.canvas_item_add_circle(ci, p, 2.4, Color("#4a4540"))
	RenderingServer.canvas_item_add_circle(ci, p + Vector2(-0.7, -0.7), 1.0, Color("#9a938a"))


## An iron corner strap: an L of flat iron with three rivets.
func _bracket(ci: RID, r: Rect2, corner: int) -> void:
	var arm := minf(34.0, r.size.y * 0.45)
	var t := 7.0
	var sx := 1.0 if corner in [0, 2] else -1.0
	var sy := 1.0 if corner in [0, 1] else -1.0
	var o := Vector2(r.position.x if sx > 0 else r.end.x, r.position.y if sy > 0 else r.end.y)
	var pts := PackedVector2Array([o, o + Vector2(arm * sx, 0), o + Vector2(arm * sx, t * sy), o + Vector2(t * sx, t * sy),
		o + Vector2(t * sx, arm * sy), o + Vector2(0, arm * sy)])
	RenderingServer.canvas_item_add_polygon(ci, pts, PackedColorArray([IRON]))
	var edge_pts := pts.duplicate()
	edge_pts.append(pts[0])
	RenderingServer.canvas_item_add_polyline(ci, Figure.clean_line(edge_pts), PackedColorArray([Color(0, 0, 0, 0.6)]), 1.0, true)
	for k in [Vector2(t * 0.5, t * 0.5), Vector2(arm - 5, t * 0.5), Vector2(t * 0.5, arm - 5)]:
		var p: Vector2 = o + Vector2(k.x * sx, k.y * sy)
		RenderingServer.canvas_item_add_circle(ci, p, 1.8, RIVET)


# --- Signboards -------------------------------------------------------------------------

func _draw_sign(ci: RID, r: Rect2, rng: RandomNumberGenerator) -> void:
	var rs := RenderingServer
	var c := 5.0   # chamfer
	var body := PackedVector2Array([r.position + Vector2(c, 0), Vector2(r.end.x - c, r.position.y), Vector2(r.end.x, r.position.y + c),
		r.end - Vector2(0, c), r.end - Vector2(c, 0), Vector2(r.position.x + c, r.end.y), Vector2(r.position.x, r.end.y - c), r.position + Vector2(0, c)])
	# Drop shadow, then the board.
	var sh := PackedVector2Array()
	for p in body:
		sh.append(p + Vector2(2, 3))
	rs.canvas_item_add_polygon(ci, sh, PackedColorArray([Color(0, 0, 0, 0.35)]))
	var tone := wood if paint.a <= 0.0 else wood.lerp(paint, 0.85)
	rs.canvas_item_add_polygon(ci, body, PackedColorArray([tone]))
	# Lit top edge, shadowed bottom edge.
	rs.canvas_item_add_rect(ci, Rect2(r.position + Vector2(c, 2), Vector2(r.size.x - 2 * c, 2)), tone.lightened(0.2))
	rs.canvas_item_add_rect(ci, Rect2(Vector2(r.position.x + c, r.end.y - 4), Vector2(r.size.x - 2 * c, 2)), tone.darkened(0.3))
	# Grain.
	for g in 2 + int(r.size.y / 18):
		var y0 := r.position.y + rng.randf_range(6, r.size.y - 6)
		var pts := PackedVector2Array()
		var x := r.position.x + 4
		var ph0 := rng.randf() * TAU
		while x <= r.end.x - 4:
			pts.append(Vector2(x, y0 + sin(x * 0.03 + ph0) * 1.2))
			x += 14.0
		rs.canvas_item_add_polyline(ci, Figure.clean_line(pts), PackedColorArray([Color(tone.darkened(0.3), 0.4)]), 1.0, true)
	# Worn paint: bare wood showing through at the corners.
	if paint.a > 0.0:
		for k in 3:
			var p := Vector2(rng.randf_range(r.position.x + 4, r.end.x - 4), r.position.y + (3 if k % 2 == 0 else r.size.y - 5))
			rs.canvas_item_add_rect(ci, Rect2(p, Vector2(rng.randf_range(6, 16), 2)), wood.lightened(0.1))
	# Ink outline.
	var ring := body.duplicate()
	ring.append(body[0])
	rs.canvas_item_add_polyline(ci, Figure.clean_line(ring), PackedColorArray([edge if edge.a > 0.0 else INK]), 2.0 if edge.a > 0.0 else 1.5, true)
	if nails and r.size.x >= 70:
		_nail(ci, Vector2(r.position.x + 8, r.position.y + r.size.y / 2))
		_nail(ci, Vector2(r.end.x - 8, r.position.y + r.size.y / 2))


# --- Rope -------------------------------------------------------------------------------

## A twisted hemp rope from a to b: a tan core with the lay drawn as diagonal strands.
static func draw_rope(ci: RID, a: Vector2, b: Vector2, t: float) -> void:
	var rs := RenderingServer
	var d := (b - a)
	var length := d.length()
	if length < 1.0:
		return
	var dir := d / length
	var nrm := dir.orthogonal()
	rs.canvas_item_add_line(ci, a + nrm * 1.5, b + nrm * 1.5, Color(0, 0, 0, 0.4), t, true)
	rs.canvas_item_add_line(ci, a, b, ROPE.darkened(0.15), t, true)
	var step := t * 0.85
	var s := 0.0
	while s < length:
		var p := a + dir * s
		var p1 := p - nrm * (t * 0.5) + dir * (t * 0.35)
		var p2 := p + nrm * (t * 0.5) - dir * (t * 0.35)
		rs.canvas_item_add_line(ci, p1, p2, ROPE.darkened(0.45), 1.6, true)
		rs.canvas_item_add_line(ci, p1 + dir * 2.0, p2 + dir * 2.0, ROPE.lightened(0.25), 1.2, true)
		s += step


func _ellipse(ci: RID, c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 14:
		var a := TAU * i / 14.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	RenderingServer.canvas_item_add_polygon(ci, pts, PackedColorArray([col]))
