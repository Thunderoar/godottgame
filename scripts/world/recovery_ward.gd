class_name RecoveryWard
extends Node2D
## Visible ward around the cottage. While active, the player is held inside and
## health regenerates until full.

var radius := 4.4
var active := false
var _t := 0.0
var _label: Label

const OUTER_WIDTH := 2.0 * PixelArt.PX
const INNER_WIDTH := PixelArt.PX


func _ready() -> void:
	z_index = 2
	_label = Label.new()
	_label.text = "RECOVERY WARD"
	_label.add_theme_font_size_override("font_size", 12)
	_label.add_theme_color_override("font_color", Color("#a8f2cf"))
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_label.scale = Vector2(0.032, 0.032)
	_label.position = Vector2(-1.05, -radius - 0.6)
	_label.z_index = 8
	_label.visible = false
	add_child(_label)
	set_process(false)


func set_active(value: bool) -> void:
	active = value
	_label.visible = value
	set_process(value)
	queue_redraw()


func _process(delta: float) -> void:
	if not GameSettings.reduce_motion():
		_t += delta
	queue_redraw()


func _draw() -> void:
	if not active:
		return
	var pulse := 0.65 + sin(_t * 2.0) * 0.18
	draw_arc(Vector2.ZERO, radius, 0, TAU, 96, Color(0.45, 0.95, 0.72, 0.28 * pulse), OUTER_WIDTH, true)
	draw_arc(Vector2.ZERO, radius - 0.15, 0, TAU, 96, Color(0.7, 1.0, 0.86, 0.18), INNER_WIDTH, true)
	for i in 8:
		var a := float(i) / 8.0 * TAU + _t * 0.15
		var p := Vector2(cos(a), sin(a)) * radius
		draw_circle(p, 0.06, Color(0.70, 1.0, 0.85, 0.6))
