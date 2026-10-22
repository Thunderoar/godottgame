class_name SettlementPlaceable
extends Node2D
## A group of scenery/buildings that can be moved in settlement editor mode.

@export var placeable_id := ""
@export var category := "decoration"
@export var selection_size := Vector2(4, 3)

var _outline: Line2D


func _ready() -> void:
	add_to_group("placeable")
	_outline = Line2D.new()
	_outline.width = 2.0
	_outline.default_color = Color("#f2d36b")
	_outline.closed = true
	_outline.z_as_relative = false
	_outline.z_index = 950
	_outline.points = PackedVector2Array([
		Vector2(-selection_size.x * 0.5, -selection_size.y * 0.5),
		Vector2(selection_size.x * 0.5, -selection_size.y * 0.5),
		Vector2(selection_size.x * 0.5, selection_size.y * 0.5),
		Vector2(-selection_size.x * 0.5, selection_size.y * 0.5),
	])
	_outline.visible = false
	add_child(_outline)


func set_selected(value: bool) -> void:
	if _outline:
		_outline.visible = value
	modulate = Color(1.18, 1.16, 1.02) if value else Color.WHITE


func contains_world(world_pos: Vector2) -> bool:
	var local := to_local(world_pos)
	return Rect2(-selection_size.x * 0.5, -selection_size.y * 0.5, selection_size.x, selection_size.y).has_point(local)
