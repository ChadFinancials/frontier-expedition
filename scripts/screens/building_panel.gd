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
	if co.is_ruin(index, bid):
		_ruin(v)
		return
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
	_staff(body)
	match bid:
		"lumber_yard", "mine", "trapping_post":
			_producer(body)
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
			_activities(body)
		"stage_line":
			_stage(body)
	if bid == "boot_hill":
		_memorial(body)
	_upgrade_footer(v)


## Townsfolk seats: none at level 1, then one, then two (see Company.staff_seats). The
## right trade is marked ★; anyone else lends a hand for less.
func _staff(body: VBoxContainer) -> void:
	var co: Company = Game.company
	var most := co.staff_seats_max(bid)
	if most <= 0:
		return
	var own := Townsfolk.trade_for(bid)
	var own_name: String = DB.townsfolk.trades[own].name
	var card := UI.panel("Card")
	body.add_child(card)
	var cv := UI.vb(6)
	card.add_child(cv)
	var cap := co.staff_seats(index, bid)
	var staff := co.staff_at(index, bid)
	var head := UI.hb(14)
	cv.add_child(head)
	head.add_child(UI.lbl("Staff", 22, "InkBold"))
	var total := co.staff_value(index, bid)
	if total > 0.0:
		head.add_child(UI.lbl("Together: %s" % Townsfolk.value_text(bid, total), 18, "Ink"))
	if cap <= 0:
		cv.add_child(UI.lbl("Opens at level 2. Best: %s ★" % own_name, 17, "Ink"))
		return
	head.add_child(UI.lbl("Best: %s ★" % own_name, 17, "Ink"))
	var row := UI.hb(10)
	cv.add_child(row)
	for n in cap:
		if n < staff.size():
			var p: Dictionary = staff[n]
			var sv := UI.vb(4)
			row.add_child(sv)
			var tc := TownsfolkCard.make(p)
			tc.custom_minimum_size.x = 520
			sv.add_child(tc)
			var sub := UI.hb(10)
			sv.add_child(sub)
			sub.add_child(UI.lbl(("★ " if Townsfolk.fits(p, bid) else "") + "Adds " + Townsfolk.value_text(bid, Townsfolk.value_in(p, bid)), 16, "InkBold"))
			sub.add_child(UI.btn("Let go", func():
				co.unpost_townsperson(p)
				_changed(), "Small"))
		else:
			row.add_child(UI.btn("+ Staff", func(): _pick_staff(), "Tab", 220))
	if co.townsfolk_at(index).is_empty():
		cv.add_child(UI.lbl("Nobody lives here yet. Townsfolk turn up on expeditions and side quests.", 16, "Ink"))


func _pick_staff() -> void:
	var co: Company = Game.company
	var free := co.townsfolk_at(index).filter(func(p): return str(p.post) != bid)
	free.sort_custom(func(a, b): return int(Townsfolk.fits(a, bid)) > int(Townsfolk.fits(b, bid)))
	TownsfolkCard.pick(free, "Who works at the %s?" % DB.buildings[bid].name, func(p: Dictionary):
		if co.post_townsperson(p, bid):
			Audio.play("coin")
			Main.inst.toast("%s goes to work at the %s." % [p.name, DB.buildings[bid].name], "good")
			_changed(),
		func(p: Dictionary):
			var t := ("★ " if Townsfolk.fits(p, bid) else "") + "Would add " + Townsfolk.value_text(bid, Townsfolk.value_in(p, bid))
			if str(p.post) != "":
				t += " (leaves the %s)" % DB.buildings.get(str(p.post), {}).get("name", "?")
			return t,
		"Nobody free lives here. Townsfolk turn up on expeditions and side quests.")


## Lumber Yard, Iron Mine, Trapping Post: what comes in each week.
func _producer(body: VBoxContainer) -> void:
	var co: Company = Game.company
	var made := co.production(index, bid)
	var lvl := co.building_level(index, bid)
	for mat in made:
		var base: Array = DB.buildings[bid].produce[mat]
		var own := int(base[mini(lvl, base.size()) - 1])
		body.add_child(UI.lbl("Brings in %d %s a week: %d from the %s, %d from its staff." % [int(made[mat]), str(mat).capitalize(), own, DB.buildings[bid].name, int(made[mat]) - own], 20, "InkBold"))
	body.add_child(UI.lbl("Delivered at the start of each week.", 17, "Ink"))


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


## A row of slots: the heroes already placed this week, then empty boxes to click.
func _slot_row(parent: Control, key: String, cap: int, on_empty: Callable, empty_text: String = "+ Assign") -> void:
	var co: Company = Game.company
	var row := UI.hb(10)
	parent.add_child(row)
	var placed: Array = co.slot_heroes(index, key)
	for n in cap:
		var h: Hero = co.hero(int(placed[n])) if n < placed.size() else null
		var sb := SlotBox.make(h, empty_text)
		if h == null:
			sb.pressed.connect(on_empty)
		row.add_child(sb)


func _activities(body: VBoxContainer) -> void:
	var co: Company = Game.company
	if bid == "saloon":
		var qs: Array = co.settlement(index).get("quests", [])
		var ch := UI.panel("Card")
		body.add_child(ch)
		var cv := UI.vb(4)
		ch.add_child(cv)
		cv.add_child(UI.lbl("Chatter at the bar this week", 22, "InkBold"))
		if qs.is_empty():
			cv.add_child(UI.lbl("Nothing worth repeating. New talk comes in every week.", 17, "Ink"))
		for q in qs:
			var reg: Dictionary = DB.regions.get(q, {})
			cv.add_child(UI.rich("[b]%s[/b]: %s  %s" % [reg.get("name", "?"), reg.get("desc", ""), Company.quest_hints(reg)], 17, true, 1100))
	if bid != "hiring_board":
		body.add_child(UI.lbl("Heroes sent here sit out the next expedition. A visit also clears a Breaking Point.", 18, "InkBold"))
	for a in DB.buildings[bid].get("activities", []):
		var aid: String = a.id
		var key: String = bid + "/" + aid
		var card := UI.panel("Card")
		body.add_child(card)
		var cv := UI.vb(6)
		card.add_child(cv)
		var relief := co.activity_relief(index, bid, aid)
		var cost := co.activity_cost(index, bid, aid)
		var head := UI.hb(14)
		cv.add_child(head)
		head.add_child(UI.lbl(a.name, 24, "InkBold"))
		head.add_child(UI.lbl("Sheds up to %d Fatigue  |  %s" % [relief, "%d chips" % cost if cost > 0 else "free"], 18, "Ink"))
		if a.has("desc"):
			cv.add_child(UI.wrap(UI.lbl(str(a.desc) + " The hero sits out the next expedition.", 16, "Ink"), 1100))
		var side: Array = []
		for se in a.get("side_effects", []):
			var what := str(se.text).replace("%s ", "").replace("%s", "")
			if se.get("type", "") == "quirk" and DB.quirks.has(se.quirk):
				# Spell out what the quirk actually does, not just its flavor line.
				var q: Dictionary = DB.quirks[se.quirk]
				var fx: Array = UI.quirk_effects(se.quirk)
				what = "the hero picks up the %s%s quirk (%s)" % ["" if q.get("positive", false) else "bad ", q.name, ", ".join(fx)]
			side.append("%d%% chance each visit: %s." % [int(se.chance), what.trim_suffix(".")])
		if not side.is_empty():
			cv.add_child(UI.wrap(UI.lbl(" ".join(side), 16, "Ink"), 1100))
		_slot_row(cv, key, co.activity_slot_cap(index, bid, aid), func():
			var elig := co.service_candidates(index).filter(func(h): return (h.fatigue > 0 or h.is_breaking()) and co.can_do_activity(index, bid, aid, h) == "")
			HeroPicker.pick(elig, "%s: who goes?" % a.name, func(h: Hero):
				var msgs := co.do_activity(index, bid, aid, h)
				Audio.play("coin")
				for m in msgs:
					Main.inst.toast(m, "good")
				_changed(),
				func(h: Hero): return "Fatigue %d, sheds up to %d" % [h.fatigue, relief],
				"Nobody here needs this (or you can't afford %d chips)." % cost))


func _doctor(body: VBoxContainer) -> void:
	var co: Company = Game.company
	body.add_child(UI.lbl("Treats one bad quirk. The patient sits out the next expedition.", 18, "InkBold"))
	_slot_row(body, "doctor", co.slot_cap(index, "doctor"), func():
		var elig := co.service_candidates(index).filter(func(h): return not h.negative_quirks().is_empty())
		HeroPicker.pick(elig, "Who sees the Doctor?", func(h: Hero): _doctor_choose(h),
			func(h: Hero): return "Bad quirks: %s  (%d chips)" % [", ".join(h.negative_quirks().map(func(q): return DB.quirks[q].name)), co.doctor_cost(index, h)],
			"Nobody here has anything the doctor can treat."), "+ Patient")


func _doctor_choose(h: Hero) -> void:
	var co: Company = Game.company
	var buttons: Array = []
	for q in h.negative_quirks():
		var qq: String = q
		var why := co.can_treat_quirk(index, h, q)
		if why == "":
			buttons.append(["Treat %s" % DB.quirks[q].name, func():
				if co.treat_quirk(index, h, qq):
					Audio.play("heal")
					Main.inst.toast("%s is cured of %s." % [h.hero_name, DB.quirks[qq].name], "good")
					_changed(), "Good"])
	buttons.append(["Never mind", Callable()])
	var lines: Array = []
	for q in h.negative_quirks():
		lines.append("[b]%s[/b]: %s" % [DB.quirks[q].name, DB.quirks[q].get("desc", "")])
	Main.inst.dialog("Treat %s" % h.hero_name, "Cost: %d chips.\n\n%s" % [co.doctor_cost(index, h), "\n".join(lines)], buttons)


## A single "workbench" slot for the Smithy and Drill Hall: the hero being worked on.
func _bench(body: VBoxContainer, title: String) -> Hero:
	var co: Company = Game.company
	var row := UI.hb(14)
	body.add_child(row)
	var h: Hero = co.hero(selected_uid) if selected_uid >= 0 else null
	if h != null and h.location != index:
		h = null
	var sb := SlotBox.make(h, "+ Choose a hero")
	sb.disabled = false
	sb.pressed.connect(func():
		HeroPicker.pick(co.heroes_at(index), title, func(ph: Hero):
			selected_uid = ph.uid
			UI.clear(self)
			_build()))
	row.add_child(sb)
	var info := UI.vb(4)
	row.add_child(info)
	if h != null:
		info.add_child(UI.hdr(h.hero_name, 26, true))
		info.add_child(UI.lbl("Level %d %s" % [h.level, h.class_name_text()], 18, "Ink"))
	return h


func _smithy(body: VBoxContainer) -> void:
	var co: Company = Game.company
	var lvl := co.building_level(index, "smithy")
	body.add_child(UI.lbl("Gear up to tier %d (never above the hero's level)." % int(DB.buildings.smithy.max_tier[lvl - 1]), 18, "InkBold"))
	var h := _bench(body, "Who needs gear?")
	if h == null:
		return
	for kind in ["weapon", "armor"]:
		var row := UI.hb(12)
		var tier: int = h.weapon_tier if kind == "weapon" else h.armor_tier
		var nl := UI.lbl("%s: tier %d" % [kind.capitalize(), tier], 21, "InkBold")
		nl.custom_minimum_size.x = 220
		row.add_child(nl)
		if tier < DB.cfg("max_tier", 4):
			var k: String = kind
			var b := UI.btn("Upgrade to %d (%s)" % [tier + 1, Company.cost_text(co.gear_cost(index, kind, tier + 1))], func():
				if co.upgrade_gear(index, h, k):
					Audio.play("clang")
					_changed(), "Good")
			var why := co.can_upgrade_gear(index, h, kind)
			b.disabled = why != ""
			b.tooltip_text = why
			row.add_child(b)
			if why != "":
				row.add_child(UI.lbl(why, 16, "Ink"))
		body.add_child(row)


func _drill(body: VBoxContainer) -> void:
	var co: Company = Game.company
	var lvl := co.building_level(index, "drill_hall")
	body.add_child(UI.lbl("New moves %d chips each. Trains moves up to level %d (at most one above the hero's level)." % [co.learn_cost(index), int(DB.buildings.drill_hall.max_skill[lvl - 1])], 18, "InkBold"))
	var h := _bench(body, "Who trains?")
	if h == null:
		return
	for sid in h.cls().skills:
		var row := UI.hb(10)
		row.add_child(ResIcon.make(UI.skill_kind(sid), 24))
		var nl := UI.lbl(DB.skill(sid).name + ("  (equipped)" if sid in h.equipped else ("" if h.knows(sid) else "  (not learned)")), 19, "InkBold")
		nl.custom_minimum_size.x = 340
		nl.tooltip_text = UI.skill_tooltip(sid, h.skill_level(sid))
		nl.mouse_filter = Control.MOUSE_FILTER_STOP
		row.add_child(nl)
		row.add_child(RankDots.for_skill(sid))
		if not h.knows(sid):
			var s3: String = sid
			var lb := UI.btn("Learn (%d chips)" % co.learn_cost(index), func():
				if co.learn_skill(index, h, s3):
					Audio.play("badge")
					_changed(), "Small")
			var why2 := co.can_learn_skill(index, h, sid)
			lb.disabled = why2 != ""
			lb.tooltip_text = why2
			row.add_child(lb)
			body.add_child(row)
			continue
		row.add_child(UI.lbl("Level %d" % h.skill_level(sid), 18, "Ink"))
		if h.skill_level(sid) < DB.cfg("max_skill_level", 5):
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
	body.add_child(UI.lbl("%d%% off supplies (bought when you plan an expedition). This week's trinkets:" % co.store_discount(index), 19, "InkBold"))
	if st.stock.is_empty():
		body.add_child(UI.lbl("Sold out. New stock arrives next week.", 18, "Ink"))
	for k in st.stock:
		var row := UI.hb(12)
		var nl := UI.lbl(DB.keepsakes[k].name, 20, "InkBold")
		nl.custom_minimum_size.x = 300
		row.add_child(nl)
		var ml := UI.lbl(", ".join(UI.keepsake_effects(k)), 17, "Ink")
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
	body.add_child(UI.lbl("Trinket stash: %d" % co.stash.size(), 18, "Ink"))


func _hiring(body: VBoxContainer) -> void:
	var co: Company = Game.company
	var st := co.settlement(index)
	body.add_child(UI.lbl("Company: %d / %d" % [co.heroes.size(), co.roster_cap()], 19, "InkBold"))
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
		b.disabled = co.heroes.size() >= co.roster_cap()
		row.add_child(b)
		body.add_child(row)
		i += 1


func _stage(body: VBoxContainer) -> void:
	var co: Company = Game.company
	body.add_child(UI.lbl("One week of travel per stop along the trail.", 18, "InkBold"))
	var dests: Array = []
	for s in co.settlements:
		if int(s.index) != index:
			dests.append(int(s.index))
	if dests.is_empty():
		body.add_child(UI.lbl("There's nowhere else to go yet. Found a new settlement to open a route.", 18, "Ink"))
		return
	_slot_row(body, "stage_line", co.slot_cap(index, "stage_line"), func():
		HeroPicker.pick(co.service_candidates(index), "Who rides the stage?", func(h: Hero):
			var buttons: Array = []
			for d in dests:
				var dd: int = d
				if co.can_send(index, d, h) == "":
					buttons.append(["%s (%d wk)" % [co.settlement_name(d), absi(d - index)], func():
						if co.send_hero(index, dd, h):
							Audio.play("whip")
							Main.inst.toast("%s boards the stage for %s." % [h.hero_name, co.settlement_name(dd)])
							_changed(), "Good"])
			buttons.append(["Never mind", Callable()])
			Main.inst.dialog("Where to?", "Send %s along the trail." % h.hero_name, buttons)), "+ Seat")


func _memorial(body: VBoxContainer) -> void:
	var co: Company = Game.company
	body.add_child(UI.hdr("The Fallen", 24, true))
	if co.dead.is_empty():
		body.add_child(UI.lbl("No graves yet. May it stay that way.", 18, "Ink"))
	for d in co.dead:
		body.add_child(UI.lbl("✝ %s, Level %d %s. %s (week %d)" % [d.name, int(d.level), DB.classes.get(d.class_id, {}).get("name", "?"), d.note, int(d.week)], 18, "Ink"))


func _upgrade_footer(v: VBoxContainer) -> void:
	var co: Company = Game.company
	var tracks: Dictionary = DB.buildings[bid].get("tracks", {})
	if not tracks.is_empty():
		v.add_child(UI.lbl("Upgrades", 22, "InkBold"))
		for tid in tracks:
			var t: Dictionary = tracks[tid]
			var tl := co.track_level(index, bid, tid)
			var row := UI.hb(12)
			v.add_child(row)
			var nl := UI.lbl("%s  %s" % [t.name, "★".repeat(tl)], 20, "InkBold")
			nl.custom_minimum_size.x = 260
			row.add_child(nl)
			var dl := UI.lbl(t.desc, 16, "Ink")
			dl.custom_minimum_size.x = 440
			dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			row.add_child(dl)
			var cost := co.track_cost(index, bid, tid)
			if cost.is_empty():
				row.add_child(UI.lbl("Fully upgraded", 17, "InkBold"))
				continue
			var ttid: String = tid
			var b := UI.btn("Upgrade (%s)" % Company.cost_text(cost), func():
				if co.upgrade_track(index, bid, ttid):
					Audio.play("hammer")
					Main.inst.toast("%s upgraded!" % t.name, "good")
					_changed(), "Good")
			var why := co.can_upgrade_track(index, bid, tid)
			b.disabled = why != ""
			b.tooltip_text = why
			row.add_child(b)
		if DB.buildings[bid].costs.size() <= 1:
			return
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


func _ruin(v: VBoxContainer) -> void:
	var co: Company = Game.company
	var b: Dictionary = DB.buildings[bid]
	var head := UI.hb(12)
	v.add_child(head)
	head.add_child(UI.hdr("Closed %s" % b.name, 34, true))
	head.add_child(UI.spacer(0, 0, true))
	head.add_child(UI.btn("Close", func(): Main.inst.close_modal(wrap), "Small"))
	v.add_child(UI.wrap(UI.lbl("Silas Crane's gang put this to the torch. It still holds its plot, but lumber and iron are scarce out here: side adventures and the trail are where you'll find them.", 19, "Ink"), 1180))
	v.add_child(UI.wrap(UI.lbl("Once rebuilt: " + b.desc, 19, "InkBold"), 1180))
	v.add_child(UI.spacer(0, 20))
	var row := UI.hb(12)
	v.add_child(row)
	var why := co.can_build(index, bid)
	row.add_child(UI.lbl("Rebuild: %s" % Company.cost_text(co.building_cost(index, bid)), 21, "InkBold"))
	var btn := UI.btn("Rebuild", func():
		if co.build(index, bid):
			Audio.play("hammer")
			Main.inst.toast("%s rebuilt!" % b.name, "good")
			_changed(), "Good")
	btn.disabled = why != ""
	btn.tooltip_text = why
	row.add_child(btn)
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
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(1190, 640)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var list := UI.vb(10)
	sc.add_child(list)
	var st := co.settlement(index)
	var ids: Array = DB.buildings.keys()
	ids.sort_custom(func(a, b): return DB.buildings[a].get("order", 0) < DB.buildings[b].get("order", 0))
	for id in ids:
		if st.buildings.has(id) or co.is_ruin(index, id):
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
		list.add_child(row)
