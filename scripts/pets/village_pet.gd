class_name VillagePet
extends CharacterBody2D
## Tournament recruits stay in the village and cannot die.
const GUARD_RANGE := 18.0
const ATTACK_RANGE := 2.2
const ROUTE_INTERVAL := 0.6
var pet_id := "sparring_ember"
var home := Vector2.ZERO
var _sprite: Sprite2D
var _attack_timer := 0.0
var _route_timer := 0.0
var _path := PackedVector2Array()
var _target: Enemy
var _clock := 0.0

func _ready() -> void:
	add_to_group("village_pets")
	collision_layer = 0
	collision_mask = 1
	z_index = 6
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 0.2
	shape.shape = circle
	add_child(shape)
	_sprite = Sprite2D.new()
	_sprite.scale = Vector2.ONE * PixelArt.PX * 1.2
	_sprite.position.y = -0.5
	add_child(_sprite)
	_sprite.texture = PixelArt.pet_texture(pet_id)

func _physics_process(delta: float) -> void:
	if GameState.game_over_active:
		return
	_clock += delta
	_attack_timer = maxf(0.0, _attack_timer - delta)
	_route_timer -= delta
	if _route_timer <= 0.0:
		_route_timer = ROUTE_INTERVAL
		_target = nearest_threat()
		var destination := _target.global_position if is_instance_valid(_target) else home
		_path = get_parent().resident_path(global_position, destination)
	var destination := _target.global_position if is_instance_valid(_target) and not _target.dead else home
	while not _path.is_empty() and global_position.distance_to(_path[0]) < 0.3:
		_path.remove_at(0)
	var next := _path[0] if not _path.is_empty() else destination
	var distance := global_position.distance_to(destination)
	velocity = (next - global_position).normalized() * 4.8 if distance > (1.5 if is_instance_valid(_target) else 0.3) else Vector2.ZERO
	move_and_slide()
	_sprite.flip_h = velocity.x < -0.1
	_sprite.texture = PixelArt.pet_texture(pet_id, 1 if velocity.length() > 0.1 and int(_clock * 5) % 2 else 0)
	if is_instance_valid(_target) and not _target.dead and distance <= ATTACK_RANGE and _attack_timer <= 0.0:
		var pet := GameState.get_pet(pet_id)
		var level := int(pet.get("level", 1))
		_attack_timer = PetDB.attack_interval(pet_id, level)
		var direction := (_target.global_position - global_position).normalized()
		_target.take_damage(PetDB.attack_damage(pet_id, level), direction, self)
		Vfx.sparks(_target.global_position, -direction, Color("#9fe8ba"), 5)

func nearest_threat() -> Enemy:
	var target: Enemy
	var nearest := GUARD_RANGE
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or enemy.dead or enemy.get_parent() != get_parent() or enemy.kind not in ["fire", "urchin"]:
			continue
		var distance := global_position.distance_to(enemy.global_position)
		if distance < nearest:
			nearest = distance
			target = enemy
	return target
