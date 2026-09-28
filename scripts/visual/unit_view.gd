class_name UnitView
extends Node2D
## One combatant on the battlefield: its Figure plus a HUD (HP, Fatigue, statuses) and a
## ground glow used for targeting highlights.

var unit: Combatant
var figure: Figure
var hud: Node2D
var glow: String = ""        # "", "enemy", "ally", "hover", "active"
var base_scale := 1.2
var _t := 0.0


func setup(c: Combatant) -> void:
	unit = c
	figure = Figure.new()
	var look: Dictionary = c.data.get("look", {})
	var seed_value: int = c.hero.look_seed if c.hero != null else c.id * 31
	figure.setup(look, seed_value, 1 if c.is_hero() else -1)
	figure.scale *= base_scale
	add_child(figure)
	hud = _Hud.new()
	hud.view = self
	add_child(hud)


func set_glow(g: String) -> void:
	glow = g
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if glow != "":
		queue_redraw()
	hud.queue_redraw()


func top_local() -> float:
	return figure.top_y() * base_scale * float(figure.look.get("scale", 1.0))


## Rough clickable area in screen space.
func hit_rect() -> Rect2:
	var top := top_local()
	var w := 150.0 * clampf(float(figure.look.get("scale", 1.0)), 1.0, 1.8)
	return Rect2(global_position + Vector2(-w / 2, top * scale.y), Vector2(w, -top * scale.y + 30))


func _draw() -> void:
	if glow == "":
		return
	var c := {"enemy": Color(0.9, 0.2, 0.15), "ally": Color(0.3, 0.85, 0.3), "hover": Color(1, 0.85, 0.3), "active": Color(1, 0.85, 0.3)}.get(glow, Color.WHITE)
	var pulse := 0.6 + 0.4 * sin(_t * 5.0)
	var rx := 80.0 * clampf(float(figure.look.get("scale", 1.0)), 1.0, 1.8)
	for i in 4:
		var pts := PackedVector2Array(Figure.ellipse(Vector2(0, 4), rx + i * 8, 18 + i * 3, 24))
		draw_colored_polygon(pts, Color(c.r, c.g, c.b, (0.22 - i * 0.05) * pulse))
	if glow == "active":
		var ty := top_local() - 36
		draw_colored_polygon(PackedVector2Array([Vector2(-16, ty - 26), Vector2(16, ty - 26), Vector2(0, ty)]), Color("#e0bd4f"))


class _Hud extends Node2D:
	var view: UnitView

	func _draw() -> void:
		var u := view.unit
		if u == null or u.dead:
			return
		var font: Font = UI.font_bold
		var w := 124.0
		var y := 16.0
		# HP bar.
		draw_rect(Rect2(-w / 2, y, w, 12), Color(0, 0, 0, 0.7))
		var f := clampf(float(u.hp) / maxf(1.0, u.max_hp), 0.0, 1.0)
		draw_rect(Rect2(-w / 2 + 1, y + 1, (w - 2) * f, 10), Color("#c0392b") if not u.deaths_door() else Color("#6b0f0f"))
		var hp_txt := "%d/%d" % [u.hp, u.max_hp]
		if u.deaths_door():
			hp_txt = "DEATH'S DOOR"
		_text(font, Vector2(0, y + 10), hp_txt, 12, Color.WHITE)
		y += 14
		if u.hero != null:
			draw_rect(Rect2(-w / 2, y, w, 8), Color(0, 0, 0, 0.7))
			var ff := clampf(u.hero.fatigue / 200.0, 0.0, 1.0)
			draw_rect(Rect2(-w / 2 + 1, y + 1, (w - 2) * ff, 6), UI.FATIGUE)
			draw_line(Vector2(0, y), Vector2(0, y + 8), Color(1, 1, 1, 0.7), 1.5)
			y += 10
			if u.hero.fatigue_state != "":
				var st: Dictionary = DB.fatigue_states[u.hero.fatigue_state]
				_text(font, Vector2(0, y + 14), st.name, 15, Color(st.get("color", "#ffffff")))
				y += 18
		# Status chips.
		var chips := u.status_chips()
		var x := -w / 2
		for ch in chips:
			var t: String = ch.text
			var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 8
			if x + tw > w / 2 + 40:
				x = -w / 2
				y += 17
			var col := Color("#5f8a3a") if ch.kind == "good" else Color("#a8392e")
			draw_rect(Rect2(x, y + 2, tw, 15), col)
			draw_string(font, Vector2(x + 4, y + 14), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
			x += tw + 3

	func _text(font: Font, pos: Vector2, t: String, size: int, c: Color) -> void:
		var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		draw_string_outline(font, pos - Vector2(tw / 2, 0), t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 3, Color(0, 0, 0, 0.9))
		draw_string(font, pos - Vector2(tw / 2, 0), t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, c)
