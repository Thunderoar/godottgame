class_name TouchActionButton
extends Control
## A large circular touch target that presses an InputMap action. The gameplay
## code never needs to know whether a finger or the keyboard sent the action.
##
## Visual language (see docs/VISUAL_OVERHAUL.md): a crisp 32px icon drawn at an
## integer scale, a ring frame that matches GameUI, press squash + ring flash,
## an optional cooldown sweep (Strike), a count badge (HP/MP potions) and an
## optional keycap hint for desktop players.

@export var action := "attack"
@export var caption := "Attack"
@export var icon_kind := "sword"
@export var accent := Color("#d8a557")
@export var diameter := 94.0

var _active := false
var _touch_id := -1
var _mouse_active := false
var _pulse := 0.0
var _cooldown := 0.0
var _badge := ""
var _enabled := true
var _press_scale := 1.0
var _key_hint := ""


func _ready() -> void:
	custom_minimum_size = Vector2(diameter, diameter)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	set_process(true)
	set_process_input(true)
	_refresh_key_hint()
	queue_redraw()


func _refresh_key_hint() -> void:
	# Source the keycap from the InputMap itself so a rebinding can never leave
	# a stale hint behind.
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var code := (event as InputEventKey).physical_keycode
			if code != 0:
				_key_hint = OS.get_keycode_string(code)
				return
	_key_hint = ""


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
	_press_scale = 0.90
	queue_redraw()


func _release() -> void:
	_active = false
	_touch_id = -1
	_mouse_active = false
	Input.action_release(action)
	_press_scale = 1.0
	queue_redraw()


func _process(delta: float) -> void:
	_pulse = maxf(0.0, _pulse - delta * 4.0)
	if not _active and Input.is_action_pressed(action):
		_pulse = maxf(_pulse, 0.35)
	if _press_scale < 1.0 and not _active:
		_press_scale = minf(1.0, _press_scale + delta * 8.0)
		queue_redraw()


func cancel() -> void:
	if _active:
		_release()


# ------------------------------------------------------------------ public surface

func set_cooldown(fraction: float) -> void:
	# fraction in 0..1: how much of the attack cooldown remains.
	_cooldown = clampf(fraction, 0.0, 1.0)
	queue_redraw()


func set_badge(text: String) -> void:
	if text == _badge:
		return
	_badge = text
	queue_redraw()


func set_icon(kind: String) -> void:
	if kind == icon_kind:
		return
	icon_kind = kind
	_refresh_key_hint()
	queue_redraw()


func set_key_hint(text: String) -> void:
	if text == _key_hint:
		return
	_key_hint = text
	queue_redraw()


func set_contextual(new_caption: String, kind: String) -> void:
	# Used by the Use button to follow the current interaction prompt.
	caption = new_caption
	set_icon(kind)


func set_touch_enabled(value: bool) -> void:
	_enabled = value
	mouse_filter = Control.MOUSE_FILTER_STOP if value else Control.MOUSE_FILTER_IGNORE
	queue_redraw()


# ------------------------------------------------------------------ drawing

func _draw() -> void:
	var d := minf(diameter, minf(size.x, size.y))
	var centre := size * 0.5
	var r := d * 0.5 - 5.0
	var pressed := _active or _pulse > 0.2
	var draw_r := r * _press_scale
	var fill := accent.darkened(0.15) if pressed else Color(0.06, 0.13, 0.15, 0.88)
	var ring := accent.lightened(0.25) if pressed else accent.darkened(0.1)
	# Drop shadow.
	draw_circle(centre + Vector2(2, 4), draw_r + 2.0, Color(0, 0, 0, 0.3))
	# Body + frame rings.
	draw_circle(centre, draw_r, fill)
	draw_arc(centre, draw_r, 0, TAU, 56, ring, 3.0, true)
	draw_arc(centre, draw_r - 5.0, 0, TAU, 56, Color(ring.r, ring.g, ring.b, 0.22), 1.0, true)
	if pressed:
		draw_circle(centre, draw_r - 7.0, Color(accent.r, accent.g, accent.b, 0.18))
	if not _enabled:
		draw_circle(centre, draw_r, Color(0.02, 0.04, 0.05, 0.55))
	# Icon at an integer multiple of its 32px source: no fractional stretching.
	var icon_px := 32 if d < 96.0 else 64
	var tex := PixelArt.icon(icon_kind, 32)
	var icon_rect := Rect2(centre - Vector2(icon_px, icon_px * 0.55) * _press_scale - Vector2(0, 6), Vector2(icon_px, icon_px) * _press_scale)
	if not _enabled:
		draw_texture_rect(tex, icon_rect, true, Color(0.55, 0.6, 0.62, 0.8))
	else:
		draw_texture_rect(tex, icon_rect, true, Color.WHITE)
	# Caption.
	var font := ThemeDB.fallback_font
	var font_size := 12
	var text_size := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var pos := Vector2(centre.x - text_size.x * 0.5, centre.y + d * 0.27)
	draw_string(font, pos, caption, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(0.94, 0.9, 0.8, 0.95))
	# Cooldown sweep: a bright arc that unwinds clockwise as it recovers.
	if _cooldown > 0.005:
		var start := -PI * 0.5
		var end := start + TAU * _cooldown
		draw_arc(centre, draw_r - 3.0, start, end, 48, Color(0.95, 0.95, 0.9, 0.55), 4.0, true)
		draw_circle(centre, draw_r - 7.0, Color(0.01, 0.03, 0.04, 0.35 * _cooldown))
	# Count badge (HP/MP potions) at the top-right edge.
	if _badge != "":
		var badge_pos := centre + Vector2(draw_r * 0.52, -draw_r * 0.62)
		draw_circle(badge_pos + Vector2(1, 2), 11.0, Color(0, 0, 0, 0.4))
		draw_circle(badge_pos, 10.5, Color(0.05, 0.1, 0.11, 0.95))
		draw_arc(badge_pos, 10.5, 0, TAU, 24, accent, 1.6, true)
		draw_string(font, badge_pos + Vector2(-2, 4), _badge, HORIZONTAL_ALIGNMENT_CENTER, 24, 11, Color(0.96, 0.92, 0.8, 0.98))
	# Keycap hint for keyboard players.
	if _key_hint != "":
		var cap := Rect2(centre.x + draw_r * 0.28, centre.y - draw_r - 10.0, 20.0, 16.0)
		draw_rect(cap, Color(0.04, 0.09, 0.1, 0.85))
		draw_rect(cap, Color(0.72, 0.9, 0.86, 0.5), false, 1.0)
		var hint_size := font.get_string_size(_key_hint, HORIZONTAL_ALIGNMENT_CENTER, -1, 10)
		draw_string(font, cap.position + (cap.size - hint_size) * 0.5 + Vector2(0, 10), _key_hint, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(0.86, 0.93, 0.9, 0.9))
	# Press ring flash.
	if _pulse > 0.05:
		var flash_r := draw_r + 4.0 + (1.0 - _pulse) * 10.0
		draw_arc(centre, flash_r, 0, TAU, 48, Color(accent.r, accent.g, accent.b, _pulse * 0.5), 2.5, true)
