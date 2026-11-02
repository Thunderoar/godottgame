class_name DialogueWorldHold
extends Node
## Hold gameplay callbacks, never the world tree. Shaders, ambience, UI and idle
## visuals keep running; callback ownership is restored exactly once on release.
var world: Node2D
var _records: Dictionary = {}
var _released := false

func _ready() -> void:
	get_tree().node_added.connect(_node_added)
	_capture_tree(world)

func _capture_tree(node: Node) -> void:
	_capture(node)
	for child in node.get_children(): _capture_tree(child)

func _node_added(node: Node) -> void:
	if _released or not is_instance_valid(world) or not world.is_ancestor_of(node): return
	if node.is_node_ready(): _capture(node)
	else: node.ready.connect(_capture.bind(node),CONNECT_ONE_SHOT)

func _capture(node: Node) -> void:
	if _released or not is_instance_valid(node) or _records.has(node.get_instance_id()): return
	var simulation := node is ForestTree or node is HouseDefense or node is RubbishSystem or node is RubbishPiece or node is RealmWildPet or node is ResourcePile or node is UrchinArrival
	_records[node.get_instance_id()] = {"node":weakref(node),"physics":node.is_physics_processing(),"process":node.is_processing(),"simulation":simulation}
	node.set_physics_process(false)
	if simulation: node.set_process(false)
	if node is CharacterBody2D: node.velocity = Vector2.ZERO
	if node is Player:
		node.clear_attack_request()
		if is_instance_valid(node._visual):
			node._visual.end_attack()
			node._visual.set_motion(Vector2.ZERO,GameState.move_speed())
		if is_instance_valid(node._combat_visuals): node._combat_visuals.cancel()
		if is_instance_valid(node._combat_motion): node._combat_motion.cancel()

func release() -> void:
	if _released: return
	_released = true
	if is_inside_tree() and get_tree().node_added.is_connected(_node_added): get_tree().node_added.disconnect(_node_added)
	for record in _records.values():
		var node: Node = record.node.get_ref()
		if not is_instance_valid(node) or node.is_queued_for_deletion(): continue
		node.set_physics_process(bool(record.physics))
		if bool(record.simulation): node.set_process(bool(record.process))
	_records.clear()

func _exit_tree() -> void:
	release()

static func protects(actor: Node) -> bool:
	if not is_instance_valid(actor) or not actor.is_inside_tree(): return false
	var game := actor.get_tree().get_first_node_in_group("game") as Game
	return is_instance_valid(game) and game.dialogue_holding() and (actor == game.world or game.world.is_ancestor_of(actor))
