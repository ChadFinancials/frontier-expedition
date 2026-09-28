class_name EventArt
extends Control
## A paper-cut illustration strip for a trail event, chosen by the event's "art" field.
## Drawn in the same cut-paper style as everything else (cream edges, drop shadows).

const PAPER := Color("#f3e9d2")
const INK := Color("#2a1d14")
var kind: String = "wagon"
var _t := 0.0


func _init() -> void:
	clip_contents = true


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _poly(pts: Array, c: Color) -> void:
	var p := PackedVector2Array(pts)
	var sh := PackedVector2Array()
	for q in p:
		sh.append(q + Vector2(4, 5))
	draw_colored_polygon(sh, Color(0, 0, 0, 0.22))
	var closed := p.duplicate()
	closed.append(p[0])
	draw_polyline(closed, PAPER, 5.0, true)
	draw_colored_polygon(p, c)


func _disc(c: Vector2, r: float, col: Color) -> void:
	draw_circle(c + Vector2(3, 4), r, Color(0, 0, 0, 0.2))
	draw_circle(c, r + 2.5, PAPER)
	draw_circle(c, r, col)


## A cloud of overlapping puffs: all the cut edges first, then the fills, so it reads as
## one piece of paper.
func _cloud(c: Vector2, n: int, r: float, col: Color) -> void:
	var puffs: Array = []
	for k in n:
		puffs.append([c + Vector2((k - (n - 1) / 2.0) * r * 1.1, -(k % 2) * r * 0.35), r * (1.0 - absf(k - (n - 1) / 2.0) * 0.12)])
	for pf in puffs:
		draw_circle(pf[0] + Vector2(3, 4), pf[1], Color(0, 0, 0, 0.2))
	for pf in puffs:
		draw_circle(pf[0], pf[1] + 3, PAPER)
	for pf in puffs:
		draw_circle(pf[0], pf[1], col)


func _hills(y: float, amp: float, col: Color, seed_value: int) -> void:
	var pts: Array = [Vector2(-10, size.y + 10)]
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for k in 9:
		pts.append(Vector2(k * size.x / 8.0, y - rng.randf() * amp))
	pts.append(Vector2(size.x + 10, size.y + 10))
	_poly(pts, col)


func _draw() -> void:
	var w := size.x
	var h := size.y
	var night := kind in ["lights", "siren", "stranger"]
	var sky_top := Color("#2b3552") if night else Color("#6f8fb0")
	var sky_bot := Color("#5b5270") if night else Color("#f0c987")
	if kind == "storm":
		sky_top = Color("#3a4150")
		sky_bot = Color("#7a7d85")
	if kind == "snow":
		sky_top = Color("#8fa4b8")
		sky_bot = Color("#dfe6ec")
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
		PackedColorArray([sky_top, sky_top, sky_bot, sky_bot]))
	var ground := h * 0.74
	_hills(h * 0.55, 30, Color("#8d7b68").lerp(sky_bot, 0.35), 3)
	var gcol := Color("#6b7d3c")
	if kind == "snow":
		gcol = Color("#eef2f5")
	elif kind in ["sun", "siren", "snake"]:
		gcol = Color("#b8864f")
	_poly([Vector2(-10, ground), Vector2(w + 10, ground - 6), Vector2(w + 10, h + 10), Vector2(-10, h + 10)], gcol)
	var c := Vector2(w / 2, ground + 6)
	match kind:
		"wagon":
			_poly([c + Vector2(-120, -10), c + Vector2(90, -40), c + Vector2(96, -16), c + Vector2(-114, 14)], Color("#7a5232"))
			_poly([c + Vector2(-96, -22), c + Vector2(-50, -100), c + Vector2(50, -112), c + Vector2(86, -44)], Color("#e6dcc4"))
			_disc(c + Vector2(60, 2), 24, Color("#3a2618"))
			_poly([c + Vector2(-140, 16), c + Vector2(-110, -6), c + Vector2(-104, 2), c + Vector2(-134, 22)], Color("#5a3a22"))
		"river":
			_poly([Vector2(-10, ground + 4), Vector2(w + 10, ground - 2), Vector2(w + 10, ground + 40), Vector2(-10, ground + 46)], Color("#4f7fa6"))
			var wb := Vector2(w * 0.55, ground + 14 + sin(_t * 2.0) * 2)
			_poly([wb + Vector2(-80, 0), wb + Vector2(70, 0), wb + Vector2(76, -24), wb + Vector2(-86, -24)], Color("#7a5232"))
			_poly([wb + Vector2(-70, -22), wb + Vector2(-40, -80), wb + Vector2(40, -86), wb + Vector2(64, -22)], Color("#e6dcc4"))
			for k in 6:
				var rx := fposmod(k * 150.0 + _t * 30.0, w + 60) - 30
				draw_line(Vector2(rx, ground + 18), Vector2(rx + 40, ground + 16), Color("#cfe3f0"), 3, true)
		"fire":
			for k in 7:
				var fx := w * (k + 0.5) / 7.0
				var fh := 60 + 30 * sin(_t * 4 + k)
				_poly([Vector2(fx - 34, ground), Vector2(fx + 34, ground), Vector2(fx + 6, ground - fh)], Color("#e07a1f"))
				_poly([Vector2(fx - 16, ground), Vector2(fx + 16, ground), Vector2(fx + 2, ground - fh * 0.6)], Color("#f2c14e"))
		"smoke":
			for k in 5:
				var ph := fmod(_t * 0.2 + k * 0.2, 1.0)
				_disc(Vector2(w * 0.7 + sin(ph * 5) * 20, ground - 30 - ph * 120), 18 + ph * 30, Color(0.55, 0.52, 0.5, 1.0))
		"buffalo":
			for k in 4:
				var bx := w * 0.2 + k * 150
				_poly([Vector2(bx - 50, ground), Vector2(bx - 54, ground - 36), Vector2(bx - 24, ground - 70), Vector2(bx + 30, ground - 56), Vector2(bx + 52, ground - 30), Vector2(bx + 46, ground)], Color("#4a3527"))
				_poly([Vector2(bx + 40, ground - 44), Vector2(bx + 66, ground - 40), Vector2(bx + 60, ground - 18), Vector2(bx + 40, ground - 20)], Color("#3a281e"))
		"deer":
			_poly([c + Vector2(-40, 0), c + Vector2(-36, -50), c + Vector2(30, -54), c + Vector2(34, 0)], Color("#9a6a42"))
			_poly([c + Vector2(24, -52), c + Vector2(40, -90), c + Vector2(54, -86), c + Vector2(40, -48)], Color("#9a6a42"))
			draw_line(c + Vector2(44, -88), c + Vector2(34, -118), Color("#5a3f2a"), 4, true)
			draw_line(c + Vector2(50, -88), c + Vector2(66, -116), Color("#5a3f2a"), 4, true)
		"cabin":
			_poly([c + Vector2(-110, 0), c + Vector2(110, 0), c + Vector2(110, -80), c + Vector2(-110, -80)], Color("#8a5a32"))
			_poly([c + Vector2(-130, -76), c + Vector2(130, -76), c + Vector2(0, -150)], Color("#5e3f27"))
			_poly([c + Vector2(-20, 0), c + Vector2(20, 0), c + Vector2(20, -52), c + Vector2(-20, -52)], Color("#3a2618"))
			_poly([c + Vector2(50, -60), c + Vector2(84, -60), c + Vector2(84, -34), c + Vector2(50, -34)], Color("#f2c46b"))
		"fork":
			draw_line(c + Vector2(0, 0), c + Vector2(0, -130), Color("#6b4426"), 10)
			_poly([c + Vector2(-110, -120), c + Vector2(-10, -120), c + Vector2(-10, -94), c + Vector2(-110, -94), c + Vector2(-126, -107)], Color("#a8834e"))
			_poly([c + Vector2(10, -84), c + Vector2(110, -84), c + Vector2(126, -71), c + Vector2(110, -58), c + Vector2(10, -58)], Color("#a8834e"))
		"grave":
			_poly([c + Vector2(-70, 4), c + Vector2(-50, -20), c + Vector2(50, -20), c + Vector2(70, 4)], Color("#6b5035"))
			_poly([c + Vector2(-8, -20), c + Vector2(8, -20), c + Vector2(8, -120), c + Vector2(-8, -120)], Color("#d9cfb8"))
			_poly([c + Vector2(-34, -96), c + Vector2(34, -96), c + Vector2(34, -82), c + Vector2(-34, -82)], Color("#d9cfb8"))
		"lights":
			for k in 6:
				var lp := Vector2(w * (k + 0.5) / 6.0, ground - 60 - 30 * sin(_t * 1.3 + k * 1.7))
				draw_circle(lp, 26, Color(0.6, 0.9, 1.0, 0.12))
				_disc(lp, 9, Color("#c9f0ff"))
		"peddler":
			_poly([c + Vector2(-130, -10), c + Vector2(90, -10), c + Vector2(90, -110), c + Vector2(-130, -110)], Color("#8a3a4a"))
			_poly([c + Vector2(-100, -100), c + Vector2(60, -100), c + Vector2(60, -70), c + Vector2(-100, -70)], Color("#e0bd4f"))
			draw_string(UI.font_bold, c + Vector2(-86, -78), "TONICS", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, INK)
			_disc(c + Vector2(-90, 4), 22, Color("#3a2618"))
			_disc(c + Vector2(50, 4), 22, Color("#3a2618"))
		"siren":
			_poly([c + Vector2(-120, 0), c + Vector2(-60, -90), c + Vector2(30, -110), c + Vector2(110, 0)], Color("#8a4a3a"))
			_disc(c + Vector2(-10, -126), 16, Color("#e8d0b8"))
			for k in 3:
				var np := c + Vector2(40 + k * 40, -150 - 12 * sin(_t * 2 + k))
				_disc(np, 7, INK)
				draw_line(np + Vector2(6, 0), np + Vector2(6, -26), INK, 3)
		"snake":
			var pts: Array = []
			for k in 30:
				var a := k * 0.5
				pts.append(c + Vector2(cos(a) * (60 - k), -20 + sin(a) * (22 - k * 0.6)))
			draw_polyline(PackedVector2Array(pts), PAPER, 20, true)
			draw_polyline(PackedVector2Array(pts), Color("#8a7a3a"), 14, true)
			_disc(c + Vector2(62, -24), 12, Color("#7a6a32"))
		"snow":
			for k in 40:
				var sp := Vector2(fposmod(k * 97.0 + _t * 20.0, w), fposmod(k * 53.0 + _t * 40.0, ground))
				draw_circle(sp, 3, Color(1, 1, 1, 0.9))
			_poly([c + Vector2(-160, 0), c + Vector2(-60, -40), c + Vector2(80, -30), c + Vector2(180, 0)], Color("#f6f8fa"))
		"storm":
			var flash := 1.0 if fmod(_t, 3.0) < 0.12 else 0.0
			var bx := w * 0.5
			_poly([Vector2(bx + 10, 50), Vector2(bx - 24, 110), Vector2(bx - 2, 110), Vector2(bx - 30, ground - 12),
				Vector2(bx + 26, 92), Vector2(bx + 2, 92), Vector2(bx + 30, 50)], Color("#fff3a8").lerp(Color.WHITE, flash))
			for k in 3:
				_cloud(Vector2(w * (0.22 + k * 0.28), 44 + (k % 2) * 14), 5, 34, Color("#5a5f6a").darkened(0.1 * (k % 2)))
			for k in 30:
				var rp := Vector2(fposmod(k * 67.0 + _t * 60.0, w), fposmod(k * 41.0 + _t * 220.0, ground))
				draw_line(rp, rp + Vector2(-4, 12), Color(0.8, 0.85, 0.95, 0.6), 2, true)
		"stranger":
			_poly([c + Vector2(-26, 0), c + Vector2(26, 0), c + Vector2(22, -90), c + Vector2(-22, -90)], Color("#2e2a30"))
			_disc(c + Vector2(0, -104), 16, Color("#2e2a30"))
			_poly([c + Vector2(-40, -112), c + Vector2(40, -112), c + Vector2(20, -120), c + Vector2(12, -140), c + Vector2(-12, -140), c + Vector2(-20, -120)], Color("#1e1a1c"))
		"sun":
			_disc(Vector2(w * 0.5, h * 0.3), 44, Color("#fff1c1"))
			for k in 4:
				var yy := ground - 20 - k * 16
				var pts2: Array = []
				for j in 12:
					pts2.append(Vector2(w * 0.2 + j * w * 0.05, yy + sin(j + _t * 3 + k) * 4))
				draw_polyline(PackedVector2Array(pts2), Color(1, 0.9, 0.7, 0.4), 2, true)
		"tracks":
			for k in 8:
				var tp := Vector2(w * 0.1 + k * w * 0.11, ground + 22 + (k % 2) * 14)
				_disc(tp, 9, Color("#4a3a2a"))
				for j in 3:
					draw_circle(tp + Vector2(-8 + j * 8, -12), 3, Color("#4a3a2a"))
		_:
			_disc(c + Vector2(0, -40), 30, Color("#a8834e"))
