class_name InventoryGrid
extends GridContainer
## The wagon's cargo as a grid of slots (see Inventory). Each filled slot shows the item
## icon and its count; clicking a slot emits slot_clicked(item). Empty slots are shown too,
## so you can see how much room is left.

signal slot_clicked(item: String)

var slot_size := 76.0


static func make(supplies: Dictionary, size_px: float = 76.0, columns_n: int = 6, tip: Callable = Callable()) -> InventoryGrid:
	var g := InventoryGrid.new()
	g.slot_size = size_px
	g.columns = columns_n
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 6)
	g.fill(supplies, tip)
	return g


func fill(supplies: Dictionary, tip: Callable = Callable()) -> void:
	for c in get_children():
		c.queue_free()
	var st := Inventory.stacks(supplies)
	for i in maxi(Inventory.capacity(), st.size()):
		var b := Button.new()
		b.custom_minimum_size = Vector2(slot_size, slot_size)
		b.theme_type_variation = "Tab"
		b.focus_mode = Control.FOCUS_NONE
		if i < st.size():
			var item: String = st[i].item
			var d: Dictionary = DB.items.get(item, {})
			var icon := ResIcon.make(d.get("icon", item), slot_size * 0.62)
			icon.position = Vector2(slot_size * 0.19, slot_size * 0.1)
			b.add_child(icon)
			var n := UI.lbl(str(st[i].count), int(slot_size * 0.24), "Bold")
			n.position = Vector2(slot_size * 0.08, slot_size * 0.62)
			n.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(n)
			b.tooltip_text = "%s x%d\n%s" % [d.get("name", item), int(supplies.get(item, 0)), d.get("desc", "")]
			if tip.is_valid():
				var extra: String = tip.call(item)
				if extra != "":
					b.tooltip_text += "\n" + extra
			b.pressed.connect(func(): slot_clicked.emit(item))
		else:
			b.disabled = true
			b.modulate = Color(1, 1, 1, 0.45)
			b.tooltip_text = "Empty slot"
		add_child(b)
