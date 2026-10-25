class_name BossProjectile
extends Node2D
## A boss orb that travels toward the player and deals contact damage.

var direction := Vector2.RIGHT
var damage := 12
var speed := 7.0
var life := 3.2
var tint := Color("#b57ce8")

var _sprite: Sprite2D
var _dead := false


func _ready() -> void:
	z_as_relative = false
	z_index = 640
	_sprite = Sprite2D.new()
	_sprite.texture = PixelArt.light_texture()
	_sprite.scale = Vector2(0.012, 0.012)
	_sprite.modulate = tint
	add_child(_sprite)
	var core := Sprite2D.new()
	core.texture = PixelArt.icon("spark")
	core.scale = Vector2(0.05, 0.05)
	core.modulate = tint.lightened(0.4)
	add_child(core)


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
		_burst()
		return
	if _sprite:
		_sprite.rotation += delta * 3.0
	var game := get_tree().get_first_node_in_group("game") as Game
	var player: Player = game.player() if is_instance_valid(game) else null
	if player != null and is_instance_valid(player):
		if global_position.distance_to(player.global_position + Vector2(0, -0.6)) <= 0.7:
			if player.has_method("take_damage"):
				player.call("take_damage", damage, global_position)
			_burst()
			return
	if global_position.x < -5 or global_position.y < -5 or global_position.x > 72 or global_position.y > 48:
		queue_free()


func _burst() -> void:
	_dead = true
	_sprite.visible = false
	var spark := Sprite2D.new()
	spark.texture = PixelArt.icon("spark")
	spark.scale = Vector2(0.07, 0.07)
	spark.modulate = tint
	spark.z_as_relative = false
	spark.z_index = 710
	spark.global_position = global_position
	get_parent().add_child(spark)
	var tween := spark.create_tween().set_parallel(true)
	tween.tween_property(spark, "modulate:a", 0.0, 0.25)
	tween.tween_property(spark, "scale", Vector2(0.13, 0.13), 0.25)
	tween.chain().tween_callback(spark.queue_free)
	queue_free()
