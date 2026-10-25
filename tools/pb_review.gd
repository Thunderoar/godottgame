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
	await _shot("01_pb_title")
	await game._on_character_selected("qayyim")
	await get_tree().create_timer(0.3).timeout
	game.hud.tutorial_guide._skip()
	var lobby := game.world as Lobby
	_freeze(lobby)
	lobby.camera.set_physics_process(false)
	lobby.camera.global_position = Vector2(34, 24)
	for role in ["builder", "water", "planter", "fighter"]:
		var npc := _worker(lobby, role)
		npc.global_position = Vector2(29 + ["builder", "water", "planter", "fighter"].find(role) * 2, 26)
	await _shot("02_colored_specialists")
	lobby.camera.global_position = Vector2(34, 7.2)
	lobby.camera.zoom = Vector2.ONE * 50
	await _shot("03_northern_portals")
	var portal: PortalEntrance
	for node in get_tree().get_nodes_in_group("battle_portal"):
		if node.gate_kind == "monster":
			portal = node
	await _click(lobby.get_global_transform_with_canvas() * (portal.global_position + Vector2(0, -1.0)), true)
	_check(game.hud.portal_panel.visible, "touching northern portal directly opens monster levels")
	await _shot("04_portal_touch")
	game.hud.portal_panel.close_panel()
	lobby.camera.global_position = lobby._house_position
	var hp := GameState.health()
	GameState.set_health(10)
	await _click(lobby.get_global_transform_with_canvas() * (lobby._house_position + Vector2(0, -2.0)), true)
	_check(is_instance_valid(game.home_interior), "touching main house enters its interior")
	await get_tree().create_timer(0.6).timeout
	_check(GameState.health() > 10, "interior automatically heals player")
	await _shot("05_home_interior")
	var exit := game.home_interior._exit
	await _click(exit.get_global_transform_with_canvas().origin, true)
	_check(not is_instance_valid(game.home_interior), "touching doorway exits home")
	lobby.camera.set_physics_process(false)
	lobby.camera.global_position = Vector2(31, 25)
	var mission := get_tree().get_first_node_in_group("mission_npc") as MissionNPC
	await _click(mission.get_global_transform_with_canvas().origin + Vector2(0, -25), true)
	_check(game.hud.mission_panel.visible, "touching purple question-mark NPC opens missions")
	await _shot("06_mission_guide")
	game.hud.mission_panel.close_panel()
	game.open_village_services()
	await get_tree().create_timer(0.2).timeout
	await _shot("07_worker_shop")
	game.hud.village_services_panel.close_panel()
	for target in get_tree().get_nodes_in_group("structures"):
		if not target.is_intact():
			GameState.repair_structure(target.structure_id)
	var house: SettlementTarget
	for target in get_tree().get_nodes_in_group("structures"):
		if target.structure_id == "cottage":
			house = target
	house.take_attack_damage(9999)
	var builder := _worker(lobby, "builder")
	builder._release_build_task()
	builder.global_position = house.shelter_position() + Vector2(-2, 1.0)
	builder.set_physics_process(true)
	var elapsed := 0.0
	while float(GameState.structure_state("cottage").get("repair_remaining", 0)) <= 0 and elapsed < 12:
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()
	_check(float(GameState.structure_state("cottage").get("repair_remaining", 0)) > 0, "orange builder walks to ruined house and starts work")
	await get_tree().create_timer(2.0).timeout
	_check(not house.is_intact(), "real-time repair is not instant")
	await _shot("08_builder_working")
	await get_tree().create_timer(8.5).timeout
	_check(house.is_intact(), "real-time builder repair finishes after ten seconds")
	await _shot("09_rebuilt_home")
	builder.set_physics_process(false)
	GameState.add_diamonds(1000)
	game.open_house()
	await get_tree().create_timer(0.2).timeout
	game.hud.house_panel._select_preview(5)
	await _shot("10_house_level_5_preview")
	game.hud.house_panel.close_panel()
	GameState.add_gold(100000)
	for i in 4:
		GameState.upgrade_pet("ember")
	for id in PetBattleDB.ordered_ids():
		game.open_pet_battles()
		await get_tree().create_timer(0.1).timeout
		var panel := game.hud.pet_battle_panel
		_check(panel.start_battle(id), "%s starts with supplied backdrop" % id)
		await get_tree().create_timer(0.3).timeout
		await _shot("11_" + id + "_background")
		if id == "pet_duel_1":
			var before := panel._opponent_hp
			await get_tree().create_timer(2.5).timeout
			_check(panel._opponent_hp == before, "pet battle still waits for a chosen action")
		panel._finish_battle(true)
		panel.close_panel()
	GameState.set_health(GameState.health_max())
	GameState.start_expedition("tidebound_grotto")
	game._load_dungeon("tidebound_grotto", false)
	await get_tree().process_frame
	await get_tree().process_frame
	var dungeon := game.world as Dungeon
	for child in dungeon.get_children():
		if child is Enemy:
			child.set_physics_process(false)
	dungeon.player.global_position = dungeon.boss.global_position + Vector2(2, 2)
	dungeon.pet.global_position = dungeon.player.global_position + Vector2(-1, 0)
	dungeon.pet.set_physics_process(false)
	dungeon.camera.set_physics_process(false)
	dungeon.camera.global_position = dungeon.boss.global_position + Vector2(0, 3)
	await _shot("12_boss_and_pet_health")
	print("PB review: %s" % ("PASS" if failures == 0 else "FAIL"))
	get_tree().quit(0 if failures == 0 else 1)

func _click(point: Vector2, touch: bool = false) -> void:
	for pressed in [true, false]:
		if touch:
			var event := InputEventScreenTouch.new()
			event.position = point
			event.pressed = pressed
			event.index = 9
			Input.parse_input_event(event)
		else:
			var event := InputEventMouseButton.new()
			event.position = point
			event.pressed = pressed
			event.button_index = MOUSE_BUTTON_LEFT
			Input.parse_input_event(event)
		await get_tree().process_frame
	await get_tree().create_timer(0.15).timeout
	while game._transitioning:
		await get_tree().process_frame

func _shot(label: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_shots.path_join(label + ".png"))
