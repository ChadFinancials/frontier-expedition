extends Control
## Plan an expedition: pick up to four heroes, arrange the formation, buy supplies.

const ITEM_ORDER := ["food", "bandages", "antivenom", "whiskey", "lamp_oil", "wagon_parts", "rope", "shovel", "crowbar", "salt"]
const RECOMMENDED := {"food": 18, "bandages": 2, "antivenom": 1, "whiskey": 1, "lamp_oil": 2, "wagon_parts": 1, "rope": 1, "shovel": 1, "crowbar": 1, "salt": 1}

var index: int = 0
var party: Array = []          # uids, index 0 = rank 1
var supplies: Dictionary = {}
var top: TopBar
var roster_grid: GridContainer
var stage: Control
var stage_row: HBoxContainer
var supply_box: VBoxContainer
var total_label: Label
var depart_btn: Button
var warn_label: Label


func setup(params: Dictionary) -> void:
	index = int(params.get("index", 0))
	var co: Company = Game.company
	var site := co.site_by_index(index)
	var region_id := co.expedition_region(index)
	var region: Dictionary = DB.regions.get(region_id, {})
	var bd := Backdrop.new()
	bd.ground_y = 1000
	bd.setup(region_id, "trail", 9)
	add_child(bd)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.35)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	top = TopBar.new()
	add_child(top)
	top.set_title("Plan Expedition", "From %s into %s" % [site.name, region.get("name", "?")])
	top.refresh()
	# Roster.
	var rp := UI.panel()
	rp.position = Vector2(20, 90)
	rp.size = Vector2(880, 830)
	rp.custom_minimum_size = Vector2(880, 830)
	add_child(rp)
	var rv := UI.vb(8)
	rp.add_child(rv)
	rv.add_child(UI.hdr("Choose Your Party", 28, true))
	rv.add_child(UI.lbl("Click heroes to add or remove them (up to 4). Tired, busy or travelling heroes can't go.", 18, "Ink"))
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(850, 700)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rv.add_child(sc)
	roster_grid = GridContainer.new()
	roster_grid.columns = 2
	roster_grid.add_theme_constant_override("h_separation", 10)
	roster_grid.add_theme_constant_override("v_separation", 8)
	sc.add_child(roster_grid)
	# Formation stage.
	var sp := UI.panel("Dark")
	sp.position = Vector2(920, 90)
	sp.custom_minimum_size = Vector2(980, 400)
	add_child(sp)
	var sv := UI.vb(6)
	sp.add_child(sv)
	var sh := UI.hb(10)
	sv.add_child(sh)
	sh.add_child(UI.hdr("Formation", 26))
	sh.add_child(UI.lbl("Rank 4 (back)  ←  →  Rank 1 (front). Enemies will be on the right.", 18))
	stage_row = UI.hb(6)
	stage_row.custom_minimum_size = Vector2(950, 320)
	sv.add_child(stage_row)
	# Supplies.
	var sup := UI.panel()
	sup.position = Vector2(920, 505)
	sup.custom_minimum_size = Vector2(980, 415)
	add_child(sup)
	var supv := UI.vb(4)
	sup.add_child(supv)
	var suph := UI.hb(10)
	supv.add_child(suph)
	suph.add_child(UI.hdr("Supplies", 26, true))
	suph.add_child(UI.spacer(0, 0, true))
	suph.add_child(UI.btn("Recommended", func():
		supplies = _affordable(RECOMMENDED)
		_refresh_supplies(), "Small"))
	suph.add_child(UI.btn("Clear", func():
		supplies = {}
		_refresh_supplies(), "Small"))
	supply_box = UI.vb(2)
	supv.add_child(supply_box)
	# Footer.
	var fp := UI.panel("Dark")
	fp.position = Vector2(0, 935)
	fp.custom_minimum_size = Vector2(1920, 145)
	add_child(fp)
	var fh := UI.hb(20)
	fp.add_child(fh)
	var back := UI.btn("<  Back", func(): Main.inst.goto("settlement", {"index": index}), "", 160)
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fh.add_child(back)
	var info := UI.rich("[b]%s[/b]  (recommended level %s)\n%s" % [region.get("name", ""), region.get("rec_level", "?"), region.get("desc", "")], 19, false, 1000)
	fh.add_child(info)
	var fv := UI.vb(4)
	fh.add_child(fv)
	total_label = UI.lbl("", 22, "Bold")
	fv.add_child(total_label)
	warn_label = UI.lbl("", 17)
	warn_label.add_theme_color_override("font_color", Color("#f0a080"))
	fv.add_child(warn_label)
	depart_btn = UI.btn("Hit the Trail!", _depart, "Big", 300)
	depart_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fh.add_child(depart_btn)
	supplies = _affordable(RECOMMENDED)
	# Default party: the four healthiest ready heroes, in a sensible order.
	var avail := co.heroes_at(index).filter(func(h): return h.available())
	avail.sort_custom(func(a, b): return a.fatigue < b.fatigue)
	var pick := avail.slice(0, 4)
	pick.sort_custom(func(a, b): return a.cls().get("ranks", [2]).min() < b.cls().get("ranks", [2]).min())
	for h in pick:
		party.append(h.uid)
	_refresh()


func _refresh() -> void:
	var co: Company = Game.company
	UI.clear(roster_grid)
	var heroes := co.heroes_at(index)
	heroes.sort_custom(func(a, b): return int(a.available()) > int(b.available()) if a.available() != b.available() else a.level > b.level)
	for h in heroes:
		var card := HeroCard.make(h)
		card.custom_minimum_size.x = 410
		card.selected = h.uid in party
		card.dimmed = not h.available()
		card.clicked.connect(func(_c): _toggle(h))
		roster_grid.add_child(card)
	# Stage: rank 4 on the left, rank 1 on the right.
	UI.clear(stage_row)
	for slot in [3, 2, 1, 0]:
		var col := UI.vb(2)
		col.custom_minimum_size = Vector2(232, 320)
		stage_row.add_child(col)
		col.add_child(UI.lbl("Rank %d" % (slot + 1), 18, "Bold"))
		if slot < party.size():
			var h: Hero = co.hero(party[slot])
			var fb := FigureBox.new()
			fb.custom_minimum_size = Vector2(220, 200)
			fb.frame_color = Color(0.25, 0.18, 0.12)
			fb.show_hero(h)
			fb.tooltip_text = "Click to remove"
			fb.gui_input.connect(func(ev):
				if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
					_toggle(h))
			col.add_child(fb)
			var nl := UI.lbl(h.hero_name, 17, "Bold")
			nl.clip_text = true
			nl.custom_minimum_size.x = 220
			col.add_child(nl)
			var pref: Array = h.cls().get("ranks", [])
			var ok: bool = (slot + 1) in pref
			var pl := UI.lbl("%s  (prefers %s)" % [h.class_name_text(), ",".join(pref.map(func(x): return str(x)))], 15)
			pl.add_theme_color_override("font_color", Color("#9fd07a") if ok else Color("#f0a080"))
			col.add_child(pl)
			var arrows := UI.hb(4)
			var s: int = slot
			if slot < party.size() - 1:
				arrows.add_child(UI.btn("< Back", func(): _swap(s, s + 1), "Small"))
			if slot > 0:
				arrows.add_child(UI.btn("Front >", func(): _swap(s, s - 1), "Small"))
			col.add_child(arrows)
		else:
			var empty := Panel.new()
			empty.custom_minimum_size = Vector2(220, 200)
			empty.add_theme_stylebox_override("panel", UI.box(Color(0, 0, 0, 0.25), UI.WOOD_LIGHT, 2, 6))
			col.add_child(empty)
			col.add_child(UI.lbl("(empty)", 16))
	_refresh_supplies()


func _toggle(h: Hero) -> void:
	if h.uid in party:
		party.erase(h.uid)
	elif not h.available():
		Main.inst.toast("%s can't go: %s" % [h.hero_name, h.status_text()], "bad")
		return
	elif party.size() >= 4:
		Main.inst.toast("The wagon only fits four.", "bad")
		return
	else:
		party.append(h.uid)
	_refresh()


func _swap(a: int, b: int) -> void:
	var t = party[a]
	party[a] = party[b]
	party[b] = t
	Audio.play("click", 0.5)
	_refresh()


func _refresh_supplies() -> void:
	var co: Company = Game.company
	UI.clear(supply_box)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 30)
	supply_box.add_child(grid)
	for it in ITEM_ORDER:
		var d: Dictionary = DB.items[it]
		var row := UI.hb(6)
		var nl := UI.lbl(d.name, 19, "InkBold")
		nl.custom_minimum_size.x = 130
		nl.tooltip_text = d.desc
		nl.mouse_filter = Control.MOUSE_FILTER_STOP
		row.add_child(nl)
		var price := co.item_price(index, it)
		row.add_child(UI.lbl("%d" % price, 17, "Ink"))
		var n := int(supplies.get(it, 0))
		var step := 4 if it == "food" else 1
		var item: String = it
		row.add_child(UI.btn("-", func():
			supplies[item] = maxi(0, int(supplies.get(item, 0)) - step)
			_refresh_supplies(), "Small"))
		var cl := UI.lbl(str(n), 20, "InkBold")
		cl.custom_minimum_size.x = 34
		cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(cl)
		row.add_child(UI.btn("+", func():
			supplies[item] = mini(int(d.stack), int(supplies.get(item, 0)) + step)
			_refresh_supplies(), "Small"))
		grid.add_child(row)
	var cost := co.supply_cost(index, supplies)
	var food := int(supplies.get("food", 0))
	supply_box.add_child(UI.lbl("Food lasts about %d stops for this party (a trail is 8 stops plus camp meals)." % int(food / maxf(1.0, ceil(2.0 * party.size() / 4.0))), 17, "Ink"))
	total_label.text = "Supplies: %d chips   (you have %d)" % [cost, co.money]
	var why := co.can_embark(index, party, supplies)
	warn_label.text = why
	if why == "" and party.size() < 4:
		warn_label.text = "Going with fewer than four heroes is risky."
	elif why == "" and food < 12:
		warn_label.text = "That's not much food..."
	depart_btn.disabled = why != ""


## The recommended load, trimmed (extras first, then food) to what the company can pay for.
func _affordable(want: Dictionary) -> Dictionary:
	var co: Company = Game.company
	var out := want.duplicate()
	for k in ["crowbar", "shovel", "rope", "salt", "whiskey", "antivenom", "lamp_oil", "wagon_parts", "bandages"]:
		if co.supply_cost(index, out) <= co.money:
			break
		out.erase(k)
	while co.supply_cost(index, out) > co.money and int(out.get("food", 0)) > 0:
		out.food = maxi(0, int(out.food) - 2)
	return out


func _depart() -> void:
	var co: Company = Game.company
	var clean := {}
	for k in supplies:
		if int(supplies[k]) > 0:
			clean[k] = int(supplies[k])
	var r := co.start_run(index, party, clean)
	if r == null:
		Main.inst.message("Can't Depart", co.can_embark(index, party, clean))
		return
	Game.save_game()
	Audio.play("whip")
	Main.inst.goto("trail")
