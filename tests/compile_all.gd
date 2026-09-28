extends Node
## Loads every script in the project so parse/compile errors show up in one run.


func _ready() -> void:
	var bad := 0
	for dir in ["res://scripts", "res://tests"]:
		bad += _scan(dir)
	print("compile check done, %d scripts failed" % bad)
	get_tree().quit(1 if bad > 0 else 0)


func _scan(path: String) -> int:
	var bad := 0
	var d := DirAccess.open(path)
	if d == null:
		return 0
	for sub in d.get_directories():
		bad += _scan(path + "/" + sub)
	for f in d.get_files():
		if f.ends_with(".gd"):
			var s = load(path + "/" + f)
			if s == null or not (s is GDScript) or not s.can_instantiate():
				print("FAILED: ", path + "/" + f)
				bad += 1
	return bad
