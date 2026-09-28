class_name FigureBox
extends Control
## A clipped portrait frame that shows a Figure (hero or enemy) scaled to fit.

var figure: Figure
var frame_color: Color = Color("#d9c7a0")
var show_frame: bool = true
var zoom: float = 1.0
var focus_head: bool = false


func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_PASS


func show_look(look: Dictionary, seed_value: int, face: int = 1) -> void:
	if figure == null:
		figure = Figure.new()
		add_child(figure)
	figure.setup(look, seed_value, face)
	figure.idle_anim = false
	_layout()


func show_hero(h: Hero) -> void:
	show_look(h.cls().get("look", {}), h.look_seed, 1)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout()


func _layout() -> void:
	if figure == null:
		return
	var body_scale: float = float(figure.look.get("scale", 1.0))
	var h := absf(figure.top_y()) * body_scale + 20
	var s := size.y / h * zoom
	if focus_head:
		s = size.y / 110.0 * zoom
		figure.position = Vector2(size.x / 2.0, size.y + 118.0 * s)
	else:
		figure.position = Vector2(size.x / 2.0, size.y - 6)
	figure.scale = Vector2(s * figure.facing * body_scale, s * body_scale)


func _draw() -> void:
	if show_frame:
		draw_rect(Rect2(Vector2.ZERO, size), frame_color)
		var c := frame_color.darkened(0.15)
		for i in 5:
			draw_circle(Vector2(size.x / 2, size.y * 0.55), size.x * (0.6 - i * 0.08), Color(c.r, c.g, c.b, 0.12))
		draw_rect(Rect2(Vector2.ZERO, size), UI.WOOD, false, 2.0)
