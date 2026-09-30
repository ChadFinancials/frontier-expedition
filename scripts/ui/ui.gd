class_name UI
extends RefCounted
## Theme and widget helpers. Screens are built in code with these so the look stays
## consistent: parchment panels, dark wood buttons, Rye for headings, Alegreya for text.

const PAPER := Color("#ecdfc2")
const PAPER_DARK := Color("#d9c7a0")
const INK := Color("#2a1d14")
const INK_SOFT := Color("#5a4632")
const WOOD := Color("#5e3f27")
const WOOD_LIGHT := Color("#83593a")
const WOOD_DARK := Color("#3a2618")
const CREAM := Color("#f3e9d2")
const ACCENT := Color("#c8742c")
const GOLD := Color("#d9b44a")
const RED := Color("#a8392e")
const GREEN := Color("#5f8a3a")
const BLUE := Color("#3f6f96")
const FATIGUE := Color("#9b7fc6")
const HP := Color("#b8372d")
const NIGHT := Color("#1b1510")

static var _theme: Theme
static var font_body: Font
static var font_bold: Font
static var font_head: Font


static func fonts() -> void:
	if font_head != null:
		return
	font_head = load("res://assets/fonts/Rye-Regular.ttf")
	var base: Font = load("res://assets/fonts/Alegreya.ttf")
	var fv := FontVariation.new()
	fv.base_font = base
	fv.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 480}
	font_body = fv
	var fb := FontVariation.new()
	fb.base_font = base
	fb.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 760}
	font_bold = fb


static func box(bg: Color, border: Color = Color.TRANSPARENT, bw: int = 0, radius: int = 6, pad: int = 12, shadow: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = pad
	s.content_margin_right = pad
	s.content_margin_top = pad * 0.75
	s.content_margin_bottom = pad * 0.75
	if shadow > 0:
		s.shadow_color = Color(0, 0, 0, 0.35)
		s.shadow_size = shadow
		s.shadow_offset = Vector2(3, 4)
	s.anti_aliasing = true
	return s


static func theme() -> Theme:
	if _theme != null:
		return _theme
	fonts()
	var t := Theme.new()
	t.default_font = font_body
	t.default_font_size = 22
	# Labels: cream by default (most screens are dark); "Ink" variations for parchment.
	t.set_color("font_color", "Label", CREAM)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.0))
	t.set_type_variation("Ink", "Label")
	t.set_color("font_color", "Ink", INK)
	t.set_type_variation("Header", "Label")
	t.set_font("font", "Header", font_head)
	t.set_color("font_color", "Header", CREAM)
	t.set_color("font_shadow_color", "Header", Color(0, 0, 0, 0.55))
	t.set_constant("shadow_offset_x", "Header", 2)
	t.set_constant("shadow_offset_y", "Header", 3)
	t.set_type_variation("InkHeader", "Label")
	t.set_font("font", "InkHeader", font_head)
	t.set_color("font_color", "InkHeader", INK)
	t.set_type_variation("Bold", "Label")
	t.set_font("font", "Bold", font_bold)
	t.set_color("font_color", "Bold", CREAM)
	t.set_type_variation("InkBold", "Label")
	t.set_font("font", "InkBold", font_bold)
	t.set_color("font_color", "InkBold", INK)
	# Rich text.
	t.set_color("default_color", "RichTextLabel", CREAM)
	t.set_font("bold_font", "RichTextLabel", font_bold)
	t.set_font("normal_font", "RichTextLabel", font_body)
	t.set_type_variation("InkRich", "RichTextLabel")
	t.set_color("default_color", "InkRich", INK)
	# Panels.
	t.set_stylebox("panel", "PanelContainer", box(PAPER, WOOD, 3, 8, 16, 6))
	# Dark panels are stained planks (StyleBoxWood); the RopeTop/RopeBottom variations add a
	# rope along that edge, for the bars at the top and bottom of the screen.
	t.set_type_variation("Dark", "PanelContainer")
	t.set_stylebox("panel", "Dark", StyleBoxWood.plank(14))
	t.set_type_variation("DarkRopeTop", "PanelContainer")
	var rt := StyleBoxWood.plank(14)
	rt.rope_top = true
	rt.content_margin_top = 18
	t.set_stylebox("panel", "DarkRopeTop", rt)
	t.set_type_variation("DarkRopeBottom", "PanelContainer")
	var rb := StyleBoxWood.plank(14)
	rb.rope_bottom = true
	rb.content_margin_bottom = 16
	t.set_stylebox("panel", "DarkRopeBottom", rb)
	t.set_type_variation("Card", "PanelContainer")
	t.set_stylebox("panel", "Card", box(PAPER_DARK, WOOD, 2, 6, 10, 3))
	t.set_type_variation("Clear", "PanelContainer")
	t.set_stylebox("panel", "Clear", box(Color(0, 0, 0, 0), Color.TRANSPARENT, 0, 0, 0))
	t.set_stylebox("panel", "Panel", box(PAPER, WOOD, 3, 8, 0, 6))
	# Buttons.
	for v in ["Button", "Big", "Small", "Tab", "Danger", "Good"]:
		if v != "Button":
			t.set_type_variation(v, "Button")
		var base := WOOD
		if v == "Danger":
			base = Color("#7a2a22")
		elif v == "Good":
			base = Color("#3f6128")
		elif v == "Tab":
			base = Color("#4a3322")
		var pad := 18 if v == "Big" else (8 if v == "Small" else 12)
		# Wooden signboards; Danger and Good are painted boards.
		var board := Color("#6e4a2e") if v != "Tab" else Color("#4a3322")
		var paint := Color(0, 0, 0, 0)
		if v in ["Danger", "Good"]:
			paint = base
		var sn := StyleBoxWood.sign_board(board, pad, paint)
		var sh := StyleBoxWood.sign_board(board.lightened(0.14), pad, paint.lightened(0.14) if paint.a > 0 else paint, GOLD)
		var sp := StyleBoxWood.sign_board(board.darkened(0.2), pad, paint.darkened(0.2) if paint.a > 0 else paint, GOLD)
		var sd := StyleBoxWood.sign_board(Color("#4f4640"), pad)
		sd.nails = false
		if v == "Small":
			for sb in [sn, sh, sp, sd]:
				sb.nails = false
		t.set_stylebox("normal", v, sn)
		t.set_stylebox("hover", v, sh)
		t.set_stylebox("pressed", v, sp)
		t.set_stylebox("disabled", v, sd)
		t.set_stylebox("focus", v, StyleBoxEmpty.new())
		t.set_color("font_color", v, CREAM)
		t.set_color("font_hover_color", v, Color.WHITE)
		t.set_color("font_pressed_color", v, GOLD)
		t.set_color("font_disabled_color", v, Color(0.75, 0.7, 0.62, 0.7))
		t.set_font("font", v, font_head if v == "Big" else font_bold)
		t.set_font_size("font_size", v, 30 if v == "Big" else (18 if v == "Small" else 21))

	# Tooltips.
	t.set_stylebox("panel", "TooltipPanel", box(Color(0.1, 0.07, 0.05, 0.96), GOLD, 2, 6, 12, 4))
	t.set_color("font_color", "TooltipLabel", CREAM)
	t.set_font("font", "TooltipLabel", font_body)
	t.set_font_size("font_size", "TooltipLabel", 19)
	# Scrollbars.
	t.set_stylebox("scroll", "VScrollBar", box(Color(0, 0, 0, 0.15), Color.TRANSPARENT, 0, 4, 4))
	t.set_stylebox("grabber", "VScrollBar", box(WOOD_LIGHT, Color.TRANSPARENT, 0, 4, 4))
	t.set_stylebox("grabber_highlight", "VScrollBar", box(ACCENT, Color.TRANSPARENT, 0, 4, 4))
	t.set_stylebox("grabber_pressed", "VScrollBar", box(GOLD, Color.TRANSPARENT, 0, 4, 4))
	# Sliders & checkboxes.
	t.set_stylebox("slider", "HSlider", box(WOOD_DARK, Color.TRANSPARENT, 0, 4, 4))
	t.set_color("font_color", "CheckBox", CREAM)
	_theme = t
	return t


# --- Widgets --------------------------------------------------------------------------

static func lbl(text: String, size: int = 22, variation: String = "", color: Variant = null) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	if variation != "":
		l.theme_type_variation = variation
	if color != null:
		l.add_theme_color_override("font_color", color)
	return l


static func hdr(text: String, size: int = 40, ink: bool = false) -> Label:
	return lbl(text, size, "InkHeader" if ink else "Header")


static func wrap(l: Label, width: float = 0.0) -> Label:
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if width > 0:
		l.custom_minimum_size.x = width
	return l


## The party's hero cards in marching order (rank 1 first), with a swap button between
## each pair so the order can be changed on the trail or between cave rooms.
## on_card(h) runs when a card is clicked; on_swap runs after a swap (save and rebuild).
static func party_cards(row: HBoxContainer, run: RunState, card_w: float, on_card: Callable, on_swap: Callable) -> void:
	clear(row)
	var hs: Array = run.party_heroes()
	for i in hs.size():
		if i > 0:
			var k := i
			var sw := btn("⇄", func():
				run.swap_party(k - 1, k)
				Audio.play("cloth")
				on_swap.call())
			sw.theme_type_variation = "Small"
			sw.custom_minimum_size = Vector2(30, 0)
			sw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			sw.tooltip_text = "Swap ranks %d and %d" % [i, i + 1]
			row.add_child(sw)
		var h: Hero = hs[i]
		var c := HeroCard.make(h, true)
		c.custom_minimum_size.x = card_w
		c.tooltip_text = "Rank %d" % (i + 1)
		if on_card.is_valid():
			c.clicked.connect(func(_c): on_card.call(h))
		row.add_child(c)


static func btn(text: String, cb: Callable = Callable(), variation: String = "", min_w: float = 0.0) -> Button:
	var b := Button.new()
	b.text = text
	if variation != "":
		b.theme_type_variation = variation
	if min_w > 0:
		b.custom_minimum_size.x = min_w
	if cb.is_valid():
		b.pressed.connect(cb)
	b.pressed.connect(func(): Audio.play("click", 0.6))
	b.mouse_entered.connect(func(): if not b.disabled: Audio.play("hover", 0.25, 0.02))
	return b


static func panel(variation: String = "") -> PanelContainer:
	var p := PanelContainer.new()
	if variation != "":
		p.theme_type_variation = variation
	return p


static func vb(sep: int = 8) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func hb(sep: int = 8) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func spacer(w: float = 0, h: float = 0, expand: bool = false) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, h)
	if expand:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c


static func rich(bbcode: String, size: int = 21, ink: bool = false, width: float = 0.0) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.text = bbcode
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	if ink:
		r.theme_type_variation = "InkRich"
	if width > 0:
		r.custom_minimum_size.x = width
	r.mouse_filter = Control.MOUSE_FILTER_PASS
	return r


static func chip(text: String, kind: String = "neutral", size: int = 16) -> PanelContainer:
	var c := {"good": GREEN, "bad": RED, "neutral": WOOD_LIGHT, "gold": Color("#8a6d1f"), "blue": BLUE, "purple": Color("#6b4f96")}.get(kind, WOOD_LIGHT)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(c, c.darkened(0.3), 1, 4, 6, 0))
	var l := lbl(text, size, "Bold")
	p.add_child(l)
	return p


static func bar(value: float, max_value: float, color: Color, w: float = 160, h: float = 14, show_text: bool = false) -> StatBar:
	var b := StatBar.new()
	b.value = value
	b.max_value = max_value
	b.fill = color
	b.show_text = show_text
	b.custom_minimum_size = Vector2(w, h)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return b


static func clear(n: Node) -> void:
	for c in n.get_children():
		n.remove_child(c)
		c.queue_free()


static func stat_color(good: bool) -> String:
	return "#7fb069" if good else "#e0685a"


static func money_text(v: int) -> String:
	return "%d chips" % v


## Text block describing a skill for tooltips.
static func skill_tooltip(sid: String, level: int = 1) -> String:
	var sk := DB.skill(sid)
	var lines: Array = [sk.get("name", sid) + ("  (Lv %d)" % level if level > 1 else ""), sk.get("desc", "")]
	var ur: Array = sk.get("use_ranks", [])
	var line := "Use from: %s" % _ranks_text(ur)
	match sk.get("target", "enemy"):
		"enemy":
			if not sk.get("aoe_groups", []).is_empty():
				line += "   Target: ALL of %s" % " or ".join(sk.aoe_groups.map(func(g): return _ranks_text(g)))
			else:
				line += "   Target: %s%s" % ["ALL " if sk.get("aoe", false) else "", _ranks_text(sk.get("target_ranks", []))]
		"ally":
			line += "   Target: an ally"
		"self":
			line += "   Target: self"
		"party":
			line += "   Target: whole party"
	lines.append(line)
	if sk.get("target", "enemy") == "enemy":
		var dm := int(round(float(sk.get("dmg", 0.0)) * 100))
		var parts: Array = ["Accuracy %d" % int(sk.get("acc", 85))]
		if sk.has("dmg_range"):
			parts.append("Damage %d-%d" % [int(sk.dmg_range[0]), int(sk.dmg_range[1])])
		elif not sk.get("no_damage", false):
			parts.append("Damage %s%d%%" % ["+" if dm >= 0 else "", dm])
		if int(sk.get("crit", 0)) != 0:
			parts.append("Crit +%d%%" % int(sk.crit))
		if sk.get("hits", 1) > 1:
			parts.append("%d hits" % int(sk.hits))
		if sk.get("random_hits", 0) > 0:
			parts.append("%d random hits" % int(sk.random_hits))
		if float(sk.get("self_poisoned_bonus", 0)) > 0:
			parts.append("+%d%% damage while the user is poisoned" % int(round(float(sk.self_poisoned_bonus) * 100)))
		if sk.get("once_per_fight", false):
			parts.append("once per fight")
		lines.append(", ".join(parts))
	for e in sk.get("effects", []):
		var t := effect_text(e, level)
		if t != "":
			lines.append("• " + t)
	for e in sk.get("self_effects", []):
		var t2 := effect_text(e, level)
		if t2 != "":
			lines.append("• Self: " + t2)
	for e in sk.get("on_kill", []):
		var t3 := "+%d chips" % int(e.get("amount", 0)) if e.get("type", "") == "money" else effect_text(e, level)
		if t3 != "":
			lines.append("• On a kill: " + t3)
	return "\n".join(lines)


## One combat effect as plain words with its actual numbers at this skill level.
static func effect_text(e: Dictionary, level: int = 1) -> String:
	var chance := (" (%d%% base chance)" % int(e.chance)) if e.has("chance") and int(e.chance) < 100 else ""
	var rounds := int(e.get("rounds", 3))
	match str(e.get("type", "")):
		"heal":
			var m: float = float(DB.cfg("heal_mult", 1.0)) * (1.0 + DB.cfg("skill_level_heal_pct", 15) / 100.0 * (level - 1))
			return "Heals %d-%d HP" % [int(round(float(e.get("min", 3)) * m)), int(round(float(e.get("max", 6)) * m))]
		"heal_pct":
			return "Heals %d%% of max HP" % int(e.get("value", 10))
		"heal_self":
			return "Heals itself %d HP" % int(e.get("amount", 5))
		"self_damage":
			return "Costs %d of the user's own HP (never below 1)" % int(e.get("amount", 4))
		"heal_self_pct":
			return "Heals itself %d%% of max HP" % int(e.get("value", 10))
		"bleed", "poison":
			var amt: float = float(e.get("amount", 2)) * (1.0 + DB.cfg("skill_level_dot_pct", 15) / 100.0 * (level - 1))
			var extra := (" (%d if the user is poisoned)" % int(e.amount_if_self_poisoned)) if e.has("amount_if_self_poisoned") else ""
			return "%s: %d damage a turn for %d turns%s%s" % [str(e.type).capitalize(), maxi(1, int(round(amt))), rounds, extra, chance]
		"stun":
			return "Stun: loses their next turn" + chance
		"mark":
			return "Marks the target for %d rounds (some moves hit marked foes harder)" % rounds
		"debuff":
			return "%s for %d rounds%s" % [Stats.mod_text({"stat": e.stat, "value": e.value}), rounds, chance]
		"buff":
			var v := float(e.value) * (1.0 + 0.1 * (level - 1))
			return "%s for %d rounds" % [Stats.mod_text({"stat": e.stat, "value": int(round(v))}), rounds]
		"random_buff":
			return "A random boon for %d rounds" % rounds
		"fatigue":
			if e.get("amount") is Array:
				var lo := int(e.amount[0])
				var hi := int(e.amount[1])
				if hi <= 0:
					return "Relieves %d-%d Fatigue%s" % [-hi, -lo, chance]
				if lo < 0:
					return "Fatigue %d to +%d (a gamble)%s" % [lo, hi, chance]
				return "+%d-%d Fatigue" % [lo, hi]
			var fa := int(e.get("amount", 5))
			if fa < 0:
				fa = int(round(fa * (1.0 + 0.15 * (level - 1))))
				return "Relieves %d Fatigue" % -fa
			return "+%d Fatigue" % fa
		"knockback":
			return "Knocks back %d rank%s%s" % [int(e.get("amount", 1)), "" if int(e.get("amount", 1)) == 1 else "s", chance]
		"pull":
			return "Pulls forward %d rank%s%s" % [int(e.get("amount", 1)), "" if int(e.get("amount", 1)) == 1 else "s", chance]
		"buff_kin":
			var mods: Array = []
			for m in e.get("mods", []):
				mods.append(Stats.mod_text(m))
			return "Other %s: %s for %d rounds" % [e.get("kin", "pack members"), ", ".join(mods), int(e.get("rounds", 2))]
		"move":
			var mv := int(e.get("amount", 1))
			return "Moves %s %d rank%s" % ["forward" if mv > 0 else "back", absi(mv), "" if absi(mv) == 1 else "s"]
		"guard":
			return "Guards the ally for %d rounds (takes their hits)" % int(e.get("rounds", 2))
		"taunt":
			return "Draws enemy attacks for %d rounds" % int(e.get("rounds", 2))
		"cure":
			var names: Array = e.get("kinds", ["bleed", "poison"]).map(func(k): return {"debuff": "all debuffs"}.get(k, k))
			return "Cures %s" % ", ".join(names)
		"clear_shaken":
			return "Cures Shaken"
		"extend":
			return "Poisons, bleeds and debuffs already on the target last %d more round%s" % [int(e.get("rounds", 1)), "" if int(e.get("rounds", 1)) == 1 else "s"]
		"light":
			return "Lamplight %+d" % int(e.get("amount", 10))
		"summon":
			var who: String = DB.enemies.get(e.get("enemy", ""), {}).get("name", "help")
			return "Calls in %s" % (who if int(e.get("count", 1)) <= 1 else "%d x %s" % [int(e.count), who])
	return ""


## A camp action's effects in words, with numbers at this rank. party: heroes, for HP ranges.
static func camp_effects_text(action: Dictionary, rank: int, party: Array = []) -> String:
	var lines: Array = []
	for e in action.get("effects", []):
		var v := int(e.get("base", e.get("amount", 0))) + int(e.get("per_rank", 0)) * (rank - 1)
		var who := {"self": "this hero", "ally": "one hero", "party": "each hero"}.get(action.get("target", "party"), "each hero")
		match str(e.get("type", "")):
			"heal_pct":
				var hp_txt := ""
				if not party.is_empty():
					var lo := 999
					var hi := 0
					for h in party:
						var amt := int(ceil(h.max_hp() * v / 100.0))
						lo = mini(lo, amt)
						hi = maxi(hi, amt)
					hp_txt = " (%d HP)" % lo if lo == hi else " (%d-%d HP)" % [lo, hi]
				lines.append("Heals %s %d%% of max HP%s" % [who, v, hp_txt])
			"fatigue":
				lines.append("%s %s %d Fatigue" % [who.capitalize(), "sheds" if v < 0 else "gains", absi(v)])
			"fatigue_self":
				lines.append("This hero sheds %d Fatigue" % absi(v))
			"food":
				lines.append("+%d Food%s" % [v, (" (%d%% chance of nothing)" % int(e.fail)) if e.has("fail") else ""])
			"money":
				lines.append("+%d chips%s" % [v, (" (%d%% chance)" % int(e.chance)) if e.has("chance") else ""])
			"timber":
				lines.append("+%d Timber" % v)
			"iron":
				lines.append("+%d Iron%s" % [v, (" (%d%% chance)" % int(e.chance)) if e.has("chance") else ""])
			"item":
				lines.append("%d%% chance of %s" % [int(e.get("chance", 100)), DB.items.get(e.get("item", ""), {}).get("name", "an item")])
			"wagon":
				lines.append("Repairs the wagon by %d" % v)
			"reveal":
				lines.append("Scouts the %d nearest unknown stops" % v)
			"no_ambush":
				lines.append("No ambush tonight")
			"next_fight_buff":
				lines.append("Next fight: %s" % Stats.mod_text({"stat": e.stat, "value": v}) if e.stat != "surprise" else "Next fight: +%d%% chance to surprise the enemy" % v)
			"clear_shaken":
				lines.append("Cures Shaken")
			"craft_parts":
				lines.append("Turns 2 Timber into 1 Wagon Parts (free at rank 3)")
	return "\n".join(lines)


static func _ranks_text(r: Array) -> String:
	var s: Array = []
	for i in [1, 2, 3, 4]:
		s.append("●" if i in r else "○")
	return " ".join(s)


static func hero_tooltip(h: Hero) -> String:
	var lines := ["%s: Level %d %s" % [h.hero_name, h.level, h.class_name_text()],
		"HP %d/%d   Fatigue %d/200" % [h.hp, h.max_hp(), h.fatigue]]
	if h.fatigue_state != "":
		lines.append(DB.fatigue_states[h.fatigue_state].name + ": " + DB.fatigue_states[h.fatigue_state].desc)
	var sv: Array = []
	for s in h.survival:
		sv.append("%s %d" % [DB.survival[s].name, int(h.survival[s].rank)])
	lines.append("Survival: " + ", ".join(sv))
	var qs: Array = []
	for q in h.quirks:
		qs.append(("+" if DB.quirks[q].positive else "-") + DB.quirks[q].name)
	lines.append("Quirks: " + ", ".join(qs))
	return "\n".join(lines)


static func quirk_tooltip(q: String) -> String:
	var d: Dictionary = DB.quirks.get(q, {})
	var lines := [d.get("name", q) + (" (good)" if d.get("positive", false) else " (bad)"), d.get("desc", "")]
	for m in d.get("mods", []):
		lines.append(Stats.mod_text(m))
	if d.has("compulsion"):
		lines.append("Compelled to handle %s things." % d.compulsion.tag)
	return "\n".join(lines)


static func keepsake_tooltip(k: String) -> String:
	var d: Dictionary = DB.keepsakes.get(k, {})
	var lines := ["%s (%s)" % [d.get("name", k), d.get("rarity", "")], d.get("desc", "")]
	for m in d.get("mods", []):
		lines.append(Stats.mod_text(m))
	return "\n".join(lines)


static func survival_tooltip(sid: String, rank: int) -> String:
	var d: Dictionary = DB.survival.get(sid, {})
	var lines := ["%s (rank %d)" % [d.get("name", sid), rank], d.get("desc", "")]
	var p: Dictionary = d.get("passive", {})
	if not p.is_empty():
		var pv := int(p.get("base", 0)) + int(p.get("per_rank", 0)) * (rank - 1)
		var unit := "%" if str(p.get("type", "")).ends_with("_pct") or p.get("type", "") in ["scout", "forage", "wagon_guard", "surprise"] else ""
		lines.append("On the trail: %s (%+d%s)" % [p.get("text", ""), pv, unit])
	for a in d.get("actions", []):
		var unlock := int(a.get("unlock", 1))
		var head := "Camp: %s (%dh)" % [a.name, int(a.hours)]
		if rank < unlock:
			lines.append("%s: unlocks at rank %d" % [head, unlock])
		else:
			lines.append("%s: %s" % [head, camp_effects_text(a, rank).replace("\n", "; ")])
	return "\n".join(lines)


## The broad kind of a skill, for its icon: melee, ranged, debuff, heal or buff.
static func skill_kind(sid: String) -> String:
	var sk := DB.skill(sid)
	var t: String = sk.get("target", "enemy")
	if t == "enemy":
		if sk.get("no_damage", false):
			return "debuff"
		return "melee" if sk.get("anim", "") in ["melee", "dog"] else "ranged"
	for e in sk.get("effects", []) + sk.get("self_effects", []):
		if e is Dictionary and e.get("type", "") == "heal":
			return "heal"
	return "buff"


const SKILL_KIND_TEXT := {"melee": "Melee attack", "ranged": "Ranged attack", "debuff": "Hinders the enemy",
	"heal": "Heals", "buff": "Helps your side"}


## A row of stat icons with values and tooltips.
static func stat_row(stats: Array, font_size: int = 16) -> HBoxContainer:
	var row := hb(12)
	for st in stats:
		var cell := hb(3)
		cell.tooltip_text = st[2]
		cell.mouse_filter = Control.MOUSE_FILTER_PASS
		cell.add_child(ResIcon.make(st[0], font_size + 2))
		var l := lbl(str(st[1]), font_size)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(l)
		row.add_child(cell)
	return row
