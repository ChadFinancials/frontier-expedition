class_name MinigameLab
extends RefCounted
## Dev tool (main menu, dev tools on): play High Noon over and over against any opponent,
## with any class and quirks, and see the numbers behind each result; and try each curio
## skill check at any difficulty.

const CLASSES := ["gunslinger", "marshal", "preacher", "rail_driver", "gambler"]
const QUIRKS := ["eagle_eye", "outlaw_hunter", "butterfingers", "jumpy", "drinker", "hard_of_hearing"]
const OPPONENTS := [
	{"name": "Outlaw leader", "draw": 0.55, "tier": 1},
	{"name": "Mad Dog Mulligan (boss)", "draw": 0.50, "tier": 1, "kind": "boss"},
	{"name": "Snake-Eye Pike", "draw": 0.45, "tier": 2},
	{"name": "A fast gun (later regions)", "draw": 0.32, "tier": 3},
]

const GAMES := ["tumblers", "pattern", "quick", "steady"]

static var state := {"cls": "gunslinger", "quirks": [], "opp": 0, "last": "", "game": "tumblers", "diff": 3}


static func open() -> void:
	var p := UI.panel()
	p.custom_minimum_size = Vector2(760, 0)
	var v := UI.vb(10)
	p.add_child(v)
	v.add_child(UI.hdr("DEV: Minigame Lab", 32, true))
	v.add_child(UI.lbl("High Noon", 22, "InkBold"))
	var holder := {"wrap": null}
	var reopen := func():
		Main.inst.close_modal(holder.wrap)
		open()
	v.add_child(UI.lbl("Hero class", 18, "InkBold"))
	var row := HFlowContainer.new()
	v.add_child(row)
	for c in CLASSES:
		var cc: String = c
		row.add_child(UI.btn(("● " if state.cls == c else "") + DB.classes[c].name, func():
			state.cls = cc
			reopen.call(), "Small"))
	v.add_child(UI.lbl("Quirks (toggle)", 18, "InkBold"))
	var row2 := HFlowContainer.new()
	v.add_child(row2)
	for q in QUIRKS:
		var qq: String = q
		row2.add_child(UI.btn(("● " if q in state.quirks else "") + DB.quirks[q].name, func():
			if qq in state.quirks:
				state.quirks.erase(qq)
			else:
				state.quirks.append(qq)
			reopen.call(), "Small"))
	v.add_child(UI.lbl("Opponent", 18, "InkBold"))
	var row3 := HFlowContainer.new()
	v.add_child(row3)
	for i in OPPONENTS.size():
		var ii: int = i
		row3.add_child(UI.btn(("● " if state.opp == i else "") + "%s (%.2f s)" % [OPPONENTS[i].name, OPPONENTS[i].draw], func():
			state.opp = ii
			reopen.call(), "Small"))
	v.add_child(UI.btn("Duel!", func():
		Main.inst.close_modal(holder.wrap)
		_duel(), "Danger", 200))
	v.add_child(UI.lbl("Curio skill checks", 22, "InkBold"))
	var row4 := HFlowContainer.new()
	v.add_child(row4)
	for g in GAMES:
		var gg: String = g
		row4.add_child(UI.btn(("● " if state.game == g else "") + g.capitalize(), func():
			state.game = gg
			reopen.call(), "Small"))
	var row5 := HFlowContainer.new()
	v.add_child(row5)
	for dlev in [1, 2, 3, 4, 5]:
		var dl: int = dlev
		row5.add_child(UI.btn(("● " if state.diff == dlev else "") + "Difficulty %d" % dlev, func():
			state.diff = dl
			reopen.call(), "Small"))
	v.add_child(UI.btn("Try the check", func():
		Main.inst.close_modal(holder.wrap)
		SkillCheck.open({"game": state.game, "difficulty": state.diff, "title": state.game.capitalize(), "text": "A test run."}, func(r: String):
			state.last = "[b]Last check: %s at difficulty %d → %s[/b]" % [state.game.capitalize(), state.diff, r.capitalize()]
			open()), "Good", 200))
	if str(state.last) != "":
		v.add_child(UI.rich(str(state.last), 17, true, 720))
	v.add_child(UI.btn("Close", func(): Main.inst.close_modal(holder.wrap), "", 140))
	holder.wrap = Main.inst.modal(p)


static func _duel() -> void:
	var co := Company.new()
	var h: Hero = co.make_hero(state.cls, 1)
	h.quirks = state.quirks.duplicate()
	var o: Dictionary = OPPONENTS[state.opp]
	var d := {"name": o.name, "draw": o.draw, "tier": o.tier, "kind": o.get("kind", "gang")}
	HighNoon.open(h, d, func(r: Dictionary):
		var z := Duel.zones(h, r.get("slow", false))
		state.last = "[b]Last: %s[/b]%s   reaction %s   edge %.2f s   their draw %.2f s\nzones: bullseye %d%%  hit %d%%  graze %d%%   shot at %.3f (0.5 = centre)" % [
			str(r.tier).capitalize(), " (too slow)" if r.get("slow", false) else "",
			("%.3f s" % r.reaction) if float(r.get("reaction", -1)) >= 0 else "-", Duel.edge(h), o.draw,
			int(round(z.bullseye * 100)), int(round(z.hit * 100)), int(round(z.graze * 100)), float(r.get("pos", 0.5))]
		open())
