extends "res://tools/pb_test.gd"

var _shots := ""

func _ready() -> void:
	if not TestEnvironment.require_isolation():
		get_tree().quit(1)
		return
	_shots = OS.get_environment("TIDESWORN_TEST_ROOT").path_join("shots")
	DirAccess.make_dir_recursive_absolute(_shots)
	game = load("res://scenes/game.tscn").instantiate() as Game
	add_child(game)
	await get_tree().process_frame
	game._on_character_selected("qayyim")
	_check(game.loading_screen.active and game._transitioning, "New Journey shows a loading cover before world creation")
	await get_tree().create_timer(0.13).timeout
	await _shot("01_loading")
	await _settle()
	var lobby := game.world as Lobby
	_freeze(lobby)
	game.set_process(false)
	game.hud.tutorial_guide._skip()
	_check(not game.loading_screen.active and not game.player().controls_locked, "loading completes and restores movement")
	for role in ["water", "builder", "planter", "fighter"]:
		_check(GameState.worker_count(role) == 1, "level one starts with one %s" % role)
	var book_button: Button
	game.open_menu()
	await get_tree().create_timer(0.2).timeout
	book_button = _button(game.hud.menu_panel, "BESUT Field Guide")
	_check(book_button != null and _button(game.hud.menu_panel, "Build settlement") != null, "Menu provides the book and Build")
	await _activate(book_button)
	_check(game.hud.field_guide_panel.visible and game._input_locked, "touching Book opens an input-locked illustrated guide")
	var book := game.hud.field_guide_panel
	for category in 3:
		book._category = category
		for page in FieldGuideDB.entries(category).size():
			book._page = page
			book._rebuild()
			await get_tree().process_frame
			var pictures := book.content.get_children().filter(func(n: Node) -> bool: return n is GuideIllustration)
			_check(pictures.size() == 1 and pictures[0].entry.get("rows", []).size() == 2, "book category %d page %d explains its role in pictures" % [category, page + 1])
			if page == 0:
				await _shot("02_book_%d" % category)
	book.close_panel()
	_check(not game._input_locked, "closing Book restores input")
	GameState.add_diamonds(1000)
	GameState.add_gold(1000)
	for level in range(2, 6):
		var balance := GameState.diamonds()
		var cost := HouseDB.upgrade_cost(level - 1)
		_check(GameState.upgrade_house().ok and GameState.diamonds() == balance - cost, "village upgrade %d charges one house price" % level)
		_freeze(lobby)
		for role in ["water", "builder", "planter", "fighter"]:
			_check(GameState.worker_count(role) == level and lobby._residents.filter(func(n: Resident) -> bool: return n.worker_role == role).size() == level, "house level %d supplies %d %s workers" % [level, level, role])
		var linked := true
		for structure in get_tree().get_nodes_in_group("structures"):
			linked = linked and GameState.structure_level(structure.structure_id) == level
			if structure.structure_kind == "fence":
				for art in structure.get_parent().get_children():
					if art is Sprite2D:
						linked = linked and art.texture == PixelArt.fence_texture(level)
		_check(linked, "all house and fence tiers follow main house level %d" % level)
		for hut in get_tree().get_nodes_in_group("roof_guns"):
			hut._process(0)
		_check(get_tree().get_nodes_in_group("roof_guns").all(func(n: HouseDefense) -> bool: return n._level == level and n._art.texture == PixelArt.roof_gun_texture(level)), "all rooftop guns follow level %d" % level)
		lobby.camera.set_physics_process(false)
		lobby.camera.global_position = lobby._house_position + Vector2(2, 3)
		await _shot("03_village_level_%d" % level)
		game.open_house()
		await get_tree().create_timer(0.18).timeout
		game.hud.house_panel._select_preview(level)
		await _shot("04_preview_level_%d" % level)
		game.hud.house_panel.close_panel()
	var before := GameState.diamonds()
	_check(not GameState.upgrade_house().ok and GameState.diamonds() == before, "level five rejects another charge")
	_check(GameState.hire_worker("builder").ok and GameState.worker_count("builder") == 6, "shop still hires additional workers above the level baseline")
	GameState.save_game()
	_check(GameState.load_game() and GameState.house_level() == 5 and GameState.worker_count("builder") == 6, "linked village level and bought workers persist")
	_freeze(lobby)
	await game.enter_home()
	_check(is_instance_valid(game.home_interior) and not game.loading_screen.active and not game._transitioning, "home entry fades through loading and finishes inside")
	await _shot("05_home")
	game.leave_home()
	_check(game.loading_screen.active and game.player().controls_locked, "home exit locks input under the fade")
	await _settle()
	_check(not is_instance_valid(game.home_interior) and not game.player().controls_locked, "home exit restores village movement")
	if not GameState.is_night():
		GameState.advance_world_clock(180)
	_freeze(lobby)
	GameState.data.completed_missions = ["fire_kill"]
	GameState.data_changed.emit()
	game.hud.start_tutorial()
	await get_tree().create_timer(0.05).timeout
	_check(game.hud._root.get_node("TutorialSpotlight").dim_strength() == 0 and game.hud._root.get_node("TutorialSpotlight").visible, "night tutorial keeps the arrow without additional darkness")
	lobby._process(4)
	if DisplayServer.get_name() != "headless":
		await get_tree().create_timer(3.2).timeout
	await _shot("06_night_tutorial")
	game.open_portals()
	await get_tree().create_timer(0.2).timeout
	_check(game.hud.portal_panel.content.get_children().filter(func(n: Node) -> bool: return n.has_meta("portal_id")).size() == 1, "portal tutorial shows only the level one dungeon")
	await _shot("07_first_boss_tutorial")
	game.hud.portal_panel.close_panel()
	GameState.record_mission_event("portal")
	GameState.complete_portal("sunken_crypt")
	_check(GameState.mission_step() == 9, "another boss cannot complete the level one lesson")
	GameState.complete_portal("tidebound_grotto")
	_check(GameState.mission_step() == MissionDB.STEPS.size(), "first boss ends the nighttime tutorial")
	var names: Array[String] = []
	for id in PortalDB.ordered_ids():
		names.append(str(PortalDB.get_portal(id).get("boss_name", "")))
	_check(names.size() == 3 and names.all(func(n: String) -> bool: return n != "" and names.count(n) == 1), "every campaign boss has a distinct name")
	GameState.start_expedition("tidebound_grotto")
	game._load_dungeon("tidebound_grotto", true)
	_check(game.player().controls_locked and game.loading_screen.active, "portal travel locks input before fading out")
	await _settle()
	_check(game.world is Dungeon and not game.loading_screen.active, "portal destination fades in after loading")
	var dungeon := game.world as Dungeon
	for enemy in dungeon.get_children():
		if enemy is Enemy:
			enemy.set_physics_process(false)
	dungeon.boss.get_node("BossHealth")._process(0)
	_check(dungeon.boss.get_node("BossHealth")._boss_title.text == names[0], "boss name is shown over its health bar")
	await get_tree().process_frame
	var boss_vitals := dungeon.boss.get_node("BossHealth")
	_check(not boss_vitals._boss_title.get_global_rect().intersects(boss_vitals._label.get_global_rect()), "boss name and HP text have separate readable space")
	dungeon.camera.set_physics_process(false)
	dungeon.camera.global_position = dungeon.boss.global_position + Vector2(0, 3)
	await _shot("09_named_boss")
	for dimensions in [Vector2i(1280, 720), Vector2i(832, 480)]:
		if DisplayServer.get_name() != "headless":
			get_window().content_scale_size = dimensions
			get_window().size = dimensions
			await get_tree().create_timer(0.18).timeout
		game.open_field_guide()
		await get_tree().create_timer(0.2).timeout
		book._category = 0
		book._page = 0
		book._rebuild()
		await get_tree().process_frame
		_check(not book.body.get_h_scroll_bar().visible, "book fits width at %dx%d" % [dimensions.x, dimensions.y])
		book.body.scroll_vertical = 9999
		await get_tree().process_frame
		var next := _button(book, "›")
		await _activate(next)
		_check(book._page == 1, "touch turns a book page at %dx%d" % [dimensions.x, dimensions.y])
		await _shot("08_book_%dx%d" % [dimensions.x, dimensions.y])
		await _activate(book._close_button)
		_check(not book.visible and not game._input_locked, "book Close works at %dx%d" % [dimensions.x, dimensions.y])
	await game.return_to_title()
	_check(game.title_screen != null and not game.loading_screen.active, "return to title finishes its fade")
	GameState.new_game("qayyim")
	GameState.data.completed_missions = MissionDB.DAY_STEPS.map(func(index: int) -> String: return str(MissionDB.step(index).get("event", "")))
	GameState.save_game()
	await game._on_continue_requested()
	lobby = game.world as Lobby
	_freeze(lobby)
	_check(not game.hud.tutorial_guide.visible and game.hud.tutorial_guide._tips_enabled, "Continue remembers unfinished night lessons after day lessons finish")
	GameState.advance_world_clock(180)
	_freeze(lobby)
	await get_tree().create_timer(0.05).timeout
	_check(game.hud.tutorial_guide.visible and GameState.mission_step() == 4, "Continue resumes night teaching when night arrives")
	print("--- PB test: %d checks, %s ---" % [checks, "PASS" if failures == 0 else "FAIL"])
	get_tree().quit(0 if failures == 0 else 1)

func _settle() -> void:
	while game._transitioning:
		await get_tree().process_frame

func _shot(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_shots.path_join(label + ".png"))

func _button(node: Node, caption: String) -> Button:
	if node is Button and node.text == caption:
		return node
	for child in node.get_children():
		var found := _button(child, caption)
		if found:
			return found
	return null

func _touch(point: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.position = point
		event.pressed = pressed
		event.index = 8
		Input.parse_input_event(event)
		await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout


func _activate(button: Button) -> void:
	if DisplayServer.get_name() == "headless":
		button.pressed.emit()
		await get_tree().create_timer(0.2).timeout
	else:
		await _touch(button.get_global_rect().get_center())
