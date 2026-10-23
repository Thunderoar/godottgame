extends Node
## Native rendering plus free repairs and shelter-loss behaviour.

var _shots := ""


func _ready() -> void:
	if not TestEnvironment.require_isolation():
		get_tree().quit(1)
		return
	_shots = OS.get_environment("TIDESWORN_TEST_ROOT").path_join("shots")
	DirAccess.make_dir_recursive_absolute(_shots)
	var game := load("res://scenes/game.tscn").instantiate() as Game
	add_child(game)
	await get_tree().process_frame
	game._on_character_selected("qayyim")
	await get_tree().create_timer(0.8).timeout
	var lobby := game.world as Lobby
	for enemy in lobby._forest_monsters:
		enemy.set_physics_process(false)
	for resident in lobby._residents:
		resident.set_physics_process(false)
	lobby._rubbish_system.set_process(false)
	await _shot("01_first_mission_path")
	game.hud.tutorial_guide._skip()
	lobby.camera.set_physics_process(false)
	lobby.camera.global_position = Vector2(30, 23)
	lobby.camera.zoom = Vector2.ONE * 39
	await _shot("02_named_shops")
	game.open_village_services()
	await _shot("03_water_keeper_shop")
	game.hud.village_services_panel.close_panel()
	var house: SettlementTarget
	for node in get_tree().get_nodes_in_group("structures"):
		if node.structure_id == "cottage":
			house = node
	GameState.add_gold(1000)
	house.take_attack_damage(9999)
	game.player().global_position = house.shelter_position() + Vector2(0, 0.6)
	game.player()._update_nearby()
	await _shot("04_free_repair_prompt")
	var result := GameState.repair_structure(house.structure_id)
	if not bool(result.get("ok", false)) or not house.is_intact():
		push_error("Free repair failed.")
		get_tree().quit(1)
		return
	await _shot("06_repaired_house")
	var elapsed := 0.0
	# Ensure the stationary approach band can actually enter a windup.
	var villager := lobby._residents[0]
	villager.global_position = house.shelter_position() + Vector2(-1.0, 1.0)
	villager._shelter_house = house
	villager.set_physics_process(true)
	var urchin := Enemy.new()
	urchin.kind = "urchin"
	urchin.damage = 180
	urchin.attack_interval = 0.4
	urchin.position = house.shelter_position() + Vector2(0, 1.0)
	lobby.add_child(urchin)
	urchin.set_physics_process(false)
	elapsed = 0.0
	while not villager.sheltered and elapsed < 8.0:
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()
	if not villager.sheltered:
		push_error("Villager failed to enter the intact shelter.")
		get_tree().quit(1)
		return
	await get_tree().create_timer(0.6).timeout
	await _shot("07_village_shelter")
	for node in get_tree().get_nodes_in_group("structures"):
		if node != house and node.structure_kind == "house":
			node.take_attack_damage(9999)
	urchin.set_physics_process(true)
	elapsed = 0.0
	while not villager.dead and elapsed < 12.0:
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()
	if house.is_intact() or not villager.dead:
		print("review diagnostic: target=", urchin._target, " state=", urchin._state, " house=", GameState.structure_state(house.structure_id), " resident=", villager.global_position, " urchin=", urchin.global_position)
		push_error("Sea urchin did not destroy the shelter and defeat the exposed resident.")
		get_tree().quit(1)
		return
	await _shot("08_destroyed_shelter")
	print("village review: PASS")
	get_tree().quit()


func _shot(label: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var path := _shots.path_join(label + ".png")
	if get_viewport().get_texture().get_image().save_png(path) != OK:
		push_error("Village screenshot could not be saved: " + path)
	print("village screenshot: ", path)
