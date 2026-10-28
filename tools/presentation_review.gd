extends Node
## Native renderer evidence and a reproducible crowded-night workload.
var _frames: Array[float] = []
var _physics: Array[float] = []
var _checks := 0
var _failures := 0

func _ready() -> void:
	if not TestEnvironment.require_isolation(): get_tree().quit(1); return
	GameState.autosave_enabled = false
	GameState.new_game("adam")
	GameState.data.mission_step = MissionDB.STEPS.size()
	GameState.data.world_time = 240.0
	GameState.data.home_wave = GameState.night_number()
	var game := load("res://scenes/game.tscn").instantiate() as Game
	add_child(game)
	game._remove_title()
	await game._load_lobby(false)
	game.set_process(false)
	game.hud.tutorial_guide.visible = false
	if "--capture-only" in OS.get_cmdline_user_args():
		await preload("res://tools/presentation_checks.gd").run(game,_check)
		await _capture_realms(game,OS.get_environment("TIDESWORN_TEST_ROOT"))
		print("presentation review: %d checks, %s" % [_checks,"PASS" if _failures == 0 else "FAIL"])
		get_tree().quit(0 if _failures == 0 else 1)
		return
	var home := game.world as Lobby
	for actor in home.get_children():
		if actor is Enemy: actor.queue_free()
	await get_tree().process_frame
	home.player.position = Vector2(47,20)
	home.player.controls_locked = true
	GameState.data.hp_max = 100000
	GameState.data.hp = 100000
	for node in get_tree().get_nodes_in_group("forest_tree"):
		if node is ForestTree: node.health = 100000
	for i in 48:
		var enemy := Enemy.new()
		enemy.kind = "fire" if i%2 == 0 else "urchin"
		enemy.forest_mode = true
		enemy.position = Vector2(38+(i%8)*2,13+(i/8)*2)
		enemy.max_hp = 100000
		enemy.damage = 1
		home.add_child(enemy)
	for i in 150:
		await get_tree().process_frame
		if i >= 30:
			_frames.append(float(Performance.get_monitor(Performance.TIME_PROCESS))*1000.0)
			_physics.append(float(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS))*1000.0)
	_frames.sort()
	_physics.sort()
	var directory := OS.get_environment("TIDESWORN_TEST_ROOT")
	var metrics := {"enemies":48,"samples":_frames.size(),"process_median_ms":_frames[_frames.size()/2],"process_p95_ms":_frames[int(_frames.size()*0.95)],"physics_median_ms":_physics[_physics.size()/2],"physics_p95_ms":_physics[int(_physics.size()*0.95)],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"renderer":RenderingServer.get_video_adapter_name()}
	var file := FileAccess.open(directory.path_join("performance.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(metrics,"\t"))
	file.close()
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(directory.path_join("crowded-night.png"))
	print("PRESENTATION_METRICS ",JSON.stringify(metrics))
	await preload("res://tools/presentation_checks.gd").run(game,_check)
	await _capture_realms(game,directory)
	print("presentation review: %d checks, %s" % [_checks,"PASS" if _failures == 0 else "FAIL"])
	get_tree().quit(0 if _failures == 0 else 1)

func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok: _failures += 1
	print("[OK] " if ok else "[FAIL] ",message)

func _capture_realms(game: Game, directory: String) -> void:
	GameState.data.level = 99
	GameState.data.xp_next = GameState.xp_for_level(99)
	for portal in PortalDB.ordered_ids():
		GameState.data.portals[portal].unlocked = true
		GameState.start_expedition(portal)
		await game._load_dungeon(portal,false)
		var world := game.world as Dungeon
		world.set_process(false)
		world._boss_arrived = true
		for node in world.get_children():
			if node is Enemy or node is Player or node is Pet or node is DungeonHazard: node.set_physics_process(false)
			if node is CanvasLayer: node.visible = false
		var boss := world.boss as ElementalBoss
		boss.position = Vector2(24,13)
		boss.visible = true
		boss.modulate.a = 1
		world.player.position = Vector2(24,19)
		world.camera.set_process(false)
		world.camera.set_physics_process(false)
		world.camera.position = Vector2(24,14)
		world.camera.zoom = Vector2.ONE*26
		boss._enter(Enemy.State.WINDUP)
		boss._pose_tween.custom_step(0.1)
		await _capture(directory,"windup_"+boss.element)
		boss._enter(Enemy.State.RECOVER)
		var effect := boss._ground(Vector2(19,18),"circle",3.0,4.0)
		effect.set_physics_process(false)
		effect.clock = 0.5
		effect._update_presentation()
		await _capture(directory,"warning_"+boss.element)
		effect.clock = effect.windup+0.3
		effect._update_presentation()
		await _capture(directory,"realm_"+boss.element)
	game._clear_world()
	var ocean := OceanJourney.new()
	game.world = ocean
	game._world_holder.add_child(ocean)
	game.hud.hide()
	ocean.set_process(false)
	ocean._process(4)
	await _capture(directory,"sea_tutorial")
	ocean.dismiss_sea_guide()
	for pair in [["food",18],["trash",22],["bomb",26],["shark",31],["heart",35]]: ocean.spawn_item(str(pair[0]),float(pair[1]))
	await _capture(directory,"sea_no_labels")
	get_window().size = Vector2i(832,480)
	await get_tree().process_frame
	ocean.show_sea_guide()
	await _capture(directory,"sea_tutorial_832x480")
	ocean.dismiss_sea_guide()
	await _capture(directory,"sea_no_labels_832x480")

func _capture(directory: String, label: String) -> void:
	await get_tree().create_timer(0.15).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(directory.path_join(label+".png"))
