class_name VillageBolt
extends Node2D

var target: Enemy
var source: Node
var damage := 6
var water := false
var arrow := false
var speed := 18.0
var _life := 2.5
var _direction := Vector2.RIGHT

func _ready() -> void:
	z_as_relative = false
	z_index = 710

func _physics_process(delta: float) -> void:
	if GameState.game_over_active or not is_instance_valid(target) or target.dead or target.is_queued_for_deletion():
		queue_free()
		return
	_life -= delta
	if _life <= 0:
		queue_free()
		return
	var destination := target.global_position + Vector2(0, -0.4)
	_direction = (destination - global_position).normalized()
	if global_position.distance_to(destination) <= speed * delta + 0.22:
		target.take_damage(damage, _direction, source if is_instance_valid(source) else null)
		Vfx.ring(destination, 0.3, Color("#70dfff") if water else Color("#ffd16e"), 0.2)
		queue_free()
		return
	global_position = global_position.move_toward(destination, speed * delta)
	queue_redraw()

func _draw() -> void:
	if arrow:
		draw_set_transform(Vector2.ZERO, _direction.angle(), Vector2.ONE * PixelArt.PX)
		draw_texture(PixelArt.arrow_texture(), Vector2(-12, -4))
		return
	var color := Color("#6fe2ff") if water else Color("#ffe69a")
	draw_line(-_direction * (0.5 if water else 0.28), Vector2.ZERO, color, 0.08)
	draw_circle(Vector2.ZERO, 0.10 if water else 0.055, color)
