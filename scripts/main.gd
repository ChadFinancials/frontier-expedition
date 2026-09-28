class_name Main
extends Control
## Root of the game: owns the current screen, modal dialogs, toasts and screen fades.
## Command-line "-- shot=<scenario> out=<file.png>" renders a scenario and saves a screenshot.

static var inst: Main

const SCREENS := {
	"menu": "res://scripts/screens/main_menu.gd",
	"settlement": "res://scripts/screens/settlement_screen.gd",
	"embark": "res://scripts/screens/embark_screen.gd",
	"trail": "res://scripts/screens/trail_screen.gd",
	"combat": "res://scripts/screens/combat_screen.gd",
	"camp": "res://scripts/screens/camp_screen.gd",
	"cave": "res://scripts/screens/cave_screen.gd",
	"results": "res://scripts/screens/results_screen.gd",
}

var screen: Control
var screen_name: String = ""
var modal_layer: Control
var toast_layer: VBoxContainer
var fade: ColorRect
var _busy := false
var shot_args: Dictionary = {}


func _ready() -> void:
	inst = self
	theme = UI.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UI.NIGHT
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	modal_layer = Control.new()
	modal_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modal_layer.z_index = 50
	add_child(modal_layer)
	toast_layer = UI.vb(6)
	toast_layer.position = Vector2(660, 90)
	toast_layer.custom_minimum_size = Vector2(600, 0)
	toast_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_layer.z_index = 80
	add_child(toast_layer)
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 1)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.z_index = 100
	add_child(fade)
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=")
		shot_args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	if shot_args.has("shot"):
		await Shots.run(self, shot_args)
		return
	goto("menu")


func goto(name: String, params: Dictionary = {}, instant: bool = false) -> void:
	if _busy:
		return
	_busy = true
	if not instant and screen != null:
		var tw := create_tween()
		tw.tween_property(fade, "color:a", 1.0, 0.25)
		await tw.finished
	close_all_modals()
	if screen != null:
		screen.queue_free()
		screen = null
	var script: GDScript = load(SCREENS[name])
	screen = script.new()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_name = name
	add_child(screen)
	move_child(screen, 1)
	if screen.has_method("setup"):
		screen.setup(params)
	var tw2 := create_tween()
	tw2.tween_property(fade, "color:a", 0.0, 0.01 if instant else 0.3)
	await tw2.finished
	_busy = false


# --- Modals ---------------------------------------------------------------------------

## Shows `content` centered over a dimmed background. Returns the wrapper to close later.
func modal(content: Control, closable: bool = true, dim: float = 0.6) -> Control:
	var wrap := Control.new()
	wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, dim)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.add_child(center)
	center.add_child(content)
	modal_layer.add_child(wrap)
	if closable:
		shade.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_RIGHT:
				close_modal(wrap))
	wrap.set_meta("closable", closable)
	content.modulate = Color(1, 1, 1, 0)
	var tw := create_tween()
	tw.tween_property(content, "modulate:a", 1.0, 0.15)
	return wrap


func close_modal(wrap: Control) -> void:
	if is_instance_valid(wrap):
		wrap.queue_free()


func close_all_modals() -> void:
	for c in modal_layer.get_children():
		c.queue_free()


func has_modal() -> bool:
	for c in modal_layer.get_children():
		if not c.is_queued_for_deletion():
			return true
	return false


## A parchment dialog with a title, body and buttons. buttons: [[text, callable, variation], ...]
func dialog(title: String, body: String, buttons: Array, width: float = 720) -> Control:
	var p := UI.panel()
	p.custom_minimum_size.x = width
	var v := UI.vb(14)
	p.add_child(v)
	if title != "":
		var t := UI.hdr(title, 34, true)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(t)
	if body != "":
		v.add_child(UI.rich(body, 22, true, width - 40))
	var row := UI.hb(12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	var holder := {"wrap": null}
	for b in buttons:
		var cb: Callable = b[1] if b.size() > 1 else Callable()
		var btn := UI.btn(b[0], Callable(), b[2] if b.size() > 2 else "", 160)
		btn.pressed.connect(func():
			close_modal(holder.wrap)
			if cb.is_valid():
				cb.call())
		row.add_child(btn)
	holder.wrap = modal(p, false)
	return holder.wrap


func confirm(title: String, body: String, on_yes: Callable, yes_text: String = "Yes") -> void:
	dialog(title, body, [[yes_text, on_yes, "Good"], ["Cancel", Callable()]])


func message(title: String, body: String, on_ok: Callable = Callable()) -> void:
	dialog(title, body, [["Continue", on_ok]])


func toast(text: String, kind: String = "neutral") -> void:
	var c := UI.chip(text, kind, 20)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_layer.add_child(c)
	var tw := create_tween()
	tw.tween_interval(2.6)
	tw.tween_property(c, "modulate:a", 0.0, 0.5)
	tw.tween_callback(c.queue_free)


# --- Pause menu -----------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if has_modal():
			var top: Control = modal_layer.get_child(modal_layer.get_child_count() - 1)
			if top.get_meta("closable", true):
				close_modal(top)
		elif screen_name != "menu":
			pause_menu()
		get_viewport().set_input_as_handled()


func pause_menu() -> void:
	var p := UI.panel()
	p.custom_minimum_size = Vector2(520, 0)
	var v := UI.vb(12)
	p.add_child(v)
	var t := UI.hdr("Paused", 40, true)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var holder := {"wrap": null}
	v.add_child(UI.btn("Resume", func(): close_modal(holder.wrap), "Big"))
	v.add_child(UI.btn("Settings", func(): settings_panel(), ""))
	v.add_child(UI.btn("How to Play", func(): help_panel(), ""))
	v.add_child(UI.btn("Save & Quit to Menu", func():
		Game.save_game()
		goto("menu"), ""))
	v.add_child(UI.btn("Quit Game", func():
		Game.save_game()
		get_tree().quit(), "Danger"))
	holder.wrap = modal(p)


func settings_panel() -> void:
	var p := UI.panel()
	p.custom_minimum_size = Vector2(620, 0)
	var v := UI.vb(14)
	p.add_child(v)
	v.add_child(UI.hdr("Settings", 36, true))
	for key in [["sfx", "Sound Effects"], ["music", "Music"]]:
		var row := UI.hb(12)
		var nl := UI.lbl(key[1], 22, "Ink")
		nl.custom_minimum_size.x = 200
		row.add_child(nl)
		var s := HSlider.new()
		s.min_value = 0
		s.max_value = 1
		s.step = 0.05
		s.value = float(Game.settings.get(key[0], 0.5))
		s.custom_minimum_size.x = 300
		s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var k: String = key[0]
		s.value_changed.connect(func(val):
			Game.settings[k] = val
			Audio.update_music_volume()
			Game.save_settings())
		row.add_child(s)
		v.add_child(row)
	var speed_row := UI.hb(12)
	var sl := UI.lbl("Combat Speed", 22, "Ink")
	sl.custom_minimum_size.x = 200
	speed_row.add_child(sl)
	for sp in [[1.0, "Normal"], [1.6, "Fast"], [2.4, "Faster"]]:
		var b := UI.btn(sp[1], Callable(), "Small")
		var val: float = sp[0]
		var nm: String = sp[1]
		b.pressed.connect(func():
			Game.settings.combat_speed = val
			Game.save_settings()
			toast("Combat speed: %s" % nm))
		speed_row.add_child(b)
	v.add_child(speed_row)
	var fs := CheckBox.new()
	fs.text = "Fullscreen (F11)"
	fs.button_pressed = Game.settings.get("fullscreen", false)
	fs.add_theme_color_override("font_color", UI.INK)
	fs.add_theme_color_override("font_hover_color", UI.INK)
	fs.add_theme_color_override("font_pressed_color", UI.INK)
	fs.toggled.connect(func(on):
		Game.settings.fullscreen = on
		Game.apply_settings()
		Game.save_settings())
	v.add_child(fs)
	var holder := {"wrap": null}
	v.add_child(UI.btn("Done", func(): close_modal(holder.wrap)))
	holder.wrap = modal(p)


func help_panel() -> void:
	var p := UI.panel()
	p.custom_minimum_size = Vector2(1100, 760)
	var v := UI.vb(10)
	p.add_child(v)
	v.add_child(UI.hdr("How to Play", 36, true))
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(1060, 600)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	sc.add_child(UI.rich(HELP_TEXT, 21, true, 1030))
	var holder := {"wrap": null}
	v.add_child(UI.btn("Close", func(): close_modal(holder.wrap)))
	holder.wrap = modal(p)


const HELP_TEXT := """[b]The Company.[/b] Somewhere past the last mountain stands [b]the Great Casino[/b], a paradise city where fortunes are made, and whose chips are the currency of the whole frontier. You lead a pioneer company pushing west toward it from Fort Providence. Each week you send up to four heroes on an [b]expedition[/b] along the trail into the region west of a settlement.

[b]The Trail.[/b] Pick a path across the map: fights, trail events, curiosities, camps, caves, trading posts and homesteads. Every stop eats [b]Food[/b] (2 for a full party). Run out and the company starves. Rough going damages the [b]Wagon[/b]; a broken wagon wears everyone down until repaired with Wagon Parts.

[b]Combat.[/b] Heroes stand on the left in ranks 1-4 (rank 1 is the front). Every skill can only be used from certain ranks and can only reach certain enemy ranks: the dots on each skill show which. Hover an enemy to see your exact chance to hit, crit chance and damage. Knockback and pulls rearrange lines. You can Swap places with a neighbor, use supplies for free, or Retreat from any fight but a boss.

[b]Death's Door.[/b] A hero at 0 HP isn't dead yet: every further hit rolls a Deathblow check (about 2 in 3 to survive). Heal them to pull them back. They'll be Shaken for the rest of the trip.

[b]Fatigue.[/b] Hard travel, frightening foes and dark caves build Fatigue (0-200). At 100 a hero is tested: most hit a [b]Breaking Point[/b] (Homesick, Reckless, Paranoid...) and may act on their own, but some find a [b]Second Wind[/b] and inspire everyone. At 200 they Collapse. Rest in town (Saloon, Chapel, Boot Hill) to recover.

[b]Survival Skills.[/b] Every hero has two survival skills (Cook, Hunter, Scout, Wheelwright...). At camp, spend 12 hours on their actions: cook, hunt, fell timber, stand night watch, tell tall tales. Skills also help on the trail and unlock special choices in events. They improve with use.

[b]Curios.[/b] Investigate odd finds by hand for a random result, or use the right supply (a crowbar on a strongbox, salt on something strange) for a sure reward. Some quirks make heroes grab things on their own.

[b]Settlements.[/b] Heroes return at full health, but Fatigue and quirks come home with them. Build and upgrade buildings with chips, Timber and Iron. Beat a region's boss to found an Outpost on its ground; grow it into a Town and City with Land Charters. Use the Stage Line to move heroes between settlements: the oldest towns have the best facilities, but the trip takes weeks.

[b]Permadeath.[/b] Fallen heroes are gone for good. New hands arrive at the Hiring Board every week.

[b]Keys.[/b] Esc: pause menu. F11: fullscreen. Right-click the dark background: close a window."""
