extends Area2D
## Port of Cainos' StairsLayerTrigger.cs
##
## The original swapped two things when the player walked onto a staircase: a
## Unity physics layer and a Unity sorting layer, so that the two storeys of the
## demo could overlap on one plane.
##
## Only the sorting half has a visible effect. The project's Physics2D layer
## matrix has Default / Layer 1 / Layer 2 / Layer 3 all colliding with one
## another, so moving between those layers changed nothing physically. What it
## really did was change draw order, which in Godot is the single z_index.
##
## The converter bakes the target z_index from the Unity sorting layer names so
## this script only has to apply them.

enum Direction { NORTH, SOUTH, WEST, EAST }

@export var direction: Direction = Direction.SOUTH
@export var z_upper := 200
@export var z_lower := 100


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


## Which side of the trigger the body is on. North triggers never fire, matching
## the original script, which only handled South, West and East.
## Godot is Y-down, so "south of the trigger" is a larger Y, not a smaller one.
func _passed_upper(body: Node2D) -> bool:
	match direction:
		Direction.SOUTH:
			return body.global_position.y > global_position.y
		Direction.WEST:
			return body.global_position.x < global_position.x
		Direction.EAST:
			return body.global_position.x > global_position.x
	return false


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and _passed_upper(body):
		_apply(body, z_upper)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and _passed_upper(body):
		_apply(body, z_lower)


func _apply(body: Node2D, z: int) -> void:
	for c in body.get_children():
		if c is CanvasItem:
			(c as CanvasItem).z_index = z