extends Control
## After an expedition: what was won, who grew, who didn't come back.


func setup(params: Dictionary) -> void:
	var s: Dictionary = params.get("summary", {})
	var co: Company = Game.company
	var region: Dictionary = DB.regions.get(s.get("region", ""), {})
	var bd := Backdrop.new()
	bd.ground_y = 900
	bd.setup(s.get("region", "tallgrass"), "trail", 5)
	add_child(bd)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.45)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var p := UI.panel()
	p.position = Vector2(260, 60)
	p.custom_minimum_size = Vector2(1400, 960)
	add_child(p)
	var v := UI.vb(12)
	p.add_child(v)
	var status: String = s.get("status", "abandoned")
	var title: String = {"victory": "Expedition Complete!", "abandoned": "The Company Returns", "defeat": "Lost on the Trail", "driven_back": "Driven Back"}.get(status, "")
	var th := UI.hdr(title, 48, true)
	th.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(th)
	var sub := UI.lbl("%s  |  now week %d" % [region.get("name", ""), co.week], 20, "Ink")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	if status == "defeat":
		v.add_child(UI.rich("[center]No one from this party made it home. Whatever they found is lost with them.[/center]", 22, true, 1360))
	elif status == "driven_back":
		v.add_child(UI.rich("[center]Silas Crane got away across the Redwater, but he's wounded and the company keeps everything it found. Grow stronger and ride back to finish it.[/center]", 21, true, 1360))
	if str(s.get("story", "")) != "":
		v.add_child(UI.rich("[center][color=#3f6128]%s[/color][/center]" % s.story, 21, true, 1360))
	# Loot.
	var loot: Dictionary = s.get("loot", {})
	var lr := UI.hb(30)
	lr.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(lr)
	for it in [["money", "%d chips" % int(loot.get("money", 0))], ["timber", "%d Timber" % int(loot.get("timber", 0))], ["iron", "%d Iron" % int(loot.get("iron", 0))], ["charter", "%d Charters" % int(loot.get("charters", 0))]]:
		var h := UI.hb(6)
		h.add_child(ResIcon.make(it[0], 34))
		h.add_child(UI.lbl(it[1], 26, "InkBold"))
		lr.add_child(h)
	var ks: Array = loot.get("keepsakes", [])
	if not ks.is_empty():
		v.add_child(UI.rich("[center]Trinkets: [b]%s[/b][/center]" % ", ".join(ks.filter(func(k): return k != "").map(func(k): return DB.keepsakes[k].name)), 21, true, 1360))
	# Heroes.
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 10)
	v.add_child(grid)
	for e in s.get("heroes", []):
		var h: Hero = co.hero(int(e.uid))
		var row := UI.hb(10)
		if h != null:
			var card := HeroCard.make(h, true)
			card.custom_minimum_size.x = 330
			row.add_child(card)
		var lines: Array = ["+%d XP" % int(e.xp)]
		if int(e.level_after) > int(e.level_before):
			lines.append("[color=#3f6128][b]LEVEL UP! Now level %d[/b][/color]" % int(e.level_after))
		for q in e.get("quirks", []):
			lines.append(("[color=#3f6128]New quirk: %s[/color]" if DB.quirks[q].positive else "[color=#a8392e]New quirk: %s[/color]") % DB.quirks[q].name)
		row.add_child(UI.rich("\n".join(lines), 19, true, 300))
		grid.add_child(row)
	var fallen: Array = co.dead.filter(func(d): return int(d.week) >= co.week - 1)
	if not fallen.is_empty():
		v.add_child(UI.hdr("Fallen", 26, true))
		for d in fallen:
			v.add_child(UI.lbl("✝ %s, Level %d %s. %s" % [d.name, int(d.level), DB.classes.get(d.class_id, {}).get("name", ""), d.note], 19, "Ink"))
	for r in s.get("recruits", []):
		v.add_child(UI.lbl("Joined on the trail: %s" % r, 19, "InkBold"))
	for m in s.get("week_msgs", []):
		v.add_child(UI.lbl(m, 18, "Ink"))
	var row2 := UI.hb(16)
	row2.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(UI.spacer(0, 10))
	v.add_child(row2)
	var origin := int(s.get("origin", 0))
	var site: int = int(s.get("found_site", -1))
	if site >= 0 and not co.founded(site):
		var why := co.can_found(site)
		var fb := UI.btn("Found %s (%s)" % [co.settlement_name(site), Company.cost_text(DB.cfg("found_cost", {}))], func():
			if co.found(site):
				# The victorious party stays to build the new outpost.
				for e in s.get("heroes", []):
					var hh: Hero = co.hero(int(e.uid))
					if hh != null:
						hh.location = site
				Game.save_game()
				Audio.play("fanfare")
				Main.inst.goto("settlement", {"index": site}), "Good")
		fb.disabled = why != ""
		fb.tooltip_text = why if why != "" else "Raise an Outpost here. The party stays to build it."
		row2.add_child(fb)
		if why != "":
			row2.add_child(UI.lbl("(%s. You can found it later from the settlement screen.)" % why, 17, "Ink"))
	var home_params := {"index": origin}
	if s.get("tutorial", false):
		home_params["intro"] = "home"
	row2.add_child(UI.btn("%s %s" % ["Ride into" if s.get("tutorial", false) else "Return to", co.settlement_name(origin)], func(): Main.inst.goto("settlement", home_params), "Big"))
	Audio.play_music("music_town")
	if status == "victory" and s.get("boss_won", false) and s.get("region", "") == "thunder_peaks" and not co.victory_seen:
		co.victory_seen = true
		Game.save_game()
		Main.inst.message("The Great Casino", "Beyond the Titan's pass the valley blazes with light: the Great Casino, at last. Your company has carved a road across the frontier, from Fort Providence to the end of the trail.\n\n[b]Thank you for playing.[/b] Found a claim at the Great Casino to see the end of the trail, and keep playing as long as you like.")
