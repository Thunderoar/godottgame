extends Node
## Isolated native captures and actual mouse/touch story controls.
var checks := 0
var failures := 0

func _ready() -> void:
	if not TestEnvironment.require_isolation(): get_tree().quit(1); return
	# Windows can clamp a decorated 1600px review window to the monitor work area.
	if "--wide-review" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		get_window().borderless = true
		get_window().size = Vector2i(1600, 720)
		await get_tree().process_frame
		await get_tree().process_frame
		_check(get_viewport().get_texture().get_size() == Vector2(1600, 720), "wide review renders a full 1600x720 viewport")
	GameState.autosave_enabled = false
	var game := load("res://scenes/game.tscn").instantiate() as Game
	add_child(game)
	await get_tree().process_frame
	await OpeningCaptureChecks.run(game, _check)
	if DisplayServer.get_name() != "headless":
		GameSettings.set_reduce_motion(false, false)
		GameSettings.set_effects_quality("high", false)
		var campaign := GameState.campaign()
		var world_time := float(GameState.data.get("world_time", 0))
		var story := _story(game)
		for t in [0.0, 0.45, 0.95, 1.55, 1.8, 2.2, 2.65, 3.2, 3.7, 4.15, 4.65, 5.8]:
			story._page_time = t
			await _capture(story, "capture_%.2f" % t)
		story._caption_panel.hide()
		await _capture(story, "capture_without_caption")
		story._caption_panel.show()
		if "--sequence" in OS.get_cmdline_user_args():
			for frame in 73:
				story._page_time = float(frame) / 12
				await _capture(story, "motion_%03d" % frame)
		GameSettings.set_reduce_motion(true, false)
		await _capture(story, "capture_reduce_motion")
		GameSettings.set_reduce_motion(false, false)
		GameSettings.set_effects_quality("low", false)
		await _capture(story, "capture_low_quality")
		GameSettings.set_effects_quality("high", false)
		await _pointer(story._next, true)
		_check(story.page == 4 and not story._canvas.uses_capture_shot(), "real touch Next reaches the turtle rescue")
		await _capture(story, "following_turtle_rescue")
		story.finish()
		await get_tree().process_frame
		story = _story(game)
		var completed := [0]
		story.completed.connect(func() -> void: completed[0] += 1)
		await _pointer(story._skip, false)
		_check(completed[0] == 1, "real mouse Skip completes captivity exactly once")
		_check(not Input.is_action_pressed("attack") and not Input.is_action_pressed("sprint"), "capture controls leave no held combat actions")
		_check(GameState.campaign() == campaign and float(GameState.data.get("world_time", 0)) == world_time, "standalone capture viewing never mutates campaign or world time")
	print("--- opening capture: %d checks, %s ---" % [checks, "PASS" if failures == 0 else "FAIL"])
	get_tree().quit(0 if failures == 0 else 1)

func _story(game: Game) -> StorySequence:
	var story := StorySequence.new()
	game.add_child(story)
	story.set_process(false)
	for i in 3: story.advance()
	return story

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("[OK] " if ok else "[FAIL] ", label)

func _pointer(button: Button, touch: bool) -> void:
	await get_tree().process_frame
	var point := get_viewport().get_final_transform() * button.get_global_rect().get_center()
	for pressed in [true, false]:
		var event: InputEvent
		if touch:
			var screen := InputEventScreenTouch.new()
			screen.index = 31
			screen.position = point
			screen.pressed = pressed
			event = screen
		else:
			var mouse := InputEventMouseButton.new()
			mouse.button_index = MOUSE_BUTTON_LEFT
			mouse.position = point
			mouse.pressed = pressed
			event = mouse
		Input.parse_input_event(event)
		await get_tree().process_frame

func _capture(story: StorySequence, label: String) -> void:
	story._canvas.queue_redraw()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var directory := OS.get_environment("TIDESWORN_TEST_ROOT").path_join("shots")
	DirAccess.make_dir_recursive_absolute(directory)
	var path := directory.path_join(label + ".png")
	_check(get_viewport().get_texture().get_image().save_png(path) == OK, "capture " + label)
	print("CAPTURE ", path)
