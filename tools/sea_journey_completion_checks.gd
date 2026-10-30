extends RefCounted

static func run(game: Game, check: Callable, capture: Callable = Callable()) -> void:
	var island := game.world as KrakenIsland
	check.call(island.defeated and GameState.sea_journey_available(), "defeating the Kraken alone does not close the unfinished Arjun rescue journey")
	island.player.position = island.cage.position
	island.cage.interact(island.player)
	await game.get_tree().process_frame
	check.call(not GameState.sea_journey_available() and bool(GameState.campaign().arjun_rescued) and game._active_story != null, "freeing Arjun closes sea access immediately while his rescue story still plays")
	if game._active_story != null: game._active_story.finish()
	for frame in 180:
		if game.world is Lobby and not game._transitioning: break
		await game.get_tree().create_timer(0.025).timeout
	check.call(game.world is Lobby and game._sailing, "closing sea access still permits the actual incoming rescue ship")
	if not game.world is Lobby: return
	var home := game.world as Lobby
	var boarding := home.ship_boarding
	check.call(boarding.returning and not boarding.available and boarding.ship.get_node_or_null("ArjunPassenger") != null, "Arjun remains aboard the returning ship while future departures are disabled")
	boarding.ship.position = boarding._moored_position
	boarding._physics_process(0)
	home.player.global_position = boarding.global_position
	boarding._physics_process(0.01)
	if game._arjun_walk != null and game._arjun_walk.is_valid():
		game._arjun_walk.pause()
		game._arjun_walk.custom_step(300)
	await game.get_tree().process_frame
	check.call(boarding.landed and not game._sailing and not game._arjun_returning and not boarding.available and home.player.collision_mask == boarding._passenger_mask and not home.player.controls_locked and game.hud.visible and home.pet.visible, "rescue disembarkation restores normal village controls, collision and pet while leaving the ship closed")
	var actor := home.player
	actor.set_physics_process(false)
	var start := actor.global_position
	var ship_at := boarding.ship.position
	check.call(not game.board_ship(boarding) and not game.board_ship(boarding,true) and not boarding.begin(actor), "nearby, direct-tap and low-level boarding APIs all reject the completed sea journey")
	actor.nearby = boarding # A cached E target must not bypass disabled availability.
	actor.try_interact()
	check.call(not game._sailing and not boarding.departing and actor.global_position == start and boarding.ship.position == ship_at and not game._input_locked, "a stale nearby interaction cannot move Adam onto the completed journey's ship")
	# Exercise actual pointer input against the hull, including a stale availability flag.
	home.camera.set_process(false)
	home.camera.set_physics_process(false)
	home.camera.global_position = boarding.position + Vector2(-2,-2)
	home.camera.force_update_scroll()
	home.camera.reset_physics_interpolation()
	await game.get_tree().process_frame
	await game.get_tree().physics_frame
	var point := game.get_viewport().get_final_transform() * (boarding.ship.get_global_transform_with_canvas() * (boarding.ship.get_rect().get_center() + Vector2(15,15)))
	boarding.available = true
	for touch in [false,true]:
		var press: InputEvent = InputEventScreenTouch.new() if touch else InputEventMouseButton.new()
		press.position = point
		press.pressed = true
		if press is InputEventScreenTouch: press.index = 27
		else: press.button_index = MOUSE_BUTTON_LEFT
		Input.parse_input_event(press)
		await game.get_tree().process_frame
		var release := press.duplicate()
		release.pressed = false
		Input.parse_input_event(release)
		await game.get_tree().process_frame
		check.call(game.world == home and not game._sailing and not boarding.departing and not actor.controls_locked, "%s on the completed journey's hull cannot bypass the campaign boarding guard" % ("touch" if touch else "mouse click"))
	boarding._refresh_availability()
	# A stale departure callback is also denied before any world/UI mutation.
	game._sailing = true
	boarding.arrived = true
	game.enter_ocean(boarding)
	check.call(game.world == home and not game._transitioning, "a delayed departure callback cannot reopen the ocean after Arjun's rescue")
	game._sailing = false
	boarding.arrived = false
	var checkpoint := int(GameState.campaign().ocean_stage)
	GameState.data.campaign.ocean_stage = 1 # Old completed saves may retain an earlier checkpoint.
	check.call(not GameState.advance_ocean_stage(1) and int(GameState.campaign().ocean_stage) == 1, "a closed sea journey cannot advance an older checkpoint through a delayed callback")
	GameState.data.campaign.ocean_stage = checkpoint
	if capture.is_valid(): await capture.call("ocean_06_completed_ship")
	GameState.save_game()
	check.call(GameState.load_game() and not GameState.sea_journey_available(), "the sea lock survives actual save/load using Arjun's existing rescue flag")
	await game._load_lobby(false)
	check.call(not game.world.ship_boarding.available and not game.board_ship(game.world.ship_boarding,true), "a rebuilt village keeps completed saves unable to board the ship")
	# Check the lower transition gate even if an outdated ocean actor survives.
	game._clear_world()
	var old_ocean := OceanJourney.new()
	game.world = old_ocean
	game._world_holder.add_child(old_ocean)
	old_ocean.set_process(false)
	game.enter_kraken_island()
	check.call(game.world == old_ocean and not game._transitioning, "an outdated ocean actor cannot start another Kraken visit after the rescue")
	game._clear_world()
	GameState.data = GameState._make_default("adam")
	GameState.data.portal_origin.opened = true
	GameState._emit_all()
	await game._load_lobby(false)
	check.call(GameState.sea_journey_available() and game.world.ship_boarding.available, "fresh-journey defaults restore the ship for a new Arjun rescue")
	GameState.rescue_friend("mei_ling")
	check.call(GameState.sea_journey_available() and game.world.ship_boarding.available, "rescuing Mei Ling alone never closes Arjun's unfinished sea journey")
