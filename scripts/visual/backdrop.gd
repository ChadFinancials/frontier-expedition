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
var paper: bool = PaperFX.enabled   # paper-theater look: layered paper sheets with the paper shader

var _pal: Dictionary = {}
var _layers: Array = []         # {factor, color, pts (for width 2W), props}
var _t: float = 0.0
var _paper_nodes: Array = []    # layer painters when paper is on
var _grass_country := false
var _lamp: ColorRect = null     # paper cave lamplight pool


var bg_key: String = ""         # optional painted-backdrop override, else "<region>_<mode>"
var bg_progress: float = 0.0    # 0 at the start of the map, 1 at the end (drives variants)
var bg_bottom: float = -1.0     # screen y for the image BOTTOM edge; -1 means the frame bottom (H).
var bg_horizon_y: float = -1.0  # screen y to place the image horizon at; -1 disables
var _horizons: Dictionary = {}
var _horizons_loaded := false
                                # Let it run below an opaque panel so the ground fills the band that is.
                                # actually visible, which is what stops figures looking like they float.
var bg: Sprite2D = null
var _bg_paths: Array = []       # every "<key>.png" and "<key>_N.png" found, sorted
var _bg_index: int = -1
var _bg_margin := 0.0


## If a painted backdrop exists for this region and mode, use it and skip the drawn layers.
## Path: assets/art/backdrops/<region>_<mode>.png, or <bg_key>.png when bg_key is set.
## Always falls back to the code-drawn scenery when the file is missing, so the game runs
## correctly with any fraction of the art done.
func _bg_candidates() -> Array:
	## Keys to try, in order: an explicit bg_key, then the region's "backdrop" field, then
	## "<region>_<mode>". The region field lets a region reuse another region's art.
	var keys: Array = []
	if bg_key != "":
		keys.append(bg_key)
	var r: Dictionary = DB.regions.get(region_id, {})
	var alias: String = str(r.get("backdrop", ""))
	if alias != "" and not keys.has(alias):
		keys.append(alias)
	var own: String = "%s_%s" % [region_id, mode]
	if not keys.has(own):
		keys.append(own)
	return keys


## Find a painted backdrop and show it, skipping the drawn layers. Variants are
## "<key>_1.png", "<key>_2.png" and so on; set_progress picks among them as the company
## travels. Falls back to the code-drawn scenery when nothing is found.
func _load_backdrop_image() -> bool:
	for key in _bg_candidates():
		var found: Array = []
		var single: String = "res://assets/art/backdrops/%s.png" % key
		if ResourceLoader.exists(single):
			found.append(single)
		for i in range(1, 25):
			var vp: String = "res://assets/art/backdrops/%s_%d.png" % [key, i]
			if ResourceLoader.exists(vp):
				found.append(vp)
		if found.is_empty():
			continue
		_bg_paths = found
		bg = Sprite2D.new()
		bg.centered = true
		add_child(bg)
		_apply_bg(0)
		return true
	return false


## Fraction down the image where its horizon sits, from assets/art/backdrops/
## horizons.json. Written by tools/art/prep_backdrops.py, which measures the images.
func _horizon_frac(path: String) -> float:
	if not _horizons_loaded:
		_horizons_loaded = true
		var f := FileAccess.open("res://assets/art/backdrops/horizons.json", FileAccess.READ)
		if f != null:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary:
				_horizons = parsed
	return float(_horizons.get(path.get_file(), -1.0))

func _apply_bg(index: int) -> void:
	if bg == null or _bg_paths.is_empty():
		return
	var i: int = clampi(index, 0, _bg_paths.size() - 1)
	if i == _bg_index:
		return
	_bg_index = i
	var tex: Texture2D = load(_bg_paths[i])
	bg.texture = tex
	# Time of day the image is anchored to. The overdraw gives the drift in set_scroll room
	# to move without ever showing an edge.
	var h := float(tex.get_height())
	var frac: float = _horizon_frac(_bg_paths[i])
	var cover: float
	var cy: float
	if bg_horizon_y > 0.0 and frac > 0.0:
		# Anchor on the horizon: sky above it, ground below, whatever the variant.
		# cover must also reach the top edge, so the frame is never left blank.
		cover = maxf(W * 1.08 / float(tex.get_width()), bg_horizon_y / (frac * h))
		cy = bg_horizon_y - h * cover * (frac - 0.5)
	else:
		# No horizon data: anchor the image bottom, which may run behind an opaque panel.
		var bottom: float = bg_bottom if bg_bottom > 0.0 else H
		cover = maxf(W * 1.08 / float(tex.get_width()), bottom / h)
		cy = bottom - h * cover * 0.5
	bg.scale = Vector2(cover, cover)
	bg.position = Vector2(W * 0.5, cy)
	_bg_margin = (float(tex.get_width()) * cover - W) * 0.5


## Screen y where the image horizon should sit. Sky above, ground below. This is the
## knob that stops figures looking like they float over an opaque panel.
func set_bg_horizon(y: float) -> void:
	bg_horizon_y = y
	var keep: int = _bg_index
	_bg_index = -1
	_apply_bg(keep if keep >= 0 else 0)

## Screen y for the image bottom edge. Lower it to pull more sky into view, raise it to
## push the horizon up so more ground shows beneath the figures.
func set_bg_bottom(y: float) -> void:
	bg_bottom = y
	var keep: int = _bg_index
	_bg_index = -1
	_apply_bg(keep if keep >= 0 else 0)

## Drive this from the screen so the scenery changes as the company pushes west.
func set_progress(p: float) -> void:
	bg_progress = clampf(p, 0.0, 1.0)
	if _bg_paths.size() > 1:
		_apply_bg(int(round(bg_progress * float(_bg_paths.size() - 1))))

func setup(region: String, m: String = "trail", s: int = 1) -> void:
	region_id = region
	mode = m
	seed_value = s
	if _load_backdrop_image():
		return
	var r: Dictionary = DB.regions.get(region, {})
	_pal = {}
	for k in r.get("palette", {}):
		_pal[k] = Color(r.palette[k])
	if _pal.is_empty():
		_pal = {"sky_top": Color("#3d5a80"), "sky_bottom": Color("#f6bd60"), "sun": Color("#fff1c1"), "far": Color("#8d7b68"),
			"mid": Color("#a98f5f"), "near": Color("#6b7d3c"), "ground": Color("#4f5d2f"), "accent": Color("#d4a24c")}
	_build_layers(r.get("props", ["grass"]))
	if paper:
		_build_paper()
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if paper:
		if _lamp != null:
			_update_lamp()
		return
	if mode in ["cave", "camp"]:
		queue_redraw()


## The lamp pool widens and the dark deepens with the lamplight level.
func _update_lamp() -> void:
	var flicker := 0.012 * sin(_t * 7.0) + 0.008 * sin(_t * 13.0)
	var m: ShaderMaterial = _lamp.material
	m.set_shader_parameter("center", Vector2(0.33, 0.62))
	m.set_shader_parameter("radius", 0.35 + 0.45 * light + flicker)
	m.set_shader_parameter("softness", 0.45)
	m.set_shader_parameter("darkness", 0.93 - 0.25 * light)
	m.set_shader_parameter("warmth", 0.1 + 0.08 * light)


func set_scroll(v: float) -> void:
	scroll = v
	if bg != null:
		# A gentle bounded drift inside the overdraw margin: a flat image cannot scroll far
		# without showing its edge, and it must not look pinned while the wagon rolls.
		bg.position.x = W * 0.5 + sin(scroll * 0.004) * _bg_margin
	queue_redraw()
	for n in _paper_nodes:
		n.queue_redraw()


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
	if paper:
		return
	match mode:
		"cave":
			_draw_cave()
			return
	_draw_sky()
	for i in _layers.size():
		_draw_layer(self, i, false)
	_draw_ground(self, false)
	if night > 0:
		draw_rect(Rect2(0, 0, W, H), Color(0.05, 0.07, 0.15, night * 0.35))


## One scenery layer onto canvas item ci. With edge, the ridge gets a cut-paper rim.
func _draw_layer(ci: CanvasItem, i: int, edge: bool) -> void:
	var L: Dictionary = _layers[i]
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
		if edge:
			var rim := moved.slice(1, moved.size() - 1)
			ci.draw_polyline(rim, Figure.PAPER.darkened(0.04), 7.0, true)
		ci.draw_colored_polygon(moved, c)
		if edge:
			_paper_detail(ci, i, moved, c, shift)
		for pr in L.props:
			var px: float = pr.x + shift
			if px > -200 and px < W + 200:
				_draw_prop(ci, pr.kind, Vector2(px, pr.y), pr.s, c.darkened(0.12))


## Craft on a paper hill: a shaded band under the cut edge, pencil strokes across the
## sheet, and little cut-paper grass tufts along the ridge.
func _paper_detail(ci: CanvasItem, i: int, pts: PackedVector2Array, c: Color, shift: float) -> void:
	var rim := pts.slice(1, pts.size() - 1)
	var band := PackedVector2Array()
	for p in rim:
		band.append(p + Vector2(0, 16 + i * 4))
	ci.draw_polyline(band, Color(c.darkened(0.18), 0.45), 20.0 + i * 6, true)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 31 + i
	var depth := float(i + 1) / _layers.size()
	for k in int(90 * depth + 30):
		var x := rng.randf() * W * 2.0 + shift
		var top := _ridge_y(rim, x)
		if x < -60 or x > W + 60 or top >= ground_y:
			rng.randf()
			rng.randf()
			continue
		var y := top + 26 + rng.randf() * (ground_y - top) * 0.9
		var ln := rng.randf_range(8, 26) * (0.6 + depth)
		ci.draw_line(Vector2(x, y), Vector2(x + ln, y - ln * 0.18), Color(c.darkened(0.3), 0.28), 1.4, true)
	# Tall grass country: whole meadows of cut-paper blades in two tones.
	if _grass_country:
		for k in int(900 * depth):
			var gx := rng.randf() * W * 2.0 + shift
			if gx < -40 or gx > W + 40:
				rng.randf()
				rng.randf()
				continue
			var gtop := _ridge_y(rim, gx)
			var gy := gtop + 8 + pow(rng.randf(), 1.6) * (ground_y - gtop) * 0.85
			var gh := rng.randf_range(16, 44) * (0.45 + depth) * clampf(ground_y / 770.0, 0.55, 1.0)
			var lean := rng.randf_range(-5, 8)
			var gc := c.lightened(0.2) if k % 3 == 0 else c.darkened(0.2)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(gx - 3, gy), Vector2(gx + 3, gy), Vector2(gx + lean, gy - gh)]), Color(gc, 0.85))
	for k in int(26 * depth + 6):
		var x2 := rng.randf() * W * 2.0 + shift
		if x2 < -60 or x2 > W + 60:
			rng.randf()
			continue
		var y2 := _ridge_y(rim, x2) + 3
		var hgt := rng.randf_range(8, 18) * (0.6 + depth)
		var tuft := c.lightened(0.12)
		for b in 3:
			var bx := x2 + (b - 1) * 5 * (0.6 + depth)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(bx - 3, y2), Vector2(bx + 3, y2), Vector2(bx + (b - 1) * 3, y2 - hgt * (1.0 - absf(b - 1) * 0.3))]), tuft)


static func _ridge_y(rim: PackedVector2Array, x: float) -> float:
	for j in rim.size() - 1:
		var a: Vector2 = rim[j]
		var b: Vector2 = rim[j + 1]
		if x >= a.x and x <= b.x and b.x > a.x:
			return lerpf(a.y, b.y, (x - a.x) / (b.x - a.x))
	return H


func _draw_ground(ci: CanvasItem, edge: bool) -> void:
	var g := pal("ground")
	if night > 0:
		g = g.lerp(Color("#0d1018"), night * 0.6)
	if edge:
		ci.draw_rect(Rect2(0, ground_y - 4, W, 8), Figure.PAPER.darkened(0.06))
	ci.draw_rect(Rect2(0, ground_y, W, H - ground_y), g)
	ci.draw_rect(Rect2(0, ground_y, W, 6), g.lightened(0.12))
	if edge:
		# Cut-paper grass along the front edge of the stage.
		var r2 := RandomNumberGenerator.new()
		r2.seed = seed_value + 11
		var goff2 := fposmod(scroll, W)
		for k in 60:
			var x := fposmod(r2.randf() * W - goff2, W)
			var hgt := r2.randf_range(10, 24)
			var tc := g.lightened(r2.randf_range(0.05, 0.2))
			for b in 3:
				var bx := x + (b - 1) * 6
				ci.draw_colored_polygon(PackedVector2Array([Vector2(bx - 4, ground_y + 2), Vector2(bx + 4, ground_y + 2), Vector2(bx + (b - 1) * 4, ground_y + 2 - hgt * (1.0 - absf(b - 1) * 0.3))]), tc)
	# Texture strokes on the ground.
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 7
	var goff := fposmod(scroll, W)
	for i in 70:
		var x := fposmod(rng.randf() * W - goff, W)
		var y := ground_y + 20 + rng.randf() * (H - ground_y - 30)
		ci.draw_line(Vector2(x, y), Vector2(x + rng.randf_range(10, 40), y), g.darkened(0.15), 2.0)


# --- Paper theater --------------------------------------------------------------------

## Builds the layered paper version: a watercolor sky sheet, the sun and clouds hung on
## strings, and each ridge plus the ground as its own paper sheet. Far sheets are hazier
## and slightly out of focus; near ones cast deeper shadows.
func _build_paper() -> void:
	for c in get_children():
		c.queue_free()
	_paper_nodes.clear()
	_grass_country = "grass" in DB.regions.get(region_id, {}).get("props", [])
	if mode == "cave":
		# Rock cut from dark paper; the lamp is a pool of light laid over it.
		var cg := PaperFX.group({"bevel_strength": 1.2, "shadow_alpha": 0.4, "shadow_offset": Vector2(0, 10), "grain_strength": 0.22}, 16.0)
		var cp := _LayerPainter.new()
		cp.bd = self
		cp.idx = -1
		cg.add_child(cp)
		add_child(cg)
		_paper_nodes.append(cp)
		_lamp = PaperFX.vignette()
		_lamp.material.set_shader_parameter("warm", Color(1.0, 0.72, 0.38))
		add_child(_lamp)
		_update_lamp()
		return
	# Stronger light-to-dark steps between the sheets than the flat painting uses.
	for i in _layers.size():
		var L: Dictionary = _layers[i]
		L.color = Color(L.color).darkened(0.05 * i)
	var sky := ColorRect.new()
	sky.size = Vector2(W, ground_y + 10)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top := pal("sky_top")
	var bot := pal("sky_bottom")
	if night > 0:
		top = top.lerp(Color("#070a18"), night)
		bot = bot.lerp(Color("#27304a"), night)
	sky.material = PaperFX.sky_material(top, bot)
	sky.material.set_shader_parameter("size", sky.size)
	add_child(sky)
	var hang := _SkyProps.new()
	hang.bd = self
	var hg := PaperFX.group({"bevel_strength": 0.7, "shadow_offset": Vector2(6, 8), "shadow_alpha": 0.22, "shadow_blur": 3.0})
	hg.add_child(hang)
	add_child(hg)
	_paper_nodes.append(hang)
	var n := _layers.size()
	for i in n + 1:
		var depth := 1.0 - float(i) / n    # 1 = farthest, 0 = ground
		var haze_c := pal("sky_bottom").lerp(Color("#f3e9d2"), 0.4)
		if night > 0:
			haze_c = haze_c.lerp(Color("#27304a"), night)
		var params := {
			"blur": 1.4 * depth * depth,
			"haze": 0.38 * depth * (1.0 - 0.5 * night),
			"haze_color": haze_c,
			"bevel_strength": lerpf(1.0, 0.45, depth),
			"bevel_radius": lerpf(3.5, 2.0, depth),
			"shadow_offset": Vector2(-7, -12) * lerpf(1.6, 0.6, depth),
			"shadow_alpha": lerpf(0.5, 0.25, depth),
			"shadow_blur": 3.0,
			"grain_strength": 0.16,
		}
		var grp := PaperFX.group(params, 32.0)
		var painter := _LayerPainter.new()
		painter.bd = self
		painter.idx = i
		grp.add_child(painter)
		add_child(grp)
		_paper_nodes.append(painter)
	if night > 0:
		var nv := ColorRect.new()
		nv.size = Vector2(W, H)
		nv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		nv.color = Color(0.05, 0.07, 0.15, night * 0.3)
		add_child(nv)


class _LayerPainter extends Node2D:
	var bd: Backdrop
	var idx := 0

	func _draw() -> void:
		if idx < 0:
			bd._draw_cave_paper(self)
		elif idx < bd._layers.size():
			bd._draw_layer(self, idx, true)
		else:
			bd._draw_ground(self, true)


## The sun and a few clouds, cut from paper and hung on thread from the top of the stage.
class _SkyProps extends Node2D:
	var bd: Backdrop
	var t := 0.0

	func _process(delta: float) -> void:
		t += delta
		queue_redraw()

	func _draw() -> void:
		var W := Backdrop.W
		var string_c := Color(0.2, 0.15, 0.1, 0.55)
		if bd.night <= 0.5:
			var sun := Vector2(1450 - bd.scroll * 0.02, 300 + sin(t * 0.6) * 4)
			draw_line(Vector2(sun.x, 0), sun + Vector2(0, -78), string_c, 2.0, true)
			for i in 10:
				draw_circle(sun, 84 + i * 16, Color(bd.pal("sun").r, bd.pal("sun").g, bd.pal("sun").b, 0.03))
			draw_circle(sun, 80, Figure.PAPER)
			draw_circle(sun, 74, bd.pal("sun"))
			# Hand-cut rays.
			for k in 12:
				var a := k * TAU / 12.0 + sin(t * 0.4) * 0.05
				var d := Vector2(cos(a), sin(a))
				var tip := sun + d * 108
				var bl := sun + d * 78 + d.orthogonal() * 12
				var br := sun + d * 78 - d.orthogonal() * 12
				draw_colored_polygon(PackedVector2Array([tip, bl, br]), bd.pal("sun").darkened(0.06))
		if bd.night > 0.5:
			# A paper moon and a few tin stars, all on threads.
			var moon := Vector2(420, 200 + sin(t * 0.5) * 3)
			draw_line(Vector2(moon.x, 0), moon + Vector2(0, -52), string_c, 2.0, true)
			var crescent := PackedVector2Array()
			for k in 25:
				var a := -PI * 0.5 + PI * k / 24.0
				crescent.append(moon + Vector2(cos(a), sin(a)) * 54)
			for k in 25:
				var a2 := PI * 0.5 - PI * k / 24.0
				crescent.append(moon + Vector2(-20 + cos(a2) * 40, sin(a2) * 46))
			draw_colored_polygon(crescent, Color("#f4efd8"))
			var srng := RandomNumberGenerator.new()
			srng.seed = 99
			for k in 9:
				var sp := Vector2(srng.randf_range(80, W - 80), srng.randf_range(70, 330) + sin(t * 0.7 + k) * 3)
				draw_line(Vector2(sp.x, 0), sp + Vector2(0, -12), Color(string_c, 0.35), 1.0, true)
				draw_colored_polygon(PackedVector2Array(Figure.star_pts(sp, 12, 5, 5)), Color("#e8d9a0"))
		var rng := RandomNumberGenerator.new()
		rng.seed = bd.seed_value + 3
		for i in 5:
			var cx := fposmod(rng.randf() * W * 1.5 - bd.scroll * 0.04, W * 1.5) - 200
			var cy := rng.randf_range(90, 280)
			var sway := sin(t * 0.8 + i * 1.3) * 5.0
			var base := Vector2(cx + sway, cy)
			draw_line(Vector2(cx + 90, 0), base + Vector2(90, -24), string_c, 2.0, true)
			var col := Color("#f7f1e3") if bd.night <= 0.5 else Color("#8a93a8")
			var puffs: Array = []
			for k in 5:
				puffs.append([base + Vector2(k * 46, (k % 2) * 8 - 6), 34 - absf(k - 2) * 6])
			for pf in puffs:
				draw_circle(pf[0], pf[1] + 5, Figure.PAPER.darkened(0.12))
			for pf in puffs:
				draw_circle(pf[0], pf[1], col)
			draw_rect(Rect2(base + Vector2(-20, 4), Vector2(224, 22)), col)


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


func _draw_prop(ci: CanvasItem, kind: String, p: Vector2, s: float, c: Color) -> void:
	match kind:
		"grass":
			for i in 5:
				var x := p.x + (i - 2) * 7 * s
				ci.draw_line(Vector2(x, p.y), Vector2(x + (i - 2) * 3 * s, p.y - (22 + (i % 3) * 8) * s), c.lightened(0.15), 3.0 * s)
		"tree":
			ci.draw_line(p, p + Vector2(0, -60 * s), c.darkened(0.2), 8 * s)
			for k in 3:
				ci.draw_circle(p + Vector2((k - 1) * 22 * s, -70 * s - (k % 2) * 16 * s), 30 * s, c)
		"fence":
			for i in 4:
				ci.draw_line(p + Vector2(i * 34 * s, 0), p + Vector2(i * 34 * s, -34 * s), c.darkened(0.25), 5 * s)
			ci.draw_line(p + Vector2(0, -26 * s), p + Vector2(102 * s, -26 * s), c.darkened(0.25), 4 * s)
			ci.draw_line(p + Vector2(0, -12 * s), p + Vector2(102 * s, -12 * s), c.darkened(0.25), 4 * s)
		"rock", "snowrock":
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-30, 0) * s, p + Vector2(-22, -24) * s, p + Vector2(4, -34) * s,
				p + Vector2(28, -18) * s, p + Vector2(34, 0) * s]), c.darkened(0.1))
			if kind == "snowrock":
				ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-22, -24) * s, p + Vector2(4, -34) * s, p + Vector2(28, -18) * s, p + Vector2(2, -24) * s]), Color("#eef3f6"))
		"cactus":
			ci.draw_line(p, p + Vector2(0, -70 * s), c.darkened(0.15), 12 * s)
			ci.draw_line(p + Vector2(0, -34 * s), p + Vector2(-18 * s, -34 * s), c.darkened(0.15), 9 * s)
			ci.draw_line(p + Vector2(-18 * s, -34 * s), p + Vector2(-18 * s, -54 * s), c.darkened(0.15), 9 * s)
			ci.draw_line(p + Vector2(0, -44 * s), p + Vector2(16 * s, -44 * s), c.darkened(0.15), 9 * s)
			ci.draw_line(p + Vector2(16 * s, -44 * s), p + Vector2(16 * s, -60 * s), c.darkened(0.15), 9 * s)
		"mesa":
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-80, 0) * s, p + Vector2(-60, -60) * s, p + Vector2(60, -60) * s, p + Vector2(80, 0) * s]), c.darkened(0.08))
		"skull":
			ci.draw_circle(p + Vector2(0, -10 * s), 10 * s, Color("#e9e2cf"))
			ci.draw_line(p + Vector2(-8, -16) * s, p + Vector2(-26, -26) * s, Color("#e9e2cf"), 4 * s)
			ci.draw_line(p + Vector2(8, -16) * s, p + Vector2(26, -26) * s, Color("#e9e2cf"), 4 * s)
		"pine":
			ci.draw_line(p, p + Vector2(0, -20 * s), c.darkened(0.3), 6 * s)
			for k in 3:
				var y := -20 - k * 26
				ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-30 + k * 7, y) * s, p + Vector2(30 - k * 7, y) * s, p + Vector2(0, y - 44) * s]), c.darkened(0.2))
		"cairn":
			for k in 4:
				ci.draw_circle(p + Vector2(0, -8 - k * 14) * s, (14 - k * 2.5) * s, c.lightened(0.1))


func _draw_cave() -> void:
	_draw_cave_on(self)


## The paper cave: rock sheets with cut edges, hanging stalactites, a stony floor.
func _draw_cave_paper(ci: CanvasItem) -> void:
	var edge := Color("#6a5a4a")
	ci.draw_rect(Rect2(0, 0, W, H), Color("#1a1511"))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in 4:
		var y := 200 + i * 130
		var pts := PackedVector2Array()
		pts.append(Vector2(-20, H))
		for k in 14:
			var x := k * 150.0 - fposmod(scroll * (0.2 + i * 0.15), 150.0)
			pts.append(Vector2(x, y + sin(k * 1.7 + i * 2.1 + seed_value) * 36 + rng.randf_range(-10, 10)))
		pts.append(Vector2(W + 20, H))
		var rim := pts.slice(1, pts.size() - 1)
		ci.draw_polyline(rim, edge.darkened(0.1 * i), 6.0, true)
		ci.draw_colored_polygon(pts, Color("#2f2822").lerp(Color("#4a3e33"), i / 4.0))
		for k in 16:
			var sx := rng.randf() * W
			var sy := y + 40 + rng.randf() * 120
			ci.draw_line(Vector2(sx, sy), Vector2(sx + rng.randf_range(10, 30), sy + 3), Color(0.1, 0.08, 0.06, 0.35), 1.5, true)
	for i in 16:
		var x2 := fposmod(rng.randf() * W * 1.5 - scroll * 0.9, W * 1.5) - 100
		var l := rng.randf_range(70, 230)
		var w2 := rng.randf_range(20, 48)
		var st := PackedVector2Array([Vector2(x2 - w2, -10), Vector2(x2 + w2, -10), Vector2(x2 + w2 * 0.3, l * 0.6), Vector2(x2 + 3, l)])
		ci.draw_polyline(PackedVector2Array([st[0], st[3], st[1]]), edge, 5.0, true)
		ci.draw_colored_polygon(st, Color("#3a3029"))
	ci.draw_rect(Rect2(0, ground_y - 4, W, 8), edge)
	ci.draw_rect(Rect2(0, ground_y, W, H - ground_y), Color("#3a3129"))
	for k in 30:
		var px := fposmod(rng.randf() * W - scroll, W)
		ci.draw_circle(Vector2(px, ground_y + 10 + rng.randf() * 60), rng.randf_range(4, 12), Color("#4d4136"))


func _draw_cave_on(ci: CanvasItem) -> void:
	var rock := Color("#2a2420")
	var rock2 := Color("#3a322b")
	ci.draw_rect(Rect2(0, 0, W, H), Color("#15110e"))
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
		ci.draw_colored_polygon(poly, rock.lerp(rock2, i / 5.0))
	# Stalactites.
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in 16:
		var x := fposmod(rng.randf() * W * 1.5 - scroll * 0.9, W * 1.5) - 100
		var l := rng.randf_range(60, 220)
		var w2 := rng.randf_range(18, 46)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x - w2, 0), Vector2(x + w2, 0), Vector2(x + 4, l)]), Color("#1d1814"))
	ci.draw_rect(Rect2(0, ground_y, W, H - ground_y), Color("#231d18"))
	ci.draw_rect(Rect2(0, ground_y, W, 5), Color("#3b3129"))
	# Lamplight: a warm pool around the party, darkness everywhere else.
	var glow_c := Vector2(640, ground_y - 150)
	var r0 := 260.0 + 520.0 * light
	for i in 8:
		var f := i / 8.0
		ci.draw_circle(glow_c, r0 * (1.0 - f * 0.6), Color(1.0, 0.75, 0.4, 0.035 + 0.02 * light))
	var dark := 0.72 - 0.5 * light
	ci.draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, clampf(dark, 0.0, 0.85) * 0.6))
