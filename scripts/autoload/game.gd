extends Node
## Global game state: the current Company, save/load, and player settings.

signal changed

const SAVE_PATH := "user://save.json"
const SETTINGS_PATH := "user://settings.json"

var company: Company = null
var settings := {"sfx": 0.8, "music": 0.45, "fullscreen": false, "combat_speed": 1.0, "paper": true}


func _ready() -> void:
	load_settings()
	apply_settings()


func new_game(seed_value: int = -1) -> void:
	company = Company.new()
	company.new_game(seed_value)
	save_game()
	changed.emit()


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	if company == null:
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Could not write save file")
		return
	f.store_string(JSON.stringify(company.to_dict()))
	f.close()


func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if not (data is Dictionary):
		return false
	company = Company.from_dict(DB.normalize(data))
	changed.emit()
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	if data is Dictionary:
		for k in data:
			settings[k] = data[k]
	PaperFX.enabled = bool(settings.get("paper", true))


func save_settings() -> void:
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(settings))


func apply_settings() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if settings.get("fullscreen", false):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		settings.fullscreen = not settings.get("fullscreen", false)
		apply_settings()
		save_settings()
