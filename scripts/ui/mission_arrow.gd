class_name MissionArrow
extends Control
## Small HUD compass arrow that points from the player toward a live objective.

var title := "OBJECTIVE"
var accent := Color("#62c7ba")
var distance := 0.0
var direction := Vector2.RIGHT


func _ready() -> void:
	custom_minimum_size = Vector2(156, 30)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	var points := PackedVector2Array([
		Vector2(-7, -7).rotated(angle) + centre,
		Vector2(10, 0).rotated(angle) + centre,
		Vector2(-7, 7).rotated(angle) + centre,
		Vector2(-2, 0).rotated(angle) + centre,
	])
	draw_colored_polygon(points, accent)
	var text := "%s  %dm" % [title, int(round(distance))]
	draw_string(font, Vector2(35, size.y * 0.5 + 4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.9, 0.9, 0.82, 0.95))
