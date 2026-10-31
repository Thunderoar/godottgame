class_name MissionArrow
extends Control
## Small HUD compass arrow that points from the player toward a live objective.

var title := "OBJECTIVE"
var accent := Color("#62c7ba")
var distance := 0.0
var direction := Vector2.RIGHT
var show_distance := true

var _time := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(156, 30)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_time = 0.0 if GameSettings.reduce_motion() else _time + delta
	queue_redraw()


func setup(label: String, color: Color) -> void:
	title = label
	accent = color
	queue_redraw()


func aim(from: Vector2, to: Vector2) -> void:
	var delta := to - from
	distance = delta.length()
	direction = delta.normalized() if distance > 0.01 else Vector2.RIGHT
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(0, 0, size.x, size.y), Color(0.02, 0.06, 0.07, 0.82))
	draw_rect(Rect2(0, 0, size.x, size.y), Color(accent.r, accent.g, accent.b, 0.55), false, 1.0)
	var centre := Vector2(18, size.y * 0.5)
	var angle := direction.angle()
	# Distance fade: near objectives glow, far ones settle to a calm tone.
	var proximity := 1.0 - clampf(distance / 60.0, 0.0, 0.65)
	var pulse := 0.82 + sin(_time * 3.2) * 0.18
	var arrow_color := accent.lerp(Color.WHITE, proximity * 0.25) * pulse
	var points := PackedVector2Array([
		Vector2(-7, -7).rotated(angle) + centre,
		Vector2(10, 0).rotated(angle) + centre,
		Vector2(-7, 7).rotated(angle) + centre,
		Vector2(-2, 0).rotated(angle) + centre,
	])
	draw_colored_polygon(points, arrow_color)
	if proximity > 0.75:
		# Pulsing halo when the objective is close.
		var halo_a := 0.4 + sin(_time * 3.2 + PI * 0.5) * 0.25
		draw_arc(centre, 12.0 + sin(_time * 3.2) * 2.0, 0, TAU, 24, Color(accent.r, accent.g, accent.b, halo_a * proximity), 1.5, true)
	var text := "%s  %dm" % [title, int(round(distance))] if show_distance else title
	draw_string(font, Vector2(35, size.y * 0.5 + 5), text, HORIZONTAL_ALIGNMENT_LEFT, size.x - 42, 14, Color(0.9, 0.9, 0.82, 0.95))
