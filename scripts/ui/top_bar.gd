class_name TopBar
extends PanelContainer
## Resource strip: week, money, timber, iron, charters, plus a menu button.

var title_label: Label
var sub_label: Label
var res_row: HBoxContainer


func _init() -> void:
	theme_type_variation = "DarkRopeBottom"
	custom_minimum_size = Vector2(1920, 70)
	var row := UI.hb(18)
	add_child(row)
	var tv := UI.vb(0)
	title_label = UI.hdr("", 30)
	sub_label = UI.lbl("", 17)
	sub_label.add_theme_color_override("font_color", UI.PAPER_DARK)
	tv.add_child(title_label)
	tv.add_child(sub_label)
	tv.custom_minimum_size.x = 560
	row.add_child(tv)
	res_row = UI.hb(40)
	res_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	res_row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(res_row)
	var help := UI.btn("?", func(): Main.inst.help_panel(), "Small")
	help.tooltip_text = "How to play"
	row.add_child(help)
	row.add_child(UI.btn("Menu", func(): Main.inst.pause_menu(), "Small"))


func set_title(t: String, sub: String = "") -> void:
	title_label.text = t
	sub_label.text = sub


func refresh(extra: Dictionary = {}) -> void:
	UI.clear(res_row)
	var co: Company = Game.company
	if co == null:
		return
	_item("week", "Week %d" % co.week, "Each expedition takes a week. Buildings, recruits and the stage line run on weeks.")
	_item("money", "%d" % co.money, "Chips: the frontier's currency, minted by the Great Casino. Pays for supplies, buildings, treatment and training.")
	_item("timber", "%d" % co.timber, "Timber: used to build and upgrade buildings.")
	_item("iron", "%d" % co.iron, "Iron: used for buildings and gear upgrades.")
	_item("charter", "%d" % co.charters, "Land Charters: needed to found and grow settlements. Won from bosses and elites.")
	for k in extra:
		_item(k, str(extra[k]), "")


func _item(icon: String, text: String, tip: String) -> void:
	res_row.add_child(UI.res_item(icon, text, tip))
