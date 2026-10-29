extends RefCounted
## Actual bodies/effects in an isolated world, with deterministic physics steps.

static func run(game: Game, check: Callable, capture: Callable = Callable()) -> void:
	var snapshot := GameState.data.duplicate(true)
	var autosave := GameState.autosave_enabled
	var ticking := game.is_processing()
	game.hud.hide_modals()
	game.set_process(false)
	GameState.autosave_enabled = false
	GameState.data = GameState._make_default("adam")
	GameState.data.equipped.armor = ""
	GameState._emit_all()
	GameState.start_expedition(RealmDB.PORTAL)
	await game._load_dungeon(RealmDB.PORTAL,false)
	await game.get_tree().physics_frame
	await game.get_tree().process_frame
	var realm := game.world as TwilightRealm
	realm.set_physics_process(false)
	realm.player.set_physics_process(false)
	realm.pet.set_physics_process(false)
	realm.camera.set_physics_process(false)
	var guards: Array[RealmGuard] = []
	var total_hp := 0
	for pack in realm._packs:
		var guard := pack.enemy as RealmGuard
		guard.set_physics_process(false)
		guards.append(guard)
		total_hp += guard.max_hp
	check.call(guards.size() == 6 and total_hp == 282 and guards.filter(func(g: RealmGuard) -> bool: return g.profile == "imp").size() == 4, "combat expansion substitutes profiles within six guards and 282 total HP")
	check.call(guards.filter(func(g: RealmGuard) -> bool: return g.profile == "watcher").size() == 1 and guards.filter(func(g: RealmGuard) -> bool: return g.profile == "keeper").size() == 1, "one lantern Watcher and one stone-mantled Keeper have distinct roles")
	check.call(guards.map(func(g: RealmGuard) -> Vector2: return g.home) == RealmDB.MINIONS, "flat compatibility homes match the authored pair definitions")
	var routes := ResidentRoutes.new(realm,realm.map_rect)
	for guard in guards:
		check.call(routes.point_clear(guard.position) and not RealmCombatDB.protected(guard.position,guard.body_radius), "guard home is collision-clear and outside refuges: " + guard.name_text())
	var target_points := [Vector2(33,37.8),Vector2(33.6,31.3),Vector2(28.1,29.8)]
	for index in 3:
		_reset(realm,guards)
		realm.player.position = target_points[index]
		realm.combat.tick(0.4)
		check.call(realm.combat.active_id == RealmCombatDB.PAIRS[index].id and realm._packs.filter(func(p: Dictionary) -> bool: return bool(p.active)).size() == 2, "entering the local core wakes exactly its pair: " + str(index+1))
		var budgets_hold := true
		for step in 100:
			_step(realm,guards,0.016)
			var actions := realm.combat.effects.filter(func(a: RealmGuardAttack) -> bool: return is_instance_valid(a) and not a.finished)
			budgets_hold = budgets_hold and actions.size() <= 1 and guards.filter(func(g: RealmGuard) -> bool: return g.mode == RealmGuard.Mode.ENGAGED).size() <= 2
		check.call(budgets_hold, "moving pair holds one committed action through windup and active effects: " + str(index+1))
	# Entering each successive core hands off ownership, without a six-actor chase.
	_reset(realm,guards)
	for point in target_points + [target_points[1],target_points[0]]:
		realm.player.position = point
		_step(realm,guards,0.1)
		check.call(guards.filter(func(g: RealmGuard) -> bool: return g.mode == RealmGuard.Mode.ENGAGED).size() <= 2 and realm.combat.effects.size() <= 1, "forward/reverse core handoff never accumulates attacking pairs")
	var imp := guards[0]
	var watcher := guards[3]
	var keeper := guards[5]
	var action := _begin(realm,guards,imp,target_points[0])
	check.call(is_instance_valid(action) and imp._state == Enemy.State.WINDUP, "Imp begins a real stationary warning before charge motion")
	var start := imp.position
	var hp := GameState.health()
	action._physics_process(0.50)
	check.call(imp.position == start and not imp._charging and GameState.health() == hp, "first half-second of Imp warning cannot move or damage")
	if capture.is_valid(): await _shot(game,realm,capture,"11_imp_warning",Vector2(33,37.5))
	action._physics_process(0.16)
	var previous := imp.position
	var continuous := true
	for frame in 4:
		action._physics_process(0.016)
		continuous = continuous and imp.position.distance_to(previous) > 0.001 and imp.position.distance_to(previous) < 0.2
		previous = imp.position
	check.call(continuous and imp._charging, "committed charge moves continuously across consecutive physics samples")
	# Retreat preserves partial HP and returns physically rather than snapping home.
	imp.hp -= 5
	var hurt_hp := imp.hp
	realm.player.position = RealmDB.ARRIVAL
	realm.combat.tick(0.016)
	check.call(action.finished and not imp._charging and imp.mode == RealmGuard.Mode.RETURNING and imp.hp == hurt_hp, "retreat cancels the charge and preserves surviving HP")
	previous = imp.position
	imp._physics_process(0.016)
	check.call(imp.position.distance_to(previous) <= imp.speed*0.016+0.001 and not realm.can_target_actor(imp), "returning guard takes a physical step and is not pursued by companion auto-targeting")
	var distance_home := imp.position.distance_to(imp.home)
	for step in 150: imp._physics_process(0.016)
	check.call(imp.mode == RealmGuard.Mode.RESTING and imp.position.distance_to(imp.home) < 0.12 and distance_home > imp.position.distance_to(imp.home), "leashed guard physically reaches its home and settles without healing or snapping")
	# A large time step still contacts once along the swept dash path.
	action = _begin(realm,guards,imp,Vector2(33,38.2))
	_heal(realm)
	hp = GameState.health()
	action._physics_process(2.0)
	check.call(action.hit_registered and GameState.health() < hp and hp-GameState.health() <= 7, "large-delta dash resolves one swept contact instead of tunnelling")
	hp = GameState.health()
	action._physics_process(2)
	check.call(GameState.health() == hp, "finished charge cannot pay damage again")
	# Watcher: visible locked fan, gap, shared hit and real stone-cover collision.
	action = _begin(realm,guards,watcher,target_points[1])
	var fixed_aim := action.aim
	action._physics_process(0.45)
	var winch: RealmInteractable
	for child in realm.get_children():
		if child is RealmInteractable and child.kind == "shortcut": winch = child
	winch._process(0)
	check.call(not winch.label.visible and winch.interact_radius == 2.5, "watchpost warning takes visual priority while the winch remains usable")
	if capture.is_valid(): await _shot(game,realm,capture,"12_watcher_warning",Vector2(35.5,32.8))
	realm.player.position += Vector2(0,1)
	check.call(action.aim == fixed_aim and action.segments.size() == 3, "Watcher shows three fixed lanes and does not track during its warning")
	var slot_owned := realm.combat.slot == watcher and not guards[2].begin_action()
	check.call(slot_owned, "Watcher windup reserves the pair's shared attack slot")
	action = _begin(realm,guards,watcher,Vector2(36.8,34.5))
	_heal(realm)
	hp = GameState.health()
	action._physics_process(0.91)
	check.call(realm.combat.slot == watcher and not guards[2].begin_action(), "fan keeps its attack slot while its shots are travelling")
	realm.player.position = Vector2(39.1,35.9)
	for step in 13: action._physics_process(0.1)
	check.call(GameState.health() == hp and action.shots.any(func(shot: Dictionary) -> bool: return not bool(shot.alive)), "real watchpost cover stops the outer fan lane before it reaches Adam")
	action = _begin(realm,guards,watcher,target_points[1])
	_heal(realm)
	hp = GameState.health()
	action._physics_process(2.2)
	check.call(action.hit_registered and GameState.health() < hp, "Watcher projectile can actually hit along its swept path")
	var damage_once := GameState.health()
	realm.player.invulnerable = 0
	action._physics_process(0.1)
	check.call(GameState.health() == damage_once and hp-damage_once <= 7, "whole fan has one damage claim, independent of blink immunity")
	# Keeper uses one clipped cross resolver; the intersection is not two hits.
	action = _begin(realm,guards,keeper,target_points[2])
	_heal(realm)
	hp = GameState.health()
	action._physics_process(0.70)
	if capture.is_valid(): await _shot(game,realm,capture,"13_keeper_warning",Vector2(27.5,28.5))
	check.call(GameState.health() == hp and action.segments.size() == 4 and not action._released, "Keeper previews four clipped arms before any damage")
	action._physics_process(0.36)
	var after_cross := GameState.health()
	realm.player.invulnerable = 0
	action._physics_process(0.10)
	check.call(after_cross < hp and GameState.health() == after_cross and hp-after_cross <= 7, "cross intersection resolves exactly one hit even when blink is cleared")
	action = _begin(realm,guards,keeper,target_points[2])
	_heal(realm)
	hp = GameState.health()
	# Ordinary walking speed comfortably reaches a diagonal clear quadrant.
	var walking := realm.player.position
	var touch_mode := GameSettings.touch_controls()
	GameSettings.set_touch_controls("always",false)
	await game.get_tree().process_frame
	var joystick := game.hud._joystick as Control
	var press := InputEventScreenTouch.new()
	press.index = 23
	press.pressed = true
	press.position = game.get_viewport().get_final_transform()*(joystick.get_global_rect().get_center()+Vector2(50,50)*joystick.get_global_transform().get_scale())
	Input.parse_input_event(press)
	await game.get_tree().process_frame
	for step in 30:
		await game.get_tree().physics_frame
		realm.player._physics_process(0.016)
		action._physics_process(0.016)
	var release := InputEventScreenTouch.new()
	release.pressed = false
	release.index = press.index
	release.position = press.position
	Input.parse_input_event(release)
	await game.get_tree().process_frame
	await game.get_tree().process_frame
	action._physics_process(0.90)
	check.call(realm.player.position.distance_to(walking) > 1 and GameState.health() == hp and Input.get_vector("move_left","move_right","move_up","move_down").is_zero_approx(), "actual touch joystick drives continuous diagonal movement out of the cross and releases cleanly without Sprint")
	GameSettings.set_touch_controls(touch_mode,false)
	# Interruptions consume pending actions and never resurrect them on re-entry.
	for guard in [imp,watcher,keeper]:
		var target: Vector2 = target_points[0 if guard == imp else (1 if guard == watcher else 2)]
		action = _begin(realm,guards,guard,target)
		action._physics_process(0.2)
		guard.take_damage(1,Vector2.ZERO,realm.player)
		check.call(action.finished and not is_instance_valid(guard.action) and realm.combat.slot == null, "weapon interrupt cancels pending power and its attack slot: " + guard.profile)
		var serial: int = guard.cast_serial
		action._physics_process(10)
		check.call(guard.cast_serial == serial and not guard._charging, "old interrupted callback cannot resume a cast: " + guard.profile)
	# Every entire stage/refuge, not merely its centre, rejects incoming attacks.
	for refuge in [Vector2(8.1,38.9),Vector2(47.9,30.9),RealmDB.CAMP,RealmDB.ARRIVAL]:
		action = _begin(realm,guards,watcher,target_points[1])
		action._physics_process(0.95)
		realm.player.position = refuge
		_heal(realm)
		hp = GameState.health()
		action._physics_process(0.5)
		check.call(action.finished and GameState.health() == hp, "in-flight fan cannot hit protected stage/refuge point " + str(refuge))
	check.call(RealmCombatDB.allowed_fraction(Vector2(35,27),Vector2(52,27),RealmCombatDB.pair("watchpost_guard").pursuit,0.18) < 0.3, "swept allowed segment stops at moth refuge before a shot can skip across it")
	# Normal menus keep combat running; the special habitat duel ends pursuit first.
	action = _begin(realm,guards,watcher,target_points[1])
	game.open_settings()
	await game.get_tree().process_frame
	action._physics_process(0.2)
	check.call(is_equal_approx(action.clock,0.2) and not action.finished, "ordinary Settings does not invent a world-combat pause")
	game.hud.settings_panel.close_panel()
	realm.player.position = realm.wildlife.bramble_cat.position+Vector2(0,2)
	realm.wildlife.bramble_cat.interact(realm.player)
	check.call(game.hud.wild_challenge.visible and action.finished and realm.process_mode == Node.PROCESS_MODE_DISABLED, "habitat challenge clears pursuing regular casts before protected staging")
	game.hud.wild_challenge.close_panel()
	# Pause-safe quality fallbacks retain the actual warning geometry.
	var quality := GameSettings.effects_quality()
	var reduce := GameSettings.reduce_motion()
	GameSettings.set_effects_quality("low",false)
	GameSettings.set_reduce_motion(true,false)
	action = _begin(realm,guards,keeper,target_points[2])
	action._physics_process(0.5)
	check.call(action.visible and action.segments.size() == 4 and not action._released, "low effects and Reduce Motion retain essential cross geometry and timing")
	if capture.is_valid(): await _shot(game,realm,capture,"14_keeper_low_effects",Vector2(27.5,28.5))
	GameSettings.set_effects_quality(quality,false)
	GameSettings.set_reduce_motion(reduce,false)
	if capture.is_valid():
		game.hud.field_guide_panel._category = 1
		game.hud.field_guide_panel._page = 6
		game.open_field_guide()
		await game.get_tree().process_frame
		await capture.call("15_guard_guide")
		game.hud.field_guide_panel.close_panel()
	# The boss receives ownership alone, and victory/retreat paths remain separate.
	action = _begin(realm,guards,watcher,target_points[1])
	realm.player.position = RealmDB.BOSS_THRESHOLD
	realm._physics_process(0.016)
	check.call(action.finished and realm._boss_arrived and realm.combat.active_id.is_empty() and realm.combat.slot == null, "citadel threshold cancels all regular attacks before enabling the boss")
	realm.player.position = RealmDB.CAMP
	realm._physics_process(0.016)
	check.call(not realm._boss_arrived and not realm.camera.framing_bounds.has_area(), "boss retreat still releases its arena framing")
	# Kill during windup: ordinary Enemy death/reward accounting remains one-shot.
	action = _begin(realm,guards,watcher,target_points[1])
	var kills := int(GameState.data.kills)
	watcher.take_damage(99999,Vector2.ZERO,realm.player)
	watcher._die()
	check.call(action.finished and watcher.dead and int(GameState.data.kills) == kills+1 and realm.combat.slot == null, "caster death cancels its action and records one ordinary kill/reward")
	action = _begin(realm,guards,imp,target_points[0])
	imp.queue_free()
	hp = GameState.health()
	action._physics_process(2)
	check.call(action.finished and not realm.can_damage_actor(imp) and GameState.health() == hp, "queued guard removal immediately invalidates attack and reward eligibility before deletion")
	await game.get_tree().process_frame
	await game.get_tree().process_frame
	realm.combat.tick(0.4)
	realm._physics_process(0.016)
	check.call(not is_instance_valid(imp) and realm.combat._living(str(RealmCombatDB.PAIRS[0].id)).all(func(guard) -> bool: return is_instance_valid(guard)), "realm physics and encounter scans survive a fully freed guard handle")
	# A retiring world's token cannot damage its replacement.
	action = _begin(realm,guards,keeper,target_points[2])
	await game._load_lobby(false)
	hp = GameState.health()
	action._physics_process(2)
	check.call(action.finished and GameState.health() == hp and game.world is Lobby, "world replacement rejects the old cast before a delayed hit can land")
	await game.get_tree().process_frame
	GameState.data = snapshot
	GameState._emit_all()
	await game._load_lobby(false)
	await game.get_tree().process_frame
	GameState.autosave_enabled = autosave
	game.set_process(ticking)

static func _heal(realm: TwilightRealm) -> void:
	GameState.set_health(GameState.health_max())
	GameState.data.shield = 0
	realm.player.invulnerable = 0

static func _reset(realm: TwilightRealm, guards: Array[RealmGuard]) -> void:
	realm.combat.cancel_all()
	for guard in guards:
		if not is_instance_valid(guard) or guard.is_queued_for_deletion() or guard.dead: continue
		guard.cancel_action()
		guard.position = guard.home
		guard.mode = RealmGuard.Mode.RESTING
		guard._cooldown = 0
		guard._state = Enemy.State.WANDER
		guard._knockback = Vector2.ZERO
		guard._alert_time = 0
		if is_instance_valid(guard._alert_icon): guard._alert_icon.queue_free()
		guard._alert_icon = null
	_heal(realm)

static func _begin(realm: TwilightRealm, guards: Array[RealmGuard], guard: RealmGuard, target: Vector2) -> RealmGuardAttack:
	_reset(realm,guards)
	realm.player.position = target
	realm.combat.tick(0.4)
	realm.combat.tick(0.4)
	guard._cooldown = 0
	guard.begin_action()
	var action := guard.action
	if is_instance_valid(action): action.set_physics_process(false)
	return action

static func _step(realm: TwilightRealm, guards: Array[RealmGuard], delta: float) -> void:
	realm.combat.tick(delta)
	for guard in guards:
		if not is_instance_valid(guard) or guard.dead: continue
		guard._physics_process(delta)
		if is_instance_valid(guard.action): guard.action.set_physics_process(false)
	for action in realm.combat.effects.duplicate():
		if is_instance_valid(action): action._physics_process(delta)

static func _shot(game: Game, realm: TwilightRealm, capture: Callable, id: String, at: Vector2) -> void:
	realm.survey()
	realm.player._update_nearby()
	game.hud._update_prompt()
	for pack in realm._packs:
		if not is_instance_valid(pack.enemy): continue
		var guard := pack.enemy as RealmGuard
		guard._update_guard_art()
		guard._name_label.visible = guard.mode == RealmGuard.Mode.ENGAGED
	realm.camera.position = at
	realm.camera.reset_physics_interpolation()
	realm.camera.force_update_scroll()
	await game.get_tree().physics_frame
	await game.get_tree().process_frame
	await capture.call(id)
