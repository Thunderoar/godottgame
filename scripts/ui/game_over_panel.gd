class_name GameOverPanel
extends ModalBase
## Locked game-over screen. It cannot be dismissed with Escape or the normal
## close path; the only exit is returning to the title screen.

var _locked := false
var _reason := ""


func _ready() -> void:
	_panel_size = Vector2(700, 420)
	super._ready()


func show_game_over(reason: String) -> void:
	_locked = true
	open_panel("Game Over")
	_reason = reason
	_rebuild()
	_close_button.visible = false


func _rebuild() -> void:
	_clear_content()
	add_body_text("THE VILLAGE HAS FALLEN", GameUI.RED, 30)
	var text := _reason if _reason != "" else "The forest is gone. There is nothing left to defend."
	add_body_text(text, GameUI.TEXT, 18)
	add_body_text("No mature trees or planted saplings remain. The earth has dried and the sea is poisoned.", GameUI.MUTED, 14)
	content.add_child(GameUI.spacer(10))
	var button := GameUI.button("Return to Title", Vector2(320, 52))
	button.pressed.connect(func() -> void:
		var game := get_tree().get_first_node_in_group("game")
		if game != null and game.has_method("return_to_title"):
			game.call("return_to_title", true))
	content.add_child(button)


func close_panel() -> void:
	if _locked:
		return
	super.close_panel()


func force_close() -> void:
	_locked = false
	visible = false
	_clear_content()
