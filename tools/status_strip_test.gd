extends Node
var checks := 0
var failures := 0

func _ready() -> void:
	if not TestEnvironment.require_isolation(): get_tree().quit(1); return
	GameState.autosave_enabled = false
	GameState.new_game("adam")
	var game := load("res://scenes/game.tscn").instantiate() as Game
	add_child(game)
	game._remove_title()
	await StatusStripChecks.run(game, _check)
	if DisplayServer.get_name() != "headless":
		GameState.data = GameState._make_default("adam")
		GameState._emit_all()
		await game._load_lobby(false, true)
		game.set_process(false)
		var lobby := game.world as Lobby
		lobby.process_mode = Node.PROCESS_MODE_DISABLED
		game.hud.start_tutorial()
		var strip := game.hud._status_strip
		for dimensions in [Vector2i(1280, 720), Vector2i(832, 480), Vector2i(640, 360), Vector2i(480, 320)]:
			get_window().size = dimensions
			for gui in [0.75, 1.0, 1.3]:
				game.hud.set_gui_scale(gui, false)
				strip.refresh_world(lobby)
				for i in 4: await get_tree().process_frame
				_check_layout(game, "%s GUI %.2f" % [dimensions, gui])
				await _capture("day_%dx%d_gui_%d" % [dimensions.x, dimensions.y, roundi(gui * 100)])
			game.hud.set_gui_scale(1.0, false)
		# A real threat snapshot exercises loss, fire and shelter information together.
		GameState.advance_world_clock(GameState.DAY_PHASE_SECONDS)
		GameState.damage_resident(lobby._residents[0].resident_name, 1000)
		lobby._forest_trees[0].take_attack_damage(1)
		GameState.damage_structure("cottage", 99999)
		strip.refresh_world(lobby)
		game.hud._on_emergency_changed(true, 3, 0)
		for dimensions in [Vector2i(1280, 720), Vector2i(832, 480), Vector2i(640, 360), Vector2i(480, 320)]:
			get_window().size = dimensions
			for i in 4: await get_tree().process_frame
			_check_layout(game, "threats %s" % dimensions)
			await _capture("threats_%dx%d" % [dimensions.x, dimensions.y])
		_check(strip.counts.monsters >= 24 and strip.counts.fires == 1 and strip.counts.npc_alive < strip.counts.npc_total, "threat strip reports live monsters, fire and NPC loss together")
		GameState.data.gold = 1234567890
		GameState.data.diamonds = 999999
		game.hud.refresh_all()
		for i in 3: await get_tree().process_frame
		_check_layout(game, "large balances")
		await _capture("large_balances")
		game.hud.set_control_layout("menu", 22, 18, 64)
		for i in 4: await get_tree().process_frame
		_check_layout(game, "custom Menu at top left")
		await _capture("custom_menu")
		game.hud.reset_control_layout()
		await game._load_dungeon(PortalDB.ordered_ids()[0], false)
		game.world.process_mode = Node.PROCESS_MODE_DISABLED
		for i in 3: await get_tree().process_frame
		await _capture("dungeon_count")
	print("--- status strip: %d checks, %s ---" % [checks, "PASS" if failures == 0 else "FAIL"])
	get_tree().quit(0 if failures == 0 else 1)

func _check_layout(game: Game, label: String) -> void:
	var strip := game.hud._status_strip
	var bounds := game.hud._root.get_global_rect()
	var boxes: Array[Rect2] = []
	var fit := true
	var separated := true
	for chip in strip._chips.values():
		if not chip.visible: continue
		var rect: Rect2 = chip.get_global_rect()
		fit = fit and bounds.encloses(rect)
		for other in boxes: separated = separated and not rect.intersects(other)
		boxes.append(rect)
		separated = separated and not rect.intersects(game.hud._menu_button.get_global_rect()) and not rect.intersects(game.hud._map_button.get_global_rect())
		if game.hud._emergency_panel.visible: separated = separated and not rect.intersects(game.hud._emergency_panel.get_global_rect())
	_check(fit and separated, "status chips fit without overlapping each other, edge controls or emergency banner: " + label)
	var display := minf(float(get_window().size.x) / bounds.size.x, float(get_window().size.y) / bounds.size.y)
	_check(HudStatusStrip.FONT_SIZE * strip.scale.x * display >= 11.99, "status text remains at least twelve physical pixels: " + label)
	var gold: Control = strip._chips.gold
	var diamonds: Control = strip._chips.diamond
	_check(gold.custom_minimum_size.x + diamonds.custom_minimum_size.x < 344 and HudStatusStrip.HEIGHT < 48, "currency boxes are narrower and shorter than the former panel: " + label)

func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	var directory := OS.get_environment("TIDESWORN_TEST_ROOT").path_join("shots")
	DirAccess.make_dir_recursive_absolute(directory)
	var path := directory.path_join(label + ".png")
	_check(get_viewport().get_texture().get_image().save_png(path) == OK, "capture " + label)
	print("CAPTURE ", path)

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("[OK] " if ok else "[FAIL] ", label)
