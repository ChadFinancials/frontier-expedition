class_name HeroPicker
extends RefCounted
## A small modal: "choose a hero", then calls back with the chosen Hero.
## info (optional) returns a line of text shown under each hero, e.g. what they'd gain.


static func pick(heroes: Array, title: String, cb: Callable, info: Callable = Callable(), empty_text: String = "Nobody here can do that right now.") -> void:
	var p := UI.panel()
	p.custom_minimum_size = Vector2(600, 0)
	var v := UI.vb(8)
	p.add_child(v)
	v.add_child(UI.hdr(title, 28, true))
	var holder := {"wrap": null}
	if heroes.is_empty():
		v.add_child(UI.wrap(UI.lbl(empty_text, 19, "Ink"), 560))
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(580, mini(heroes.size(), 5) * 128)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var list := UI.vb(6)
	sc.add_child(list)
	for h in heroes:
		var card := HeroCard.make(h, true)
		card.clicked.connect(func(_c):
			Main.inst.close_modal(holder.wrap)
			cb.call(h))
		list.add_child(card)
		if info.is_valid():
			var t: String = info.call(h)
			# One label per line; ★ lines are green, ✗ lines red (curio experts).
			for line in t.split("\n", false):
				var col: Variant = UI.GREEN if line.begins_with("★") else (UI.RED if line.begins_with("✗") else null)
				list.add_child(UI.lbl("   " + line, 16, "Ink", col))
	v.add_child(UI.btn("Cancel", func(): Main.inst.close_modal(holder.wrap), "Small"))
	holder.wrap = Main.inst.modal(p)
