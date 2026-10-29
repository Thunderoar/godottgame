class_name RealmGuardAttack
extends Node2D
## One ownership token and one hit for an entire dash, fan, cross or close swipe.

var caster: RealmGuard
var director: RealmEncounterDirector
var attack_type := "imp"
var serial := 0
var epoch := 0
var origin := Vector2.ZERO
var aim := Vector2.ZERO
var clock := 0.0
var windup := 0.65
var duration := 0.38
var finished := false
var hit_registered := false
var segments: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var _released := false
var _direction := Vector2.RIGHT

func _ready() -> void:
	director = caster.director
	z_index = 2
	windup = 0.50 if attack_type == "melee" else float(RealmCombatDB.PROFILES[attack_type].windup)
	duration = 0.12 if attack_type == "melee" else float(RealmCombatDB.PROFILES[attack_type].active)
	_direction = origin.direction_to(aim)
	Sfx.play("charge",-18)
	if _direction == Vector2.ZERO: _direction = Vector2.DOWN
	if attack_type == "keeper":
		for axis in [Vector2.RIGHT,Vector2.DOWN]:
			for sign_value in [-1.0,1.0]:
				var tip: Vector2 = aim+axis*sign_value*RealmCombatDB.CROSS_HALF
				var part := caster.director.fraction(aim,tip,RealmCombatDB.CROSS_RADIUS,caster.encounter_id)
				segments.append({"from":aim,"to":aim.lerp(tip,maxf(0,part-0.001))})
	elif attack_type == "watcher":
		for angle in [-25.0,0.0,25.0]:
			var direction := _direction.rotated(deg_to_rad(angle))
			var end := origin+direction*6.0
			var part := caster.director.fraction(origin,end,RealmCombatDB.SHOT_RADIUS,caster.encounter_id)
			segments.append({"from":origin,"to":origin.lerp(end,maxf(0,part-0.001))})
	else:
		var end := origin+_direction*(1.6 if attack_type == "melee" else caster.speed*4.8*duration)
		var part := caster.director.fraction(origin,end,0.45,caster.encounter_id)
		segments.append({"from":origin,"to":origin.lerp(end,maxf(0,part-0.001))})
	queue_redraw()

static func cross_has_escape(owner: RealmEncounterDirector, at: Vector2) -> bool:
	var clear := 0
	var planner := ResidentRoutes.new(owner.world,owner.world.map_rect)
	for direction in [Vector2(-1,-1),Vector2(1,-1),Vector2(-1,1),Vector2(1,1)]:
		if planner.segment_clear(at,at+direction*1.2): clear += 1
	return clear >= 2

func owns_cast() -> bool:
	return not finished and is_instance_valid(caster) and caster.director.valid_cast(caster,serial,epoch)

func _physics_process(delta: float) -> void:
	if not owns_cast():
		cancel()
		return
	var previous := clock
	clock += delta
	if clock >= windup:
		caster._state = Enemy.State.ATTACK
		var active_delta := maxf(0,minf(clock-windup,duration)-maxf(0,previous-windup))
		if not _released:
			_released = true
			Sfx.play("skill_attack",-20)
			if attack_type == "watcher":
				for angle in [-25.0,0.0,25.0]: shots.append({"at":origin,"direction":_direction.rotated(deg_to_rad(angle)),"alive":true})
		match attack_type:
			"imp":
				caster._charging = true
				caster.velocity = _direction*caster.speed*4.8
				var from := caster.position
				caster._move_motion(_direction*caster.speed*4.8*active_delta)
				_hit_segment(from,caster.position,0.45)
			"watcher":
				for shot in shots:
					if not bool(shot.alive): continue
					var from: Vector2 = shot.at
					var to: Vector2 = from+shot.direction*RealmCombatDB.SHOT_SPEED*active_delta
					var part := caster.director.fraction(from,to,RealmCombatDB.SHOT_RADIUS,caster.encounter_id)
					shot.at = from.lerp(to,maxf(0,part-0.001))
					_hit_segment(from,shot.at,RealmCombatDB.SHOT_RADIUS)
					if part < 0.999: shot.alive = false
			"keeper","melee":
				for segment in segments: _hit_segment(segment.from,segment.to,RealmCombatDB.CROSS_RADIUS if attack_type == "keeper" else 0.45)
	queue_redraw()
	if clock >= windup+duration or (attack_type == "watcher" and _released and shots.all(func(shot: Dictionary) -> bool: return not bool(shot.alive))): _finish(false)

func _hit_segment(from: Vector2, to: Vector2, radius: float) -> void:
	if hit_registered or not owns_cast(): return
	var player := caster.director.world.player
	if Geometry2D.get_closest_point_to_segment(player.position,from,to).distance_to(player.position) <= radius+0.25:
		hit_registered = true # Consume contact even if existing blink/shield absorbs it.
		player.take_damage(caster.damage,origin)

func cancel() -> void:
	_finish(true)

func _finish(interrupted: bool) -> void:
	if finished: return
	finished = true
	visible = false
	if director != null: director.effects.erase(self)
	if is_instance_valid(caster):
		caster.finish_action(self,interrupted)
	queue_free()

func _draw() -> void:
	if finished: return
	var active_phase := clock >= windup
	var warm := Color("#ffe1a1")
	var colour := Color("#e8aeed") if attack_type == "keeper" else warm
	if attack_type == "watcher" and active_phase:
		for shot in shots:
			if not bool(shot.alive): continue
			draw_circle(shot.at,RealmCombatDB.SHOT_RADIUS+0.09,Color("#563948"))
			draw_circle(shot.at,RealmCombatDB.SHOT_RADIUS,colour)
			draw_circle(shot.at,0.065,Color("#fff5d4"))
		return
	for segment in segments:
		var from: Vector2 = segment.from
		var to: Vector2 = segment.to
		if from.distance_to(to) < 0.02: continue
		var width := (RealmCombatDB.CROSS_RADIUS*2 if attack_type == "keeper" else 0.9)
		if attack_type == "watcher": width = 0.10
		draw_line(from,to,Color("#292136"),width+0.10,false)
		draw_line(from,to,Color(colour,0.85 if active_phase else 0.35),width,false)
		draw_line(from,to,colour,0.055,false)
		if not active_phase:
			var mark := from if GameSettings.reduce_motion() else from.lerp(to,clampf(clock/windup,0,1))
			draw_circle(mark,0.10,colour)
