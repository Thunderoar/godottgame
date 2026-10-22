class_name Player
extends CharacterBody2D
## Player controller shared by the lobby and portal dungeons.
##
## Movement and actions are read through InputMap so the virtual joystick and
## keyboard use exactly the same code path.

signal sleep_changed(active: bool, progress: float, label: String)
signal nearby_changed(interactable: Node)
signal hurt_flash

const INTERACT_RANGE := 2.0

var controls_locked := false
var facing := Vector2.DOWN
var nearby: Node = null
var attacking := false
var sleeping := false
var sleep_progress := 0.0
var invulnerable := 0.0
var dead := false

var _attack_timer := 0.0
var _sleep_elapsed := 0.0
var _sleep_duration := 10.0
var _sleep_hp_start := 0
var _visual: Sprite2D
var _shadow: Sprite2D
var _sword: Sprite2D
var _attack_sprite: Sprite2D
var _sword_bob := 0.0


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 5
	_build_body()
	_build_visual()
	var vitals := PlayerVitalHud.new()
	vitals.name = "VitalHud"
	add_child(vitals)
	set_process_input(true)


func _build_body() -> void:
	var shape := CollisionShape2D.new()
	shape.name = "Shape"
	var capsule := CapsuleShape2D.new()
	capsule.radius = 0.26
	capsule.height = 0.62
	shape.shape = capsule
	shape.position = Vector2(0, -0.12)
	add_child(shape)


func _build_visual() -> void:
	_shadow = Sprite2D.new()
	_shadow.name = "Shadow"
	_shadow.texture = PixelArt.light_texture()
	_shadow.scale = Vector2(0.018, 0.009)
	_shadow.modulate = Color(0.02, 0.02, 0.03, 0.32)
	_shadow.z_index = 2
	add_child(_shadow)

	_visual = PlayerSprite.new()
	_visual.name = "Sprite"
	_visual.character_id = str(GameState.data.get("character_id", "qayyim"))
	_visual.base_scale = Vector2(PixelArt.PX, PixelArt.PX)
	_visual.scale = Vector2(PixelArt.PX, PixelArt.PX)
	_visual.offset = Vector2(0, -24)
	_visual.z_index = 4
	add_child(_visual)

	_attack_sprite = Sprite2D.new()
	_attack_sprite.name = "Slash"
	_attack_sprite.texture = PixelArt.slash_texture()
	_attack_sprite.scale = Vector2(0.034, 0.034)
	_attack_sprite.visible = false
	_attack_sprite.z_as_relative = false
	_attack_sprite.z_index = 900
	add_child(_attack_sprite)


func _physics_process(delta: float) -> void:
	if invulnerable > 0.0:
		invulnerable = maxf(0.0, invulnerable - delta)
		if _visual:
			_visual.modulate.a = 0.55 if int(invulnerable * 20.0) % 2 == 0 else 1.0
		if invulnerable <= 0.0 and _visual:
			_visual.modulate.a = 1.0
	if _attack_timer > 0.0:
		_attack_timer = maxf(0.0, _attack_timer - delta)

	if dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if sleeping:
		_process_sleep(delta)
		return

	if controls_locked:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_nearby()
		return

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input * GameState.move_speed()
	move_and_slide()
	if input.length_squared() > 0.01:
		facing = input.normalized()
		if _visual and _visual.has_method("set_facing"):
			_visual.call("set_facing", _facing_index(facing), true)
	else:
		if _visual and _visual.has_method("set_facing"):
			_visual.call("set_facing", -1, false)

	if Input.is_action_just_pressed("attack"):
		try_attack()
	if Input.is_action_just_pressed("interact"):
		try_interact()

	_update_sword(delta)
	_update_nearby()


func _process_sleep(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	if Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("interact") or Input.get_vector("move_left", "move_right", "move_up", "move_down").length() > 0.15:
		cancel_sleep("Rest interrupted.")
		return
	_sleep_elapsed += delta
	sleep_progress = clampf(_sleep_elapsed / maxf(0.1, _sleep_duration), 0.0, 1.0)
	# Walk health toward the maximum over exactly the configured duration.
	var expected := int(round(lerpf(float(_sleep_hp_start), float(GameState.health_max()), sleep_progress)))
	if expected > GameState.health():
		GameState.heal(expected - GameState.health())
	sleep_changed.emit(true, sleep_progress, "Sleeping... %d%%" % int(sleep_progress * 100.0))
	if _sleep_elapsed >= _sleep_duration:
		GameState.set_health(GameState.health_max())
		sleeping = false
		sleep_progress = 1.0
		sleep_changed.emit(false, 1.0, "You wake up refreshed.")
		toast("Rested. Health fully restored.")


func try_attack() -> bool:
	if controls_locked or sleeping or dead:
		return false
	if _attack_timer > 0.0:
		return false
	var character := GameState.character_data()
	var style := str(character.get("weapon_style", "sword"))
	_attack_timer = float(character.get("attack_cooldown", 0.45))
	attacking = true
	if style == "bow":
		_fire_arrow(character)
	elif style == "hammer":
		_hammer_strike(character)
	else:
		_sword_strike(character)
	_finish_attack_pose()
	if _sword:
		_sword.visible = false
	return true


func _sword_strike(character: Dictionary) -> void:
	_show_slash(Color(1, 0.98, 0.82, 0.95), 0.040)
	var attack_range := float(character.get("attack_range", 2.05))
	var multiplier := float(character.get("attack_mult", 1.0))
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		if not enemy.has_method("take_damage"):
			continue
		var to_enemy: Vector2 = enemy.global_position - global_position
		if to_enemy.length() > attack_range + float(enemy.get("body_radius")):
			continue
		if to_enemy.length() > 0.05 and facing.dot(to_enemy.normalized()) < -0.05:
			continue
		var damage := int(round(float(GameState.attack_power()) * multiplier))
		enemy.call("take_damage", damage, to_enemy.normalized(), self)
		_spawn_damage_number(enemy.global_position + Vector2(0, -0.8), damage)


func _hammer_strike(character: Dictionary) -> void:
	_show_slash(Color(1.0, 0.7, 0.35, 0.95), 0.062)
	var attack_range := float(character.get("attack_range", 2.55))
	var multiplier := float(character.get("attack_mult", 1.35))
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		if not enemy.has_method("take_damage"):
			continue
		var to_enemy: Vector2 = enemy.global_position - global_position
		if to_enemy.length() > attack_range + float(enemy.get("body_radius")):
			continue
		var damage := int(round(float(GameState.attack_power()) * multiplier))
		enemy.call("take_damage", damage, to_enemy.normalized(), self)
		_spawn_damage_number(enemy.global_position + Vector2(0, -0.8), damage)
	get_tree().call_group("camera", "shake", 0.2, 0.18)


func _fire_arrow(character: Dictionary) -> void:
	var aim := facing
	var best: Node2D = null
	var best_distance := 999.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		var to_enemy: Vector2 = enemy.global_position - global_position
		var distance := to_enemy.length()
		if distance > 8.5 or distance < 0.1:
			continue
		if facing.dot(to_enemy.normalized()) < 0.25:
			continue
		if distance < best_distance:
			best = enemy
			best_distance = distance
	if best != null:
		aim = (best.global_position - global_position).normalized()
		facing = aim
	var arrow := Arrow.new()
	arrow.direction = aim
	arrow.damage = int(round(float(GameState.attack_power()) * float(character.get("attack_mult", 0.95))))
	arrow.source = self
	arrow.position = global_position + aim * 0.75 + Vector2(0, -0.65)
	get_parent().add_child(arrow)
	if _visual and _visual.has_method("set_facing"):
		_visual.call("set_facing", _facing_index(aim), true)


func _show_slash(color: Color = Color(1, 0.98, 0.82, 0.95), final_scale: float = 0.040) -> void:
	if _attack_sprite == null:
		return
	_attack_sprite.visible = true
	_attack_sprite.position = facing * 0.88
	_attack_sprite.rotation = facing.angle() + 0.4
	_attack_sprite.modulate = color
	_attack_sprite.scale = Vector2(0.020, 0.020)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_attack_sprite, "scale", Vector2(final_scale, final_scale), 0.12)
	tween.tween_property(_attack_sprite, "modulate:a", 0.0, 0.22)
	tween.chain().tween_callback(func() -> void:
		if is_instance_valid(_attack_sprite):
			_attack_sprite.visible = false)


func _finish_attack_pose() -> void:
	await get_tree().create_timer(0.12).timeout
	if is_inside_tree():
		attacking = false


func _spawn_damage_number(at: Vector2, amount: int) -> void:
	var label := Label.new()
	label.text = str(amount)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color("#ffe7a1"))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.scale = Vector2(0.032, 0.032)
	label.position = at - Vector2(0.3, 0.3)
	label.z_as_relative = false
	label.z_index = 1000
	get_parent().add_child(label)
	var tween := label.create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 1.1, 0.65)
	tween.tween_property(label, "modulate:a", 0.0, 0.65)
	tween.chain().tween_callback(label.queue_free)


func try_interact() -> void:
	if controls_locked or sleeping or dead:
		return
	if nearby != null and is_instance_valid(nearby) and nearby.has_method("interact"):
		nearby.call("interact", self)


func _update_nearby() -> void:
	var best: Node = null
	var best_dist := 99999.0
	for node in get_tree().get_nodes_in_group("interactable"):
		if not is_instance_valid(node):
			continue
		if node.has_method("is_interactable_available") and not bool(node.call("is_interactable_available")):
			continue
		var radius := float(node.get("interact_radius")) if node.get("interact_radius") != null else 1.8
		var d := global_position.distance_to(node.global_position)
		if d <= radius and d < best_dist:
			best = node
			best_dist = d
	if best != nearby:
		nearby = best
		nearby_changed.emit(nearby)


func _update_sword(delta: float) -> void:
	if _sword == null:
		return
	_sword_bob += delta
	_sword.visible = not attacking and not sleeping
	if not _sword.visible:
		return
	var side := 1.0 if facing.x >= 0.0 else -1.0
	_sword.position = Vector2(0.29 * side, -0.72 + sin(_sword_bob * 5.0) * 0.02)
	_sword.rotation = 0.5 * side
	_sword.flip_h = side < 0.0


func _facing_index(dir: Vector2) -> int:
	if absf(dir.x) > absf(dir.y):
		return 2 if dir.x > 0.0 else 3
	return 0 if dir.y > 0.0 else 1


func take_damage(amount: int, from: Vector2 = Vector2.ZERO) -> void:
	if dead or sleeping or invulnerable > 0.0:
		return
	invulnerable = 0.55
	GameState.damage_player(amount)
	hurt_flash.emit()
	if from != Vector2.ZERO:
		var push := (global_position - from).normalized()
		global_position += push * 0.18
	if _visual:
		var tween := create_tween()
		_visual.modulate = Color("#ff8b7d")
		tween.tween_property(_visual, "modulate", Color.WHITE, 0.22)
	if GameState.health() <= 0:
		die()


func die() -> void:
	dead = true
	sleeping = false
	velocity = Vector2.ZERO
	if _visual:
		var tween := create_tween()
		tween.tween_property(_visual, "rotation", -PI * 0.5, 0.35)
		tween.parallel().tween_property(_visual, "modulate:a", 0.25, 0.35)


func revive_at(position: Vector2) -> void:
	global_position = position
	dead = false
	controls_locked = false
	sleeping = false
	velocity = Vector2.ZERO
	if _visual:
		_visual.rotation = 0.0
		_visual.modulate.a = 1.0


func start_sleep(duration: float) -> void:
	if sleeping or dead:
		return
	sleeping = true
	sleep_progress = 0.0
	_sleep_elapsed = 0.0
	_sleep_duration = maxf(0.2, duration)
	_sleep_hp_start = GameState.health()
	velocity = Vector2.ZERO
	if _visual:
		var tween := create_tween()
		tween.tween_property(_visual, "rotation", -0.35, 0.3)
	sleep_changed.emit(true, 0.0, "Sleeping... 0%")


func cancel_sleep(reason: String = "Rest interrupted.") -> void:
	if not sleeping:
		return
	sleeping = false
	sleep_progress = 0.0
	if _visual:
		_visual.rotation = 0.0
	sleep_changed.emit(false, 0.0, reason)
	toast(reason, "bad")


func toast(text: String, tone: String = "info") -> void:
	GameState.toast_requested.emit(text, tone)


func get_facing_angle() -> float:
	return facing.angle()
