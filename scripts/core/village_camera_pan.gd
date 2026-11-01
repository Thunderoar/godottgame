extends Node
## Village-only inspection gesture. It never moves Adam or pauses village life.

const DRAG_THRESHOLD := 12.0
var camera: FollowCamera
var _pointer := -2
var _start := Vector2.ZERO
var _last := Vector2.ZERO
var _dragging := false

func _ready() -> void:
	camera = get_parent() as FollowCamera
	var game := get_tree().get_first_node_in_group("game") as Game
	if not is_instance_valid(game) or not is_instance_valid(game.hud):
		queue_free()
		return

func _can_pan() -> bool:
	var game := get_tree().get_first_node_in_group("game") as Game
	return is_instance_valid(game) and is_instance_valid(camera) and game.world == camera.get_parent() and game.world is Lobby and not game.world._settlement_editor.active and not is_instance_valid(game.home_interior) and not (game._input_locked or game._transitioning or game._story_active or game._sailing or game._game_over or game._defeat_pending or game._developer_paused or game.hud.any_modal_open()) and is_instance_valid(camera.target) and not camera.target.dead and not camera.target.sleeping

func _unhandled_input(event: InputEvent) -> void:
	if not _can_pan() or _pointer != -2: return
	if event is InputEventScreenTouch and event.pressed:
		_begin(event.position, event.index)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_begin(event.position, -1)

func _begin(at: Vector2, pointer: int) -> void:
	_pointer = pointer
	_start = at
	_last = at
	_dragging = false

func _input(event: InputEvent) -> void:
	if _pointer == -2: return
	if not _can_pan():
		reset_pan()
		return
	if event is InputEventScreenDrag and event.index == _pointer:
		_drag(event.position)
	elif event is InputEventMouseMotion and _pointer == -1:
		_drag(event.position)
	elif (event is InputEventScreenTouch and not event.pressed and event.index == _pointer) or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and _pointer == -1):
		if _dragging: get_viewport().set_input_as_handled()
		reset_pan()

func _drag(at: Vector2) -> void:
	if not _dragging and at.distance_to(_start) < DRAG_THRESHOLD: return
	if not _dragging:
		camera.pan_center = camera.get_screen_center_position()
		camera.manual_pan = true
		_dragging = true
	var half_view := get_viewport().get_visible_rect().size / camera.zoom * 0.5
	var minimum := camera.bounds.position + half_view
	var maximum := camera.bounds.end - half_view
	var wanted := camera.pan_center - (at - _last) / camera.zoom
	for axis in 2:
		wanted[axis] = clampf(wanted[axis], minimum[axis], maximum[axis]) if minimum[axis] <= maximum[axis] else camera.bounds.get_center()[axis]
	camera.pan_center = wanted
	camera.global_position = wanted
	camera.reset_physics_interpolation()
	camera.force_update_scroll()
	_last = at
	get_viewport().set_input_as_handled()

func _physics_process(_delta: float) -> void:
	if not _can_pan() or Input.get_vector("move_left","move_right","move_up","move_down").length_squared() > 0 or Input.is_action_pressed("attack"):
		reset_pan()

func reset_pan() -> void:
	_pointer = -2
	_dragging = false
	if is_instance_valid(camera): camera.manual_pan = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT: reset_pan()

func _exit_tree() -> void:
	reset_pan()
