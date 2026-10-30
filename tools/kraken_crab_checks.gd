extends RefCounted

static func run(game: Game, check: Callable, capture: Callable = Callable()) -> void:
	var island := game.world as KrakenIsland
	var crabs := island.crabs.duplicate()
	var health := GameState.health()
	island.boss.set_physics_process(false)
	island.player.set_physics_process(false)
	for crab in crabs: crab.set_physics_process(false)
	check.call(crabs.size() == 10 and crabs.all(func(crab: KrakenCrab) -> bool: return crab.kind == "crab" and not crab.is_boss and crab.collision_layer == 4 and crab.collision_mask == 1), "ten real crab monsters guard Kraken Island with the regular enemy collision contract")
	check.call(crabs.all(func(crab: KrakenCrab) -> bool: return crab.active and crab.dungeon_alerted and crab._target == island.player and crab._state == Enemy.State.CHASE) and island.boss.active and island.boss._boss_notified and island.boss._target == island.player and island.boss._state == Enemy.State.CHASE, "entering the arena immediately engages all ten crabs and the Kraken without proximity triggers")
	await game.get_tree().physics_frame
	var clear_posts := true
	for crab in crabs:
		var shape := CircleShape2D.new()
		shape.radius = crab.body_radius
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = shape
		query.collision_mask = 1
		query.transform = Transform2D(0,crab.global_position + Vector2(0,-crab.body_radius * 0.5))
		clear_posts = clear_posts and island.get_world_2d().direct_space_state.intersect_shape(query).is_empty()
	check.call(clear_posts and crabs.all(func(crab: KrakenCrab) -> bool: return crab.position.distance_to(island.player.position) > 2.5), "ten crab posts clear fortress obstacles without overlapping Adam's arrival")
	check.call(RealisticArt._record("enemy_crab_false_0")[0] == "ocean" and PixelArt.enemy_texture("crab") != PixelArt.enemy_texture("bogling"), "crabs have their own art in both supported visual styles")
	var crab: KrakenCrab = crabs[0]
	var far_guard: KrakenCrab = crabs[2]
	var far_distance := far_guard.position.distance_to(island.player.position)
	far_guard._physics_process(0.1)
	check.call(far_distance > far_guard._aggro_range() and far_guard._state == Enemy.State.CHASE and far_guard.position.distance_to(island.player.position) < far_distance, "even a distant crab immediately pursues Adam from beyond its normal alert radius")
	island.boss._special_timer = KrakenIsland.OPENING_SPECIAL_DELAY
	island.boss.tentacle_time = -1
	island.boss._physics_process(KrakenIsland.OPENING_SPECIAL_DELAY + 0.01)
	check.call(island.boss.tentacle_time >= 0 and GameState.health() == health, "the Kraken opens with an automatic tentacle warning before Adam approaches, preserving time to dodge")
	island.player.position = crab.position + Vector2(2,0)
	var distance := crab.position.distance_to(island.player.position)
	crab._physics_process(0.1)
	check.call(crab._state == Enemy.State.CHASE and crab.position.distance_to(island.player.position) < distance, "alerted crabs skitter toward Adam through the existing movement engine")
	island.player.position = crab.position + Vector2(0.8,0)
	island.player.invulnerable = 0
	crab._attack_timer = 0
	crab._physics_process(0.01)
	check.call(crab._state == Enemy.State.WINDUP and GameState.health() == health, "crab pincers warn before dealing contact damage")
	crab._physics_process(0.43)
	crab._physics_process(0.01)
	var hit_health := GameState.health()
	check.call(hit_health < health, "the crab's active pincer strike deals real player damage")
	island.player.invulnerable = 0
	crab._physics_process(0.01)
	check.call(GameState.health() == hit_health, "one pincer strike cannot damage Adam twice")
	crab._enter(Enemy.State.WINDUP)
	crab.take_damage(1,Vector2.ZERO,island.player)
	check.call(crab._state == Enemy.State.STAGGER, "hitting a crab interrupts its telegraphed pincer attack")
	crab._state = Enemy.State.ATTACK
	crab._hit_dealt = false
	game.world = null
	crab._physics_process(0.1)
	island.boss.tentacle_time = KrakenKing.IMPACT_SECONDS - 0.01
	island.boss.tentacle_target = island.player.position
	island.boss._impact_done = false
	island.boss.hook_attack = false
	island.boss._physics_process(0.1)
	game.world = island
	check.call(GameState.health() == hit_health and not island.boss._impact_done, "retiring crabs and Kraken attacks cannot damage the player after world ownership changes")
	var kills := int(GameState.data.kills)
	var gold_drops := [0]
	var count_gold := func(node: Node) -> void:
		if node is LootDrop and node.kind == "gold": gold_drops[0] += 1
	island.child_entered_tree.connect(count_gold)
	crab.take_damage(crab.max_hp,Vector2.ZERO,island.player)
	crab.take_damage(crab.max_hp,Vector2.ZERO,island.player)
	await game.get_tree().process_frame
	island.child_entered_tree.disconnect(count_gold)
	check.call(crab.dead and not crab.is_in_group("enemies") and int(GameState.data.kills) == kills + 1 and gold_drops[0] == 1, "a defeated crab awards one kill and standard collectible Gold without duplicate rewards")
	var before_boss := int(GameState.data.kills)
	island.boss.take_damage(island.boss.max_hp,Vector2.ZERO,island.player)
	check.call(island.defeated and crabs.all(func(guard: KrakenCrab) -> bool: return guard.dead or (guard.retreating and not guard.is_in_group("enemies") and guard.collision_layer == 0 and not guard.is_physics_processing())), "the Kraken's defeat makes every surviving crab withdraw without further attacks")
	check.call(island.cage.available and not island.cage.opened and not bool(GameState.campaign().arjun_rescued) and int(GameState.data.kills) == before_boss + 1, "withdrawing guards give no kill rewards and preserve the separate prison rescue")
	await game.get_tree().create_timer(0.55).timeout
	check.call(crabs.slice(1).all(func(guard: Variant) -> bool: return not is_instance_valid(guard)), "surviving crab guards leave the arena after their retreat animation")
	if capture.is_valid(): await capture.call("ocean_05_crabs_retreat")
	GameState.set_health(health)
