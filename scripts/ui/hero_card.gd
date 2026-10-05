class_name HeroCard
extends PanelContainer
## Compact hero card: portrait, name, class/level, HP and Fatigue bars, status line.

signal clicked(card: HeroCard)
signal right_clicked(card: HeroCard)

var hero: Hero
var selected: bool = false:
	set(v):
		selected = v
		_restyle()
var dimmed: bool = false:
	set(v):
		dimmed = v
		modulate = Color(1, 1, 1, 0.55) if v else Color.WHITE
var compact: bool = false


static func make(h: Hero, is_compact: bool = false) -> HeroCard:
	var c := HeroCard.new()
	c.hero = h
	c.compact = is_compact
	c._build()
	return c


func _build() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_restyle()
	var row := UI.hb(10)
	add_child(row)
	var fb := FigureBox.new()
	fb.custom_minimum_size = Vector2(64, 64) if compact else Vector2(78, 90)
	fb.focus_head = true
	fb.zoom = 1.0
	fb.show_hero(hero)
	row.add_child(fb)
	var col := UI.vb(2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	var name_l := UI.lbl(hero.hero_name, 19 if compact else 21, "InkBold")
	name_l.clip_text = true
	name_l.custom_minimum_size.x = 140 if compact else 190
	col.add_child(name_l)
	col.add_child(UI.lbl("Lv %d %s" % [hero.level, hero.class_name_text()], 16, "Ink"))
	var hp := UI.bar(hero.hp, hero.max_hp(), UI.HP, 150 if compact else 200, 14, true)
	col.add_child(hp)
	var ft := UI.bar(hero.fatigue, 200, UI.FATIGUE, 150 if compact else 200, 12, true)
	ft.notch = 100
	ft.text_override = "Fatigue %d" % hero.fatigue
	col.add_child(ft)
	if not compact:
		var st := hero.status_text()
		if hero.rattled:
			st = "Rattled" + ("  |  " + st if st != "Ready" else "")
		if hero.fatigue_state != "":
			st = DB.fatigue_states[hero.fatigue_state].name + ("  |  " + st if st != "Ready" else "")
		var sl := UI.lbl(st, 15, "Ink")
		if hero.is_breaking():
			sl.add_theme_color_override("font_color", UI.RED)
		elif hero.is_second_wind():
			sl.add_theme_color_override("font_color", UI.GREEN)
		col.add_child(sl)
	tooltip_text = UI.hero_tooltip(hero)


func _restyle() -> void:
	var bg := UI.PAPER_DARK if not selected else Color("#f1d38a")
	add_theme_stylebox_override("panel", UI.box(bg, UI.GOLD if selected else UI.WOOD, 3 if selected else 2, 6, 8, 3))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Audio.play("click", 0.5)
		clicked.emit(self)
		accept_event()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and right_clicked.get_connections().size() > 0:
		Audio.play("page", 0.5)
		right_clicked.emit(self)
		accept_event()
