class_name BuildingPanel
extends PanelContainer
## Modal for one building in a settlement (or an empty plot when bid == "").

var bid: String = ""
var index: int = 0
var on_change: Callable
var wrap: Control
var selected_uid: int = -1


func setup(building_id: String, settlement_index: int, changed: Callable = Callable()) -> void:
	bid = building_id
	index = settlement_index
	on_change = changed
	custom_minimum_size = Vector2(1240, 780)
	_build()


func _changed() -> void:
	Game.save_game()
	if on_change.is_valid():
		on_change.call()
	UI.clear(self)
	_build()


func _build() -> void:
	var v := UI.vb(10)
	add_child(v)
	if bid == "":
		_empty_plot(v)
		return
	var co: Company = Game.company
	var b: Dictionary = DB.buildings[bid]
	var lvl := co.building_level(index, bid)
	var head := UI.hb(12)
	v.add_child(head)
	head.add_child(UI.hdr("%s  %s" % [b.name, "★".repeat(lvl)], 34, true))
	head.add_child(UI.spacer(0, 0, true))
	head.add_child(UI.btn("Close", func(): Main.inst.close_modal(wrap), "Small"))
	v.add_child(UI.wrap(UI.lbl(b.desc, 19, "Ink"), 1180))
	var body := UI.vb(8)
	body.custom_minimum_size = Vector2(1180, 520)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(1190, 540)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.add_child(body)
	v.add_child(sc)
	match bid:
		"saloon", "chapel", "boot_hill":
			_activities(body)
		"doctor":
			_doctor(body)
		"smithy":
			_smithy(body)
		"drill_hall":
			_drill(body)
		"general_store":
			_store(body)
		"hiring_board":
			_hiring(body)
		"stage_line":
			_stage(body)
	if bid == "boot_hill":
		_memorial(body)
	_upgrade_footer(v)


func _hero_picker(parent: Control, filter: Callable, empty_text: String = "No available heroes here.") -> void:
	var co: Company = Game.company
	var cands := co.service_candidates(index).filter(filter)
	var flow := HFlowContainer.new()
	flow.custom_minimum_size.x = 1160
	parent.add_child(flow)
	if cands.is_empty():
		parent.add_child(UI.lbl(empty_text, 18, "Ink"))
		return
	if selected_uid < 0 or not cands.any(func(h): return h.uid == selected_uid):
		selected_uid = cands[0].uid
	for h in cands:
		var card := HeroCard.make(h, true)
		card.selected = h.uid == selected_uid
		card.clicked.connect(func(_c):
			selected_uid = h.uid
			UI.clear(self)
			_build())
		flow.add_child(card)


func _activities(body: VBoxContainer) -> void:
	var co: Company = Game.company
	body.add_child(UI.lbl("Choose a hero, then an activity. Rooms left this week: %d" % co.slots_left(index, bid), 19, "InkBold"))
	_hero_picker(body, func(h): return h.fatigue > 0 or h.is_breaking(), "Nobody here needs rest right now. Heroes come back from the trail tired.")
	var h: Hero = co.hero(selected_uid)
	for a in DB.buildings[bid].get("activities", []):
		var row := UI.hb(14)
		var lbl := UI.lbl(a.name, 22, "InkBold")
		lbl.custom_minimum_size.x = 300
		row.add_child(lbl)
		var relief := co.activity_relief(index, bid, a.id)
		var cost := co.activity_cost(index, bid, a.id)
		var side: Array = []
		for se in a.get("side_effects", []):
			side.append("%d%% chance: %s" % [int(se.chance), str(se.text).replace("%s ", "").replace("%s", "")])
		var desc := UI.lbl("Sheds up to %d Fatigue. %d chips.%s" % [relief, cost, ("  " + " ".join(side)) if not side.is_empty() else ""], 17, "Ink")
		desc.custom_minimum_size.x = 620
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(desc)
		var aid: String = a.id
		var btn := UI.btn("Send", func():
			var msgs := co.do_activity(index, bid, aid, h)
			Audio.play("coin")
			for m in msgs:
				Main.inst.toast(m, "good")
			_changed(), "Good")
		var why := co.can_do_activity(index, bid, a.id, h) if h != null else "Choose a hero"
		btn.disabled = why != ""
		btn.tooltip_text = why
		row.add_child(btn)
		body.add_child(row)
	body.add_child(UI.lbl("Heroes who use this building sit out the next expedition. Visiting also clears a Breaking Point.", 17, "Ink"))


func _doctor(body: VBoxContainer) -> void:
	var co: Company = Game.company
	body.add_child(UI.lbl("Patients this week: %d left. Treatment removes one bad quirk; the patient sits out the next expedition." % co.slots_left(index, "doctor"), 19, "InkBold"))
	var any := false
	for h in co.heroes_at(index):
		var negs: Array = h.negative_quirks()
		if negs.is_empty():
			continue
		any = true
		var row := UI.hb(10)
		var nl := UI.lbl("%s (Lv %d %s)" % [h.hero_name, h.level, h.class_name_text()], 19, "InkBold")
		nl.custom_minimum_size.x = 380
		row.add_child(nl)
		for q in negs:
			var qq: String = q
			var hh: Hero = h
			var b := UI.btn("Treat %s (%d chips)" % [DB.quirks[q].name, co.doctor_cost(index, h)], func():
				if co.treat_quirk(index, hh, qq):
					Audio.play("heal")
					Main.inst.toast("%s is cured of %s." % [hh.hero_name, DB.quirks[qq].name], "good")
					_changed(), "Small")
			var why := co.can_treat_quirk(index, h, q)
			b.disabled = why != ""
			b.tooltip_text = UI.quirk_tooltip(q) + ("\n" + why if why != "" else "")
			row.add_child(b)
		body.add_child(row)
	if not any:
		body.add_child(UI.lbl("Nobody here has anything the doctor can treat.", 18, "Ink"))


func _smithy(body: VBoxContainer) -> void:
	var co: Company = Game.company
	var lvl := co.building_level(index, "smithy")
	body.add_child(UI.lbl("This Smithy can make gear up to tier %d. Gear tier can't exceed a hero's level." % int(DB.buildings.smithy.max_tier[lvl - 1]), 19, "InkBold"))
	for h in co.heroes_at(index):
		var row := UI.hb(10)
		var nl := UI.lbl("%s (Lv %d %s)" % [h.hero_name, h.level, h.class_name_text()], 19, "InkBold")
		nl.custom_minimum_size.x = 380
		row.add_child(nl)
		for kind in ["weapon", "armor"]:
			var tier: int = h.weapon_tier if kind == "weapon" else h.armor_tier
			row.add_child(UI.lbl("%s %d" % [kind.capitalize(), tier], 18, "Ink"))
			if tier < DB.cfg("max_tier", 4):
				var k: String = kind
				var hh: Hero = h
				var b := UI.btn("→ %d (%s)" % [tier + 1, Company.cost_text(co.gear_cost(index, kind, tier + 1))], func():
					if co.upgrade_gear(index, hh, k):
						Audio.play("clang")
						_changed(), "Small")
				var why := co.can_upgrade_gear(index, h, kind)
				b.disabled = why != ""
				b.tooltip_text = why
				row.add_child(b)
		body.add_child(row)


func _drill(body: VBoxContainer) -> void:
	var co: Company = Game.company
	var lvl := co.building_level(index, "drill_hall")
	body.add_child(UI.lbl("Trains skills up to level %d. A skill can be at most one level above its hero's level." % int(DB.buildings.drill_hall.max_skill[lvl - 1]), 19, "InkBold"))
	_hero_picker(body, func(_h): return true)
	var h: Hero = co.hero(selected_uid)
	if h == null:
		return
	for sid in h.cls().skills:
		var row := UI.hb(10)
		var nl := UI.lbl(DB.skill(sid).name + ("  (equipped)" if sid in h.equipped else ""), 19, "InkBold")
		nl.custom_minimum_size.x = 340
		nl.tooltip_text = UI.skill_tooltip(sid, h.skill_level(sid))
		nl.mouse_filter = Control.MOUSE_FILTER_STOP
		row.add_child(nl)
		row.add_child(RankDots.for_skill(sid))
		row.add_child(UI.lbl("Level %d" % h.skill_level(sid), 18, "Ink"))
		if h.skill_level(sid) < DB.cfg("max_skill_level", 4):
			var s2: String = sid
			var b := UI.btn("Train to %d (%d chips)" % [h.skill_level(sid) + 1, co.skill_cost(index, h.skill_level(sid) + 1)], func():
				if co.upgrade_skill(index, h, s2):
					Audio.play("buff")
					_changed(), "Small")
			var why := co.can_upgrade_skill(index, h, sid)
			b.disabled = why != ""
			b.tooltip_text = why
			row.add_child(b)
		body.add_child(row)


func _store(body: VBoxContainer) -> void:
	var co: Company = Game.company
	var st := co.settlement(index)
	body.add_child(UI.lbl("Supplies are bought when you plan an expedition (%d%% discount here). This week's keepsakes:" % co.store_discount(index), 19, "InkBold"))
	if st.stock.is_empty():
		body.add_child(UI.lbl("Sold out. New stock arrives next week.", 18, "Ink"))
	for k in st.stock:
		var row := UI.hb(12)
		var nl := UI.lbl(DB.keepsakes[k].name, 20, "InkBold")
		nl.custom_minimum_size.x = 300
		row.add_child(nl)
		var ml := UI.lbl(", ".join(DB.keepsakes[k].get("mods", []).map(func(m): return Stats.mod_text(m))), 17, "Ink")
		ml.custom_minimum_size.x = 560
		ml.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(ml)
		var kk: String = k
		var b := UI.btn("Buy (%d chips)" % co.keepsake_price(index, k), func():
			if co.buy_keepsake(index, kk):
				Audio.play("coin")
				Main.inst.toast("Bought %s. Equip it from a hero's sheet." % DB.keepsakes[kk].name, "good")
				_changed(), "Good")
		b.disabled = co.money < co.keepsake_price(index, k)
		row.add_child(b)
		body.add_child(row)
	body.add_child(UI.lbl("Keepsake stash: %d" % co.stash.size(), 18, "Ink"))


func _hiring(body: VBoxContainer) -> void:
	var co: Company = Game.company
	var st := co.settlement(index)
	body.add_child(UI.lbl("Hands looking for work this week. Hiring is free. Company size: %d / %d" % [co.heroes.size(), DB.cfg("roster_cap", 24)], 19, "InkBold"))
	if st.recruits.is_empty():
		body.add_child(UI.lbl("Nobody's left. More will turn up next week.", 18, "Ink"))
	var i := 0
	for rd in st.recruits:
		var h := Hero.from_dict(rd)
		var row := UI.hb(12)
		var card := HeroCard.make(h, true)
		card.custom_minimum_size.x = 420
		row.add_child(card)
		var info := UI.vb(2)
		var sv: Array = []
		for s in h.survival:
			sv.append(DB.survival[s].name)
		var qs: Array = []
		for q in h.quirks:
			qs.append(("[color=#3f6128]+%s[/color]" if DB.quirks[q].positive else "[color=#a8392e]-%s[/color]") % DB.quirks[q].name)
		info.add_child(UI.rich("[b]%s[/b], %s\nSurvival: %s\nQuirks: %s" % [h.class_name_text(), h.cls().get("role", ""), ", ".join(sv), ", ".join(qs)], 17, true, 520))
		row.add_child(info)
		var idx := i
		var b := UI.btn("Hire", func():
			var nh := co.hire(index, idx)
			if nh != null:
				Audio.play("coin")
				Main.inst.toast("%s joins the company!" % nh.hero_name, "good")
				_changed(), "Good")
		b.disabled = co.heroes.size() >= DB.cfg("roster_cap", 24)
		row.add_child(b)
		body.add_child(row)
		i += 1


func _stage(body: VBoxContainer) -> void:
	var co: Company = Game.company
	body.add_child(UI.lbl("Seats left this week: %d. Each stop along the trail takes a week of travel." % co.slots_left(index, "stage_line"), 19, "InkBold"))
	var dests: Array = []
	for s in co.settlements:
		if int(s.index) != index:
			dests.append(int(s.index))
	if dests.is_empty():
		body.add_child(UI.lbl("There's nowhere else to go yet. Found a new settlement to open a route.", 18, "Ink"))
		return
	for h in co.service_candidates(index):
		var row := UI.hb(10)
		var nl := UI.lbl("%s (Lv %d %s)" % [h.hero_name, h.level, h.class_name_text()], 19, "InkBold")
		nl.custom_minimum_size.x = 380
		row.add_child(nl)
		for d in dests:
			var hh: Hero = h
			var dd: int = d
			var b := UI.btn("→ %s (%d wk)" % [co.settlement_name(d), absi(d - index)], func():
				if co.send_hero(index, dd, hh):
					Audio.play("whip")
					Main.inst.toast("%s boards the stage for %s." % [hh.hero_name, co.settlement_name(dd)])
					_changed(), "Small")
			var why := co.can_send(index, d, h)
			b.disabled = why != ""
			b.tooltip_text = why
			row.add_child(b)
		body.add_child(row)


func _memorial(body: VBoxContainer) -> void:
	var co: Company = Game.company
	body.add_child(UI.hdr("The Fallen", 24, true))
	if co.dead.is_empty():
		body.add_child(UI.lbl("No graves yet. May it stay that way.", 18, "Ink"))
	for d in co.dead:
		body.add_child(UI.lbl("✝ %s, Level %d %s. %s (week %d)" % [d.name, int(d.level), DB.classes.get(d.class_id, {}).get("name", "?"), d.note, int(d.week)], 18, "Ink"))


func _upgrade_footer(v: VBoxContainer) -> void:
	var co: Company = Game.company
	var lvl := co.building_level(index, bid)
	var costs: Array = DB.buildings[bid].costs
	var row := UI.hb(12)
	v.add_child(row)
	if lvl >= costs.size():
		row.add_child(UI.lbl("Fully upgraded.", 18, "InkBold"))
		return
	var why := co.can_build(index, bid)
	row.add_child(UI.lbl("Upgrade to level %d: %s" % [lvl + 1, Company.cost_text(co.building_cost(index, bid))], 19, "InkBold"))
	var b := UI.btn("Upgrade", func():
		if co.build(index, bid):
			Audio.play("hammer")
			Main.inst.toast("%s upgraded!" % DB.buildings[bid].name, "good")
			_changed(), "Good")
	b.disabled = why != ""
	b.tooltip_text = why
	row.add_child(b)
	if why != "":
		row.add_child(UI.lbl(why, 17, "Ink"))


func _empty_plot(v: VBoxContainer) -> void:
	var co: Company = Game.company
	var head := UI.hb(12)
	v.add_child(head)
	head.add_child(UI.hdr("Empty Plot", 34, true))
	head.add_child(UI.spacer(0, 0, true))
	head.add_child(UI.btn("Close", func(): Main.inst.close_modal(wrap), "Small"))
	v.add_child(UI.lbl("Choose something to build here.", 19, "Ink"))
	var st := co.settlement(index)
	var ids: Array = DB.buildings.keys()
	ids.sort_custom(func(a, b): return DB.buildings[a].get("order", 0) < DB.buildings[b].get("order", 0))
	for id in ids:
		if st.buildings.has(id):
			continue
		var row := UI.hb(12)
		var nl := UI.lbl(DB.buildings[id].name, 21, "InkBold")
		nl.custom_minimum_size.x = 230
		row.add_child(nl)
		var dl := UI.lbl(DB.buildings[id].desc, 16, "Ink")
		dl.custom_minimum_size.x = 620
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(dl)
		var bb: String = id
		var b := UI.btn("Build (%s)" % Company.cost_text(co.building_cost(index, id)), func():
			if co.build(index, bb):
				Audio.play("hammer")
				Main.inst.toast("%s built!" % DB.buildings[bb].name, "good")
				Main.inst.close_modal(wrap)
				Game.save_game()
				if on_change.is_valid():
					on_change.call(), "Good")
		var why := co.can_build(index, id)
		b.disabled = why != ""
		b.tooltip_text = why
		row.add_child(b)
		v.add_child(row)
