class_name Backdrop
extends Node2D
## Painted, layered parallax scenery drawn in code. `scroll` moves the layers at
## different speeds (used while the wagon travels). mode: "trail", "cave", "town", "camp".

const W := 1920.0
const H := 1080.0

var region_id: String = "tallgrass"
var mode: String = "trail"
var scroll: float = 0.0
var ground_y: float = 770.0
var light: float = 1.0          # cave lamplight 0..1
var night: float = 0.0          # 0 day .. 1 night (camp)
var seed_value: int = 1

var _pal: Dictionary = {}
var _layers: Array = []         # {factor, color, pts (for width 2W), props}
var _t: float = 0.0


func setup(region: String, m: String = "trail", s: int = 1) -> void:
	region_id = region
	mode = m
	seed_value = s
	var r: Dictionary = DB.regions.get(region, {})
	_pal = {}
	for k in r.get("palette", {}):
		_pal[k] = Color(r.palette[k])
	if _pal.is_empty():
		_pal = {"sky_top": Color("#3d5a80"), "sky_bottom": Color("#f6bd60"), "sun": Color("#fff1c1"), "far": Color("#8d7b68"),
			"mid": Color("#a98f5f"), "near": Color("#6b7d3c"), "ground": Color("#4f5d2f"), "accent": Color("#d4a24c")}
	_build_layers(r.get("props", ["grass"]))
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if mode in ["cave", "camp"]:
		queue_redraw()


func set_scroll(v: float) -> void:
	scroll = v
	queue_redraw()


func pal(k: String) -> Color:
	return _pal.get(k, Color.GRAY)


func _build_layers(props: Array) -> void:
	_layers.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var style := "hills"
	if "mesa" in props:
		style = "mesa"
	elif "pine" in props:
		style = "peaks"
	# Far ridge, mid hills, near rise.
	_layers.append({"factor": 0.08, "color": pal("far").lerp(pal("sky_bottom"), 0.35), "pts": _ridge(rng, style, 430, 150, 9), "props": []})
	_layers.append({"factor": 0.2, "color": pal("far"), "pts": _ridge(rng, style, 520, 110, 12), "props": _props(rng, props, 520, 0.55, 5)})
	_layers.append({"factor": 0.45, "color": pal("mid"), "pts": _ridge(rng, "hills" if style != "peaks" else "peaks", 640, 70, 16), "props": _props(rng, props, 640, 0.8, 7)})
	_layers.append({"factor": 1.0, "color": pal("near"), "pts": _ridge(rng, "hills", ground_y - 40, 26, 20), "props": _props(rng, props, ground_y - 30, 1.1, 9)})


func _ridge(rng: RandomNumberGenerator, style: String, base: float, amp: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var width := W * 2.0
	var heights: Array = []
	for i in n:
		heights.append(rng.randf_range(0.2, 1.0))
	heights.append(heights[0])   # seamless wrap
	pts.append(Vector2(0, H))
	for i in n + 1:
		var x := width * i / float(n)
		var h: float = heights[i]
		match style:
			"mesa":
				var hw := width / n * 0.3
				if h > 0.55:
					pts.append(Vector2(x - hw, base - amp * 0.2))
					pts.append(Vector2(x - hw * 0.7, base - amp * h))
					pts.append(Vector2(x + hw * 0.7, base - amp * h))
					pts.append(Vector2(x + hw, base - amp * 0.2))
				else:
					pts.append(Vector2(x, base - amp * h * 0.4))
			"peaks":
				pts.append(Vector2(x - width / n * 0.5, base - amp * 0.15))
				pts.append(Vector2(x, base - amp * (0.5 + h)))
			_:
				# Smooth rolling hills: several points per segment.
				if i < n:
					var h2: float = heights[i + 1]
					for k in 6:
						var f := k / 6.0
						var s := (1.0 - cos(f * PI)) / 2.0
						pts.append(Vector2(x + width / n * f, base - amp * lerpf(h, h2, s)))
	pts.append(Vector2(width, H))
	return pts


func _props(rng: RandomNumberGenerator, kinds: Array, base: float, size: float, count: int) -> Array:
	var out: Array = []
	for i in count:
		out.append({"kind": Stats.pick(rng, kinds), "x": rng.randf_range(0, W * 2.0), "y": base + rng.randf_range(-6, 14),
			"s": size * rng.randf_range(0.7, 1.2)})
	return out


func _draw() -> void:
	match mode:
		"cave":
			_draw_cave()
			return
	_draw_sky()
	for L in _layers:
		var off := fposmod(scroll * L.factor, W * 2.0)
		for rep in [-1, 0, 1]:
			var shift: float = -off + rep * W * 2.0
			if shift > W or shift < -W * 2.0 - 10:
				continue
			var moved := PackedVector2Array()
			for p in L.pts:
				moved.append(p + Vector2(shift, 0))
			var c: Color = L.color
			if night > 0:
				c = c.lerp(Color("#101522"), night * 0.6)
			draw_colored_polygon(moved, c)
			for pr in L.props:
				var px: float = pr.x + shift
				if px > -200 and px < W + 200:
					_draw_prop(pr.kind, Vector2(px, pr.y), pr.s, c.darkened(0.12))
	# Ground band.
	var g := pal("ground")
	if night > 0:
		g = g.lerp(Color("#0d1018"), night * 0.6)
	draw_rect(Rect2(0, ground_y, W, H - ground_y), g)
	draw_rect(Rect2(0, ground_y, W, 6), g.lightened(0.12))
	# Texture strokes on the ground.
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 7
	var goff := fposmod(scroll, W)
	for i in 70:
		var x := fposmod(rng.randf() * W - goff, W)
		var y := ground_y + 20 + rng.randf() * (H - ground_y - 30)
		draw_line(Vector2(x, y), Vector2(x + rng.randf_range(10, 40), y), g.darkened(0.15), 2.0)
	if night > 0:
		draw_rect(Rect2(0, 0, W, H), Color(0.05, 0.07, 0.15, night * 0.35))


func _draw_sky() -> void:
	var top := pal("sky_top")
	var bot := pal("sky_bottom")
	if night > 0:
		top = top.lerp(Color("#070a18"), night)
		bot = bot.lerp(Color("#27304a"), night)
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, ground_y), Vector2(0, ground_y)]),
		PackedColorArray([top, top, bot, bot]))
	var sun_pos := Vector2(1450 - scroll * 0.02, 330)
	if night > 0.5:
		# Moon and stars.
		var rng := RandomNumberGenerator.new()
		rng.seed = 99
		for i in 90:
			var p := Vector2(rng.randf() * W, rng.randf() * 520)
			draw_circle(p, rng.randf_range(0.8, 2.2), Color(1, 1, 0.9, 0.5 + 0.4 * sin(_t * 2 + i)))
		draw_circle(Vector2(420, 180), 46, Color("#f4f1de"))
		draw_circle(Vector2(440, 170), 44, top.lerp(bot, 0.2))
		return
	for i in 16:
		draw_circle(sun_pos, 72 + i * 14, Color(pal("sun").r, pal("sun").g, pal("sun").b, 0.028))
	draw_circle(sun_pos, 70, pal("sun"))
	# A few paper clouds.
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = seed_value + 3
	for i in 5:
		var cx := fposmod(rng2.randf() * W * 1.5 - scroll * 0.04, W * 1.5) - 200
		var cy := rng2.randf_range(80, 300)
		var cc := Color(1, 1, 1, 0.13)
		for k in 5:
			var pts := PackedVector2Array(Figure.ellipse(Vector2(cx + k * 46, cy + (k % 2) * 6), 70 - absf(k - 2) * 12, 16 + (k % 2) * 6, 16))
			draw_colored_polygon(pts, cc)


func _draw_prop(kind: String, p: Vector2, s: float, c: Color) -> void:
	match kind:
		"grass":
			for i in 5:
				var x := p.x + (i - 2) * 7 * s
				draw_line(Vector2(x, p.y), Vector2(x + (i - 2) * 3 * s, p.y - (22 + (i % 3) * 8) * s), c.lightened(0.15), 3.0 * s)
		"tree":
			draw_line(p, p + Vector2(0, -60 * s), c.darkened(0.2), 8 * s)
			for k in 3:
				draw_circle(p + Vector2((k - 1) * 22 * s, -70 * s - (k % 2) * 16 * s), 30 * s, c)
		"fence":
			for i in 4:
				draw_line(p + Vector2(i * 34 * s, 0), p + Vector2(i * 34 * s, -34 * s), c.darkened(0.25), 5 * s)
			draw_line(p + Vector2(0, -26 * s), p + Vector2(102 * s, -26 * s), c.darkened(0.25), 4 * s)
			draw_line(p + Vector2(0, -12 * s), p + Vector2(102 * s, -12 * s), c.darkened(0.25), 4 * s)
		"rock", "snowrock":
			draw_colored_polygon(PackedVector2Array([p + Vector2(-30, 0) * s, p + Vector2(-22, -24) * s, p + Vector2(4, -34) * s,
				p + Vector2(28, -18) * s, p + Vector2(34, 0) * s]), c.darkened(0.1))
			if kind == "snowrock":
				draw_colored_polygon(PackedVector2Array([p + Vector2(-22, -24) * s, p + Vector2(4, -34) * s, p + Vector2(28, -18) * s, p + Vector2(2, -24) * s]), Color("#eef3f6"))
		"cactus":
			draw_line(p, p + Vector2(0, -70 * s), c.darkened(0.15), 12 * s)
			draw_line(p + Vector2(0, -34 * s), p + Vector2(-18 * s, -34 * s), c.darkened(0.15), 9 * s)
			draw_line(p + Vector2(-18 * s, -34 * s), p + Vector2(-18 * s, -54 * s), c.darkened(0.15), 9 * s)
			draw_line(p + Vector2(0, -44 * s), p + Vector2(16 * s, -44 * s), c.darkened(0.15), 9 * s)
			draw_line(p + Vector2(16 * s, -44 * s), p + Vector2(16 * s, -60 * s), c.darkened(0.15), 9 * s)
		"mesa":
			draw_colored_polygon(PackedVector2Array([p + Vector2(-80, 0) * s, p + Vector2(-60, -60) * s, p + Vector2(60, -60) * s, p + Vector2(80, 0) * s]), c.darkened(0.08))
		"skull":
			draw_circle(p + Vector2(0, -10 * s), 10 * s, Color("#e9e2cf"))
			draw_line(p + Vector2(-8, -16) * s, p + Vector2(-26, -26) * s, Color("#e9e2cf"), 4 * s)
			draw_line(p + Vector2(8, -16) * s, p + Vector2(26, -26) * s, Color("#e9e2cf"), 4 * s)
		"pine":
			draw_line(p, p + Vector2(0, -20 * s), c.darkened(0.3), 6 * s)
			for k in 3:
				var y := -20 - k * 26
				draw_colored_polygon(PackedVector2Array([p + Vector2(-30 + k * 7, y) * s, p + Vector2(30 - k * 7, y) * s, p + Vector2(0, y - 44) * s]), c.darkened(0.2))
		"cairn":
			for k in 4:
				draw_circle(p + Vector2(0, -8 - k * 14) * s, (14 - k * 2.5) * s, c.lightened(0.1))


func _draw_cave() -> void:
	var rock := Color("#2a2420")
	var rock2 := Color("#3a322b")
	draw_rect(Rect2(0, 0, W, H), Color("#15110e"))
	# Back wall bands.
	for i in 5:
		var y := 120 + i * 120
		var pts := PackedVector2Array()
		pts.append(Vector2(0, H))
		for k in 13:
			var x := fposmod(k * 170 - scroll * (0.2 + i * 0.15), W + 340) - 170
			pts.append(Vector2(x, y + sin(k * 1.7 + i) * 30))
		pts.append(Vector2(W, H))
		var sorted := Array(pts).slice(1, pts.size() - 1)
		sorted.sort_custom(func(a, b): return a.x < b.x)
		var poly := PackedVector2Array([Vector2(0, H)] + sorted + [Vector2(W, H)])
		draw_colored_polygon(poly, rock.lerp(rock2, i / 5.0))
	# Stalactites.
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in 16:
		var x := fposmod(rng.randf() * W * 1.5 - scroll * 0.9, W * 1.5) - 100
		var l := rng.randf_range(60, 220)
		var w2 := rng.randf_range(18, 46)
		draw_colored_polygon(PackedVector2Array([Vector2(x - w2, 0), Vector2(x + w2, 0), Vector2(x + 4, l)]), Color("#1d1814"))
	draw_rect(Rect2(0, ground_y, W, H - ground_y), Color("#231d18"))
	draw_rect(Rect2(0, ground_y, W, 5), Color("#3b3129"))
	# Lamplight: a warm pool around the party, darkness everywhere else.
	var glow_c := Vector2(640, ground_y - 150)
	var r0 := 260.0 + 520.0 * light
	for i in 8:
		var f := i / 8.0
		draw_circle(glow_c, r0 * (1.0 - f * 0.6), Color(1.0, 0.75, 0.4, 0.035 + 0.02 * light))
	var dark := 0.72 - 0.5 * light
	draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, clampf(dark, 0.0, 0.85) * 0.6))
