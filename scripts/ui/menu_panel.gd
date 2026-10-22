class_name MenuPanel
extends ModalBase
## In-game menu opened from the top-right Menu button. It exposes Settings and
## a safe return-to-title path.

func _ready() -> void:
	_panel_size = Vector2(560, 360)
	super._ready()


func open_menu() -> void:
	open_panel("Menu")


func _rebuild() -> void:
	_clear_content()
	add_body_text("Pause the tide. Your progress is kept when you return to the title.", GameUI.MUTED, 14)
	content.add_child(GameUI.spacer(6))
	var resume := GameUI.button("Resume", Vector2(320, 52))
	resume.pressed.connect(close_panel)
	content.add_child(resume)
	var settings := GameUI.button("Settings", Vector2(320, 52))
	settings.pressed.connect(func() -> void:
		var game := get_tree().get_first_node_in_group("game")
		close_panel()
		if game != null and game.has_method("open_settings"):
			game.call("open_settings"))
	content.add_child(settings)
	var title := GameUI.button("Return to Title", Vector2(320, 52))
	title.pressed.connect(func() -> void:
		var game := get_tree().get_first_node_in_group("game")
		close_panel()
		if game != null and game.has_method("return_to_title"):
			game.call("return_to_title", false))
	content.add_child(title)
