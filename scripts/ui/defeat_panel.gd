class_name DefeatPanel
extends ModalBase
## Death report. Death no longer kills the pet or demands a revival item: the
## player wakes in the recovery ward and must stay there until fully healed.

var lost_text := ""
var pet_name := ""
var dungeon_name := ""


func _ready() -> void:
	super._ready()


func show_defeat(portal_name: String, lost: String, companion: String) -> void:
	dungeon_name = portal_name
	lost_text = lost
	pet_name = companion
	open_panel("The Dark Takes Its Due")


func _rebuild() -> void:
	_clear_content()
	add_body_text("You fell in %s." % dungeon_name, GameUI.RED, 22)
	add_body_text("The tide carries you back to the cottage. Your companion is shaken, but will recover.", GameUI.MUTED, 15)
	content.add_child(GameUI.spacer(6))
	add_section("LOST ON THE EXPEDITION", GameUI.RED)
	add_body_text(lost_text if lost_text != "" else "No unbanked loot was carried.", GameUI.TEXT, 15)
	add_section("RECOVERY", GameUI.GOLD)
	add_body_text("• You wake inside the cottage recovery ward.\n• The ward holds you there until health is fully restored.\n• Healing potions are optional and only speed recovery.\n• %s is safe and will rejoin you automatically.\n• The unfinished portal resets; cleared portals remain cleared." % pet_name, GameUI.TEXT, 15)
	var button := GameUI.button("Wake in the Recovery Ward", Vector2(360, 52))
	button.pressed.connect(func() -> void:
		var game := get_tree().get_first_node_in_group("game")
		if game and game.has_method("return_to_lobby"):
			close_panel()
			game.call("return_to_lobby", true))
	content.add_child(button)
