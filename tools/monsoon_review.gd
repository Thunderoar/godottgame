extends Node
## Repeatable real-renderer fixtures. All clock/save mutations require isolation.
var game: Game
var output := ""
var manifest: Array[Dictionary] = []

func _ready() -> void:
	if not TestEnvironment.require_isolation():
		get_tree().quit(1)
		return
	output = OS.get_environment("MONSOON_OUTPUT")
	if output.is_empty():
		get_tree().quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output)
	game = load("res://scenes/game.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	var start := Time.get_ticks_usec()
	game.call("_on_character_selected", "qayyim")
	var cold := (Time.get_ticks_usec() - start) / 1000.0
	game.hud.tutorial_guide.call("_skip")
	game.set_process(false)
	_freeze()
	var forest: Array = []
	for tree in (game.world as Lobby)._forest_trees:
		forest.append({"id": tree.tree_id, "position": [tree.position.x, tree.position.y], "hp": tree.max_health})
	_write("forest.json", forest)
	await _look(Lobby.SPAWN)
	await _shot("new-journey")
	GameState.advance_world_clock(45.0 - float(GameState.data.get("world_time", 0.0)))
	for fixture in [["village", Vector2(34, 24.3)], ["market", Vector2(24, 22)], ["forest", Vector2(53, 19)], ["beach", Vector2(9, 25)], ["turtle", Vector2(14, 28)], ["east-coast", Vector2(24, 35)], ["besut", Vector2(30.4, 26.8)], ["portals", Vector2(34, 13)]]:
		await _look(fixture[1])
		await _shot(fixture[0])
	await _look(Lobby.SPAWN)
	game.call("open_inventory")
	await _shot("inventory")
	game.hud.hide_modals()
	game.call("open_shop", "potion", "Mara")
	await _shot("shop")
	game.hud.hide_modals()
	await _look(Vector2(14, 28))
	for quality in ["low", "med", "high"]:
		GameSettings.set_effects_quality(quality, false)
		await _shot("water-" + quality)
	GameSettings.set_reduce_motion(true, false)
	await _shot("reduce-motion")
	GameSettings.set_reduce_motion(false, false)
	for zoom_value in [28.0, 64.0]:
		GameSettings.set_camera_zoom(zoom_value, false)
		await _look(Lobby.SPAWN)
		await _shot("zoom-%d" % zoom_value)
	GameSettings.set_camera_zoom(38.0, false)
	get_window().size = Vector2i(832, 480)
	await _look(Lobby.SPAWN)
	await _shot("small-screen")
	game.call("open_shop", "potion", "Mara")
	await _shot("small-shop")
	game.hud.hide_modals()
	get_window().size = Vector2i(1280, 720)
	GameState.advance_world_clock(155.0 - float(GameState.data.get("world_time", 0.0)))
	await _look(Lobby.SPAWN)
	await _shot("golden-hour")
	GameState.advance_world_clock(205.0 - float(GameState.data.get("world_time", 0.0)))
	_freeze()
	await get_tree().create_timer(3.2).timeout
	await _look(Lobby.SPAWN)
	await _shot("night-village")
	await _look(Vector2(53, 19))
	await _shot("night-forest")
	var lobby := game.world as Lobby
	var tree := lobby._forest_trees[0]
	var keeper: Resident
	for resident in lobby._residents:
		if resident.water_power:
			keeper = resident
			break
	tree.take_attack_damage(60)
	if keeper:
		keeper.position = tree.position + Vector2(1.2, 0.9)
		keeper.reset_physics_interpolation()
		keeper.set_physics_process(true)
	await _look(tree.position + Vector2(0, 1))
	for frame in 120:
		await get_tree().physics_frame
		if keeper and keeper._watering: break
	await _shot("water-keeper")
	print("CARETAKER watering=", keeper != null and keeper._watering)
	if keeper: keeper.set_physics_process(false)
	var enemy := Enemy.new()
	enemy.kind = "urchin"
	enemy.max_hp = 500
	enemy.speed = 0.0
	enemy.damage = 0
	enemy.position = game.player().position + Vector2(1.4, 0)
	lobby.add_child(enemy)
	game.player().facing = Vector2.RIGHT
	game.player().controls_locked = false
	Engine.time_scale = 0.25
	assert(game.player().try_attack())
	await get_tree().create_timer(0.13).timeout
	await _shot("coastal-combat", 0.0)
	assert(enemy.hp < 500)
	Engine.time_scale = 1.0
	print("COMBAT coastal: damage verified")
	# Reset only the isolated gameplay clock through its existing transaction.
	GameState.advance_world_clock(360.0 - float(GameState.data.get("world_time", 0.0)))
	game.call("enter_portal", "tidebound_grotto")
	await _wait_for_world(true)
	await _look(Dungeon.SPAWN + Vector2(0, -4))
	await _shot("dungeon")
	var dungeon := game.world as Dungeon
	if dungeon:
		var foe := Enemy.new()
		foe.kind = "drowned"
		foe.max_hp = 500
		foe.damage = 0
		foe.speed = 0
		foe.position = game.player().position + Vector2(1.4, 0)
		dungeon.add_child(foe)
		game.player().facing = Vector2.RIGHT
		game.player().controls_locked = false
		Engine.time_scale = 0.25
		assert(game.player().try_attack())
		await get_tree().create_timer(0.10).timeout
		await _shot("dungeon-combat", 0.0)
		assert(foe.hp < 500)
		Engine.time_scale = 1.0
		print("COMBAT dungeon: damage verified")
	game.call("return_to_lobby", true)
	await _wait_for_world(false)
	var warm_start := Time.get_ticks_usec()
	game.call("_load_lobby", false)
	var warm := (Time.get_ticks_usec() - warm_start) / 1000.0
	_freeze()
	await _look(Lobby.SPAWN)
	var metrics := {"cold_build_ms": cold, "warm_build_ms": warm, "world_time": GameState.data.get("world_time", 0.0), "renderer": RenderingServer.get_video_adapter_name(), "resolution": [1280, 720], "quality": {}}
	for quality in ["high", "med", "low"]:
		GameSettings.set_effects_quality(quality, false)
		for frame in 40: await get_tree().process_frame
		var times: Array[float] = []
		var draws := 0.0
		var previous := Time.get_ticks_usec()
		for frame in 180:
			await get_tree().process_frame
			var now := Time.get_ticks_usec()
			times.append((now - previous) / 1000.0)
			previous = now
			draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		times.sort()
		metrics.quality[quality] = {"median_ms": times[90], "mean_ms": times.reduce(func(a: float, b: float) -> float: return a + b, 0.0) / 180.0, "p95_ms": times[171], "max_ms": times[-1], "draw_calls": draws / 180.0, "texture_bytes": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED), "cache_entries": PixelArt.CACHE.size()}
	_write("performance.json", metrics)
	_write("manifest.json", manifest)
	print("MONSOON_REVIEW PASS ", JSON.stringify(metrics))
	game.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit()

func _wait_for_world(dungeon: bool) -> void:
	for frame in 600:
		await get_tree().process_frame
		if not game._transitioning and not game._portal_fx_active and ((game.world is Dungeon) if dungeon else (game.world is Lobby)):
			return
	assert(false, "World transition did not settle for the capture fixture")

func _freeze() -> void:
	game.player().controls_locked = true
	if game.world is Lobby:
		(game.world as Lobby)._rubbish_system.spawn_interval = 999999
	for group in ["residents", "enemies"]:
		for node in get_tree().get_nodes_in_group(group):
			node.set_physics_process(false)

func _look(at: Vector2) -> void:
	var player := game.player()
	player.position = at
	player.velocity = Vector2.ZERO
	player.facing = Vector2.ZERO
	player.reset_physics_interpolation()
	var camera: FollowCamera = game.world.camera
	camera.global_position = at + Vector2(0, -1)
	camera.reset_physics_interpolation()
	await get_tree().create_timer(0.25).timeout

func _shot(label: String, settle: float = 0.2) -> void:
	if settle > 0.0: await get_tree().create_timer(settle).timeout
	await RenderingServer.frame_post_draw
	var picture := get_viewport().get_texture().get_image()
	var result := picture.save_png(output.path_join(label + ".png"))
	assert(result == OK)
	manifest.append({"name": label, "world_time": GameState.data.get("world_time", 0.0), "player": [game.player().position.x, game.player().position.y], "zoom": GameSettings.camera_zoom(), "quality": GameSettings.effects_quality(), "reduce_motion": GameSettings.reduce_motion(), "size": [picture.get_width(), picture.get_height()]})
	print("CAPTURE ", label)

func _write(filename: String, value: Variant) -> void:
	var file := FileAccess.open(output.path_join(filename), FileAccess.WRITE)
	file.store_string(JSON.stringify(value, "\t"))
