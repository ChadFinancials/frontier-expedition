class_name Campfire
extends Node2D
## An animated paper-cutout campfire with a warm glow.

var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	for i in 10:
		draw_circle(Vector2(0, -40), 60 + i * 34, Color(1, 0.6, 0.2, 0.05 - i * 0.004))
	draw_line(Vector2(-50, 0), Vector2(46, -16), Color("#5a3822"), 16)
	draw_line(Vector2(-44, -16), Vector2(50, 0), Color("#4a2e1a"), 16)
	for k in 3:
		var h := maxf(34.0, 70.0 + 26 * sin(_t * 7 + k * 2.1) - k * 16)
		var w := 34.0 - k * 8
		var sway := sin(_t * 5 + k) * 8
		var col: Color = [Color("#e0561f"), Color("#f29a2e"), Color("#ffe08a")][k]
		draw_colored_polygon(PackedVector2Array([Vector2(-w, -8), Vector2(sway * 0.5 - w * 0.4, -h * 0.55), Vector2(sway, -h), Vector2(sway * 0.5 + w * 0.4, -h * 0.55), Vector2(w, -8)]), col)
	for i in 5:
		var p := fmod(_t * 0.7 + i * 0.37, 1.0)
		draw_circle(Vector2(sin(i * 3.1 + _t) * 20, -60 - p * 160), 3 * (1.0 - p), Color(1, 0.8, 0.4, 1.0 - p))
