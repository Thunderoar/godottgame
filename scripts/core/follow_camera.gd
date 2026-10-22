class_name FollowCamera
extends Camera2D
## Smooth camera with a small hit shake. Each world owns one so its map bounds
## and zoom can differ between the lobby and a portal dungeon.

var target: Node2D
var bounds := Rect2(0, 0, 64, 40)
var follow_speed := 6.0
var shake_amount := 0.0
var shake_time := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("camera")
	_rng.randomize()
	zoom = Vector2(38, 38)
	position_smoothing_enabled = false
	limit_left = int(bounds.position.x)
	limit_top = int(bounds.position.y)
	limit_right = int(bounds.position.x + bounds.size.x)
	limit_bottom = int(bounds.position.y + bounds.size.y)
	make_current()


func _process(delta: float) -> void:
	if is_instance_valid(target):
		global_position = global_position.lerp(target.global_position + Vector2(0, -1.0), clampf(delta * follow_speed, 0.0, 1.0))
	if shake_time > 0.0:
		shake_time = maxf(0.0, shake_time - delta)
		offset = Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1)) * shake_amount * (shake_time / maxf(0.01, shake_time + delta))
	else:
		offset = offset.lerp(Vector2.ZERO, clampf(delta * 12.0, 0.0, 1.0))


func shake(amount: float = 0.16, duration: float = 0.2) -> void:
	shake_amount = amount
	shake_time = duration
