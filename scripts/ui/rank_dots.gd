class_name RankDots
extends Control
## Darkest Dungeon-style position pips: the user's usable ranks (heroes 4-3-2-1, left to
## right) then the ranks the skill can reach (enemies 1-2-3-4).

var use_ranks: Array = []
var target_ranks: Array = []
var target_kind: String = "enemy"
var aoe: bool = false


static func for_skill(sid: String) -> RankDots:
	var d := RankDots.new()
	var sk := DB.skill(sid)
	d.use_ranks = sk.get("use_ranks", [])
	d.target_kind = sk.get("target", "enemy")
	d.target_ranks = sk.get("target_ranks", [1, 2, 3, 4]) if d.target_kind == "enemy" else []
	d.aoe = sk.get("aoe", false)
	d.custom_minimum_size = Vector2(150, 22)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return d


func _draw() -> void:
	var r := 7.0
	var y := size.y / 2
	for i in 4:
		var rank := 4 - i
		var p := Vector2(10 + i * 17, y)
		var on := rank in use_ranks
		draw_circle(p, r, Color("#e0bd4f") if on else Color(0, 0, 0, 0.3))
		draw_arc(p, r, 0, TAU, 16, Color(0, 0, 0, 0.6), 1.5)
	var x0 := 10 + 4 * 17 + 6
	match target_kind:
		"enemy":
			for i in 4:
				var p := Vector2(x0 + i * 17, y)
				var on := (i + 1) in target_ranks
				draw_circle(p, r, Color("#c0392b") if on else Color(0, 0, 0, 0.3))
				draw_arc(p, r, 0, TAU, 16, Color(0, 0, 0, 0.6), 1.5)
			if aoe and target_ranks.size() > 1:
				var a: int = target_ranks.min() - 1
				var b: int = target_ranks.max() - 1
				draw_line(Vector2(x0 + a * 17, y), Vector2(x0 + b * 17, y), Color("#c0392b"), 3)
		"ally", "party":
			draw_string(UI.font_bold, Vector2(x0, y + 7), "allies" if target_kind == "party" else "ally", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#5f8a3a"))
		"self":
			draw_string(UI.font_bold, Vector2(x0, y + 7), "self", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#3f6f96"))
