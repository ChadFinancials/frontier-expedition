class_name ResIcon
extends Control
## Tiny drawn icons for resources: money, timber, iron, charter, food, week, wagon, xp.

var kind: String = "money"


static func make(k: String, s: float = 26) -> ResIcon:
	var r := ResIcon.new()
	r.kind = k
	r.custom_minimum_size = Vector2(s, s)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _draw() -> void:
	var s := size.x
	var c := Vector2(s / 2, s / 2)
	match kind:
		"money":
			# A poker chip: red rim with white notches, cream center.
			draw_circle(c, s * 0.45, Color("#6b1a14"))
			draw_circle(c, s * 0.42, Color("#b8322a"))
			for i in 6:
				var a := i * TAU / 6.0
				draw_line(c + Vector2(cos(a), sin(a)) * s * 0.28, c + Vector2(cos(a), sin(a)) * s * 0.42, Color("#f3e9d2"), s * 0.1)
			draw_circle(c, s * 0.24, Color("#f3e9d2"))
			draw_circle(c, s * 0.16, Color("#b8322a"))
		"timber":
			for i in 3:
				var y := s * (0.3 + i * 0.2)
				draw_rect(Rect2(s * 0.1, y - s * 0.08, s * 0.8, s * 0.16), Color("#8a5a32"))
				draw_circle(Vector2(s * 0.86, y), s * 0.09, Color("#d9b27a"))
		"iron":
			draw_colored_polygon(PackedVector2Array([Vector2(s * 0.1, s * 0.75), Vector2(s * 0.25, s * 0.35), Vector2(s * 0.75, s * 0.35), Vector2(s * 0.9, s * 0.75)]), Color("#8c9096"))
			draw_colored_polygon(PackedVector2Array([Vector2(s * 0.25, s * 0.35), Vector2(s * 0.75, s * 0.35), Vector2(s * 0.7, s * 0.45), Vector2(s * 0.3, s * 0.45)]), Color("#c5cad0"))
		"charter":
			draw_rect(Rect2(s * 0.2, s * 0.12, s * 0.6, s * 0.76), Color("#efe3c8"))
			for i in 4:
				draw_line(Vector2(s * 0.3, s * (0.28 + i * 0.13)), Vector2(s * 0.7, s * (0.28 + i * 0.13)), Color("#8a7a60"), 1.5)
			draw_circle(Vector2(s * 0.66, s * 0.78), s * 0.12, Color("#a8392e"))
		"food":
			draw_circle(Vector2(s * 0.5, s * 0.55), s * 0.34, Color("#b5733a"))
			draw_circle(Vector2(s * 0.5, s * 0.5), s * 0.22, Color("#e8c28a"))
		"week":
			draw_rect(Rect2(s * 0.12, s * 0.2, s * 0.76, s * 0.66), Color("#efe3c8"))
			draw_rect(Rect2(s * 0.12, s * 0.2, s * 0.76, s * 0.18), Color("#a8392e"))
		"wagon":
			draw_arc(Vector2(s * 0.5, s * 0.55), s * 0.34, PI, TAU, 12, Color("#efe3c8"), s * 0.12)
			draw_rect(Rect2(s * 0.1, s * 0.55, s * 0.8, s * 0.12), Color("#7a5232"))
			draw_circle(Vector2(s * 0.28, s * 0.78), s * 0.12, Color("#3a2618"))
			draw_circle(Vector2(s * 0.72, s * 0.78), s * 0.12, Color("#3a2618"))
		"xp":
			draw_colored_polygon(PackedVector2Array(Figure.star_pts(c, s * 0.45, s * 0.2, 5)), Color("#e0bd4f"))
		"eye":
			draw_colored_polygon(PackedVector2Array(Figure.ellipse(c, s * 0.45, s * 0.26, 16)), Color("#efe3c8"))
			draw_circle(c, s * 0.18, Color("#3f6f96"))
			draw_circle(c, s * 0.08, Color("#1a1210"))
		"skull":
			draw_circle(Vector2(s * 0.5, s * 0.42), s * 0.3, Color("#e9e2cf"))
			draw_rect(Rect2(s * 0.34, s * 0.6, s * 0.32, s * 0.2), Color("#e9e2cf"))
			draw_circle(Vector2(s * 0.4, s * 0.42), s * 0.08, Color("#2a1d14"))
			draw_circle(Vector2(s * 0.6, s * 0.42), s * 0.08, Color("#2a1d14"))
