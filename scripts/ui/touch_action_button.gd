class_name TouchActionButton
extends Control
## A large circular touch target that presses an InputMap action. The gameplay
## code never needs to know whether a finger or the keyboard sent the action.

@export var action := "attack"
@export var caption := "Attack"
@export var icon_kind := "sword"
@export var accent := Color("#d8a557")
@export var diameter := 94.0

var _active := false
var _touch_id := -1
var _mouse_active := false
var _pulse := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(diameter, diameter)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	set_process(true)
	set_process_input(true)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not _active:
			_touch_id = event.index
			_press()
			accept_event()
		elif not event.pressed and event.index == _touch_id:
			_release()
			accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not _active:
			_mouse_active = true
			_press()
			accept_event()
		elif not event.pressed and _mouse_active:
			_release()
			accept_event()


func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event is InputEventScreenTouch and not event.pressed and event.index == _touch_id:
		_release()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT and _mouse_active:
		_release()
		get_viewport().set_input_as_handled()


func _press() -> void:
	_active = true
	_pulse = 1.0
	Input.action_press(action)
	queue_redraw()


func _release() -> void:
	_active = false
	_touch_id = -1
	_mouse_active = false
	Input.action_release(action)
	queue_redraw()


func _process(delta: float) -> void:
	_pulse = maxf(0.0, _pulse - delta * 4.0)
	if not _active and Input.is_action_pressed(action):
		_pulse = maxf(_pulse, 0.35)
	queue_redraw()


func cancel() -> void:
	if _active:
		_release()


func _draw() -> void:
	var d := minf(diameter, minf(size.x, size.y))
	var centre := size * 0.5
	var r := d * 0.5 - 5.0
	var pressed := _active or _pulse > 0.2
	var fill := accent.darkened(0.15) if pressed else Color(0.06, 0.13, 0.15, 0.88)
	var ring := accent.lightened(0.25) if pressed else accent.darkened(0.1)
	draw_circle(centre + Vector2(2, 4), r + 2.0, Color(0, 0, 0, 0.28))
	draw_circle(centre, r, fill)
	draw_arc(centre, r, 0, TAU, 56, ring, 3.0, true)
	draw_arc(centre, r - 5.0, 0, TAU, 56, Color(ring.r, ring.g, ring.b, 0.22), 1.0, true)
	if pressed:
		draw_circle(centre, r - 7.0, Color(accent.r, accent.g, accent.b, 0.18))
	# Icon.
	var tex := PixelArt.icon(icon_kind)
	var icon_size := d * 0.43
	var icon_rect := Rect2(centre - Vector2(icon_size, icon_size * 0.5) - Vector2(0, 7), Vector2(icon_size, icon_size))
	draw_texture_rect(tex, icon_rect, true, Color.WHITE)
	# Caption.
	var font := ThemeDB.fallback_font
	var font_size := 12
	var text_size := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var pos := Vector2(centre.x - text_size.x * 0.5, centre.y + d * 0.27)
	draw_string(font, pos, caption, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(0.94, 0.9, 0.8, 0.95))
