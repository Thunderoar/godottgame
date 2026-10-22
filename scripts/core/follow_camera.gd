class_name FollowCamera
extends Camera2D
## Smooth camera with look-ahead and a decaying hit shake. Each world owns one
## so its map bounds can differ between the lobby and a portal dungeon.
##
## ZOOM is an integer multiple of 32 (one art pixel = exactly 2 screen pixels at
## 64) so pixels never shimmer while panning; the camera position additionally
## snaps to the art grid. See docs/VISUAL_OVERHAUL.md §2 for the decision.

const ZOOM_SCALE := 64.0
const LOOKAHEAD_UNITS := 1.15
const ART_GRID := 32.0

var target: Node2D
var bounds := Rect2(0, 0, 64, 40)
var follow_speed := 6.0
var shake_amount := 0.0
var shake_time := 0.0
var _rng := RandomNumberGenerator.new()
var _look := Vector2.ZERO


func _ready() -> void:
	add_to_group("camera")
	_rng.randomize()
	zoom = Vector2(ZOOM_SCALE, ZOOM_SCALE)
	position_smoothing_enabled = false
	limit_left = int(bounds.position.x)
	limit_top = int(bounds.position.y)
	limit_right = int(bounds.position.x + bounds.size.x)
	limit_bottom = int(bounds.position.y + bounds.size.y)
	make_current()


func _process(delta: float) -> void:
	if is_instance_valid(target):
		var aim := target.global_position + Vector2(0, -1.0)
		# Look a little ahead of the player's facing so the view leads movement.
		var facing_variant: Variant = target.get("facing")
		if facing_variant != null and not GameSettings.reduce_motion():
			var facing: Vector2 = facing_variant
			if facing.length_squared() > 0.2:
				_look = _look.lerp(facing.normalized() * LOOKAHEAD_UNITS, clampf(delta * 3.0, 0.0, 1.0))
			else:
				_look = _look.lerp(Vector2.ZERO, clampf(delta * 3.0, 0.0, 1.0))
		aim += _look
		global_position = global_position.lerp(aim, clampf(delta * follow_speed, 0.0, 1.0))
		# Snap to the art grid so 1 art pixel = exactly 2 aligned screen pixels.
		global_position = (global_position * ART_GRID).round() / ART_GRID
	if shake_time > 0.0:
		shake_time = maxf(0.0, shake_time - delta)
		offset = Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1)) * shake_amount * (shake_time / maxf(0.01, shake_time + delta))
	else:
		offset = offset.lerp(Vector2.ZERO, clampf(delta * 12.0, 0.0, 1.0))


func shake(amount: float = 0.16, duration: float = 0.2) -> void:
	# The screen_shake GameSetting existed but nothing read it; this camera now
	# honours it, and reduce-motion disables shake entirely.
	if GameSettings.reduce_motion() or not GameSettings.screen_shake():
		return
	shake_amount = amount
	shake_time = duration
