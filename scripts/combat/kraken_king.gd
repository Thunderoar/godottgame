class_name KrakenKing
extends Enemy
## A guarded prison arm and a repeating drag, ink-fan and tentacle-whirl cycle.
const WARNING_SECONDS := 0.9
const EXTEND_SECONDS := 0.4
const IMPACT_SECONDS := WARNING_SECONDS + EXTEND_SECONDS
const RELEASE_SECONDS := 3.1
const MAX_TENTACLE_REACH := 18.0
const WALK_SPEED := 1.8
const ARENA_AGGRO_RANGE := 32.0
const INK_WARNING := 0.85
const INK_SPEED := 12.0
const SPIN_WARNING := 1.0
const SPIN_SECONDS := 1.4
const SPIN_RADIUS := 5.6
var prison: Node2D
var tentacle_time := -1.0
var tentacle_target := Vector2.ZERO
var tentacle_tip := Vector2.ZERO
var hook_attack := false
var grabbing := false
var _impact_done := false
var power := ""
var power_time := -1.0
var _power_index := 0
var _ink_target := Vector2.ZERO
var _ink_origin := Vector2.ZERO
var ink_shots: Array[Dictionary] = []
var _ink_fired := false
var _ink_hit := false
var _spin_hit := false
var _ink_lanes := PackedVector2Array()
var _spin_tips := PackedVector2Array()

func _ready() -> void:
	kind = "kraken_king"
	is_boss = true
	max_hp = 720
	damage = 16
	special_damage = 22
	speed = WALK_SPEED
	body_radius = 2.1
	boss_ability = "tentacle"
	boss_ability_name = "Royal Tentacles: Drag / Ink / Whirl"
	special_cooldown = 4.5
	dungeon_alerted = true
	super._ready()
	_update_body()
	_shadow.scale = Vector2(0.055,0.028)
	var bar := get_node_or_null("BossHealth")
	if bar: bar.position.y = -6.4

func _update_body() -> void:
	sprite.texture = KrakenArt.body_texture()
	sprite.texture_filter=VisualStyle.texture_filter()

func _sprite_rest_scale() -> Vector2:
	return Vector2.ONE*PixelArt.PX*1.5

func _sprite_rest_position() -> Vector2:
	return Vector2(0,-2.5)

func _physics_process(delta: float) -> void:
	if dead: return
	if get_parent() is KrakenIsland:
		var game := get_tree().get_first_node_in_group("game") as Game
		if not is_instance_valid(game) or game.world != get_parent() or is_queued_for_deletion():
			_cancel_powers()
			return
	if power_time >= 0:
		velocity = Vector2.ZERO
		_hit_flash = maxf(0,_hit_flash-delta)
		if _hit_flash <= 0: sprite.modulate = Color.WHITE
		_update_power(delta)
		_update_ink(delta)
		_update_body()
		queue_redraw()
		return
	super._physics_process(delta)
	_update_body()
	_update_tentacle(delta)
	_update_power(delta)
	_update_ink(delta)
	queue_redraw()

func _aggro_range() -> float:
	return ARENA_AGGRO_RANGE

func _chase(delta: float) -> void:
	if tentacle_time >= 0:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if _special_timer <= 0 and _boss_notified:
		var next := _power_index % 3
		_power_index += 1
		if next != 0:
			_special_timer = special_cooldown
			_begin_power("ink" if next == 1 else "spin")
			return
	super._chase(delta)

func _owns_power() -> bool:
	var game := get_tree().get_first_node_in_group("game") as Game
	return not dead and not is_queued_for_deletion() and get_parent() is KrakenIsland and is_instance_valid(game) and game.world == get_parent() and is_instance_valid(_player) and not _player.dead and _player.get_parent() == get_parent()

func _begin_power(kind: String) -> void:
	if not _owns_power() or tentacle_time >= 0 or power_time >= 0: return
	power = kind
	power_time = 0
	velocity = Vector2.ZERO
	ink_shots.clear()
	_ink_fired = false
	_ink_hit = false
	_spin_hit = false
	var reach := _player.global_position-global_position
	_ink_origin = global_position + reach.normalized()*minf(4,reach.length()*0.6)
	var wall := _world_hit(global_position,_ink_origin)
	if not wall.is_empty(): _ink_origin = wall.position-reach.normalized()*0.3
	_ink_target = _player.global_position
	_refresh_power_geometry()
	queue_redraw()

func _update_power(delta: float) -> void:
	if power_time < 0: return
	if not _owns_power():
		_cancel_powers()
		return
	power_time += delta
	_refresh_power_geometry()
	queue_redraw()
	if power == "ink":
		if power_time >= INK_WARNING and not _ink_fired:
			_ink_fired = true
			var aim := _ink_origin.direction_to(_ink_target)
			if aim == Vector2.ZERO: aim = Vector2.DOWN
			for angle in [-0.18,0.0,0.18]:
				ink_shots.append({"at":_ink_origin,"direction":aim.rotated(angle),"life":2.7,"delay":clampf(INK_WARNING-(power_time-delta),0,delta)})
			Sfx.play("kraken_ink", -10)
		if power_time >= INK_WARNING + 0.45:
			power_time = -1
			power = ""
	elif power == "spin":
		if power_time >= SPIN_WARNING and power_time-delta < SPIN_WARNING + SPIN_SECONDS and not _spin_hit:
			if global_position.distance_to(_player.global_position) <= SPIN_RADIUS and not _world_blocked(global_position, _player.global_position):
				_spin_hit = true
				_player.take_damage(special_damage, global_position)
			if power_time - delta < SPIN_WARNING: Sfx.play("kraken_spin", -12)
		if power_time >= SPIN_WARNING + SPIN_SECONDS + 0.45:
			power_time = -1
			power = ""

func _world_hit(from: Vector2, to: Vector2) -> Dictionary:
	var query := PhysicsRayQueryParameters2D.create(from,to,1)
	return get_world_2d().direct_space_state.intersect_ray(query)

func _world_blocked(from: Vector2, to: Vector2) -> bool:
	return not _world_hit(from,to).is_empty()

func _update_ink(delta: float) -> void:
	if ink_shots.is_empty(): return
	if not _owns_power():
		ink_shots.clear()
		return
	for shot in ink_shots.duplicate():
		var step := maxf(0,delta-float(shot.get("delay",0)))
		shot.delay = 0.0
		var before: Vector2 = shot.at
		var after: Vector2 = before + Vector2(shot.direction) * INK_SPEED * step
		var wall := _world_hit(before,after)
		if not wall.is_empty(): after = wall.position
		shot.at = after
		shot.life = float(shot.life) - step
		var contact := Geometry2D.get_closest_point_to_segment(_player.global_position,before,after)
		var hit := contact.distance_to(_player.global_position) <= 0.75
		if hit and not _ink_hit:
			_ink_hit = true # One fan pays at most one hit, even if blink is cleared.
			_player.take_damage(maxi(1,roundi(special_damage * 0.65)), before)
		if hit or not wall.is_empty() or float(shot.life) <= 0:
			ink_shots.erase(shot)
	queue_redraw()

func _refresh_power_geometry() -> void:
	_ink_lanes.clear()
	_spin_tips.clear()
	if power == "ink":
		var aim := _ink_origin.direction_to(_ink_target)
		for angle in [-0.18,0.0,0.18]:
			var end := _ink_origin + aim.rotated(angle) * minf(20,_ink_origin.distance_to(_ink_target)+3)
			var wall := _world_hit(_ink_origin,end)
			_ink_lanes.append(wall.position if not wall.is_empty() else end)
	elif power == "spin":
		var angle := maxf(0,power_time-SPIN_WARNING) * TAU * (0.0 if GameSettings.reduce_motion() else 1.25)
		for i in 8:
			var tip := global_position + Vector2.from_angle(angle+TAU*i/8) * SPIN_RADIUS
			var wall := _world_hit(global_position,tip)
			_spin_tips.append(wall.position if not wall.is_empty() else tip)

func _cancel_powers() -> void:
	ink_shots.clear()
	_ink_lanes.clear()
	_spin_tips.clear()
	power_time = -1
	power = ""
	tentacle_time = -1
	grabbing = false
	queue_redraw()

func _die() -> void:
	_cancel_powers()
	super._die()

func _cast_special() -> void:
	if dead or tentacle_time >= 0 or power_time >= 0 or not is_instance_valid(_player) or bool(_player.get("dead")): return
	velocity = Vector2.ZERO
	hook_attack = not hook_attack
	var origin := global_position + Vector2(-1,-0.6)
	tentacle_target = origin + (_player.global_position-origin).limit_length(MAX_TENTACLE_REACH)
	tentacle_tip = origin
	tentacle_time = 0
	grabbing = false
	_impact_done = false

func _update_tentacle(delta: float) -> void:
	if tentacle_time < 0: return
	if not is_instance_valid(_player) or bool(_player.get("dead")):
		tentacle_time = -1
		grabbing = false
		return
	tentacle_time += delta
	var origin := global_position + Vector2(-1,-0.6)
	if tentacle_time < WARNING_SECONDS:
		tentacle_tip = origin
	elif tentacle_time < IMPACT_SECONDS:
		tentacle_tip = origin.lerp(tentacle_target,(tentacle_time-WARNING_SECONDS)/EXTEND_SECONDS)
	elif tentacle_time < IMPACT_SECONDS+0.18:
		tentacle_tip = tentacle_target
		if not _impact_done:
			_impact_done = true
			var hit := _hook_hits(_player.global_position,origin,tentacle_target) if hook_attack else tentacle_target.distance_to(_player.global_position) < 2.1
			Vfx.ring(tentacle_target,2.1,Color("#dd97bd"),0.4)
			if hit and float(_player.get("invulnerable")) <= 0:
				_player.call("take_damage",special_damage,global_position)
				grabbing = hook_attack and not bool(_player.get("dead"))
	elif tentacle_time < 2.65 and grabbing:
		var distance := global_position.distance_to(_player.global_position)
		if distance > 3.2:
			var goal := global_position + (_player.global_position-global_position).normalized()*3.2
			var motion := _player.global_position.direction_to(goal)*minf(6.0*delta,_player.global_position.distance_to(goal))
			(_player as CharacterBody2D).move_and_collide(motion)
		tentacle_tip = _player.global_position + Vector2(0,-0.35)
	else:
		tentacle_tip = tentacle_target.lerp(origin,clampf((tentacle_time-1.48)/(RELEASE_SECONDS-1.48),0,1))
	if tentacle_time >= RELEASE_SECONDS:
		tentacle_time = -1
		grabbing = false

func _arm_points(from: Vector2, to: Vector2, bend: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 25:
		points.append(from.bezier_interpolate(from+bend,to+bend*0.25,to,i/24.0))
	return points

func _hook_hits(at: Vector2, from: Vector2, to: Vector2) -> bool:
	var points := _arm_points(from,to,Vector2(-1,0.5))
	for i in points.size()-1:
		if Geometry2D.get_closest_point_to_segment(at,points[i],points[i+1]).distance_to(at) <= 0.85: return true
	return false

func _draw_arm(from: Vector2, to: Vector2, bend: Vector2, color: Color) -> void:
	var points := _arm_points(from,to,bend)
	draw_polyline(points,Color("#27253f"),0.68,true)
	draw_polyline(points,color,0.45,true)
	for i in range(2,24,3):
		draw_circle(points[i]+Vector2(0,0.12),0.1,Color("#d2a0b6"))
		draw_circle(points[i]+Vector2(0,0.12),0.04,Color("#7c526c"))

func _draw() -> void:
	if dead: return
	if _state in [State.WINDUP, State.ATTACK] and is_instance_valid(_target):
		var reach := to_local(_target.global_position).limit_length(body_radius + 1.35)
		_draw_arm(Vector2(-1,-0.6),reach,Vector2(-0.6,0.5),Color("#a778a5"))
	if is_instance_valid(prison) and not bool(prison.get("opened")):
		var grip := to_local(prison.global_position+Vector2(0,-3.7))
		_draw_arm(Vector2(1.4,-0.7),grip,Vector2(4,-3.3),Color("#88679d"))
		draw_arc(grip+Vector2(0,0.1),0.33,0,TAU*0.85,24,Color("#b180a7"),0.22,true)
	_draw_powers()
	if tentacle_time < 0: return
	if tentacle_time < WARNING_SECONDS:
		var at := to_local(tentacle_target)
		draw_arc(at,2.1,0,TAU,48,Color("#f3b27b"),0.09)
		var points := _arm_points(Vector2(-1,-0.6),at,Vector2(-1,0.5))
		for i in range(0,points.size(),2): draw_circle(points[i],0.07,Color("#f3b27b"))
	else:
		_draw_arm(Vector2(-1,-0.6),to_local(tentacle_tip),Vector2(-1,0.5),Color("#a778a5"))

func _draw_powers() -> void:
	var gold := Color("#ffe2a0")
	if power == "ink" and power_time >= 0:
		_draw_arm(Vector2(-1,-0.6),to_local(_ink_origin),Vector2(-0.5,-1.6),Color("#a778a5"))
		if power_time < INK_WARNING:
			for end in _ink_lanes:
				draw_line(to_local(_ink_origin),to_local(end),gold,0.09)
				draw_circle(to_local(_ink_origin),0.38,Color("#171423"))
	if power == "spin" and power_time >= 0:
		var active := power_time >= SPIN_WARNING
		draw_circle(Vector2.ZERO,SPIN_RADIUS,Color(0.67,0.43,0.66,0.10 if active else 0.07))
		draw_arc(Vector2.ZERO,SPIN_RADIUS,0,TAU,64,Color("#dca5d3") if active else gold,0.12)
		for tip in _spin_tips:
			if active:
				_draw_arm(Vector2(0,-0.6),to_local(tip),Vector2(0,0.25),Color("#b180a7"))
			else:
				draw_line(Vector2.ZERO,to_local(tip),gold,0.08)
	for shot in ink_shots:
		var at := to_local(shot.at)
		var direction: Vector2 = shot.direction
		for tail in range(3,0,-1): draw_circle(at-direction*tail*0.24,0.34-tail*0.04,Color(0.08,0.06,0.13,0.55))
		draw_circle(at,0.48,Color("#b6a5c7"))
		draw_circle(at,0.40,Color("#12101c"))
		draw_circle(at+Vector2(-0.1,-0.13),0.10,Color("#655374"))

func take_damage(amount: int, _from_dir: Vector2 = Vector2.ZERO, source: Node = null) -> void:
	super.take_damage(amount,Vector2.ZERO,source)

func _boss_name() -> String:
	return "VORATH, THE KRAKEN KING"
