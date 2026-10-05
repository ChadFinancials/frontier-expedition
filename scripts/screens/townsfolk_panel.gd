class_name TownsfolkPanel
extends PanelContainer
## Modal roster of a settlement's townsfolk: who lives here, what they do, what they cost,
## and the controls to put them to work, take them off a job, or send them away.

var index: int = 0
var on_change: Callable
var wrap: Control


func setup(settlement_index: int, changed: Callable = Callable()) -> void:
	index = settlement_index
	on_change = changed
	custom_minimum_size = Vector2(1240, 820)
	_build()


func _changed() -> void:
	Game.save_game()
	if on_change.is_valid():
		on_change.call()
	UI.clear(self)
	_build()


func _build() -> void:
	var co: Company = Game.company
	var v := UI.vb(10)
	add_child(v)
	var head := UI.hb(12)
	v.add_child(head)
	head.add_child(UI.hdr("Townsfolk of %s" % co.settlement_name(index), 34, true))
	head.add_child(UI.spacer(0, 0, true))
	head.add_child(UI.btn("Close", func(): Main.inst.close_modal(wrap), "Small"))
	var st := co.settlement(index)
	var tier := co.tier_info(st.tier)
	var lines: Array = ["Living here: [b]%d of %d[/b]" % [co.population(index), co.housing(index)]]
	var wages := 0
	for p in co.townsfolk_at(index):
		wages += Townsfolk.wage(p)
	lines.append("Wages: [b]%d chips a week[/b]" % wages)
	var nt := co.next_tier(st.tier)
	if not nt.is_empty() and int(nt.get("population", 0)) > 0:
		lines.append("Growing to a %s takes %d townsfolk living here." % [nt.name, int(nt.population)])
	v.add_child(UI.rich("\n".join(lines), 19, true, 1180))
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(1190, 600)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var list := UI.vb(10)
	sc.add_child(list)
	var folk := co.townsfolk_at(index)
	if folk.is_empty():
		list.add_child(UI.wrap(UI.lbl("Nobody has settled here yet. On expeditions and side quests you'll meet folk looking for a town to call home; they arrive when the company comes back. Buildings open staff seats at level 2.", 20, "Ink"), 1150))
		return
	for p in folk:
		var row := UI.hb(12)
		list.add_child(row)
		row.add_child(TownsfolkCard.make(p))
		var info := UI.vb(6)
		row.add_child(info)
		var lvl := int(p.level)
		var need: Array = DB.townsfolk.get("level_xp", [8, 24])
		if lvl < Townsfolk.max_level(p):
			info.add_child(UI.lbl("Learning: %d / %d toward %s" % [int(p.xp), int(need[lvl - 1]), Townsfolk.level_name(lvl + 1)], 16, "Ink"))
		else:
			info.add_child(UI.lbl("Learned all they will." if lvl < 3 else "A Master of the trade.", 16, "Ink"))
		var own := str(Townsfolk.trade(p).get("building", ""))
		if own != "":
			info.add_child(UI.lbl("Belongs at the %s%s" % [DB.buildings[own].name, "" if co.building_level(index, own) > 0 else " (not built here)"], 16, "Ink"))
		var btns := UI.hb(8)
		info.add_child(btns)
		btns.add_child(UI.btn("Put to Work", func(): _assign(p), "Good"))
		if str(p.post) != "":
			btns.add_child(UI.btn("Take off the Job", func():
				co.unpost_townsperson(p)
				_changed(), "Small"))
		btns.add_child(UI.btn("Send Away", func():
			Main.inst.confirm("Send %s Away?" % p.name, "%s packs up and leaves %s for good." % [p.name, co.settlement_name(index)], func():
				co.townsfolk.erase(p)
				_changed(), "Send Away"), "Small"))


## Choose a building with a free staff seat. The one that suits their trade is marked ★.
func _assign(p: Dictionary) -> void:
	var co: Company = Game.company
	var box := UI.panel()
	box.custom_minimum_size = Vector2(640, 0)
	var v := UI.vb(8)
	box.add_child(v)
	v.add_child(UI.hdr("Where does %s work?" % p.name, 28, true))
	var holder := {"wrap": null}
	var ids: Array = co.settlement(index).get("buildings", {}).keys()
	ids.sort_custom(func(a, b): return DB.buildings[a].get("order", 0) < DB.buildings[b].get("order", 0))
	var any := false
	for bid in ids:
		if co.staff_seats_max(bid) <= 0:
			continue
		any = true
		var why := co.can_post(p, bid)
		var fits := Townsfolk.fits(p, bid)
		var label := "%s%s: %s  (%d / %d seats)" % ["★ " if fits else "", DB.buildings[bid].name, Townsfolk.value_text(bid, Townsfolk.value_in(p, bid)), co.staff_at(index, bid).size(), co.staff_seats(index, bid)]
		var b := UI.btn(label, func():
			Main.inst.close_modal(holder.wrap)
			if co.post_townsperson(p, bid):
				Audio.play("coin")
				Main.inst.toast("%s goes to work at the %s." % [p.name, DB.buildings[bid].name], "good")
				_changed(), "Good" if fits else "", 600)
		b.disabled = why != ""
		b.tooltip_text = why
		v.add_child(b)
	if not any:
		v.add_child(UI.wrap(UI.lbl("No building here has staff seats yet. Seats open at level 2.", 18, "Ink"), 600))
	v.add_child(UI.btn("Cancel", func(): Main.inst.close_modal(holder.wrap), "Small"))
	holder.wrap = Main.inst.modal(box, true)
