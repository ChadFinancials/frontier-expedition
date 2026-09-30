class_name CurioArt
extends Control
## Small painted vignette for a curio (paper-cutout style).

const PAPER := Color("#f3e9d2")
var kind: String = "crate"


func _init() -> void:
	clip_contents = true


func _poly(pts: Array, c: Color) -> void:
	var p := PackedVector2Array(pts)
	var sh := PackedVector2Array()
	for q in p:
		sh.append(q + Vector2(4, 5))
	draw_colored_polygon(sh, Color(0, 0, 0, 0.25))
	var closed := p.duplicate()
	closed.append(p[0])
	draw_polyline(Figure.clean_line(closed), PAPER, 6.0, true)
	draw_colored_polygon(p, c)


func _box(r: Rect2, c: Color) -> void:
	_poly([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)], c)


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(Vector2.ZERO, size), Color("#cdb894"))
	draw_rect(Rect2(0, h * 0.72, w, h * 0.28), Color("#a88f63"))
	var c := Vector2(w / 2, h * 0.78)
	match kind:
		"wagon":
			_poly([c + Vector2(-110, -20), c + Vector2(80, -60), c + Vector2(90, -30), c + Vector2(-100, 10)], Color("#7a5232"))
			_poly([c + Vector2(-90, -30), c + Vector2(-40, -110), c + Vector2(40, -120), c + Vector2(80, -60)], Color("#e6dcc4"))
			draw_circle(c + Vector2(50, 0), 26, Color("#3a2618"))
			draw_circle(c + Vector2(50, 0), 18, Color("#8a6a45"))
		"barrel":
			_poly([c + Vector2(-40, 0), c + Vector2(-48, -50), c + Vector2(-40, -100), c + Vector2(40, -100), c + Vector2(48, -50), c + Vector2(40, 0)], Color("#8a5a32"))
			for y in [-20.0, -80.0]:
				draw_line(c + Vector2(-46, y), c + Vector2(46, y), Color("#3c3f44"), 5)
			draw_string(UI.font_head, c + Vector2(-22, -40), "XXX", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#2a1d14"))
		"grave":
			_poly([c + Vector2(-60, 0), c + Vector2(60, 0), c + Vector2(40, -24), c + Vector2(-40, -24)], Color("#8a7a60"))
			_box(Rect2(c + Vector2(-6, -110), Vector2(12, 90)), Color("#6b4426"))
			_box(Rect2(c + Vector2(-34, -90), Vector2(68, 12)), Color("#6b4426"))
		"strongbox":
			_box(Rect2(c + Vector2(-60, -70), Vector2(120, 70)), Color("#3c4a3a"))
			_box(Rect2(c + Vector2(-60, -90), Vector2(120, 22)), Color("#2e3a2d"))
			_box(Rect2(c + Vector2(-10, -60), Vector2(20, 26)), Color("#c9a227"))
		"well":
			_poly([c + Vector2(-50, 0), c + Vector2(50, 0), c + Vector2(50, -50), c + Vector2(-50, -50)], Color("#8a8378"))
			draw_line(c + Vector2(-44, -50), c + Vector2(-44, -120), Color("#6b4426"), 7)
			draw_line(c + Vector2(44, -50), c + Vector2(44, -120), Color("#6b4426"), 7)
			_poly([c + Vector2(-60, -110), c + Vector2(0, -140), c + Vector2(60, -110)], Color("#7a5232"))
		"scarecrow":
			draw_line(c, c + Vector2(0, -130), Color("#6b4426"), 7)
			draw_line(c + Vector2(-60, -90), c + Vector2(60, -90), Color("#6b4426"), 7)
			_poly([c + Vector2(-30, -100), c + Vector2(30, -100), c + Vector2(24, -40), c + Vector2(-24, -40)], Color("#6b5a3a"))
			draw_circle(c + Vector2(0, -118), 18, Color("#d9c38a"))
			_poly([c + Vector2(-26, -128), c + Vector2(26, -128), c + Vector2(0, -150)], Color("#3a2e24"))
			draw_circle(c + Vector2(-6, -118), 3, Color("#1a1210"))
			draw_circle(c + Vector2(6, -118), 3, Color("#1a1210"))
		"bush":
			for i in 5:
				draw_circle(c + Vector2(-60 + i * 30, -30 - (i % 2) * 18), 34, Color("#4f6b2e"))
			for i in 12:
				draw_circle(c + Vector2(-70 + i * 13, -40 + (i * 37) % 30), 5, Color("#5a1a3a"))
		"skull":
			draw_line(c, c + Vector2(0, -90), Color("#6b4426"), 7)
			_poly([c + Vector2(-26, -120), c + Vector2(26, -120), c + Vector2(16, -80), c + Vector2(-16, -80)], Color("#ece5d2"))
			draw_line(c + Vector2(-24, -116), c + Vector2(-80, -140), Color("#ece5d2"), 8)
			draw_line(c + Vector2(24, -116), c + Vector2(80, -140), Color("#ece5d2"), 8)
			draw_circle(c + Vector2(-9, -106), 6, Color("#2a1d14"))
			draw_circle(c + Vector2(9, -106), 6, Color("#2a1d14"))
		"horse":
			_poly([c + Vector2(-90, -10), c + Vector2(60, -14), c + Vector2(80, -44), c + Vector2(-70, -46)], Color("#6b4a32"))
			_poly([c + Vector2(60, -30), c + Vector2(110, -40), c + Vector2(120, -20), c + Vector2(70, -10)], Color("#5a3e2a"))
			_box(Rect2(c + Vector2(-30, -60), Vector2(50, 20)), Color("#8a5a32"))
		"stone":
			_poly([c + Vector2(-40, 0), c + Vector2(-30, -140), c + Vector2(10, -160), c + Vector2(40, -130), c + Vector2(44, 0)], Color("#7d7870"))
			for i in 4:
				draw_line(c + Vector2(-16, -120 + i * 26), c + Vector2(18, -114 + i * 26), Color("#9ee6ff"), 2)
		"crate", "pack":
			_box(Rect2(c + Vector2(-70, -80), Vector2(90, 80)), Color("#9a6b3c"))
			_box(Rect2(c + Vector2(10, -56), Vector2(64, 56)), Color("#8a5a32"))
			draw_line(c + Vector2(-70, -80), c + Vector2(20, 0), Color("#6b4426"), 4)
			if kind == "pack":
				draw_rect(Rect2(c + Vector2(-90, -100), Vector2(180, 100)), Color(0.85, 0.93, 1.0, 0.45))
		"bones":
			for i in 7:
				var a := i * 0.9
				var p := c + Vector2(-70 + i * 22, -14 - (i % 3) * 10)
				draw_line(p, p + Vector2(cos(a), sin(a)) * 40, Color("#ece5d2"), 7)
			draw_circle(c + Vector2(40, -40), 18, Color("#ece5d2"))
		"pool":
			var pts := Figure.ellipse(c + Vector2(0, -20), 110, 24, 20)
			_poly(pts, Color("#3fb3a6") if kind == "pool" else Color("#5a8fb3"))
			draw_circle(c + Vector2(0, -20), 90, Color(0.4, 0.9, 0.8, 0.12))
		"rubble":
			for i in 8:
				_poly([c + Vector2(-80 + i * 22, 0), c + Vector2(-70 + i * 22, -30 - (i % 3) * 18), c + Vector2(-54 + i * 22, 0)], Color("#6e6660"))
		"wall":
			_box(Rect2(c + Vector2(-140, -130), Vector2(280, 130)), Color("#b8603f"))
			for i in 3:
				var x := -100 + i * 90
				draw_line(c + Vector2(x, -20), c + Vector2(x, -70 - i * 10), Color("#f2e8cf"), 5)
				draw_circle(c + Vector2(x, -80 - i * 10), 10, Color("#f2e8cf"))
			draw_line(c + Vector2(100, -10), c + Vector2(100, -120), Color("#f2e8cf"), 9)
			draw_circle(c + Vector2(100, -120), 16, Color("#f2e8cf"))
		"vein":
			_box(Rect2(c + Vector2(-140, -130), Vector2(280, 130)), Color("#5a524a"))
			draw_line(c + Vector2(-120, -40), c + Vector2(130, -100), Color("#b5522e"), 12)
			for i in 6:
				draw_circle(c + Vector2(-100 + i * 40, -48 - i * 9), 4, Color("#f2c14e"))
		"cairn":
			for i in 5:
				draw_circle(c + Vector2(0, -14 - i * 22), 30 - i * 5, Color("#8a8378"))
		_:
			_box(Rect2(c + Vector2(-50, -60), Vector2(100, 60)), Color("#8a5a32"))
