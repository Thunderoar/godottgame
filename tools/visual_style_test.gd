extends Node
## Isolated restart/persistence test and paired native-renderer art review.
var checks := 0
var failures := 0

func _ready() -> void:
	if not TestEnvironment.require_isolation():
		get_tree().quit(1)
		return
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--select-style="):
			GameSettings.set_visual_style(argument.trim_prefix("--select-style="))
			print("STYLE_SELECTED=", GameSettings.visual_style(), "; ACTIVE=", GameSettings.active_visual_style())
			get_tree().quit()
			return
	GameState.autosave_enabled = false
	GameState.new_game("adam")
	GameState.data.mission_step = MissionDB.STEPS.size()
	var game := load("res://scenes/game.tscn").instantiate() as Game
	add_child(game)
	await get_tree().process_frame
	game.set_process(false)
	var style := GameSettings.active_visual_style()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--expect-style="):
			_check(style == argument.trim_prefix("--expect-style="), "saved style is active after a real process restart")
	game.title_screen._open_settings()
	await get_tree().process_frame
	_check(game.title_screen.find_child("VisualStyleOption", true, false) is OptionButton, "title Settings exposes art style before starting a journey")
	await _capture("title-settings")
	game._remove_title()
	await game._load_lobby(false)
	game.world.set_process(false)
	game.player().set_physics_process(false)
	game.hud.tutorial_guide.hide()
	await preload("res://tools/visual_style_checks.gd").run(game, _check)
	var home := game.world as Lobby
	_check((home.background.material == null) == VisualStyle.is_pixel(), "village uses pixel terrain or modern surface shader")
	home.camera.set_physics_process(false)
	home.camera.position = Vector2(34, 23)
	home.camera.zoom = Vector2.ONE * 48
	await _capture("village")
	game.open_settings()
	await get_tree().process_frame
	_check(game.hud.settings_panel.find_child("VisualStyleOption", true, false) is OptionButton, "in-game Settings exposes the same art styles")
	await _capture("game-settings")
	game.hud.settings_panel.close_panel()
	var interior := HomeInterior.new()
	home.add_child(interior)
	_check((interior._floor_texture == null) == VisualStyle.is_pixel(), "home floor uses original pixels or modern wood")
	interior.queue_free()
	GameState.data.level = 99
	GameState.data.portals.tidebound_grotto.unlocked = true
	GameState.start_expedition("tidebound_grotto")
	await game._load_dungeon("tidebound_grotto", false)
	var dungeon := game.world as Dungeon
	dungeon.set_process(false)
	dungeon.camera.set_physics_process(false)
	dungeon.camera.position = Vector2(24, 16)
	dungeon.camera.zoom = Vector2.ONE * 30
	_check((dungeon.get_node_or_null("RealmStoneFloor") == null) == VisualStyle.is_pixel(), "portal floor selects procedural pixels or illustrated stone")
	await _capture("portal")
	game._clear_world()
	var ocean := OceanJourney.new()
	game.world = ocean
	game._world_holder.add_child(ocean)
	game.hud.set_world(ocean)
	game.hud.hide()
	ocean.set_process(false)
	_check(is_instance_valid(ocean._realistic_background) == not VisualStyle.is_pixel(), "ocean selects procedural water or modern seabed")
	ocean.dismiss_sea_guide()
	ocean.turtle.position = OceanJourney.TURTLE_AT
	ocean.player.position = ocean.turtle.position + Vector2(-0.55, -1.0)
	await _capture("ocean")
	ocean._ocean_settings.open_settings()
	await get_tree().process_frame
	_check(ocean._ocean_settings.find_child("VisualStyleOption", true, false) is OptionButton, "ocean Settings exposes art style")
	await _capture("ocean-settings")
	game._clear_world()
	var island := KrakenIsland.new()
	game.world = island
	game._world_holder.add_child(island)
	island.set_process(false)
	island.player.set_physics_process(false)
	island.boss.set_physics_process(false)
	_check((island.get_node_or_null("KrakenStoneFloor") == null) == VisualStyle.is_pixel(), "Kraken arena selects pixel or modern stone floor")
	_check(island.get_children().filter(func(node: Node) -> bool: return node.get_child_count() == 2 and node.get_child(0) is Sprite2D and node.get_child(1) is StaticBody2D).size() == 4, "all four Kraken pillars retain art and collision in either style")
	await _capture("kraken")
	print("--- visual style: %d checks, %s; active=%s ---" % [checks, "PASS" if failures == 0 else "FAIL", style])
	Sfx.stop_battle_music()
	Sfx._music.stream = null
	for player in Sfx._players:
		player.stop()
		player.stream = null
	Sfx._music_cache.clear()
	game.queue_free()
	await get_tree().create_timer(0.15).timeout
	get_tree().quit(0 if failures == 0 else 1)

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("[OK] " if ok else "[FAIL] ", message)

func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	# Wait for modal entry fades, not just their first translucent frame.
	await get_tree().create_timer(0.35).timeout
	for frame in 3: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var folder := OS.get_environment("TIDESWORN_STYLE_OUTPUT")
	if folder.is_empty(): folder = OS.get_environment("TIDESWORN_TEST_ROOT")
	DirAccess.make_dir_recursive_absolute(folder)
	var path := folder.path_join(GameSettings.active_visual_style() + "-" + label + ".png")
	_check(get_viewport().get_texture().get_image().save_png(path) == OK, "rendered " + path.get_file())
