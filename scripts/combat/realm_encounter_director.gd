class_name RealmEncounterDirector
extends RefCounted
## One active sector/wave and one owned action; reinforcements are warned and bounded.

var world: TwilightRealm
var defeated_members: Dictionary = {}
var active_id := ""
var generation := 0
var slot: RealmGuard
var gap := 0.0
var effects: Array[RealmGuardAttack] = []
var routes: Dictionary = {}
var warning: WaveWarning
var pending_id := ""
var warning_left := 0.0

func _init(owner_world: TwilightRealm) -> void:
	world = owner_world
	for def in RealmCombatDB.PAIRS: routes[def.id] = RealmGuardRoutes.new(world,def.pursuit)

func current_world() -> bool:
	if not is_instance_valid(world) or not world.is_inside_tree() or world.is_queued_for_deletion(): return false
	var game := world.get_tree().get_first_node_in_group("game") as Game
	return is_instance_valid(game) and game.world == world and world._journey == GameState.journey_serial and not game._transitioning and not game._defeat_pending and not world._leaving and is_instance_valid(world.player) and not world.player.dead

func combat_allowed() -> bool:
	return current_world() and not DialogueWorldHold.protects(world) and world.process_mode != Node.PROCESS_MODE_DISABLED and not world._boss_defeated and not world._boss_arrived and not world._camp_resting and not RealmCombatDB.protected(world.player.position)

func line_clear(from: Vector2, to: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(world.to_global(from),world.to_global(to),1)
	return world.get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func _living(id: String) -> Array[RealmGuard]:
	var result: Array[RealmGuard] = []
	for pack in world._packs:
		if not is_instance_valid(pack.enemy): continue
		var guard := pack.enemy as RealmGuard
		if is_instance_valid(guard) and not guard.is_queued_for_deletion() and not guard.dead and guard.encounter_id == id: result.append(guard)
	return result

func wave_hint(id: String) -> String:
	var index := GameState.citadel_waves_cleared(id)
	if index >= RealmCombatDB.WAVE_SIZES.size(): return "Sector cleared. Restore its road light."
	return "WAVE %d/%d · %d guards · %s" % [index+1,RealmCombatDB.WAVE_SIZES.size(),RealmCombatDB.wave_size(index),str(RealmCombatDB.pair(id).hint)]

func _cancel_warning() -> void:
	if is_instance_valid(warning): warning.queue_free()
	warning = null
	pending_id = ""
	warning_left = 0

func _update_reinforcements(delta: float) -> void:
	if active_id.is_empty() or not combat_allowed() or not _living(active_id).is_empty() or GameState.citadel_waves_cleared(active_id)>=RealmCombatDB.WAVE_SIZES.size():
		_cancel_warning()
		return
	if pending_id != active_id or not is_instance_valid(warning) or warning.is_queued_for_deletion():
		_cancel_warning()
		pending_id = active_id
		warning_left = RealmCombatDB.REINFORCEMENT_WARNING
		warning = WaveWarning.new()
		var count := RealmCombatDB.wave_size(GameState.citadel_waves_cleared(active_id))
		for index in count: warning.posts.append(RealmCombatDB.WAVE_POSTS[active_id][index])
		world.add_child(warning)
		world.set_message("WAVE %d/%d · %d guards arriving · Step clear of the gold marks." % [GameState.citadel_waves_cleared(active_id)+1,RealmCombatDB.WAVE_SIZES.size(),count])
		return # Always present a real warning before accepting elapsed time.
	warning_left -= delta
	if warning_left > 0: return
	for at in warning.posts:
		if at.distance_to(world.player.position) < 1.0:
			warning_left = 0.2
			world.set_message("Step clear of the arrival marks before the next wave arrives.")
			return
	var id := active_id
	var wave := GameState.citadel_waves_cleared(id)
	_cancel_warning()
	world.spawn_guard_wave(id,wave)
	world.set_message(wave_hint(id))

func tick(delta: float) -> void:
	if not current_world():
		if is_instance_valid(world): cancel_all()
		else: _cancel_warning()
		return
	gap = maxf(0,gap-delta)
	var wanted := ""
	if combat_allowed():
		var at := world.player.position
		if not active_id.is_empty() and not _living(active_id).is_empty() and (RealmCombatDB.pair(active_id).core as Rect2).grow(0.25).has_point(at):
			wanted = active_id
		else:
			var nearest := INF
			for def in RealmCombatDB.PAIRS:
				if not (def.core as Rect2).has_point(at): continue
				if _living(str(def.id)).is_empty() and GameState.citadel_waves_cleared(str(def.id))<RealmCombatDB.WAVE_SIZES.size():
					wanted = str(def.id)
				for guard in _living(str(def.id)):
					var distance := at.distance_to(guard.position)
					if distance < nearest and line_clear(guard.position,at):
						nearest = distance
						wanted = str(def.id)
			if wanted.is_empty() and not active_id.is_empty() and not _living(active_id).is_empty() and (RealmCombatDB.pair(active_id).pursuit as Rect2).has_point(at): wanted = active_id
	if wanted != active_id: _handoff(wanted)
	_update_reinforcements(delta)
	for pack in world._packs:
		if not is_instance_valid(pack.enemy):
			pack.active = false
			continue
		var guard := pack.enemy as RealmGuard
		pack.active = is_instance_valid(guard) and not guard.is_queued_for_deletion() and not guard.dead and guard.mode == RealmGuard.Mode.ENGAGED

func _handoff(id: String) -> void:
	generation += 1
	_cancel_warning()
	for effect in effects.duplicate():
		if is_instance_valid(effect): effect.cancel()
	effects.clear()
	slot = null
	gap = RealmCombatDB.ATTACK_GAP
	active_id = id
	if not id.is_empty(): world.set_message(wave_hint(id))
	for pack in world._packs:
		if not is_instance_valid(pack.enemy): continue
		var guard := pack.enemy as RealmGuard
		if not is_instance_valid(guard) or guard.is_queued_for_deletion() or guard.dead: continue
		if guard.encounter_id == id: guard.engage()
		elif guard.mode == RealmGuard.Mode.ENGAGED: guard.return_home()

func cancel_all() -> void:
	_cancel_warning()
	if not active_id.is_empty() or is_instance_valid(slot) or not effects.is_empty(): _handoff("")
	for pack in world._packs: pack.active = false

func can_attack(guard: RealmGuard) -> bool:
	return combat_allowed() and guard.mode == RealmGuard.Mode.ENGAGED and guard.encounter_id == active_id and guard.wave_index == GameState.citadel_waves_cleared(guard.encounter_id) and not guard.is_queued_for_deletion() and not guard.dead and world.process_mode != Node.PROCESS_MODE_DISABLED

func claim(guard: RealmGuard) -> bool:
	if not can_attack(guard) or is_instance_valid(slot) or gap > 0: return false
	slot = guard
	return true

func release(guard: RealmGuard) -> void:
	if slot == guard:
		slot = null
		gap = RealmCombatDB.ATTACK_GAP

func valid_cast(guard: RealmGuard, serial: int, epoch: int) -> bool:
	return is_instance_valid(guard) and slot == guard and generation == epoch and guard.cast_serial == serial and can_attack(guard)

func can_damage(guard: RealmGuard) -> bool:
	return current_world() and guard.wave_index == GameState.citadel_waves_cleared(guard.encounter_id) and not world._boss_defeated and world.process_mode != Node.PROCESS_MODE_DISABLED and not RealmCombatDB.protected(world.player.position) and not guard.is_queued_for_deletion() and not guard.dead and guard.mode != RealmGuard.Mode.RESTING

func fraction(from: Vector2, to: Vector2, radius: float, id: String) -> float:
	var def := RealmCombatDB.pair(id)
	if def.is_empty(): return 0.0
	var permitted := RealmCombatDB.allowed_fraction(from,to,def.pursuit,radius)
	var circle := CircleShape2D.new()
	circle.radius = radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0,world.to_global(from))
	query.motion = to-from
	query.collision_mask = 1
	var space := world.get_world_2d().direct_space_state
	if not space.intersect_shape(query,1).is_empty(): return 0.0
	var collision := space.cast_motion(query)
	return minf(permitted,collision[0])

func travel(guard: RealmGuard, motion: Vector2) -> Vector2:
	var fraction_allowed := fraction(guard.position,guard.position+motion,guard.body_radius+0.1,guard.encounter_id)
	return motion*maxf(0,fraction_allowed-0.001)

func return_direction(guard: RealmGuard) -> Vector2:
	if guard._route_clock <= 0 or guard._route.is_empty():
		guard._route_clock = 0.7
		guard._route = (routes[guard.encounter_id] as RealmGuardRoutes).path(guard.position,guard.home,false)
		guard._route_index = 0
	if guard._route.is_empty(): return Vector2.ZERO
	while guard._route_index < guard._route.size()-1 and guard.position.distance_to(guard._route[guard._route_index]) < 0.25: guard._route_index += 1
	return guard.position.direction_to(guard._route[guard._route_index])

func invalidate_routes() -> void:
	for planner in routes.values(): planner.invalidate()

class WaveWarning extends Node2D:
	var posts: Array[Vector2] = []
	func _ready() -> void:
		z_index = 4
		queue_redraw()
	func _draw() -> void:
		for at in posts:
			draw_circle(at,0.65,Color("#f0b07733"))
			draw_arc(at,0.65,0,TAU,24,Color("#f5ce88"),0.07)
			draw_line(at+Vector2(-0.22,0),at+Vector2(0.22,0),Color("#fff1cc"),0.07)
			draw_line(at+Vector2(0,-0.22),at+Vector2(0,0.22),Color("#fff1cc"),0.07)
