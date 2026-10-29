class_name StoryChecks
extends RefCounted

static func run(game: Game, check: Callable, capture: Callable = Callable()) -> void:
	var snapshot := GameState.data.duplicate(true)
	var autosave := GameState.autosave_enabled
	var ticking := game.is_processing()
	game.set_process(false)
	GameState.autosave_enabled = false
	game.hud.hide_modals()
	GameState.data = GameState._make_default("adam")
	GameState._emit_all()
	await game._load_lobby(false)
	await game.get_tree().process_frame
	check.call(GameState.campaign().get("ocean_stage") == 1 and not GameState.friends_reunited(), "campaign begins with both friends missing and sea route one")
	check.call(not GameState.rescue_friend("unknown"), "invalid rescue IDs cannot change campaign progress")
	check.call(not GameState.advance_ocean_stage(2) and GameState.advance_ocean_stage(1), "sea routes unlock only in order")
	check.call(GameState.rescue_friend("arjun") and not GameState.rescue_friend("arjun"), "friend rescue is idempotent")
	GameState.save_game()
	check.call(GameState.load_game() and int(GameState.campaign().get("ocean_stage")) == 2 and bool(GameState.campaign().get("arjun_rescued")), "sea progress and rescued friends survive JSON save reload")
	GameState.data.campaign.ocean_stage = 1000.0
	GameState.data.campaign.ending_seen = true
	GameState._sanitize()
	check.call(int(GameState.campaign().get("ocean_stage")) == 3 and not bool(GameState.campaign().get("ending_seen")), "campaign sanitizer clamps stages and rejects premature endings")
	GameState.data = GameState._make_default("adam")
	GameState._emit_all()
	await game._load_lobby(false)
	await game.get_tree().process_frame
	check.call(game.hud._map_button is Button and game.hud._map_button.anchor_right == 1 and not game.hud._minimap.visible, "top-right Map button keeps the map hidden until requested")
	check.call(game.hud._clock_label.get_parent().anchor_bottom == 1, "world clock is anchored to the bottom of the screen")
	check.call(FieldGuideDB.entries(3).size() == 4 and NpcInfo.description("water").contains("extinguishes"), "book includes four story/sea pages and NPC job explanations")
	if capture.is_valid(): await capture.call("01_village_map_clock")
	var villager := game.world._residents[0] as Resident
	villager.set_physics_process(false)
	villager.global_position = game.player().global_position + Vector2(1.2, 0)
	var touch := InputEventScreenTouch.new()
	touch.index = 19
	touch.position = game.get_viewport().get_final_transform() * (villager.get_global_transform_with_canvas() * Vector2(0, -0.6))
	touch.pressed = true
	Input.parse_input_event(touch)
	await game.get_tree().process_frame
	var release := InputEventScreenTouch.new()
	release.index = 19
	release.position = touch.position
	Input.parse_input_event(release)
	await game.get_tree().process_frame
	check.call(game.hud.dialogue_panel.visible, "real screen touch on a villager opens their role and powers")
	if capture.is_valid(): await capture.call("02_npc_information")
	game.hud.hide_modals()
	if capture.is_valid():
		game.hud.field_guide_panel._category = 3
		game.open_field_guide()
		await game.get_tree().process_frame
		await game.get_tree().process_frame
		await capture.call("02b_storybook")
		game.hud.hide_modals()
	game.open_shop("equipment", "Ilan")
	await game.get_tree().process_frame
	await game.get_tree().process_frame
	check.call(_contains(game.hud.shop_panel, "ROOFTOP MACHINE GUNS"), "tower defense purchases are exposed at the weapon shop")
	GameState.add_gold(GameState.roof_gun_cost())
	check.call(not game.hud.shop_panel._tower_button.disabled, "tower purchase affordability refreshes in place after Gold changes")
	if capture.is_valid(): await capture.call("02c_weapon_towers")
	game.hud.hide_modals()
	var editor := ControlLayoutEditor.new()
	game.add_child(editor)
	await game.get_tree().process_frame
	check.call(editor._handles.has("menu") and editor._handles.has("joystick"), "visual control editor exposes Menu and world movement")
	if capture.is_valid(): await capture.call("03_drag_controls")
	var handle := editor._handles["attack"] as Control
	var at := handle.get_global_rect().get_center()
	var initial := handle.position
	var drag_press := InputEventScreenTouch.new()
	drag_press.index = 20
	drag_press.position = game.get_viewport().get_final_transform() * at
	drag_press.pressed = true
	Input.parse_input_event(drag_press)
	await game.get_tree().process_frame
	var drag := InputEventScreenDrag.new()
	drag.index = 20
	drag.position = game.get_viewport().get_final_transform() * (at - Vector2(90, 30))
	drag.relative = Vector2(-90, -30)
	Input.parse_input_event(drag)
	await game.get_tree().process_frame
	var drag_release := InputEventScreenTouch.new()
	drag_release.index = 20
	drag_release.position = drag.position
	Input.parse_input_event(drag_release)
	check.call(handle.position.distance_to(initial - Vector2(90, 30)) < 2, "real screen drag repositions a control without triggering combat")
	editor.move_handle("attack", Vector2(420, 390))
	editor._commit_all()
	check.call(float(GameState.control_layout().get("attack", {}).get("x", 0)) == 420, "drag-editor positions persist through the control transaction")
	editor.queue_free()
	game.hud.reset_control_layout()
	var mode := game.world.process_mode
	game.play_story("intro")
	await game.get_tree().process_frame
	var intro := _story(game)
	check.call(intro != null and intro.lines().size() == 6 and game.world.process_mode == Node.PROCESS_MODE_DISABLED, "animated six-beat introduction locks the village safely")
	if capture.is_valid():
		intro.page = 2
		intro._page_time = 1.5
		intro._render()
		await capture.call("04_shipwreck_story")
	intro.finish()
	await game.get_tree().process_frame
	check.call(bool(GameState.campaign().get("intro_seen")) and game.world.process_mode == mode and not game._story_active, "skipping an introduction finishes once and restores world processing")
	await OpeningFishingChecks.run(game, check)
	game._clear_world()
	var ocean := OceanJourney.new()
	game.world = ocean
	game._world_holder.add_child(ocean)
	game.hud.set_world(ocean)
	game.hud.visible = false
	ocean.set_process(false)
	ocean._process(4.0)
	ocean.dismiss_sea_guide()
	check.call(ocean.health == 3 and is_equal_approx(ocean.speed() / OceanJourney.INITIAL_SPEED, 2.5), "turtle starts with three lives and 2.5x speed")
	var initial_y := ocean.turtle.position.y
	Input.action_press("move_up")
	ocean._process(0.25)
	Input.action_release("move_up")
	check.call(ocean.turtle.position.y < initial_y and ocean.player.position.distance_to(ocean.turtle.position) < 1.5, "vertical input steers both turtle and rider")
	if capture.is_valid():
		ocean.spawn_item("bomb", 28)
		ocean.spawn_item("heart", 24)
		await capture.call("05_ocean_bombs_hearts")
		for item in ocean.items.duplicate(): ocean._resolve_item(item, false)
	ocean.health = 2
	ocean.spawn_item("food", ocean.mouth_position().x)
	ocean._update_run(0)
	check.call(ocean.food_eaten == 1 and ocean.health == 2, "automatically eating ordinary food never restores a life")
	ocean.spawn_item("heart", ocean.mouth_position().x)
	ocean._update_run(0)
	check.call(ocean.health == 3, "a nearby pink heart automatically restores exactly one life")
	var bomb := ocean.spawn_item("bomb", ocean.turtle.position.x + 0.6)
	bomb.node.position = ocean.turtle.position + Vector2(0.6, 0)
	bomb.lane = ocean.turtle.position.y
	bomb.phase = -ocean._clock * 1.4
	ocean._process(0.01)
	check.call(ocean.health == 2 and bomb.resolved and ocean._hurt_time > 0, "bomb collision explodes once and starts turtle protection blinking")
	var protected_hp := ocean.health
	ocean._mistake("second hit")
	check.call(ocean.health == protected_hp, "the blinking window prevents repeated life loss")
	ocean.health = 1
	ocean._hurt_time = 0
	ocean._mistake("last hit")
	ocean._process(1.1)
	check.call(ocean.phase == OceanJourney.Phase.FINISHED and is_equal_approx(ocean.turtle.rotation, PI), "zero lives flips the turtle before it sinks")
	ocean._process(1.2)
	check.call(ocean.turtle.modulate.a < 0.05 and ocean._retry.visible, "sinking fades the turtle and then exposes retry")
	ocean.restart()
	check.call(ocean.health == 3 and ocean.turtle.rotation == 0 and ocean.player.modulate.a == 1, "retry restores turtle and passenger visibility")
	for route in range(1,GameState.OCEAN_STAGES+1):
		ocean.phase = OceanJourney.Phase.RUNNING
		ocean.elapsed = OceanJourney.STAGE_SECONDS
		ocean._refresh_ui()
		ocean._pickup._press()
		var start_position := ocean.turtle.position
		ocean._update_run(0)
		check.call(ocean.phase == OceanJourney.Phase.TRAVELLING and ocean.stage_cleared, "route %d automatically begins forward departure" % route)
		check.call(int(GameState.campaign().get("ocean_stage")) == mini(route+1,GameState.OCEAN_STAGES), "route %d saves its checkpoint before the travel animation" % route)
		check.call(not ocean._retry.visible and ocean._return.disabled and ocean._controls_button.disabled and not Input.is_action_pressed("ocean_pickup"), "route %d transit hides Next and releases/locks gameplay controls" % route)
		var lives := ocean.health
		var saved_route := int(GameState.campaign().get("ocean_stage"))
		ocean._complete_stage()
		ocean.restart()
		ocean._mistake("cannot damage between routes")
		check.call(ocean.phase == OceanJourney.Phase.TRAVELLING and ocean.health == lives and int(GameState.campaign().get("ocean_stage")) == saved_route and not ocean.choose_action("pickup"), "route %d transit cannot be skipped, damaged or rewarded twice" % route)
		if route == 1:
			GameState.save_game()
			check.call(GameState.load_game() and int(GameState.campaign().get("ocean_stage")) == 2, "next sea checkpoint survives a save reload during departure")
		ocean._process(OceanJourney.ROUTE_EXIT_SECONDS*0.5)
		check.call(ocean.turtle.position.x > start_position.x and ocean.player.position.distance_to(ocean.turtle.position) < 1.5, "route %d visibly carries Adam forwards with the turtle" % route)
		if capture.is_valid() and route == 1: await capture.call("05b_route_1_swim_forward")
		ocean._process(OceanJourney.ROUTE_EXIT_SECONDS*0.5)
		if route < GameState.OCEAN_STAGES:
			check.call(ocean.stage == route+1 and ocean.phase == OceanJourney.Phase.ARRIVING and ocean.elapsed == 0 and ocean.health == OceanJourney.MAX_HEALTH, "route %d loads automatically after the outgoing turtle leaves the screen" % (route+1))
			ocean._process(OceanJourney.ROUTE_ENTRY_SECONDS*0.5)
			check.call(ocean.turtle.position.x > ocean.visible_left()-5 and ocean.player.position.distance_to(ocean.turtle.position) < 1.5, "route %d has a visible mounted entry animation" % (route+1))
			if capture.is_valid(): await capture.call("05c_route_%d_arrival" % (route+1))
			ocean._process(OceanJourney.ROUTE_ENTRY_SECONDS*0.5)
			check.call(ocean.phase == OceanJourney.Phase.RUNNING and not ocean._return.disabled and not ocean._controls_button.disabled and not ocean._retry.visible, "route %d resumes gameplay without a confirmation button" % (route+1))
	for i in 180:
		if game.world is KrakenIsland and not game._transitioning: break
		await game.get_tree().create_timer(0.025).timeout
	check.call(game.world is KrakenIsland, "the last sea route carries Adam to Kraken Island")
	if not game.world is KrakenIsland: return
	var island := game.world as KrakenIsland
	if capture.is_valid(): await capture.call("06_kraken_island_prison")
	check.call(not island.cage.available and not island.defeated, "Arjun's prison stays locked until the sea king is defeated")
	island.boss.take_damage(island.boss.max_hp, Vector2.ZERO, island.player)
	for i in 50:
		if island.cage.available: break
		await game.get_tree().create_timer(0.02).timeout
	check.call(island.cage.available and island.defeated, "real boss damage unlocks the prison")
	island.player.position = island.cage.position
	island.cage.interact(island.player)
	await game.get_tree().process_frame
	check.call(bool(GameState.campaign().get("arjun_rescued")) and island.cage.opened and _story(game) != null, "Use opens Arjun's cage and starts his boarding sequence")
	_finish_story(game)
	for i in 100:
		if game.world is Lobby and not game._transitioning: break
		await game.get_tree().create_timer(0.02).timeout
	check.call(game.world is Lobby and game._sailing, "Arjun's rescue returns on an incoming ship")
	var home := game.world as Lobby
	var boarding := home.ship_boarding
	check.call(boarding.ship.get_node_or_null("ArjunPassenger") != null, "rescued Arjun is visible aboard the returning ship")
	var returning_friend := boarding.ship.get_node_or_null("ArjunPassenger") as Sprite2D
	check.call(returning_friend != null and is_equal_approx(returning_friend.global_scale.x,PixelArt.PX), "rescued Arjun keeps the correct human scale aboard the ship")
	check.call(returning_friend is PlayerSprite and returning_friend.offset == Vector2(0,-24) and returning_friend.global_position.distance_to(home.player.global_position) > 2.0, "Arjun stands feet-aligned on the stern, clearly separated from Adam and the mast")
	boarding.ship.position = boarding._moored_position + Vector2(-4,0)
	boarding._physics_process(0)
	check.call(returning_friend.global_position.is_equal_approx(boarding.ship.global_position+ShipDeparture.ARJUN_OFFSET), "Arjun follows the returning ship at his visible rear-deck position")
	if capture.is_valid(): await capture.call("06a_arjun_visible_on_returning_ship")
	boarding.ship.position = boarding._moored_position
	boarding._physics_process(0)
	home.player.position = boarding.position
	boarding._physics_process(0.01)
	check.call(game._arjun_walk != null and game._arjun_walk.is_valid() and returning_friend.get_parent() == home and _hero_count(home) == 0, "Arjun leaves the ship as one continuous actor without a duplicate villager")
	var walk_route := home.resident_path(boarding.global_position+Vector2(0.6,0),home._house_position+Vector2(-3,3))
	check.call(not walk_route.is_empty() and walk_route[-1].distance_to(home._house_position+Vector2(-3,3)) < 0.6, "Arjun's walk has a connected resident route from the jetty into the village")
	game._arjun_walk.pause()
	var walk_start := returning_friend.global_position
	game._arjun_walk.custom_step(0.5)
	check.call(is_equal_approx(returning_friend.global_position.distance_to(walk_start),Resident.WALK_SPEED*0.5) and is_equal_approx(returning_friend.global_scale.x,PixelArt.PX), "Arjun disembarks at normal resident walking speed and keeps human scale")
	if capture.is_valid(): await capture.call("06b_arjun_walking_from_jetty")
	game._arjun_walk.custom_step(300)
	await game.get_tree().process_frame
	check.call(not game._arjun_returning and _hero_count(home) == 1, "Arjun disembarks and joins the village once")
	var friend: VillageHero
	for child in home.get_children():
		if child is VillageHero: friend = child
	var foe := Enemy.new()
	foe.kind = "urchin"
	foe.max_hp = 200
	foe.position = friend.position + Vector2(1, 0)
	home.add_child(foe)
	foe.set_physics_process(false)
	friend._physics_process(1.2)
	check.call(foe.hp < foe.max_hp, "rescued Arjun deals real damage defending BESUT")
	foe.queue_free()
	GameState.data.level = 30
	GameState.data.portals["drowned_throne"].unlocked = true
	GameState.start_expedition("drowned_throne")
	await game._load_dungeon("drowned_throne", false)
	var dungeon := game.world as Dungeon
	dungeon.boss.take_damage(dungeon.boss.max_hp, Vector2.ZERO, dungeon.player)
	for i in 60:
		if _story(game) != null: break
		await game.get_tree().create_timer(0.025).timeout
	check.call(bool(GameState.campaign().get("mei_ling_rescued")) and _story(game) != null and _story(game).kind == "mei", "the final portal boss frees Mei Ling and starts her exit sequence")
	_finish_story(game)
	for i in 180:
		if game.world is Lobby and _story(game) != null: break
		await game.get_tree().create_timer(0.025).timeout
	check.call(game.world is Lobby and _story(game) != null and _story(game).kind == "ending", "returning with both friends triggers the reunion ending")
	if capture.is_valid(): await capture.call("07_friends_reunited")
	_finish_story(game)
	await game.get_tree().process_frame
	check.call(GameState.friends_reunited() and bool(GameState.campaign().get("ending_seen")) and _hero_count(game.world) == 2, "the ending persists with both friends protecting BESUT")
	var archer: VillageHero
	for friend_node in game.world.get_children():
		if friend_node is VillageHero and friend_node.hero_id == "mei_ling": archer = friend_node
	archer.position = game.player().position + Vector2(0, 2)
	var archer_target := Enemy.new()
	archer_target.kind = "fire"
	archer_target.max_hp = 200
	archer_target.position = archer.position + Vector2(1.2, 0)
	game.world.add_child(archer_target)
	archer_target.set_physics_process(false)
	archer._physics_process(1.0)
	for bullet in game.world.get_children():
		if bullet is Arrow and bullet.source == archer:
			for step in 8:
				if not bullet._dead: bullet._physics_process(1.0 / 60.0)
	check.call(archer_target.hp < archer_target.max_hp, "rescued Mei Ling deals real ranged damage to village fire monsters")
	archer_target.queue_free()
	GameState.save_game()
	check.call(GameState.load_game() and GameState.friends_reunited(), "completed story survives a save reload")
	game.world._sync_rescued_friends()
	check.call(_hero_count(game.world) == 2, "reloading completed progress never duplicates village friends")
	GameState.data = snapshot
	GameState._emit_all()
	await game._load_lobby(false)
	game.hud.visible = true
	GameState.autosave_enabled = autosave
	for frame in 3: await game.get_tree().physics_frame
	game.set_process(ticking)

static func _hero_count(world: Node) -> int:
	var count := 0
	for node in world.get_children():
		if node is VillageHero: count += 1
	return count

static func _story(game: Game) -> StorySequence:
	for node in game.get_children():
		if node is StorySequence and not node.is_queued_for_deletion(): return node
	return null

static func _finish_story(game: Game) -> void:
	var story := _story(game)
	if story: story.finish()

static func _contains(node: Node, text: String) -> bool:
	if node is Label and node.text.contains(text): return true
	for child in node.get_children():
		if _contains(child, text): return true
	return false
