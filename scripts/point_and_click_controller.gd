extends CharacterBody2D
## Port of Unisza' PointAndClickController.cs.
##
## Click anywhere to send the character there. WASD/arrows still work and take
## over the moment a key is pressed, so the two schemes never fight.
##
## Unity drove a dynamic Rigidbody2D by writing linearVelocity every frame. That
## is CharacterBody2D + move_and_slide() here, which keeps walls solid without
## a physics body fighting the script for the transform.

@export var speed := 3.0
## Distance at which the character stops and considers itself arrived.
@export var arrive_threshold := 0.15
## Press a movement key to cancel the current walk and steer manually.
@export var manual_input_cancels_click := true
@export var show_click_marker := true
@export var click_marker_color := Color(1.0, 0.95, 0.6, 0.9)
@export var marker_lifetime := 0.6
## Seconds without getting measurably closer before the walk is cancelled.
@export var stuck_timeout := 1.1

@export var visual_path: NodePath

const DIRECTION_SOUTH := 0
const DIRECTION_NORTH := 1
const DIRECTION_EAST := 2
const DIRECTION_WEST := 3

var _target := Vector2.ZERO
var _has_target := false
var _last_distance := 0.0
var _no_progress_time := 0.0

var _marker: Sprite2D
var _marker_life := 0.0
var _visual: Node2D


func _ready() -> void:
	add_to_group("player")
	if visual_path and not visual_path.is_empty():
		_visual = get_node_or_null(visual_path)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Use the event's own position rather than the live cursor so the click
		# maps correctly even when input is synthesised (tests, touch, remote).
		var world: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * event.position
		_set_target(world)
		if show_click_marker:
			_spawn_marker(world)
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	var dir := _desired_direction()
	velocity = dir * speed
	move_and_slide()

	_update_visual(dir)
	_track_progress(delta)
	_update_marker(delta)


func _set_target(world: Vector2) -> void:
	_target = world
	_has_target = true
	_last_distance = 0.0
	_no_progress_time = 0.0


func _desired_direction() -> Vector2:
	var manual := _read_manual()
	if manual.length_squared() > 0.0001:
		if manual_input_cancels_click:
			_has_target = false
		return manual.normalized()

	if not _has_target:
		return Vector2.ZERO

	var delta := _target - global_position
	var distance := delta.length()
	if distance <= arrive_threshold:
		_has_target = false
		return Vector2.ZERO

	return delta / distance


static func _read_manual() -> Vector2:
	# Godot is Y-down, so "up" is the negative-Y slot.
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


## Matches the Unity controller: 0 = South, 1 = North, 2 = East, 3 = West.
func _update_visual(dir: Vector2) -> void:
	if not _visual:
		return
	var moving := dir.length_squared() > 0.0001
	if moving:
		var d := DIRECTION_SOUTH
		if absf(dir.x) > absf(dir.y):
			d = DIRECTION_EAST if dir.x > 0.0 else DIRECTION_WEST
		else:
			# Godot is Y-down: positive Y walks south.
			d = DIRECTION_SOUTH if dir.y > 0.0 else DIRECTION_NORTH
		if _visual.has_method("set_facing"):
			_visual.call("set_facing", d, moving)
	elif _visual.has_method("set_facing"):
		_visual.call("set_facing", -1, false)


## Walls have no navmesh here, so steering straight at the target can wedge the
## character against geometry. Cancel the walk if it stops making progress.
func _track_progress(delta: float) -> void:
	if not _has_target:
		_last_distance = 0.0
		_no_progress_time = 0.0
		return

	var distance := global_position.distance_to(_target)

	if _last_distance > 0.0 and _last_distance - distance < 0.01:
		_no_progress_time += delta
	else:
		_no_progress_time = 0.0

	_last_distance = distance

	if _no_progress_time >= stuck_timeout:
		_has_target = false
		_no_progress_time = 0.0


func _spawn_marker(world: Vector2) -> void:
	if not _marker:
		_marker = _build_marker()
	_marker.global_position = world
	_marker.modulate = click_marker_color
	_marker_life = marker_lifetime


func _update_marker(delta: float) -> void:
	if not _marker:
		return
	if _marker_life <= 0.0:
		if _marker.visible:
			_marker.visible = false
		return

	_marker_life -= delta
	var c := _marker.modulate
	c.a = clampf(_marker_life / marker_lifetime, 0.0, 1.0) * click_marker_color.a
	_marker.modulate = c


## A tiny generated ring; avoids shipping another texture for one decal.
func _build_marker() -> Sprite2D:
	const SIZE := 32
	var image := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var radius := SIZE * 0.5 - 2.0
	var centre := Vector2(SIZE * 0.5, SIZE * 0.5)

	for y in SIZE:
		for x in SIZE:
			var d := Vector2(x, y).distance_to(centre)
			var a := 255.0 if absf(d - radius) <= 2.0 else 0.0
			image.set_pixel(x, y, Color(1, 1, 1, a / 255.0))

	var sr := Sprite2D.new()
	sr.name = "ClickMarker"
	sr.texture = ImageTexture.create_from_image(image)
	sr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# The ring is drawn in texture pixels; the world is 32 px per unit.
	sr.scale = Vector2.ONE / 32.0
	sr.z_index = 500
	sr.z_as_relative = false
	get_tree().root.call_deferred("add_child", sr)
	return sr