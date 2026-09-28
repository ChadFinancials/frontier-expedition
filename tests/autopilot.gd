class_name Autopilot
extends Node
## Plays the real UI like a (not very smart) player: presses buttons, answers dialogs,
## picks targets and walks the trail. Used to smoke-test every screen for runtime errors.
##   godot --headless --path . -- shot=autoplay expeditions=3

var expeditions_target := 3
var expeditions_done := 0
var rng := RandomNumberGenerator.new()
var _cool := 0.0
var _last_screen := ""
var _stuck := 0.0
var log_lines: Array = []
var camp_actions_done := 0
var panels_opened := {}
var need_rest := false
var turn_back_next := false


func _ready() -> void:
	rng.seed = 5
	Engine.time_scale = 6.0


func _process(delta: float) -> void:
	_cool -= delta / Engine.time_scale
	if _cool > 0:
		return
	_cool = 0.05
	var m := Main.inst
	if m == null or m._busy:
		return
	var sname := m.screen_name
	if sname != _last_screen:
		_last_screen = sname
		_stuck = 0.0
		note("screen: " + sname)
		if Game.company != null and sname == "settlement":
			note("seed %s first hero %s" % [str(Game.company.rng.seed), Game.company.heroes[0].hero_name if not Game.company.heroes.is_empty() else "-"])
	_stuck += 0.05
	if _stuck > 60.0:
		note("STUCK on " + sname)
		finish(1)
		return
	if m.has_modal():
		_handle_modal(m)
		return
	match sname:
		"menu":
			_press_text(m.screen, ["New Game", "Continue"])
		"settlement":
			if expeditions_done >= expeditions_target:
				finish(0)
				return
			var s = m.screen
			if need_rest:
				need_rest = false
				_press_text(s, ["Rest a Week"])
				return
			# Occasionally rest heroes first, to exercise the building UI.
			for h in Game.company.heroes_at(s.index):
				if h.fatigue > 50 and h.available() and Game.company.can_do_activity(s.index, "saloon", "bar", h) == "":
					Game.company.do_activity(s.index, "saloon", "bar", h)
					s.refresh()
			while Game.company.heroes_at(s.index).filter(func(x): return x.available()).size() < 4 and not Game.company.settlement(s.index).recruits.is_empty():
				if Game.company.hire(s.index, 0) == null:
					break
			s.refresh()
			# Exercise the settlement UI: open each building and a hero sheet once per week.
			var key := "w%d" % Game.company.week
			if not panels_opened.has(key):
				panels_opened[key] = 0
			var st: Dictionary = Game.company.settlement(s.index)
			var bids: Array = st.buildings.keys()
			if panels_opened[key] < bids.size():
				s.open_building(bids[panels_opened[key]])
				panels_opened[key] += 1
				return
			if panels_opened[key] == bids.size() and not Game.company.heroes_at(s.index).is_empty():
				panels_opened[key] += 1
				s.open_hero(Game.company.heroes_at(s.index)[0])
				return
			if panels_opened[key] == bids.size() + 1 and Game.company.money > 900:
				panels_opened[key] += 1
				s.open_building("")
				return
			_press_text(s, ["Plan Expedition"])
		"embark":
			if m.screen.party.is_empty():
				need_rest = true
				_press_text(m.screen, ["<  Back"])
				return
			if not _press_text(m.screen, ["Hit the Trail!"]):
				_press_text(m.screen, ["Clear"])
				for i in 3:
					_press_text(m.screen, ["+"])
		"trail":
			var t = m.screen
			if t.travelling:
				return
			if turn_back_next:
				turn_back_next = false
				_press_text(t, ["Turn Back"])
				return
			var ch: Array = t.run.choices()
			var weak: bool = t.run.party_heroes().all(func(h): return h.hp < h.max_hp() * 0.3)
			if weak and t.run.current_node().done:
				_press_text(t, ["Turn Back"])
				return
			for h in t.run.party_heroes():
				if h.hp < h.max_hp() * 0.4 and t.run.can_use_item("bandages"):
					t.run.use_item("bandages", h)
			if not ch.is_empty() and t.run.current_node().done:
				t._travel(Stats.pick(rng, ch))
		"combat":
			var c = m.screen
			if c.engine != null and c.engine.is_over() and not c.has_meta("noted"):
				c.set_meta("noted", true)
				note("  combat %s vs %s -> %s (fallen %d, round %d)" % [c.kind, c.params.get("enemies", []), c.engine.state, c.engine.fallen.size(), c.engine.round_num])
			if c.awaiting:
				_combat_turn(c)
		"camp":
			var cs = m.screen
			if cs.run.camp.get("meal", "") == "":
				_press_text(cs, ["Square Meal", "Half Rations", "Go Hungry"])
			elif camp_actions_done < 4 and _press_text(cs, ["h)"], true):
				camp_actions_done += 1
			else:
				camp_actions_done = 0
				_press_text(cs, ["Break Camp"])
		"cave":
			_press_text(m.screen, ["Face It", "Investigate", "Search the Chamber", "Press Deeper", "Climb Out"])
		"results":
			expeditions_done += 1
			note("expedition %d finished; week %d, money $%d, heroes %d, dead %d" % [expeditions_done, Game.company.week, Game.company.money, Game.company.heroes.size(), Game.company.dead.size()])
			_press_text(m.screen, ["Found ", "Return to"])


func _handle_modal(m: Main) -> void:
	var top: Control = m.modal_layer.get_child(m.modal_layer.get_child_count() - 1)
	if top.is_queued_for_deletion():
		return
	# Hero picker: click the first card.
	var cards := _find_all(top, "HeroCard")
	if not cards.is_empty() and _find_buttons(top).size() <= 1:
		cards[0].clicked.emit(cards[0])
		return
	# A careful player sometimes declines the boss with a green party.
	if _find_text(buttons_of(top), ["Ride On"]) != null and rng.randf() < 0.5:
		_find_text(buttons_of(top), ["Not Yet"]).pressed.emit()
		note("  declined the boss")
		turn_back_next = true
		return
	var prefs := ["Ride On", "Fight!", "Continue", "Head Home", "Turn Back", "Go In", "Found It", "Build It", "Run!", "Rest", "Yes", "Build (", "Investigate", "Move On", "Leave", "Done", "Close", "Cancel"]
	# Events: pick a random available option.
	var buttons := _find_buttons(top)
	var event_like := buttons.filter(func(b): return b.alignment == HORIZONTAL_ALIGNMENT_LEFT and not b.disabled)
	if not event_like.is_empty() and m.screen_name == "trail" and _find_text(buttons, ["Move On", "Leave", "Investigate"]) == null:
		var b: Button = Stats.pick(rng, event_like)
		note("  event option: " + b.text.left(60))
		b.pressed.emit()
		return
	var btn := _find_text(buttons, prefs)
	if btn != null:
		btn.pressed.emit()
	elif not buttons.is_empty():
		buttons[0].pressed.emit()


func _combat_turn(c) -> void:
	var e: CombatEngine = c.engine
	var cur: Combatant = e.current
	var usable := e.usable_skills(cur)
	if rng.randf() < 0.005 and e.can_retreat():
		c.chosen.emit("retreat", null, null)
		return
	if usable.is_empty():
		if cur.rank > 1:
			c.chosen.emit("swap", 1, null)
		else:
			c.chosen.emit("pass", null, null)
		return
	# Heal the badly hurt, otherwise attack the weakest reachable enemy.
	for h in e.heroes:
		if h.hp_ratio() < 0.4:
			for s2 in usable:
				var sk := DB.skill(s2)
				if sk.get("target", "") in ["ally", "party"] and sk.get("effects", []).any(func(x): return x.type == "heal"):
					var tt := e.valid_targets(cur, s2)
					c.chosen.emit("skill", s2, h.id if h.id in tt else tt[0])
					return
	var attacks := usable.filter(func(s3): return e.is_hostile(DB.skill(s3)))
	var sid: String = Stats.pick(rng, attacks if not attacks.is_empty() and rng.randf() < 0.85 else usable)
	var targets := e.valid_targets(cur, sid)
	var best: int = targets[0]
	for t in targets:
		if e.unit(t).hp < e.unit(best).hp:
			best = t
	c.chosen.emit("skill", sid, best)


func _press_text(root: Node, texts: Array, contains_any: bool = false) -> bool:
	var buttons := _find_buttons(root)
	for t in texts:
		for b in buttons:
			if b.disabled or not b.is_visible_in_tree():
				continue
			if (b.text.begins_with(t) if not contains_any else t in b.text):
				b.pressed.emit()
				return true
	return false


func _find_text(buttons: Array, texts: Array) -> Button:
	for t in texts:
		for b in buttons:
			if not b.disabled and b.is_visible_in_tree() and b.text.begins_with(t):
				return b
	return null


func buttons_of(root: Node) -> Array:
	return _find_buttons(root)


func _find_buttons(root: Node) -> Array:
	var out: Array = []
	for n in root.find_children("*", "Button", true, false):
		out.append(n)
	return out


func _find_all(root: Node, cls: String) -> Array:
	var out: Array = []
	for n in root.find_children("*", "", true, false):
		if n.get_script() != null and n.get_script().get_global_name() == cls:
			out.append(n)
	return out


func note(t: String) -> void:
	print("[autopilot] ", t)
	log_lines.append(t)


func finish(code: int) -> void:
	note("done: %d expeditions, week %d" % [expeditions_done, Game.company.week if Game.company else 0])
	Engine.time_scale = 1.0
	get_tree().quit(code)
