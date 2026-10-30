extends RefCounted
## Two sea levels, hazard progression, real onward travel and legacy checkpoint migration.

static func run(game: Game, check: Callable, capture: Callable = Callable()) -> void:
	var saved := GameState.data.duplicate(true)
	var autosave := GameState.autosave_enabled
	var ticking := game.is_processing()
	game.set_process(false)
	game.hud.hide_modals()
	GameState.autosave_enabled = false
	game._clear_world()
	await game.get_tree().process_frame
	GameState.data = GameState._make_default("adam")
	GameState.data.campaign.ocean_stage = 3
	GameState.data.campaign.arjun_rescued = true
	GameState.data.gold = 777
	var pets: Dictionary = GameState.data.pets.duplicate(true)
	GameState.save_game()
	check.call(GameState.load_game() and int(GameState.campaign().ocean_stage) == 2, "an actual old level-three JSON checkpoint safely resumes at the new final sea level")
	check.call(GameState.gold() == 777 and bool(GameState.campaign().arjun_rescued) and JSON.parse_string(JSON.stringify(GameState.data.pets)) == JSON.parse_string(JSON.stringify(pets)), "two-level migration preserves earned currency, pets and rescued friends")
	GameState.data = GameState._make_default("adam")
	GameState.data.portal_origin.opened = true
	GameState.data.campaign.intro_seen = true
	GameState.data.campaign.dock_welcome_seen = true
	GameState._emit_all()
	var ocean := OceanJourney.new()
	game.world = ocean
	game._world_holder.add_child(ocean)
	game.hud.set_world(ocean)
	game.hud.visible = false
	ocean.set_process(false)
	ocean._process(4)
	check.call(GameState.OCEAN_STAGES == 2 and ocean.stage == 1, "new ocean journeys contain exactly two levels and begin at level one")
	check.call(ocean._sea_guide.visible and _contains(ocean._sea_guide,"Level 2 adds sharks"), "Sea Guide explains the first-level objects and second-level shark introduction")
	if capture.is_valid(): await capture.call("ocean_01_guide")
	ocean.dismiss_sea_guide()
	check.call(ocean.spawn_item("shark",25).is_empty() and not ocean.sharks_enabled(), "level one rejects shark creation even through the shared spawn entry point")
	check.call(ocean.scenery.life.all(func(actor: Dictionary) -> bool: return str(actor.kind) not in ["shark","megalodon"] or not actor.sprite.visible), "level one contains no visible shark or megalodon background silhouettes")
	var first_catalog := _sample_spawns(ocean)
	check.call(["trash","food","heart","bomb"].all(func(kind: String) -> bool: return kind in first_catalog) and not first_catalog.has("shark"), "real level-one spawn updates supply rubbish, fish, hearts and bombs without sharks")
	check.call(ocean._shark_clock == 0, "level one's disabled shark timer cannot accumulate an overdue encounter")
	_clear(ocean)
	ocean.elapsed = OceanJourney.STAGE_SECONDS*0.5
	ocean._refresh_ui()
	check.call(is_equal_approx(ocean._progress.progress,0.25) and ocean._score.text.contains("1/2") and not ocean.swim_instruction().contains("sharks"), "first-level HUD and portrait progress use two levels and the correct active hazard hint")
	if capture.is_valid():
		_picture_items(ocean)
		await capture.call("ocean_02_level_one")
	_clear(ocean)
	ocean.health = 3
	ocean.fullness = 100
	ocean.elapsed = OceanJourney.STAGE_SECONDS
	ocean._complete_stage()
	check.call(ocean.phase == OceanJourney.Phase.TRAVELLING and int(GameState.campaign().ocean_stage) == 2, "clearing level one saves level two before its automatic travel animation")
	GameState.save_game()
	check.call(GameState.load_game() and int(GameState.campaign().ocean_stage) == 2, "the new final-level checkpoint survives a JSON reload during travel")
	ocean._advance_route_exit(OceanJourney.ROUTE_EXIT_SECONDS)
	check.call(ocean.stage == 2 and ocean.phase == OceanJourney.Phase.ARRIVING and ocean.health == 3 and ocean.fullness == 100 and is_equal_approx(ocean._progress.progress,0.5), "level two arrives with reset lives/fullness at the halfway checkpoint")
	check.call(ocean.scenery.life.any(func(actor: Dictionary) -> bool: return str(actor.kind) == "megalodon" and actor.sprite.visible), "the existing megalodon background appears only after entering level two")
	ocean._advance_route_entry(OceanJourney.ROUTE_ENTRY_SECONDS)
	check.call(ocean.phase == OceanJourney.Phase.RUNNING and ocean._status.text.contains("bombs and sharks"), "second-level play resumes with an explicit shark hazard hint")
	ocean._hurt_time = 1000
	ocean._spawn_clock = 1000
	ocean._heart_clock = 1000
	ocean._bomb_clock = 1000
	ocean._update_run(6.9)
	check.call(not ocean.items.any(func(item: Dictionary) -> bool: return item.kind == "shark"), "the first second-level shark waits for its normal seven-second approach")
	ocean._update_run(0.2)
	check.call(ocean.items.any(func(item: Dictionary) -> bool: return item.kind == "shark"), "the second level automatically spawns sharks after the approach delay")
	var second_catalog := _sample_spawns(ocean)
	check.call(["trash","food","heart","bomb","shark"].all(func(kind: String) -> bool: return kind in second_catalog), "level two keeps all four original objects and adds sharks")
	_clear(ocean)
	ocean.elapsed = OceanJourney.STAGE_SECONDS*0.5
	ocean._refresh_ui()
	check.call(is_equal_approx(ocean._progress.progress,0.75) and ocean._score.text.contains("2/2") and GameState.campaign_objective().contains("2/2"), "second-level HUD and campaign objective agree with the two-level progression")
	if capture.is_valid():
		_picture_items(ocean)
		ocean.spawn_item("shark",35)
		await capture.call("ocean_03_level_two")
	_clear(ocean)
	ocean._end_run("Retry fixture")
	ocean.restart()
	check.call(ocean.stage == 2 and ocean.health == 3 and ocean.fullness == 100 and ocean._shark_clock == 7, "retry keeps the final-level checkpoint while resetting health, fullness and shark timing")
	ocean._process(4)
	ocean.dismiss_sea_guide()
	ocean.elapsed = OceanJourney.STAGE_SECONDS
	ocean._complete_stage()
	check.call(ocean.stage == 2 and ocean.phase == OceanJourney.Phase.TRAVELLING and int(GameState.campaign().ocean_stage) == 2, "completing the second level cannot create or unlock a third sea level")
	ocean._advance_route_exit(OceanJourney.ROUTE_EXIT_SECONDS)
	for frame in 180:
		if game.world is KrakenIsland and not game._transitioning: break
		await game.get_tree().create_timer(0.025).timeout
	check.call(game.world is KrakenIsland and not game._transitioning, "the second level carries Adam directly into the actual Kraken Island world")
	if game.world is KrakenIsland:
		check.call(not game.world.cage.available and not bool(GameState.campaign().arjun_rescued), "two sea levels still require the Kraken fight and separate prison rescue")
		if capture.is_valid(): await capture.call("ocean_04_kraken_arrival")
		await preload("res://tools/kraken_crab_checks.gd").run(game,check,capture)
		await preload("res://tools/sea_journey_completion_checks.gd").run(game,check,capture)
	GameState.data = saved
	GameState._emit_all()
	await game._load_lobby(false)
	GameState.autosave_enabled = autosave
	game.set_process(ticking)

static func _sample_spawns(ocean: OceanJourney) -> Array[String]:
	var catalog: Array[String] = []
	ocean._rng.seed = 41473
	for tick in 24:
		ocean.health = 3
		ocean.fullness = 100
		ocean._hurt_time = 1000
		ocean._spawn_clock = 0
		ocean._heart_clock = 0
		ocean._bomb_clock = 0
		ocean._shark_clock = 0
		ocean._update_run(0.1)
		for item in ocean.items:
			if str(item.kind) not in catalog: catalog.append(str(item.kind))
		_clear(ocean)
	return catalog

static func _clear(ocean: OceanJourney) -> void:
	for item in ocean.items.duplicate(): ocean._resolve_item(item,false)

static func _picture_items(ocean: OceanJourney) -> void:
	ocean.spawn_item("food",20)
	ocean.spawn_item("trash",24)
	ocean.spawn_item("heart",28)
	ocean.spawn_item("bomb",31)

static func _contains(node: Node, text: String) -> bool:
	if node is Label and text in node.text: return true
	for child in node.get_children():
		if _contains(child,text): return true
	return false
