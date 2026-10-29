class_name RealmEncounterDirector
extends RefCounted
## One attacking pair and one owned action; dormant/returning bodies stay visible.

var world: TwilightRealm
var active_id := ""
var generation := 0
var slot: RealmGuard
var gap := 0.0
var effects: Array[RealmGuardAttack] = []
var routes: Dictionary = {}

func _init(owner_world: TwilightRealm) -> void:
	world = owner_world
	for def in RealmCombatDB.PAIRS: routes[def.id] = RealmGuardRoutes.new(world,def.pursuit)

func current_world() -> bool:
	if not is_instance_valid(world) or not world.is_inside_tree() or world.is_queued_for_deletion(): return false
	var game := world.get_tree().get_first_node_in_group("game") as Game
	return is_instance_valid(game) and game.world == world and not game._transitioning and not game._defeat_pending and not world._leaving and is_instance_valid(world.player) and not world.player.dead

func combat_allowed() -> bool:
	return current_world() and not world._boss_defeated and not world._boss_arrived and not world._camp_resting and not RealmCombatDB.protected(world.player.position)

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

func tick(delta: float) -> void:
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
				for guard in _living(str(def.id)):
					var distance := at.distance_to(guard.position)
					if distance < nearest and line_clear(guard.position,at):
						nearest = distance
						wanted = str(def.id)
			if wanted.is_empty() and not active_id.is_empty() and not _living(active_id).is_empty() and (RealmCombatDB.pair(active_id).pursuit as Rect2).has_point(at): wanted = active_id
	if wanted != active_id: _handoff(wanted)
	for pack in world._packs:
		if not is_instance_valid(pack.enemy):
			pack.active = false
			continue
		var guard := pack.enemy as RealmGuard
		pack.active = is_instance_valid(guard) and not guard.is_queued_for_deletion() and not guard.dead and guard.mode == RealmGuard.Mode.ENGAGED

func _handoff(id: String) -> void:
	generation += 1
	for effect in effects.duplicate():
		if is_instance_valid(effect): effect.cancel()
	effects.clear()
	slot = null
	gap = RealmCombatDB.ATTACK_GAP
	active_id = id
	if not id.is_empty(): world.set_message(str(RealmCombatDB.pair(id).hint))
	for pack in world._packs:
		if not is_instance_valid(pack.enemy): continue
		var guard := pack.enemy as RealmGuard
		if not is_instance_valid(guard) or guard.is_queued_for_deletion() or guard.dead: continue
		if guard.encounter_id == id: guard.engage()
		elif guard.mode == RealmGuard.Mode.ENGAGED: guard.return_home()

func cancel_all() -> void:
	if not active_id.is_empty() or is_instance_valid(slot) or not effects.is_empty(): _handoff("")
	for pack in world._packs: pack.active = false

func can_attack(guard: RealmGuard) -> bool:
	return combat_allowed() and guard.mode == RealmGuard.Mode.ENGAGED and guard.encounter_id == active_id and not guard.is_queued_for_deletion() and not guard.dead and world.process_mode != Node.PROCESS_MODE_DISABLED

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
	return current_world() and not world._boss_defeated and world.process_mode != Node.PROCESS_MODE_DISABLED and not RealmCombatDB.protected(world.player.position) and not guard.is_queued_for_deletion() and not guard.dead and guard.mode != RealmGuard.Mode.RESTING

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
