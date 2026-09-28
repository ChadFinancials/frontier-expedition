class_name WagonArt
extends Node2D
## A covered prairie schooner with a team of oxen, paper-cutout style.
## Origin: ground level under the wagon's center. Faces right (west).

const PAPER := Color("#f3e9d2")
var wheel_angle := 0.0
var step := 0.0
var damaged := false
var show_team := true


func roll(dist: float) -> void:
	wheel_angle = dist / 34.0
	step = dist / 22.0
	queue_redraw()


func _poly(pts: Array, c: Color) -> void:
	var p := PackedVector2Array(pts)
	var sh := PackedVector2Array()
	for q in p:
		sh.append(q + Vector2(5, 6))
	draw_colored_polygon(sh, Color(0, 0, 0, 0.28))
	var closed := p.duplicate()
	closed.append(p[0])
	draw_polyline(closed, PAPER, 8.0, true)
	draw_colored_polygon(p, c)


func _wheel(c: Vector2, r: float) -> void:
	draw_circle(c + Vector2(5, 6), r + 3, Color(0, 0, 0, 0.28))
	draw_circle(c, r + 4, PAPER)
	draw_circle(c, r, Color("#3a2618"))
	draw_circle(c, r - 6, Color("#8a6a45"))
	for i in 8:
		var a := wheel_angle + i * TAU / 8
		draw_line(c, c + Vector2(cos(a), sin(a)) * (r - 6), Color("#3a2618"), 4.0)
	draw_circle(c, 7, Color("#3a2618"))


func _ox(at: Vector2, phase: float) -> void:
	var fur := Color("#7a5a3e")
	var dark := fur.darkened(0.25)
	for k in 2:
		var lx := at.x - 40 + k * 64
		var sw := sin(step + phase + k * PI) * 8
		draw_line(Vector2(lx, at.y - 34), Vector2(lx + sw, at.y), dark, 9.0)
	_poly([at + Vector2(-58, -70), at + Vector2(30, -76), at + Vector2(46, -52), at + Vector2(40, -30), at + Vector2(-50, -30), at + Vector2(-62, -48)], fur)
	for k in 2:
		var lx := at.x - 30 + k * 60
		var sw := sin(step + phase + k * PI + 1.3) * 8
		draw_line(Vector2(lx, at.y - 34), Vector2(lx - sw, at.y), fur, 10.0)
	_poly([at + Vector2(34, -74), at + Vector2(62, -70), at + Vector2(72, -44), at + Vector2(56, -36), at + Vector2(38, -50)], fur.darkened(0.1))
	draw_line(at + Vector2(48, -72), at + Vector2(60, -90), Color("#e9dfc8"), 5.0)
	draw_line(at + Vector2(-60, -60), at + Vector2(-70, -38), fur, 4.0)


func _draw() -> void:
	# Team of oxen ahead of the wagon.
	if show_team:
		_ox(Vector2(330, 0), 0.0)
		_ox(Vector2(230, 0), 1.7)
		draw_line(Vector2(120, -40), Vector2(290, -46), Color("#5a3e26"), 5.0)
	# Wagon bed.
	_wheel(Vector2(-110, -40), 40)
	_poly([Vector2(-170, -110), Vector2(150, -110), Vector2(138, -64), Vector2(-160, -64)], Color("#7a5232"))
	for i in 5:
		draw_line(Vector2(-150 + i * 64, -108), Vector2(-150 + i * 64, -66), Color("#5a3a22"), 2.0)
	# Canvas bonnet.
	var bonnet: Array = [Vector2(-180, -110)]
	for i in 13:
		var f := i / 12.0
		var x := lerpf(-176, 156, f)
		var bump := 8.0 * sin(f * PI * 6)
		bonnet.append(Vector2(x, -110 - 120 * sin(f * PI) * 0.55 - 70 - bump * 0.3))
	bonnet.append(Vector2(160, -110))
	var canvas := Color("#efe3c8") if not damaged else Color("#cdbd9a")
	_poly(bonnet, canvas)
	for i in 5:
		var x := -140 + i * 70
		draw_line(Vector2(x, -112), Vector2(x + 6, -236 + absf(i - 2) * 16), Color("#cbb994"), 3.0)
	if damaged:
		draw_line(Vector2(-60, -200), Vector2(-20, -140), Color("#8a6a45"), 3.0)
		draw_line(Vector2(40, -210), Vector2(70, -160), Color("#8a6a45"), 3.0)
	_wheel(Vector2(100, -36), 36)
	draw_line(Vector2(150, -80), Vector2(230, -60), Color("#5a3a22"), 6.0)
