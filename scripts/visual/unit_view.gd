class_name UnitView
extends Node2D
## One combatant on the battlefield: its Figure plus a HUD (HP, Fatigue, statuses) and a
## ground glow used for targeting highlights.

var unit: Combatant
var figure: Figure
var hud: Node2D
var glow: String = ""        # "", "enemy", "ally", "hover", "active"
var base_scale := 1.2
var paper_group: CanvasGroup = null   # paper-theater material around the figure
var _t := 0.0
## What the HUD shows. The engine resolves a whole action at once, so while the combat
## screen plays it back the HUD is frozen and only moves as each hit lands (shift_hp,
## sync); otherwise it follows the unit every frame.
var shown: Dictionary = {}
var frozen := false
var _hud_key := ""


func setup(c: Combatant, paper: bool = false) -> void:
	unit = c
	figure = Figure.new()
	var look: Dictionary = c.data.get("look", {})
	var seed_value: int = c.hero.look_seed if c.hero != null else c.id * 31
	figure.setup(look, seed_value, 1 if c.is_hero() else -1)
	figure.scale *= base_scale
	if paper:
		figure.crafted = true
		add_child(figure)
		repaper()
	else:
		add_child(figure)
	hud = _Hud.new()
	hud.view = self
	add_child(hud)


## Wrap the figure in its paper group (the paper-theater material).
func repaper() -> void:
	if paper_group != null or figure == null:
		return
	paper_group = PaperFX.group({"shadow_offset": Vector2(10, 7), "shadow_alpha": 0.3, "shadow_blur": 2.5,
		"bevel_strength": 1.1, "bevel_radius": 3.0}, 30.0)
	remove_child(figure)
	paper_group.add_child(figure)
	add_child(paper_group)
	move_child(paper_group, 0)


## Take the figure out of its paper group before fading or spinning the whole unit (death,
## a summon's fade-in). A CanvasGroup faded through its parent's modulate drew as a grey box
## under Vulkan; a plain figure fades cleanly. repaper() puts the group back.
func unpaper() -> void:
	if paper_group == null:
		return
	paper_group.remove_child(figure)
	add_child(figure)
	move_child(figure, 0)
	paper_group.queue_free()
	paper_group = null


func set_glow(g: String) -> void:
	glow = g
	queue_redraw()


func sync() -> void:
	var u := unit
	if u == null:
		return
	shown = {"hp": u.hp, "max_hp": u.max_hp, "dd": u.deaths_door(), "fatigue": u.hero.fatigue if u.hero != null else 0.0,
		"fstate": u.hero.fatigue_state if u.hero != null else "", "chips": u.status_chips(), "actions": u.actions_left,
		"momentum": u.momentum if u.uses_momentum() else -1}


## A hit or heal landing on screen: move the shown HP now, before the full sync.
func shift_hp(delta: int) -> void:
	if shown.is_empty():
		sync()
	shown.hp = clampi(int(shown.hp) + delta, 0, int(shown.max_hp))
	if unit.hero != null:
		shown.dd = int(shown.hp) <= 0 and (bool(shown.dd) or delta < 0)


func shift_fatigue(delta: float) -> void:
	if shown.is_empty():
		sync()
	shown.fatigue = clampf(float(shown.fatigue) + delta, 0.0, 200.0)


## Take the unit's statuses (and fatigue state) as they are now, leaving HP as shown.
func sync_status() -> void:
	if shown.is_empty():
		sync()
		return
	shown.chips = unit.status_chips()
	if unit.hero != null:
		shown.fstate = unit.hero.fatigue_state


func _process(delta: float) -> void:
	_t += delta
	if not frozen or shown.is_empty():
		sync()
	if paper_group != null:
		paper_group.material.set_shader_parameter("grain_offset", get_global_transform_with_canvas().origin)
	if glow != "":
		queue_redraw()
	# The HUD redraws only when what it shows changes.
	var key := str(shown) + str(unit.dead if unit != null else true)
	if key != _hud_key:
		_hud_key = key
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
	## How far below the feet the HUD may draw before the combat panel covers it
	## (panel top 835 minus the ground line 745).
	const CHIP_FLOOR := 88.0
	var view: UnitView

	func _draw() -> void:
		var u := view.unit
		if u == null or u.dead or view.shown.is_empty():
			return
		var sh: Dictionary = view.shown
		var font: Font = UI.font_bold
		var w := 124.0
		var y := 16.0
		# HP bar.
		draw_rect(Rect2(-w / 2, y, w, 12), Color(0, 0, 0, 0.7))
		var f := clampf(float(sh.hp) / maxf(1.0, sh.max_hp), 0.0, 1.0)
		draw_rect(Rect2(-w / 2 + 1, y + 1, (w - 2) * f, 10), Color("#c0392b") if not sh.dd else Color("#6b0f0f"))
		var hp_txt := "%d/%d" % [sh.hp, sh.max_hp]
		if sh.dd:
			hp_txt = "DEATH'S DOOR"
		_text(font, Vector2(0, y + 10), hp_txt, 12, Color.WHITE)
		y += 14
		if u.hero != null:
			draw_rect(Rect2(-w / 2, y, w, 8), Color(0, 0, 0, 0.7))
			var ff := clampf(float(sh.fatigue) / 200.0, 0.0, 1.0)
			draw_rect(Rect2(-w / 2 + 1, y + 1, (w - 2) * ff, 6), UI.FATIGUE)
			draw_line(Vector2(0, y), Vector2(0, y + 8), Color(1, 1, 1, 0.7), 1.5)
			y += 10
			# Momentum (Train Hopper): steam-gold, brighter at Full Steam, white-gold when full.
			if int(sh.get("momentum", -1)) >= 0:
				var mx := float(DB.cfg("momentum_max", 100))
				var mf := clampf(float(sh.momentum) / mx, 0.0, 1.0)
				var mc := Color("#b8862e")
				if mf >= 1.0:
					mc = Color("#ffe08a")
				elif float(sh.momentum) >= float(DB.cfg("full_steam_at", 50)):
					mc = Color("#f0c24a")
				draw_rect(Rect2(-w / 2, y, w, 8), Color(0, 0, 0, 0.7))
				draw_rect(Rect2(-w / 2 + 1, y + 1, (w - 2) * mf, 6), mc)
				var nx := -w / 2 + w * float(DB.cfg("full_steam_at", 50)) / mx
				draw_line(Vector2(nx, y), Vector2(nx, y + 8), Color(1, 1, 1, 0.7), 1.5)
				y += 10
			if str(sh.fstate) != "" and DB.fatigue_states.has(str(sh.fstate)):
				var st: Dictionary = DB.fatigue_states[str(sh.fstate)]
				_text(font, Vector2(0, y + 14), st.name, 15, Color(st.get("color", "#ffffff")))
				y += 18
		# Turn markers: one gold pip per action this unit still has this round (like DD).
		for k in int(sh.actions):
			var c := Vector2(w / 2 + 14, 22 + k * 20)
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -10), c + Vector2(8, 0), c + Vector2(0, 10), c + Vector2(-8, 0)]), Color(0, 0, 0, 0.8))
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -7), c + Vector2(5.5, 0), c + Vector2(0, 7), c + Vector2(-5.5, 0)]), Color("#e0bd4f"))
		# Status chips: short tags ("ACC +10") in rows under the bars. The combat screen keeps
		# the ground line high enough for three rows above the HUD panel; the unit's tooltip
		# lists each one in full with its duration.
		# Rows use the gap between neighbours (units stand 180 apart); anything that would
		# drop behind the HUD panel folds into a "+N" chip.
		var chips: Array = sh.chips
		var left := -w / 2 - 16.0
		var right := w / 2 + 34.0
		var x := left
		for i in chips.size():
			var ch: Dictionary = chips[i]
			var t: String = ch.text
			var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 7
			if x + tw > right and x > left:
				x = left
				y += 15
			if y + 16 > CHIP_FLOOR - 15 and i < chips.size() - 1 and x + tw + 30 > right:
				# Last row, and more to come than fits: say how many are hidden.
				var more := "+%d" % (chips.size() - i)
				var mw := font.get_string_size(more, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 7
				draw_rect(Rect2(x, y + 2, mw, 14), Color(0.15, 0.1, 0.07, 0.9))
				draw_string(font, Vector2(x + 3.5, y + 13), more, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
				break
			var col := Color("#5f8a3a") if ch.kind == "good" else Color("#a8392e")
			draw_rect(Rect2(x, y + 2, tw, 14), col)
			draw_string(font, Vector2(x + 3.5, y + 13), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
			x += tw + 2

	func _text(font: Font, pos: Vector2, t: String, size: int, c: Color) -> void:
		var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		draw_string_outline(font, pos - Vector2(tw / 2, 0), t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 3, Color(0, 0, 0, 0.9))
		draw_string(font, pos - Vector2(tw / 2, 0), t, HORIZONTAL_ALIGNMENT_LEFT, -1, size, c)
