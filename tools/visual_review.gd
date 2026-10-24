extends Node
## Isolated visual review harness. Creates a new journey in temporary user data.
##
## Renders fixed scenarios (title, lobby, shops, panels, dungeon, HUD at two
## window sizes) to PNGs so visual work can be judged without running the
## destructive tide_capture tool. It changes temporary saves/settings, requires
## verified isolation and writes fresh captures outside res://.
##
## Run with a virtual display:
##   xvfb-run -a -s "-screen 0 1280x720x24" env LIBGL_ALWAYS_SOFTWARE=1 \
##     godot --path . res://tools/visual_review.tscn -- [--shots DIR] [--only NAME]


const DEFAULT_SHOT_DIR := ""

var shot_dir := DEFAULT_SHOT_DIR
var only := ""
var game: Node
var hud: Node


func _ready() -> void:
	if not TestEnvironment.require_isolation():
		get_tree().quit(1)
		return
	var args := OS.get_cmdline_user_args()
	for i in range(0, args.size() - 1, 2):
		if args[i] == "--shots":
			shot_dir = args[i + 1]
		elif args[i] == "--only":
			only = args[i + 1]
	if shot_dir.is_empty():
		shot_dir = OS.get_cache_dir().path_join("tidesworn-review-%d" % Time.get_ticks_msec())
	print("visual_review user data: ", OS.get_user_data_dir())
	DirAccess.make_dir_recursive_absolute(shot_dir)
	print("visual_review: writing to ", shot_dir)

	game = load("res://scenes/game.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	await _shot("01_title")

	await game.call("_on_character_selected", "qayyim")
	await get_tree().create_timer(0.6).timeout
	hud = game.get("hud")
	if hud != null and hud.tutorial_guide != null:
		hud.tutorial_guide.call("_skip")
	await get_tree().create_timer(0.3).timeout
	await _shot("02_lobby_home")
	await _capture_repairs()

	var player: Node = game.call("player")
	if player != null:
		player.global_position = Vector2(34.0, 16.2)
		await get_tree().create_timer(0.6).timeout
	await _shot("03_lobby_portals")

	if player != null:
		player.global_position = Vector2(23.8, 24.5)
		await get_tree().create_timer(0.4).timeout
	await _shot("04_lobby_market")

	await _capture_shop("05_shop_potion", "potion", "Mara")
	await _capture_shop("06_shop_equipment", "equipment", "Garrick")
	await _capture_shop("07_shop_pet", "pet", "Nia")

	game.call("open_house")
	await get_tree().create_timer(0.5).timeout
	await _shot("08_house_bram")
	hud.hide_modals()
	await get_tree().process_frame

	game.call("open_inventory")
	await get_tree().create_timer(0.5).timeout
	await _shot("09_inventory")
	hud.hide_modals()
	await get_tree().process_frame

	game.call("enter_portal", "tidebound_grotto")
	await get_tree().create_timer(1.0).timeout
	await _shot("10_dungeon_grotto")

	game.call("return_to_lobby", true)
	await get_tree().create_timer(1.2).timeout

	# Narrow window: HUD and modal fit checks at 832x480.
	get_window().size = Vector2(832, 480)
	await get_tree().create_timer(0.3).timeout
	await _shot("11_hud_832x480")
	game.call("open_shop", "potion", "Mara")
	await get_tree().create_timer(0.5).timeout
	await _shot("12_shop_832x480")
	hud.hide_modals()
	await get_tree().process_frame

	# Combat frame strip: sword wind-up / active / recovery against a dummy.
	var strip_player: Node = game.call("player")
	if strip_player != null and game.world is Lobby:
		strip_player.global_position = Vector2(34.0, 30.0)
		var dummy: Enemy = load("res://scripts/combat/enemy.gd").new()
		dummy.kind = "bogling"
		dummy.max_hp = 500
		dummy.damage = 0
		dummy.speed = 0.0
		dummy.position = strip_player.global_position + Vector2(1.6, 0.2)
		game.world.add_child(dummy)
		strip_player.set("facing", Vector2.RIGHT)
		await get_tree().create_timer(0.3).timeout
		strip_player.call("try_attack")
		for i in 5:
			await get_tree().create_timer(0.07).timeout
			await _shot("13_combat_strip_%d" % i)
		dummy.queue_free()

	print("visual_review: done")
	game.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(0)


func _capture_shop(shot_name: String, kind: String, keeper: String) -> void:
	game.call("open_shop", kind, keeper)
	await get_tree().create_timer(0.5).timeout
	await _shot(shot_name)
	hud.hide_modals()
	await get_tree().process_frame


func _shot(shot_name: String) -> void:
	if only != "" and only != shot_name:
		return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := shot_dir.path_join(shot_name + ".png")
	var err := image.save_png(path)
	print("visual_review: ", shot_name, " -> ", path, " (", "ok" if err == OK else str(err), ")")


func _look_at(at: Vector2) -> void:
	var p: Player = game.call("player")
	p.global_position = at
	p.velocity = Vector2.ZERO
	p.reset_physics_interpolation()
	if game.world is Lobby:
		game.world.camera.global_position = at + Vector2(0, -1)
		game.world.camera.reset_physics_interpolation()
	await get_tree().create_timer(0.5).timeout


func _capture_repairs() -> void:
	var lobby := game.world as Lobby
	var p: Player = game.call("player")
	var system: RubbishSystem = lobby._rubbish_system
	system.spawn_interval = 999999.0
	for monster in lobby._forest_monsters:
		monster.set_physics_process(false)
	for resident in lobby._residents:
		resident.set_physics_process(false)
		resident._end_visit()
	# Complete coastline, including the formerly leaking eastern end.
	for entry in [["west", Vector2(6, 24)], ["turtle", Vector2(14, 28)], ["east", Vector2(24, 35)]]:
		await _look_at(entry[1])
		await _shot("repair_coast_" + entry[0])
	await _look_at(Vector2(30.4, 26.8))
	await _shot("repair_besut")
	await _look_at(Vector2(53, 19))
	await _shot("repair_forest")
	# All quality/motion combinations use the actual shader renderer.
	await _look_at(Vector2(14, 28))
	for quality in ["low", "med", "high"]:
		for reduced in [false, true]:
			GameSettings.set_effects_quality(quality, false)
			GameSettings.set_reduce_motion(reduced, false)
			await get_tree().create_timer(0.2).timeout
			await _shot("repair_water_%s_motion_%s" % [quality, reduced])
	GameSettings.set_effects_quality("high", false)
	GameSettings.set_reduce_motion(false, false)
	# GUI extremes at each requested physical window resolution.
	for resolution in [Vector2i(1280, 720), Vector2i(832, 480)]:
		get_window().size = resolution
		for gui in [0.75, 1.0, 1.3]:
			hud.set_gui_scale(gui, false)
			await _look_at(Lobby.SPAWN)
			await _shot("repair_gui_%dx%d_%d" % [resolution.x, resolution.y, roundi(gui * 100.0)])
		game.call("open_settings")
		await get_tree().create_timer(0.3).timeout
		await _shot("repair_settings_%dx%d" % [resolution.x, resolution.y])
		hud.settings_panel.close_panel()
	get_window().size = Vector2i(1280, 720)
	hud.set_gui_scale(1.0, false)
	for zoom_value in [GameSettings.CAMERA_ZOOM_MIN, GameSettings.CAMERA_ZOOM_DEFAULT, GameSettings.CAMERA_ZOOM_MAX]:
		GameSettings.set_camera_zoom(zoom_value, false)
		await _look_at(Vector2(30.4, 26.8))
		await get_tree().create_timer(0.5).timeout
		await _shot("repair_zoom_%d" % zoom_value)
	GameSettings.set_camera_zoom(GameSettings.CAMERA_ZOOM_DEFAULT, false)
	# A real customer performs a complete visit; capture states as they occur.
	var shops := get_tree().get_nodes_in_group("ambient_shop")
	var shop := shops[0] as ShopNPC
	var customer := Resident.new()
	customer.resident_name = "Review customer"
	customer.position = shop.customer_position() + Vector2(0.0, 1.4)
	customer.waypoints = [customer.position]
	lobby.add_child(customer)
	for seed_value in 100:
		var random := RandomNumberGenerator.new()
		random.seed = seed_value
		random.randf_range(24.0, 50.0)
		if random.randi_range(0, shops.size() - 1) == 0:
			customer._shopping_rng.seed = seed_value
			break
	p.global_position = shop.customer_position() + Vector2(3, 1)
	p.reset_physics_interpolation()
	var gold := GameState.gold()
	var inventory: Dictionary = GameState.data.inventory.duplicate(true)
	customer.begin_shop_visit()
	var captured := {}
	for i in 840:
		await get_tree().physics_frame
		var state: int = customer.shopping_state
		if state != Resident.Shopping.ROUTINE and not captured.has(state):
			captured[state] = true
			await get_tree().create_timer(0.15).timeout
			await _shot("repair_shopping_%d" % state)
		if customer.shopping_visits > 0 and state == Resident.Shopping.ROUTINE:
			break
	print("SHOPPING_REVIEW visits=", customer.shopping_visits, " states=", captured.keys(), " economy_unchanged=", gold == GameState.gold() and inventory == GameState.data.inventory)
	customer.queue_free()
	# Consecutive rendered movement frames, plus numeric physics samples.
	await _look_at(Vector2(31, 28))
	lobby.pet.global_position = p.global_position + Vector2(-8, 0)
	lobby.pet.reset_physics_interpolation()
	var records: Array = []
	Input.action_press("move_right")
	for i in 30:
		await get_tree().physics_frame
		records.append({"frame": i, "player": [p.position.x, p.position.y], "pet": [lobby.pet.position.x, lobby.pet.position.y], "camera": [lobby.camera.position.x, lobby.camera.position.y]})
		if i >= 8 and i <= 15:
			await _shot("repair_motion_%02d" % i)
	Input.action_release("move_right")
	Input.action_press("move_down")
	for i in 20:
		await get_tree().physics_frame
	Input.action_release("move_down")
	await get_tree().create_timer(0.3).timeout
	await _shot("repair_motion_stop")
	var file := FileAccess.open(shot_dir.path_join("movement-samples.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(records, "\t"))
	file.close()
	for monster in lobby._forest_monsters:
		monster.set_physics_process(true)
	for resident in lobby._residents:
		resident.set_physics_process(true)
	await _look_at(Lobby.SPAWN)
