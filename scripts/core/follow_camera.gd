class_name FollowCamera
extends Camera2D
## Smooth camera with look-ahead and a decaying hit shake. Each world owns one
## so its map bounds can differ between the lobby and a portal dungeon.
##
## Default zoom keeps the original 2:1 pixel-art scale. World follow remains
## continuous so entities never advance in grid-sized jumps.

const ZOOM_SCALE := 64.0
const ZOOM_MIN := 32.0
const ZOOM_MAX := 80.0
const ZOOM_STEP := 4.0
const LOOKAHEAD_UNITS := 1.15

var target: Node2D
var bounds := Rect2(0, 0, 64, 40)
var follow_speed := 6.0
var shake_amount := 0.0
var shake_time := 0.0
var _rng := RandomNumberGenerator.new()
var _look := Vector2.ZERO
var _target_zoom := ZOOM_SCALE


func _ready() -> void:
	add_to_group("camera")
	_rng.randomize()
	_target_zoom = GameSettings.camera_zoom()
	zoom = Vector2(_target_zoom, _target_zoom)
	position_smoothing_enabled = false
	set_process_unhandled_input(true)
	GameSettings.changed.connect(_on_setting_changed)
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
	zoom = zoom.lerp(Vector2(_target_zoom, _target_zoom), clampf(delta * 8.0, 0.0, 1.0))
	if shake_time > 0.0:
		shake_time = maxf(0.0, shake_time - delta)
		offset = Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1)) * shake_amount * (shake_time / maxf(0.01, shake_time + delta))
	else:
		offset = offset.lerp(Vector2.ZERO, clampf(delta * 12.0, 0.0, 1.0))


func _unhandled_input(event: InputEvent) -> void:
	var direction := 0.0
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			direction = 1.0
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			direction = -1.0
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_PLUS, KEY_EQUAL, KEY_KP_ADD]:
			direction = 1.0
		elif event.keycode in [KEY_MINUS, KEY_KP_SUBTRACT]:
			direction = -1.0
	if is_zero_approx(direction):
		return
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null and hud.has_method("any_modal_open") and bool(hud.call("any_modal_open")):
		return
	step_zoom(direction)
	get_viewport().set_input_as_handled()


func step_zoom(direction: float) -> void:
	if is_zero_approx(direction):
		return
	set_zoom_scale(_target_zoom + signf(direction) * ZOOM_STEP)


func set_zoom_scale(value: float, persist: bool = true) -> void:
	_target_zoom = clampf(value, ZOOM_MIN, ZOOM_MAX)
	if persist:
		GameSettings.set_camera_zoom(_target_zoom)


func _on_setting_changed(key: String) -> void:
	if key == "camera_zoom":
		_target_zoom = clampf(GameSettings.camera_zoom(), ZOOM_MIN, ZOOM_MAX)


func shake(amount: float = 0.16, duration: float = 0.2) -> void:
	# The screen_shake GameSetting existed but nothing read it; this camera now
	# honours it, and reduce-motion disables shake entirely.
	if GameSettings.reduce_motion() or not GameSettings.screen_shake():
		return
	shake_amount = amount
	shake_time = duration
