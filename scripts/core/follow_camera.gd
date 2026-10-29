class_name FollowCamera
extends Camera2D
## Smooth camera with look-ahead and a decaying hit shake. Each world owns one
## so its map bounds can differ between the lobby and a portal dungeon.
##
## Nearest-filtered art, interpolated actors and an unsnapped camera preserve
## continuous motion. Zoom is a device preference independent of the HUD.

const ZOOM_SCALE := 38.0
const LOOKAHEAD_UNITS := 1.15

var target: Node2D
var bounds := Rect2(0, 0, 64, 40)
var framing_bounds := Rect2() # Optional encounter framing, released on retreat/exit.
var follow_speed := 6.0
var shake_amount := 0.0
var shake_time := 0.0
var _rng := RandomNumberGenerator.new()
var _look := Vector2.ZERO


func _init() -> void:
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS


func _ready() -> void:
	add_to_group("camera")
	_rng.randomize()
	zoom = Vector2.ONE * GameSettings.camera_zoom()
	position_smoothing_enabled = false
	limit_left = int(bounds.position.x)
	limit_top = int(bounds.position.y)
	limit_right = int(bounds.position.x + bounds.size.x)
	limit_bottom = int(bounds.position.y + bounds.size.y)
	make_current()


func _physics_process(delta: float) -> void:
	var desired_zoom := GameSettings.camera_zoom()
	if framing_bounds.has_area():
		var available := get_viewport_rect().size / (framing_bounds.size + Vector2(2,2))
		desired_zoom = minf(desired_zoom,minf(available.x,available.y))
	zoom = zoom.lerp(Vector2.ONE * desired_zoom, 1.0 - exp(-10.0 * delta))
	if is_instance_valid(target):
		var aim: Vector2 = target.global_position + Vector2(0, -1.0)
		# Look a little ahead of the player's facing so the view leads movement.
		var facing_variant: Variant = target.get("facing")
		if facing_variant != null and not GameSettings.reduce_motion():
			var facing: Vector2 = facing_variant
			if facing.length_squared() > 0.2:
				_look = _look.lerp(facing.normalized() * LOOKAHEAD_UNITS, clampf(delta * 3.0, 0.0, 1.0))
			else:
				_look = _look.lerp(Vector2.ZERO, clampf(delta * 3.0, 0.0, 1.0))
		if GameSettings.reduce_motion():
			_look = _look.move_toward(Vector2.ZERO, delta * 6.0)
		aim += _look
		if framing_bounds.has_area(): aim = framing_bounds.get_center()
		global_position = global_position.lerp(aim, 1.0 - exp(-delta * follow_speed))
	if GameSettings.reduce_motion() or not GameSettings.screen_shake():
		shake_time = 0.0
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
	shake_amount = minf(amount, 0.08)
	shake_time = duration
