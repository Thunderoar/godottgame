class_name MenuPanel
extends ModalBase
## In-game menu opened from the top-right Menu button. It exposes Settings and
## a safe return-to-title path.

func _ready() -> void:
	_panel_size = Vector2(560, 420)
	super._ready()


func open_menu() -> void:
	open_panel("Menu")


func _rebuild() -> void:
	_clear_content()
	add_body_text("Village life continues while menus are open. Returning to the title saves your progress.", GameUI.MUTED, 14)
	content.add_child(GameUI.spacer(6))
	var resume := GameUI.button("Resume", Vector2(320, 52))
	resume.pressed.connect(close_panel)
	content.add_child(resume)
	var controller := get_tree().get_first_node_in_group("game") as Game
	var editing: bool = is_instance_valid(controller) and controller.world is Lobby and controller.world._settlement_editor.active
	var build := GameUI.button("Finish building" if editing else "Build settlement", Vector2(320, 48))
	build.disabled = not is_instance_valid(controller) or not controller.world is Lobby or is_instance_valid(controller.home_interior)
	build.pressed.connect(func() -> void:
		close_panel()
		if is_instance_valid(controller):
			controller.toggle_build_mode())
	content.add_child(build)
	var book := GameUI.button("BESUT Field Guide", Vector2(320, 48))
	book.pressed.connect(func() -> void:
		close_panel()
		if is_instance_valid(controller):
			controller.open_field_guide())
	content.add_child(book)
	var settings := GameUI.button("Settings", Vector2(320, 52))
	settings.pressed.connect(func() -> void:
		var game := get_tree().get_first_node_in_group("game")
		close_panel()
		if game != null and game.has_method("open_settings"):
			game.call("open_settings"))
	content.add_child(settings)
	var help := GameUI.button("Show current mission tips", Vector2(320, 44))
	help.pressed.connect(func() -> void:
		close_panel()
		var hud := get_tree().get_first_node_in_group("hud") as GameHUD
		if hud:
			hud.start_tutorial())
	content.add_child(help)
	var title := GameUI.button("Return to Title", Vector2(320, 52))
	title.pressed.connect(func() -> void:
		var game := get_tree().get_first_node_in_group("game")
		close_panel()
		if game != null and game.has_method("return_to_title"):
			game.call("return_to_title", false))
	content.add_child(title)
