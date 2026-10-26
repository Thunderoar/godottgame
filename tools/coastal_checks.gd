class_name CoastalChecks
extends RefCounted
## Full feature path using the gate's already verified temporary player data.
static func run(game: Game, check: Callable, capture: Callable = Callable()) -> void:
	var snapshot := GameState.data.duplicate(true)
	var autosave := GameState.autosave_enabled
	var processing := game.is_processing()
	game.set_process(false)
	GameState.autosave_enabled = false
	GameState.new_game("adam")
	game._load_lobby(false)
	for frame in 4: await game.get_tree().physics_frame
	var lobby := game.world as Lobby
	_freeze(lobby)
	game.hud.tutorial_guide._skip()
	game._input_locked = false
	lobby.player.controls_locked = false
	var player := game.player()
	var tree := lobby._forest_trees[0]
	var sound_cursor := Sfx._next_player
	tree.take_attack_damage(10)
	tree._process(0.01)
	check.call(tree.burning and Sfx._next_player == sound_cursor and tree.get_node_or_null("BurningSound") == null, "fire-monster tree hits and burning create no sound")
	var burning_hp := tree.health
	tree._process(ForestTree.BURN_INTERVAL)
	check.call(tree.health < burning_hp and Sfx._next_player == sound_cursor, "ongoing tree burning damages silently")
	tree.take_physical_damage(2)
	check.call(tree.burning and Sfx._next_player == sound_cursor, "physical hits on a burning tree stay silent too")
	tree.water(tree.max_health)
	check.call(not tree.burning and Sfx._next_player == sound_cursor, "watering silently extinguishes the fire")
	tree.take_physical_damage(2)
	tree._process(0.01)
	check.call(not tree.burning and Sfx._next_player != sound_cursor, "physical tree hits retain their normal impact sound")
	var resident := Resident.new()
	resident.resident_name = "Coastal Test Resident"
	resident.position = Vector2(34, 24.3)
	lobby.add_child(resident)
	resident.set_physics_process(false)
	for kind in ["fire", "urchin"]:
		var enemy := Enemy.new()
		enemy.kind = kind
		enemy.damage = 10
		enemy.max_hp = 200
		enemy.position = Vector2(34.6, 24.3)
		lobby.add_child(enemy)
		enemy.set_physics_process(false)
		sound_cursor = Sfx._next_player
		enemy._enter(Enemy.State.ALERT)
		check.call((Sfx._next_player == sound_cursor) if kind == "fire" else (Sfx._next_player != sound_cursor), "%s alert follows its combat audio policy" % kind)
		sound_cursor = Sfx._next_player
		for cycle in 3:
			enemy._enter(Enemy.State.WINDUP)
		check.call((Sfx._next_player == sound_cursor) if kind == "fire" else (Sfx._next_player != sound_cursor), "%s repeated attack windups follow its audio policy" % kind)
		player.global_position = Vector2(34, 24.3)
		resident.global_position = Vector2(42, 25)
		GameState.data.shield = 0
		GameState.set_health(GameState.health_max())
		player.invulnerable = 0
		enemy._target = enemy._choose_village_actor(null)
		check.call(enemy._target == player, "%s can choose the current living player" % kind)
		var hp := GameState.health()
		sound_cursor = Sfx._next_player
		enemy._hit_dealt = false
		enemy._attack_active(0)
		check.call(GameState.health() < hp, "%s active hit damages the player" % kind)
		check.call(Sfx._next_player == sound_cursor, "%s active hit adds no target impact audio" % kind)
		player._attack_dir = Vector2.RIGHT
		player._apply_melee_hit(GameState.character_data(), {"arc": "lr"})
		check.call(enemy.hp < enemy.max_hp and ((Sfx._next_player == sound_cursor) if kind == "fire" else (Sfx._next_player != sound_cursor)), "player melee damages %s with the correct impact audio policy" % kind)
		player.global_position = Vector2(22, 24)
		resident.global_position = Vector2(34, 24.3)
		enemy._target = enemy._choose_village_actor(null)
		check.call(enemy._target == resident, "%s can choose an exposed resident" % kind)
		var resident_hp := GameState.resident_health(resident.resident_name)
		sound_cursor = Sfx._next_player
		enemy._hit_dealt = false
		enemy._attack_active(0)
		check.call(GameState.resident_health(resident.resident_name) < resident_hp, "%s active hit damages the resident" % kind)
		check.call(Sfx._next_player == sound_cursor, "%s resident hit adds no impact audio" % kind)
		resident.sheltered = true
		check.call(enemy._choose_village_actor(null) != resident, "%s excludes sheltered residents" % kind)
		resident.sheltered = false
		sound_cursor = Sfx._next_player
		enemy.take_damage(enemy.hp)
		check.call(enemy.dead and ((Sfx._next_player == sound_cursor) if kind == "fire" else (Sfx._next_player != sound_cursor)), "%s defeat follows its combat audio policy" % kind)
		enemy.queue_free()
		await game.get_tree().process_frame
	resident.queue_free()
	GameState.set_health(GameState.health_max())
	player.invulnerable = 0
	player._visual.modulate = Color.WHITE
	var occlusion := lobby.get_node("WorldOcclusion") as WorldOcclusion
	player.global_position = lobby._house_position + Vector2(0, -2.7)
	occlusion._process(1.0)
	check.call(lobby.house_sprite.self_modulate.a < 0.4, "the main house fades when it hides the player's body")
	if capture.is_valid():
		_look(lobby, player.global_position)
		await capture.call("01_transparent_house")
	player.global_position = lobby._house_position + Vector2(0, 3)
	occlusion._process(1.0)
	check.call(is_equal_approx(lobby.house_sprite.self_modulate.a, 1.0), "house opacity restores after leaving its silhouette")
	var crown := tree._visuals[1] as Sprite2D
	player.global_position = crown.global_transform * crown.get_rect().get_center() + Vector2(0, 0.65)
	occlusion._process(1.0)
	check.call(crown.self_modulate.a < 0.4, "tree canopy fades when the player walks behind it")
	if capture.is_valid():
		_look(lobby, player.global_position)
		await capture.call("02_transparent_tree")
	var query := PhysicsPointQueryParameters2D.new()
	query.collision_mask = 1
	var space := lobby.get_world_2d().direct_space_state
	for x in [1.0, 32.0, 63.0]:
		query.position = Vector2(x, 0.7)
		check.call(not space.intersect_point(query).is_empty(), "northern stone wall blocks passage at x=%.0f" % x)
	check.call(lobby.get_node_or_null("TwinCaveHill") == null and lobby.get_node_or_null("CaveRockCollision") == null, "portals have no cave artwork or hidden cave collider")
	for id in ["monster_portal", "pet_portal"]:
		query.position = lobby._layout.position_of(id) + Vector2(0, -2.7)
		check.call(space.intersect_point(query).is_empty(), "%s former cave back is open after cave removal" % id)
		query.position = lobby._layout.approach(id)
		check.call(space.intersect_point(query).is_empty(), "%s remains accessible from its front" % id)
	for gate in game.get_tree().get_nodes_in_group("battle_portal"):
		var frame := gate._frame as Sprite2D
		check.call(frame.scale.is_equal_approx(Vector2.ONE * PixelArt.PX) and frame.global_position.is_equal_approx(gate.global_position), "%s portal retains its full standalone frame" % gate.gate_kind)
	if capture.is_valid():
		player.global_position = lobby._layout.position_of("portal_court")
		_look(lobby, player.global_position)
		await capture.call("03_portals_and_north_wall")
	var piece := lobby._rubbish_system.spawn_piece(1)
	piece.global_position = piece.target
	piece._reach_beach()
	await game.get_tree().process_frame
	var rubbish := game.get_tree().get_first_node_in_group("beach_rubbish") as BeachRubbish
	check.call(is_instance_valid(rubbish), "ocean rubbish becomes a collectible object on the beach")
	var gold := GameState.gold()
	player.global_position = rubbish.global_position + Vector2(5, 0)
	rubbish.interact(player)
	check.call(GameState.gold() == gold and not rubbish.collected, "distant beach pickup cannot grant gold")
	player.global_position = rubbish.global_position
	if capture.is_valid():
		_look(lobby, player.global_position)
		await capture.call("04_manual_beach_rubbish")
	rubbish.interact(player)
	rubbish.interact(player)
	check.call(GameState.gold() == gold + 1 and rubbish.collected, "one beached piece pays exactly once on Pick Up")
	await game.enter_home()
	var interior := game.home_interior
	GameState.set_health(1)
	GameState.data.recovery_active = true
	player.global_position = interior.global_position + HomeInterior.EXIT_FOOTPRINT.get_center()
	interior._process(0)
	check.call(game.home_interior == interior and not game._transitioning, "automatic doorway respects recovery confinement")
	GameState.set_health(GameState.health_max())
	GameState.finish_recovery()
	interior._process(0)
	for i in 60:
		if not game._transitioning: break
		await game.get_tree().create_timer(0.03).timeout
	check.call(game.home_interior == null and not game._transitioning, "walking onto the indoor doorway automatically returns outdoors once")
	var boarding := lobby.ship_boarding
	check.call(boarding.ship.position.distance_to(boarding.position) < 2.5, "the UNISZA ship is moored immediately beside the jetty")
	if capture.is_valid():
		_look(lobby, boarding.global_position + Vector2(0, 0.7))
		await capture.call("05a_unisza_moored")
	player.global_position = boarding.global_position + Vector2(7, 0)
	check.call(not game.board_ship(boarding), "ship boarding rejects a distant player")
	player.global_position = boarding.global_position
	Input.action_press("move_right")
	check.call(game.board_ship(boarding), "the reachable jetty boarding point starts automatic sailing")
	check.call(not game.board_ship(boarding) and player.controls_locked and not Input.is_action_pressed("move_right"), "boarding locks input, releases held controls and rejects duplicate departures")
	if capture.is_valid():
		_look(lobby, boarding.ship.global_position)
		await capture.call("05_ship_departure")
	boarding.ship.position.x = 0.01
	boarding._physics_process(0.05)
	check.call(game._transitioning and boarding.arrived, "touching the sea map boundary starts a fade transition")
	for i in 80:
		if game.world is OceanJourney and not game._transitioning: break
		await game.get_tree().create_timer(0.03).timeout
	check.call(game.world is OceanJourney and not game._transitioning, "ship departure loads the separate turtle world without scene switching")
	var ocean := game.world as OceanJourney
	if ocean == null: return
	check.call(ocean.get_viewport().get_camera_2d() == ocean.camera, "the ocean camera replaces the departing village camera")
	ocean.set_process(false)
	ocean._process(0.8)
	check.call(ocean.phase == OceanJourney.Phase.DIVE and ocean.player.position.y > 4.5, "player automatically dives into the sea")
	if capture.is_valid(): await capture.call("06_ocean_dive")
	ocean._process(1.2)
	check.call(ocean.phase == OceanJourney.Phase.RESCUE and ocean.turtle.position.x > -6, "turtle automatically swims toward the diving player")
	ocean._process(2.0)
	check.call(ocean.phase == OceanJourney.Phase.RUNNING and ocean.player.position.distance_to(ocean.turtle.position) < 1.5, "player automatically boards the turtle")
	if capture.is_valid():
		for pair in [["trash", ocean._pickup], ["food", ocean._eat]]:
			var kind := str(pair[0])
			var button := pair[1] as TouchActionButton
			ocean.health = 2
			var before_gold := GameState.gold()
			var before_food := ocean.food_eaten
			ocean.spawn_item(kind, ocean.mouth_position().x)
			ocean.set_process(true)
			var press := InputEventScreenTouch.new()
			press.index = 17
			press.position = ocean.get_viewport().get_final_transform() * button.get_global_rect().get_center()
			press.pressed = true
			Input.parse_input_event(press)
			await game.get_tree().create_timer(0.08).timeout
			var release := InputEventScreenTouch.new()
			release.index = 17
			release.position = press.position
			Input.parse_input_event(release)
			await game.get_tree().process_frame
			ocean.set_process(false)
			check.call((GameState.gold() == before_gold + 1) if kind == "trash" else (ocean.food_eaten == before_food + 1 and ocean.health == 2), "native screen touch activates the %s button" % button.caption)
			check.call(not Input.is_action_pressed(button.action), "native screen touch releases %s" % button.action)
			# Separate gestures across frames, including on slow native renderers.
			await game.get_tree().create_timer(0.12).timeout
	var trash := ocean.spawn_item("trash", ocean.mouth_position().x)
	gold = GameState.gold()
	if capture.is_valid(): await capture.call("07_turtle_trash_action")
	check.call(ocean.choose_action("pickup") and GameState.gold() == gold + 1 and trash.resolved, "correct turtle rubbish pickup pays one gold and resolves the item")
	check.call(not ocean.choose_action("pickup") and GameState.gold() == gold + 1, "a resolved ocean item cannot pay twice")
	if capture.is_valid(): await capture.call("08_player_net_animation")
	ocean.health = 2
	ocean.spawn_item("food", ocean.mouth_position().x)
	check.call(ocean.choose_action("eat") and ocean.health == 2 and ocean._mouth_time > 0, "correct food opens the turtle mouth without restoring health")
	ocean._process(0.01)
	if capture.is_valid(): await capture.call("09_turtle_eat_animation")
	ocean.health = 3
	for kind in ["food", "trash"]:
		ocean._hurt_time = 0
		ocean.spawn_item(kind, ocean.mouth_position().x)
		var hp := ocean.health
		check.call(not ocean.choose_action("pickup" if kind == "food" else "eat") and ocean.health == hp - 1, "wrong action on %s costs turtle health" % kind)
	check.call(GameState.gold() == gold + 1, "wrong turtle actions never award gold")
	var base_speed := ocean.speed()
	ocean.elapsed += 120
	check.call(ocean.speed() > base_speed and ocean.speed() <= OceanJourney.MAX_SPEED, "food and rubbish travel faster as the journey progresses")
	ocean.elapsed = 0
	var hp := ocean.health
	ocean.spawn_item("trash", ocean.mouth_position().x - OceanJourney.ACTION_REACH - 0.05)
	ocean._process(0.01)
	check.call(ocean.health == hp, "missed rubbish does not inflict bomb damage")
	ocean._pickup._press()
	check.call(Input.is_action_pressed("ocean_pickup"), "Pick Up touch uses its shared InputMap action")
	ocean._pickup.cancel()
	check.call(not Input.is_action_pressed("ocean_pickup"), "cancelling Pick Up releases its synthetic input")
	for i in ocean.health:
		ocean._hurt_time = 0
		ocean.spawn_item("trash", ocean.mouth_position().x)
		ocean.choose_action("eat")
	ocean._process(2.2)
	check.call(ocean.phase == OceanJourney.Phase.FINISHED and ocean.health == 0 and ocean._retry.visible, "zero turtle health ends the run and exposes Ride Again")
	if capture.is_valid(): await capture.call("10_turtle_result")
	ocean.restart()
	check.call(ocean.phase == OceanJourney.Phase.DIVE and ocean.health == OceanJourney.MAX_HEALTH and ocean.items.is_empty(), "Ride Again resets the journey and clears old items")
	game.return_from_ocean()
	for i in 120:
		if game.world is Lobby and not game._transitioning: break
		await game.get_tree().create_timer(0.03).timeout
	var returned_lobby := game.world as Lobby
	var incoming := returned_lobby.ship_boarding
	check.call(incoming.returning and game.player().controls_locked and not game.hud.visible, "returning from sea keeps the player aboard a moving ship with controls locked")
	check.call(game.player().global_position.distance_to(incoming.ship.global_position + ShipDeparture.PASSENGER_OFFSET) < 0.05 and not incoming.landed, "the returning passenger stays on the ship before docking")
	check.call(not game.board_ship(incoming), "a returning ship cannot start another departure")
	var return_occlusion := returned_lobby.get_node("WorldOcclusion") as WorldOcclusion
	check.call(not return_occlusion.obscures(incoming.ship, game.player()), "the yellow ship stays opaque while carrying its passenger")
	if capture.is_valid():
		for i in 180:
			if incoming.ship.position.x >= 2.5: break
			await game.get_tree().create_timer(0.02).timeout
		await capture.call("11_returning_ship")
	for i in 300:
		if incoming.disembarking or incoming.landed: break
		await game.get_tree().create_timer(0.02).timeout
	check.call(incoming.disembarking and incoming.ship.position.is_equal_approx(incoming._moored_position) and game.player().controls_locked, "disembarking starts only after the ship reaches its mooring")
	for i in 120:
		if incoming.landed: break
		await game.get_tree().create_timer(0.02).timeout
	check.call(incoming.landed and game.hud.visible and not game.player().controls_locked and game.player().collision_mask != 0, "stepping onto the jetty restores collision, HUD and movement")
	check.call(game.player().position.distance_to(incoming.position) < 0.2, "the passenger disembarks directly onto the jetty deck")
	if capture.is_valid(): await capture.call("12_jetty_disembark")
	check.call(not Input.is_action_pressed("ocean_pickup") and not Input.is_action_pressed("ocean_eat"), "ocean actions are released on world changes")
	GameState.save_game()
	check.call(GameState.load_game() and GameState.gold() >= gold + 1, "earned cleanup gold survives save and reload")
	GameState.data = snapshot
	GameState._emit_all()
	game._load_lobby(false)
	for i in 4: await game.get_tree().physics_frame
	GameState.autosave_enabled = autosave
	game.set_process(processing)

static func _freeze(node: Node) -> void:
	node.set_process(false)
	node.set_physics_process(false)
	for child in node.get_children(): _freeze(child)

static func _look(lobby: Lobby, at: Vector2) -> void:
	lobby.camera.set_process(false)
	lobby.camera.set_physics_process(false)
	lobby.player.reset_physics_interpolation()
	lobby.player._update_nearby()
	var game := lobby.get_tree().get_first_node_in_group("game") as Game
	if is_instance_valid(game): game.hud._update_prompt()
	lobby.camera.target = null
	lobby.camera.global_position = at
	lobby.camera.reset_physics_interpolation()
