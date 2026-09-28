extends Control
## Night camp: choose a meal, spend 12 hours on survival skills, then risk the night.

var run: RunState
var backdrop: Backdrop
var panel_box: VBoxContainer
var log_label: RichTextLabel
var hours_label: Label


func setup(_params: Dictionary) -> void:
	run = Game.company.run
	backdrop = Backdrop.new()
	backdrop.ground_y = 760
	backdrop.night = 1.0
	backdrop.setup(run.region_id, "camp", 55)
	add_child(backdrop)
	var wagon := WagonArt.new()
	wagon.show_team = false
	wagon.position = Vector2(300, 700)
	wagon.scale = Vector2(0.75, 0.75)
	wagon.modulate = Color(0.55, 0.5, 0.6)
	var stage_node := PaperFX.stage(self)
	stage_node.add_child(wagon)
	var fire := Campfire.new()
	fire.position = Vector2(620, 790)
	fire.z_index = 2
	add_child(fire)
	var hs := run.party_heroes()
	var spots := [Vector2(420, 800), Vector2(520, 850), Vector2(760, 850), Vector2(840, 800)]
	for i in hs.size():
		var f := Figure.new()
		f.setup(hs[i].cls().look, hs[i].look_seed, 1 if spots[i].x < 620 else -1)
		f.position = spots[i]
		f.scale *= 0.8
		f.modulate = Color(1.0, 0.82, 0.62)
		stage_node.add_child(f)
	var title := UI.hdr("Campsite", 48)
	title.position = Vector2(40, 30)
	add_child(title)
	var sub := UI.lbl("Day %d on the trail. Food: %d" % [run.day, int(run.supplies.get("food", 0))], 22, "Bold")
	sub.position = Vector2(44, 96)
	add_child(sub)
	var lp := UI.panel("Dark")
	lp.position = Vector2(20, 900)
	lp.custom_minimum_size = Vector2(1080, 170)
	add_child(lp)
	log_label = UI.rich("", 18, false, 1050)
	log_label.fit_content = false
	log_label.scroll_active = true
	log_label.scroll_following = true
	log_label.custom_minimum_size = Vector2(1050, 150)
	lp.add_child(log_label)
	var rp := UI.panel()
	rp.position = Vector2(1120, 20)
	rp.custom_minimum_size = Vector2(780, 1040)
	rp.size = Vector2(780, 1040)
	add_child(rp)
	var rv := UI.vb(8)
	rp.add_child(rv)
	hours_label = UI.hdr("", 30, true)
	rv.add_child(hours_label)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(750, 900)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rv.add_child(sc)
	panel_box = UI.vb(8)
	sc.add_child(panel_box)
	if run.camp.is_empty():
		run.camp_start()
	Audio.play_music("music_camp")
	Audio.play("fire")
	_refresh()


func _log(lines: Array) -> void:
	for l in lines:
		log_label.append_text(str(l) + "\n")


func _refresh() -> void:
	UI.clear(panel_box)
	if run.camp.get("meal", "") == "":
		hours_label.text = "Supper"
		panel_box.add_child(UI.lbl("First, what does the company eat tonight?", 20, "Ink"))
		var hs := run.party_heroes()
		for m in DB.cfg("meals", []):
			var cost := int(ceil(int(m.food) * hs.size() / 4.0))
			var fx: Array = []
			if int(m.heal_pct) > 0:
				fx.append("heal %d%%" % int(m.heal_pct))
			if int(m.fatigue) < 0:
				fx.append("%d Fatigue" % int(m.fatigue))
			if int(m.fatigue) > 0:
				fx.append("+%d Fatigue" % int(m.fatigue))
			var mid: String = m.id
			var b := UI.btn("%s: %d food%s" % [m.name, cost, ("  (" + ", ".join(fx) + ")") if not fx.is_empty() else ""], func():
				_log(run.camp_meal(mid))
				Audio.play("eat")
				Game.save_game()
				_refresh(), "")
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.disabled = int(run.supplies.get("food", 0)) < cost
			panel_box.add_child(b)
		return
	hours_label.text = "Hours until dawn: %d" % int(run.camp.hours)
	panel_box.add_child(UI.lbl("Each hero can use each of their survival actions once. More unlock as survival skills rank up with use. Hover for details.", 18, "Ink"))
	var acts := run.camp_actions()
	for h in run.party_heroes():
		var hv := UI.vb(4)
		panel_box.add_child(hv)
		var head := UI.hb(8)
		hv.add_child(head)
		head.add_child(UI.lbl(h.hero_name, 21, "InkBold"))
		head.add_child(UI.lbl("HP %d/%d  Fatigue %d" % [h.hp, h.max_hp(), h.fatigue], 17, "Ink"))
		var flow := HFlowContainer.new()
		flow.custom_minimum_size.x = 730
		hv.add_child(flow)
		for a in acts:
			if a.uid != h.uid:
				continue
			var ad: Dictionary = a.action
			var cost_txt := ""
			for it in ad.get("cost", {}):
				cost_txt += ", %d %s" % [int(ad.cost[it]), DB.items.get(it, {}).get("name", it)]
			var b := UI.btn("%s: %s (%dh%s)" % [DB.survival[a.skill].name, ad.name, int(ad.hours), cost_txt], Callable(), "Small")
			b.tooltip_text = "%s  (rank %d %s)\n%s\n\n%s" % [ad.name, a.rank, DB.survival[a.skill].name, ad.desc, UI.camp_effects_text(ad, a.rank, run.party_heroes())]
			b.disabled = not a.available
			if a.used:
				b.text = "✔ " + b.text
			elif a.locked:
				b.text = "%s (unlocks at rank %d)" % [ad.name, int(ad.get("unlock", 2))]
				b.tooltip_text += "\n\nUnlocks when %s reaches rank %d." % [DB.survival[a.skill].name, int(ad.get("unlock", 2))]
			elif a.get("pointless", false):
				b.tooltip_text += "\n\nNothing left to scout: every stop ahead is already known."
			elif not a.affordable:
				b.tooltip_text += "\n\nNot enough supplies."
			var uid: int = h.uid
			var aid: String = ad.id
			var target_kind: String = ad.get("target", "party")
			b.pressed.connect(func():
				if target_kind == "ally":
					HeroPicker.pick(run.party_heroes(), "%s: on whom?" % ad.name, func(t: Hero): _act(uid, aid, t.uid))
				else:
					_act(uid, aid, uid))
			flow.add_child(b)
	panel_box.add_child(UI.spacer(0, 10))
	var brk := UI.btn("Break Camp at Dawn", _end, "Big")
	panel_box.add_child(brk)
	if not run.camp.get("no_ambush", false):
		panel_box.add_child(UI.lbl("Without a watch, there's a %d%% chance of a night ambush." % DB.cfg("camp_ambush_chance", 20), 17, "Ink"))
	else:
		panel_box.add_child(UI.lbl("The camp is guarded tonight.", 17, "Ink"))


func _act(uid: int, aid: String, target_uid: int) -> void:
	var msgs := run.camp_act(uid, aid, target_uid)
	_log(msgs)
	Audio.play("buff")
	for m in msgs:
		if "improves" in m:
			Main.inst.toast(m, "good")
	Game.save_game()
	_refresh()


func _end() -> void:
	var res := run.camp_end()
	if res.ambush:
		var pf: Dictionary = run.pending_fight
		run.pending_fight = {}
		run.complete_current()
		Game.save_game()
		Audio.play("howl")
		Main.inst.dialog("Ambush in the Night!", "Shapes move at the edge of the firelight. The company scrambles for their weapons!", [["Fight!", func():
			Main.inst.goto("combat", {"enemies": pf.enemies, "kind": "fight", "surprise": "heroes", "return": "trail"}), "Danger"]])
		return
	run.complete_current()
	Game.save_game()
	Main.inst.dialog("Dawn", "The night passes quietly. The company packs up and moves on.", [["Continue", func(): Main.inst.goto("trail")]])
