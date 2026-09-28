class_name HeroPicker
extends RefCounted
## A small modal: "choose a hero", then calls back with the chosen Hero.


static func pick(heroes: Array, title: String, cb: Callable) -> void:
	var p := UI.panel()
	p.custom_minimum_size = Vector2(560, 0)
	var v := UI.vb(8)
	p.add_child(v)
	v.add_child(UI.hdr(title, 28, true))
	var holder := {"wrap": null}
	for h in heroes:
		var card := HeroCard.make(h, true)
		card.clicked.connect(func(_c):
			Main.inst.close_modal(holder.wrap)
			cb.call(h))
		v.add_child(card)
	v.add_child(UI.btn("Cancel", func(): Main.inst.close_modal(holder.wrap), "Small"))
	holder.wrap = Main.inst.modal(p)
