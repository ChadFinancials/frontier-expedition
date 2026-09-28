class_name ResIcon
extends Control
## Tiny drawn icons for resources (money, timber, iron...), move types (melee, ranged, heal,
## buff, debuff) and combat stats (dmg, crit, dodge, prot, speed, acc).

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
		"melee":
			# A knife blade with a wrapped grip.
			draw_colored_polygon(PackedVector2Array([Vector2(s * 0.18, s * 0.82), Vector2(s * 0.72, s * 0.14), Vector2(s * 0.84, s * 0.18), Vector2(s * 0.34, s * 0.84)]), Color("#d8dde2"))
			draw_line(Vector2(s * 0.1, s * 0.62), Vector2(s * 0.42, s * 0.92), Color("#e0bd4f"), s * 0.1)
			draw_line(Vector2(s * 0.06, s * 0.96), Vector2(s * 0.22, s * 0.78), Color("#6b4a2e"), s * 0.14)
		"ranged":
			# Crosshairs.
			draw_arc(c, s * 0.34, 0, TAU, 20, Color("#e8dcc0"), s * 0.09)
			for d in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
				draw_line(c + d * s * 0.14, c + d * s * 0.48, Color("#e8dcc0"), s * 0.08)
			draw_circle(c, s * 0.07, Color("#e05a4a"))
		"heal":
			draw_circle(c, s * 0.44, Color("#f3e9d2"))
			draw_rect(Rect2(s * 0.4, s * 0.18, s * 0.2, s * 0.64), Color("#c0392b"))
			draw_rect(Rect2(s * 0.18, s * 0.4, s * 0.64, s * 0.2), Color("#c0392b"))
		"buff":
			draw_colored_polygon(PackedVector2Array([Vector2(s * 0.5, s * 0.08), Vector2(s * 0.9, s * 0.52), Vector2(s * 0.64, s * 0.52), Vector2(s * 0.64, s * 0.92), Vector2(s * 0.36, s * 0.92), Vector2(s * 0.36, s * 0.52), Vector2(s * 0.1, s * 0.52)]), Color("#7fb069"))
		"debuff":
			draw_colored_polygon(PackedVector2Array([Vector2(s * 0.5, s * 0.92), Vector2(s * 0.9, s * 0.48), Vector2(s * 0.64, s * 0.48), Vector2(s * 0.64, s * 0.08), Vector2(s * 0.36, s * 0.08), Vector2(s * 0.36, s * 0.48), Vector2(s * 0.1, s * 0.48)]), Color("#b07cc6"))
		"dmg":
			draw_colored_polygon(PackedVector2Array(Figure.star_pts(c, s * 0.46, s * 0.22, 7)), Color("#e05a4a"))
		"crit":
			draw_colored_polygon(PackedVector2Array(Figure.star_pts(c, s * 0.48, s * 0.16, 4)), Color("#f1d38a"))
		"dodge":
			for i in 3:
				draw_arc(Vector2(s * (0.62 - i * 0.14), s * 0.5), s * 0.3, -PI * 0.45, PI * 0.45, 8, Color("#9ecbe8", 1.0 - i * 0.28), s * 0.08)
		"prot":
			draw_colored_polygon(PackedVector2Array([Vector2(s * 0.5, s * 0.06), Vector2(s * 0.88, s * 0.2), Vector2(s * 0.82, s * 0.6), Vector2(s * 0.5, s * 0.94), Vector2(s * 0.18, s * 0.6), Vector2(s * 0.12, s * 0.2)]), Color("#8c9096"))
			draw_colored_polygon(PackedVector2Array([Vector2(s * 0.5, s * 0.18), Vector2(s * 0.76, s * 0.28), Vector2(s * 0.7, s * 0.58), Vector2(s * 0.5, s * 0.8)]), Color("#c5cad0"))
		"speed":
			draw_colored_polygon(PackedVector2Array([Vector2(s * 0.6, s * 0.04), Vector2(s * 0.2, s * 0.56), Vector2(s * 0.46, s * 0.56), Vector2(s * 0.36, s * 0.96), Vector2(s * 0.8, s * 0.42), Vector2(s * 0.54, s * 0.42)]), Color("#e0bd4f"))
		"acc":
			draw_arc(c, s * 0.4, 0, TAU, 20, Color("#e8dcc0"), s * 0.08)
			draw_arc(c, s * 0.22, 0, TAU, 16, Color("#e05a4a"), s * 0.08)
			draw_circle(c, s * 0.07, Color("#e8dcc0"))
		"oil":
			# A lamp-oil tin with a spout.
			draw_rect(Rect2(s * 0.24, s * 0.3, s * 0.52, s * 0.58), Color("#7b8a8f"))
			draw_rect(Rect2(s * 0.24, s * 0.3, s * 0.52, s * 0.1), Color("#a9b6ba"))
			draw_line(Vector2(s * 0.62, s * 0.3), Vector2(s * 0.78, s * 0.1), Color("#5a6569"), s * 0.08)
			draw_circle(Vector2(s * 0.5, s * 0.62), s * 0.1, Color("#f2c14e"))
		"bandage":
			draw_rect(Rect2(s * 0.14, s * 0.34, s * 0.72, s * 0.32), Color("#f3ecdc"))
			draw_circle(Vector2(s * 0.3, s * 0.5), s * 0.2, Color("#e8dfcb"))
			draw_arc(Vector2(s * 0.3, s * 0.5), s * 0.12, 0, TAU, 12, Color("#c8bda6"), s * 0.04)
			draw_rect(Rect2(s * 0.56, s * 0.42, s * 0.16, s * 0.16), Color("#c0392b"))
		"vial":
			draw_rect(Rect2(s * 0.4, s * 0.1, s * 0.2, s * 0.12), Color("#8a5a32"))
			draw_rect(Rect2(s * 0.34, s * 0.22, s * 0.32, s * 0.64), Color("#cfe3d4"))
			draw_rect(Rect2(s * 0.34, s * 0.5, s * 0.32, s * 0.36), Color("#4f9a5a"))
		"bottle":
			draw_rect(Rect2(s * 0.42, s * 0.06, s * 0.16, s * 0.3), Color("#6b4a2e"))
			draw_colored_polygon(PackedVector2Array([Vector2(s * 0.42, s * 0.34), Vector2(s * 0.58, s * 0.34), Vector2(s * 0.72, s * 0.5), Vector2(s * 0.72, s * 0.94), Vector2(s * 0.28, s * 0.94), Vector2(s * 0.28, s * 0.5)]), Color("#a8672a"))
			draw_rect(Rect2(s * 0.32, s * 0.58, s * 0.36, s * 0.2), Color("#efe3c8"))
		"rope":
			for i in 3:
				draw_arc(Vector2(s * 0.5, s * 0.52), s * (0.18 + i * 0.1), 0, TAU, 20, Color("#c49a5c"), s * 0.08)
		"shovel":
			draw_line(Vector2(s * 0.3, s * 0.1), Vector2(s * 0.55, s * 0.62), Color("#8a5a32"), s * 0.09)
			draw_colored_polygon(PackedVector2Array([Vector2(s * 0.45, s * 0.6), Vector2(s * 0.7, s * 0.52), Vector2(s * 0.82, s * 0.86), Vector2(s * 0.62, s * 0.94)]), Color("#8c9096"))
		"crowbar":
			draw_line(Vector2(s * 0.2, s * 0.86), Vector2(s * 0.7, s * 0.2), Color("#6f7a80"), s * 0.1)
			draw_arc(Vector2(s * 0.76, s * 0.26), s * 0.1, PI * 0.9, PI * 2.2, 8, Color("#6f7a80"), s * 0.1)
			draw_line(Vector2(s * 0.12, s * 0.84), Vector2(s * 0.24, s * 0.92), Color("#6f7a80"), s * 0.1)
		"salt":
			draw_colored_polygon(PackedVector2Array([Vector2(s * 0.3, s * 0.28), Vector2(s * 0.7, s * 0.28), Vector2(s * 0.78, s * 0.9), Vector2(s * 0.22, s * 0.9)]), Color("#d9c7a0"))
			draw_rect(Rect2(s * 0.3, s * 0.18, s * 0.4, s * 0.12), Color("#8a5a32"))
			draw_rect(Rect2(s * 0.3, s * 0.5, s * 0.4, s * 0.16), Color("#f7f4ec"))
		"wheel":
			draw_arc(c, s * 0.38, 0, TAU, 24, Color("#7a5232"), s * 0.1)
			for i in 6:
				var a := i * TAU / 6.0
				draw_line(c, c + Vector2(cos(a), sin(a)) * s * 0.36, Color("#8a6040"), s * 0.06)
			draw_circle(c, s * 0.1, Color("#5a3f2f"))
		"skull":
			draw_circle(Vector2(s * 0.5, s * 0.42), s * 0.3, Color("#e9e2cf"))
			draw_rect(Rect2(s * 0.34, s * 0.6, s * 0.32, s * 0.2), Color("#e9e2cf"))
			draw_circle(Vector2(s * 0.4, s * 0.42), s * 0.08, Color("#2a1d14"))
			draw_circle(Vector2(s * 0.6, s * 0.42), s * 0.08, Color("#2a1d14"))
