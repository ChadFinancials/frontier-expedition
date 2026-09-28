class_name SlotBox
extends Button
## A Darkest Dungeon-style building slot: shows the hero placed in it, or an empty,
## clickable "+ Assign" box. Used by the Saloon, Chapel, Doctor, Stage Line and others.

const W := 132.0
const H := 170.0


static func make(h: Hero, empty_text: String = "+ Assign", enabled: bool = true) -> SlotBox:
	var b := SlotBox.new()
	b.custom_minimum_size = Vector2(W, H)
	b.theme_type_variation = "Tab"
	b.focus_mode = Control.FOCUS_NONE
	var v := UI.vb(2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.position = Vector2(8, 8)
	v.custom_minimum_size = Vector2(W - 16, H - 16)
	b.add_child(v)
	if h != null:
		var fb := FigureBox.new()
		fb.custom_minimum_size = Vector2(W - 16, 110)
		fb.focus_head = true
		fb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fb.show_hero(h)
		v.add_child(fb)
		var n := UI.lbl(h.hero_name, 17, "Bold")
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n.clip_text = true
		n.custom_minimum_size.x = W - 16
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(n)
		var c := UI.lbl(h.class_name_text(), 14)
		c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(c)
		b.disabled = true
		b.tooltip_text = "%s is here this week." % h.hero_name
	else:
		v.add_child(UI.spacer(0, 50))
		var l := UI.lbl(empty_text, 20, "Bold")
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = W - 16
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(l)
		b.disabled = not enabled
		if not enabled:
			b.modulate = Color(1, 1, 1, 0.5)
	return b
