class_name Player
extends CharacterBody2D
## Player controller shared by the lobby and portal dungeons.
##
## Movement and actions are read through InputMap so the virtual joystick and
## keyboard use exactly the same code path.
##
## Overhaul (3B/3D): velocity eases in and out (ACCEL/FRICTION) instead of
## snapping; try_attack() opens a data-driven anticipation -> active ->
## recovery chain (AttackDB) and damage lands on the ACTIVE frame; the cooldown
## restarts at each hit frame so per-second damage is unchanged. Footsteps kick
## up dust, hits and deaths use PlayerSprite poses.

signal sleep_changed(active: bool, progress: float, label: String)
signal nearby_changed(interactable: Node)
signal hurt_flash

const INTERACT_RANGE := 2.0
const ACCEL := 26.0
const FRICTION := 30.0
const TURN_BOOST := 1.7
const FOOTSTEP_INTERVAL := 0.3
@export var acceleration := ACCEL
@export var braking := FRICTION
@export var turn_assistance := TURN_BOOST

enum AttackPhase { NONE, ANTICIPATION, ACTIVE, RECOVERY }

var controls_locked := false
var facing := Vector2.DOWN
var nearby: Node = null
var attacking := false
var sleeping := false
var sleep_progress := 0.0
var invulnerable := 0.0
var dead := false

var _attack_timer := 0.0
var _attack_total := 0.45
var _sleep_elapsed := 0.0
var _sleep_duration := 10.0
var _sleep_hp_start := 0
var _visual: PlayerSprite
var _shadow: Sprite2D
var _attack_sprite: Sprite2D
var _attack_phase := AttackPhase.NONE
var _attack_step := 0
var _phase_time := 0.0
var _attack_dir := Vector2.RIGHT
var _chain_style := "sword"
var _chain: Dictionary = {}
var _combo_expire := -1.0
var _idle_clock := 0.0
var _lunge_impulse := Vector2.ZERO
var _step_timer := 0.0
var _step_count := 0


func _ready() -> void:
	add_to_group("player")
	z_index = 6
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
	_shadow.z_index = -1
	add_child(_shadow)

	_visual = PlayerSprite.new()
	_visual.name = "Sprite"
	_visual.character_id = str(GameState.data.get("character_id", "adam"))
	_visual.base_scale = Vector2(PixelArt.PX, PixelArt.PX)
	_visual.scale = Vector2(PixelArt.PX, PixelArt.PX)
	_visual.offset = Vector2(0, -24)
	_visual.z_index = 0
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
	_idle_clock += delta

	if dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if sleeping:
		_process_sleep(delta)
		return

	if controls_locked:
		velocity = velocity.move_toward(Vector2.ZERO, braking * delta)
		move_and_slide()
		if _visual:
			_visual.set_motion(get_real_velocity(), GameState.move_speed())
		_update_nearby()
		return

	_update_attack_phase(delta)

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input.length_squared() > 0.01:
		facing = input.normalized()
		var target := input.limit_length(1.0) * GameState.move_speed()
		# Turning against the current slide direction grips harder.
		var turn := turn_assistance if velocity.dot(input) < -0.5 else 1.0
		velocity = velocity.move_toward(target, acceleration * turn * delta)
		if _visual and _visual.has_method("set_facing"):
			_visual.call("set_facing", _facing_index(facing), true)
		_update_footsteps(delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, braking * delta)
		if _visual and _visual.has_method("set_facing"):
			_visual.call("set_facing", -1, false)
	if _lunge_impulse != Vector2.ZERO:
		velocity += _lunge_impulse
		_lunge_impulse = Vector2.ZERO
	move_and_slide()
	if _visual:
		_visual.set_motion(get_real_velocity(), GameState.move_speed())

	if Input.is_action_just_pressed("attack"):
		try_attack()
	if Input.is_action_just_pressed("interact"):
		try_interact()

	_update_nearby()


func _update_footsteps(delta: float) -> void:
	# Dust puffs on the move; a quiet tick every other step.
	if GameSettings.reduce_motion() or not GameSettings.effects_at_least("med"):
		return
	_step_timer += delta
	if _step_timer >= FOOTSTEP_INTERVAL:
		_step_timer = 0.0
		_step_count += 1
		Vfx.dust(global_position + Vector2(0, -0.04), 2)
		if _step_count % 2 == 0:
			Sfx.play("step", -26.0)


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
		if _visual:
			_visual.call("play_pose", PlayerSprite.Pose.IDLE)
		sleep_changed.emit(false, 1.0, "You wake up refreshed.")
		toast("Rested. Health fully restored.")


# ------------------------------------------------------------------ attacks

func try_attack() -> bool:
	if controls_locked or sleeping or dead:
		return false
	if _attack_timer > 0.0 or _attack_phase != AttackPhase.NONE:
		return false
	var character := GameState.character_data()
	_chain_style = str(character.get("weapon_style", "sword"))
	_chain = AttackDB.chain(_chain_style)
	var next_step := 0
	if _combo_expire > 0.0 and _idle_clock < _combo_expire:
		next_step = (_attack_step + 1) % AttackDB.step_count(_chain_style)
	_attack_step = next_step
	_attack_dir = facing
	_attack_phase = AttackPhase.ANTICIPATION
	var step := AttackDB.step(_chain_style, _attack_step)
	_phase_time = float(step.get("anticipation", 0.06))
	attacking = true
	# A tiny hitch at the wind-up start sells the anticipation.
	if _visual and not GameSettings.reduce_motion():
		_visual.scale = Vector2(PixelArt.PX * 0.97, PixelArt.PX * 1.02)
	return true


func _update_attack_phase(delta: float) -> void:
	if _attack_phase == AttackPhase.NONE:
		return
	_phase_time -= delta
	if _phase_time > 0.0:
		return
	match _attack_phase:
		AttackPhase.ANTICIPATION:
			_begin_active_phase()
		AttackPhase.ACTIVE:
			_attack_phase = AttackPhase.RECOVERY
			_phase_time = float(AttackDB.step(_chain_style, _attack_step).get("recovery", 0.14))
		AttackPhase.RECOVERY:
			_attack_phase = AttackPhase.NONE
			attacking = false
			_combo_expire = _idle_clock + AttackDB.COMBO_WINDOW
			if _visual:
				_visual.scale = Vector2(PixelArt.PX, PixelArt.PX)


func _begin_active_phase() -> void:
	var character := GameState.character_data()
	var step := AttackDB.step(_chain_style, _attack_step)
	_attack_phase = AttackPhase.ACTIVE
	_phase_time = float(step.get("active", 0.08))
	# The cooldown restarts AT the hit frame: successive hits are never faster
	# than the pre-overhaul pacing, so damage per second is preserved.
	_attack_timer = float(character.get("attack_cooldown", 0.45))
	_attack_total = maxf(0.05, _attack_timer)
	if _visual:
		_visual.scale = Vector2(PixelArt.PX, PixelArt.PX)
		if _visual.has_method("set_facing"):
			_visual.call("set_facing", _facing_index(_attack_dir), true)
	var lunge := float(step.get("lunge", 0.0))
	if lunge > 0.0 and not GameSettings.reduce_motion():
		_lunge_impulse = _attack_dir * lunge
	if _chain_style == "bow":
		_fire_arrow(character, str(step.get("arc", "shot")))
		return
	_apply_melee_hit(character, step)


func _apply_melee_hit(character: Dictionary, step: Dictionary) -> void:
	var arc := str(step.get("arc", "lr"))
	_show_slash(arc)
	var attack_range := float(character.get("attack_range", 2.05))
	var multiplier := float(character.get("attack_mult", 1.0))
	var hit_any := false
	var audible_hit := false
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		if not enemy.has_method("take_damage"):
			continue
		var to_enemy: Vector2 = enemy.global_position - global_position
		if to_enemy.length() > attack_range + float(enemy.get("body_radius")):
			continue
		if arc != "slam" and to_enemy.length() > 0.05 and _attack_dir.dot(to_enemy.normalized()) < -0.05:
			continue
		var damage := int(round(float(GameState.attack_power()) * multiplier))
		enemy.call("take_damage", damage, to_enemy.normalized(), self)
		hit_any = true
		if not enemy.has_method("combat_sounds_enabled") or bool(enemy.call("combat_sounds_enabled")):
			audible_hit = true
	var shake := float(_chain.get("shake", 0.07))
	if hit_any:
		if audible_hit:
			Sfx.play("hit", -9.0)
		get_tree().call_group("camera", "shake", shake, float(_chain.get("shake_time", 0.12)))
		if bool(step.get("shockwave", false)):
			# Hammer ground impact: expanding ring + dust + rubble.
			Vfx.ring(global_position + _attack_dir * 0.9, 1.6, Color("#ffd47b"), 0.4)
			Vfx.dust(global_position + _attack_dir * 0.7, 4, Color(0.7, 0.62, 0.5, 0.8))
			Vfx.sparks(global_position + _attack_dir * 1.2, Vector2.UP, Color("#c9b48a"), 6)
	elif bool(step.get("shockwave", false)):
		# A miss still cracks the ground a little.
		Vfx.dust(global_position + _attack_dir * 0.7, 3, Color(0.7, 0.62, 0.5, 0.7))


func _fire_arrow(character: Dictionary, arc_kind: String) -> void:
	var aim := _attack_dir
	var best: Node2D = null
	var best_distance := 999.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		var to_enemy: Vector2 = enemy.global_position - global_position
		var distance := to_enemy.length()
		if distance > 8.5 or distance < 0.1:
			continue
		if _attack_dir.dot(to_enemy.normalized()) < 0.25:
			continue
		if distance < best_distance:
			best = enemy
			best_distance = distance
	if best != null:
		aim = (best.global_position - global_position).normalized()
		facing = aim
		_attack_dir = aim
	var arrow := Arrow.new()
	arrow.direction = aim
	arrow.damage = int(round(float(GameState.attack_power()) * float(character.get("attack_mult", 0.95))))
	arrow.source = self
	arrow.position = get_parent().to_local(global_position + aim * 0.75 + Vector2(0, -0.65))
	get_parent().add_child(arrow)
	# Muzzle flash at the release.
	Vfx.sparks(global_position + aim * 0.75 + Vector2(0, -0.65), aim, Color("#ffe7a1"), 3)
	if _visual and _visual.has_method("set_facing"):
		_visual.call("set_facing", _facing_index(aim), true)


func _show_slash(arc := "lr") -> void:
	if _attack_sprite == null:
		return
	var tex := PixelArt.slash_arc_texture(arc if arc != "shot" else "lr")
	_attack_sprite.texture = tex
	_attack_sprite.visible = true
	_attack_sprite.position = facing * 0.88
	_attack_sprite.rotation = facing.angle() + (0.4 if arc != "slam" else 0.0)
	_attack_sprite.flip_h = arc == "rl"
	var color := Color(1, 0.98, 0.82, 0.95)
	if arc == "slam":
		color = Color(1.0, 0.7, 0.35, 0.95)
	_attack_sprite.modulate = color
	_attack_sprite.scale = Vector2(0.020, 0.020)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_attack_sprite, "scale", Vector2(0.042, 0.042), 0.12)
	tween.tween_property(_attack_sprite, "modulate:a", 0.0, 0.22)
	tween.chain().tween_callback(func() -> void:
		if is_instance_valid(_attack_sprite):
			_attack_sprite.visible = false)


# ------------------------------------------------------------------ interaction

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


func _facing_index(dir: Vector2) -> int:
	if absf(dir.x) > absf(dir.y):
		return 2 if dir.x > 0.0 else 3
	return 0 if dir.y > 0.0 else 1


# ------------------------------------------------------------------ damage & rest

func take_damage(amount: int, from: Vector2 = Vector2.ZERO) -> void:
	if dead or sleeping or invulnerable > 0.0:
		return
	invulnerable = 0.55
	GameState.damage_player(amount)
	hurt_flash.emit()
	if from != Vector2.ZERO:
		var push := (global_position - from).normalized()
		velocity += push * 2.2
	if _visual:
		_visual.call("play_pose", PlayerSprite.Pose.HURT, 0.28)
		var tween := create_tween()
		_visual.modulate = Color("#ff8b7d")
		tween.tween_property(_visual, "modulate", Color.WHITE, 0.22)
	if GameState.health() <= 0:
		die()


func die() -> void:
	dead = true
	sleeping = false
	velocity = Vector2.ZERO
	_attack_phase = AttackPhase.NONE
	attacking = false
	if _visual:
		# Collapse: hurt pose, sink and fade instead of a stiff 90-degree tip.
		_visual.call("play_pose", PlayerSprite.Pose.HURT)
		var tween := create_tween().set_parallel(true)
		tween.tween_property(_visual, "rotation", -0.5, 0.4)
		tween.tween_property(_visual, "scale", Vector2(PixelArt.PX * 1.25, PixelArt.PX * 0.55), 0.4)
		tween.tween_property(_visual, "modulate:a", 0.3, 0.5)
		Vfx.dust(global_position, 4)


func revive_at(position: Vector2) -> void:
	global_position = position
	dead = false
	controls_locked = false
	sleeping = false
	velocity = Vector2.ZERO
	if _visual:
		_visual.rotation = 0.0
		_visual.modulate.a = 1.0
		_visual.scale = Vector2(PixelArt.PX, PixelArt.PX)
		_visual.call("play_pose", PlayerSprite.Pose.IDLE)


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
		_visual.call("play_pose", PlayerSprite.Pose.SLEEP)
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
		_visual.call("play_pose", PlayerSprite.Pose.IDLE)
	sleep_changed.emit(false, 0.0, reason)
	toast(reason, "bad")


func toast(text: String, tone: String = "info") -> void:
	GameState.toast_requested.emit(text, tone)


func get_facing_angle() -> float:
	return facing.angle()


func cooldown_fraction() -> float:
	# 1.0 right after a hit frame, easing to 0.0; drives the HUD cooldown sweep.
	if _attack_timer <= 0.0:
		return 0.0
	return clampf(_attack_timer / _attack_total, 0.0, 1.0)


func play_pickup(reach: float = 1.3) -> void:
	var net := Sprite2D.new()
	net.texture = PixelArt.net_texture()
	net.scale = Vector2.ONE * PixelArt.PX * 2.1
	net.position = Vector2(0.5, -0.7)
	net.z_index = 12
	add_child(net)
	var tween := net.create_tween()
	tween.tween_property(net, "rotation", -0.9, 0.16)
	tween.parallel().tween_property(net, "position", Vector2(reach, -0.2), 0.16)
	tween.tween_property(net, "position", Vector2(0.2, -1), 0.18)
	tween.parallel().tween_property(net, "modulate:a", 0.0, 0.18)
	tween.tween_callback(net.queue_free)
