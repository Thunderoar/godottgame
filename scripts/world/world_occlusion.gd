class_name WorldOcclusion
extends Node
## Fade only obstructing art, leaving collision, damage tints and lighting intact.
const FADED_ALPHA := 0.25
const FADE_RATE := 5.0
var world: Node2D
var sprites: Array[Sprite2D] = []
var _baseline: Dictionary = {}

func _ready() -> void:
	world = get_parent() as Node2D
	_collect(world)

func _collect(node: Node) -> void:
	if node is Player or node is Pet or node is Enemy or node is Resident or node is Interactable:
		return
	if node is Sprite2D and node.texture != null:
		var bounds: Rect2 = node.global_transform * node.get_rect()
		if bounds.size.y >= 0.9 and bounds.size.x >= 0.5 and bounds.get_area() < 160.0 and node.z_index >= 0:
			sprites.append(node)
			_baseline[node.get_instance_id()] = node.self_modulate.a
	for child in node.get_children():
		_collect(child)

func obscures(sprite: Sprite2D, player: Player) -> bool:
	# A passenger stands on the ship; its sails are not scenery behind them.
	if sprite.get_meta("passenger_onboard", false):
		return false
	if not sprite.is_visible_in_tree() or player.global_position.y >= sprite.global_position.y + 0.1:
		return false
	var bounds: Rect2 = sprite.global_transform * sprite.get_rect()
	for height in [0.25, 0.65, 1.0]:
		var point := player.global_position - Vector2(0, height)
		if bounds.has_point(point) and sprite.is_pixel_opaque(sprite.to_local(point)):
			return true
	return false

func _process(delta: float) -> void:
	var game := get_tree().get_first_node_in_group("game") as Game
	var player := game.player() if is_instance_valid(game) and game.world == world else null
	for sprite in sprites:
		if not is_instance_valid(sprite) or sprite.is_queued_for_deletion():
			continue
		var base := float(_baseline.get(sprite.get_instance_id(), 1.0))
		var target := base * FADED_ALPHA if is_instance_valid(player) and obscures(sprite, player) else base
		sprite.self_modulate.a = move_toward(sprite.self_modulate.a, target, delta * FADE_RATE)
