extends Node
## Sound effects and music. Loads every clip in res://assets/audio/ by file name.
## play("gunshot") picks "gunshot.wav", or a random variant "gunshot_1.wav", "gunshot_2.wav"...

const DIR := "res://assets/audio/"
const POOL := 12

var clips: Dictionary = {}       # name -> Array[AudioStream]
var gains: Dictionary = {}       # AudioStream -> dB offset from levels.json (tools/level_audio.py)
var players: Array = []
var music_player: AudioStreamPlayer
var _next := 0


func _ready() -> void:
	_load_clips()
	for i in POOL:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.finished.connect(func(): if music_player.stream != null: music_player.play())


func _load_clips() -> void:
	var d := DirAccess.open(DIR)
	if d == null:
		return
	var levels: Dictionary = {}
	if FileAccess.file_exists(DIR + "levels.json"):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(DIR + "levels.json"))
		if parsed is Dictionary:
			levels = parsed
	for f in d.get_files():
		# Exported builds list "x.wav.import" instead of "x.wav".
		var fname := f.trim_suffix(".import").trim_suffix(".remap")
		if not (fname.ends_with(".wav") or fname.ends_with(".ogg")):
			continue
		var stream = load(DIR + fname)
		if stream == null:
			continue
		var base := fname.get_basename()
		var key := base
		var us := base.rfind("_")
		if us > 0 and base.substr(us + 1).is_valid_int():
			key = base.substr(0, us)
		if not clips.has(key):
			clips[key] = []
		if not stream in clips[key]:
			clips[key].append(stream)
			gains[stream] = float(levels.get(base, 0.0))


func has(name: String) -> bool:
	return clips.has(name)


func play(name: String, volume: float = 1.0, pitch_var: float = 0.08) -> void:
	if name == "" or not clips.has(name):
		return
	var vol: float = float(Game.settings.get("sfx", 0.8)) * volume
	if vol <= 0.001:
		return
	var p: AudioStreamPlayer = players[_next]
	_next = (_next + 1) % players.size()
	p.stream = clips[name][randi() % clips[name].size()]
	p.volume_db = linear_to_db(vol) + float(gains.get(p.stream, 0.0))
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.play()


func play_music(name: String) -> void:
	if not clips.has(name):
		music_player.stop()
		music_player.stream = null
		return
	var s: AudioStream = clips[name][0]
	if music_player.stream == s and music_player.playing:
		return
	music_player.stream = s
	update_music_volume()
	music_player.play()


func stop_music() -> void:
	music_player.stop()
	music_player.stream = null


func update_music_volume() -> void:
	var v: float = float(Game.settings.get("music", 0.45))
	music_player.volume_db = linear_to_db(maxf(0.0001, v)) - 6.0
