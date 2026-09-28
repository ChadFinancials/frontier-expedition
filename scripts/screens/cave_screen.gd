extends Control
## A side cave: a short string of rooms explored by lamplight.

var run: RunState
var backdrop: Backdrop
var walkers: Array = []
var info: RichTextLabel
var rooms_row: HBoxContainer
var btn_row: HBoxContainer
var light_bar: StatBar
var party_row: HBoxContainer


func setup(_params: Dictionary) -> void:
	run = Game.company.run
	if run == null or not run.in_cave():
		Main.inst.goto("trail", {}, true)
		return
	backdrop = Backdrop.new()
	backdrop.ground_y = 760
	backdrop.mode = "cave"
	backdrop.setup(run.region_id, "cave", 88 + int(run.cave.room))
	add_child(backdrop)
	var hs := run.party_heroes()
	for i in hs.size():
		var f := Figure.new()
		f.setup(hs[i].cls().look, hs[i].look_seed, 1)
		f.position = Vector2(820 - i * 150, 770)
		f.scale *= 1.05
		add_child(f)
		walkers.append(f)
	var hp := UI.panel("Dark")
	hp.custom_minimum_size = Vector2(1920, 90)
	add_child(hp)
	var hh := UI.hb(20)
	hp.add_child(hh)
	hh.add_child(UI.hdr(run.current_node().data.get("name", "Cave"), 32))
	hh.add_child(UI.lbl("Lamplight", 20, "Bold"))
	light_bar = UI.bar(0, 100, Color("#f2c14e"), 320, 24, true)
	hh.add_child(light_bar)
	rooms_row = UI.hb(8)
	hh.add_child(rooms_row)
	var bp := UI.panel("Dark")
	bp.position = Vector2(0, 850)
	bp.custom_minimum_size = Vector2(1920, 230)
	add_child(bp)
	var bh := UI.hb(20)
	bp.add_child(bh)
	party_row = UI.hb(6)
	bh.add_child(party_row)
	var col := UI.vb(8)
	bh.add_child(col)
	info = UI.rich("", 20, false, 700)
	col.add_child(info)
	btn_row = UI.hb(10)
	col.add_child(btn_row)
	Audio.play_music("music_cave")
	_refresh()


func _refresh() -> void:
	if run == null or not run.in_cave() or not is_inside_tree():
		return
	light_bar.value = int(run.cave.light)
	light_bar.text_override = "%d (%s)" % [int(run.cave.light), run.light_name()]
	backdrop.light = float(run.cave.light) / 100.0
	backdrop.queue_redraw()
	UI.clear(rooms_row)
	var rooms := run.cave_rooms()
	for i in rooms.size():
		var cur := i == int(run.cave.room)
		var done: bool = rooms[i].get("done", false)
		rooms_row.add_child(UI.chip("Room %d%s" % [i + 1, " ✓" if done else ""], "gold" if cur else ("good" if done else "neutral"), 17))
	UI.clear(party_row)
	for h in run.party_heroes():
		var c := HeroCard.make(h, true)
		c.custom_minimum_size.x = 225
		party_row.add_child(c)
	UI.clear(btn_row)
	if run.party_heroes().is_empty():
		return
	if run.cave_done():
		info.text = "You've reached the end of the cave."
		btn_row.add_child(UI.btn("Climb Out", _leave, "Good"))
		return
	var room := run.cave_room()
	var lines: Array = []
	if not room.get("done", false):
		if not room.fight.is_empty():
			lines.append("[color=#f0a080]Something stirs in the dark ahead...[/color]")
		elif room.get("curio", "") != "" and not room.get("curio_done", false):
			lines.append("Something catches the lamplight: [b]%s[/b]." % DB.curios[room.curio].name)
		elif room.get("treasure", false):
			lines.append("The deepest chamber. Something glitters.")
		else:
			lines.append("An empty chamber, dripping and cold.")
	else:
		lines.append("This chamber is clear.")
	info.text = "\n".join(lines)
	if not room.get("done", false):
		if not room.fight.is_empty():
			btn_row.add_child(UI.btn("Face It", _fight_room, "Danger"))
		elif room.get("curio", "") != "" and not room.get("curio_done", false):
			btn_row.add_child(UI.btn("Investigate", _curio_room, ""))
			btn_row.add_child(UI.btn("Leave It", func():
				room.curio_done = true
				room.done = true
				_refresh(), "Small"))
		elif room.get("treasure", false):
			btn_row.add_child(UI.btn("Search the Chamber", func():
				var msgs := run.cave_treasure()
				room.done = true
				room.treasure = false
				Audio.play("coin")
				Game.save_game()
				Main.inst.message("Treasure!", "\n".join(msgs), func(): _refresh()), "Good"))
		else:
			room.done = true
	if room.get("done", false):
		btn_row.add_child(UI.btn("Press Deeper", _advance, "Good"))
	if int(run.supplies.get("lamp_oil", 0)) > 0:
		btn_row.add_child(UI.btn("Lamp Oil (%d)" % int(run.supplies.lamp_oil), func():
			run.use_item("lamp_oil", null)
			Audio.play("click")
			Game.save_game()
			_refresh(), "Small"))
	btn_row.add_child(UI.btn("Leave Cave", _leave, "Small"))


func _fight_room() -> void:
	var room := run.cave_room()
	var enemies: Array = room.fight
	room.fight = []
	if room.get("curio", "") == "" and not room.get("treasure", false):
		room.done = true
	Game.save_game()
	Main.inst.goto("combat", {"enemies": enemies, "kind": "fight", "return": "cave"})


func _curio_room() -> void:
	var room := run.cave_room()
	var cid: String = room.curio
	var comp := run.compulsion_for(cid)
	var known: Array = Game.company.known_keys.get(cid, [])
	var p := UI.panel()
	p.custom_minimum_size = Vector2(700, 0)
	var v := UI.vb(10)
	p.add_child(v)
	v.add_child(UI.hdr(DB.curios[cid].name, 32, true))
	var art := CurioArt.new()
	art.kind = DB.curios[cid].get("art", "crate")
	art.custom_minimum_size = Vector2(660, 160)
	v.add_child(art)
	v.add_child(UI.wrap(UI.lbl(DB.curios[cid].desc, 19, "Ink"), 660))
	var holder := {"wrap": null}
	var go := func(item: String):
		Main.inst.close_modal(holder.wrap)
		var doit := func(h: Hero):
			var res := run.interact_curio(cid, h, item)
			room.curio_done = true
			if not room.get("treasure", false):
				room.done = true
			Game.save_game()
			Audio.play("coin" if res.key_worked else "page")
			var body: String = (comp.text + "\n\n" if not comp.is_empty() else "") + res.text + ("\n\n" + "\n".join(res.msgs) if not res.msgs.is_empty() else "")
			if res.fight != null:
				Main.inst.dialog("Ambush!", body, [["Fight!", func(): Main.inst.goto("combat", {"enemies": res.fight.enemies, "kind": "fight", "return": "cave"}), "Danger"]])
			else:
				Main.inst.message(DB.curios[cid].name, body, func(): _refresh())
		if not comp.is_empty():
			doit.call(comp.hero)
		else:
			HeroPicker.pick(run.party_heroes(), "Who investigates?", doit)
	var flow := HFlowContainer.new()
	v.add_child(flow)
	flow.add_child(UI.btn("Investigate", func(): go.call(""), ""))
	for it in EmbarkOrder.ORDER:
		if int(run.supplies.get(it, 0)) > 0 and it != "food":
			var item: String = it
			flow.add_child(UI.btn(("✓ " if it in known else "") + DB.items[it].name, func(): go.call(item), "Small"))
	v.add_child(UI.btn("Cancel", func(): Main.inst.close_modal(holder.wrap), "Small"))
	holder.wrap = Main.inst.modal(p)


func _advance() -> void:
	UI.clear(btn_row)
	var msgs := run.cave_advance()
	Audio.play("footsteps")
	for m in msgs:
		if "Breaking" in m or "BREAKING" in m or "SECOND" in m:
			Main.inst.toast(m, "purple")
	var tw := create_tween().set_parallel(true)
	for f in walkers:
		tw.tween_property(f, "position:x", f.position.x + 60, 0.5)
	await tw.finished
	for f in walkers:
		f.position.x -= 60
	backdrop.scroll += 300
	Game.save_game()
	if run.party_heroes().is_empty():
		var summary := Game.company.finish_run("defeat")
		Game.save_game()
		Main.inst.goto("results", {"summary": summary})
		return
	_refresh()


func _leave() -> void:
	run.cave_exit()
	run.complete_current()
	Game.save_game()
	Main.inst.goto("trail")
