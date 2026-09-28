extends Control
## Title screen.

var backdrop: Backdrop
var wagon: WagonArt
var _scroll := 0.0


func setup(_params: Dictionary) -> void:
	backdrop = Backdrop.new()
	backdrop.setup("tallgrass", "trail", 4)
	add_child(backdrop)
	wagon = WagonArt.new()
	wagon.position = Vector2(700, 772)
	wagon.scale = Vector2(1.1, 1.1)
	var stage_node := PaperFX.stage(self)
	stage_node.add_child(wagon)
	for i in 3:
		var f := Figure.new()
		var cid: String = ["marshal", "preacher", "gunslinger"][i]
		f.setup(DB.cls(cid).look, 100 + i, 1)
		f.position = Vector2(1040 + i * 110, 776)
		f.scale *= 0.82
		stage_node.add_child(f)
	var title := UI.hdr("Frontier Expedition", 104)
	title.position = Vector2(0, 120)
	title.size = Vector2(1920, 140)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("#fbe9c4"))
	title.add_theme_constant_override("shadow_offset_y", 5)
	add_child(title)
	var sub := UI.lbl("All bets are west: a caravan-crawler on the road to the Great Casino", 30, "Bold")
	sub.position = Vector2(0, 250)
	sub.size = Vector2(1920, 40)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", Color("#2a1d14"))
	add_child(sub)
	var box := UI.vb(12)
	box.position = Vector2(760, 820)
	box.custom_minimum_size = Vector2(400, 0)
	add_child(box)
	var row := UI.hb(12)
	box.add_child(row)
	if Game.has_save():
		row.add_child(UI.btn("Continue", _continue, "Big", 260))
	row.add_child(UI.btn("New Game", _new_game, "Big", 260))
	var row2 := UI.hb(12)
	row2.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row2)
	row2.add_child(UI.btn("How to Play", func(): Main.inst.help_panel(), "", 170))
	row2.add_child(UI.btn("Settings", func(): Main.inst.settings_panel(), "", 170))
	row2.add_child(UI.btn("Quit", func(): get_tree().quit(), "Danger", 170))
	box.position.x = (1920 - (560 if Game.has_save() else 280)) / 2.0
	Audio.play_music("music_trail")


func _process(delta: float) -> void:
	_scroll += delta * 40.0
	backdrop.set_scroll(_scroll)
	wagon.roll(_scroll)


func _continue() -> void:
	if Game.load_game():
		if Game.company.run != null:
			Main.inst.goto("trail")
		else:
			Main.inst.goto("settlement", {"index": 0})
	else:
		Main.inst.message("Couldn't load", "The save file couldn't be read.")


func _new_game() -> void:
	if Game.has_save():
		Main.inst.confirm("Start Over?", "Starting a new game will erase your current company.", func():
			Game.new_game()
			_intro(), "Start Over")
	else:
		Game.new_game()
		_intro()


func _intro() -> void:
	if not Game.company.tutorial_pending(0):
		Main.inst.goto("settlement", {"index": 0, "intro": true})
		return
	Main.inst.dialog("The Road West", "Your story begins on the road to Fort Providence: three short stops and one hard fight that teach the basics of travel, camp and combat.\n\nYou can skip it if you already know the trail.",
		[["Ride the Old Mill Road", func():
			Game.company.start_tutorial()
			Game.save_game()
			Main.inst.goto("trail"), "Good"],
		["Skip to Fort Providence", func():
			Game.company.complete_tutorial()
			Game.save_game()
			Main.inst.goto("settlement", {"index": 0, "intro": true})]])
