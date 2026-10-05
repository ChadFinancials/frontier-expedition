class_name HighNoon
extends Control
## The High Noon screen: a dusty street, two figures, and the two parts of a duel (see Duel
## for the scoring). Opens as a modal; calls back with {"tier", "slow", "reaction", "pos"}.
##   1. Wait for "DRAW!" (false cues first), then click or press Space. Too early: jumped.
##      Too late: they fire first (the hero takes a hit; the aim zones shrink).
##   2. A sight swings across the aim bar, speeding up and slowing down; click or Space to
##      fire. Hold too long (config aim_time) and the shot goes wide.

signal finished(result: Dictionary)

const W := 1180.0
const H := 640.0
const STREET_H := 380.0
const BAR := Rect2(140, 470, 900, 46)

var hero: Hero
var duel: Dictionary = {}
var rng := RandomNumberGenerator.new()
var phase := "intro"          # intro, wait, draw, beat, shot, aim, result
var t := 0.0
var wait_time := 2.5
var cues: Array = []          # times of false cues during the wait
var cue_shown: Array = []
var draw_t := 0.0
var opp_fire := 0.6           # seconds after DRAW the opponent fires (their draw + the hero's edge)
var slow := false
var reaction := -1.0
var zones: Dictionary = {}
var sight := 0.0
var speed := 1.0
var aim_phase := 0.0          # the sight's swing, advanced at a pace that wanders
var pace := 1.0               # current multiple of speed
var pace_to := 1.0            # the pace it's easing toward
var pace_t := 0.0             # seconds until a new pace is picked
var aim_time := 4.0
var pos := 0.5
var tier := ""
var flash := {"hero": 0.0, "opp": 0.0}
var cue_text := ""
var cue_t := 0.0
var headline := ""
var subline := ""
var buttons: HBoxContainer
var _wrap: Control


## Opens the duel for hero against duel {"name", "draw", "tier"}. cb gets the result.
static func open(h: Hero, d: Dictionary, cb: Callable) -> HighNoon:
	var hn := HighNoon.new()
	hn.hero = h
	hn.duel = d
	hn.finished.connect(func(r): cb.call(r))
	hn._wrap = Main.inst.modal(hn, false, 0.75)
	return hn


func _ready() -> void:
	custom_minimum_size = Vector2(W, H)
	rng.randomize()
	var c := Duel.cfg()
	var wr: Array = c.get("wait", [1.5, 4.0])
	wait_time = rng.randf_range(float(wr[0]), float(wr[1]))
	for i in Duel.false_cues(hero, rng):
		cues.append(rng.randf_range(0.5, maxf(0.6, wait_time - 0.5)))
		cue_shown.append(false)
	opp_fire = float(duel.get("draw", 0.55)) + Duel.edge(hero)
	zones = Duel.zones(hero, false)
	speed = Duel.sight_speed(hero, int(duel.get("tier", 1)))
	aim_time = float(c.get("aim_time", 4.0))
	headline = "High Noon"
	subline = "%s faces %s. When the bell rings and DRAW! shows, click or press Space. Not before." % [hero.hero_name, duel.get("name", "the stranger")]
	buttons = UI.hb(12)
	buttons.position = Vector2(W / 2 - 110, H - 70)
	add_child(buttons)
	buttons.add_child(UI.btn("Step out", _start, "Danger", 220))
	Audio.play("wind", 0.6)


func _start() -> void:
	UI.clear(buttons)
	phase = "wait"
	t = 0.0
	headline = "..."
	subline = "Wait for it."


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	var pressed := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = true
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
		pressed = true
	if not pressed or not phase in ["wait", "draw", "aim"]:
		return
	get_viewport().set_input_as_handled()
	_press()


func _press() -> void:
	match phase:
		"wait":
			# Jumped the gun: no shot at all.
			tier = "jumped"
			flash.opp = 0.35
			flash.hero = 0.35
			Audio.play("gunshot")
			_finish("Jumped the gun!", "%s goes for the iron before the bell. %s doesn't miss." % [hero.hero_name, duel.get("name", "The stranger")])
		"draw":
			reaction = draw_t
			flash.hero = 0.3
			Audio.play("gunshot", 0.6)
			phase = "beat"
			t = 0.0
			headline = "Quicker!"
			subline = "%.2f s. Now aim." % reaction
		"aim":
			pos = sight
			tier = Duel.aim_tier(pos, zones)
			flash.hero = 0.35
			Audio.play("gunshot")
			var names := {"bullseye": "Bullseye!", "hit": "Hit!", "graze": "Graze", "miss": "Missed"}
			_finish(names.get(tier, tier), _result_line())


func _result_line() -> String:
	var opp: String = duel.get("name", "the stranger")
	match tier:
		"bullseye":
			return "Dead centre. %s goes down." % opp if duel.get("kind", "") != "boss" else "Dead centre. %s staggers, bleeding hard." % opp
		"hit":
			return "%s reels away bleeding." % opp
		"graze":
			return "The bullet only grazes %s." % opp
	return "The shot goes wide."


func _finish(head: String, sub: String) -> void:
	phase = "result"
	headline = head
	subline = sub
	UI.clear(buttons)
	buttons.add_child(UI.btn("Continue", func():
		Main.inst.close_modal(_wrap)
		finished.emit({"tier": tier, "slow": slow, "reaction": reaction, "pos": pos}), "Good", 220))


func _process(delta: float) -> void:
	t += delta
	for k in flash:
		flash[k] = maxf(0.0, flash[k] - delta)
	cue_t = maxf(0.0, cue_t - delta)
	match phase:
		"wait":
			for i in cues.size():
				if not cue_shown[i] and t >= cues[i]:
					cue_shown[i] = true
					cue_t = 0.9
					cue_text = Stats.pick(rng, ["*caw*", "A tumbleweed rolls by...", "*a shutter bangs*"])
					Audio.play("caw", 0.8)
			if t >= wait_time:
				phase = "draw"
				draw_t = 0.0
				headline = "DRAW!"
				subline = ""
				if not Duel.deaf(hero):
					Audio.play("bell")
		"draw":
			draw_t += delta
			if draw_t >= opp_fire:
				# Too slow: they fire first. The hero still gets a shot, with narrower zones.
				slow = true
				reaction = draw_t
				zones = Duel.zones(hero, true)
				flash.opp = 0.35
				Audio.play("gunshot")
				phase = "shot"
				t = 0.0
				headline = "Too slow!"
				subline = "%s fires first and the bullet finds %s. Return fire!" % [duel.get("name", "The stranger"), hero.hero_name]
		"beat", "shot":
			if t >= 0.9:
				phase = "aim"
				t = 0.0
				# Start the swing at a random point, so the first pass can't be learned.
				aim_phase = rng.randf()
				headline = "Aim"
				subline = "Click or press Space to fire."
		"aim":
			# The sight's pace wanders: it eases toward a new speed every fraction of a second.
			pace_t -= delta
			if pace_t <= 0.0:
				var dc := Duel.cfg()
				var pw: Array = dc.get("sight_wobble", [0.65, 1.45])
				var pe: Array = dc.get("sight_wobble_every", [0.25, 0.6])
				pace_to = rng.randf_range(float(pw[0]), float(pw[1]))
				pace_t = rng.randf_range(float(pe[0]), float(pe[1]))
			pace = lerpf(pace, pace_to, minf(1.0, delta * 6.0))
			aim_phase += delta * speed * pace
			var wob := 0.02 * sin(t * 13.0) if "drinker" in hero.quirks else 0.0
			sight = clampf(0.5 + 0.5 * sin(aim_phase * TAU) + wob, 0.0, 1.0)
			if t >= aim_time:
				# Held too long: the moment passes and the shot goes wide.
				pos = sight
				tier = "miss"
				Audio.play("gunshot", 0.7)
				_finish("Held too long", "%s's hand shakes and the shot goes wide." % hero.hero_name)
	queue_redraw()


# --- Drawing ------------------------------------------------------------------------------

func _figure(x: float, ground: float, facing: float, col: Color, hit: float) -> void:
	var c := col.lerp(Color("#ffffff"), clampf(hit * 2.0, 0.0, 0.8))
	var top := ground - 150.0
	draw_colored_polygon(PackedVector2Array([Vector2(x - 18, ground), Vector2(x - 8, ground), Vector2(x - 4, top + 95), Vector2(x - 20, top + 95)]), c)
	draw_colored_polygon(PackedVector2Array([Vector2(x + 8, ground), Vector2(x + 18, ground), Vector2(x + 20, top + 95), Vector2(x + 4, top + 95)]), c)
	draw_colored_polygon(PackedVector2Array([Vector2(x - 24, top + 98), Vector2(x + 24, top + 98), Vector2(x + 20, top + 38), Vector2(x - 20, top + 38)]), c)
	draw_circle(Vector2(x, top + 26), 14, c)
	draw_colored_polygon(PackedVector2Array([Vector2(x - 34, top + 16), Vector2(x + 34, top + 16), Vector2(x + 18, top + 10), Vector2(x + 14, top - 8), Vector2(x - 14, top - 8), Vector2(x - 18, top + 10)]), c)
	# Gun arm: down at the hip, up once the shooting starts.
	var up := phase in ["beat", "shot", "aim", "result"]
	var hand := Vector2(x + facing * (52 if up else 26), top + (52 if up else 88))
	draw_line(Vector2(x + facing * 16, top + 46), hand, c, 9)
	draw_line(hand, hand + Vector2(facing * 16, 0), c, 6)
	if hit > 0.0:
		draw_circle(hand + Vector2(facing * 24, 0), 10 * hit / 0.35, Color("#ffe08a"))


func _draw() -> void:
	# Paper card.
	draw_rect(Rect2(0, 0, W, H), Color("#efe2c4"))
	draw_rect(Rect2(0, 0, W, H), Color("#3a2a1c"), false, 4.0)
	# The street at noon.
	var st := Rect2(20, 20, W - 40, STREET_H)
	draw_polygon(PackedVector2Array([st.position, Vector2(st.end.x, st.position.y), st.end, Vector2(st.position.x, st.end.y)]),
		PackedColorArray([Color("#e9b46a"), Color("#e9b46a"), Color("#f4dfa8"), Color("#f4dfa8")]))
	draw_circle(Vector2(W / 2, 70), 34, Color("#fff4d0"))
	var mesa := PackedVector2Array([Vector2(20, 300), Vector2(150, 250), Vector2(260, 250), Vector2(320, 290), Vector2(760, 285), Vector2(840, 230), Vector2(1000, 230), Vector2(1080, 280), Vector2(W - 20, 290), Vector2(W - 20, 400), Vector2(20, 400)])
	draw_colored_polygon(mesa, Color("#c58a55"))
	var ground := STREET_H - 20.0
	draw_rect(Rect2(20, ground, W - 40, STREET_H + 20 - ground), Color("#b9875a"))
	_figure(300, ground + 14, 1.0, Color("#2a211a"), flash.hero)
	_figure(W - 300, ground + 14, -1.0, Color("#3a1e1a"), flash.opp)
	var f: Font = UI.font_bold
	draw_string(f, Vector2(250, ground + 50), hero.hero_name, HORIZONTAL_ALIGNMENT_LEFT, 200, 20, Color("#2a1d14"))
	draw_string(f, Vector2(W - 380, ground + 50), str(duel.get("name", "")), HORIZONTAL_ALIGNMENT_LEFT, 260, 20, Color("#2a1d14"))
	# The cue or headline over the street.
	if cue_t > 0.0 and phase == "wait":
		draw_string(f, Vector2(0, 150), cue_text, HORIZONTAL_ALIGNMENT_CENTER, W, 30, Color(0.17, 0.11, 0.08, cue_t))
	var hs := 64 if headline == "DRAW!" else 44
	var hc := Color("#a8392e") if headline in ["DRAW!", "Too slow!", "Jumped the gun!", "Missed", "Held too long"] else Color("#2a1d14")
	draw_string(f, Vector2(0, 225 if headline == "DRAW!" else 130), headline, HORIZONTAL_ALIGNMENT_CENTER, W, hs, hc)
	draw_string(f, Vector2(40, STREET_H + 60), subline, HORIZONTAL_ALIGNMENT_CENTER, W - 80, 22, Color("#2a1d14"))
	# The aim bar: miss at the edges, then graze, hit, bullseye at the centre.
	if phase in ["aim", "result", "beat", "shot"] and tier != "jumped":
		draw_rect(BAR, Color("#7a3a2a"))
		var cx := BAR.position.x + BAR.size.x / 2
		for band in [["graze", Color("#d9b44a")], ["hit", Color("#6e9a4a")], ["bullseye", Color("#f2e6a0")]]:
			var w := BAR.size.x * float(zones[band[0]])
			draw_rect(Rect2(cx - w / 2, BAR.position.y, w, BAR.size.y), band[1])
		draw_rect(BAR, Color("#2a1d14"), false, 3.0)
		var sx := BAR.position.x + BAR.size.x * (pos if phase == "result" else sight)
		draw_colored_polygon(PackedVector2Array([Vector2(sx - 12, BAR.position.y - 18), Vector2(sx + 12, BAR.position.y - 18), Vector2(sx, BAR.position.y - 2)]), Color("#2a1d14"))
		draw_line(Vector2(sx, BAR.position.y), Vector2(sx, BAR.end.y), Color("#2a1d14"), 3)
		# The time left to take the shot.
		if phase == "aim":
			var left := maxf(0.0, aim_time - t)
			var lc := Color("#a8392e") if left < 1.0 else Color("#2a1d14")
			var tw := (BAR.size.x * 0.3) * left / maxf(0.01, aim_time)
			draw_rect(Rect2(BAR.get_center().x - tw / 2, BAR.end.y + 10, tw, 8), lc)
			draw_string(UI.font_bold, Vector2(BAR.end.x + 12, BAR.get_center().y + 8), "%.1f" % left, HORIZONTAL_ALIGNMENT_LEFT, 80, 24, lc)
