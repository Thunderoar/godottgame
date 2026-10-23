class_name StructureRepairPoint
extends Interactable
## One reachable interaction at the doorway or beside each fence segment.

var target: SettlementTarget


func _ready() -> void:
	show_marker = false
	interact_radius = 1.9
	add_to_group("structure_repairs")
	super._ready()


func is_interactable_available() -> bool:
	if not is_instance_valid(target) or GameState.game_over_active:
		return false
	var entry := GameState.structure_state(target.structure_id)
	return not entry.is_empty() and int(entry.get("health", 0)) < int(entry.get("maximum", 1))


func get_prompt() -> String:
	return "Betulkan pagar" if target.structure_kind == "fence" else "Betulkan rumah"


func interact(player: Node) -> void:
	if not is_interactable_available() or not is_instance_valid(player) or not player is Node2D:
		return
	if global_position.distance_to(player.global_position) > interact_radius:
		return
	var result := GameState.repair_structure(target.structure_id)
	if bool(result.get("ok", false)):
		Vfx.ring(global_position, 0.8, Color("#83dfb2"), 0.5)
