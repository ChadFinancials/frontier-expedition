class_name StatBar
extends Control
## A simple drawn bar (HP, Fatigue, wagon...). Fatigue bars get a notch at 100.

var value: float = 0.0:
	set(v):
		value = v
		queue_redraw()
var max_value: float = 100.0:
	set(v):
		max_value = v
		queue_redraw()
var fill: Color = Color.RED
var back: Color = Color(0, 0, 0, 0.55)
var show_text: bool = false
var notch: float = -1.0
var text_override: String = ""


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, back)
	var f := clampf(value / maxf(1.0, max_value), 0.0, 1.0)
	if f > 0:
		draw_rect(Rect2(Vector2(1, 1), Vector2((size.x - 2) * f, size.y - 2)), fill)
		draw_rect(Rect2(Vector2(1, 1), Vector2((size.x - 2) * f, (size.y - 2) * 0.35)), Color(1, 1, 1, 0.18))
	if notch > 0 and max_value > 0:
		var x := size.x * notch / max_value
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color(1, 1, 1, 0.7), 2.0)
	draw_rect(r, Color(0, 0, 0, 0.8), false, 1.5)
	if show_text:
		var t := text_override if text_override != "" else "%d/%d" % [int(value), int(max_value)]
		var font := UI.font_bold if UI.font_bold != null else get_theme_default_font()
		var fs := int(maxf(11, size.y - 3))
		var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var pos := Vector2((size.x - tw) / 2.0, size.y / 2.0 + fs * 0.36)
		draw_string_outline(font, pos, t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0, 0, 0, 0.9))
		draw_string(font, pos, t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
