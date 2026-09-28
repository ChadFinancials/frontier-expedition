extends Control
## Settlement hub: the painted street of buildings, the roster, the chain of settlements
## and the controls for time and expeditions.

var index: int = 0
var top: TopBar
var backdrop: Backdrop
var town: TownView
var chain_row: HBoxContainer
var roster_box: VBoxContainer
var transit_box: VBoxContainer
var info_label: RichTextLabel
var action_row: HBoxContainer
var roster_title: Label


func setup(params: Dictionary) -> void:
	index = int(params.get("index", 0))
	if not Game.company.founded(index):
		index = 0
	var site := Game.company.site_by_index(index)
	backdrop = Backdrop.new()
	backdrop.ground_y = 850
	backdrop.setup(site.get("region_west", "tallgrass") if site.get("region_west", "") != "" else "thunder_peaks", "town", 20 + index)
	add_child(backdrop)
	top = TopBar.new()
	add_child(top)
	# Settlement chain.
	var chain_panel := UI.panel("Dark")
	chain_panel.position = Vector2(0, 72)
	chain_panel.custom_minimum_size = Vector2(1920, 56)
	add_child(chain_panel)
	chain_row = UI.hb(10)
	chain_panel.add_child(chain_row)
	# Town.
	town = TownView.new()
	town.position = Vector2(0, 150)
	town.size = Vector2(1340, 700)
	town.street_y = 680
	town.building_clicked.connect(_on_building)
	add_child(town)
	# Roster.
	var rp := UI.panel()
	rp.position = Vector2(1350, 140)
	rp.custom_minimum_size = Vector2(560, 740)
	rp.size = Vector2(560, 740)
	add_child(rp)
	var rv := UI.vb(8)
	rp.add_child(rv)
	roster_title = UI.hdr("Company", 28, true)
	rv.add_child(roster_title)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(530, 520)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rv.add_child(sc)
	roster_box = UI.vb(6)
	roster_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(roster_box)
	rv.add_child(UI.lbl("On the stage / elsewhere", 18, "InkBold"))
	var sc2 := ScrollContainer.new()
	sc2.custom_minimum_size = Vector2(530, 120)
	sc2.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rv.add_child(sc2)
	transit_box = UI.vb(2)
	sc2.add_child(transit_box)
	# Bottom bar.
	var bp := UI.panel("Dark")
	bp.position = Vector2(0, 890)
	bp.custom_minimum_size = Vector2(1920, 190)
	add_child(bp)
	var bh := UI.hb(24)
	bp.add_child(bh)
	info_label = UI.rich("", 20, false, 900)
	info_label.custom_minimum_size = Vector2(900, 150)
	bh.add_child(info_label)
	action_row = UI.hb(14)
	action_row.alignment = BoxContainer.ALIGNMENT_END
	action_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	action_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bh.add_child(action_row)
	refresh()
	Audio.play_music("music_town")
	var intro = params.get("intro", false)
	if intro is String and intro == "home":
		_intro_home()
	elif intro:
		_intro()
	var msgs: Array = params.get("msgs", [])
	for m in msgs:
		Main.inst.toast(m)


func refresh() -> void:
	var co: Company = Game.company
	var st := co.settlement(index)
	var site := co.site_by_index(index)
	var tier := co.tier_info(st.tier)
	top.set_title(site.name, "%s  |  %d of %d building plots used" % [tier.name, co.plots_used(index), int(tier.slots)])
	top.refresh()
	# Chain.
	UI.clear(chain_row)
	chain_row.add_child(UI.lbl("The Trail West:", 20, "Bold"))
	for i in co.site_count():
		var s2 := co.site_by_index(i)
		var b: Button
		if co.founded(i):
			var t2 := co.tier_info(co.settlement(i).tier)
			var here := co.heroes_at(i).size()
			b = UI.btn("%s (%s, %d)" % [s2.name, t2.name, here], func(): _switch(i), "Tab" if i != index else "Good")
			b.tooltip_text = s2.get("desc", "")
		elif s2.get("founded_at", "") in co.beaten:
			b = UI.btn("Found %s" % s2.name, func(): _found(i), "")
			b.tooltip_text = "%s\nCost: %s" % [s2.get("desc", ""), Company.cost_text(DB.cfg("found_cost", {}))]
		else:
			var reg: Dictionary = DB.regions.get(s2.get("founded_at", ""), {})
			b = UI.btn("? ? ?", Callable(), "Tab")
			b.disabled = true
			b.tooltip_text = "Beyond %s. Defeat %s to settle here." % [reg.get("name", "?"), reg.get("boss", {}).get("name", "its boss")]
		chain_row.add_child(b)
		if i < co.site_count() - 1:
			chain_row.add_child(UI.lbl("→", 22, "Bold"))
	# Town.
	town.set_buildings(st.buildings, int(tier.slots), st.get("ruins", []))
	# Roster.
	var here := co.heroes_at(index)
	roster_title.text = "Company at %s (%d)" % [site.name, here.size()]
	UI.clear(roster_box)
	here.sort_custom(func(a, b): return a.level > b.level if a.level != b.level else a.uid < b.uid)
	for h in here:
		var card := HeroCard.make(h)
		card.dimmed = not h.available()
		card.clicked.connect(func(_c): open_hero(h))
		roster_box.add_child(card)
	if here.is_empty():
		roster_box.add_child(UI.wrap(UI.lbl("No heroes here. Hire at the Hiring Board, or send some along the Stage Line.", 20, "Ink"), 500))
	UI.clear(transit_box)
	for h in co.heroes:
		if h.location != index or h.transit_to >= 0:
			var where := "riding to %s (%d wk)" % [co.settlement_name(h.transit_to), h.transit_weeks] if h.transit_to >= 0 else "at %s" % co.settlement_name(h.location)
			transit_box.add_child(UI.lbl("%s, Lv %d %s: %s" % [h.hero_name, h.level, h.class_name_text(), where], 17, "Ink"))
	# Info & actions.
	var region_id: String = co.expedition_region(index)
	var txt := "[b]%s[/b]  %s" % [site.name, site.get("desc", "")]
	if co.tutorial_pending(index):
		txt += "\n[b]Unfinished business:[/b] Mulligan's gang still holds the old mill on %s, and Ma Delaney with it." % DB.regions[region_id].name
	elif region_id != "":
		var reg2: Dictionary = DB.regions[region_id]
		txt += "\n[b]West:[/b] %s (recommended level %s). %s" % [reg2.name, reg2.rec_level,
			"[color=#7fb069]Boss defeated.[/color]" if region_id in co.beaten else "Boss: %s." % reg2.boss.name]
	info_label.text = txt
	UI.clear(action_row)
	var nt := co.next_tier(st.tier)
	if not nt.is_empty():
		var ub := UI.btn("Grow to %s" % nt.name, _upgrade_tier, "")
		ub.tooltip_text = "Upgrade this %s to a %s: more building plots and bigger buildings.\nCost: %s" % [tier.name, nt.name, Company.cost_text(nt.cost)]
		action_row.add_child(ub)
	var rest := UI.btn("Rest a Week", _rest_week, "")
	rest.tooltip_text = "Let a week pass without an expedition. Heroes finish treatments, the stage line moves, new recruits arrive."
	action_row.add_child(rest)
	if region_id != "":
		action_row.add_child(UI.btn("Ride to the Old Mill  →" if co.tutorial_pending(index) else "Plan Expedition  →", func(): Main.inst.goto("embark", {"index": index}), "Big"))
	else:
		action_row.add_child(UI.btn("The Great Casino", _victory_view, "Big"))


func _switch(i: int) -> void:
	Main.inst.goto("settlement", {"index": i})


func _found(i: int) -> void:
	var co: Company = Game.company
	var why := co.can_found(i)
	if why != "":
		Main.inst.message("Can't Found Yet", why)
		return
	Main.inst.confirm("Found %s?" % co.settlement_name(i), "Raise an Outpost at %s for %s. It starts with a Stage Line so you can send heroes there." % [co.settlement_name(i), Company.cost_text(DB.cfg("found_cost", {}))], func():
		co.found(i)
		Game.save_game()
		Audio.play("fanfare")
		Main.inst.goto("settlement", {"index": i}), "Found It")


func _upgrade_tier() -> void:
	var co: Company = Game.company
	var why := co.can_upgrade_tier(index)
	if why != "":
		Main.inst.message("Not Yet", why)
		return
	var nt := co.next_tier(co.settlement(index).tier)
	Main.inst.confirm("Grow to a %s?" % nt.name, "Cost: %s" % Company.cost_text(nt.cost), func():
		co.upgrade_tier(index)
		Game.save_game()
		Audio.play("fanfare")
		refresh(), "Build It")


func _rest_week() -> void:
	Main.inst.confirm("Rest a Week?", "A week passes with no expedition.", func():
		var msgs := Game.company.advance_week()
		Game.save_game()
		refresh()
		Main.inst.toast("Week %d begins." % Game.company.week)
		for m in msgs:
			Main.inst.toast(m), "Rest")


func _victory_view() -> void:
	Main.inst.message("The Great Casino", "Your company rides under the Casino's golden arch with the whole frontier at its back. Wagons roll down the long trail behind you, bound for the towns you built, and the house has never seen a crew like yours.\n\nYou can keep playing: strengthen your settlements and send expeditions back into the regions for glory and chips.")


func _intro() -> void:
	Main.inst.message("Fort Providence", "Every wagon on the frontier is chasing the same rumor: far to the west, past the last mountain, stands [b]the Great Casino[/b], a paradise city where fortunes are made. Its chips are the only currency anyone trusts out here.\n\nFort Providence was the last real town before the edge of the map, until the outlaw [b]Silas Crane[/b] burned it for refusing his toll. Your company is six hard souls, a wagon, and a short stack of chips.\n\n" + _home_tips())


func _intro_home() -> void:
	Main.inst.message("Fort Providence", "Fort Providence is mostly ash. The stockade is half down, the store and the smithy are charred frames, and the townsfolk are camped in the mud. But Ma Delaney is already hauling planks, and the two members of your company who rode ahead are waiting at the hiring board.\n\nThis is home now. Rebuild it, and push west: [b]the Tallgrass Sea[/b] and Silas Crane's toll bridge lie beyond.\n\n" + _home_tips())


func _home_tips() -> String:
	return "[i]Tips: Click a building to use it. Burned buildings can be rebuilt at half price. Click a hero to see their skills, quirks and gear. When you're ready, [b]Plan Expedition[/b]. Esc opens the menu and How to Play.[/i]"


func open_hero(h: Hero) -> void:
	var sheet := HeroSheet.new()
	sheet.setup(h, index, func(): refresh())
	sheet.wrap = Main.inst.modal(sheet)


func open_building(bid: String) -> void:
	var p := BuildingPanel.new()
	p.setup(bid, index, func(): refresh())
	p.wrap = Main.inst.modal(p)


func _on_building(bid: String) -> void:
	open_building(bid)
