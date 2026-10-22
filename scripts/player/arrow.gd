class_name Arrow
extends Node2D
## Simple ranged projectile for Ayiz. It travels in a straight line, checks
## living monsters each step, and leaves a short impact flash.

var direction := Vector2.RIGHT
var damage := 10
var speed := 16.0
var life := 1.4
var source: Node = null

var _sprite: Sprite2D
var _dead := false


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
	global_position += direction * speed * delta
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		if not enemy.has_method("take_damage"):
			continue
		var radius := float(enemy.get("body_radius")) if enemy.get("body_radius") != null else 0.4
		if global_position.distance_to(enemy.global_position) <= radius + 0.28:
			enemy.call("take_damage", damage, direction, source)
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
