class_name Enemy
extends CharacterBody2D
## Reusable regular monster / boss body. One script handles both because they
## share movement, hit reactions and death; the boss flag changes scale, stats
## and the HUD signal it emits.

signal boss_started(enemy: Enemy)
signal boss_finished(enemy: Enemy)

@export var kind := "bogling"
@export var is_boss := false
@export var monster_level := 1
@export var body_radius := 0.42
@export var max_hp := 42
@export var damage := 8
@export var speed := 2.0
@export var xp_reward := 12
@export var gold_reward := 9
@export var diamond_chance := 0.12
@export var settlement_mode := false
@export var forest_mode := false
@export var sight_range := 11.0
@export var attack_interval := 1.35
@export var boss_ability := "punch"
@export var boss_ability_name := "Heavy Strike"
@export var special_damage := 18
@export var special_cooldown := 3.8
@export var projectile_damage := 12

var hp := 42
var dead := false
var active := false
var spawning := true
var _player: Node2D
var _target: Node2D
var _special_timer := 2.5
var _charging := false
var _charge_time := 0.0
var _charge_dir := Vector2.ZERO
var _charge_hit := false
var _alternate_charge := false
var _sprite: Sprite2D
var _shadow: Sprite2D
var _attack_timer := 0.0
var _hit_flash := 0.0
var _bob := 0.0
var _frame_timer := 0.0
var _frame := 0
var _knockback := Vector2.ZERO
var _boss_notified := false
var _saw_player := false


func _ready() -> void:
	add_to_group("enemies")
	if forest_mode:
		add_to_group("forest_monsters")
	collision_layer = 4
	collision_mask = 1
	hp = max_hp
	_player = get_tree().get_first_node_in_group("player")
	_build()
	# A short spawn-in shimmer so monsters do not pop into the dark.
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.35)
	spawning = false


func _build() -> void:
	var size := 64 if is_boss else 32
	_shadow = Sprite2D.new()
	_shadow.texture = PixelArt.light_texture()
	_shadow.scale = Vector2(float(size) * 0.00052, float(size) * 0.00028)
	_shadow.modulate = Color(0, 0, 0, 0.4)
	_shadow.position = Vector2(0, -0.05)
	_shadow.z_index = -1
	add_child(_shadow)

	_sprite = Sprite2D.new()
	_sprite.name = "Sprite"
	_sprite.texture = PixelArt.enemy_texture(kind, is_boss, 0)
	_sprite.scale = Vector2(PixelArt.PX, PixelArt.PX)
	_sprite.position = Vector2(0, -float(size) * 0.5 * PixelArt.PX)
	_sprite.z_index = 6
	add_child(_sprite)

	var shape := CollisionShape2D.new()
	shape.name = "Shape"
	var circle := CircleShape2D.new()
	circle.radius = body_radius
	shape.shape = circle
	shape.position = Vector2(0, -body_radius * 0.5)
	add_child(shape)


func _physics_process(delta: float) -> void:
	if dead:
		return
	_bob += delta
	_frame_timer += delta
	if _frame_timer >= 0.35:
		_frame_timer -= 0.35
		_frame = 1 - _frame
		if _sprite:
			_sprite.texture = PixelArt.enemy_texture(kind, is_boss, _frame)
	if _sprite:
		_sprite.position.y = -float(64 if is_boss else 32) * 0.5 * PixelArt.PX + sin(_bob * 4.0) * 0.03
	if _hit_flash > 0.0:
		_hit_flash = maxf(0.0, _hit_flash - delta)
		if _sprite:
			_sprite.modulate = Color(1.8, 1.4, 1.4) if _hit_flash > 0.0 else Color.WHITE
	if _attack_timer > 0.0:
		_attack_timer = maxf(0.0, _attack_timer - delta)
	if _special_timer > 0.0:
		_special_timer = maxf(0.0, _special_timer - delta)
	if _charging:
		_process_charge(delta)
		return

	if _knockback.length_squared() > 0.01:
		velocity = _knockback
		_knockback = _knockback.move_toward(Vector2.ZERO, delta * 18.0)
		move_and_slide()
		return

	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	if forest_mode:
		_update_forest_target()
	elif settlement_mode:
		_target = _choose_settlement_target()
	else:
		_target = _player
	if not is_instance_valid(_target):
		velocity = velocity.move_toward(Vector2.ZERO, delta * 4.0)
		move_and_slide()
		return
	var to_target: Vector2 = _target.global_position - global_position
	var distance := to_target.length()
	var aggro := 14.0 if settlement_mode else (8.5 if is_boss else 6.2)
	if distance <= aggro:
		if not active:
			active = true
			if is_boss and not _boss_notified:
				_boss_notified = true
				boss_started.emit(self)
				GameState.boss_health_changed.emit(true, _boss_name(), hp, max_hp)
		if distance > body_radius + 0.55:
			velocity = to_target.normalized() * speed
			move_and_slide()
		else:
			velocity = Vector2.ZERO
			move_and_slide()
			if _attack_timer <= 0.0:
				_attack_timer = 1.15 if is_boss else attack_interval
				if _target.has_method("take_damage"):
					_target.call("take_damage", damage, global_position)
				elif _target.has_method("take_attack_damage"):
					_target.call("take_attack_damage", damage)
				_lunge(to_target.normalized())
		if is_boss and _boss_notified:
			GameState.boss_health_changed.emit(true, _boss_name(), hp, max_hp)
			if _special_timer <= 0.0:
				_special_timer = special_cooldown
				_cast_special()
	else:
		velocity = velocity.move_toward(Vector2.ZERO, delta * 4.0)
		move_and_slide()
	queue_redraw()


func _cast_special() -> void:
	if not is_instance_valid(_target) or dead:
		return
	match boss_ability:
		"charge":
			_begin_charge()
		"projectile":
			_fire_projectile()
		"projectile_charge":
			_alternate_charge = not _alternate_charge
			if _alternate_charge:
				_begin_charge()
			else:
				_fire_projectile()
		"area", "slam":
			_area_slam()
		_:
			_punch()


func _punch() -> void:
	if _target == null or not is_instance_valid(_target):
		return
	var distance := global_position.distance_to(_target.global_position)
	_spawn_burst(Color("#ff8b5f"), 2.5)
	if distance <= 3.8 and _target.has_method("take_damage"):
		_target.call("take_damage", special_damage, global_position)
	_lunge((_target.global_position - global_position).normalized())


func _area_slam() -> void:
	var origin := global_position
	_spawn_burst(Color("#d96464"), 4.2)
	await get_tree().create_timer(0.55).timeout
	if dead or not is_inside_tree():
		return
	if _target != null and is_instance_valid(_target):
		if origin.distance_to(_target.global_position) <= 4.2 and _target.has_method("take_damage"):
			_target.call("take_damage", special_damage, origin)
	_spawn_burst(Color("#ff9f78"), 4.2)


func _fire_projectile() -> void:
	if not is_instance_valid(_player):
		return
	var orb := BossProjectile.new()
	orb.direction = (_player.global_position - global_position).normalized()
	orb.damage = projectile_damage
	orb.tint = Color("#b57ce8") if boss_ability != "storm" else Color("#8fe8ff")
	orb.global_position = global_position + Vector2(0, -1.2)
	get_parent().add_child(orb)
	orb.global_position = global_position + Vector2(0, -1.2)


func _begin_charge() -> void:
	if not is_instance_valid(_target):
		return
	_charging = true
	_charge_time = 0.38
	_charge_hit = false
	_charge_dir = (_target.global_position - global_position).normalized()
	_spawn_burst(Color("#f5c96b"), 2.0)
	Sfx.play("charge", -6.0)


func _process_charge(delta: float) -> void:
	_charge_time -= delta
	velocity = _charge_dir * speed * 4.8
	move_and_slide()
	if _sprite:
		_sprite.rotation = _charge_dir.angle() * 0.08
	if not _charge_hit and is_instance_valid(_player):
		if global_position.distance_to(_player.global_position) <= 1.15 and _player.has_method("take_damage"):
			_charge_hit = true
			_player.call("take_damage", special_damage, global_position)
			_spawn_burst(Color("#ffc966"), 2.4)
	if _charge_time <= 0.0:
		_charging = false
		velocity = Vector2.ZERO
		if _sprite:
			_sprite.rotation = 0.0


func _spawn_burst(color: Color, radius: float) -> void:
	var ring := Sprite2D.new()
	ring.texture = PixelArt.light_texture()
	ring.modulate = Color(color.r, color.g, color.b, 0.55)
	ring.scale = Vector2.ONE * (radius * 2.0 / 128.0)
	ring.z_as_relative = false
	ring.z_index = 680
	ring.global_position = global_position + Vector2(0, -0.4)
	get_parent().add_child(ring)
	ring.global_position = global_position + Vector2(0, -0.4)
	var tween := ring.create_tween().set_parallel(true)
	tween.tween_property(ring, "scale", Vector2.ONE * (radius * 2.6 / 128.0), 0.5)
	tween.tween_property(ring, "modulate:a", 0.0, 0.5)
	tween.chain().tween_callback(ring.queue_free)


func _update_forest_target() -> void:
	if not is_instance_valid(_player):
		_target = _nearest_forest_tree()
		return
	var distance := global_position.distance_to(_player.global_position)
	if _can_see_player():
		if not _saw_player:
			_saw_player = true
			_target = _player
			Sfx.play("aggro", -5.0)
			_begin_charge()
		else:
			_target = _player
		return
	if _saw_player and distance <= sight_range + 5.0:
		_target = _player
		return
	_saw_player = false
	_target = _nearest_forest_tree()


func _can_see_player() -> bool:
	if not is_instance_valid(_player) or not is_inside_tree():
		return false
	if global_position.distance_to(_player.global_position) > sight_range:
		return false
	var from := global_position + Vector2(0, -0.55)
	var to := _player.global_position + Vector2(0, -0.55)
	var query := PhysicsRayQueryParameters2D.create(from, to, 3, [get_rid()])
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.get("collider") == _player


func _nearest_forest_tree() -> Node2D:
	var best: Node2D = null
	var best_distance := 22.0
	for node in get_tree().get_nodes_in_group("forest_tree"):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var distance := global_position.distance_to(node.global_position)
		if distance < best_distance:
			best = node
			best_distance = distance
	return best


func _choose_settlement_target() -> Node2D:
	var best: Node2D = null
	var best_distance := 9999.0
	if is_instance_valid(_player):
		var player_distance := global_position.distance_to(_player.global_position)
		if player_distance <= 6.0:
			return _player
	for node in get_tree().get_nodes_in_group("settlement_target"):
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var distance := global_position.distance_to(node.global_position)
		if distance < best_distance:
			best = node
			best_distance = distance
	return best


func _lunge(dir: Vector2) -> void:
	if _sprite == null:
		return
	var base := _sprite.position
	var tween := create_tween()
	tween.tween_property(_sprite, "position", base + dir * 0.22, 0.09)
	tween.tween_property(_sprite, "position", base, 0.14)


func take_damage(amount: int, from_dir: Vector2 = Vector2.ZERO, _source: Node = null) -> void:
	if dead:
		return
	hp = maxi(0, hp - amount)
	_hit_flash = 0.14
	if _sprite:
		create_tween().tween_property(_sprite, "scale", Vector2(PixelArt.PX * 1.12, PixelArt.PX * 0.9), 0.05).set_trans(Tween.TRANS_QUAD)
	if from_dir != Vector2.ZERO:
		_knockback = from_dir * (5.0 if is_boss else 6.5)
	if is_boss:
		GameState.boss_health_changed.emit(true, _boss_name(), hp, max_hp)
	if hp <= 0:
		_die()
	queue_redraw()


func _die() -> void:
	if dead:
		return
	dead = true
	remove_from_group("enemies")
	if is_boss:
		GameState.register_kill(0)
	elif settlement_mode:
		GameState.add_gold(gold_reward)
		GameState.register_emergency_kill()
		GameState.toast_requested.emit("Emergency monster defeated: +%d Gold." % gold_reward, "gold")
	else:
		GameState.register_kill(xp_reward)
	if kind == "rubbish":
		GameState.add_gold(gold_reward)
		GameState.toast_requested.emit("Rubbish monster defeated: +%d Gold." % gold_reward, "gold")
	elif not settlement_mode and not is_boss:
		_spawn_reward()
	if is_boss:
		GameState.boss_health_changed.emit(false, _boss_name(), 0, max_hp)
		boss_finished.emit(self)
		velocity = Vector2.ZERO
		collision_layer = 0
		var tween := create_tween().set_parallel(true)
		tween.tween_property(self, "modulate:a", 0.0, 0.9)
		tween.tween_property(self, "scale", Vector2(1.15, 0.8), 0.9)
		tween.chain().tween_callback(queue_free)
	else:
		collision_layer = 0
		var tween := create_tween().set_parallel(true)
		tween.tween_property(self, "modulate:a", 0.0, 0.26)
		tween.tween_property(self, "scale", Vector2(1.2, 0.7), 0.26)
		tween.chain().tween_callback(queue_free)


func _spawn_reward() -> void:
	if is_boss:
		return
	var parent := get_parent()
	if parent == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var gold := maxi(1, gold_reward + rng.randi_range(-2, 4))
	var gold_drop := LootDrop.new()
	gold_drop.kind = "gold"
	gold_drop.amount = gold
	gold_drop.position = global_position + Vector2(rng.randf_range(-0.35, 0.35), 0.0)
	parent.call_deferred("add_child", gold_drop)
	if rng.randf() < diamond_chance:
		var gem := LootDrop.new()
		gem.kind = "diamond"
		gem.amount = 1
		gem.position = global_position + Vector2(0.45, -0.2)
		parent.call_deferred("add_child", gem)


func _boss_name() -> String:
	var portal_id := str(GameState.expedition_portal())
	return str(PortalDB.get_portal(portal_id).get("boss_name", "Guardian"))


func _draw() -> void:
	if dead or is_boss:
		return
	var width := 0.72
	var y := -1.03
	var ratio := clampf(float(hp) / float(maxi(1, max_hp)), 0.0, 1.0)
	if ratio >= 0.999:
		return
	draw_rect(Rect2(-width * 0.5 - 0.02, y - 0.02, width + 0.04, 0.14), Color(0.03, 0.04, 0.05, 0.92))
	draw_rect(Rect2(-width * 0.5, y, width * ratio, 0.10), Color("#d75a58"))


func name_text() -> String:
	if kind == "drowned":
		return "Drowned Courtier"
	if kind == "bogling":
		return "Bogling"
	return kind.capitalize()
