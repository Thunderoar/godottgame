class_name KrakenHungerChecks
extends RefCounted

static func run(game: Game, check: Callable, capture: Callable = Callable()) -> void:
	var snapshot := GameState.data.duplicate(true)
	var ticking := game.is_processing()
	game.set_process(false)
	game.hud.hide_modals()
	GameState.data = GameState._make_default("adam")
	GameState._emit_all()
	game._clear_world()
	var ocean := OceanJourney.new()
	game.world = ocean
	game._world_holder.add_child(ocean)
	game.hud.set_world(ocean)
	game.hud.visible = false
	ocean.set_process(false)
	ocean._process(4)
	ocean.dismiss_sea_guide()
	_quiet_spawn(ocean)
	var full := ocean.fullness
	ocean._update_run(0.5)
	check.call(ocean.fullness < full and ocean.health == 3, "ordinary swimming drains fullness without healing or hurting a fed turtle")
	ocean.health = 2
	ocean.fullness = 40
	ocean.spawn_item("food",ocean.mouth_position().x)
	ocean._update_run(0)
	check.call(is_equal_approx(ocean.fullness,75) and ocean.health == 2 and ocean.food_eaten == 1, "nearby fish automatically restore fullness instead of lives without an input")
	check.call(ocean.fullness_speed_multiplier() == 1.0, "eating fish across 50 percent fullness immediately restores fast swimming")
	ocean._update_run(0)
	check.call(is_equal_approx(ocean.fullness,75) and ocean.food_eaten == 1, "an automatically eaten fish cannot feed the turtle twice")
	ocean.fullness = 95
	ocean.spawn_item("food",ocean.mouth_position().x)
	ocean._update_run(0)
	check.call(ocean.fullness == OceanJourney.FULLNESS_MAX, "fish cannot overfill the fullness meter")
	ocean.fullness = 50
	ocean.spawn_item("heart",ocean.mouth_position().x)
	ocean._update_run(0)
	check.call(ocean.health == 3 and ocean.fullness == 50, "pink hearts restore lives without replacing fish as food")
	var distant := ocean.spawn_item("food",ocean.mouth_position().x + OceanJourney.ACTION_REACH + 1)
	ocean._update_run(0)
	check.call(not distant.resolved and ocean.fullness == 50, "fish outside the mouth's feeding reach stay uneaten")
	distant.node.position = ocean.mouth_position() + Vector2(6,4)
	distant.lane = distant.node.position.y
	distant.phase = -ocean._clock * 3.0
	ocean._update_run(1.4)
	check.call(not distant.resolved, "fast fish in a different lane are not eaten")
	_clear(ocean)
	ocean.fullness = 40
	var fast_fish := ocean.spawn_item("food",ocean.mouth_position().x + 6)
	fast_fish.lane = ocean.mouth_position().y
	fast_fish.phase = -ocean._clock * 3.0
	ocean._update_run(1.4)
	check.call(fast_fish.resolved and ocean.fullness > 65, "swept automatic feeding catches fast fish crossing the mouth between frames")
	var waiting := ocean.spawn_item("food",ocean.mouth_position().x)
	var before_wait := ocean.fullness
	ocean._ocean_settings.visible = true
	ocean._update_run(0.5)
	check.call(not waiting.resolved and ocean.fullness == before_wait, "opening ocean settings suspends automatic feeding and fullness drain")
	ocean._ocean_settings.visible = false
	ocean.phase = OceanJourney.Phase.TRAVELLING
	ocean._update_run(0.5)
	check.call(not waiting.resolved and ocean.fullness == before_wait, "automatic feeding is disabled between routes")
	ocean.phase = OceanJourney.Phase.RUNNING
	_clear(ocean)
	ocean.health = 3
	ocean.fullness = 0.2
	ocean._hurt_time = OceanJourney.HIT_IMMUNITY
	var saved_stage := int(GameState.campaign().get("ocean_stage"))
	ocean._update_run(0.1)
	check.call(ocean.fullness == 0 and ocean.health == 0 and ocean.phase == OceanJourney.Phase.FINISHED, "reaching zero fullness immediately kills the turtle even with three protected lives")
	check.call(not Input.is_action_pressed("ocean_pickup") and ocean.swim_speed() == 0 and ocean.speed() == 0 and int(GameState.campaign().get("ocean_stage")) == saved_stage, "starvation stops movement and input without unlocking a sea checkpoint")
	ocean.restart()
	ocean._process(4)
	ocean.dismiss_sea_guide()
	_quiet_spawn(ocean)
	check.call(ocean.fullness == OceanJourney.FULLNESS_MAX and ocean.health == OceanJourney.MAX_HEALTH, "retry restores fullness and lives after immediate starvation")
	ocean.fullness = 1
	ocean.spawn_item("food",ocean.mouth_position().x)
	ocean._update_run(0)
	var hp := ocean.health
	ocean._update_run(0.2)
	check.call(ocean.fullness > 0 and ocean.health == hp, "eating nearby fish before fullness empties prevents starvation")
	_clear(ocean)
	ocean.health = 3
	ocean.fullness = 100
	ocean._hurt_time = 0
	var trash := ocean.spawn_item("trash",ocean.turtle.position.x-3)
	ocean._update_run(0)
	check.call(not trash.resolved and ocean.health == 3, "rubbish remains recoverable while it is still on screen")
	trash.node.position.x = ocean.visible_left()-10
	ocean._hurt_time = 1.2
	ocean._update_run(0)
	check.call(trash.resolved and ocean.health == 2 and ocean.missed_trash == 1, "each escaped rubbish item costs a life even during blinking protection")
	ocean._update_run(0)
	check.call(ocean.health == 2 and ocean.missed_trash == 1, "one escaped rubbish item cannot deduct lives twice")
	ocean.health = 3
	for i in 2: ocean.spawn_item("trash",ocean.visible_left()-10-i)
	ocean._update_run(0)
	check.call(ocean.health == 1 and ocean.missed_trash == 3, "two rubbish items escaping together each subtract one life")
	ocean.health = 3
	for kind in ["food","heart","bomb","shark"]: ocean.spawn_item(kind,ocean.visible_left()-10)
	ocean._update_run(0)
	check.call(ocean.health == 3 and ocean.missed_trash == 3, "missed fish, hearts and avoided hazards do not count as missed rubbish")
	var gold := GameState.gold()
	ocean._hurt_time = 1.2
	trash = ocean.spawn_item("trash",ocean.mouth_position().x)
	ocean._update_run(0)
	check.call(not trash.resolved and ocean.health == 3 and GameState.gold() == gold, "automatic feeding never consumes rubbish or awards its gold")
	check.call(ocean.choose_action("pickup") and trash.resolved and GameState.gold() == gold+1, "the remaining Pick Up action collects nearby rubbish during protection blinking")
	_clear(ocean)
	ocean.health = 3
	ocean.elapsed = OceanJourney.STAGE_SECONDS
	for i in 2: ocean.spawn_item("trash",25+i*3)
	ocean._complete_stage()
	check.call(ocean.health == 1 and ocean.phase == OceanJourney.Phase.TRAVELLING and ocean.missed_trash == 5, "route completion charges every uncollected rubbish item before saving success")
	ocean._process(OceanJourney.ROUTE_EXIT_SECONDS)
	ocean._process(OceanJourney.ROUTE_ENTRY_SECONDS)
	check.call(ocean.stage == 2 and ocean.fullness == OceanJourney.FULLNESS_MAX and ocean.health == 3 and ocean.missed_trash == 0, "a new sea route resets lives, fullness and missed-rubbish count")
	_quiet_spawn(ocean)
	ocean.health = 2
	ocean.elapsed = OceanJourney.STAGE_SECONDS
	var checkpoint := int(GameState.campaign().get("ocean_stage"))
	for i in 3: ocean.spawn_item("trash",25+i*3)
	ocean._complete_stage()
	check.call(ocean.health == 0 and ocean.phase == OceanJourney.Phase.FINISHED and int(GameState.campaign().get("ocean_stage")) == checkpoint, "fatal rubbish left behind causes defeat instead of unlocking the next route")
	ocean.restart()
	ocean._process(4)
	ocean.dismiss_sea_guide()
	_quiet_spawn(ocean)
	ocean.elapsed = 44
	for i in 20:
		ocean._spawn_clock = 0
		ocean._update_run(0)
	check.call(ocean.items.all(func(item: Dictionary) -> bool: return item.kind != "trash"), "late spawns leave enough time to collect all mandatory rubbish")
	_clear(ocean)
	ocean.elapsed = 12
	ocean.health = 3
	ocean.fullness = 55
	ocean.missed_trash = 1
	ocean.trash_collected = 3
	ocean._hurt_time = 0
	ocean.spawn_item("food",20)
	ocean.spawn_item("trash",24)
	ocean.spawn_item("shark",29)
	ocean._refresh_ui()
	if capture.is_valid(): await capture.call("01_fullness_and_required_rubbish")
	game._clear_world()
	var island := KrakenIsland.new()
	game.world = island
	game._world_holder.add_child(island)
	game.hud.set_world(island)
	game.hud.visible = true
	game._input_locked = false
	game._apply_input_lock()
	var king := island.boss
	king.set_physics_process(false)
	island.player.set_physics_process(false)
	king._player = island.player
	king._target = island.player
	check.call(island.background.texture.get_width() == 1280 and island.background.texture.get_height() == 800 and island.canvas_modulate != null, "Kraken arena uses the portal stone-floor renderer and moody lighting")
	await game.get_tree().physics_frame
	var ray := PhysicsRayQueryParameters2D.create(Vector2(4,7.7),Vector2(8,7.7),1)
	check.call(not island.get_world_2d().direct_space_state.intersect_ray(ray).is_empty(), "reference-style stone pillars are real combat obstacles")
	check.call(king.prison == island.cage and island.cage.friend.visible and not island.cage.available and king.sprite.texture == KrakenArt.body_texture(), "detailed Kraken visibly holds Arjun's locked illustrated prison")
	var king_start := king.position
	island.player.position = Vector2(21,16)
	king._state = Enemy.State.CHASE
	king._special_timer = 99
	var chase_distance := king.position.distance_to(island.player.position)
	for frame in 40:
		king._physics_process(1.0/60.0)
		await game.get_tree().physics_frame
	check.call(king.speed > 0 and king.position.distance_to(island.player.position) < chase_distance-0.5, "the Kraken actually walks toward Adam instead of staying at its spawn")
	var detour := island.monster_path(Vector2(6,14),Vector2(6,4.8))
	check.call(not detour.is_empty() and Array(detour).any(func(point: Vector2) -> bool: return absf(point.x-6) > 0.5), "Kraken pursuit plans a body-sized detour around stone pillars")
	king._special_timer = 0
	king._physics_process(0.01)
	check.call(king.tentacle_time >= 0 and king._boss_notified, "normal Kraken AI starts its tentacle power automatically")
	var casting_at := king.position
	king._physics_process(0.1)
	check.call(king.position.is_equal_approx(casting_at), "the Kraken holds still while its tentacle attack is telegraphed")
	if capture.is_valid(): await capture.call("02a_kraken_pursuit_and_power")
	king.position = king_start
	king.tentacle_time = -1
	king.grabbing = false
	king.hook_attack = false
	king._state = Enemy.State.CHASE
	king._attack_timer = 0
	king._special_timer = 99
	island.player.position = king.position + Vector2(0,2.8)
	island.player.invulnerable = 0
	var melee_health := GameState.health()
	var melee_damage := maxi(1,king.damage-GameState.defense())
	king._physics_process(0.01)
	check.call(king._state == Enemy.State.WINDUP and GameState.health() == melee_health, "nearby Kraken melee attacks warn before dealing damage")
	king._physics_process(0.6)
	king._physics_process(0.01)
	check.call(GameState.health() == melee_health-melee_damage, "the Kraken's ordinary melee attack deals real damage after player defence")
	island.player.invulnerable = 0
	king._physics_process(0.01)
	check.call(GameState.health() == melee_health-melee_damage, "one Kraken melee swing cannot damage Adam twice")
	GameState.set_health(melee_health)
	island.player.invulnerable = 0
	island.player.position = Vector2(21,16)
	var health := GameState.health()
	king._cast_special()
	king._update_tentacle(0.5)
	check.call(GameState.health() == health and not king.grabbing, "tentacle warning gives time to dodge before damage")
	island.player.position = Vector2(8,20)
	king._update_tentacle(0.9)
	check.call(GameState.health() == health and not king.grabbing, "dodging the locked hook trajectory avoids both damage and capture")
	king.tentacle_time = -1
	king.hook_attack = false
	island.player.position = Vector2(21,16)
	island.player.invulnerable = 0
	king._cast_special()
	king._update_tentacle(1.4)
	check.call(king.grabbing and GameState.health() < health, "an extended tentacle catches and damages a player who stays in its path")
	var distance := island.player.position.distance_to(king.position)
	king._update_tentacle(0.3)
	check.call(island.player.position.distance_to(king.position) < distance, "caught Adam is physically pulled closer to the Kraken")
	island.player.position = Vector2(21,16)
	var wall := StaticBody2D.new()
	wall.collision_layer = 1
	wall.position = Vector2(21,14.8)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(8,0.35)
	shape.shape = rectangle
	wall.add_child(shape)
	island.add_child(wall)
	await game.get_tree().physics_frame
	king._update_tentacle(0.4)
	check.call(island.player.position.y > 15.1, "tentacle dragging respects walls instead of teleporting Adam through them")
	wall.queue_free()
	if capture.is_valid():
		await game.get_tree().create_timer(0.6).timeout
		await capture.call("02_portal_arena_kraken_grapple")
	king.take_damage(king.max_hp,Vector2.ZERO,island.player)
	await game.get_tree().process_frame
	check.call(island.defeated and island.cage.available and not island.cage.opened, "real Kraken defeat unlocks the prison without rescuing Arjun before it is opened")
	GameState.data = snapshot
	GameState._emit_all()
	await game._load_lobby(false)
	game.hud.visible = true
	for frame in 3: await game.get_tree().physics_frame
	game.set_process(ticking)

static func _quiet_spawn(ocean: OceanJourney) -> void:
	ocean._spawn_clock = 999
	ocean._heart_clock = 999
	ocean._bomb_clock = 999
	ocean._shark_clock = 999

static func _clear(ocean: OceanJourney) -> void:
	for item in ocean.items.duplicate(): ocean._resolve_item(item,false)
