class_name KrakenKing
extends Enemy
## A telegraphed fighting arm alternates slam/hook while a second guards Arjun.
const WARNING_SECONDS := 0.9
const EXTEND_SECONDS := 0.4
const IMPACT_SECONDS := WARNING_SECONDS + EXTEND_SECONDS
const RELEASE_SECONDS := 3.1
const MAX_TENTACLE_REACH := 18.0
const WALK_SPEED := 1.8
const ARENA_AGGRO_RANGE := 32.0
var prison: Node2D
var tentacle_time := -1.0
var tentacle_target := Vector2.ZERO
var tentacle_tip := Vector2.ZERO
var hook_attack := false
var grabbing := false
var _impact_done := false

func _ready() -> void:
	kind = "kraken_king"
	is_boss = true
	max_hp = 720
	damage = 16
	special_damage = 22
	speed = WALK_SPEED
	body_radius = 2.1
	boss_ability = "tentacle"
	boss_ability_name = "Royal Tentacle: Slam / Drag"
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
	super._physics_process(delta)
	_update_body()
	_update_tentacle(delta)
	queue_redraw()

func _aggro_range() -> float:
	return ARENA_AGGRO_RANGE

func _chase(delta: float) -> void:
	if tentacle_time >= 0:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	super._chase(delta)

func _cast_special() -> void:
	if dead or tentacle_time >= 0 or not is_instance_valid(_player) or bool(_player.get("dead")): return
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
	if tentacle_time < 0: return
	if tentacle_time < WARNING_SECONDS:
		var at := to_local(tentacle_target)
		draw_arc(at,2.1,0,TAU,48,Color("#f3b27b"),0.09)
		var points := _arm_points(Vector2(-1,-0.6),at,Vector2(-1,0.5))
		for i in range(0,points.size(),2): draw_circle(points[i],0.07,Color("#f3b27b"))
	else:
		_draw_arm(Vector2(-1,-0.6),to_local(tentacle_tip),Vector2(-1,0.5),Color("#a778a5"))

func take_damage(amount: int, _from_dir: Vector2 = Vector2.ZERO, source: Node = null) -> void:
	super.take_damage(amount,Vector2.ZERO,source)

func _boss_name() -> String:
	return "VORATH, THE KRAKEN KING"
