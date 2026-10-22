extends Control
## Port of Unisza's WelcomePopup.cs
##
## Fades a panel in, holds it, then fades it out, with a slight scale pop on the
## way in. Unity ran the coroutine on unscaled time, so the Tween is created
## with set_ignore_time_scale(true).

@export var panel_path: NodePath
@export var message := "Welcome to Unisza"
@export var fade_in_duration := 0.3
@export var hold_duration := 2.5
@export var fade_out_duration := 0.45
@export var pop_scale := true
@export var scale_from := 0.85

var _panel: Control
var _label: Label
var _tween: Tween

var _from_alpha := 0.0
var _to_alpha := 1.0
var _from_scale := 1.0
var _to_scale := 1.0


func _ready() -> void:
	if panel_path and not panel_path.is_empty():
		_panel = get_node_or_null(panel_path) as Control
	if _panel == null:
		_panel = self
	_label = _find_label(_panel)
	# Hidden without leaving the tree, so the tween can still drive it.
	modulate.a = 0.0
	visible = false
	_set_scale(scale_from)


static func _find_label(root: Node) -> Label:
	for c in root.get_children():
		if c is Label:
			return c
	return null


func show_popup() -> void:
	show_message(message)


func show_message(text: String) -> void:
	if _label:
		_label.text = text
	if _tween and _tween.is_valid():
		_tween.kill()

	# The panel is scaled about its centre, which needs the laid-out size.
	if _panel:
		_panel.pivot_offset = _panel.size * 0.5

	visible = true
	_tween = create_tween().set_ignore_time_scale(true)
	# Each tween_method callback reads shared from/to fields, so the fade-out's
	# values must be set when that step starts, not up front.
	_begin_fade(modulate.a, 1.0, _panel.scale.x if _panel else 1.0, 1.0)
	_tween.tween_method(_apply_fade, 0.0, 1.0, fade_in_duration)
	_tween.tween_interval(hold_duration)
	_tween.tween_callback(func() -> void:
		_begin_fade(1.0, 0.0, 1.0, scale_from if pop_scale else 1.0))
	_tween.tween_method(_apply_fade, 0.0, 1.0, fade_out_duration)
	_tween.tween_callback(func() -> void: visible = false)


func _begin_fade(from_a: float, to_a: float, from_s: float, to_s: float) -> void:
	_from_alpha = from_a
	_to_alpha = to_a
	_from_scale = from_s
	_to_scale = to_s


func _apply_fade(k: float) -> void:
	modulate.a = lerpf(_from_alpha, _to_alpha, k)
	if pop_scale and _panel:
		_set_scale(lerpf(_from_scale, _to_scale, k))


func _set_scale(s: float) -> void:
	if _panel:
		_panel.scale = Vector2(s, s)
