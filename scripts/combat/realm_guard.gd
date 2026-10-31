class_name RealmGuard
extends Enemy
## Narrow realm FSM: no ElementDB changes or inherited automatic elemental cast.

enum Mode { RESTING, ENGAGED, RETURNING }
var profile := "imp"
var encounter_id := ""
var home := Vector2.ZERO
var director: RealmEncounterDirector
var mode := Mode.RESTING
var cast_serial := 0
var action: RealmGuardAttack
var _cooldown := 0.0
var _name_label: Label

func _ready() -> void:
	kind = "minion_chaos"
	super._ready()
	_state = State.WANDER
	_name_label = Label.new()
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_label.scale = Vector2.ONE*PixelArt.PX
	_name_label.position = Vector2(-2.5,-2.6)
	_name_label.size = Vector2(160,30)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size",13)
	_name_label.add_theme_color_override("font_outline_color",Color("#181a2b"))
	_name_label.add_theme_constant_override("outline_size",4)
	_name_label.text = name_text()
	add_child(_name_label)
	_update_guard_art()

func _sprite_rest_scale() -> Vector2:
	return Vector2.ONE*PixelArt.PX*(64.0/sprite.texture.get_height())

func _sprite_rest_position() -> Vector2:
	return Vector2(0,-0.9)

func name_text() -> String:
	return str(RealmCombatDB.PROFILES[profile].name)

func engage() -> void:
	if mode == Mode.ENGAGED: return
	mode = Mode.ENGAGED
	active = true
	_cooldown = 0.45 + (0.25 if profile != "imp" else 0.0)
	_enter(State.ALERT)

func return_home() -> void:
	cancel_action()
	mode = Mode.RETURNING
	active = false
	_state = State.WANDER
	_route.clear()
	_route_clock = 0
	velocity = Vector2.ZERO
	_knockback = Vector2.ZERO

func cancel_action() -> void:
	cast_serial += 1
	_charging = false
	_charge_time = 0
	_charge_hit = false
	_hit_dealt = false
	if is_instance_valid(action): action.cancel()
	action = null
	if director != null: director.release(self)
	_clear_windup_pose()
	if is_instance_valid(_telegraph): _telegraph.modulate.a = 0

func _enter(next: State) -> void:
	if next == State.STAGGER: cancel_action()
	super._enter(next)

func _die() -> void:
	if dead: return
	cancel_action()
	super._die()

func _physics_process(delta: float) -> void:
	if dead or director == null: return
	if not director.current_world():
		cancel_action()
		return
	var animation_delta := delta
	if _freeze > 0:
		_freeze = maxf(0,_freeze-delta)
		animation_delta = 0
	_bob += animation_delta
	_route_clock -= delta
	_state_time -= delta
	_cooldown = maxf(0,_cooldown-delta)
	_hit_flash = maxf(0,_hit_flash-delta)
	if _alert_time > 0:
		_alert_time = maxf(0,_alert_time-delta)
		if is_instance_valid(_alert_icon) and _alert_time <= 0:
			_alert_icon.queue_free()
			_alert_icon = null
	_update_guard_art()
	_name_label.visible = (mode == Mode.ENGAGED or director.world.player.position.distance_to(position) < 2.5) and mode != Mode.RETURNING
	if mode == Mode.ENGAGED and not director.can_attack(self): return_home()
	if mode == Mode.RESTING: return
	if mode == Mode.RETURNING:
		if position.distance_to(home) < 0.12:
			mode = Mode.RESTING
			velocity = Vector2.ZERO
			return
		_move_step(director.return_direction(self),delta)
		return
	if _knockback.length_squared() > 0.01:
		_move_motion(_knockback*delta)
		_knockback = _knockback.move_toward(Vector2.ZERO,18*delta)
		return
	if is_instance_valid(action): return # Its owned component advances windup/active.
	if _state in [State.ALERT,State.RECOVER,State.STAGGER] and _state_time > 0: return
	_state = State.CHASE
	velocity = Vector2.ZERO
	var target := director.world.player.position
	var distance := position.distance_to(target)
	var in_range := distance < (3.8 if profile == "imp" else 5.5)
	if in_range and _cooldown <= 0 and begin_action(): return
	# Casters hold their ground within casting distance; closing remains viable.
	var stop := 1.2 if profile == "imp" else 4.0
	if distance > stop:
		var path := director.routes[encounter_id] as RealmGuardRoutes
		if _route_clock <= 0 or target.distance_to(_route_goal) > 1:
			_route_clock = 0.6
			_route_goal = target
			_route = path.path(position,target,false)
			_route_index = 0
		while _route_index < _route.size()-1 and position.distance_to(_route[_route_index]) < 0.25: _route_index += 1
		if not _route.is_empty(): _move_step(position.direction_to(_route[_route_index]),delta)

func begin_action() -> bool:
	if not director.can_attack(self) or is_instance_valid(action) or _cooldown > 0: return false
	var target := director.world.player.position
	if not director.line_clear(position,target): return false
	var attack_type := profile
	if profile == "watcher" and position.distance_to(target) < 2.8: attack_type = "melee"
	if attack_type == "melee" and position.distance_to(target) > 1.65: return false
	if profile == "keeper" and not RealmGuardAttack.cross_has_escape(director,target): return false
	if not director.claim(self): return false
	cast_serial += 1
	_cooldown = float(RealmCombatDB.PROFILES[profile].cooldown) * CombatBalance.ATTACK_INTERVAL
	_state = State.WINDUP
	velocity = Vector2.ZERO
	_knockback = Vector2.ZERO
	director.world.close_reading()
	action = RealmGuardAttack.new()
	action.caster = self
	action.attack_type = attack_type
	action.serial = cast_serial
	action.epoch = director.generation
	action.origin = position
	action.aim = target
	director.effects.append(action)
	director.world.add_child(action)
	return true

func finish_action(subject: RealmGuardAttack, interrupted: bool) -> void:
	if action != subject: return
	action = null
	_charging = false
	velocity = Vector2.ZERO
	director.release(self)
	if not dead:
		_state = State.STAGGER if interrupted else State.RECOVER
		_state_time = 0.2 if interrupted else float(RealmCombatDB.PROFILES[profile].recovery)
	_clear_windup_pose()

func _move_step(direction: Vector2, delta: float) -> void:
	velocity = direction*speed
	_move_motion(direction*speed*delta)
	if direction.length_squared() > 0.01: sprite.flip_h = direction.x < 0

func _move_motion(motion: Vector2) -> void:
	var allowed := director.travel(self,motion)
	if allowed.length_squared() > 0.0000001: move_and_collide(allowed)

func _update_guard_art() -> void:
	var frame := 0
	if _state == State.WINDUP: frame = 2
	elif _state == State.RECOVER: frame = 3
	elif not GameSettings.reduce_motion(): frame = int(_bob*3)%2
	sprite.texture = RealmCombatArt.guard_texture(profile,frame)
	sprite.scale = _sprite_rest_scale()
	sprite.position = _sprite_rest_position()
	if not GameSettings.reduce_motion(): sprite.position.y += sin(_bob*3)*0.02
	sprite.modulate = Color(1.7,1.3,1.3) if _hit_flash > 0 else Color.WHITE
	sprite.texture_filter = VisualStyle.texture_filter()
