class_name MissionNPC
extends Interactable

func _ready() -> void:
	super._ready()
	add_to_group("mission_npc")
	prompt = "View Missions"
	var sprite := Sprite2D.new()
	sprite.texture = PixelArt.npc_texture("mission_guide")
	sprite.scale = Vector2.ONE * PixelArt.PX
	sprite.position = Vector2(0, -0.55)
	add_child(sprite)
	var question := Label.new()
	question.text = "?"
	question.scale = Vector2.ONE * PixelArt.PX
	question.position = Vector2(-0.22, -2.0)
	question.add_theme_font_size_override("font_size", 34)
	question.add_theme_color_override("font_color", Color("#f3c8ff"))
	question.add_theme_color_override("font_shadow_color", Color("#291132"))
	question.z_as_relative = false
	question.z_index = 720
	add_child(question)

func interact(_player: Node) -> void:
	var game := get_tree().get_first_node_in_group("game") as Game
	if is_instance_valid(game):
		game.open_missions()

func _unhandled_input(event: InputEvent) -> void:
	var point := Vector2.ZERO
	var pressed := false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		point = event.position
		pressed = true
	elif event is InputEventScreenTouch and event.pressed:
		point = event.position
		pressed = true
	var game := get_tree().get_first_node_in_group("game") as Game
	if pressed and is_instance_valid(game) and not game._input_locked and game.world == get_parent() and not is_instance_valid(game.home_interior):
		var local := to_local(get_canvas_transform().affine_inverse() * point)
		if Rect2(-0.8, -2.0, 1.6, 2.8).has_point(local):
			interact(game.player())
			get_viewport().set_input_as_handled()
