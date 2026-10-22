class_name RubbishPiece
extends Node2D
## One piece of coastal rubbish. It either gets caught by the guard or reaches
## the beach and becomes a monster — never both.

var manager: RubbishSystem
var guard: CoastalGuard
var target := Vector2.ZERO
var speed := 0.75
var resolved := false
var outcome := ""
var _sprite: Sprite2D
var _t := 0.0


func setup(p_manager: RubbishSystem, p_guard: CoastalGuard, start: Vector2, p_target: Vector2, lane_speed: float = 0.75) -> void:
	manager = p_manager
	guard = p_guard
	global_position = start
	target = p_target
	speed = lane_speed


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = PixelArt.rubbish_texture(0)
	_sprite.scale = Vector2(0.055, 0.055)
	_sprite.position = Vector2(0, -0.12)
	_sprite.z_index = 6
	add_child(_sprite)


func _process(delta: float) -> void:
	if resolved:
		return
	_t += delta
	if _sprite:
		_sprite.position.y = -0.12 + sin(_t * 2.5) * 0.06
		_sprite.texture = PixelArt.rubbish_texture(int(_t * 1.4) % 2)
	var to_target := target - global_position
	if to_target.length() <= 0.22:
		_reach_beach()
		return
	global_position += to_target.normalized() * speed * delta + Vector2(sin(_t * 2.0) * 0.06, 0)
	if is_instance_valid(guard) and global_position.distance_to(guard.global_position) <= guard.catch_radius:
		_caught()


func _caught() -> void:
	if resolved:
		return
	resolved = true
	outcome = "caught"
	if manager != null:
		manager.on_rubbish_caught(self)
	queue_free()


func _reach_beach() -> void:
	if resolved:
		return
	resolved = true
	outcome = "monster"
	if manager != null:
		manager.on_rubbish_beached(self)
	queue_free()
