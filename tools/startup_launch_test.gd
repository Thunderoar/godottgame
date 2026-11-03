extends SceneTree
## Exercise normal startup in a fresh process without preloading Game's classes.
var _elapsed := 0.0
var _reported_hold := false
var _splash: WeakRef
var _capturing := false

func _initialize() -> void:
	call_deferred("_launch")

func _launch() -> void:
	if not load("res://tools/test_environment.gd").require_isolation():
		quit(1)
		return
	var packed = load(ProjectSettings.get_setting("application/run/main_scene"))
	var splash = packed.instantiate()
	_splash = weakref(splash)
	root.add_child(splash)
	current_scene = splash

func _process(delta: float) -> bool:
	_elapsed += delta
	if current_scene != null and current_scene.is_in_group("game"):
		var title = current_scene.get("title_screen")
		if is_instance_valid(title) and title.is_visible_in_tree() and _splash.get_ref() == null and not _capturing:
			var start = title.get("_start_button")
			if is_instance_valid(start) and start.is_visible_in_tree() and not start.disabled:
				_capturing = true
				call_deferred("_finish")
	elif _elapsed >= 8.0 and not _reported_hold and current_scene != null:
		_reported_hold = true
		print("Startup still waiting: movie_finished=%s load_active=%s handoff=%s focus_out=%s" % [current_scene.get("_movie_finished"), current_scene.get("_load_active"), current_scene.get("_handoff"), current_scene.get("_focus_out")])
	if _elapsed > 25.0:
		push_error("Startup did not reveal the main menu within 25 seconds")
		quit(1)
	return false

func _finish() -> void:
	if _elapsed < 3.0 or get_nodes_in_group("game").size() != 1 or current_scene.get("world") != null:
		push_error("Startup must finish its film and install exactly one Game at the menu")
		quit(1)
		return
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("TIDESWORN_TEST_ROOT").path_join("main-menu.png"))
	var title = current_scene.get("title_screen")
	title.get("_start_button").pressed.emit()
	await create_timer(0.5).timeout
	if int(title.get("current_page")) != 1 or not title.get("_begin_button").is_visible_in_tree():
		push_error("The revealed menu must respond to Start Game")
		quit(1)
		return
	print("--- startup launch: PASS ---")
	quit(0)
