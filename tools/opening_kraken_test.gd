extends Node
## Safe native review of the second beat, with real Next/Skip input.
var checks := 0
var failures := 0

func _ready() -> void:
	if not TestEnvironment.require_isolation(): get_tree().quit(1); return
	GameState.autosave_enabled = false
	var game := load("res://scenes/game.tscn").instantiate() as Game
	add_child(game)
	await get_tree().process_frame
	await OpeningKrakenChecks.run(game, _check)
	if DisplayServer.get_name() != "headless":
		var story := StorySequence.new()
		game.add_child(story)
		story.set_process(false)
		story.advance()
		for t in [0.0, 0.6, 1.5, 2.5, 3.5, 4.5, 5.8]:
			story._page_time = t
			await _capture(story, "kraken_%.1f" % t)
		GameSettings.set_reduce_motion(true, false)
		await _capture(story, "kraken_reduce_motion")
		GameSettings.set_reduce_motion(false, false)
		GameSettings.set_effects_quality("low", false)
		await _capture(story, "kraken_low_quality")
		GameSettings.set_effects_quality("high", false)
		await _tap(story._next)
		_check(story.page == 2 and not story._canvas.uses_kraken_shot(), "real Next touch exits the second beat")
		story.finish()
		await get_tree().process_frame
		story = StorySequence.new()
		game.add_child(story)
		story.set_process(false)
		story.advance()
		var completions := [0]
		story.completed.connect(func() -> void: completions[0] += 1)
		await _tap(story._skip)
		_check(completions[0] == 1, "real Skip touch completes the Kraken sequence once")
		_check(not Input.is_action_pressed("attack") and not Input.is_action_pressed("sprint"), "story touches leave no held combat action")
	print("--- opening kraken: %d checks, %s ---" % [checks, "PASS" if failures == 0 else "FAIL"])
	get_tree().quit(0 if failures == 0 else 1)

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("[OK] " if ok else "[FAIL] ", label)

func _tap(button: Button) -> void:
	# A newly constructed caption needs a layout frame before its native hit test.
	await get_tree().process_frame
	var point := get_viewport().get_final_transform() * button.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.index = 29
		event.position = point
		event.pressed = pressed
		Input.parse_input_event(event)
		await get_tree().process_frame

func _capture(story: StorySequence, label: String) -> void:
	story._canvas.queue_redraw()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var dir := OS.get_environment("TIDESWORN_TEST_ROOT").path_join("shots")
	DirAccess.make_dir_recursive_absolute(dir)
	var path := dir.path_join(label + ".png")
	_check(get_viewport().get_texture().get_image().save_png(path) == OK, "capture " + label)
	print("CAPTURE ", path)
