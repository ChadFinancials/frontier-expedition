class_name TownsfolkCard
extends PanelContainer
## A townsperson's card: a drawn silhouette (placeholder until the image pass), name, level
## and trade, trait (★/✗), wage and where they work. Also the "who works here?" picker.

signal clicked(card: TownsfolkCard)

const TRADE_COLORS := {"barkeep": "#9c5b34", "parson": "#3a3a48", "sawbones": "#e6dfcf", "blacksmith": "#3c3f44",
	"drillmaster": "#6d7a52", "storekeeper": "#b88a4a", "undertaker": "#2a2422", "logger": "#a8392e",
	"mucker": "#7a6a55", "trapper": "#8a6a45", "laborer": "#5e7a8a"}

var person: Dictionary = {}


## A small figure in the trade's colors: hat, head, coat.
class Sil extends Control:
	var col := Color("#5a3822")
	var hat := "brim"

	func _draw() -> void:
		var c := size / 2.0
		var ink := Color("#2a1d14")
		draw_circle(c + Vector2(0, -14), 13, Color("#d9b48a"))
		draw_colored_polygon(PackedVector2Array([c + Vector2(-22, 34), c + Vector2(22, 34), c + Vector2(16, 0), c + Vector2(-16, 0)]), col)
		draw_polyline(PackedVector2Array([c + Vector2(-22, 34), c + Vector2(-16, 0), c + Vector2(16, 0), c + Vector2(22, 34)]), ink, 2.0)
		match hat:
			"bowler":
				draw_circle(c + Vector2(0, -26), 11, ink)
				draw_line(c + Vector2(-16, -22), c + Vector2(16, -22), ink, 4)
			"cap":
				draw_colored_polygon(PackedVector2Array([c + Vector2(-13, -24), c + Vector2(13, -24), c + Vector2(20, -20), c + Vector2(-13, -20)]), ink)
			"bonnet":
				draw_arc(c + Vector2(0, -16), 17, PI, TAU, 16, ink, 5)
			_:
				draw_colored_polygon(PackedVector2Array([c + Vector2(-22, -22), c + Vector2(22, -22), c + Vector2(10, -27), c + Vector2(8, -38), c + Vector2(-8, -38), c + Vector2(-10, -27)]), ink)


static func make(p: Dictionary, clickable: bool = false) -> TownsfolkCard:
	var card := TownsfolkCard.new()
	card.person = p
	card.theme_type_variation = "Card"
	card.custom_minimum_size = Vector2(540, 0)
	var row := UI.hb(12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(row)
	var sil := Sil.new()
	sil.custom_minimum_size = Vector2(64, 84)
	sil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sil.col = Color(TRADE_COLORS.get(str(p.trade), "#5a3822"))
	var hats := ["brim", "bowler", "cap", "bonnet"]
	sil.hat = hats[int(p.uid) % hats.size()]
	row.add_child(sil)
	var v := UI.vb(2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(v)
	var lvl := int(p.get("level", 1))
	v.add_child(UI.lbl(str(p.name), 21, "InkBold"))
	var tr := Townsfolk.trade(p)
	v.add_child(UI.lbl("%s %s  %s" % [Townsfolk.level_name(lvl), tr.get("name", "?"), "●".repeat(lvl) + "○".repeat(3 - lvl)], 17, "Ink"))
	var ti := Townsfolk.trait_info(p)
	var tcol := UI.GREEN if ti.get("good", false) else UI.RED
	var tl := UI.rich("[color=#%s]%s[/color]: %s" % [tcol.to_html(false), Townsfolk.trait_text(p), ti.get("desc", "")], 15, true, 440)
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(tl)
	var where := "Idle"
	if str(p.get("post", "")) != "":
		where = "Works at the %s" % DB.buildings.get(str(p.post), {}).get("name", "?")
		if p.get("off", false):
			where += " (sleeping one off this week)"
	v.add_child(UI.lbl("%s  |  Wage %d chips a week" % [where, Townsfolk.wage(p)], 15, "Ink"))
	card.tooltip_text = "%s: %s" % [tr.get("name", ""), tr.get("desc", "")]
	if clickable:
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		card.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				card.clicked.emit(card))
	return card


## "Who works here?": a list of cards; info(p) gives a line under each (★ marks the right
## trade). Calls cb with the chosen person.
static func pick(people: Array, title: String, cb: Callable, info: Callable = Callable(), empty_text: String = "Nobody's free.") -> void:
	var p := UI.panel()
	p.custom_minimum_size = Vector2(620, 0)
	var v := UI.vb(8)
	p.add_child(v)
	v.add_child(UI.hdr(title, 28, true))
	var holder := {"wrap": null}
	if people.is_empty():
		v.add_child(UI.wrap(UI.lbl(empty_text, 19, "Ink"), 580))
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(600, mini(people.size(), 5) * 150)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var list := UI.vb(6)
	sc.add_child(list)
	for person in people:
		var card := TownsfolkCard.make(person, true)
		card.clicked.connect(func(_c):
			Main.inst.close_modal(holder.wrap)
			cb.call(person))
		list.add_child(card)
		if info.is_valid():
			var t: String = info.call(person)
			var col: Variant = UI.GREEN if t.begins_with("★") else null
			list.add_child(UI.rich(("   [color=#%s]%s[/color]" % [col.to_html(false), t]) if col != null else "   " + t, 16, true))
	v.add_child(UI.btn("Cancel", func(): Main.inst.close_modal(holder.wrap), "Small"))
	holder.wrap = Main.inst.modal(p, true)
