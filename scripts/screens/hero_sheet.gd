class_name HeroSheet
extends PanelContainer
## Full character sheet in a modal. Handles equipping skills and keepsakes, and, when
## the right building is here, training, gear and quirk treatment.

var hero: Hero
var index: int = -1       # settlement index, -1 when opened on the trail
var on_change: Callable
var wrap: Control


func setup(h: Hero, settlement_index: int, changed: Callable = Callable()) -> void:
	hero = h
	index = settlement_index
	on_change = changed
	custom_minimum_size = Vector2(1560, 880)
	_build()


func _changed() -> void:
	Game.save_game()
	if on_change.is_valid():
		on_change.call()
	UI.clear(self)
	_build()


func _build() -> void:
	var co: Company = Game.company
	var h := hero
	var root := UI.hb(22)
	add_child(root)
	# --- Left: portrait & vitals.
	var left := UI.vb(8)
	left.custom_minimum_size.x = 360
	root.add_child(left)
	var fb := FigureBox.new()
	fb.custom_minimum_size = Vector2(360, 380)
	fb.show_hero(h)
	left.add_child(fb)
	left.add_child(UI.hdr(h.hero_name, 28, true))
	left.add_child(UI.lbl("Level %d %s  (%s)" % [h.level, h.class_name_text(), h.cls().get("role", "")], 20, "InkBold"))
	var nxt := h.xp_for_next()
	var xpb := UI.bar(h.xp, nxt if nxt > 0 else h.xp, UI.GOLD, 340, 14, true)
	xpb.text_override = "XP %d / %d" % [h.xp, nxt] if nxt > 0 else "MAX LEVEL"
	left.add_child(xpb)
	var hpb := UI.bar(h.hp, h.max_hp(), UI.HP, 340, 18, true)
	hpb.text_override = "HP %d / %d" % [h.hp, h.max_hp()]
	left.add_child(hpb)
	var fb2 := UI.bar(h.fatigue, 200, UI.FATIGUE, 340, 18, true)
	fb2.notch = 100
	fb2.text_override = "Fatigue %d / 200" % h.fatigue
	left.add_child(fb2)
	if h.fatigue_state != "":
		var fs: Dictionary = DB.fatigue_states[h.fatigue_state]
		left.add_child(UI.rich("[b][color=%s]%s[/color][/b]: %s" % ["#a8392e" if fs.kind == "breaking" else "#3f6128", fs.name, fs.desc], 18, true, 340))
	left.add_child(UI.lbl("Status: " + h.status_text(), 18, "Ink"))
	# Gear.
	left.add_child(UI.lbl("Gear", 20, "InkBold"))
	for kind in ["weapon", "armor"]:
		var row := UI.hb(8)
		var tier: int = h.weapon_tier if kind == "weapon" else h.armor_tier
		var gl := UI.lbl("%s tier %d" % [kind.capitalize(), tier], 18, "Ink")
		gl.custom_minimum_size.x = 150
		gl.tooltip_text = "+%d%% damage per tier" % DB.cfg("weapon_dmg_pct", 12) if kind == "weapon" else "+%d%% max HP and +%d dodge per tier" % [DB.cfg("armor_hp_pct", 8), DB.cfg("armor_dodge", 2)]
		gl.mouse_filter = Control.MOUSE_FILTER_STOP
		row.add_child(gl)
		if index >= 0 and co.building_level(index, "smithy") > 0 and tier < DB.cfg("max_tier", 4):
			var why := co.can_upgrade_gear(index, h, kind)
			var cost := co.gear_cost(index, kind, tier + 1)
			var k: String = kind
			var b := UI.btn("Upgrade (%s)" % Company.cost_text(cost), func():
				if co.upgrade_gear(index, h, k):
					Audio.play("clang")
					_changed(), "Small")
			b.disabled = why != ""
			b.tooltip_text = why
			row.add_child(b)
		left.add_child(row)
	# --- Middle: combat skills.
	var mid := UI.vb(6)
	mid.custom_minimum_size.x = 640
	root.add_child(mid)
	mid.add_child(UI.hdr("Combat Skills  (%d/4 equipped, %d/%d learned)" % [h.equipped.size(), h.known.size(), h.cls().get("skills", []).size()], 24, true))
	mid.add_child(UI.lbl("Equip up to 4. Gold pips: ranks it's used from. Red: ranks it reaches.", 16, "Ink"))
	for sid in h.cls().get("skills", []):
		mid.add_child(_skill_row(sid))
	mid.add_child(UI.lbl("Preferred ranks: %s" % ", ".join(h.cls().get("ranks", []).map(func(x): return str(x))), 18, "Ink"))
	mid.add_child(UI.wrap(UI.lbl(h.cls().get("desc", ""), 17, "Ink"), 620))
	# --- Right: stats, survival, quirks, keepsakes.
	var right := UI.vb(6)
	right.custom_minimum_size.x = 480
	root.add_child(right)
	right.add_child(UI.hdr("Stats", 24, true))
	var d := h.dmg_range()
	var mult := 1.0 + h.stat("dmg_pct") / 100.0
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 18)
	right.add_child(grid)
	var stat_rows := [["Max HP", str(h.max_hp())], ["Damage", "%d-%d" % [int(d[0] * mult), int(d[1] * mult)]],
		["Speed", str(int(h.stat("speed")))], ["Dodge", str(int(h.stat("dodge")))],
		["Protection", "%d%%" % int(h.stat("prot"))], ["Accuracy", "+%d" % int(h.stat("acc"))],
		["Crit", "%d%%" % int(h.stat("crit"))], ["Cheat Death", "%d%%" % int(h.stat("deathblow"))],
		["Stun Res", "%d%%" % int(h.stat("stun_res"))], ["Bleed Res", "%d%%" % int(h.stat("bleed_res"))],
		["Poison Res", "%d%%" % int(h.stat("poison_res"))], ["Move Res", "%d%%" % int(h.stat("move_res"))]]
	for sr in stat_rows:
		grid.add_child(UI.lbl(sr[0], 17, "Ink"))
		grid.add_child(UI.lbl(sr[1], 17, "InkBold"))
	right.add_child(UI.hdr("Survival Skills", 22, true))
	var srow := UI.hb(8)
	right.add_child(srow)
	for sid in h.survival:
		var rank := int(h.survival[sid].rank)
		var c := UI.chip("%s  %s" % [DB.survival[sid].name, "★".repeat(rank)], "blue", 18)
		c.tooltip_text = UI.survival_tooltip(sid, rank) + "\nUses toward next rank: %d" % int(h.survival[sid].xp)
		c.mouse_filter = Control.MOUSE_FILTER_STOP
		srow.add_child(c)
	right.add_child(UI.hdr("Quirks", 22, true))
	var qflow := HFlowContainer.new()
	qflow.custom_minimum_size.x = 470
	right.add_child(qflow)
	var doc_here := index >= 0 and co.building_level(index, "doctor") > 0
	for q in h.quirks:
		var pos: bool = DB.quirks[q].positive
		var chip := UI.chip(DB.quirks[q].name, "good" if pos else "bad", 17)
		chip.tooltip_text = UI.quirk_tooltip(q)
		chip.mouse_filter = Control.MOUSE_FILTER_STOP
		qflow.add_child(chip)
		if not pos and doc_here:
			var qq: String = q
			var tb := UI.btn("Treat (%d chips)" % co.doctor_cost(index, h), func():
				if co.treat_quirk(index, h, qq):
					Audio.play("heal")
					_changed(), "Small")
			var why := co.can_treat_quirk(index, h, q)
			tb.disabled = why != ""
			tb.tooltip_text = why if why != "" else "The Doctor removes this quirk. The hero sits out the next expedition."
			qflow.add_child(tb)
	right.add_child(UI.hdr("Trinkets", 22, true))
	var krow := UI.vb(4)
	right.add_child(krow)
	for k in h.keepsakes:
		var row := UI.hb(8)
		var kc := UI.chip(DB.keepsakes[k].name, "gold", 17)
		kc.tooltip_text = UI.keepsake_tooltip(k)
		kc.mouse_filter = Control.MOUSE_FILTER_STOP
		row.add_child(kc)
		var kk: String = k
		row.add_child(UI.btn("Unequip", func():
			_unequip(kk)
			_changed(), "Small"))
		krow.add_child(row)
	var pool := _pool()
	if h.keepsakes.size() < 2 and not pool.is_empty():
		var where := "found this trip" if _on_trail() else "in stash"
		var eq := UI.btn("Equip a trinket (%d %s)" % [pool.size(), where], _pick_keepsake, "Good")
		krow.add_child(eq)
	elif h.keepsakes.is_empty():
		krow.add_child(UI.lbl("None. Trinkets turn up on the trail, and the General Store sells a few.", 16, "Ink"))
	if _on_trail() and not co.stash.is_empty():
		krow.add_child(UI.lbl("(%d more trinkets wait in the stash back in town.)" % co.stash.size(), 15, "Ink"))
	right.add_child(UI.lbl("Expeditions: %d   Kills: %d" % [h.expeditions, h.kills], 17, "Ink"))
	var brow := UI.hb(10)
	right.add_child(brow)
	brow.add_child(UI.btn("Close", func(): Main.inst.close_modal(wrap), ""))
	if index >= 0 and co.run == null:
		brow.add_child(UI.btn("Dismiss", func():
			Main.inst.confirm("Dismiss %s?" % h.hero_name, "They'll leave the company for good. Their trinkets go to the stash.", func():
				co.dismiss(h)
				Game.save_game()
				Main.inst.close_modal(wrap)
				if on_change.is_valid():
					on_change.call(), "Dismiss"), "Danger"))


func _skill_row(sid: String) -> Control:
	var co: Company = Game.company
	var h := hero
	var sk := DB.skill(sid)
	var equipped := sid in h.equipped
	var learned := h.knows(sid)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.box(Color("#f1d38a") if equipped else UI.PAPER_DARK, UI.GOLD if equipped else UI.WOOD, 2, 6, 8, 0))
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.tooltip_text = UI.skill_tooltip(sid, h.skill_level(sid)) + ("" if learned else "\n\nNot learned yet: teach it at a Drill Hall.")
	if not learned:
		p.modulate = Color(1, 1, 1, 0.5)
	var row := UI.hb(10)
	p.add_child(row)
	var name_l := UI.lbl(("✔ " if equipped else "   ") + sk.get("name", sid) + ("" if learned else " (unlearned)"), 19, "InkBold")
	name_l.custom_minimum_size.x = 230
	row.add_child(name_l)
	row.add_child(RankDots.for_skill(sid))
	var lv := UI.lbl("Lv %d" % h.skill_level(sid) if learned else "", 17, "Ink")
	lv.custom_minimum_size.x = 44
	row.add_child(lv)
	var can_edit := co.run == null or index >= 0
	p.gui_input.connect(func(ev):
		if can_edit and ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			if not learned:
				Main.inst.toast("%s hasn't learned %s yet. Teach it at a Drill Hall." % [h.hero_name, sk.get("name", sid)])
				return
			if sid in h.equipped:
				if h.equipped.size() > 1:
					h.equipped.erase(sid)
			elif h.equipped.size() < 4:
				h.equipped.append(sid)
			else:
				Main.inst.toast("Only 4 skills can be equipped. Unequip one first.")
				return
			Audio.play("click", 0.5)
			_changed())
	if index >= 0 and learned and co.building_level(index, "drill_hall") > 0 and h.skill_level(sid) < DB.cfg("max_skill_level", 5):
		var nl := h.skill_level(sid) + 1
		var why := co.can_upgrade_skill(index, h, sid)
		var b := UI.btn("Train (%d chips)" % co.skill_cost(index, nl), func():
			if co.upgrade_skill(index, h, sid):
				Audio.play("buff")
				_changed(), "Small")
		b.disabled = why != ""
		b.tooltip_text = why if why != "" else "Drill Hall: raise to level %d (+accuracy, damage, effect chance)" % nl
		row.add_child(b)
	return p


func _on_trail() -> bool:
	return index < 0 and Game.company.run != null


## Keepsakes this hero can equip right now: the town stash, or finds from this trip.
func _pool() -> Array:
	return Game.company.run.loot.keepsakes.filter(func(k): return k != "") if _on_trail() else Game.company.stash


func _equip(k: String) -> void:
	if hero.keepsakes.size() >= 2 or Game.company.keepsake_block(hero, k) != "":
		return
	if _on_trail():
		Game.company.run.loot.keepsakes.erase(k)
		hero.keepsakes.append(k)
	else:
		Game.company.equip_keepsake(hero, k)
	Audio.play("badge")


func _unequip(k: String) -> void:
	if _on_trail():
		hero.keepsakes.erase(k)
		Game.company.run.loot.keepsakes.append(k)
	else:
		Game.company.unequip_keepsake(hero, k)


func _pick_keepsake() -> void:
	var co: Company = Game.company
	var p := UI.panel()
	p.custom_minimum_size = Vector2(620, 0)
	var v := UI.vb(8)
	p.add_child(v)
	v.add_child(UI.hdr("Trinkets Found This Trip" if _on_trail() else "Trinket Stash", 28, true))
	var holder := {"wrap": null}
	for k in _pool():
		var row := UI.hb(10)
		var l := UI.lbl(DB.keepsakes[k].name, 20, "InkBold")
		l.custom_minimum_size.x = 260
		row.add_child(l)
		var fx := UI.wrap(UI.lbl(", ".join(UI.keepsake_effects(k)), 16, "Ink"), 300)
		row.add_child(fx)
		var kk: String = k
		var eb := UI.btn("Equip", func():
			_equip(kk)
			Main.inst.close_modal(holder.wrap)
			_changed(), "Small")
		var why := co.keepsake_block(hero, k)
		eb.disabled = why != ""
		if why != "":
			eb.tooltip_text = "Only a %s can wear this." % why.trim_suffix(" only")
		row.add_child(eb)
		v.add_child(row)
	v.add_child(UI.btn("Cancel", func(): Main.inst.close_modal(holder.wrap)))
	holder.wrap = Main.inst.modal(p)
