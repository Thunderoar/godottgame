extends Node
var checks := 0
var failures := 0
func _ready() -> void:
	if not TestEnvironment.require_isolation(): get_tree().quit(1); return
	GameState.autosave_enabled = false
	var game := load("res://scenes/game.tscn").instantiate() as Game
	add_child(game)
	await get_tree().process_frame
	await OpeningRescueChecks.run(game, _check)
	if DisplayServer.get_name() != "headless":
		GameSettings.set_reduce_motion(false, false)
		GameSettings.set_effects_quality("high", false)
		var campaign := GameState.campaign()
		var world_time := float(GameState.data.get("world_time", 0))
		var story := _story(game)
		for t in [0.0, 0.7, 1.25, 1.7, 2.1, 2.3, 3.3, 4.25, 4.4, 4.8, 5.15, 5.8]:
			story._page_time = t
			await _capture(story, "rescue_%.2f" % t)
		if "--sequence" in OS.get_cmdline_user_args():
			for i in 73:
				story._page_time = float(i) / 12
				await _capture(story, "motion_%03d" % i)
		GameSettings.set_reduce_motion(true, false)
		await _capture(story, "rescue_reduce_motion")
		GameSettings.set_reduce_motion(false, false)
		GameSettings.set_effects_quality("low", false)
		await _capture(story, "rescue_low_quality")
		GameSettings.set_effects_quality("high", false)
		await _pointer(story._next, true)
		_check(story.page == 6 and not story._canvas.uses_rescue_shot(), "real touch Next reaches Adam's final promise")
		_check(story._canvas.uses_rescue_epilogue() and story._canvas.rescue_state().ashore, "real Next preserves the completed safe arrival beneath the final caption")
		story._page_time = 0
		await _capture(story, "following_promise_start")
		story._page_time = 5.8
		await _capture(story, "following_promise_end")
		story.finish()
		await get_tree().process_frame
		story = _story(game)
		var completed := [0]
		story.completed.connect(func() -> void: completed[0] += 1)
		await _pointer(story._skip, false)
		_check(completed[0] == 1, "real mouse Skip completes rescue once")
		_check(not Input.is_action_pressed("attack") and not Input.is_action_pressed("sprint"), "rescue controls leave no held combat actions")
		await get_tree().process_frame
		story = _story(game)
		await _pointer(story._next, false)
		_check(story.page == 6, "real mouse Next reaches the final promise")
		story.finish()
		await get_tree().process_frame
		story = _story(game)
		var touch_completed := [0]
		story.completed.connect(func() -> void: touch_completed[0] += 1)
		await _pointer(story._skip, true)
		_check(touch_completed[0] == 1, "real touch Skip completes rescue once")
		_check(GameState.campaign() == campaign and float(GameState.data.get("world_time", 0)) == world_time, "standalone rescue never mutates campaign or world time")
	print("--- opening rescue: %d checks, %s ---" % [checks, "PASS" if failures == 0 else "FAIL"])
	get_tree().quit(0 if failures == 0 else 1)
func _story(game: Game) -> StorySequence:
	var story := StorySequence.new()
	game.add_child(story)
	story.set_process(false)
	for i in StorySequence.INTRO_RESCUE_PAGE: story.advance()
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
			screen.index = 32
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
