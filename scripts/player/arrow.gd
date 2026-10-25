class_name Arrow
extends Node2D
## Simple ranged projectile for Mei Ling. It travels in a straight line, checks
## living monsters each step, and leaves a short impact flash.

var direction := Vector2.RIGHT
var damage := 10
var speed := 16.0
var life := 1.4
var source: Node = null
var pierce := 1
var _hit_ids: Array[int] = []

var _sprite: Sprite2D
var _dead := false
var _trail_timer := 0.0


func _ready() -> void:
	add_to_group("projectile")
	z_as_relative = false
	z_index = 620
	_sprite = Sprite2D.new()
	_sprite.texture = PixelArt.arrow_texture()
	_sprite.scale = Vector2(PixelArt.PX, PixelArt.PX)
	_sprite.rotation = direction.angle()
	_sprite.z_index = 620
	add_child(_sprite)
	rotation = 0.0


func _physics_process(delta: float) -> void:
	if _dead:
		return
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	var previous := global_position
	global_position += direction * speed * delta
	var ray := PhysicsRayQueryParameters2D.create(previous, global_position, 1)
	if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
		queue_free()
		return
	# Faint trail behind the arrow.
	_trail_timer -= delta
	if _trail_timer <= 0.0 and not GameSettings.reduce_motion():
		_trail_timer = 0.035
		Vfx.dust(global_position - direction * 0.3, 1, Color(0.9, 0.85, 0.7, 0.4))
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		if enemy.get_parent() != get_parent() or bool(enemy.get("dead")) or enemy.get_instance_id() in _hit_ids:
			continue
		if not enemy.has_method("take_damage"):
			continue
		var radius := float(enemy.get("body_radius")) if enemy.get("body_radius") != null else 0.4
		if Geometry2D.get_closest_point_to_segment(enemy.global_position, previous, global_position).distance_to(enemy.global_position) <= radius + 0.28:
			enemy.call("take_damage", damage, direction, source)
			_hit_ids.append(enemy.get_instance_id())
			pierce -= 1
			if pierce <= 0:
				_impact(enemy.global_position)
				return
	if global_position.x < -4 or global_position.y < -4 or global_position.x > 70 or global_position.y > 46:
		queue_free()


func _impact(at: Vector2) -> void:
	_dead = true
	_sprite.visible = false
	var spark := Sprite2D.new()
	spark.texture = PixelArt.icon("spark")
	spark.scale = Vector2(0.05, 0.05)
	spark.position = at
	spark.z_as_relative = false
	spark.z_index = 700
	get_parent().add_child(spark)
	var tween := spark.create_tween().set_parallel(true)
	tween.tween_property(spark, "modulate:a", 0.0, 0.18)
	tween.tween_property(spark, "scale", Vector2(0.09, 0.09), 0.18)
	tween.chain().tween_callback(spark.queue_free)
	queue_free()
