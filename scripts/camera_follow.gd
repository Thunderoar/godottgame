extends Node2D
## Port of Cainos' CameraFollow.cs
## Smoothly lerps the camera towards the target, keeping the initial offset.

@export var target_path: NodePath
@export var lerp_speed := 1.0

var target: Node2D
var offset := Vector2.ZERO


func _ready() -> void:
	if not target and target_path and not target_path.is_empty():
		target = get_node_or_null(target_path) as Node2D
	if target:
		offset = global_position - target.global_position


func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	global_position = global_position.lerp(target.global_position + offset, lerp_speed * delta)