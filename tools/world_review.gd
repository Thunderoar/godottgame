extends Node
## Runs unchanged against the source baseline and feature branch.
var game: Game
var output := ""
var manifest: Array[Dictionary] = []
var failures := 0

func _ready() -> void:
	if not TestEnvironment.require_isolation(): get_tree().quit(1); return
	output = OS.get_environment("WORLD_OUTPUT")
	if output.is_empty(): get_tree().quit(1); return
	DirAccess.make_dir_recursive_absolute(output)
	game = load("res://scenes/game.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	var start := Time.get_ticks_usec()
	await game.call("_on_character_selected", "qayyim")
	var cold := float(Time.get_ticks_usec() - start) / 1000.0
	game.set_process(false)
	game.hud.tutorial_guide.call("_skip")
	GameSettings.set_camera_zoom(38, false)
	GameSettings.set_effects_quality("high", false)
	GameSettings.set_reduce_motion(true, false)
	GameState.advance_world_clock(45 - float(GameState.data.get("world_time", 0)))
	_freeze()
	# Identical camera/time/settings for every paired composition fixture.
	for fixture in [["spawn", Vector2(34, 24.3)], ["market", Vector2(24, 22)], ["market-home", Vector2(29, 23)], ["portals", Vector2(34, 13)], ["forest-edge", Vector2(46, 22)], ["forest-interior", Vector2(55, 22)], ["beach-turtle", Vector2(14, 28)], ["jetty-ship", Vector2(9, 28.5)], ["farms-residential", Vector2(40, 28)], ["besut", Vector2(29.5, 28.3)], ["west-cottages", Vector2(15, 17)], ["residential-lane", Vector2(17, 13)], ["market-lower", Vector2(26, 29)], ["farm-yard", Vector2(39, 34)]]:
		await _look(fixture[1])
		await _shot(fixture[0])
	GameSettings.set_camera_zoom(64, false)
	await _look(Vector2(53.8, 23.1))
	await _shot("deep-forest")
	GameSettings.set_camera_zoom(38, false)
	await _overview()
	await _shot("overview")
	game.hud.visible = false
	await _shot("overview-clean")
	game.hud.visible = true
	game.world.camera.set_process(true)
	game.world.camera.set_physics_process(true)
	GameSettings.set_reduce_motion(false, false)
	await _look(Lobby.SPAWN)
	for quality in ["low", "med", "high"]:
		GameSettings.set_effects_quality(quality, false)
		await _shot("effects-" + quality)
	GameSettings.set_reduce_motion(true, false)
	await _shot("reduce-motion")
	GameSettings.set_reduce_motion(false, false)
	for zoom in [28.0, 64.0]:
		GameSettings.set_camera_zoom(zoom, false)
		await _look(Lobby.SPAWN)
		await _shot("zoom-%d" % zoom)
	GameSettings.set_camera_zoom(38, false)
	get_window().size = Vector2i(832, 480)
	await _look(Lobby.SPAWN)
	await _shot("small-screen")
	get_window().size = Vector2i(1280, 720)
	# Continuous input produces actual intermediate positions and rendered frames.
	await _look(Vector2(32, 24.4))
	game.world.camera.target = game.player()
	game.world.camera.set_physics_process(true)
	game.player().controls_locked = false
	var travel_start := game.player().position
	var positions: Array = []
	Input.action_press("move_right")
	for frame in 30:
		await get_tree().physics_frame
		positions.append([game.player().position.x, game.player().position.y])
		if frame in [0, 14, 29]: await _shot("traversal-%02d" % frame)
	Input.action_release("move_right")
	game.player().controls_locked = true
	var travelled := game.player().position.distance_to(travel_start)
	_verify(travelled > 1.0, "player traverses the central lane under actual movement input")
	_write("traversal.json", positions)
	var enemy := Enemy.new()
	enemy.kind = "urchin"
	enemy.max_hp = 500
	enemy.damage = 0
	enemy.speed = 0
	enemy.position = game.player().position + Vector2(1.4, 0)
	game.world.add_child(enemy)
	game.player().controls_locked = false
	game.player().facing = Vector2.RIGHT
	Engine.time_scale = 0.25
	_verify(game.player().try_attack(), "representative combat attack starts")
	await get_tree().create_timer(0.13).timeout
	await _shot("combat", 0)
	_verify(enemy.hp < 500, "representative combat delivers actual damage")
	Engine.time_scale = 1.0
	enemy.queue_free()
	game.player().controls_locked = true
	GameState.advance_world_clock(205 - float(GameState.data.get("world_time", 0)))
	_freeze()
	await get_tree().create_timer(0.4).timeout
	for fixture in [["night-village", Lobby.SPAWN], ["night-forest", Vector2(53, 22)], ["night-coast", Vector2(12, 27)], ["night-portals", Vector2(34, 13)], ["night-residential", Vector2(15, 17)], ["night-farm", Vector2(40, 28)]]:
		await _look(fixture[1])
		await _shot(fixture[0])
	GameSettings.set_effects_quality("low", false)
	GameSettings.set_reduce_motion(true, false)
	await _shot("night-low-reduce-motion")
	# Fresh process construction above, cached reconstruction below. Same state
	# and scripted actor hold on both refs; CPU physics/planning are also recorded.
	GameState.new_game("qayyim")
	GameState.advance_world_clock(45)
	var warm_start := Time.get_ticks_usec()
	game.call("_load_lobby", false)
	var warm := float(Time.get_ticks_usec() - warm_start) / 1000.0
	game.hud.tutorial_guide.call("_skip")
	_freeze()
	GameSettings.set_reduce_motion(false, false)
	await _look(Lobby.SPAWN)
	var metrics := {"cold_build_ms": cold, "warm_build_ms": warm, "renderer": RenderingServer.get_video_adapter_name(), "resolution": [1280, 720], "world_time": GameState.data.get("world_time", 0), "quality": {}}
	for quality in ["high", "med", "low"]:
		GameSettings.set_effects_quality(quality, false)
		for frame in 40: await get_tree().process_frame
		var times: Array[float] = []
		var draws := 0.0
		var physics := 0.0
		var process := 0.0
		var previous := Time.get_ticks_usec()
		for frame in 180:
			await get_tree().process_frame
			var now := Time.get_ticks_usec()
			times.append(float(now - previous) / 1000.0)
			previous = now
			draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
			physics += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000
			process += Performance.get_monitor(Performance.TIME_PROCESS) * 1000
		times.sort()
		metrics.quality[quality] = {"median_ms": times[90], "p95_ms": times[171], "mean_ms": times.reduce(func(a: float, b: float) -> float: return a + b, 0.0) / 180.0, "draw_calls": draws / 180, "physics_ms": physics / 180, "process_ms": process / 180, "nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT), "texture_bytes": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)}
	var planner := ResidentRoutes.new(game.world)
	var plan_start := Time.get_ticks_usec()
	var distances := {}
	for id in ["shop_potion", "shop_equipment", "shop_pet", "monster_portal", "pet_portal", "shop_house", "jetty_landing", "forest_defence"]:
		var path := planner.path(Lobby.SPAWN, game.world._layout.approach(id), false)
		var distance := 0.0
		var from := Lobby.SPAWN
		for point in path:
			distance += from.distance_to(point)
			from = point
		distances[id] = {"distance": distance, "reachable": not path.is_empty()}
	metrics.arrival_travel = distances
	metrics.planning_eight_destinations_ms = float(Time.get_ticks_usec() - plan_start) / 1000.0
	GameSettings.set_effects_quality("high", false)
	for resident in (game.world as Lobby)._residents: resident.set_physics_process(true)
	for frame in 60: await get_tree().process_frame
	var live_times: Array[float] = []
	var live_physics := 0.0
	var live_previous := Time.get_ticks_usec()
	for frame in 240:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		live_times.append(float(now - live_previous) / 1000.0)
		live_previous = now
		live_physics += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000
	live_times.sort()
	metrics.live_residents = {"median_ms": live_times[120], "p95_ms": live_times[228], "physics_ms": live_physics / 240.0, "resident_count": (game.world as Lobby)._residents.size()}
	_write("performance.json", metrics)
	_write("manifest.json", manifest)
	print("WORLD_REVIEW ", "PASS" if failures == 0 else "FAIL", " ", JSON.stringify(metrics))
	game.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(0 if failures == 0 else 1)

func _verify(ok: bool, message: String) -> void:
	if not ok: failures += 1
	print("[%s] %s" % ["OK" if ok else "FAIL", message])

func _freeze() -> void:
	game.player().controls_locked = true
	if game.world is Lobby: game.world._rubbish_system.spawn_interval = 999999
	for group in ["residents", "enemies"]:
		for node in get_tree().get_nodes_in_group(group): node.set_physics_process(false)

func _look(at: Vector2) -> void:
	var player := game.player()
	player.position = at
	player.velocity = Vector2.ZERO
	player.reset_physics_interpolation()
	var camera: Camera2D = game.world.camera
	camera.target = null
	camera.set_physics_process(false)
	camera.set_process(false)
	camera.zoom = Vector2.ONE * GameSettings.camera_zoom()
	camera.global_position = at + Vector2(0, -1)
	camera.reset_physics_interpolation()
	await get_tree().create_timer(0.15).timeout

func _overview() -> void:
	var camera: Camera2D = game.world.camera
	camera.set_process(false)
	camera.set_physics_process(false)
	camera.target = null
	camera.zoom = Vector2(17, 17)
	camera.position = Vector2(32, 20)
	camera.reset_physics_interpolation()
	await get_tree().create_timer(0.2).timeout

func _shot(label: String, settle: float = 0.1) -> void:
	if settle > 0: await get_tree().create_timer(settle).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	_verify(img.save_png(output.path_join(label + ".png")) == OK, "capture " + label)
	manifest.append({"name": label, "world_time": GameState.data.get("world_time", 0), "player": [game.player().position.x, game.player().position.y], "zoom": game.world.camera.zoom.x, "camera": [game.world.camera.get_screen_center_position().x, game.world.camera.get_screen_center_position().y], "quality": GameSettings.effects_quality(), "reduce_motion": GameSettings.reduce_motion(), "size": [img.get_width(), img.get_height()]})

func _write(filename: String, value: Variant) -> void:
	var file := FileAccess.open(output.path_join(filename), FileAccess.WRITE)
	file.store_string(JSON.stringify(value, "\t"))
