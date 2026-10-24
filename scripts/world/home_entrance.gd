class_name HomeEntrance
extends Interactable

func _ready() -> void:
	super._ready()
	prompt = "Enter Home"
	interact_radius = 2.5

func is_interactable_available() -> bool:
	return available and not GameState.game_over_active and int(GameState.structure_state("cottage").get("health", 0)) > 0

func _unhandled_input(event: InputEvent) -> void:
	var point := Vector2.ZERO
	var pressed := false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		point = event.position
		pressed = true
	elif event is InputEventScreenTouch and event.pressed:
		point = event.position
		pressed = true
	if not pressed or not is_interactable_available():
		return
	var game := get_tree().get_first_node_in_group("game") as Game
	if not is_instance_valid(game) or game._input_locked or not game.world is Lobby or game.home_interior != null or game.world._settlement_editor.active:
		return
	if get_parent().get_parent() != game.world:
		return
	var local: Vector2 = get_parent().to_local(get_canvas_transform().affine_inverse() * point)
	if Rect2(-4.5, -7.2, 9, 8.4).has_point(local):
		interact(game.player())
		get_viewport().set_input_as_handled()

func interact(_player: Node) -> void:
	var game := get_tree().get_first_node_in_group("game") as Game
	if is_instance_valid(game) and is_interactable_available():
		game.enter_home()
