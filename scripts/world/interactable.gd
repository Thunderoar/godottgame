class_name Interactable
extends Area2D
## Base class for things the player can talk to, sleep in, loot or enter.
## Players find these through the "interactable" group and ask for a prompt.

@export var prompt := "Interact"
@export var interact_radius := 1.9
@export var show_marker := true

var available := true
var marker: Sprite2D
var _bob := 0.0


func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 0
	collision_mask = 0
	monitoring = false
	monitorable = false
	if show_marker:
		_make_marker()


func _process(delta: float) -> void:
	if marker == null:
		return
	_bob += delta
	marker.position.y = -1.65 + (0.0 if GameSettings.reduce_motion() else sin(_bob * 2.4) * 0.035)
	marker.visible = available
	marker.modulate.a = 0.65


func _make_marker() -> void:
	marker = Sprite2D.new()
	marker.name = "InteractionMarker"
	marker.texture = PixelArt.interaction_marker_texture()
	marker.scale = Vector2.ONE * PixelArt.PX
	marker.position = Vector2(0, -1.65)
	marker.z_as_relative = false
	marker.z_index = 700
	add_child(marker)


func get_prompt() -> String:
	return prompt


func is_interactable_available() -> bool:
	return available


func interact(_player: Node) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if not available: return
	var at := Vector2.ZERO
	if event is InputEventScreenTouch and event.pressed: at = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed: at = event.position
	else: return
	var game := get_tree().get_first_node_in_group("game") as Game
	if not is_instance_valid(game) or game._input_locked or game._transitioning or not is_instance_valid(game.world) or not game.world.is_ancestor_of(self): return
	if game.world is Lobby and game.world._settlement_editor.active: return
	var actor := game.player()
	if not is_instance_valid(actor) or actor.dead or actor.sleeping or actor.global_position.distance_to(global_position) > interact_radius: return
	var point := get_canvas_transform().affine_inverse() * at
	if point.distance_to(global_position + Vector2(0,-0.65)) <= 1.05:
		interact(actor)
		get_viewport().set_input_as_handled()
