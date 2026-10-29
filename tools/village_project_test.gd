extends Node
var checks := 0
var failures := 0

func _ready() -> void:
	if not TestEnvironment.require_isolation(): get_tree().quit(1); return
	var game := load("res://scenes/game.tscn").instantiate() as Game
	add_child(game)
	game._remove_title()
	await VillageProjectChecks.run(game, _check)
	if DisplayServer.get_name() != "headless": await _review(game)
	print("--- village project: %d checks, %s ---" % [checks, "PASS" if failures == 0 else "%d failures" % failures])
	get_tree().quit(0 if failures == 0 else 1)

func _review(game: Game) -> void:
	game.set_process(false)
	game._clear_world()
	await get_tree().process_frame
	GameState.autosave_enabled = false
	GameState.data = GameState._make_default("adam")
	GameState._emit_all()
	await game._load_lobby(false)
	await get_tree().physics_frame
	await get_tree().physics_frame
	game.hud.tutorial_guide._skip()
	var home := game.world as Lobby
	var site := home.workshop
	for child in home.get_children():
		if child is CharacterBody2D: child.set_physics_process(false)
	home.camera.set_physics_process(false)
	home.camera.zoom = Vector2.ONE * 60
	home.camera.position = Vector2(10.5, 10.5)
	home.camera.reset_physics_interpolation()
	game.player().position = site.workpoint() + Vector2(0, 0.6)
	game.player()._update_nearby()
	await _capture("01_locked_site")
	game.open_shop("equipment", "Garrick")
	await _capture("02_locked_forge")
	game.hud.hide_modals()
	game._on_modal_closed()
	GameState.complete_portal("tidebound_grotto")
	game.open_house()
	await _capture("03_commission_desktop")
	get_window().size = Vector2i(832, 480)
	await _capture("04_commission_compact")
	_check(get_viewport().get_visible_rect().encloses(game.hud.house_panel._close_button.get_global_rect()), "compact construction panel keeps Close inside the viewport")
	game.hud.hide_modals()
	game._on_modal_closed()
	# Real screen-touch route: no direct invocation of the site's interact method.
	await get_tree().process_frame
	var point := game.get_viewport().get_final_transform() * (site.get_global_transform_with_canvas() * Vector2(0, -0.65))
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = point
	touch.pressed = true
	Input.parse_input_event(touch)
	await get_tree().process_frame
	touch = InputEventScreenTouch.new()
	touch.index = 0
	touch.position = point
	touch.pressed = false
	Input.parse_input_event(touch)
	await get_tree().process_frame
	_check(str(GameState.project_status().state) == "working" and site.current_worker() == game.player(), "native direct touch commissions the site and begins player work")
	if site.current_worker() != game.player():
		print("TOUCH_DIAGNOSTIC ", JSON.stringify({"state": GameState.project_status().state, "worker": str(site.current_worker()), "screen": str(point), "active": site.active_context(), "locked": game._input_locked, "player_locked": game.player().controls_locked, "attacking": game.player().attacking, "safe": site.daytime_safe(), "move_input": str(Input.get_vector("move_left", "move_right", "move_up", "move_down")), "distance": game.player().global_position.distance_to(site.global_position), "dialogue": game.hud.dialogue_panel._lines, "blocker": site.commission_blocker()}))
	var labor := Time.get_ticks_msec()
	var captured_labor := false
	while str(GameState.project_status().state) == "working" and Time.get_ticks_msec() - labor < 15000:
		if not captured_labor and float(GameState.project_status().remaining) < 5.1:
			captured_labor = true
			await _capture("05_real_player_labor")
		await get_tree().physics_frame
	_check(str(GameState.project_status().state) == "complete", "real player labor completes the ten-second project without builders")
	await _capture("06_completed_compact")
	# The returning craftsman physically follows his new route across several frames.
	var rami: Resident
	for resident in home._residents:
		if resident.resident_name == "Rami": rami = resident
	rami.position = site.workpoint() + Vector2(3.0, 0.4)
	rami._index = 0
	rami._wait = 0
	rami.set_physics_process(true)
	var before := rami.position
	await get_tree().create_timer(0.6).timeout
	var middle := rami.position
	await _capture("07_craftsman_movement")
	await get_tree().create_timer(0.6).timeout
	_check(before.distance_to(middle) > 0.1 and middle.distance_to(rami.position) > 0.1 and before.distance_to(rami.position) < 2.0, "craftsman walks continuously toward the workshop over consecutive intervals")
	game.open_map()
	await _capture("08_workshop_map")
	game.hud.hide_modals()
	game._on_modal_closed()
	game.open_shop("equipment", "Garrick")
	await _capture("09_unlocked_forge_compact")
	get_window().size = Vector2i(1280, 720)
	await _capture("10_unlocked_forge_desktop")
	game.hud.hide_modals()
	game._on_modal_closed()
	GameSettings.set_value("reduce_motion", true, false)
	GameSettings.set_value("effects_quality", "low", false)
	await _capture("11_completed_accessible")
	_check(site._label.visible and site._label.text.contains("licensed"), "essential completion feedback remains in low quality and Reduce Motion")

func _capture(label: String) -> void:
	for frame in 4: await get_tree().process_frame
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
