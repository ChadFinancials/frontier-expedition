extends Control
## The expedition map: pick the next stop, travel with the wagon, and resolve what's there.

var run: RunState
var backdrop: Backdrop
var wagon: WagonArt
var walkers: Array = []
var caravan: Node   # paper group holding the wagon and walkers
var map: MapView
var hud_row: HBoxContainer
var party_row: HBoxContainer
var item_row: VBoxContainer
var log_label: RichTextLabel
var scroll := 0.0
var travelling := false
var wagon_bar: StatBar
var _walk_t := 0.0
## Road news (scouting, food, wagon wear) from arriving at a stop that opens another screen
## (a fight, camp, a cave). Held until the map is back, so there is time to read it.
static var pending_notes: Array = []


func setup(_params: Dictionary) -> void:
	run = Game.company.run
	if run == null:
		Main.inst.goto("settlement", {"index": 0}, true)
		return
	backdrop = Backdrop.new()
	backdrop.ground_y = 400
	backdrop.setup(run.region_id, "trail", 30 + run.day)
	# Ground under the wagon: the map panel starts at y=430, so the horizon sits at 300.
	backdrop.set_bg_horizon(300.0)
	add_child(backdrop)
	var clip := Control.new()
	add_child(clip)
	wagon = WagonArt.new()
	wagon.position = Vector2(960, 404)
	wagon.scale = Vector2(0.7, 0.7)
	wagon.damaged = run.wagon < 40
	caravan = PaperFX.stage(self)
	caravan.add_child(wagon)
	_make_walkers()
	wagon_bar = UI.bar(run.wagon, DB.cfg("wagon_max", 100), Color("#d9a441"), 190, 18, true)
	wagon_bar.position = Vector2(865, 180)
	wagon_bar.tooltip_text = "Wagon condition. The trail wears it down a little every stop; events and some enemies damage it. Wagon Parts or a Wheelwright repair it. At 0 every stop adds Fatigue."
	add_child(wagon_bar)
	# HUD strip.
	var hp := UI.panel("DarkRopeBottom")
	hp.custom_minimum_size = Vector2(1920, 64)
	add_child(hp)
	hud_row = UI.hb(30)
	hp.add_child(hud_row)
	# Map.
	# The map sheet is nailed to a board (MapView draws the parchment, legend and signpost).
	var mp := UI.panel("Dark")
	mp.position = Vector2(10, 430)
	mp.custom_minimum_size = Vector2(1900, 420)
	mp.size = Vector2(1900, 420)
	add_child(mp)
	map = MapView.new()
	map.run = run
	map.custom_minimum_size = Vector2(1860, 390)
	map.node_clicked.connect(_travel)
	var mg := PaperFX.stage(mp, {"shadow_offset": Vector2(4, 5), "shadow_alpha": 0.28, "bevel_strength": 0.8})
	if mg != mp:
		var sb := mp.get_theme_stylebox("panel")
		map.position = Vector2(sb.get_margin(SIDE_LEFT), sb.get_margin(SIDE_TOP))
		map.size = Vector2(1860, 390)
	mg.add_child(map)
	# Bottom bar.
	var bp := UI.panel("DarkRopeTop")
	bp.position = Vector2(0, 860)
	bp.custom_minimum_size = Vector2(1920, 220)
	add_child(bp)
	var bh := UI.hb(14)
	bp.add_child(bh)
	party_row = UI.hb(6)
	bh.add_child(party_row)
	var mid := UI.vb(6)
	mid.custom_minimum_size.x = 450
	bh.add_child(mid)
	item_row = UI.vb(4)
	item_row.custom_minimum_size.x = 450
	mid.add_child(item_row)
	var turn_back := UI.btn("Turn Back", _turn_back, "Danger")
	turn_back.tooltip_text = "Abandon the expedition and head home with what you've found. Everyone gains Fatigue."
	mid.add_child(turn_back)
	log_label = UI.rich("", 16, false, 272)
	log_label.custom_minimum_size = Vector2(272, 176)
	log_label.scroll_active = true
	log_label.fit_content = false
	log_label.scroll_following = true
	bh.add_child(UI.inset(log_label))
	refresh()
	Audio.play_music("music_trail")
	for m in pending_notes:
		Main.inst.toast(m, _note_kind(m))
	pending_notes = []
	if _has_story(run.current_node()):
		call_deferred("_show_story", run.current_node(), Callable())
		return
	if run.day == 1 and run.current == 0:
		Main.inst.toast("Click a glowing stop on the map to travel on. Hover a stop to see what's there.")
	# Arrived somewhere that hasn't been dealt with yet (e.g. after loading a save).
	if not run.current_node().done:
		call_deferred("_resolve_node")
	elif run.current_node().type in ["fight", "elite"] and run.current_node().data.get("curios", []).any(func(c): return not c.done) \
			and not run.party_heroes().is_empty():
		# The dust settles: something on the battlefield is worth a look.
		call_deferred("show_curios", run.current_node().data.curios, "After the Fight")
	else:
		call_deferred("_check_end")


func _make_walkers() -> void:
	for w in walkers:
		w.queue_free()
	walkers.clear()
	var hs := run.party_heroes()
	for i in hs.size():
		var f := Figure.new()
		f.setup(hs[i].cls().look, hs[i].look_seed, 1)
		f.position = Vector2(780 - i * 95, 408)
		f.scale *= 0.62
		caravan.add_child(f)
		walkers.append(f)


func refresh() -> void:
	UI.clear(hud_row)
	hud_row.add_child(UI.hdr(run.region().name, 28))
	var items := [["week", "Day %d" % run.day, "Days on the trail."],
		["food", "Food %d" % int(run.supplies.get("food", 0)), "The party eats %d per stop." % run.food_need()],
		["wagon", "Wagon %d" % run.wagon, "Wagon condition. At 0 every stop adds Fatigue until repaired."],
		["money", "+%d" % int(run.loot.money), "Chips won this expedition."],
		["timber", "+%d" % int(run.loot.timber), "Timber found."],
		["iron", "+%d" % int(run.loot.iron), "Iron found."],
		["hides", "+%d" % int(run.loot.get("hides", 0)), "Hides taken: skin beasts, trap and hunt."],
		["charter", "+%d" % int(run.loot.charters), "Land Charters found."],
		["xp", "%d XP" % run.xp, "Experience each survivor earns."],
		["eye", "Scouting %d" % int(run.scout_score()), _scout_tip()]]
	if not run.loot.keepsakes.is_empty():
		items.append(["xp", "%d trinket%s" % [run.loot.keepsakes.size(), "s" if run.loot.keepsakes.size() > 1 else ""], ", ".join(run.loot.keepsakes.map(func(k): return DB.keepsakes[k].name))])
	for it in items:
		hud_row.add_child(UI.res_item(it[0], it[1], it[2], 30, 22))
	UI.party_cards(party_row, run, 0, _open_hero, func():
		Game.save_game()
		_make_walkers()
		refresh())
	UI.clear(item_row)
	item_row.add_child(UI.lbl("Wagon: %d of %d slots  (click to use)" % [Inventory.slots_used(run.cargo()), Inventory.capacity()], 16, "Bold"))
	var grid := InventoryGrid.make(run.cargo(), 50.0, 8, func(it: String):
		if DB.items.get(it, {}).get("cargo", false):
			return "Building material, carried home for your settlements."
		return "Click to use." if run.can_use_item(it) else "Used by events, curios and camp, not directly.")
	grid.slot_clicked.connect(func(it: String):
		if run.can_use_item(it):
			_use_item(it)
		elif DB.items[it].get("cargo", false):
			Main.inst.toast("%s is carried home to build with." % DB.items[it].name)
		else:
			Main.inst.toast("%s gets used by events, curios and camp actions." % DB.items[it].name))
	item_row.add_child(grid)
	var lines: Array = run.log.slice(maxi(0, run.log.size() - 30))
	log_label.text = "\n".join(lines)
	map.queue_redraw()
	wagon.damaged = run.wagon < 40
	wagon_bar.value = run.wagon
	wagon_bar.text_override = "Wagon %d/%d" % [run.wagon, DB.cfg("wagon_max", 100)]
	wagon_bar.fill = Color("#d9a441") if run.wagon >= 40 else (Color("#c0392b") if run.wagon > 0 else Color("#555555"))


## Painted scenery changes as the company pushes west: 0 at the first column, 1 at the last.
func _sync_backdrop() -> void:
	if backdrop == null or run == null:
		return
	backdrop.set_progress(run.map_progress())

func _process(delta: float) -> void:
	_sync_backdrop()
	_walk_t += delta
	for i in walkers.size():
		var w: Figure = walkers[i]
		if travelling:
			w.position.y = 408 - absf(sin(_walk_t * 8 + i)) * 6
		else:
			w.position.y = 408


func _scout_tip() -> String:
	var lines := ["Scouting: how well the company sees the trail ahead.", "Each stop, nearby stops come into rough view; a higher score reveals exactly what they are."]
	for h in run.party_heroes():
		var v: float = h.stat("scout")
		if v != 0:
			lines.append("%s: %+d (quirks/trinkets)" % [h.hero_name, int(v)])
		for sid in h.survival:
			if DB.survival[sid].get("passive", {}).get("type", "") == "scout":
				lines.append("%s: Scout skill" % h.hero_name)
			if sid == "tracker":
				lines.append("%s: Tracker (reads who's waiting at fights)" % h.hero_name)
	return "\n".join(lines)


func _open_hero(h: Hero) -> void:
	var sheet := HeroSheet.new()
	sheet.setup(h, -1, func(): refresh())
	sheet.wrap = Main.inst.modal(sheet)


# --- Travel ---------------------------------------------------------------------------

func _travel(id: int, confirmed: bool = false) -> void:
	if travelling or Main.inst.has_modal():
		return
	if not confirmed and run.node(id).type == "boss":
		var lvl := 0.0
		var hs := run.party_heroes()
		for h in hs:
			lvl += h.level
		lvl /= maxf(1, hs.size())
		var rec: String = run.region().get("rec_level", "?")
		Main.inst.dialog("Face %s?" % run.region().boss.name, "Ahead waits the master of this region. Recommended level: [b]%s[/b]. Your party averages level [b]%.1f[/b].\n\nThere is [b]no retreat[/b] from a boss fight. You can also turn back now and come again stronger." % [rec, lvl],
			[["Ride On", func(): _travel(id, true), "Danger"], ["Not Yet", Callable()]])
		return
	travelling = true
	map.enabled = false
	Audio.play("footsteps", 0.8)
	var start := scroll
	map.token_to = id
	map.token_t = 0.0
	var tw := create_tween()
	tw.tween_method(func(v):
		scroll = v
		backdrop.set_scroll(v)
		map.token_t = (v - start) / 700.0
		wagon.roll(v), start, start + 700.0, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	map.token_to = -1
	map.token_t = 0.0
	var msgs := run.travel_to(id)
	travelling = false
	map.enabled = true
	var leaving: bool = not run.current_node().done and run.current_node().type in ["fight", "elite", "boss", "crossing", "camp", "cave"]
	for m in msgs:
		if leaving:
			pending_notes.append(m)
		else:
			Main.inst.toast(m, _note_kind(m))
	Game.save_game()
	refresh()
	if run.party_heroes().is_empty():
		_check_end()
		return
	_resolve_node()


func _note_kind(m: String) -> String:
	return "bad" if "hungry" in m or "BROKEN" in m or "Breaking" in m or "BREAKING" in m else "neutral"


func _has_story(n: Dictionary) -> bool:
	return n.get("data", {}).has("story") and not n.data.get("story_seen", false)


## Story text for a hand-authored stop (the tutorial), shown once on arrival.
func _show_story(n: Dictionary, then: Callable) -> void:
	Main.inst.dialog(n.data.get("title", MapGen.TYPE_NAMES.get(n.type, "")), n.data.story, [["Continue", func():
		n.data["story_seen"] = true
		Game.save_game()
		if then.is_valid():
			then.call(), "Good"]])


func _resolve_node() -> void:
	var n := run.current_node()
	if n.done:
		return
	if _has_story(n):
		_show_story(n, _resolve_node)
		return
	match n.type:
		"fight", "elite":
			_to_combat(n.data.enemies, n.type)
		"boss":
			var b: Dictionary = run.region().boss
			Main.inst.dialog(b.name, run.boss_intro(), [["Fight!", func(): _to_combat(n.data.enemies, "boss"), "Danger"],
				["Turn Back", func():
					var summary := Game.company.finish_run("abandoned")
					Game.save_game()
					Main.inst.goto("results", {"summary": summary})]])
		"crossing":
			Main.inst.dialog(run.region().crossing.name, "The last stretch before %s. Somebody's waiting there." % run.region().boss.landmark, [["Fight!", func(): _to_combat(n.data.enemies, "crossing"), "Danger"]])
		"event", "homestead":
			show_event(n.data.event)
		"curio":
			show_curios(n.data.curios)
		"camp":
			Main.inst.goto("camp")
		"cave":
			Main.inst.dialog(n.data.get("name", "Cave"), "A dark opening in the ground breathes cold air. Caves hold treasure, and things that like the dark. Lamp oil keeps the dark at bay.\n\nYou have %d Lamp Oil." % int(run.supplies.get("lamp_oil", 0)),
				[["Go In", func():
					run.cave_enter()
					Game.save_game()
					Main.inst.goto("cave"), "Good"],
				["Pass By", func():
					run.complete_current()
					Game.save_game()
					refresh()]])
		"trading_post":
			show_trade()
		_:
			run.complete_current()
			refresh()


## setup: an event fight's extras (drop, wounded, foe_mods, foe_mark; see Effects "fight").
func _to_combat(enemies: Array, kind: String, surprise: String = "", reward: Dictionary = {}, setup: Dictionary = {}) -> void:
	var foes := enemies.duplicate()
	for d in setup.get("drop", []):
		if foes.size() > 1 and d in foes:
			foes.erase(d)
	Main.inst.goto("combat", {"enemies": foes, "kind": kind, "surprise": surprise, "reward": reward, "return": "trail",
		"setup": setup, "complete_node": kind in ["fight", "elite", "boss", "crossing"]})


func _check_end() -> void:
	if run.party_heroes().is_empty():
		var summary := Game.company.finish_run("defeat")
		Game.save_game()
		Main.inst.goto("results", {"summary": summary})
		return
	if run.is_final_node() and run.current_node().done:
		var summary2 := Game.company.finish_run("victory" if run.boss_won else ("driven_back" if run.driven_back else "abandoned"))
		Game.save_game()
		Main.inst.goto("results", {"summary": summary2})


func _turn_back() -> void:
	Main.inst.confirm("Turn Back?", "Head home to %s now. You keep what you've found, but everyone gains %d Fatigue from the long ride back." % [Game.company.settlement_name(run.origin), DB.cfg("turn_back_fatigue", 20)], func():
		var summary := Game.company.finish_run("abandoned")
		Game.save_game()
		Main.inst.goto("results", {"summary": summary}), "Turn Back")


# --- Items ----------------------------------------------------------------------------

func _use_item(item: String) -> void:
	var use: Dictionary = DB.items[item].use
	if use.type in ["wagon", "light"]:
		var msgs := run.use_item(item, null)
		for m in msgs:
			Main.inst.toast(m)
		Audio.play("clang" if use.type == "wagon" else "click")
		Game.save_game()
		refresh()
		return
	HeroPicker.pick(run.party_heroes(), "Use %s on whom?" % DB.items[item].name, func(h: Hero):
		var msgs2 := run.use_item(item, h)
		for m in msgs2:
			Main.inst.toast(m, "good")
		Audio.play("heal")
		Game.save_game()
		refresh())


# --- Events ---------------------------------------------------------------------------

func show_event(event_id: String) -> void:
	var ev: Dictionary = DB.events.get(event_id, {})
	var p := UI.panel()
	p.custom_minimum_size = Vector2(980, 0)
	var v := UI.vb(12)
	p.add_child(v)
	v.add_child(UI.hdr(ev.get("title", "Event"), 38, true))
	if ev.has("art"):
		var art := EventArt.new()
		art.kind = ev.art
		v.add_child(PaperFX.framed(art, Vector2(940, 190)))
	v.add_child(UI.rich(run.event_text(event_id), 23, true, 930))
	var holder := {"wrap": null}
	# A bad quirk may take the choice out of the company's hands.
	var compel := run.event_compel(event_id)
	if not compel.is_empty():
		v.add_child(UI.rich("[color=#%s][b]✗ %s[/b][/color]" % [UI.RED.to_html(false), compel.text], 21, true, 930))
	_option_buttons(v, run.event_options(event_id), holder, int(compel.get("index", -1)),
		func(idx: int): _event_result(event_id, run.choose_event_option(event_id, idx)))
	holder.wrap = Main.inst.modal(p, false)


## One button per visible option, with the ★/✗ names under it. only >= 0 shows just that one.
func _option_buttons(v: VBoxContainer, views: Array, holder: Dictionary, only: int, pick: Callable) -> void:
	for o in views:
		if o.hidden or (only >= 0 and o.index != only):
			continue
		var txt: String = ("%s  " % o.tag if o.tag != "" else "") + o.text
		var idx: int = o.index
		var b := UI.btn(txt, func():
			Main.inst.close_modal(holder.wrap)
			pick.call(idx), "")
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = not o.available
		if not o.available:
			b.tooltip_text = "You don't have what this needs."
		v.add_child(b)
		# ★ / ✗: what the company brings to this option (a class, skill or quirk), names only.
		if not o.experts.is_empty():
			var marks := []
			for m in o.experts:
				var col: Color = UI.RED if m.mark == "✗" else UI.GREEN
				marks.append("[color=#%s]%s %s[/color]" % [col.to_html(false), m.mark, m.name])
			v.add_child(UI.rich("      " + "    ".join(marks), 17, true, 930))


func _event_result(event_id: String, res: Dictionary) -> void:
	var fight = res.fight
	if fight == null:
		run.complete_current()
	Game.save_game()
	refresh()
	var body := "%s\n\n%s" % [res.text, "\n".join(res.msgs)]
	if fight != null:
		Main.inst.dialog("Trouble!", body, [["Fight!", func():
			run.complete_current()
			Game.save_game()
			_to_combat(fight.enemies, "fight", fight.get("surprise", ""), fight.get("reward", {}), fight), "Danger"]])
	elif res.get("then", false):
		Audio.play("page")
		Main.inst.dialog(DB.events[event_id].get("title", ""), body, [["Continue", func(): _show_followup(event_id)]])
	else:
		Audio.play("page")
		Main.inst.dialog(DB.events[event_id].get("title", ""), body, [["Continue", func(): _check_end()]])


## The second choice an outcome opened (dig up the grave, or leave a coin?).
func _show_followup(event_id: String) -> void:
	var p := UI.panel()
	p.custom_minimum_size = Vector2(980, 0)
	var v := UI.vb(12)
	p.add_child(v)
	v.add_child(UI.hdr(DB.events.get(event_id, {}).get("title", "Event"), 38, true))
	v.add_child(UI.rich(str(run.followup.get("text", "")), 23, true, 930))
	var holder := {"wrap": null}
	_option_buttons(v, run.followup_options(), holder, -1,
		func(idx: int): _event_result(event_id, run.choose_followup(idx)))
	holder.wrap = Main.inst.modal(p, false)


# --- Curios ---------------------------------------------------------------------------

func show_curios(curios: Array, title: String = "Curiosities") -> void:
	var p := UI.panel()
	p.custom_minimum_size = Vector2(1300, 0)
	var v := UI.vb(12)
	p.add_child(v)
	v.add_child(UI.hdr(title, 36, true))
	v.add_child(UI.lbl("Investigate by hand for a random result, or use a supply for a sure one. Known uses are marked ✓.", 19, "Ink"))
	var holder := {"wrap": null}
	var row := UI.hb(14)
	v.add_child(row)
	var all_done := true
	for cu in curios:
		if cu.done:
			continue
		all_done = false
		row.add_child(_curio_card(cu, curios, holder))
	if all_done:
		row.add_child(UI.lbl("Nothing left to look at here.", 20, "Ink"))
	v.add_child(UI.btn("Move On", func():
		Main.inst.close_modal(holder.wrap)
		for cu in curios:
			cu.done = true
		run.complete_current()
		Game.save_game()
		refresh()
		_check_end(), "Good"))
	holder.wrap = Main.inst.modal(p, false)


func _curio_card(cu: Dictionary, curios: Array, holder: Dictionary) -> Control:
	var d: Dictionary = DB.curios[cu.id]
	var card := UI.panel("Card")
	card.custom_minimum_size = Vector2(400, 0)
	var v := UI.vb(8)
	card.add_child(v)
	var art := CurioArt.new()
	art.kind = d.get("art", "crate")
	v.add_child(PaperFX.framed(art, Vector2(380, 150)))
	v.add_child(UI.hdr(d.name, 24, true))
	v.add_child(UI.wrap(UI.lbl(d.desc, 17, "Ink"), 380))
	var known: Array = Game.company.known_keys.get(cu.id, [])
	var btns := HFlowContainer.new()
	v.add_child(btns)
	btns.add_child(UI.btn("Investigate", func(): _do_curio(cu, "", curios, holder), "Small"))
	for it in EmbarkOrder.ORDER:
		if int(run.supplies.get(it, 0)) <= 0 or it == "food":
			continue
		var item: String = it
		var b := UI.btn(("✓ " if it in known else "") + DB.items[it].name, func(): _do_curio(cu, item, curios, holder), "Small")
		b.tooltip_text = "Use %s on it" % DB.items[it].name
		btns.add_child(b)
	return card


func _do_curio(cu: Dictionary, item: String, curios: Array, holder: Dictionary) -> void:
	Main.inst.close_modal(holder.wrap)
	var comp := run.compulsion_for(cu.id)
	var intro := ""
	var h: Hero
	if not comp.is_empty():
		h = comp.hero
		intro = comp.text + "\n\n"
		item = ""
	var go := func(hero: Hero):
		var res := run.interact_curio(cu.id, hero, item)
		cu.done = true
		Audio.play("coin" if res.key_worked else "page")
		Game.save_game()
		refresh()
		var body: String = intro + res.text + ("\n\n" + "\n".join(res.msgs) if not res.msgs.is_empty() else "")
		if res.fight != null:
			Main.inst.dialog("Ambush!", body, [["Fight!", func():
				if curios.all(func(x): return x.done):
					run.complete_current()
				Game.save_game()
				_to_combat(res.fight.enemies, "fight", res.fight.get("surprise", "")), "Danger"]])
		else:
			Main.inst.dialog(DB.curios[cu.id].name, body, [["Continue", func():
				if run.party_heroes().is_empty():
					_check_end()
				else:
					show_curios(curios)]])
	if h != null:
		go.call(h)
	else:
		HeroPicker.pick(run.party_heroes(), "Who investigates?", go,
			func(x: Hero): return run.curio_hint(cu.id, x) if item == "" else "")


# --- Trading post ---------------------------------------------------------------------

func show_trade() -> void:
	var p := UI.panel()
	p.custom_minimum_size = Vector2(760, 0)
	var v := UI.vb(10)
	p.add_child(v)
	v.add_child(UI.hdr("Trading Post", 36, true))
	v.add_child(UI.lbl("A lonely store at a crossroads. Prices are steep out here. Chips won on this trip are spent first.", 18, "Ink"))
	var holder := {"wrap": null}
	var stock: Dictionary = run.current_node().data.get("stock", {})
	var funds := UI.lbl("", 20, "InkBold")
	v.add_child(funds)
	var list := UI.vb(4)
	v.add_child(list)
	var fn := {"rebuild": null}
	fn.rebuild = func():
		funds.text = "Chips: %d (company) + %d (this trip)" % [Game.company.money, int(run.loot.money)]
		UI.clear(list)
		for it in stock:
			var row := UI.hb(10)
			var nl := UI.lbl("%s (%d left)" % [DB.items[it].name, int(stock[it])], 19, "InkBold")
			nl.custom_minimum_size.x = 300
			row.add_child(nl)
			row.add_child(UI.lbl("%d chips" % run.trade_price(it), 19, "Ink"))
			var item: String = it
			var b := UI.btn("Buy", func():
				if run.trade_buy(item):
					Audio.play("coin")
					refresh()
					fn.rebuild.call(), "Small")
			b.disabled = int(stock[it]) <= 0 or Game.company.money + int(run.loot.money) < run.trade_price(it)
			row.add_child(b)
			list.add_child(row)
	fn.rebuild.call()
	v.add_child(UI.btn("Leave", func():
		Main.inst.close_modal(holder.wrap)
		run.complete_current()
		Game.save_game()
		refresh(), "Good"))
	holder.wrap = Main.inst.modal(p, false)
