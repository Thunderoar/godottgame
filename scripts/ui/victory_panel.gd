class_name VictoryPanel
extends ModalBase
## Boss victory report. The actual reward transaction is done by GameState
## before this panel opens; this is a read-only summary plus the way home.

var _summary: Dictionary = {}
var _portal_id := ""


func _ready() -> void:
	super._ready()


func show_victory(summary: Dictionary, portal_id: String) -> void:
	_summary = summary
	_portal_id = portal_id
	var def := PortalDB.get_portal(portal_id)
	open_panel("Guardian Defeated")


func _rebuild() -> void:
	_clear_content()
	var def := PortalDB.get_portal(_portal_id)
	var first := bool(_summary.get("first", false))
	add_body_text(str(def.get("boss_name", "The guardian")) + " has fallen.", GameUI.TEXT, 22)
	add_body_text("The portal's whisper fades. Your expedition loot has been carried safely home.", GameUI.MUTED, 14)
	content.add_child(GameUI.spacer(8))
	var reward_row := HBoxContainer.new()
	reward_row.add_theme_constant_override("separation", 28)
	reward_row.add_child(_reward_chip("gold", "%d gold" % int(_summary.get("gold", 0)), GameUI.GOLD))
	reward_row.add_child(_reward_chip("diamond", "%d diamonds" % int(_summary.get("diamonds", 0)), GameUI.DIAMOND))
	if int(_summary.get("xp", 0)) > 0:
		reward_row.add_child(_reward_chip("spark", "%d XP" % int(_summary.get("xp", 0)), GameUI.TEAL))
	content.add_child(reward_row)
	if str(_summary.get("pet", "")) != "":
		add_section("NEW COMPANION", GameUI.GOLD)
		var pet_id := str(_summary.pet)
		var def_pet := PetDB.get_pet(pet_id)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		var preview := TextureRect.new()
		preview.texture = PixelArt.pet_texture(pet_id)
		preview.custom_minimum_size = Vector2(80, 80)
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(preview)
		var info := VBoxContainer.new()
		info.add_child(GameUI.label("%s  •  %s" % [def_pet.name, def_pet.species], 19, GameUI.TEXT))
		info.add_child(GameUI.label(str(def_pet.description), 13, GameUI.MUTED))
		info.add_child(GameUI.label("Heal %d / Atk %d / Shield %d. Select it at Nia's shop." % [int(def_pet.heal), int(def_pet.attack), int(def_pet.shield)], 13, GameUI.TEAL))
		row.add_child(info)
		content.add_child(row)
	if first:
		var next_id := str(def.get("unlocks", ""))
		if next_id != "":
			add_section("PORTAL UNLOCKED", GameUI.PURPLE)
			add_body_text("%s now answers your level requirement." % str(PortalDB.get_portal(next_id).name), GameUI.TEXT, 16)
	var button := GameUI.button("Return to the Seaside Home", Vector2(430, 54))
	button.pressed.connect(func() -> void:
		var game := get_tree().get_first_node_in_group("game")
		if game and game.has_method("return_to_lobby"):
			close_panel()
			game.call("return_to_lobby", true))
	content.add_child(button)


func _reward_chip(kind: String, text: String, color: Color) -> Control:
	var panel := GameUI.panel(Color("#14262c"), color.darkened(0.3))
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.add_child(GameUI.icon_rect(kind, 24))
	hbox.add_child(GameUI.label(text, 18, color))
	panel.add_child(hbox)
	return panel
