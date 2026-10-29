extends Node
## Isolated native/headless first-beat review. Captures always go outside res://.
var checks := 0
var fails := 0

func _ready() -> void:
	if not TestEnvironment.require_isolation(): get_tree().quit(1); return
	GameState.autosave_enabled = false
	var game := load("res://scenes/game.tscn").instantiate() as Game
	add_child(game)
	await get_tree().process_frame
	await OpeningFishingChecks.run(game, _check)
	if DisplayServer.get_name() != "headless":
		await _capture_shot(game)
	print("--- opening fishing: %d checks, %s ---" % [checks, "PASS" if fails == 0 else "FAIL"])
	get_tree().quit(0 if fails == 0 else 1)

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: fails += 1
	print("[OK] " if ok else "[FAIL] ", label)

func _capture_shot(game: Game) -> void:
	var story := StorySequence.new()
	game.add_child(story)
	story.set_process(false)
	var reduced := GameSettings.reduce_motion()
	var quality := GameSettings.effects_quality()
	GameSettings.set_reduce_motion(false, false)
	GameSettings.set_effects_quality("high", false)
	for t in [0.5, 2.0, 3.5, 5.5]:
		story._page_time = t
		await _capture(story, "first_beat_%.1f" % t)
	story._page_time = 3.5
	GameSettings.set_reduce_motion(true, false)
	await _capture(story, "first_beat_reduce_motion")
	GameSettings.set_reduce_motion(false, false)
	GameSettings.set_effects_quality("low", false)
	await _capture(story, "first_beat_low")
	GameSettings.set_effects_quality("high", false)
	story.advance()
	story._page_time = 0.5
	await _capture(story, "second_beat_cut")
	story.finish()
	GameSettings.set_reduce_motion(reduced, false)
	GameSettings.set_effects_quality(quality, false)
	await get_tree().process_frame
	await _check_touch_navigation(game)
	await _capture_handoff(game)

func _capture_handoff(game: Game) -> void:
	var reduced := GameSettings.reduce_motion()
	GameSettings.set_reduce_motion(false, false)
	var title := game.title_screen
	var other := CanvasLayer.new()
	game.add_child(other)
	game._remove_title_if_owner(other)
	_check(game.title_screen == title, "stale transition ownership cannot remove the current title")
	other.queue_free()
	# Confirmed fresh-journey fixture; the separate title suite covers replacement.
	title.save_available = false
	title._open_heroes()
	# Real input must wait for the page track to arrive before tapping Begin.
	await get_tree().create_timer(TitleScreen.PAGE_SLIDE_SECONDS + 0.12).timeout
	await _tap(title._begin_button)
	var story := _active_story(game)
	_check(story != null and story._arrival_active and game.title_screen != null, "real Begin touch keeps Adam selection visible as departure starts")
	if story == null: return
	story.set_process(false)
	var serial := GameState.journey_serial
	game._on_character_selected("adam")
	game._on_continue_requested()
	_check(GameState.journey_serial == serial and _story_count(game) == 1, "duplicate start/continue cannot replace an in-flight opening")
	_check(not game.hud.visible and game._input_locked and game.world == null, "handoff has no HUD flash or prematurely built village")
	for t in [0.14, 0.28, 0.4, 0.7, 0.95, 1.04, 1.13, 1.37, 1.59]:
		story._process(maxf(0, t - story._arrival_time))
		if is_equal_approx(t, 0.7):
			var opening := story.opening_loader()
			_check(opening != null and opening.active and opening.cover.modulate.a == 1.0 and opening.destination.text == "Adam's Journey", "real Begin handoff visibly shows the existing PB loading screen")
		await _capture(story, "handoff_%.2f" % t)
	_check(game.title_screen == null and story.opening_loader() == null and not story._arrival_active and story._page_time == 0, "title and loader retire before the six-second reading time starts")
	_check(float(GameState.data.world_time) == 0.0 and not GameState.campaign().intro_seen, "arrival neither advances village time nor prematurely completes the introduction")
	await _tap(story._next)
	_check(story.page == 1, "Next responds normally after the revealed caption is readable")
	await _tap(_button_with_text(story, "Skip scene"))
	while game._transitioning or not game.world is Lobby: await get_tree().process_frame
	_check(GameState.campaign().intro_seen and not game._input_locked and game.hud.tutorial_guide.visible, "post-reveal Skip reaches the unlocked village and tutorial")
	await game.return_to_title()
	game.title_screen._request_continue()
	_check(_active_story(game) == null, "Continue after a seen intro does not replay the arrival")
	while game._transitioning or not game.world is Lobby: await get_tree().process_frame
	# Unfinished intro is a real Continue path, with the shorter accessibility timing.
	GameState.data.campaign.intro_seen = false
	GameState.save_game()
	await game.return_to_title()
	GameSettings.set_reduce_motion(true, false)
	game.title_screen._request_continue()
	story = _active_story(game)
	_check(story != null and story._arrival_active and story._arrival_reduced, "Continue into an unfinished intro uses the reduced-motion handoff")
	if story != null:
		story.set_process(false)
		for t in [0.06, 0.12, 0.24, 0.5, 0.79, 0.88, 0.97]:
			story._process(maxf(0, t - story._arrival_time))
			await _capture(story, "handoff_reduced_%.2f" % t)
		_check(not story._arrival_active and story.opening_loader() == null and story._page_time == 0 and game.title_screen == null, "reduced loading handoff fully reveals without shortening the first beat")
		story.finish()
		while game._transitioning or not game.world is Lobby: await get_tree().process_frame
	GameSettings.set_reduce_motion(reduced, false)

func _active_story(game: Game) -> StorySequence:
	for node in game.get_children():
		if node is StorySequence and not node.is_queued_for_deletion(): return node
	return null

func _story_count(game: Game) -> int:
	var count := 0
	for node in game.get_children():
		if node is StorySequence and not node.is_queued_for_deletion(): count += 1
	return count

func _check_touch_navigation(game: Game) -> void:
	var story := StorySequence.new()
	game.add_child(story)
	story.set_process(false)
	await get_tree().process_frame
	await _tap(story._next)
	_check(story.page == 1 and not story._canvas.uses_fishing_shot(), "real screen touch on Next advances out of fishing")
	var done := [0]
	story.completed.connect(func() -> void: done[0] += 1)
	await _tap(_button_with_text(story, "Skip scene"))
	_check(done[0] == 1, "real screen touch on Skip completes once")
	var held := Input.is_action_pressed("attack") or Input.is_action_pressed("sprint")
	_check(not held, "story navigation leaves no held combat/sprint input")

func _tap(button: Button) -> void:
	var point := get_viewport().get_final_transform() * button.get_global_rect().get_center()
	var touch := InputEventScreenTouch.new()
	touch.index = 29
	touch.position = point
	touch.pressed = true
	Input.parse_input_event(touch)
	await get_tree().process_frame
	var release := InputEventScreenTouch.new()
	release.index = 29
	release.position = point
	release.pressed = false
	Input.parse_input_event(release)
	await get_tree().process_frame

func _button_with_text(node: Node, text: String) -> Button:
	if node is Button and node.text == text: return node
	for child in node.get_children():
		var found := _button_with_text(child, text)
		if found != null: return found
	return null

func _capture(story: StorySequence, name: String) -> void:
	await get_tree().process_frame
	story._canvas.queue_redraw()
	await RenderingServer.frame_post_draw
	var directory := OS.get_environment("TIDESWORN_TEST_ROOT").path_join("shots")
	DirAccess.make_dir_recursive_absolute(directory)
	var path := directory.path_join(name + ".png")
	var result := get_viewport().get_texture().get_image().save_png(path)
	_check(result == OK, "native capture " + name)
	print("CAPTURE ", path)
