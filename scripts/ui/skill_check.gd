class_name SkillCheck
extends Control
## A hands-on curio check (see RunState.curio_check). Four games, each 5-10 seconds, tuned by
## difficulty 1-5 from config "checks":
##   tumblers  a needle sweeps a dial; press Space or click as it crosses the notch (3 pins)
##   pattern   arrows flash, then type them back (arrow keys or WASD, or click the arrows)
##   quick     a key pops up inside a closing ring; press it before the ring closes
##   steady    hold Space or the mouse to lift the marker; keep it inside the drifting band
## Calls back with "clean", "close" or "botched".

signal finished(result: String)

const W := 900.0
const H := 560.0
const ARENA := Rect2(40, 120, 820, 300)
const DIRS := ["up", "left", "down", "right"]
const GLYPH := {"up": "↑", "left": "←", "down": "↓", "right": "→"}
const KEY_DIR := {KEY_UP: "up", KEY_W: "up", KEY_LEFT: "left", KEY_A: "left", KEY_DOWN: "down", KEY_S: "down", KEY_RIGHT: "right", KEY_D: "right"}

var check: Dictionary = {}     # {"game", "difficulty", "title", "text"}
var game := "tumblers"
var d := 3                     # difficulty 1-5
var rng := RandomNumberGenerator.new()
var phase := "intro"           # intro, play, result
var t := 0.0
var slips := 0
var result := ""
var headline := ""
var subline := ""
var buttons: HBoxContainer
var arrow_row: HBoxContainer
var _wrap: Control
# tumblers
var pin := 0
var pins := 3
var needle := 0.0              # degrees, -90..90
var notch := 0.0
var notch_w := 20.0
var sweeps := 0.8
var pin_flash := 0.0
# pattern
var seq: Array = []
var typed: Array = []
var show_time := 2.0
# quick
var prompts := 3
var prompt_i := 0
var prompt_dir := "up"
var window := 1.0
var prompt_t := 0.0
var gap := 0.0
# steady
var marker := 0.5              # 0 bottom .. 1 top
var vel := 0.0
var zone_c := 0.5
var zone_h := 0.25
var drift := 0.3
var holding := false
var out_time := 0.0
var seconds := 4.0


## Opens a check {"game", "difficulty", "title", "text"}; cb gets "clean", "close" or "botched".
static func open(c: Dictionary, cb: Callable) -> SkillCheck:
	var sc := SkillCheck.new()
	sc.check = c
	sc.finished.connect(func(r): cb.call(r))
	sc._wrap = Main.inst.modal(sc, false, 0.75)
	return sc


## Investigates a curio by hand: plays its check first if it has one (see RunState.curio_check),
## then applies the result. cb gets interact_curio's result.
static func investigate(run: RunState, cid: String, h: Hero, item: String, cb: Callable) -> void:
	var c := run.curio_check(cid, h, item)
	if c.is_empty():
		cb.call(run.interact_curio(cid, h, item))
	else:
		open(c, func(r: String): cb.call(run.interact_curio(cid, h, item, r)))


func _cfg(key: String, fallback):
	var g: Dictionary = DB.cfg("checks", {}).get(game, {})
	var v = g.get(key, fallback)
	if v is Array:
		return v[clampi(d - 1, 0, v.size() - 1)]
	return v


func _ready() -> void:
	custom_minimum_size = Vector2(W, H)
	rng.randomize()
	game = str(check.get("game", "tumblers"))
	d = clampi(int(check.get("difficulty", 3)), 1, 5)
	headline = str(check.get("title", "A careful job"))
	var how := {"tumblers": "Press Space or click when the needle crosses the notch. Three pins.",
		"pattern": "Watch the arrows, then type them back (arrow keys or WASD, or click them).",
		"quick": "Press the key shown before its ring closes (arrow keys or WASD, or click them).",
		"steady": "Hold Space or the mouse to lift the marker. Keep it inside the band."}
	subline = "%s\n%s   Difficulty %d of 5." % [check.get("text", ""), how.get(game, ""), d]
	buttons = UI.hb(12)
	buttons.position = Vector2(W / 2 - 100, H - 68)
	add_child(buttons)
	buttons.add_child(UI.btn("Begin", _begin, "Good", 200))


func _begin() -> void:
	UI.clear(buttons)
	phase = "play"
	t = 0.0
	match game:
		"tumblers":
			pins = int(_cfg("pins", 3))
			notch_w = float(_cfg("width_deg", 22))
			sweeps = float(_cfg("sweeps", 0.85))
			_new_notch()
			subline = "Pin 1 of %d" % pins
		"pattern":
			for i in int(_cfg("length", 5)):
				seq.append(Stats.pick(rng, DIRS))
			show_time = float(_cfg("show", 2.0))
			subline = "Remember them..."
		"quick":
			prompts = int(_cfg("prompts", 4))
			window = float(_cfg("window", 1.0))
			_next_prompt()
		"steady":
			seconds = float(_cfg("seconds", 4.0))
			zone_h = float(_cfg("zone", 0.25))
			drift = float(_cfg("drift", 0.3))
			subline = "Hold steady..."
	if game in ["pattern", "quick"]:
		arrow_row = UI.hb(10)
		arrow_row.position = Vector2(W / 2 - 190, H - 84)
		add_child(arrow_row)
		for dir in DIRS:
			var dd: String = dir
			var ab := UI.btn("", func(): _dir_pressed(dd), "", 86)
			ab.custom_minimum_size.y = 66
			var gl := Label.new()
			gl.text = GLYPH[dir]
			gl.add_theme_font_override("font", UI.font_bold)
			gl.add_theme_font_size_override("font_size", 48)
			gl.add_theme_color_override("font_color", Color("#f3e9d2"))
			gl.set_anchors_preset(Control.PRESET_FULL_RECT)
			gl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			gl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			gl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ab.add_child(gl)
			ab.focus_mode = Control.FOCUS_NONE
			arrow_row.add_child(ab)
		arrow_row.visible = game == "quick"


func _new_notch() -> void:
	notch = rng.randf_range(-60.0, 60.0)


func _next_prompt() -> void:
	prompt_dir = Stats.pick(rng, DIRS)
	prompt_t = 0.0
	subline = "%d of %d" % [prompt_i + 1, prompts]


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or phase != "play":
		return
	if event is InputEventKey and not event.echo:
		if game == "steady" and event.keycode == KEY_SPACE:
			holding = event.pressed
			get_viewport().set_input_as_handled()
			return
		if not event.pressed:
			return
		if game == "tumblers" and event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			get_viewport().set_input_as_handled()
			_tumbler_press()
		elif game in ["pattern", "quick"] and KEY_DIR.has(event.keycode):
			get_viewport().set_input_as_handled()
			_dir_pressed(KEY_DIR[event.keycode])
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if game == "steady":
			holding = event.pressed
			get_viewport().set_input_as_handled()
		elif game == "tumblers" and event.pressed and ARENA.has_point(get_local_mouse_position()):
			get_viewport().set_input_as_handled()
			_tumbler_press()


func _tumbler_press() -> void:
	if absf(needle - notch) <= notch_w / 2.0:
		Audio.play("click")
	else:
		slips += 1
		Audio.play("clang", 0.7)
	pin_flash = 0.3
	pin += 1
	if pin >= pins:
		_done()
	else:
		_new_notch()
		subline = "Pin %d of %d" % [pin + 1, pins]


func _dir_pressed(dir: String) -> void:
	if phase != "play":
		return
	if game == "pattern":
		if t < show_time:
			return
		if dir != seq[typed.size()]:
			slips += 1
			Audio.play("clang", 0.6)
		else:
			Audio.play("click")
		typed.append(dir)
		if typed.size() >= seq.size():
			_done()
	elif game == "quick" and gap <= 0.0:
		if dir == prompt_dir:
			Audio.play("click")
		else:
			slips += 1
			Audio.play("clang", 0.6)
		_advance_prompt()


func _advance_prompt() -> void:
	prompt_i += 1
	if prompt_i >= prompts:
		_done()
	else:
		gap = 0.35


func _done() -> void:
	phase = "result"
	if arrow_row != null:
		arrow_row.visible = false
	if game == "steady":
		var frac := out_time / maxf(0.01, seconds)
		result = "clean" if frac <= float(_cfg("clean_out", 0.12)) else ("close" if frac <= float(_cfg("close_out", 0.35)) else "botched")
	else:
		result = "clean" if slips == 0 else ("close" if slips == 1 else "botched")
	headline = {"clean": "Clean work!", "close": "Close...", "botched": "Botched!"}[result]
	subline = {"clean": "Not a slip.", "close": "One slip. It could go either way.", "botched": "That went badly."}[result]
	Audio.play("coin" if result == "clean" else ("page" if result == "close" else "clang"))
	UI.clear(buttons)
	buttons.add_child(UI.btn("Continue", func():
		Main.inst.close_modal(_wrap)
		finished.emit(result), "Good", 200))


func _process(delta: float) -> void:
	pin_flash = maxf(0.0, pin_flash - delta)
	if phase == "play":
		t += delta
		match game:
			"tumblers":
				needle = sin(t * sweeps * TAU) * 90.0
			"pattern":
				if t >= show_time and arrow_row != null and not arrow_row.visible:
					arrow_row.visible = true
					subline = "Your turn: %d arrows." % seq.size()
			"quick":
				if gap > 0.0:
					gap -= delta
					if gap <= 0.0:
						_next_prompt()
				else:
					prompt_t += delta
					if prompt_t >= window:
						slips += 1
						Audio.play("clang", 0.6)
						_advance_prompt()
			"steady":
				vel += (2.2 if holding else -1.6) * delta
				vel = clampf(vel, -1.2, 1.2)
				marker = clampf(marker + vel * delta, 0.0, 1.0)
				if marker <= 0.0 or marker >= 1.0:
					vel = 0.0
				zone_c = 0.5 + 0.3 * sin(t * drift * TAU) + (0.06 * sin(t * 5.3) if d >= 4 else 0.0)
				if absf(marker - zone_c) > zone_h / 2.0:
					out_time += delta
				if t >= seconds:
					_done()
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, W, H), Color("#efe2c4"))
	draw_rect(Rect2(0, 0, W, H), Color("#3a2a1c"), false, 4.0)
	var f: Font = UI.font_bold
	var ink := Color("#2a1d14")
	var hc := Color("#a8392e") if result == "botched" else (Color("#3f6128") if result == "clean" else ink)
	draw_string(f, Vector2(0, 62), headline, HORIZONTAL_ALIGNMENT_CENTER, W, 40, hc)
	var lines := subline.split("\n")
	for i in lines.size():
		draw_string(f, Vector2(40, 96 + i * 26 + (ARENA.end.y - 70 if phase != "intro" else 0)), lines[i], HORIZONTAL_ALIGNMENT_CENTER, W - 80, 20, ink)
	if phase == "intro":
		return
	draw_rect(ARENA, Color("#d8c39a"))
	draw_rect(ARENA, ink, false, 2.0)
	var c := ARENA.get_center()
	match game:
		"tumblers":
			var r := 120.0
			var base := c + Vector2(0, 80)
			draw_arc(base, r, PI, TAU, 48, ink, 3.0)
			var a0 := deg_to_rad(notch - notch_w / 2.0) - PI / 2.0
			var a1 := deg_to_rad(notch + notch_w / 2.0) - PI / 2.0
			draw_arc(base, r - 8, a0, a1, 16, Color("#6e9a4a"), 16.0)
			var na := deg_to_rad(needle) - PI / 2.0
			draw_line(base, base + Vector2(cos(na), sin(na)) * (r + 10), Color("#a8392e") if pin_flash > 0 else ink, 4.0)
			draw_circle(base, 8, ink)
			for i in pins:
				var col := Color("#6e9a4a") if i < pin else Color("#b9a27a")
				draw_circle(Vector2(c.x - (pins - 1) * 22 + i * 44, ARENA.position.y + 30), 12, col)
		"pattern":
			var showing := t < show_time and phase == "play"
			var n := seq.size()
			for i in n:
				var x := c.x - (n - 1) * 50.0 + i * 100.0
				var glyph := "?"
				var col := ink
				if showing:
					glyph = GLYPH[seq[i]]
				elif i < typed.size():
					glyph = GLYPH[typed[i]]
					col = Color("#3f6128") if typed[i] == seq[i] else Color("#a8392e")
				draw_string(f, Vector2(x - 40, c.y + 24), glyph, HORIZONTAL_ALIGNMENT_CENTER, 80, 64, col)
		"quick":
			if phase == "play" and gap <= 0.0:
				var frac := 1.0 - prompt_t / window
				draw_arc(c, 30 + 70 * frac, 0, TAU, 48, Color("#a8392e"), 5.0)
				draw_string(f, Vector2(c.x - 60, c.y + 26), GLYPH[prompt_dir], HORIZONTAL_ALIGNMENT_CENTER, 120, 72, ink)
		"steady":
			var track := Rect2(c.x - 40, ARENA.position.y + 20, 80, ARENA.size.y - 40)
			draw_rect(track, Color("#b9a27a"))
			var zh := track.size.y * zone_h
			var zy := track.end.y - track.size.y * zone_c - zh / 2.0
			draw_rect(Rect2(track.position.x, zy, track.size.x, zh), Color("#6e9a4a"))
			var my := track.end.y - track.size.y * marker
			draw_rect(Rect2(track.position.x - 14, my - 4, track.size.x + 28, 8), ink)
			var left := maxf(0.0, seconds - t) if phase == "play" else 0.0
			draw_string(f, Vector2(track.end.x + 40, c.y), "%.1f s" % left, HORIZONTAL_ALIGNMENT_LEFT, 200, 28, ink)
