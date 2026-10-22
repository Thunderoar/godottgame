class_name TouchJoystick
extends Control
## On-screen joystick that writes into the same InputMap actions as WASD.
## Supports a finger and a mouse; releasing always clears every axis.

@export var radius := 72.0
@export var knob_radius := 30.0
@export var deadzone := 0.14

var _value := Vector2.ZERO
var _touch_id := -1
var _mouse_active := false
var _knob := Vector2.ZERO
var _active := false


func _ready() -> void:
	custom_minimum_size = Vector2(190, 190)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	set_process_input(true)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not _active:
			_touch_id = event.index
			_begin(_local(event.position))
			accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not _active:
			_mouse_active = true
			_begin(_local(event.position))
			accept_event()
		elif not event.pressed and _mouse_active:
			_end()
			accept_event()


func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event is InputEventScreenDrag and event.index == _touch_id:
		_move(_local(event.position))
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and not event.pressed and event.index == _touch_id:
		_end()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _mouse_active:
		_move(_local(event.position))
		get_viewport().set_input_as_handled()


func _begin(local_pos: Vector2) -> void:
	_active = true
	_move(local_pos)


func _move(local_pos: Vector2) -> void:
	var centre := size * 0.5
	var offset := local_pos - centre
	var length := offset.length()
	var max_length := minf(radius, maxf(24.0, size.x * 0.5 - 8.0))
	if length > max_length:
		offset = offset / length * max_length
		length = max_length
	var raw := offset / max_length
	if raw.length() < deadzone:
		raw = Vector2.ZERO
	_value = raw.limit_length(1.0)
	_knob = raw * minf(max_length, radius)
	_apply_actions()
	queue_redraw()


func _end() -> void:
	_active = false
	_touch_id = -1
	_mouse_active = false
	_value = Vector2.ZERO
	_knob = Vector2.ZERO
	_release_actions()
	queue_redraw()


func _apply_actions() -> void:
	Input.action_press("move_left", maxf(0.0, -_value.x))
	Input.action_press("move_right", maxf(0.0, _value.x))
	Input.action_press("move_up", maxf(0.0, -_value.y))
	Input.action_press("move_down", maxf(0.0, _value.y))


func _release_actions() -> void:
	for action in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(action)


func _local(viewport_position: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * viewport_position


func _draw() -> void:
	var centre := size * 0.5
	var ring := minf(radius, size.x * 0.5 - 4.0)
	draw_circle(centre + Vector2(2, 4), ring + 3.0, Color(0, 0, 0, 0.24))
	draw_circle(centre, ring + 3.0, Color(0.04, 0.09, 0.11, 0.66))
	draw_arc(centre, ring, 0, TAU, 64, Color(0.57, 0.78, 0.76, 0.55), 3.0, true)
	draw_arc(centre, ring * 0.72, 0, TAU, 48, Color(0.57, 0.78, 0.76, 0.16), 2.0, true)
	# Four small directional ticks.
	for dir: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var a: Vector2 = centre + dir * (ring - 7.0)
		var b: Vector2 = centre + dir * (ring - 16.0)
		draw_line(a, b, Color(0.72, 0.9, 0.86, 0.5), 2.0, true)
	var knob_pos := centre + _knob.limit_length(ring - knob_radius - 4.0)
	draw_circle(knob_pos + Vector2(1, 3), knob_radius + 1.0, Color(0, 0, 0, 0.32))
	draw_circle(knob_pos, knob_radius, Color(0.14, 0.30, 0.33, 0.96))
	draw_circle(knob_pos - Vector2(2, 3), knob_radius - 4.0, Color(0.25, 0.49, 0.51, 0.92))
	draw_arc(knob_pos, knob_radius, 0, TAU, 40, Color(0.71, 0.93, 0.88, 0.72), 2.0, true)
	if _active:
		draw_arc(centre, ring + 6.0, 0, TAU, 64, Color(0.94, 0.78, 0.38, 0.38), 2.0, true)
