class_name Figure
extends Node2D
## Paper-cutout character drawn entirely in code from a "look" dictionary (see classes.json
## and enemies.json). Origin is at the feet; the figure faces right (enemies are flipped).
## Every piece gets a drop shadow and a cream paper edge, like layered cut paper.

const PAPER := Color("#f3e9d2")
const SHADOW := Color(0, 0, 0, 0.28)
const SKINS := ["#f1c9a5", "#e0ac86", "#c68863", "#a86b4a", "#7d4e34", "#5c3a26"]
const HAIRS := ["#2b1d14", "#4a3222", "#7a5230", "#b08a5a", "#8c8c8c", "#d9c9a3", "#1b1b1b"]
const BOOT := Color("#2b1d14")
const METAL := Color("#8c9096")
const DARK_METAL := Color("#3c3f44")
const WOOD := Color("#7a5232")

var look: Dictionary = {}
var look_seed: int = 0
var facing: int = 1
var pose: String = "idle"          # idle, aim, windup, strike, cast, hurt, dead
var flash: float = 0.0
var flash_color: Color = Color.WHITE
var muzzle: float = 0.0            # muzzle flash strength
var idle_anim: bool = true
var height_px: float = 200.0       # nominal height of a normal human at scale 1
var crafted: bool = PaperFX.enabled   # paper-theater detail: sculpted shading and pencil hatching

var _shapes: Array = []
var _t: float = 0.0
var _skin: Color
var _hair: Color
var _colors: Dictionary = {}
var _dirty := true
var _muzzle_pos := Vector2.ZERO


func setup(look_in: Dictionary, seed_value: int = 0, face: int = 1) -> void:
	look = look_in
	look_seed = seed_value
	facing = face
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var cols: Dictionary = look.get("colors", {})
	_skin = Color(cols.get("skin", SKINS[rng.randi() % SKINS.size()]))
	_hair = Color(HAIRS[rng.randi() % HAIRS.size()])
	_colors = {}
	for k in cols:
		var c := Color(cols[k])
		if k in ["coat", "pants"] and seed_value != 0:
			c = c.from_hsv(fposmod(c.h + rng.randf_range(-0.04, 0.04), 1.0), clampf(c.s * rng.randf_range(0.85, 1.15), 0, 1), clampf(c.v * rng.randf_range(0.9, 1.1), 0, 1))
		_colors[k] = c
	scale = Vector2(facing, 1) * float(look.get("scale", 1.0))
	_dirty = true
	queue_redraw()


func set_pose(p: String) -> void:
	if p != pose:
		pose = p
		_dirty = true
		queue_redraw()


func col(key: String, fallback: String = "#777777") -> Color:
	return _colors.get(key, Color(fallback))


## Approximate top of the head in local coordinates (for bars and labels).
func top_y() -> float:
	match look.get("body", "human"):
		"human", "ghost", "harpy":
			return -235.0
		"giant":
			return -300.0
		"wolf", "ram", "lizard", "snake", "crawler":
			return -120.0
		"bull", "bear":
			return -170.0
		"flock", "bird", "bat":
			return -210.0
		"swirl":
			return -230.0
	return -220.0


func _process(delta: float) -> void:
	if not idle_anim:
		return
	_t += delta
	var body: String = look.get("body", "human")
	if body in ["ghost", "swirl", "bird", "bat", "flock", "harpy"] or flash > 0.0 or muzzle > 0.0:
		_dirty = true
	queue_redraw()


func _draw() -> void:
	if _dirty:
		_shapes.clear()
		_build()
		if crafted:
			_add_hatching()
		_dirty = false
	var breathe := 1.0 + 0.012 * sin(_t * 2.2 + look_seed % 7) if idle_anim and pose != "dead" else 1.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, breathe))
	# Shadow pass.
	for s in _shapes:
		if s.get("glow", false):
			continue
		_draw_shape(s, SHADOW, Vector2(5 * facing, 6), 0.0)
	# Paper-edge pass.
	for s in _shapes:
		if s.get("glow", false) or s.get("no_edge", false):
			continue
		_draw_shape(s, PAPER, Vector2.ZERO, 4.0)
	# Fill pass.
	for s in _shapes:
		if crafted and not s.get("glow", false):
			_draw_sculpted(s)
		else:
			_draw_shape(s, s.c, Vector2.ZERO, 0.0)
	if muzzle > 0.05 and _muzzle_pos.is_finite():
		_draw_star(_muzzle_pos, 10 + 22 * muzzle, 5 + 8 * muzzle, 7, Color(1, 0.85, 0.35, muzzle))
		draw_circle(_muzzle_pos, 8 * muzzle, Color(1, 1, 0.9, muzzle))
	if flash > 0.01:
		for s in _shapes:
			if not s.get("glow", false):
				_draw_shape(s, Color(flash_color.r, flash_color.g, flash_color.b, flash * 0.75), Vector2.ZERO, 0.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Drops broken and repeated points so antialiased outlines never get zero-length
## segments (Godot can build runaway geometry from those, which stalls the GPU).
static func clean_line(pts: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		if not p.is_finite():
			continue
		if out.is_empty() or out[out.size() - 1].distance_squared_to(p) > 0.01:
			out.append(p)
	return out


func _draw_shape(s: Dictionary, c: Color, off: Vector2, edge: float) -> void:
	var cc := c
	if s.has("a") and c != PAPER and c != SHADOW:
		cc.a *= float(s.a)
	elif s.has("a"):
		cc.a *= float(s.a)
	match s.k:
		"poly":
			var pts: PackedVector2Array = s.pts
			if off != Vector2.ZERO:
				var moved := PackedVector2Array()
				for p in pts:
					moved.append(p + off)
				pts = moved
			pts = clean_line(pts)
			if pts.size() < 3:
				return
			if edge > 0.0:
				var closed := pts.duplicate()
				if closed[0].distance_squared_to(closed[closed.size() - 1]) > 0.01:
					closed.append(pts[0])
				draw_polyline(closed, cc, edge * 2.0, true)
			else:
				draw_colored_polygon(pts, cc)
		"circle":
			if not Vector2(s.p).is_finite() or float(s.r) + edge < 0.5:
				return
			draw_circle(s.p + off, s.r + edge, cc, true, -1.0, true)
		"line":
			var pts2: PackedVector2Array = s.pts
			if off != Vector2.ZERO:
				var moved2 := PackedVector2Array()
				for p in pts2:
					moved2.append(p + off)
				pts2 = moved2
			pts2 = clean_line(pts2)
			if pts2.size() < 2:
				return
			draw_polyline(pts2, cc, float(s.w) + edge * 2.0, true)
			if edge == 0.0 and pts2.size() > 0 and float(s.w) >= 1.0:
				draw_circle(pts2[0], float(s.w) / 2.0, cc)
				draw_circle(pts2[pts2.size() - 1], float(s.w) / 2.0, cc)


## Papier-mache volume: each piece is lit from the top left of the screen and falls into
## shadow toward the bottom right, with pencil hatching on the shadow side.
func _draw_sculpted(s: Dictionary) -> void:
	var c: Color = s.c
	if s.has("a"):
		c.a *= float(s.a)
	match s.k:
		"poly":
			var pts: PackedVector2Array = clean_line(s.pts)
			if pts.size() < 3:
				return
			var bb := _bounds(pts)
			var cols := PackedColorArray()
			for p in pts:
				var tx := (p.x - bb.position.x) / maxf(1.0, bb.size.x)
				if facing < 0:
					tx = 1.0 - tx
				var ty := (p.y - bb.position.y) / maxf(1.0, bb.size.y)
				var t := clampf(tx * 0.45 + ty * 0.55, 0.0, 1.0)
				cols.append(c.lightened(0.1 * (1.0 - t)).darkened(0.16 * t))
			draw_polygon(pts, cols)
			for h in s.get("hatch", []):
				if Vector2(h[0]).distance_squared_to(h[1]) > 0.25:
					draw_line(h[0], h[1], Color(c.darkened(0.45), 0.35 * c.a), 1.3, true)
		"circle":
			if not Vector2(s.p).is_finite() or float(s.r) < 0.5:
				return
			draw_circle(s.p, s.r, c.darkened(0.08), true, -1.0, true)
			var hl := Vector2(-s.r * 0.22 * facing, -s.r * 0.22)
			draw_circle(s.p + hl, s.r * 0.72, c.lightened(0.05), true, -1.0, true)
		_:
			_draw_shape(s, s.c, Vector2.ZERO, 0.0)


static func _bounds(pts: PackedVector2Array) -> Rect2:
	var r := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		r = r.expand(p)
	return r


## Pencil hatching clipped to the shadow side of the larger pieces.
func _add_hatching() -> void:
	for s in _shapes:
		if s.k != "poly" or s.get("no_edge", false) or s.get("glow", false):
			continue
		var pts: PackedVector2Array = s.pts
		var bb := _bounds(pts)
		if not bb.is_finite() or bb.size.x > 4000.0 or bb.size.y > 4000.0:
			continue
		if bb.size.x * bb.size.y < 900.0 or bb.size.x < 14.0:
			continue
		var segs: Array = []
		var step := 6.0
		var x := bb.position.x - bb.size.y
		while x < bb.end.x:
			var a := Vector2(x, bb.end.y)
			var b := Vector2(x + bb.size.y * 0.8, bb.position.y)
			for piece in Geometry2D.intersect_polyline_with_polygon(PackedVector2Array([a, b]), pts):
				if piece.size() < 2:
					continue
				var mid: Vector2 = (piece[0] + piece[piece.size() - 1]) / 2.0
				var tx := (mid.x - bb.position.x) / bb.size.x
				if facing < 0:
					tx = 1.0 - tx
				var ty := (mid.y - bb.position.y) / bb.size.y
				if tx * 0.45 + ty * 0.55 > 0.62:
					segs.append([piece[0], piece[piece.size() - 1]])
			x += step
		s["hatch"] = segs


# --- Shape helpers --------------------------------------------------------------------

func _poly(pts: Array, c: Color, extra: Dictionary = {}) -> void:
	var d := {"k": "poly", "pts": PackedVector2Array(pts), "c": c}
	d.merge(extra)
	_shapes.append(d)


func _circle(p: Vector2, r: float, c: Color, extra: Dictionary = {}) -> void:
	var d := {"k": "circle", "p": p, "r": r, "c": c}
	d.merge(extra)
	_shapes.append(d)


func _line(pts: Array, w: float, c: Color, extra: Dictionary = {}) -> void:
	var d := {"k": "line", "pts": PackedVector2Array(pts), "w": w, "c": c}
	d.merge(extra)
	_shapes.append(d)


static func ellipse(center: Vector2, rx: float, ry: float, n: int = 18, a0: float = 0.0, a1: float = TAU) -> Array:
	var pts: Array = []
	for i in n + 1:
		var a := a0 + (a1 - a0) * i / float(n)
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	if is_equal_approx(a1 - a0, TAU):
		pts.pop_back()
	return pts


static func rot(pts: Array, pivot: Vector2, ang: float) -> Array:
	var out: Array = []
	for p in pts:
		out.append(pivot + (p - pivot).rotated(ang))
	return out


static func star_pts(c: Vector2, r_out: float, r_in: float, n: int) -> Array:
	var pts: Array = []
	for i in n * 2:
		var r := r_out if i % 2 == 0 else r_in
		var a := -PI / 2 + PI * i / n
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


func _draw_star(c: Vector2, r_out: float, r_in: float, n: int, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array(star_pts(c, r_out, r_in, n)), color)


# --- Builders -------------------------------------------------------------------------

func _build() -> void:
	match look.get("body", "human"):
		"human":
			_build_human()
		"wolf":
			_build_quadruped("wolf")
		"bull":
			_build_quadruped("bull")
		"bear":
			_build_quadruped("bear")
		"ram":
			_build_quadruped("ram")
		"snake":
			_build_snake()
		"lizard":
			_build_lizard()
		"flock":
			_build_flock()
		"bird":
			_build_bird(Vector2(0, -120), 1.0)
		"bat":
			_build_bat()
		"harpy":
			_build_harpy()
		"ghost":
			_build_ghost()
		"swirl":
			_build_swirl()
		"crawler":
			_build_crawler()
		"giant":
			_build_giant()
		_:
			_build_human()


func _build_human() -> void:
	var build: String = look.get("build", "normal")
	var w: float = {"slim": 38.0, "normal": 44.0, "broad": 52.0, "heavy": 56.0, "tiny": 42.0}.get(build, 44.0)
	var hip := -92.0
	var sh := -158.0
	var head := Vector2(2, -180)
	var coat := col("coat")
	var pants := col("pants")
	var accent := col("accent", "#aa3333")
	var coat_kind: String = look.get("coat", "shirt")
	var shirt := Color("#d8cbb0")
	var lean := 0.0
	match pose:
		"aim":
			lean = 0.04
		"windup":
			lean = -0.08
		"strike":
			lean = 0.14
		"hurt":
			lean = -0.16
		"cast":
			lean = -0.05
	var pivot := Vector2(0, -10)

	# Hand positions per pose.
	var shoulder_f := Vector2(w / 2 - 6, sh + 8)
	var shoulder_b := Vector2(-w / 2 + 8, sh + 8)
	var hand_f := Vector2(w / 2 + 12, hip + 4)
	var hand_b := Vector2(-w / 2 + 2, hip + 6)
	var weapon_ang := 1.1
	var weapon: String = look.get("weapon", "none")
	var long_melee: bool = weapon in ["axe", "hammer", "pickaxe", "big_pickaxe", "club"]
	var long_gun: bool = weapon in ["rifle", "shotgun", "blowgun"]
	if long_melee:
		hand_f = Vector2(w / 2 + 10, hip - 6)
		weapon_ang = 1.05
	if long_gun:
		hand_f = Vector2(w / 2 + 10, hip - 8)
		hand_b = Vector2(w / 2 - 14, hip - 18)
		weapon_ang = -0.45
	match pose:
		"aim":
			hand_f = shoulder_f + Vector2(40, 4)
			weapon_ang = 0.0
			if long_gun:
				hand_b = shoulder_f + Vector2(14, 10)
				hand_f = shoulder_f + Vector2(30, 6)
			if weapon == "pistols":
				hand_b = shoulder_b + Vector2(44, 14)
		"windup":
			hand_f = shoulder_f + Vector2(-6, -34)
			weapon_ang = -2.4 if long_melee else -1.2
		"strike":
			hand_f = shoulder_f + Vector2(38, 18)
			weapon_ang = 0.5 if long_melee else 0.2
		"cast":
			hand_f = shoulder_f + Vector2(16, -46)
			weapon_ang = -1.4
		"hurt":
			hand_f = shoulder_f + Vector2(10, 30)
			weapon_ang = 1.5

	var parts_start := _shapes.size()
	# Lantern at the hip (behind).
	if look.get("extra", "") == "lantern":
		_line([Vector2(-w / 2 - 2, hip + 2), Vector2(-w / 2 - 8, hip + 18)], 2.0, DARK_METAL)
		_circle(Vector2(-w / 2 - 8, hip + 30), 22.0, Color(1, 0.8, 0.3, 0.18), {"glow": true})
		_poly([Vector2(-w / 2 - 15, hip + 18), Vector2(-w / 2 - 1, hip + 18), Vector2(-w / 2 - 3, hip + 40), Vector2(-w / 2 - 13, hip + 40)], Color("#f2c14e"))
	# Coat tails behind the legs.
	var tail_y: float = {"duster": -34.0, "long": -44.0, "frock": -54.0}.get(coat_kind, 0.0)
	if tail_y != 0.0:
		_poly([Vector2(-w / 2 - 3, hip - 6), Vector2(w / 2 + 3, hip - 6), Vector2(w / 2 + 12, tail_y), Vector2(-w / 2 - 14, tail_y)], coat.darkened(0.12))
	# Back arm (behind the body).
	_arm(shoulder_b, hand_b, coat.darkened(0.25), false)
	if weapon == "pistols":
		_weapon("pistol", hand_b, 0.0 if pose == "aim" else 1.2, true)
	# Legs.
	var leg_c := pants
	if crafted:
		# Storybook legs: tapered, a little bend at the knee, big boots with heels.
		_poly([Vector2(-17, hip), Vector2(1, hip), Vector2(-1, -52), Vector2(-4, -12), Vector2(-15, -12), Vector2(-18, -52)], leg_c.darkened(0.15))
		_poly([Vector2(-2, hip), Vector2(16, hip), Vector2(15, -52), Vector2(13, -12), Vector2(2, -12), Vector2(0, -52)], leg_c)
		if coat_kind == "chaps":
			_poly([Vector2(0, hip + 10), Vector2(17, hip + 8), Vector2(15, -16), Vector2(3, -16)], coat)
		_poly([Vector2(-19, -15), Vector2(-3, -15), Vector2(-1, -7), Vector2(4, -5), Vector2(4, 0), Vector2(-21, 0), Vector2(-21, -5)], BOOT)
		_poly([Vector2(0, -15), Vector2(15, -15), Vector2(17, -8), Vector2(25, -5), Vector2(26, 0), Vector2(-1, 0), Vector2(-1, -5)], BOOT)
	else:
		_poly([Vector2(-16, hip), Vector2(0, hip), Vector2(-3, -9), Vector2(-15, -9)], leg_c.darkened(0.15))
		_poly([Vector2(-2, hip), Vector2(15, hip), Vector2(13, -9), Vector2(1, -9)], leg_c)
		if coat_kind == "chaps":
			_poly([Vector2(0, hip + 10), Vector2(16, hip + 8), Vector2(15, -14), Vector2(3, -14)], coat)
		_poly([Vector2(-18, -11), Vector2(-1, -11), Vector2(2, 0), Vector2(-19, 0)], BOOT)
		_poly([Vector2(-1, -11), Vector2(15, -11), Vector2(22, 0), Vector2(-1, 0)], BOOT)
	# Torso.
	var torso := [Vector2(-w / 2, hip + 4), Vector2(w / 2, hip + 4)]
	if crafted:
		# Broad rounded shoulders over a narrower waist.
		torso = [Vector2(-w / 2 + 3, hip + 4), Vector2(w / 2 - 3, hip + 4)]
		if build == "heavy":
			torso.append(Vector2(w / 2 + 8, hip - 28))
		torso.append_array([Vector2(w / 2 + 5, sh + 16), Vector2(w / 2 + 2, sh + 5), Vector2(w / 2 - 6, sh - 1),
			Vector2(-w / 2 + 6, sh - 1), Vector2(-w / 2 - 2, sh + 5), Vector2(-w / 2 - 5, sh + 16)])
	else:
		if build == "heavy":
			torso.append(Vector2(w / 2 + 7, hip - 26))
		torso.append_array([Vector2(w / 2 + 2, sh + 8), Vector2(w / 2 - 6, sh), Vector2(-w / 2 + 6, sh), Vector2(-w / 2 - 2, sh + 8)])
	match coat_kind:
		"vest", "overalls":
			_poly(torso, shirt)
			if coat_kind == "vest":
				_poly([Vector2(-w / 2, hip + 4), Vector2(2, hip + 4), Vector2(-2, sh + 2), Vector2(-w / 2 + 6, sh), Vector2(-w / 2 - 2, sh + 8)], coat)
				_poly([Vector2(8, hip + 4), Vector2(w / 2, hip + 4), Vector2(w / 2 + 2, sh + 8), Vector2(w / 2 - 6, sh), Vector2(12, sh + 2)], coat)
			else:
				_poly([Vector2(-w / 2 + 4, hip + 4), Vector2(w / 2 - 4, hip + 4), Vector2(w / 2 - 8, sh + 30), Vector2(-w / 2 + 8, sh + 30)], coat)
				_line([Vector2(-w / 2 + 10, sh + 32), Vector2(-w / 2 + 12, sh + 2)], 4.0, coat)
				_line([Vector2(w / 2 - 10, sh + 32), Vector2(w / 2 - 12, sh + 2)], 4.0, coat)
		_:
			_poly(torso, coat)
			if coat_kind in ["duster", "long", "frock"]:
				_line([Vector2(6, hip + 4), Vector2(2, sh + 4)], 2.0, coat.darkened(0.3))
			if coat_kind == "buckskin":
				for i in 7:
					var x := -w / 2 + 4 + i * (w - 8) / 6.0
					_line([Vector2(x, hip + 4), Vector2(x + 1, hip + 16)], 2.0, coat.darkened(0.2))
	# Belt.
	_poly([Vector2(-w / 2 - 1, hip + 6), Vector2(w / 2 + 1, hip + 6), Vector2(w / 2 + 1, hip - 2), Vector2(-w / 2 - 1, hip - 2)], Color("#2e2118"))
	_poly([Vector2(2, hip + 5), Vector2(10, hip + 5), Vector2(10, hip - 1), Vector2(2, hip - 1)], Color("#c9a227"))
	# Neck & head.
	_poly([Vector2(-5, sh + 2), Vector2(8, sh + 2), Vector2(8, sh - 10), Vector2(-5, sh - 10)], _skin.darkened(0.1))
	var extra: String = look.get("extra", "")
	if extra == "collar":
		_poly([Vector2(-7, sh + 3), Vector2(10, sh + 3), Vector2(10, sh - 4), Vector2(-7, sh - 4)], Color("#f2efe6"))
	if extra == "bandana":
		_poly([Vector2(-9, sh + 2), Vector2(12, sh + 2), Vector2(3, sh + 18)], accent)
	_circle(head, 16.0, _skin)
	# Hair at the back of the head.
	_poly(ellipse(head + Vector2(-6, -2), 11, 13, 10, PI * 0.5, PI * 1.5), _hair)
	if look.get("beard", false):
		_poly([Vector2(-6, -178), Vector2(18, -176), Vector2(14, -160), Vector2(2, -156), Vector2(-6, -166)], _hair)
	if extra == "mustache" or look.get("beard", false):
		_poly([Vector2(8, -175), Vector2(20, -174), Vector2(22, -169), Vector2(8, -171)], _hair.darkened(0.1))
	if extra == "bandana_mask":
		_poly([Vector2(-8, -178), Vector2(19, -178), Vector2(18, -166), Vector2(4, -160), Vector2(-8, -166)], accent)
	# Face: nose, brow and eye.
	_poly([head + Vector2(13, -3), head + Vector2(20, 4), head + Vector2(13, 6)], _skin.darkened(0.12), {"no_edge": true})
	_line([head + Vector2(4, -10), head + Vector2(13, -9)], 2.0, _hair.darkened(0.2), {"no_edge": true})
	if crafted:
		# A storybook eye with a white, and a touch of color in the cheek.
		_circle(head + Vector2(3, 5), 4.0, Color(0.85, 0.35, 0.3, 0.22), {"no_edge": true})
		_circle(head + Vector2(8, -4), 3.6, Color("#f4efe4"), {"no_edge": true})
		_circle(head + Vector2(9, -4), 2.2, Color("#1a1210"), {"no_edge": true})
	else:
		_circle(head + Vector2(8, -4), 2.2, Color("#1a1210"), {"no_edge": true})
	if extra == "spectacles":
		_circle(head + Vector2(9, -4), 5.0, Color(0.8, 0.85, 0.9, 0.5), {"no_edge": true})
		_line([head + Vector2(4, -4), head + Vector2(14, -4)], 1.5, DARK_METAL, {"no_edge": true})
	_hat(head)
	# Crow gang markings: a black feather in the hat band, a crow on the shoulder.
	if look.get("feather", false):
		var fy := head.y - 14
		_poly([Vector2(-12, fy), Vector2(-17, fy - 14), Vector2(-26, fy - 34), Vector2(-20, fy - 36), Vector2(-12, fy - 20), Vector2(-8, fy - 2)], Color("#15131a"))
		_line([Vector2(-10, fy), Vector2(-22, fy - 34)], 1.5, Color("#4a4652"), {"no_edge": true})
	if look.get("pet", "") == "crow":
		var cp := Vector2(-w / 2 + 6, sh - 4)
		_poly(ellipse(cp + Vector2(0, -8), 13, 9, 12), Color("#17161c"))
		_poly([cp + Vector2(-10, -6), cp + Vector2(-26, 2), cp + Vector2(-22, -10)], Color("#17161c"))
		_circle(cp + Vector2(10, -18), 7.0, Color("#1d1c22"))
		_poly([cp + Vector2(15, -21), cp + Vector2(26, -17), cp + Vector2(15, -15)], Color("#3a3530"), {"no_edge": true})
		_circle(cp + Vector2(12, -20), 1.6, Color("#d9d2c0"), {"no_edge": true})
	# Badge on the chest.
	if extra == "badge":
		_poly(star_pts(Vector2(w / 2 - 12, sh + 24), 7, 3, 5), col("accent", "#d9b44a"))
	# Front arm and weapon.
	if weapon != "pistols" or true:
		_arm(shoulder_f, hand_f, coat.darkened(0.05) if coat_kind != "vest" and coat_kind != "overalls" else shirt, true)
	if weapon == "pistols":
		_weapon("pistol", hand_f, weapon_ang, false)
	else:
		_weapon(weapon, hand_f, weapon_ang, false)
	if extra == "dog":
		_dog(Vector2(w / 2 + 34, 0))
	# Lean the whole figure.
	if lean != 0.0:
		for i in range(parts_start, _shapes.size()):
			var s: Dictionary = _shapes[i]
			if s.k == "circle":
				s.p = pivot + (s.p - pivot).rotated(lean)
			else:
				var arr: Array = Array(s.pts)
				s.pts = PackedVector2Array(rot(arr, pivot, lean))
		_muzzle_pos = pivot + (_muzzle_pos - pivot).rotated(lean)


func _arm(shoulder: Vector2, hand: Vector2, c: Color, front: bool) -> void:
	var mid := (shoulder + hand) / 2.0 + Vector2(-4 if front else 4, 6)
	_line([shoulder, mid, hand], 12.0 if front else 11.0, c)
	_circle(hand, 6.5, _skin if front else _skin.darkened(0.2))


func _hat(head: Vector2) -> void:
	var hat: String = look.get("hat", "none")
	var hc := col("hat", "#3a2e24")
	var y := head.y - 8
	match hat:
		"cowboy", "stetson", "stetson_black", "cowboy_wide":
			var bw := 40.0 if hat == "cowboy_wide" else (32.0 if hat != "stetson" and hat != "stetson_black" else 34.0)
			var ch := 26.0 if hat in ["stetson", "stetson_black"] else 20.0
			_poly([Vector2(-bw, y - 2), Vector2(-bw + 6, y - 6), Vector2(bw - 6, y - 6), Vector2(bw + 4, y - 4), Vector2(bw, y + 1), Vector2(0, y - 2)], hc)
			_poly([Vector2(-14, y - 5), Vector2(16, y - 5), Vector2(14, y - 5 - ch), Vector2(1, y - ch), Vector2(-12, y - 5 - ch)], hc.lightened(0.05))
			_poly([Vector2(-14, y - 5), Vector2(16, y - 5), Vector2(15.5, y - 10), Vector2(-13.5, y - 10)], col("accent", "#8b2e2e").darkened(0.2))
		"coonskin":
			_poly(ellipse(Vector2(head.x, y - 4), 18, 14, 12, PI, TAU), hc)
			_line([Vector2(head.x - 16, y - 2), Vector2(head.x - 26, y + 16), Vector2(head.x - 30, y + 36)], 7.0, hc.darkened(0.1))
			_line([Vector2(head.x - 28, y + 26), Vector2(head.x - 30, y + 36)], 7.0, Color("#2b1d14"))
		"bowler":
			_poly(ellipse(Vector2(head.x, y - 6), 15, 14, 12, PI, TAU), hc)
			_poly([Vector2(-22, y - 4), Vector2(24, y - 4), Vector2(24, y - 8), Vector2(-22, y - 8)], hc.darkened(0.1))
		"top":
			_poly([Vector2(-24, y - 2), Vector2(26, y - 2), Vector2(26, y - 7), Vector2(-24, y - 7)], hc)
			_poly([Vector2(-13, y - 6), Vector2(15, y - 6), Vector2(16, y - 46), Vector2(-12, y - 46)], hc)
			_poly([Vector2(-13, y - 8), Vector2(15, y - 8), Vector2(15, y - 14), Vector2(-13, y - 14)], col("accent", "#555555"))
		"preacher":
			_poly([Vector2(-36, y - 1), Vector2(38, y - 1), Vector2(38, y - 6), Vector2(-36, y - 6)], hc)
			_poly(ellipse(Vector2(head.x, y - 5), 15, 13, 12, PI, TAU), hc)
		"flat_cap":
			_poly([Vector2(-17, y + 2), Vector2(24, y + 2), Vector2(30, y + 5), Vector2(20, y - 10), Vector2(-14, y - 12), Vector2(-18, y - 4)], hc)
		"slouch":
			_poly([Vector2(-32, y + 6), Vector2(-20, y - 3), Vector2(20, y - 3), Vector2(34, y + 7), Vector2(28, y + 9), Vector2(0, y + 1), Vector2(-28, y + 10)], hc)
			_poly(ellipse(Vector2(head.x, y - 4), 16, 14, 12, PI, TAU), hc.lightened(0.06))
		"kepi":
			_poly([Vector2(-14, y), Vector2(15, y), Vector2(11, y - 22), Vector2(-12, y - 19)], hc)
			_poly([Vector2(13, y + 1), Vector2(28, y + 3), Vector2(14, y - 3)], hc.darkened(0.3))
		"miner":
			_poly(ellipse(Vector2(head.x, y - 2), 18, 16, 12, PI, TAU), hc)
			_circle(Vector2(head.x + 14, y - 6), 26.0, Color(1, 0.9, 0.5, 0.18), {"glow": true})
			_circle(Vector2(head.x + 14, y - 6), 5.0, Color("#fff3b0"))


func _weapon(kind: String, hand: Vector2, ang: float, back: bool) -> void:
	var gun := DARK_METAL if not back else DARK_METAL.darkened(0.2)
	var dir := Vector2.RIGHT.rotated(ang)
	match kind:
		"pistol":
			var tip := hand + dir * 26
			_line([hand, tip], 6.0, gun)
			_line([hand, hand + dir.rotated(1.9) * 12], 6.0, WOOD)
			if not back:
				_muzzle_pos = tip + dir * 6
		"blowgun":
			# A long cane tube, bound with twine, a dart pouch at the hip.
			var tip := hand + dir * 70
			_line([hand - dir * 40, tip], 5.0, WOOD.lightened(0.15))
			for k in 3:
				var at := hand + dir * (-24 + k * 34)
				_line([at - dir.orthogonal() * 3.5, at + dir.orthogonal() * 3.5], 3.0, WOOD.darkened(0.35))
			if not back:
				_muzzle_pos = tip + dir * 4
		"rifle", "shotgun":
			var length := 92.0 if kind == "rifle" else 70.0
			var tip := hand + dir * length * 0.62
			_line([hand - dir * length * 0.38, hand], 8.0, WOOD)
			_line([hand, tip], 5.0 if kind == "rifle" else 7.0, gun)
			_muzzle_pos = tip + dir * 6
		"axe":
			var tip := hand + dir * 62
			_line([hand - dir * 10, tip], 6.0, WOOD)
			var n := dir.orthogonal()
			_poly([tip + n * 4 - dir * 4, tip + n * 22 - dir * 10, tip + n * 22 + dir * 12, tip + n * 4 + dir * 6], METAL)
		"hammer":
			var tip := hand + dir * 78
			_line([hand - dir * 12, tip], 6.0, WOOD)
			var n2 := dir.orthogonal()
			_poly([tip - dir * 10 + n2 * 20, tip + dir * 10 + n2 * 20, tip + dir * 10 - n2 * 12, tip - dir * 10 - n2 * 12], DARK_METAL)
		"pickaxe":
			var tip := hand + dir * 64
			_line([hand - dir * 8, tip], 6.0, WOOD)
			var n3 := dir.orthogonal()
			_poly([tip + n3 * 30 - dir * 12, tip + n3 * 4 + dir * 4, tip - n3 * 26 - dir * 10, tip - n3 * 4 - dir * 6], METAL)
		"big_pickaxe":
			# Comically oversized: a full-size miner's pick in very small hands.
			var tip := hand + dir * 118
			_line([hand - dir * 16, tip], 10.0, WOOD)
			var n4 := dir.orthogonal()
			_poly([tip + n4 * 58 - dir * 26, tip + n4 * 8 + dir * 9, tip - n4 * 50 - dir * 22, tip - n4 * 8 - dir * 12], METAL)
			_line([tip + n4 * 10 + dir * 6, tip - n4 * 10 + dir * 6], 5.0, METAL.darkened(0.3))
		"club":
			var tip := hand + dir * 56
			_poly([hand + dir.orthogonal() * 3, hand - dir.orthogonal() * 3, tip - dir.orthogonal() * 8, tip + dir.orthogonal() * 8], WOOD.darkened(0.2))
		"knife":
			_line([hand, hand + dir * 24], 4.0, METAL)
			_line([hand - dir * 6, hand], 5.0, WOOD)
		"cards":
			for i in 3:
				var a := ang - 0.9 + i * 0.35
				var d2 := Vector2.RIGHT.rotated(a)
				var o := hand + d2 * 6
				_poly([o, o + d2 * 20, o + d2 * 20 + d2.orthogonal() * 13, o + d2.orthogonal() * 13], Color("#f4f1e8"))
		"bible":
			_poly([hand + Vector2(-6, -14), hand + Vector2(14, -14), hand + Vector2(14, 12), hand + Vector2(-6, 12)], Color("#2a1a12"))
			_line([hand + Vector2(4, -8), hand + Vector2(4, 6)], 2.0, Color("#d9b44a"), {"no_edge": true})
			_line([hand + Vector2(-1, -3), hand + Vector2(9, -3)], 2.0, Color("#d9b44a"), {"no_edge": true})
		"lasso":
			_line([hand, hand + Vector2(4, 20)], 3.0, Color("#c8a46a"))
			var loop := ellipse(hand + Vector2(8, 38), 16, 20, 14)
			loop.append(loop[0])
			_line(loop, 3.0, Color("#c8a46a"))
		"bag":
			_poly([hand + Vector2(-14, 4), hand + Vector2(16, 4), hand + Vector2(20, 30), hand + Vector2(-18, 30)], Color("#3b2418"))
			_line([hand + Vector2(-6, 4), hand + Vector2(-4, -4), hand + Vector2(6, -4), hand + Vector2(8, 4)], 3.0, Color("#3b2418"))
		"dynamite":
			var tip := hand + dir * 18
			_line([hand, tip], 8.0, Color("#b83227"))
			_circle(tip + dir * 6, 3.0, Color("#ffd166"), {"no_edge": true})
		"fists":
			_circle(hand, 8.0, _skin)


func _dog(at: Vector2) -> void:
	var fur := Color("#8a6a45")
	var s := 0.42
	_poly([at + Vector2(-40, -44) * s, at + Vector2(36, -48) * s, at + Vector2(40, -26) * s, at + Vector2(-38, -24) * s], fur)
	for x in [-30.0, -18.0, 22.0, 32.0]:
		_line([at + Vector2(x, -28) * s, at + Vector2(x, 0) * s], 5.0, fur.darkened(0.15))
	_poly([at + Vector2(30, -50) * s, at + Vector2(58, -58) * s, at + Vector2(66, -44) * s, at + Vector2(38, -36) * s], fur)
	_poly([at + Vector2(38, -54) * s, at + Vector2(44, -74) * s, at + Vector2(50, -56) * s], fur.darkened(0.2))
	_line([at + Vector2(-40, -42) * s, at + Vector2(-56, -60) * s], 4.0, fur)


func _build_quadruped(kind: String) -> void:
	var fur := col("fur", "#6d6258")
	var belly := col("belly", "#a39686")
	var eye := col("eye", "#e8c547")
	var sx := 1.0
	var body_h := 44.0
	var body_len := 110.0
	var leg_h := 50.0
	match kind:
		"bull":
			body_h = 72.0
			body_len = 150.0
			leg_h = 46.0
		"bear":
			body_h = 78.0
			body_len = 130.0
			leg_h = 40.0
		"ram":
			body_h = 56.0
			body_len = 110.0
			leg_h = 38.0
	var lunge := 14.0 if pose in ["strike", "aim"] else (-8.0 if pose == "hurt" else 0.0)
	var top := -leg_h - body_h
	var x0 := -body_len / 2
	var x1 := body_len / 2
	# Far legs.
	for x in [x0 + 18, x1 - 22]:
		_line([Vector2(x + 6, top + body_h - 6), Vector2(x + 10, -2)], 11.0, fur.darkened(0.3))
	# Tail.
	if kind == "wolf":
		_line([Vector2(x0 + 4, top + 12), Vector2(x0 - 30, top + 30), Vector2(x0 - 42, top + 52)], 12.0, fur.darkened(0.1))
	elif kind == "bull":
		_line([Vector2(x0 + 2, top + 16), Vector2(x0 - 10, top + 50)], 4.0, fur.darkened(0.2))
	# Body.
	var body: Array = []
	if kind == "bull":
		body = [Vector2(x0, top + 20), Vector2(x0 + 30, top + 4), Vector2(x1 - 50, top - 22), Vector2(x1 - 10, top + 6), Vector2(x1, top + body_h - 10), Vector2(x1 - 30, top + body_h), Vector2(x0 + 20, top + body_h), Vector2(x0 - 4, top + body_h - 18)]
	elif kind == "bear":
		body = ellipse(Vector2(0, top + body_h / 2), body_len / 2, body_h / 2 + 6, 16)
	elif kind == "ram":
		body = [Vector2(x0, top + 14), Vector2(x0 + 18, top), Vector2(x0 + 50, top - 6), Vector2(x1 - 20, top), Vector2(x1, top + 16), Vector2(x1 - 4, top + body_h - 8), Vector2(x1 - 30, top + body_h), Vector2(x0 + 20, top + body_h), Vector2(x0 - 2, top + body_h - 14)]
	else:
		body = [Vector2(x0, top + 8), Vector2(x0 + 30, top - 2), Vector2(x1 - 26, top), Vector2(x1, top + 10), Vector2(x1 - 6, top + body_h - 8), Vector2(x1 - 36, top + body_h), Vector2(x0 + 24, top + body_h - 2), Vector2(x0 - 2, top + body_h - 12)]
	_poly(body, fur)
	_poly([Vector2(x0 + 26, top + body_h - 10), Vector2(x1 - 34, top + body_h - 8), Vector2(x1 - 44, top + body_h), Vector2(x0 + 30, top + body_h)], belly)
	if kind == "ram":
		for i in 4:
			var cx := x0 + 20 + i * 22
			_line([Vector2(cx, top + 6), Vector2(cx + 10, top + body_h - 10)], 2.0, fur.darkened(0.25), {"no_edge": true})
	# Near legs.
	for x in [x0 + 26, x1 - 16]:
		_line([Vector2(x, top + body_h - 8), Vector2(x + 2, -2)], 12.0 if kind != "bull" else 16.0, fur.darkened(0.1))
		_line([Vector2(x + 2, -8), Vector2(x + 6, -1)], 12.0, BOOT)
	# Head.
	var hx := x1 + lunge
	var hy := top + (4.0 if kind in ["wolf"] else 18.0)
	if kind == "wolf":
		_poly([Vector2(hx - 20, hy - 6), Vector2(hx + 4, hy - 18), Vector2(hx + 20, hy - 12), Vector2(hx + 46, hy + 2), Vector2(hx + 44, hy + 12), Vector2(hx + 10, hy + 18), Vector2(hx - 16, hy + 16)], fur)
		_poly([Vector2(hx - 2, hy - 14), Vector2(hx + 4, hy - 38), Vector2(hx + 14, hy - 14)], fur.darkened(0.2))
		if pose in ["strike", "aim"]:
			_poly([Vector2(hx + 20, hy + 10), Vector2(hx + 44, hy + 12), Vector2(hx + 36, hy + 24)], Color("#5a1a1a"))
		_circle(Vector2(hx + 16, hy - 6), 3.0, eye, {"no_edge": true})
	elif kind == "bull":
		_poly([Vector2(hx - 24, hy - 10), Vector2(hx + 18, hy - 6), Vector2(hx + 30, hy + 26), Vector2(hx + 16, hy + 40), Vector2(hx - 14, hy + 32)], fur.darkened(0.15))
		_line([Vector2(hx - 6, hy - 6), Vector2(hx + 4, hy - 30), Vector2(hx + 20, hy - 34)], 6.0, Color("#e9dfc8"))
		_circle(Vector2(hx + 8, hy + 8), 3.0, eye, {"no_edge": true})
	elif kind == "bear":
		_circle(Vector2(hx + 4, hy - 4), 28.0, fur)
		_circle(Vector2(hx - 8, hy - 30), 9.0, fur.darkened(0.15))
		_poly([Vector2(hx + 14, hy - 8), Vector2(hx + 44, hy), Vector2(hx + 40, hy + 14), Vector2(hx + 14, hy + 16)], belly)
		_circle(Vector2(hx + 14, hy - 10), 3.0, eye, {"no_edge": true})
	elif kind == "ram":
		_poly([Vector2(hx - 16, hy - 14), Vector2(hx + 16, hy - 10), Vector2(hx + 34, hy + 14), Vector2(hx + 20, hy + 26), Vector2(hx - 10, hy + 18)], fur.lightened(0.05))
		var horn := ellipse(Vector2(hx - 2, hy + 2), 18, 18, 14, -PI * 0.9, PI * 0.9)
		_line(horn, 9.0, Color("#b8ad96"))
		_circle(Vector2(hx + 12, hy), 3.5, eye, {"no_edge": true})
		_circle(Vector2(hx + 12, hy), 8.0, Color(eye.r, eye.g, eye.b, 0.25), {"glow": true})


func _build_snake() -> void:
	var fur := col("fur")
	var belly := col("belly")
	var rise := 20.0 if pose in ["strike", "aim"] else 0.0
	var coil := ellipse(Vector2(-10, -22), 46, 20, 20)
	_poly(coil, fur.darkened(0.1))
	_poly(ellipse(Vector2(-10, -30), 30, 12, 16), fur)
	for i in 6:
		var x := -44 + i * 14.0
		_poly([Vector2(x, -36), Vector2(x + 8, -40), Vector2(x + 12, -32), Vector2(x + 4, -28)], fur.darkened(0.35), {"no_edge": true})
	_line([Vector2(-6, -34), Vector2(14, -70 - rise), Vector2(34, -96 - rise)], 14.0, fur)
	_poly([Vector2(28, -104 - rise), Vector2(58, -98 - rise), Vector2(62, -90 - rise), Vector2(30, -86 - rise)], fur.lightened(0.05))
	_circle(Vector2(44, -98 - rise), 2.5, col("eye"), {"no_edge": true})
	_line([Vector2(60, -94 - rise), Vector2(72, -92 - rise)], 2.0, Color("#b0302a"), {"no_edge": true})
	# Rattle.
	_line([Vector2(-56, -26), Vector2(-66, -44 + sin(_t * 30) * 3), Vector2(-70, -58)], 7.0, belly)
	_poly(ellipse(Vector2(-6, -18), 38, 8, 12), belly, {"no_edge": true, "a": 0.6})


func _build_lizard() -> void:
	var fur := col("fur")
	var belly := col("belly")
	var lunge := 16.0 if pose in ["strike", "aim"] else 0.0
	_line([Vector2(-60, -20), Vector2(-96, -12), Vector2(-120, -4)], 16.0, fur)
	for x in [-40.0, 30.0]:
		_line([Vector2(x, -18), Vector2(x - 8, 0)], 9.0, fur.darkened(0.2))
	_poly([Vector2(-66, -30), Vector2(-20, -46), Vector2(40, -44), Vector2(66, -30), Vector2(60, -12), Vector2(-60, -10)], fur)
	for i in 8:
		var x := -56 + i * 15.0
		_circle(Vector2(x, -30 + (i % 2) * 8), 5.0, belly, {"no_edge": true})
	for x in [-30.0, 44.0]:
		_line([Vector2(x, -14), Vector2(x + 8, 0)], 10.0, fur.darkened(0.05))
	_poly([Vector2(56 + lunge, -42), Vector2(98 + lunge, -34), Vector2(98 + lunge, -20), Vector2(58 + lunge, -16)], fur.darkened(0.1))
	_circle(Vector2(80 + lunge, -34), 3.0, col("eye"), {"no_edge": true})


func _build_bird(center: Vector2, s: float) -> void:
	var fur := col("fur")
	var belly := col("belly")
	var flap := sin(_t * 9.0 + center.x * 0.1) * 0.5
	var wing_up := Vector2(-10, -60 - 30 * flap) * s
	_poly([center + Vector2(-8, -4) * s, center + wing_up + Vector2(-50, -10) * s, center + wing_up + Vector2(20, 0) * s, center + Vector2(20, -6) * s], fur.darkened(0.15))
	_poly(ellipse(center, 34 * s, 16 * s, 14), fur)
	_poly(ellipse(center + Vector2(4, 6) * s, 24 * s, 8 * s, 10), belly, {"no_edge": true})
	_circle(center + Vector2(32, -10) * s, 12 * s, fur)
	_poly([center + Vector2(40, -14) * s, center + Vector2(58, -8) * s, center + Vector2(40, -4) * s], Color("#e0a030"))
	_circle(center + Vector2(36, -13) * s, 2.5 * s, col("eye"), {"no_edge": true})
	_poly([center + Vector2(-30, -4) * s, center + Vector2(-58, -14) * s, center + Vector2(-58, 8) * s], fur.darkened(0.2))
	_poly([center + Vector2(-4, 0) * s, center + wing_up * Vector2(1, -0.3) + Vector2(-44, 30) * s, center + Vector2(24, 4) * s], fur.darkened(0.05))
	if look.get("body", "") == "bird" and s >= 1.0:
		_line([center + Vector2(-20, 20), center + Vector2(-10, 40), center + Vector2(-24, 52), center + Vector2(-12, 70)], 3.0, Color("#bfe8ff"), {"glow": true})


func _build_flock() -> void:
	_build_bird(Vector2(-30, -60), 0.55)
	_build_bird(Vector2(30, -110), 0.6)
	_build_bird(Vector2(-20, -160), 0.5)
	_build_bird(Vector2(40, -40), 0.45)


func _build_bat() -> void:
	var fur := col("fur")
	var flap := sin(_t * 12.0) * 16.0
	var c := Vector2(0, -130)
	_poly([c, c + Vector2(-80, -30 - flap), c + Vector2(-66, 0 - flap * 0.5), c + Vector2(-50, -8), c + Vector2(-38, 10), c + Vector2(-20, 4)], fur.darkened(0.1))
	_poly([c, c + Vector2(80, -30 - flap), c + Vector2(66, 0 - flap * 0.5), c + Vector2(50, -8), c + Vector2(38, 10), c + Vector2(20, 4)], fur.darkened(0.1))
	_poly(ellipse(c + Vector2(0, 6), 14, 22, 12), fur)
	_poly([c + Vector2(-10, -12), c + Vector2(-6, -30), c + Vector2(-2, -14)], fur)
	_poly([c + Vector2(10, -12), c + Vector2(6, -30), c + Vector2(2, -14)], fur)
	_circle(c + Vector2(-5, -6), 2.5, col("eye"), {"no_edge": true})
	_circle(c + Vector2(5, -6), 2.5, col("eye"), {"no_edge": true})


func _build_harpy() -> void:
	var fur := col("fur")
	var skin := col("belly")
	var flap := sin(_t * 5.0) * 14.0
	var c := Vector2(0, -150)
	_poly([c + Vector2(-6, -20), c + Vector2(-90, -70 - flap), c + Vector2(-70, -20 - flap), c + Vector2(-80, 10), c + Vector2(-40, 20)], fur.darkened(0.15))
	_poly([c + Vector2(-16, 20), c + Vector2(22, 20), c + Vector2(16, 90), c + Vector2(-8, 90)], fur)
	_line([c + Vector2(-2, 90), c + Vector2(-8, 130), c + Vector2(-16, 146)], 6.0, Color("#c9a24b"))
	_line([c + Vector2(10, 90), c + Vector2(14, 130), c + Vector2(22, 146)], 6.0, Color("#c9a24b"))
	_poly([c + Vector2(-10, -18), c + Vector2(18, -18), c + Vector2(22, 22), c + Vector2(-14, 22)], skin)
	_poly(ellipse(c + Vector2(-2, -44), 22, 26, 12, PI * 0.6, PI * 2.2), Color("#3b1f18"))
	_circle(c + Vector2(4, -36), 15.0, skin)
	_circle(c + Vector2(10, -38), 2.5, col("eye"), {"no_edge": true})
	_poly([c + Vector2(6, -20), c + Vector2(80, -70 + flap), c + Vector2(70, -10 + flap), c + Vector2(40, 18)], fur)


func _build_ghost() -> void:
	var c := col("fur", "#c9d6c3")
	var bob := sin(_t * 1.8) * 6.0
	var a := 0.78
	var pts: Array = [Vector2(-26, -40 + bob)]
	for i in 7:
		var x := -26 + i * 9.0
		pts.append(Vector2(x + 4, -8 + bob + sin(_t * 3 + i) * 6 + (i % 2) * 10))
	pts.append_array([Vector2(34, -40 + bob), Vector2(30, -150 + bob), Vector2(16, -170 + bob), Vector2(-14, -170 + bob), Vector2(-28, -150 + bob)])
	_poly(pts, c, {"a": a})
	_circle(Vector2(2, -186 + bob), 20.0, c, {"a": a})
	_line([Vector2(24, -140 + bob), Vector2(48 + (14 if pose in ["strike", "cast"] else 0), -110 + bob)], 9.0, c, {"a": a})
	_circle(Vector2(-4, -188 + bob), 4.0, col("eye", "#1a1a1a"), {"no_edge": true})
	_circle(Vector2(10, -188 + bob), 4.0, col("eye", "#1a1a1a"), {"no_edge": true})
	_poly(ellipse(Vector2(3, -176 + bob), 5, 7, 8), col("eye", "#1a1a1a"), {"no_edge": true})
	_circle(Vector2(2, -120 + bob), 70.0, Color(c.r, c.g, c.b, 0.12), {"glow": true})


func _build_swirl() -> void:
	var c := col("fur")
	var c2 := col("belly")
	for i in 8:
		var y := -20 - i * 26.0
		var rx := 14 + i * 9.0
		var off := sin(_t * 6 + i * 0.8) * (6 + i * 1.5)
		_poly(ellipse(Vector2(off, y), rx, 10 + i, 14), c if i % 2 == 0 else c2, {"a": 0.85})
	_circle(Vector2(-8 + sin(_t * 6 + 5) * 12, -160), 4.0, col("eye"), {"no_edge": true})
	_circle(Vector2(10 + sin(_t * 6 + 5) * 12, -160), 4.0, col("eye"), {"no_edge": true})


func _build_crawler() -> void:
	var c := col("fur")
	var c2 := col("belly")
	var lunge := 14.0 if pose in ["strike", "aim"] else 0.0
	_line([Vector2(-50, -46), Vector2(-70, -20), Vector2(-66, 0)], 8.0, c2)
	_line([Vector2(-30, -48), Vector2(-40, -20), Vector2(-50, 0)], 8.0, c2)
	_poly([Vector2(-70, -60), Vector2(-20, -80), Vector2(30, -76), Vector2(50, -60), Vector2(40, -44), Vector2(-60, -40)], c)
	for i in 5:
		_line([Vector2(-50 + i * 18, -70), Vector2(-46 + i * 18, -60)], 2.0, c2.darkened(0.2), {"no_edge": true})
	_line([Vector2(30, -56), Vector2(56 + lunge, -30), Vector2(70 + lunge, 0)], 8.0, c)
	_line([Vector2(10, -56), Vector2(24, -26), Vector2(20, 0)], 8.0, c)
	_poly(ellipse(Vector2(56 + lunge, -74), 20, 16, 12), c)
	_poly([Vector2(60 + lunge, -68), Vector2(80 + lunge, -64), Vector2(66 + lunge, -58)], Color("#3a1414"))


func _build_giant() -> void:
	var skin := col("fur", "#9a7b62")
	var dark := col("belly", "#6e5846")
	var cloth := col("coat", "#5a4a3a")
	var eye := col("eye", "#f2e8cf")
	var arm_up := pose in ["windup", "cast"]
	var strike := pose == "strike"
	# Legs.
	_poly([Vector2(-44, -120), Vector2(-8, -120), Vector2(-12, -8), Vector2(-46, -8)], dark)
	_poly([Vector2(4, -120), Vector2(42, -120), Vector2(46, -8), Vector2(10, -8)], skin.darkened(0.08))
	_poly([Vector2(-50, -14), Vector2(-6, -14), Vector2(-4, 0), Vector2(-54, 0)], dark.darkened(0.2))
	_poly([Vector2(6, -14), Vector2(50, -14), Vector2(58, 0), Vector2(6, 0)], dark.darkened(0.2))
	# Back arm.
	_line([Vector2(-50, -236), Vector2(-66, -170), Vector2(-60, -110)], 26.0, dark)
	# Torso.
	_poly([Vector2(-58, -120), Vector2(58, -120), Vector2(70, -200), Vector2(56, -250), Vector2(-56, -250), Vector2(-70, -200)], skin)
	_poly([Vector2(-60, -120), Vector2(60, -120), Vector2(64, -150), Vector2(-64, -150)], cloth)
	_line([Vector2(-50, -240), Vector2(46, -150)], 10.0, cloth.darkened(0.1))
	# Head.
	var hc := Vector2(6, -282)
	_poly(ellipse(hc, 34, 36, 16), skin.lightened(0.05))
	match look.get("eye", "two"):
		"one":
			_circle(hc + Vector2(8, -6), 14.0, Color("#f7f2e4"))
			_circle(hc + Vector2(12, -6), 7.0, Color("#3a2410"), {"no_edge": true})
			_line([hc + Vector2(-8, -24), hc + Vector2(26, -20)], 5.0, dark, {"no_edge": true})
		"glow":
			_circle(hc + Vector2(-4, -6), 6.0, eye, {"no_edge": true})
			_circle(hc + Vector2(18, -6), 6.0, eye, {"no_edge": true})
			_circle(hc + Vector2(7, -6), 40.0, Color(eye.r, eye.g, eye.b, 0.15), {"glow": true})
		_:
			_circle(hc + Vector2(-4, -6), 4.0, eye, {"no_edge": true})
			_circle(hc + Vector2(16, -6), 4.0, eye, {"no_edge": true})
	_line([hc + Vector2(-6, 16), hc + Vector2(20, 14)], 4.0, dark, {"no_edge": true})
	if look.get("crown", false):
		var crown: Array = [hc + Vector2(-30, -26)]
		for i in 5:
			crown.append(hc + Vector2(-26 + i * 13, -64 - (i % 2) * 14))
			crown.append(hc + Vector2(-20 + i * 13, -34))
		crown.append(hc + Vector2(36, -26))
		_poly(crown, col("accent", "#b8c6cf"))
	# Front arm with club/boulder.
	var shoulder := Vector2(56, -236)
	var hand := Vector2(90, -120)
	if arm_up:
		hand = Vector2(70, -330)
	elif strike:
		hand = Vector2(130, -170)
	_line([shoulder, (shoulder + hand) / 2 + Vector2(12, 0), hand], 28.0, skin)
	_circle(hand, 16.0, skin.darkened(0.05))
	if look.get("eye", "") == "one":
		var dir := (hand - shoulder).normalized()
		_poly([hand + dir.orthogonal() * 6, hand - dir.orthogonal() * 6, hand + dir * 110 - dir.orthogonal() * 22, hand + dir * 110 + dir.orthogonal() * 22], Color("#5a3e26"))
