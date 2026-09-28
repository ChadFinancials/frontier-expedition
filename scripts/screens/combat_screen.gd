extends Control
## Turn-based battle. Drives CombatEngine and animates its events Darkest Dungeon style:
## the screen dims, attacker and target lunge toward the center, then everyone steps back.

signal chosen(kind: String, a: Variant, b: Variant)

const HERO_X := [790.0, 610.0, 430.0, 250.0]
const ENEMY_X := [1130.0, 1310.0, 1490.0, 1670.0]
const GROUND := 770.0

var run: RunState
var engine: CombatEngine
var params: Dictionary = {}
var kind: String = "fight"
var backdrop: Backdrop
var field: Node2D
var dim: ColorRect
var popups: Node2D
var views: Dictionary = {}       # combatant id -> UnitView
var hud_panel: PanelContainer
var hero_info: VBoxContainer
var skill_row: HBoxContainer
var action_row: HBoxContainer
var log_label: RichTextLabel
var order_label: RichTextLabel
var preview: PanelContainer
var preview_label: RichTextLabel
var banner: Label
var selected_skill: String = ""
var hover_id: int = -1
var awaiting := false
var speed := 1.0


func setup(p: Dictionary) -> void:
	params = p
	run = Game.company.run
	kind = p.get("kind", "fight")
	speed = float(Game.settings.get("combat_speed", 1.0))
	backdrop = Backdrop.new()
	backdrop.ground_y = GROUND
	if run != null and run.in_cave():
		backdrop.mode = "cave"
		backdrop.light = float(run.cave.light) / 100.0
	backdrop.setup(run.region_id if run != null else "tallgrass", backdrop.mode, 77)
	add_child(backdrop)
	field = Node2D.new()
	add_child(field)
	dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0)
	dim.size = Vector2(1920, 830)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.z_index = 5
	add_child(dim)
	popups = Node2D.new()
	popups.z_index = 30
	add_child(popups)
	_build_hud()
	engine = CombatEngine.new()
	var opts: Dictionary = run.combat_options(kind, p.get("surprise", "")) if run != null else {"rng": Game.company.rng}
	var ev := engine.setup(run.party_heroes() if run != null else [], p.get("enemies", []), opts)
	for c in engine.heroes + engine.enemies:
		_add_view(c)
	_layout(true)
	Audio.play_music("music_boss" if kind == "boss" else "music_combat")
	_start.call_deferred(ev)


func _start(ev: Array) -> void:
	await _play(ev)
	if kind == "boss":
		await _banner(DB.regions[run.region_id].boss.name, 1.4)
	_loop()


func _build_hud() -> void:
	order_label = UI.rich("", 19, false, 1400)
	order_label.position = Vector2(260, 12)
	order_label.z_index = 20
	add_child(order_label)
	banner = UI.hdr("", 52)
	banner.position = Vector2(0, 150)
	banner.size = Vector2(1920, 80)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.z_index = 40
	banner.modulate.a = 0
	add_child(banner)
	preview = UI.panel("Dark")
	preview.position = Vector2(1260, 60)
	preview.custom_minimum_size = Vector2(620, 0)
	preview.z_index = 25
	preview.visible = false
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(preview)
	preview_label = UI.rich("", 19, false, 590)
	preview.add_child(preview_label)
	hud_panel = UI.panel("Dark")
	hud_panel.position = Vector2(0, 835)
	hud_panel.custom_minimum_size = Vector2(1920, 245)
	hud_panel.z_index = 20
	add_child(hud_panel)
	var h := UI.hb(16)
	hud_panel.add_child(h)
	hero_info = UI.vb(4)
	hero_info.custom_minimum_size = Vector2(430, 220)
	h.add_child(hero_info)
	var mid := UI.vb(8)
	mid.custom_minimum_size.x = 960
	h.add_child(mid)
	skill_row = UI.hb(8)
	mid.add_child(skill_row)
	action_row = UI.hb(8)
	mid.add_child(action_row)
	log_label = UI.rich("", 16, false, 470)
	log_label.custom_minimum_size = Vector2(470, 220)
	log_label.fit_content = false
	log_label.scroll_active = true
	log_label.scroll_following = true
	h.add_child(log_label)


func _add_view(c: Combatant) -> void:
	var v := UnitView.new()
	v.setup(c)
	field.add_child(v)
	views[c.id] = v


func _rank_pos(c: Combatant) -> Vector2:
	var xs: Array = HERO_X if c.is_hero() else ENEMY_X
	return Vector2(xs[clampi(c.rank - 1, 0, 3)], GROUND)


func _layout(instant: bool = false) -> void:
	for id in views:
		var v: UnitView = views[id]
		var c: Combatant = v.unit
		if c.dead:
			continue
		var target := _rank_pos(c)
		if instant:
			v.position = target
		else:
			create_tween().tween_property(v, "position", target, 0.3 / speed).set_trans(Tween.TRANS_SINE)


func _log(t: String) -> void:
	log_label.append_text(t + "\n")


# --- Main loop ------------------------------------------------------------------------

func _loop() -> void:
	while not engine.is_over():
		var ev := engine.step()
		await _play(ev)
		if engine.awaiting_input():
			_show_controls()
			var choice: Array = await chosen
			_hide_controls()
			var ev2: Array = []
			match choice[0]:
				"skill":
					ev2 = engine.hero_skill(choice[1], choice[2])
				"swap":
					ev2 = engine.hero_swap(choice[1])
				"pass":
					ev2 = engine.hero_pass()
				"retreat":
					ev2 = engine.retreat()
			await _play(ev2)
	await _finish()


func _update_order() -> void:
	var parts: Array = []
	for c in engine.queue:
		if c.dead:
			continue
		parts.append(("[color=#9fd07a]%s[/color]" if c.is_hero() else "[color=#f0a080]%s[/color]") % c.display_name)
	var cur := ""
	if engine.current != null:
		cur = "[b][color=#e0bd4f]%s[/color][/b]  →  " % engine.current.display_name
	order_label.text = "[b]Round %d[/b]   %s%s" % [engine.round_num, cur, "  ·  ".join(parts)]


# --- Controls -------------------------------------------------------------------------

func _show_controls() -> void:
	awaiting = true
	selected_skill = ""
	var c: Combatant = engine.current
	for id in views:
		views[id].set_glow("")
	views[c.id].set_glow("active")
	_update_order()
	_fill_hero_info(c)
	UI.clear(skill_row)
	var i := 0
	for sid in c.skills:
		i += 1
		skill_row.add_child(_skill_button(c, sid, i))
	UI.clear(action_row)
	var back := UI.btn("<< Swap Back", func(): chosen.emit("swap", -1, null), "Small")
	back.disabled = c.rank >= engine.heroes.size()
	back.tooltip_text = "Trade places with the hero behind you. Uses your turn."
	action_row.add_child(back)
	var fwd := UI.btn("Swap Forward >>", func(): chosen.emit("swap", 1, null), "Small")
	fwd.disabled = c.rank <= 1
	fwd.tooltip_text = "Trade places with the hero in front of you. Uses your turn."
	action_row.add_child(fwd)
	action_row.add_child(UI.btn("Pass", func(): chosen.emit("pass", null, null), "Small"))
	var items := UI.btn("Use Supplies", _items_menu, "Small")
	items.tooltip_text = "Bandages, Antivenom, Whiskey... Using supplies doesn't cost your turn."
	action_row.add_child(items)
	var ret := UI.btn("Retreat", func():
		Main.inst.confirm("Retreat?", "Flee the fight. Everyone gains %d Fatigue and you get no loot." % DB.cfg("retreat_fatigue", 12), func(): chosen.emit("retreat", null, null), "Run!"), "Danger")
	ret.disabled = not engine.can_retreat()
	ret.tooltip_text = "You can't run from this fight." if not engine.can_retreat() else "Flee the fight."
	action_row.add_child(ret)
	# Auto-select the first usable skill so a click on an enemy just works.
	for sid in c.skills:
		if not engine.valid_targets(c, sid).is_empty() and engine.is_hostile(DB.skill(sid)):
			_select_skill(sid)
			break


func _skill_button(c: Combatant, sid: String, n: int) -> Control:
	var sk := DB.skill(sid)
	var b := Button.new()
	b.custom_minimum_size = Vector2(228, 86)
	b.theme_type_variation = "Tab"
	var v := UI.vb(2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.position = Vector2(10, 6)
	b.add_child(v)
	var nl := UI.lbl("%d. %s" % [n, sk.get("name", sid)], 19, "Bold")
	nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(nl)
	var dots := RankDots.for_skill(sid)
	v.add_child(dots)
	var usable := not engine.valid_targets(c, sid).is_empty()
	var tip := UI.skill_tooltip(sid, c.skill_level(sid))
	if not engine.can_use_from_rank(c, sid):
		tip += "\n[Can't use from rank %d]" % c.rank
	elif not usable:
		tip += "\n[No valid targets]"
	b.tooltip_text = tip
	b.disabled = not usable
	b.theme_type_variation = "" if usable else "Tab"
	if not usable:
		b.modulate = Color(1, 1, 1, 0.45)
	b.set_meta("sid", sid)
	b.pressed.connect(func():
		Audio.play("click", 0.5)
		var t: String = sk.get("target", "enemy")
		if t == "self" or t == "party":
			chosen.emit("skill", sid, c.id)
		else:
			_select_skill(sid))
	return b


func _select_skill(sid: String) -> void:
	selected_skill = sid
	var c: Combatant = engine.current
	var valid := engine.valid_targets(c, sid)
	var hostile := engine.is_hostile(DB.skill(sid))
	for id in views:
		var v: UnitView = views[id]
		if id == c.id:
			v.set_glow("active" if not id in valid else "ally")
		elif id in valid:
			v.set_glow("enemy" if hostile else "ally")
		else:
			v.set_glow("")
	for b in skill_row.get_children():
		var s: String = b.get_meta("sid", "")
		if not b.disabled:
			b.theme_type_variation = "Good" if s == sid else ""


func _fill_hero_info(c: Combatant) -> void:
	UI.clear(hero_info)
	var h := c.hero
	var row := UI.hb(10)
	hero_info.add_child(row)
	var fb := FigureBox.new()
	fb.custom_minimum_size = Vector2(90, 100)
	fb.focus_head = true
	fb.show_hero(h)
	row.add_child(fb)
	var v := UI.vb(2)
	row.add_child(v)
	v.add_child(UI.hdr(h.hero_name, 22))
	v.add_child(UI.lbl("Lv %d %s  |  Rank %d" % [h.level, h.class_name_text(), c.rank], 17))
	var hpb := UI.bar(c.hp, c.max_hp, UI.HP, 300, 16, true)
	hpb.text_override = "HP %d/%d" % [c.hp, c.max_hp]
	v.add_child(hpb)
	var fb2 := UI.bar(h.fatigue, 200, UI.FATIGUE, 300, 14, true)
	fb2.notch = 100
	fb2.text_override = "Fatigue %d/200" % h.fatigue
	v.add_child(fb2)
	var r := c.dmg_range()
	var m := 1.0 + c.stat("dmg_pct") / 100.0
	hero_info.add_child(UI.lbl("Dmg %d-%d  Crit %d%%  Dodge %d  Prot %d%%  Spd %d" % [int(r[0] * m), int(r[1] * m), int(c.stat("crit")), int(c.stat("dodge")), int(c.stat("prot")), int(c.stat("speed"))], 16))
	if h.fatigue_state != "":
		var st: Dictionary = DB.fatigue_states[h.fatigue_state]
		var l := UI.wrap(UI.lbl("%s: %s" % [st.name, st.desc], 15), 420)
		l.add_theme_color_override("font_color", Color(st.get("color", "#ffffff")))
		hero_info.add_child(l)


func _fill_enemy_info(c: Combatant) -> void:
	UI.clear(hero_info)
	UI.clear(skill_row)
	UI.clear(action_row)
	hero_info.add_child(UI.hdr(c.display_name, 24))
	if c.data.has("title"):
		hero_info.add_child(UI.lbl(str(c.data.title), 17))
	var hpb := UI.bar(c.hp, c.max_hp, UI.HP, 300, 16, true)
	hpb.text_override = "HP %d/%d" % [c.hp, c.max_hp]
	hero_info.add_child(hpb)
	hero_info.add_child(UI.lbl(", ".join(c.tags).capitalize(), 16))
	skill_row.add_child(UI.lbl("Enemy turn...", 22, "Bold"))


func _hide_controls() -> void:
	awaiting = false
	selected_skill = ""
	preview.visible = false
	UI.clear(skill_row)
	UI.clear(action_row)
	for id in views:
		views[id].set_glow("")


func _items_menu() -> void:
	var c: Combatant = engine.current
	var p := UI.panel()
	p.custom_minimum_size = Vector2(620, 0)
	var v := UI.vb(8)
	p.add_child(v)
	v.add_child(UI.hdr("Supplies (free action)", 28, true))
	var holder := {"wrap": null}
	var any := false
	for it in EmbarkOrder.ORDER:
		if not run.can_use_item(it) or it in ["lamp_oil", "wagon_parts"] and not (it == "lamp_oil" and run.in_cave()):
			continue
		any = true
		var item: String = it
		var b := UI.btn("%s ×%d: %s" % [DB.items[it].name, int(run.supplies[it]), DB.items[it].desc], func():
			Main.inst.close_modal(holder.wrap)
			if item == "lamp_oil":
				run.use_item(item, null)
				engine.light = int(run.cave.light)
				backdrop.light = engine.light / 100.0
				_log("Lamp oil: the light brightens.")
				return
			var heroes: Array = []
			for hc in engine.heroes:
				heroes.append(hc.hero)
			HeroPicker.pick(heroes, "Use %s on whom?" % DB.items[item].name, func(h: Hero):
				_use_item_on(item, h)), "")
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		v.add_child(b)
	if not any:
		v.add_child(UI.lbl("No usable supplies.", 20, "Ink"))
	v.add_child(UI.btn("Close", func(): Main.inst.close_modal(holder.wrap), "Small"))
	holder.wrap = Main.inst.modal(p)


func _use_item_on(item: String, h: Hero) -> void:
	var c: Combatant = null
	for hc in engine.heroes:
		if hc.hero == h:
			c = hc
	if c == null:
		return
	var msgs := run.use_item(item, h)
	c.hp = clampi(h.hp, 0, c.max_hp)
	if item == "bandages":
		c.dots = c.dots.filter(func(d): return d.kind != "bleed")
	if item == "antivenom":
		c.dots = c.dots.filter(func(d): return d.kind != "poison")
	for m in msgs:
		_log(m)
		_popup(c, m.get_slice(".", 0), Color("#9fd07a"), 20)
	Audio.play("heal")
	_fill_hero_info(engine.current)


# --- Mouse targeting -------------------------------------------------------------------

func _unit_under_mouse(p: Vector2) -> int:
	var best := -1
	for id in views:
		var v: UnitView = views[id]
		if v.unit.dead:
			continue
		if v.hit_rect().has_point(p):
			best = id
	return best


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var id := _unit_under_mouse(event.position)
		if id != hover_id:
			hover_id = id
			_update_preview()
	elif event is InputEventMouseButton and event.pressed:
		if Main.inst.has_modal():
			return
		if event.button_index == MOUSE_BUTTON_RIGHT and awaiting and selected_skill != "":
			selected_skill = ""
			for id in views:
				views[id].set_glow("active" if id == engine.current.id else "")
			return
		if event.button_index == MOUSE_BUTTON_LEFT and awaiting and selected_skill != "":
			var id2 := _unit_under_mouse(event.position)
			if id2 >= 0 and id2 in engine.valid_targets(engine.current, selected_skill):
				get_viewport().set_input_as_handled()
				chosen.emit("skill", selected_skill, id2)
	elif event is InputEventKey and event.pressed and not event.echo and awaiting:
		var k: int = event.keycode - KEY_1
		if k >= 0 and k < skill_row.get_child_count():
			var b: Button = skill_row.get_child(k)
			if not b.disabled:
				b.pressed.emit()


func _update_preview() -> void:
	if hover_id < 0 or not views.has(hover_id):
		preview.visible = false
		return
	var t: Combatant = views[hover_id].unit
	var lines: Array = []
	var title := t.display_name
	if t.hero == null and t.data.has("title"):
		title += ", " + str(t.data.title)
	lines.append("[b]%s[/b]  HP %d/%d%s" % [title, t.hp, t.max_hp, "  [color=#f0a080]DEATH'S DOOR[/color]" if t.deaths_door() else ""])
	if t.hero == null:
		lines.append("Dodge %d  Prot %d%%  Speed %d  |  Resist: Stun %d%% Bleed %d%% Poison %d%% Move %d%%" % [int(t.stat("dodge")), int(t.stat("prot")), int(t.stat("speed")),
			int(t.stat("stun_res")), int(t.stat("bleed_res")), int(t.stat("poison_res")), int(t.stat("move_res"))])
		lines.append("[i]%s[/i]" % ", ".join(t.tags))
	if awaiting and selected_skill != "" and hover_id in engine.valid_targets(engine.current, selected_skill):
		var a: Combatant = engine.current
		var sk := DB.skill(selected_skill)
		if engine.is_hostile(sk):
			var parts: Array = ["[color=#e0bd4f]%s[/color]:  Hit [b]%d%%[/b]" % [sk.name, engine.hit_chance(a, selected_skill, t)]]
			var dp := engine.dmg_preview(a, selected_skill, t)
			if not dp.is_empty():
				parts.append("Dmg [b]%d-%d[/b]" % [dp[0], dp[1]])
				parts.append("Crit [b]%d%%[/b]" % engine.crit_chance(a, selected_skill, t))
			for e in sk.get("effects", []):
				if e.type in ["stun", "bleed", "poison", "knockback", "pull", "debuff"]:
					parts.append("%s %d%%" % [e.type.capitalize(), engine.effect_chance(a, selected_skill, e, t)])
				elif e.type == "mark":
					parts.append("Mark")
			if sk.get("aoe", false):
				parts.append("(hits all highlighted)")
			lines.append("  ".join(parts))
		else:
			lines.append("[color=#9fd07a]%s[/color] on %s" % [sk.name, t.display_name])
	preview_label.text = "\n".join(lines)
	preview.visible = true


# --- Event playback -------------------------------------------------------------------

const PACE := 1.3


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec * PACE / speed).timeout


## A curved arrow from the actor to a target that fades away.
func _arrow(from: UnitView, to: UnitView, hostile: bool) -> void:
	var arr := _Arrow.new()
	arr.a = from.position + Vector2(0, from.top_local() * 0.6)
	arr.b = to.position + Vector2(0, to.top_local() * 0.6)
	arr.color = Color("#e05a4a") if hostile else Color("#7ee07a")
	arr.z_index = 32
	add_child(arr)
	var tw := create_tween()
	tw.tween_property(arr, "t", 1.0, 0.3 * PACE / speed)
	tw.tween_interval(0.4 * PACE / speed)
	tw.tween_property(arr, "modulate:a", 0.0, 0.3)
	tw.tween_callback(arr.queue_free)


## The target flinches away from the blow.
func _flinch(c: Combatant, strong: bool) -> void:
	if c == null or not views.has(c.id):
		return
	var f: Figure = views[c.id].figure
	var away := -1.0 if c.is_hero() else 1.0
	var tw := create_tween()
	tw.tween_property(f, "position:x", away * (38.0 if strong else 20.0), 0.07)
	tw.tween_property(f, "position:x", 0.0, 0.25 / speed).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


## A puff of dust or a shower of sparkles at a unit's feet.
func _burst(c: Combatant, color: Color, rising: bool) -> void:
	if c == null or not views.has(c.id):
		return
	var b := _Burst.new()
	b.position = views[c.id].position + Vector2(0, -10 if not rising else -80)
	b.color = color
	b.rising = rising
	b.z_index = 31
	add_child(b)


func _play(events: Array) -> void:
	var i := 0
	while i < events.size():
		var e: Dictionary = events[i]
		if e.t == "action":
			var group: Array = []
			var j := i + 1
			while j < events.size() and not events[j].t in ["action", "turn", "round", "end"]:
				group.append(events[j])
				j += 1
			await _animate_action(e, group)
			i = j
			continue
		await _play_one(e)
		i += 1
	_layout()


func _play_one(e: Dictionary) -> void:
	match e.t:
		"round":
			_update_order()
			_log("[b]— Round %d —[/b]" % e.round)
		"turn":
			_update_order()
			var c := engine.unit(e.actor)
			if c != null and views.has(e.actor):
				for id in views:
					views[id].set_glow("")
				views[e.actor].set_glow("active")
				if not c.is_hero():
					_fill_enemy_info(c)
					await _wait(0.35)
		"surprise":
			await _banner("Ambush!" if e.who == "heroes" else "Surprise Attack!", 1.1)
			_log("The heroes were caught off guard!" if e.who == "heroes" else "You caught them napping!")
		"stun_skip":
			var c2 := engine.unit(e.actor)
			_popup(c2, "Stunned!", Color("#e0bd4f"), 26)
			_log("%s is stunned and loses the turn." % c2.display_name)
			await _wait(0.6)
		"dot":
			var c3 := engine.unit(e.target)
			_popup(c3, str(e.amount), Color("#e05a4a") if e.kind == "bleed" else Color("#8fce5a"), 30)
			_flash(c3, Color("#e05a4a") if e.kind == "bleed" else Color("#8fce5a"))
			_log("%s takes %d %s damage." % [c3.display_name, e.amount, e.kind])
			await _wait(0.45)
		"act_out", "boon", "refuse":
			var c4 := engine.unit(e.get("actor", e.get("target", -1)))
			if c4 != null:
				_popup(c4, "!", Color("#e0bd4f"), 34)
			_log("[i]%s[/i]" % e.text)
			Main.inst.toast(e.text, "purple")
			await _wait(0.9)
		"end":
			pass
		_:
			_result(e)


func _result(e: Dictionary) -> void:
	match e.t:
		"hit":
			var t := engine.unit(e.target)
			if t == null:
				return
			if e.amount > 0:
				_popup(t, ("CRIT! " if e.crit else "") + str(e.amount) + (" " + e.note if e.note != "" else ""), Color("#ffe08a") if e.crit else Color("#ffffff"), 40 if e.crit else 32)
				_flash(t, Color(1, 0.3, 0.2))
				_flinch(t, e.crit)
				_burst(t, Color("#c9b48a"), false)
				if views.has(t.id):
					views[t.id].figure.set_pose("hurt")
				Audio.play("hit", 0.8)
				if e.crit:
					_shake(10)
					Audio.play("crit")
			if e.amount > 0:
				_log("%s hits %s for %d%s." % [engine.unit(e.actor).display_name if engine.unit(e.actor) else "?", t.display_name, e.amount, " (CRIT)" if e.crit else ""])
		"miss":
			var t2 := engine.unit(e.target)
			if t2 != null:
				_popup(t2, "Miss" if t2.hero == null else "Dodged!", Color("#bbbbbb"), 28)
				_flinch(t2, false)
				Audio.play("whoosh", 0.7)
				_log("%s misses %s." % [engine.unit(e.actor).display_name if engine.unit(e.actor) else "?", t2.display_name])
		"heal":
			var t3 := engine.unit(e.target)
			if t3 != null and e.amount > 0:
				_popup(t3, "+%d" % e.amount, Color("#7ee07a"), 32)
				_flash(t3, Color(0.4, 1, 0.4))
				_burst(t3, Color("#b9f5a0"), true)
				_log("%s heals %d." % [t3.display_name, e.amount])
		"status":
			var t4 := engine.unit(e.target)
			var names := {"bleed": "Bleeding", "poison": "Poisoned", "stun": "Stunned", "mark": "Marked", "guard": "Guarded", "taunt": "Taunting"}
			if t4 != null:
				_popup(t4, names.get(e.status, e.status), Color("#f0a080") if e.status in ["bleed", "poison", "stun", "mark"] else Color("#9fd07a"), 22, 40)
				_log("%s is %s." % [t4.display_name, names.get(e.status, e.status).to_lower()])
		"resist":
			var t5 := engine.unit(e.target)
			if t5 != null:
				_popup(t5, "Resisted", Color("#cccccc"), 22, 40)
				_log("%s resists the %s." % [t5.display_name, e.status])
		"buff", "debuff":
			var t6 := engine.unit(e.target)
			if t6 != null:
				var txt := Stats.mod_text({"stat": e.stat, "value": e.value})
				_popup(t6, txt, Color("#9fd07a") if Stats.mod_is_good({"stat": e.stat, "value": e.value}) else Color("#f0a080"), 20, 60)
		"cure":
			var t7 := engine.unit(e.target)
			if t7 != null:
				_popup(t7, "Cured", Color("#7ee07a"), 22, 40)
		"fatigue":
			var h := Game.company.hero(e.hero)
			var c := _combatant_for_hero(e.hero)
			if c != null and e.amount != 0:
				_popup(c, "%s%d Fatigue" % ["+" if e.amount > 0 else "", e.amount], Color("#c9a8ff") if e.amount > 0 else Color("#e8dcff"), 20, 80)
			if h != null:
				_log(Fatigue.describe(e, h.hero_name))
		"breaking", "second_wind":
			var h2 := Game.company.hero(e.hero)
			var st: Dictionary = DB.fatigue_states.get(e.state, {})
			if h2 != null:
				_banner_async("%s: %s!" % [h2.hero_name, st.get("name", "")], e.t == "breaking")
				Audio.play("breaking" if e.t == "breaking" else "fanfare")
				_log("[b]%s[/b]" % Fatigue.describe(e, h2.hero_name))
		"recovered":
			var h3 := Game.company.hero(e.hero)
			if h3 != null:
				_log(Fatigue.describe(e, h3.hero_name))
		"collapse":
			var h4 := Game.company.hero(e.hero)
			if h4 != null:
				_log("[b]%s[/b]" % Fatigue.describe(e, h4.hero_name))
				Audio.play("heartbeat")
		"deaths_door":
			var t8 := engine.unit(e.target)
			if t8 != null:
				_popup(t8, "DEATH'S DOOR", Color("#ff5a4a"), 30, 70)
				Audio.play("heartbeat")
				_log("[color=#f0a080][b]%s is at Death's Door![/b][/color]" % t8.display_name)
		"deathblow_resist":
			var t9 := engine.unit(e.target)
			if t9 != null:
				_popup(t9, "Deathblow resisted!", Color("#ffe08a"), 24, 90)
				_log("%s clings to life!" % t9.display_name)
		"revived":
			var t10 := engine.unit(e.target)
			if t10 != null:
				_log("%s is pulled back from Death's Door." % t10.display_name)
		"death":
			var t11 := engine.unit(e.target)
			if t11 != null and views.has(t11.id):
				var v: UnitView = views[t11.id]
				var tw := create_tween().set_parallel(true)
				tw.tween_property(v, "modulate:a", 0.0, 0.7 / speed)
				tw.tween_property(v, "rotation", -0.9 if t11.is_hero() else 0.9, 0.7 / speed)
				tw.tween_property(v, "position:y", v.position.y + 20, 0.7 / speed)
				views.erase(t11.id)
				tw.chain().tween_callback(v.queue_free)
				Audio.play("death_hero" if t11.is_hero() else "death")
				_log("[b]%s %s.[/b]" % [t11.display_name, "has died" if t11.is_hero() else "is defeated"])
		"moved":
			pass
		"positions":
			_layout()
		"summon":
			var nc := engine.unit(e.unit)
			if nc != null:
				_add_view(nc)
				views[nc.id].position = _rank_pos(nc) + Vector2(200, 0)
				views[nc.id].modulate.a = 0
				create_tween().tween_property(views[nc.id], "modulate:a", 1.0, 0.4)
				_log("%s joins the fight!" % nc.display_name)
				_layout()
		"light":
			backdrop.light = e.light / 100.0
			_log("The lamp flares brighter.")
		"retreat":
			_log("[b]The company retreats![/b]")
		"crit_relief":
			var ca := engine.unit(e.actor)
			if ca != null:
				_popup(ca, "Critical hit! Spirits lift", Color("#e8dcff"), 22, 110)
				_log("[color=#c9a8ff]%s's critical hit lifts the company's spirits: Fatigue drops.[/color]" % ca.display_name)
		"swap", "pass":
			var c5 := engine.unit(e.actor)
			if c5 != null and e.t == "pass":
				_log("%s waits." % c5.display_name)


func _combatant_for_hero(uid: int) -> Combatant:
	for c in engine.heroes:
		if c.hero != null and c.hero.uid == uid:
			return c
	return null


func _animate_action(e: Dictionary, group: Array) -> void:
	var a := engine.unit(e.actor)
	if a == null or not views.has(a.id):
		for g in group:
			_result(g)
		return
	var av: UnitView = views[a.id]
	var sk := DB.skill(e.skill)
	var anim: String = e.get("anim", "melee")
	var targets: Array = []
	for tid in e.targets:
		if views.has(tid) and tid != a.id:
			targets.append(views[tid])
	_log("[color=#e0bd4f]%s[/color] uses [b]%s[/b]." % [a.display_name, sk.get("name", e.skill)])
	# Telegraph: who is acting, on whom, before anything moves.
	var tnames: Array = []
	for v in targets:
		tnames.append(v.unit.display_name)
	var who := a.display_name
	if not tnames.is_empty():
		who += "  →  " + (", ".join(tnames) if tnames.size() <= 2 else "%d targets" % tnames.size())
	_banner_skill(sk.get("name", ""), a.is_hero(), who)
	av.set_glow("active")
	for v in targets:
		v.set_glow("enemy" if e.hostile else "ally")
		_arrow(av, v, e.hostile)
	await _wait(0.45)
	for v in [av] + targets:
		if is_instance_valid(v):
			v.set_glow("")
	# Dim and bring the actors forward.
	var focus: Array = [av] + targets
	for v in focus:
		v.z_index = 10
	var tw := create_tween().set_parallel(true)
	tw.tween_property(dim, "color:a", 0.55, 0.15 / speed)
	var dir := 1.0 if a.is_hero() else -1.0
	var a_to := av.position
	var big := Vector2(1.18, 1.18)
	# Darkest Dungeon-style staging: attacker and a single target meet at center stage.
	var close_in := anim in ["melee", "dog"]
	if e.hostile and not targets.is_empty():
		var t0: UnitView = targets[0]
		var gap := 150.0 + 40.0 * float(t0.figure.look.get("scale", 1.0)) + 20.0 * float(av.figure.look.get("scale", 1.0))
		if not close_in:
			gap += 220.0
		var center := 960.0
		a_to = Vector2(center - dir * gap / 2.0, GROUND)
		if targets.size() == 1:
			tw.tween_property(t0, "position", Vector2(center + dir * gap / 2.0, GROUND), 0.2 / speed)
	elif not e.hostile:
		if targets.size() == 1 and targets[0] != av:
			a_to = Vector2(820 if a.is_hero() else 1100, GROUND)
			tw.tween_property(targets[0], "position", Vector2(620 if a.is_hero() else 1300, GROUND), 0.2 / speed)
		else:
			a_to = av.position + Vector2(dir * 30, 0)
	tw.tween_property(av, "position", a_to, 0.2 / speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for v in focus:
		tw.tween_property(v, "scale", big, 0.2 / speed)
	await tw.finished
	# Pose and sound.
	match anim:
		"melee", "throw":
			av.figure.set_pose("windup")
			await _wait(0.12)
			av.figure.set_pose("strike")
		"shoot":
			av.figure.set_pose("aim")
			await _wait(0.1)
			av.figure.muzzle = 1.0
			create_tween().tween_property(av.figure, "muzzle", 0.0, 0.25 / speed)
		"dog":
			av.figure.set_pose("strike")
		_:
			av.figure.set_pose("cast")
	Audio.play(e.get("sfx", ""))
	if anim == "throw" and not targets.is_empty():
		_projectile(av.position + Vector2(0, -160), targets[0].position + Vector2(0, -120))
	await _wait(0.12)
	for g in group:
		_result(g)
	await _wait(1.0)
	# Step back.
	av.figure.set_pose("idle")
	for v in targets:
		if is_instance_valid(v):
			v.figure.set_pose("idle")
	var tw2 := create_tween().set_parallel(true)
	tw2.tween_property(dim, "color:a", 0.0, 0.2 / speed)
	for v in focus:
		if is_instance_valid(v):
			tw2.tween_property(v, "scale", Vector2.ONE, 0.2 / speed)
	await tw2.finished
	for v in focus:
		if is_instance_valid(v):
			v.z_index = 0
	_layout()
	await _wait(0.15)


func _projectile(from: Vector2, to: Vector2) -> void:
	var dot := _Spark.new()
	dot.position = from
	popups.add_child(dot)
	var tw := create_tween()
	tw.tween_property(dot, "position", to, 0.18 / speed)
	tw.tween_callback(dot.queue_free)


func _popup(c: Combatant, text: String, color: Color, size: int = 28, yoff: float = 0.0) -> void:
	if c == null or not views.has(c.id):
		return
	var v: UnitView = views[c.id]
	var l := UI.lbl(text, size, "Header")
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 8)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	var top := v.position + Vector2(0, v.top_local() * v.scale.y - 30 - yoff)
	l.position = top - Vector2(200, 0)
	l.size = Vector2(400, 60)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.z_index = 35
	add_child(l)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", top.y - 70, 1.1 / speed)
	tw.tween_property(l, "modulate:a", 0.0, 1.1 / speed).set_delay(0.5 / speed)
	tw.chain().tween_callback(l.queue_free)


func _flash(c: Combatant, color: Color) -> void:
	if c == null or not views.has(c.id):
		return
	var f: Figure = views[c.id].figure
	f.flash_color = color
	f.flash = 1.0
	create_tween().tween_property(f, "flash", 0.0, 0.35 / speed)


func _shake(amount: float) -> void:
	var tw := create_tween()
	for i in 6:
		tw.tween_property(field, "position", Vector2(randf_range(-amount, amount), randf_range(-amount, amount)), 0.03)
	tw.tween_property(field, "position", Vector2.ZERO, 0.05)


func _banner(text: String, dur: float) -> void:
	banner.text = text
	var tw := create_tween()
	tw.tween_property(banner, "modulate:a", 1.0, 0.2)
	tw.tween_interval(dur / speed)
	tw.tween_property(banner, "modulate:a", 0.0, 0.3)
	await tw.finished


func _banner_async(text: String, bad: bool) -> void:
	var l := UI.hdr(text, 46)
	l.add_theme_color_override("font_color", Color("#f0a080") if bad else Color("#9fd07a"))
	l.position = Vector2(0, 240)
	l.size = Vector2(1920, 70)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.z_index = 40
	add_child(l)
	var tw := create_tween()
	tw.tween_interval(1.6)
	tw.tween_property(l, "modulate:a", 0.0, 0.5)
	tw.tween_callback(l.queue_free)


func _banner_skill(text: String, hero: bool, sub: String = "") -> void:
	if sub != "":
		var sl := UI.lbl(sub, 24, "Bold")
		sl.position = Vector2(0, 148)
		sl.size = Vector2(1920, 34)
		sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sl.add_theme_constant_override("outline_size", 6)
		sl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		sl.z_index = 40
		add_child(sl)
		var tw0 := create_tween()
		tw0.tween_interval(1.5 * PACE / speed)
		tw0.tween_property(sl, "modulate:a", 0.0, 0.3)
		tw0.tween_callback(sl.queue_free)
	var l := UI.hdr(text, 40)
	l.add_theme_color_override("font_color", Color("#f1d38a") if hero else Color("#f0a080"))
	l.position = Vector2(0, 90)
	l.size = Vector2(1920, 60)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.z_index = 40
	add_child(l)
	var tw := create_tween()
	tw.tween_interval(1.5 * PACE / speed)
	tw.tween_property(l, "modulate:a", 0.0, 0.3)
	tw.tween_callback(l.queue_free)


# --- End of battle --------------------------------------------------------------------

func _finish() -> void:
	var state := engine.state
	var res: Dictionary = run.after_combat(engine, kind, params.get("reward", {}))
	if params.get("complete_node", false):
		run.complete_current()
	Game.save_game()
	match state:
		"victory":
			Audio.play("fanfare")
			await _banner("Victory!", 0.8)
		"defeat":
			Audio.play("breaking")
			await _banner("The Company Has Fallen", 1.5)
		"fled":
			await _banner("Retreat!", 0.8)
	var lines: Array = []
	if state == "victory":
		if int(res.money) > 0:
			lines.append("+%d chips" % res.money)
		if int(res.timber) > 0:
			lines.append("+%d Timber" % res.timber)
		if int(res.iron) > 0:
			lines.append("+%d Iron" % res.iron)
		if int(res.charters) > 0:
			lines.append("+%d Land Charter%s!" % [res.charters, "s" if res.charters > 1 else ""])
		for k in res.keepsakes:
			if k != "":
				lines.append("Keepsake: %s  (click a hero's card on the trail to equip it)" % DB.keepsakes[k].name)
	lines.append_array(res.msgs)
	var ret: String = params.get("return", "trail")
	if run.party_heroes().is_empty():
		var summary := Game.company.finish_run("defeat")
		Game.save_game()
		Main.inst.goto("results", {"summary": summary})
		return
	if state == "victory" and kind in ["boss", "crossing"]:
		var txt: String = DB.regions[run.region_id].boss.victory if kind == "boss" else "The way west is clear once more."
		Main.inst.dialog("Victory!", txt + "\n\n" + "\n".join(lines), [["Head Home", func():
			var summary2 := Game.company.finish_run("victory")
			Game.save_game()
			Main.inst.goto("results", {"summary": summary2}), "Good"]])
		return
	var title := {"victory": "Victory", "fled": "Escaped", "defeat": "Defeat"}.get(state, "")
	if lines.is_empty():
		lines.append("The dust settles.")
	Main.inst.dialog(title, "\n".join(lines), [["Continue", func(): Main.inst.goto(ret)]])


class _Spark extends Node2D:
	func _draw() -> void:
		draw_circle(Vector2.ZERO, 10, Color(1, 0.8, 0.3, 0.5))
		draw_circle(Vector2.ZERO, 5, Color(1, 1, 0.8))


class _Arrow extends Node2D:
	var a := Vector2.ZERO
	var b := Vector2.ZERO
	var color := Color.RED
	var t := 0.0:
		set(v):
			t = v
			queue_redraw()

	func _draw() -> void:
		var mid := (a + b) / 2.0 + Vector2(0, -90 - absf(b.x - a.x) * 0.08)
		var pts := PackedVector2Array()
		var n := 24
		for i in n + 1:
			var f := t * i / float(n)
			pts.append(a.lerp(mid, f).lerp(mid.lerp(b, f), f))
		if pts.size() < 2:
			return
		draw_polyline(pts, Color(0, 0, 0, 0.5), 9.0, true)
		draw_polyline(pts, color, 5.0, true)
		var tip := pts[pts.size() - 1]
		var dir := (tip - pts[pts.size() - 2]).normalized()
		var n2 := dir.orthogonal()
		draw_colored_polygon(PackedVector2Array([tip + dir * 16, tip - dir * 8 + n2 * 11, tip - dir * 8 - n2 * 11]), color)


class _Burst extends Node2D:
	var color := Color.WHITE
	var rising := false
	var life := 0.0
	var parts: Array = []

	func _ready() -> void:
		for i in 10:
			parts.append({"p": Vector2(randf_range(-30, 30), randf_range(-6, 6)), "v": Vector2(randf_range(-60, 60), randf_range(-140, -40) if rising else randf_range(-50, -10)), "r": randf_range(4, 10)})

	func _process(delta: float) -> void:
		life += delta
		for q in parts:
			q.p += q.v * delta
			q.v *= 0.94
		queue_redraw()
		if life > 0.8:
			queue_free()

	func _draw() -> void:
		var a := clampf(1.0 - life / 0.8, 0.0, 1.0)
		for q in parts:
			draw_circle(q.p, q.r * (0.6 + life), Color(color.r, color.g, color.b, a * 0.8))
