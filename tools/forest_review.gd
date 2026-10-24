extends Node
## Rendered forest lifecycle and real NPC approach in verified temporary data.

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
	await game._on_character_selected("qayyim")
	await get_tree().create_timer(0.5).timeout
	game.hud.tutorial_guide._skip()
	GameState.advance_world_clock(GameState.DAY_PHASE_SECONDS)
	var lobby := game.world as Lobby
	for enemy in lobby._forest_monsters:
		enemy.set_physics_process(false)
	for resident in lobby._residents:
		resident.set_physics_process(false)
	lobby._rubbish_system.set_process(false)
	var tree := lobby._forest_trees[0]
	for candidate in lobby._forest_trees:
		if candidate.position.distance_to(Vector2(50, 15)) < tree.position.distance_to(Vector2(50, 15)):
			tree = candidate
	lobby.camera.set_physics_process(false)
	lobby.camera.global_position = tree.position + Vector2(-1, -1)
	lobby.camera.zoom = Vector2.ONE * 55
	lobby.player.global_position = tree.position + Vector2(-3, 3)
	var keeper: Resident
	for resident in lobby._residents:
		if resident.water_power:
			keeper = resident
			break
	keeper._release_tree_task()
	keeper.global_position = tree.global_position + Vector2(-4.5, 1.5)
	keeper._tree_task = tree
	tree.caretaker = keeper
	var monster := lobby._forest_monsters[0]
	monster.global_position = tree.global_position + Vector2(1.6, 0.4)
	tree.take_attack_damage(70)
	await _shot("01_fire")
	keeper.set_physics_process(true)
	var elapsed := 0.0
	while not keeper._watering and elapsed < 12.0:
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()
	if not keeper._watering:
		push_error("Water keeper failed to walk to the burning tree.")
		get_tree().quit(1)
		return
	await _shot("02_water_rescue")
	await get_tree().create_timer(3.0).timeout
	tree.take_attack_damage(9999)
	keeper.set_physics_process(false)
	keeper._release_tree_task()
	for resident in lobby._residents:
		if resident.worker_role == "planter":
			keeper = resident
			break
	keeper.global_position = tree.global_position + Vector2(-4, 1.5)
	keeper._tree_task = tree
	tree.caretaker = keeper
	keeper.set_physics_process(true)
	elapsed = 0.0
	while tree.fallen and elapsed < 10.0:
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()
	if tree.fallen:
		push_error("Green planter failed to plant the fallen tree.")
		get_tree().quit(1)
		return
	await _shot("03_sapling")
	tree._process(15.0)
	await _shot("04_growing")
	tree._process(15.0)
	await _shot("05_mature")
	keeper.set_physics_process(false)
	for candidate in lobby._forest_trees:
		candidate._process(ForestTree.GROW_SECONDS)
		candidate.take_attack_damage(9999)
	await get_tree().create_timer(3.6).timeout
	await _shot("06_devastation")
	await get_tree().create_timer(0.6).timeout
	await _shot("07_game_over")
	print("forest review: PASS")
	get_tree().quit()


func _shot(label: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var path := _shots.path_join(label + ".png")
	var error := get_viewport().get_texture().get_image().save_png(path)
	if error != OK:
		push_error("Forest screenshot could not be saved: " + path)
	print("forest screenshot: ", path)
