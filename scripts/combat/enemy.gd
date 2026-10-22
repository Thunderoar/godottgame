class_name Enemy
extends CharacterBody2D
## Reusable regular monster / boss body with an explicit state machine:
## SPAWN -> (IDLE/WANDER) -> ALERT -> CHASE -> WINDUP -> ATTACK -> RECOVER
## -> STAGGER -> DEAD. Damage is dealt on the ATTACK (active) frame only, after
## a visible telegraph (wind-up pose + pulsing ground decal). Groups soften into
## separation steering so monsters never stack into one pixel, and each kind
## moves with its own personality (bogling shamble, drowned lunge, rubbish
## skitter, raider weave).
##
## Kept contracts: groups enemies/forest_monsters, take_damage(amount, from_dir,
## source), _can_see_player(), body_radius, settlement_mode/forest_mode
## targeting, kind == "rubbish" rewards, boss specials, _charging flow used by
## the acceptance suite.

signal boss_started(enemy: Enemy)
signal boss_finished(enemy: Enemy)

enum State { SPAWN, WANDER, ALERT, CHASE, WINDUP, ATTACK, RECOVER, STAGGER, DEAD }

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
var sprite: Sprite2D
var _state := State.SPAWN
var _state_time := 0.35

var _player: Node2D
var _target: Node2D
var _special_timer := 2.5
var _charging := false
var _charge_time := 0.0
var _charge_dir := Vector2.ZERO
var _charge_hit := false
var _alternate_charge := false
var _shadow: Sprite2D
var _attack_timer := 0.0
var _hit_flash := 0.0
var _bob := 0.0
var _frame_timer := 0.0
var _frame := 0
var _knockback := Vector2.ZERO
var _boss_notified := false
var _saw_player := false
var _freeze := 0.0
var _telegraph: Sprite2D
var _alert_icon: Sprite2D
var _alert_time := 0.0
var _cached_enemies: Array = []
var _separation_timer := 0.0
var _move_phase := 0.0
var _personality := {}
var _wander_dir := Vector2.ZERO
var _wander_timer := 0.0
var _hit_dealt := false


func _ready() -> void:
	add_to_group("enemies")
	if forest_mode:
		add_to_group("forest_monsters")
	collision_layer = 4
	collision_mask = 1
	hp = max_hp
	_player = get_tree().get_first_node_in_group("player")
	_personality = _personality_for(kind)
	_build()
	# A short spawn-in shimmer so monsters do not pop into the dark.
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.35)
	spawning = false


func _personality_for(kind_id: String) -> Dictionary:
	match kind_id:
		"bogling":
			return {"shamble": 0.38, "shamble_rate": 2.1}
		"drowned":
			return {"lunge_cycle": 2.3, "lunge_speed": 1.9, "lunge_time": 0.5}
		"rubbish":
			return {"skitter": 0.5, "skitter_rate": 0.4}
		"raider":
			return {"weave": 0.25, "weave_rate": 1.7}
		_:
			return {}


func _build() -> void:
	var size := 64 if is_boss else 32
	_shadow = Sprite2D.new()
	_shadow.texture = PixelArt.light_texture()
	_shadow.scale = Vector2(float(size) * 0.00052, float(size) * 0.00028)
	_shadow.modulate = Color(0, 0, 0, 0.4)
	_shadow.position = Vector2(0, -0.05)
	_shadow.z_index = -1
	add_child(_shadow)

	sprite = Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = PixelArt.enemy_texture(kind, is_boss, 0)
	sprite.scale = Vector2(PixelArt.PX, PixelArt.PX)
	sprite.position = Vector2(0, -float(size) * 0.5 * PixelArt.PX)
	sprite.z_index = 6
	add_child(sprite)

	# Telegraph decal: a pulsing disc under the body while winding up.
	_telegraph = Sprite2D.new()
	_telegraph.texture = PixelArt.light_texture()
	_telegraph.modulate = Color(0.95, 0.45, 0.35, 0.0)
	_telegraph.z_as_relative = false
	_telegraph.z_index = 1
	_telegraph.scale = Vector2(0.02, 0.011)
	add_child(_telegraph)

	var shape := CollisionShape2D.new()
	shape.name = "Shape"
	var circle := CircleShape2D.new()
	circle.radius = body_radius
	shape.shape = circle
	shape.position = Vector2(0, -body_radius * 0.5)
	add_child(shape)


func apply_hit_stop(seconds: float) -> void:
	# HitFeedback contract: freeze logic for a beat without pausing the tree.
	_freeze = maxf(_freeze, seconds)


func _physics_process(delta: float) -> void:
	if dead:
		return
	if _freeze > 0.0:
		_freeze -= delta
		return
	_bob += delta
	_move_phase += delta
	_state_time -= delta
	_frame_timer += delta
	if _frame_timer >= 0.35:
		_frame_timer -= 0.35
		_frame = 1 - _frame
		if sprite and _state not in [State.WINDUP, State.STAGGER]:
			sprite.texture = PixelArt.enemy_texture(kind, is_boss, _frame)
	if sprite and _state not in [State.WINDUP]:
		sprite.position.y = -float(64 if is_boss else 32) * 0.5 * PixelArt.PX + sin(_bob * 4.0) * 0.03
	if _hit_flash > 0.0:
		_hit_flash = maxf(0.0, _hit_flash - delta)
		if sprite:
			sprite.modulate = Color(1.8, 1.4, 1.4) if _hit_flash > 0.0 else Color.WHITE
	if _attack_timer > 0.0:
		_attack_timer = maxf(0.0, _attack_timer - delta)
	if _special_timer > 0.0:
		_special_timer = maxf(0.0, _special_timer - delta)
	if _alert_time > 0.0:
		_alert_time -= delta
		if _alert_icon:
			_alert_icon.modulate.a = clampf(_alert_time * 2.2, 0.0, 1.0)
			_alert_icon.position.y = -1.7 - sin(_bob * 9.0) * 0.05
			if _alert_time <= 0.0:
				_alert_icon.queue_free()
				_alert_icon = null
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

	match _state:
		State.SPAWN:
			if _state_time <= 0.0:
				_enter(State.WANDER if not settlement_mode else State.CHASE)
		State.WANDER:
			_wander(delta)
		State.ALERT:
			velocity = velocity.move_toward(Vector2.ZERO, delta * 6.0)
			move_and_slide()
			if _state_time <= 0.0:
				_enter(State.CHASE)
		State.CHASE:
			_chase(delta)
		State.WINDUP:
			_windup(delta)
		State.ATTACK:
			_attack_active(delta)
		State.RECOVER:
			velocity = velocity.move_toward(Vector2.ZERO, delta * 8.0)
			move_and_slide()
			if _state_time <= 0.0:
				_enter(State.CHASE)
		State.STAGGER:
			velocity = velocity.move_toward(Vector2.ZERO, delta * 10.0)
			move_and_slide()
			if _state_time <= 0.0:
				_enter(State.CHASE)
	queue_redraw()


# ------------------------------------------------------------------ states

func _enter(next: State) -> void:
	_state = next
	match next:
		State.ALERT:
			_state_time = 0.3
			_show_alert()
		State.CHASE:
			_state_time = 0.0
		State.WINDUP:
			_state_time = 0.42 if not is_boss else 0.55
			_hit_dealt = false
			_telegraph.modulate.a = 0.0
			if sprite:
				# Rear back while winding up.
				var back := Vector2.ZERO
				if is_instance_valid(_target):
					back = -( _target.global_position - global_position).normalized() * 0.16
				var tween := create_tween()
				tween.tween_property(sprite, "position", Vector2(back.x, -float(64 if is_boss else 32) * 0.5 * PixelArt.PX + back.y), 0.18)
				tween.parallel().tween_property(sprite, "scale", Vector2(PixelArt.PX * 1.12, PixelArt.PX * 0.94), 0.2)
			Sfx.play("aggro", -14.0)
		State.ATTACK:
			_state_time = 0.14
		State.RECOVER:
			_state_time = 0.5 if not is_boss else 0.6
			_clear_windup_pose()
		State.STAGGER:
			_state_time = 0.2
			_clear_windup_pose()


func _clear_windup_pose() -> void:
	if sprite:
		sprite.scale = Vector2(PixelArt.PX, PixelArt.PX)
		sprite.position = Vector2(0, -float(64 if is_boss else 32) * 0.5 * PixelArt.PX)


func _wander(delta: float) -> void:
	# Idle drift for un-aggroed dungeon monsters; aggro pulls them out of it.
	if is_instance_valid(_player) and not settlement_mode and not forest_mode:
		if global_position.distance_to(_player.global_position) <= _aggro_range():
			if not active:
				active = true
				_notify_boss_start()
			_enter(State.ALERT)
			return
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(1.2, 2.8)
		_wander_dir = Vector2.from_angle(randf() * TAU) * 0.35
	velocity = velocity.move_toward(_wander_dir * speed * 0.4, delta * 4.0)
	_separate(delta)
	move_and_slide()


func _chase(delta: float) -> void:
	if not is_instance_valid(_target):
		velocity = velocity.move_toward(Vector2.ZERO, delta * 4.0)
		move_and_slide()
		return
	if not active:
		active = true
		_notify_boss_start()
	var to_target: Vector2 = _target.global_position - global_position
	var distance := to_target.length()
	if distance > _aggro_range() * 1.6 and not settlement_mode and not forest_mode:
		# Lost the player: settle back down.
		active = false
		_enter(State.WANDER)
		return
	var stop := body_radius + 0.55
	if distance <= stop:
		velocity = Vector2.ZERO
		move_and_slide()
		if _attack_timer <= 0.0:
			_enter(State.WINDUP)
		return
	# Hysteresis: only re-approach once clearly out of reach.
	if distance > stop * 1.25:
		var dir := to_target.normalized()
		dir = _apply_personality(dir)
		velocity = dir * speed
		_separate(delta)
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		move_and_slide()
	if is_boss and _boss_notified:
		GameState.boss_health_changed.emit(true, _boss_name(), hp, max_hp)
		if _special_timer <= 0.0:
			_special_timer = special_cooldown
			_cast_special()


func _aggro_range() -> float:
	return 14.0 if settlement_mode else (8.5 if is_boss else 6.2)


func _windup(delta: float) -> void:
	# Face the target, hold still and pulse the ground decal. No damage yet.
	velocity = Vector2.ZERO
	move_and_slide()
	if is_instance_valid(_target):
		var to_target := _target.global_position - global_position
		if sprite and to_target.length() > 0.1:
			sprite.flip_h = to_target.x < 0.0
	if _telegraph:
		var pulse := 0.28 + absf(sin(_bob * 10.0)) * 0.16
		_telegraph.modulate = Color(0.95, 0.4, 0.32, pulse)
		_telegraph.scale = Vector2(0.026, 0.014)
	if _state_time <= 0.0:
		_enter(State.ATTACK)


func _attack_active(_delta: float) -> void:
	# Damage lands once, on the first active frame.
	if not _hit_dealt:
		_hit_dealt = true
		var reach := body_radius + 1.35
		if is_instance_valid(_target):
			var to_target := _target.global_position - global_position
			if to_target.length() <= reach:
				if _target.has_method("take_damage"):
					_target.call("take_damage", damage, global_position)
				elif _target.has_method("take_attack_damage"):
					_target.call("take_attack_damage", damage)
			if to_target.length() > 0.1:
				_lunge(to_target.normalized())
		if _telegraph:
			_telegraph.modulate.a = 0.0
		_attack_timer = 1.15 if is_boss else attack_interval
	if _state_time <= 0.0:
		_enter(State.RECOVER)


func _apply_personality(dir: Vector2) -> Vector2:
	# Per-kind movement character so monsters do not all glide the same way.
	var out := dir
	if _personality.has("shamble"):
		var w := 1.0 + sin(_move_phase * float(_personality["shamble_rate"])) * float(_personality["shamble"])
		out = dir.rotated(sin(_move_phase * 1.3) * 0.18) * maxf(0.35, w)
	elif _personality.has("lunge_cycle"):
		var cycle := fmod(_move_phase, float(_personality["lunge_cycle"]))
		if cycle < float(_personality["lunge_time"]):
			out = dir * float(_personality["lunge_speed"])
		else:
			out = dir * 0.45
	elif _personality.has("skitter"):
		out = dir.rotated(sin(_move_phase / float(_personality["skitter_rate"])) * 0.6)
	elif _personality.has("weave"):
		out = dir.rotated(sin(_move_phase * float(_personality["weave_rate"])) * float(_personality["weave"]))
	return out


func _separate(delta: float) -> void:
	# Soft repulsion from nearby monsters so packs never stack. The group list
	# is cached and refreshed on a timer (no per-frame group scans at scale).
	_separation_timer -= delta
	if _separation_timer <= 0.0:
		_separation_timer = 0.25
		_cached_enemies = get_tree().get_nodes_in_group("enemies")
	var push := Vector2.ZERO
	var reach := body_radius * 2.6
	for other in _cached_enemies:
		# Freed bodies can linger in the cache until the next refresh.
		if other == self or not is_instance_valid(other) or not (other is Node2D):
			continue
		var to_other: Vector2 = (other as Node2D).global_position - global_position
		var d := to_other.length()
		if d > reach or d < 0.0001:
			continue
		push -= to_other / d * (1.0 - d / reach)
	if push.length_squared() > 0.001:
		velocity += push.limit_length(1.0) * speed * 0.65


func _show_alert() -> void:
	# A small "!" over the head when the monster notices the player.
	if _alert_icon != null and is_instance_valid(_alert_icon):
		return
	_alert_icon = Sprite2D.new()
	_alert_icon.texture = PixelArt.icon("spark", 16)
	_alert_icon.scale = Vector2(0.05, 0.05)
	_alert_icon.modulate = Color("#ffd455")
	_alert_icon.position = Vector2(0, -1.7)
	_alert_icon.z_as_relative = false
	_alert_icon.z_index = 702
	add_child(_alert_icon)
	_alert_time = 0.6
	Sfx.play("aggro", -12.0)


# ------------------------------------------------------------------ boss specials

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
	Vfx.ring(global_position + Vector2(0, -0.4), 1.8, Color("#ff8b5f"), 0.4)
	if distance <= 3.8 and _target.has_method("take_damage"):
		_target.call("take_damage", special_damage, global_position)
	_lunge((_target.global_position - global_position).normalized())


func _area_slam() -> void:
	var origin := global_position
	# Telegraph the slam radius before it lands.
	Vfx.ring(origin, 4.2, Color("#d96464"), 0.55)
	_telegraph.modulate = Color(0.95, 0.4, 0.32, 0.4)
	_telegraph.scale = Vector2(0.075, 0.04)
	await get_tree().create_timer(0.55).timeout
	if dead or not is_inside_tree():
		return
	_telegraph.modulate.a = 0.0
	if _target != null and is_instance_valid(_target):
		if origin.distance_to(_target.global_position) <= 4.2 and _target.has_method("take_damage"):
			_target.call("take_damage", special_damage, origin)
	Vfx.ring(origin, 4.2, Color("#ff9f78"), 0.45)
	Vfx.dust(origin, 4)
	Sfx.play("hit", -10.0)


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
	Vfx.sparks(global_position + Vector2(0, -1.2), orb.direction, orb.tint, 4)


func _begin_charge() -> void:
	if not is_instance_valid(_target):
		return
	_charging = true
	_charge_time = 0.38
	_charge_hit = false
	_charge_dir = (_target.global_position - global_position).normalized()
	Vfx.ring(global_position + Vector2(0, -0.4), 1.6, Color("#f5c96b"), 0.4)
	Sfx.play("charge", -6.0)


func _process_charge(delta: float) -> void:
	_charge_time -= delta
	velocity = _charge_dir * speed * 4.8
	move_and_slide()
	if sprite:
		sprite.rotation = _charge_dir.angle() * 0.08
	if not _charge_hit and is_instance_valid(_player):
		if global_position.distance_to(_player.global_position) <= 1.15 and _player.has_method("take_damage"):
			_charge_hit = true
			_player.call("take_damage", special_damage, global_position)
			Vfx.ring(global_position, 1.4, Color("#ffc966"), 0.35)
	if _charge_time <= 0.0:
		_charging = false
		velocity = Vector2.ZERO
		if sprite:
			sprite.rotation = 0.0
		if _state in [State.WINDUP, State.ATTACK]:
			_enter(State.RECOVER)


func _notify_boss_start() -> void:
	if is_boss and not _boss_notified:
		_boss_notified = true
		boss_started.emit(self)
		GameState.boss_health_changed.emit(true, _boss_name(), hp, max_hp)


# ------------------------------------------------------------------ forest / settlement targeting

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
	if sprite == null:
		return
	var base := sprite.position
	var tween := create_tween()
	tween.tween_property(sprite, "position", base + dir * 0.22, 0.09)
	tween.tween_property(sprite, "position", Vector2(0, -float(64 if is_boss else 32) * 0.5 * PixelArt.PX), 0.14)


# ------------------------------------------------------------------ damage & death

func take_damage(amount: int, from_dir: Vector2 = Vector2.ZERO, _source: Node = null) -> void:
	if dead:
		return
	hp = maxi(0, hp - amount)
	_hit_flash = 0.14
	var opts := {"shake": 0.06, "shake_time": 0.1}
	if is_boss:
		# Bosses shrug off staggers; they get an armour flash instead.
		opts["shake"] = 0.1
		opts["hitstop"] = 0.0
	else:
		opts["hitstop"] = 0.03
	HitFeedback.impact(self, from_dir, amount, opts)
	if from_dir != Vector2.ZERO:
		_knockback = from_dir * (5.0 if is_boss else 6.5)
	if not is_boss and _state == State.WINDUP:
		# A solid hit interrupts the wind-up: the telegraph can be beaten.
		# (Chase is deliberately not staggered, or fast weapons would stunlock.)
		_enter(State.STAGGER)
	if is_boss:
		GameState.boss_health_changed.emit(true, _boss_name(), hp, max_hp)
	if hp <= 0:
		_die()
	queue_redraw()


func _die() -> void:
	if dead:
		return
	dead = true
	_state = State.DEAD
	if _alert_icon != null and is_instance_valid(_alert_icon):
		_alert_icon.queue_free()
	_telegraph.modulate.a = 0.0
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
	# Death presentation: pop, burst of motes and a knock-slide, then fade.
	var death_color := Color("#e8b46b")
	match kind:
		"bogling":
			death_color = Color("#8fbf5d")
		"drowned":
			death_color = Color("#9fd8c8")
		"rubbish":
			death_color = Color("#b0c48a")
	Vfx.burst(global_position + Vector2(0, -0.5), death_color, 9)
	Vfx.ring(global_position + Vector2(0, -0.4), 1.1, death_color, 0.35)
	Sfx.play("hit", -8.0)
	if is_boss:
		GameState.boss_health_changed.emit(false, _boss_name(), 0, max_hp)
		boss_finished.emit(self)
	velocity = Vector2.ZERO
	collision_layer = 0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.9)
	tween.tween_property(self, "scale", Vector2(1.15, 0.8), 0.9)
	tween.tween_property(self, "position", global_position + _knockback.limit_length(1.2) * 0.2, 0.9)
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
	# Loot "spits" out of the body in a short arc.
	gold_drop.pop_velocity = Vector2(rng.randf_range(-1.6, 1.6), -rng.randf_range(1.2, 2.4))
	parent.call_deferred("add_child", gold_drop)
	if rng.randf() < diamond_chance:
		var gem := LootDrop.new()
		gem.kind = "diamond"
		gem.amount = 1
		gem.position = global_position + Vector2(0.45, -0.2)
		gem.pop_velocity = Vector2(rng.randf_range(0.8, 1.8), -rng.randf_range(1.4, 2.2))
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
