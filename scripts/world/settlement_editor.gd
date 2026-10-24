class_name SettlementEditor
extends Node2D
## Touch/mouse drag editor for the residential building area.

@export var building_area := Rect2(18.8, 13.8, 26.8, 16.2)

const BORDER_WIDTH := 2.0 * PixelArt.PX
const GRID_WIDTH := PixelArt.PX

var active := false
var placeables: Array[SettlementPlaceable] = []

var _selected: SettlementPlaceable = null
var _dragging := false
var _grab_offset := Vector2.ZERO
var _touch_id := -1


func _ready() -> void:
	z_as_relative = false
	z_index = 900
	set_process_input(true)
	set_process(false)


func register(placeable: SettlementPlaceable) -> void:
	if placeable == null:
		return
	placeables.append(placeable)


func toggle() -> bool:
	active = not active
	if active:
		_enter()
	else:
		_exit()
	return active


func _enter() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		player.set("controls_locked", true)
	GameState.toast_requested.emit("Settlement Editor: drag buildings inside the marked area.", "info")
	set_process(true)
	queue_redraw()


func _exit() -> void:
	var lobby := get_parent() as Lobby
	if lobby:
		lobby.invalidate_resident_routes()
	_finish_drag()
	var player := get_tree().get_first_node_in_group("player")
	if player != null and not bool(player.get("dead")):
		player.set("controls_locked", false)
	set_process(false)
	queue_redraw()


func _process(_delta: float) -> void:
	if active:
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press(_screen_to_world(event.position))
			get_viewport().set_input_as_handled()
		else:
			_release()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _dragging:
		_drag(_screen_to_world(event.position))
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		if event.pressed and _touch_id == -1:
			_touch_id = event.index
			_press(_screen_to_world(event.position))
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == _touch_id:
			_release()
			_touch_id = -1
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == _touch_id:
		_drag(_screen_to_world(event.position))
		get_viewport().set_input_as_handled()


func _screen_to_world(screen_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_pos


func _press(world_pos: Vector2) -> void:
	_finish_drag()
	var hit := _find_at(world_pos)
	if hit == null:
		return
	_selected = hit
	_selected.set_selected(true)
	_grab_offset = world_pos - _selected.global_position
	_dragging = true


func _drag(world_pos: Vector2) -> void:
	if not _dragging or _selected == null:
		return
	var target := world_pos - _grab_offset
	var half := _selected.selection_size * 0.5
	var min_x := building_area.position.x + half.x
	var max_x := building_area.end.x - half.x
	var min_y := building_area.position.y + half.y
	var max_y := building_area.end.y - half.y
	if min_x > max_x:
		min_x = (building_area.position.x + building_area.end.x) * 0.5
		max_x = min_x
	if min_y > max_y:
		min_y = (building_area.position.y + building_area.end.y) * 0.5
		max_y = min_y
	target.x = snappedf(clampf(target.x, min_x, max_x), 0.25)
	target.y = snappedf(clampf(target.y, min_y, max_y), 0.25)
	_selected.global_position = target


func _release() -> void:
	_finish_drag()


func _finish_drag() -> void:
	if _selected != null:
		GameState.set_placeable_position(_selected.placeable_id, _selected.global_position)
		_selected.set_selected(false)
		_selected = null
		var lobby := get_parent() as Lobby
		if lobby:
			lobby.refresh_spatial_layout()
	_dragging = false


func _find_at(world_pos: Vector2) -> SettlementPlaceable:
	for i in range(placeables.size() - 1, -1, -1):
		var placeable := placeables[i]
		if is_instance_valid(placeable) and placeable.contains_world(world_pos):
			return placeable
	return null


func _draw() -> void:
	if not active:
		return
	draw_rect(building_area, Color(0.20, 0.65, 0.38, 0.14))
	draw_rect(building_area, Color(0.55, 0.95, 0.68, 0.82), false, BORDER_WIDTH)
	var x := building_area.position.x
	while x <= building_area.end.x:
		draw_line(Vector2(x, building_area.position.y), Vector2(x, building_area.end.y), Color(0.55, 0.9, 0.68, 0.08), GRID_WIDTH)
		x += 1.0
	var y := building_area.position.y
	while y <= building_area.end.y:
		draw_line(Vector2(building_area.position.x, y), Vector2(building_area.end.x, y), Color(0.55, 0.9, 0.68, 0.08), GRID_WIDTH)
		y += 1.0
