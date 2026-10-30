extends Node
## Release benchmark exported under its own Android package. Never uses player data.
const PACKAGE := "com.tidesworn.protectbesut.benchmark"
const WARMUP_SECONDS := 4.0
const SAMPLE_SECONDS := 12.0
const PROFILES := [
	{"id":"native_60_high", "viewport":false, "fps":60, "quality":"high"},
	{"id":"viewport_60_high", "viewport":true, "fps":60, "quality":"high"},
	{"id":"viewport_60_med", "viewport":true, "fps":60, "quality":"med"},
]
const SCENARIOS := ["village", "forest_night", "citadel", "ocean"]
var game: Game
var results: Array[Dictionary] = []
var anchor := Vector2.ZERO
var _ocean: OceanJourney

func _ready() -> void:
	var isolated := TestEnvironment.require_isolation() if OS.get_name() != "Android" else OS.has_feature("android_benchmark") and PACKAGE in OS.get_user_data_dir().split("/")
	if not isolated:
		push_error("Android benchmark requires its dedicated package and feature tag.")
		get_tree().quit(1)
		return
	GameState.autosave_enabled = false
	GameSettings.set_mute_all(true, false)
	GameSettings.set_reduce_motion(false, false)
	game = load("res://scenes/game.tscn").instantiate() as Game
	add_child(game)
	game._side_quest_auto_enabled = false
	game.set_process(false) # Fixed clock phase; actor physics remains live.
	game._remove_title()
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	print("ANDROID_BENCHMARK_START ", JSON.stringify({"engine":Engine.get_version_info().string,"gpu":RenderingServer.get_video_adapter_name(),"driver":RenderingServer.get_current_rendering_driver_name(),"renderer":RenderingServer.get_current_rendering_method(),"audio_driver":AudioServer.get_driver_name(),"user_data":OS.get_user_data_dir(),"build":ProjectSettings.get_setting("application/config/benchmark_source", "unknown")}))
	for pass_index in 2:
		var profiles := PROFILES.duplicate()
		if pass_index == 1: profiles.reverse() # Counterbalance warm-up/thermal order.
		for profile in profiles:
			Engine.max_fps = int(profile.fps)
			get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT if profile.viewport else Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
			GameSettings.set_effects_quality(str(profile.quality), false)
			for scenario in SCENARIOS:
				var began := Time.get_ticks_usec()
				await _prepare(scenario)
				var build_ms := (Time.get_ticks_usec() - began) / 1000.0
				await get_tree().create_timer(WARMUP_SECONDS).timeout
				var sample := await _measure()
				sample.profile = profile.id
				sample.scenario = scenario
				sample.pass_index = pass_index
				sample.build_ms = build_ms
				sample.build = ProjectSettings.get_setting("application/config/benchmark_source", "unknown")
				sample.focused = get_window().has_focus()
				sample.gpu_timer_available = sample.gpu_ms.max > 0.0
				sample.window = [get_window().size.x, get_window().size.y]
				var render_size := get_viewport().get_texture().get_size()
				sample.render_size = [render_size.x, render_size.y]
				sample.logical_size = [get_viewport().get_visible_rect().size.x, get_viewport().get_visible_rect().size.y]
				results.append(sample)
				print("ANDROID_BENCHMARK_SAMPLE ", JSON.stringify(sample))
				var output := FileAccess.open("user://android_benchmark.json", FileAccess.WRITE)
				if output: output.store_string(JSON.stringify(results, "\t"))
				# Capture after measurement, never inside its frame-time window.
				if pass_index == 0 and profile.id in ["native_60_high", "viewport_60_high"]:
					await RenderingServer.frame_post_draw
					get_viewport().get_texture().get_image().save_png("user://%s_%s.png" % [profile.id, scenario])
	print("ANDROID_BENCHMARK_DONE ", results.size())
	# Leave an isolated playable village for actual phone UI/input inspection.
	set_physics_process(false)
	Engine.max_fps = 60
	GameSettings.set_value("render_resolution", "balanced", false)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	await game._load_lobby(false)
	game.set_process(true)
	game._input_locked = false
	game._apply_input_lock()
	game.hud.show()
	game.hud.tutorial_guide.hide()

func _prepare(scenario: String) -> void:
	_ocean = null
	GameState.data = GameState._make_default("adam")
	GameState.data.portal_origin.opened = true
	GameState.data.campaign.intro_seen = true
	GameState.data.campaign.dock_welcome_seen = true
	GameState.data.world_time = 250.0 if scenario == "forest_night" else 45.0
	GameState.data.home_wave = GameState.night_number()
	game.hud.hide_modals()
	if scenario == "ocean":
		game._clear_world()
		_ocean = OceanJourney.new()
		_ocean.name = "OceanJourney"
		game.world = _ocean
		game._world_holder.add_child(_ocean)
		game.hud.set_world(_ocean)
		game.hud.hide()
		_ocean._rng.seed = 86037
		_ocean.phase = OceanJourney.Phase.RUNNING
		_ocean._sea_guide.hide()
		_ocean.player.visible = true
		_ocean.player.position = _ocean.turtle.position + Vector2(-0.55, -1.0)
	elif scenario == "citadel":
		GameState.start_expedition(RealmDB.PORTAL)
		await game._load_dungeon(RealmDB.PORTAL, false)
		anchor = RealmDB.BOSS_THRESHOLD
		game.player().position = anchor
		(game.world as TwilightRealm).pet.set_physics_process(false)
	else:
		await game._load_lobby(false)
		anchor = Vector2(53, 22) if scenario == "forest_night" else Lobby.SPAWN
		game.player().position = anchor
		if scenario == "forest_night":
			(game.world as Lobby)._spawn_forest_monsters(6)
			for tree in (game.world as Lobby)._forest_trees:
				if tree.position.distance_to(anchor) < 6: tree.take_attack_damage(1)
	game._input_locked = true
	game._apply_input_lock()
	if scenario != "ocean":
		game.hud.show()
		game.hud.tutorial_guide.hide()
		game.player().invulnerable = 10000
	await get_tree().physics_frame

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(game) or not is_instance_valid(game.world): return
	if is_instance_valid(_ocean):
		# Exercise normal spawning/scenery without starvation or route transitions.
		_ocean.health = OceanJourney.MAX_HEALTH
		_ocean.fullness = 100
		_ocean.elapsed = minf(_ocean.elapsed, 20)
		_ocean._hurt_time = 2
	elif is_instance_valid(game.player()):
		game.player().position = anchor
		game.player().velocity = Vector2.ZERO

func _measure() -> Dictionary:
	var intervals: Array[float] = []
	var gpu: Array[float] = []
	var cpu_render: Array[float] = []
	var process: Array[float] = []
	var physics: Array[float] = []
	var draws := 0.0
	var start := Time.get_ticks_usec()
	var previous := start
	var viewport := get_viewport().get_viewport_rid()
	while Time.get_ticks_usec() - start < SAMPLE_SECONDS * 1000000:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		intervals.append((now - previous) / 1000.0)
		previous = now
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(viewport))
		cpu_render.append(RenderingServer.viewport_get_measured_render_time_cpu(viewport))
		process.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000)
		physics.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000)
		draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	return {"seconds":(previous-start)/1000000.0,"frames":intervals.size(),"fps":intervals.size()*1000000.0/(previous-start),"frame_ms":_stats(intervals),"gpu_ms":_stats(gpu),"render_cpu_ms":_stats(cpu_render),"engine_process_ms":_stats(process),"physics_ms":_stats(physics),"draw_calls":draws/maxi(1,intervals.size()),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"cache_entries":PixelArt.CACHE.size()}

func _stats(values: Array[float]) -> Dictionary:
	values.sort()
	if values.is_empty(): return {}
	var sum := 0.0
	var over_20 := 0
	for value in values:
		sum += value
		if value > 20: over_20 += 1
	return {"mean":sum/values.size(),"p50":values[ceili(values.size()*0.5)-1],"p95":values[ceili(values.size()*0.95)-1],"p99":values[ceili(values.size()*0.99)-1],"max":values[-1],"over_20_ms":over_20}
