extends Node
var checks := 0
var failures := 0

func _ready() -> void:
	if not TestEnvironment.require_isolation(): get_tree().quit(1); return
	GameState.autosave_enabled = false
	if "--wide-review" in OS.get_cmdline_user_args():
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		DisplayServer.window_set_size(Vector2i(1600, 720))
	var game := load("res://scenes/game.tscn").instantiate() as Game
	add_child(game)
	await get_tree().process_frame
	await OpeningWelcomeChecks.run(game, _check)
	if DisplayServer.get_name() != "headless":
		GameSettings.set_reduce_motion(false, false)
		GameSettings.set_effects_quality("high", false)
		var story := _story(game)
		story.page = 6
		story._render()
		await _capture(story, "preceding_promise")
		await _pointer(story._next, true)
		_check(story.page == StorySequence.INTRO_WELCOME_PAGE and story._next.text == "Continue", "real touch Next enters the eighth welcome before completion")
		for t in [0.0, 0.7, 1.5, 1.85, 2.2, 2.8, 3.4, 4.1, 4.95, 5.8]:
			story._page_time = t
			await _capture(story, "welcome_%.2f" % t)
		if "--sequence" in OS.get_cmdline_user_args():
			for i in 73:
				story._page_time = float(i) / 12
				await _capture(story, "motion_%03d" % i)
		GameSettings.set_reduce_motion(true, false)
		await _capture(story, "welcome_reduce_motion")
		GameSettings.set_reduce_motion(false, false)
		GameSettings.set_effects_quality("low", false)
		await _capture(story, "welcome_low_quality")
		GameSettings.set_effects_quality("high", false)
		var completed := [0]
		story.completed.connect(func() -> void: completed[0] += 1)
		await _pointer(story._next, false)
		_check(completed[0] == 1, "real mouse Continue completes the eighth beat once")
		for touch in [false, true]:
			await get_tree().process_frame
			story = _story(game)
			var skipped := [0]
			story.completed.connect(func() -> void: skipped[0] += 1)
			await _pointer(story._skip, touch)
			_check(skipped[0] == 1, "real %s Skip releases the village welcome once" % ("touch" if touch else "mouse"))
		_check(not Input.is_action_pressed("attack") and not Input.is_action_pressed("sprint"), "welcome pointer releases leave no held combat controls")
		await _test_gameplay_handoff(game)
	print("--- opening welcome: %d checks, %s ---" % [checks, "PASS" if failures == 0 else "FAIL"])
	get_tree().quit(0 if failures == 0 else 1)

func _test_gameplay_handoff(game: Game) -> void:
	game._on_character_selected("adam")
	await get_tree().process_frame
	var story: StorySequence
	for node in game.get_children():
		if node is StorySequence and not node.is_queued_for_deletion(): story = node
	_check(story != null and game.world == null and not game.hud.visible, "new journey constructs no active village behind its introduction")
	if story == null: return
	story.set_process(false)
	story._process(2.0)
	for i in StorySequence.INTRO_WELCOME_PAGE: story.advance()
	_check(not bool(GameState.campaign().get("intro_seen")) and game._story_active and not game.hud.visible, "intro completion stays unsaved and HUD hidden throughout the eighth beat")
	await _pointer(story._next, true)
	for i in 160:
		if game.world is Lobby and not game._transitioning: break
		await get_tree().create_timer(0.05).timeout
	_check(game.world is Lobby and bool(GameState.campaign().get("intro_seen")) and not game._story_active, "touch Continue hands the completed welcome into the real village")
	_check(game.hud.visible and game.hud.tutorial_guide.visible and game.player() != null and not game.player().controls_locked, "village handoff restores movement and starts its existing tutorial")
	var lobby := game.world as Lobby
	var deck := lobby._layout.world_footprint("jetty_deck")
	_check(lobby.arrive_at_dock and game.player().position.distance_to(lobby._layout.approach("jetty_deck")) < 0.05, "touch Continue starts playable Adam at the actual dock anchor")
	_check(deck.grow(-0.26).has_point(game.player().position) and deck.grow(-0.18).has_point(lobby.pet.position), "player and companion bodies fit safely within the dock planks")
	_check(lobby.camera.target == game.player() and lobby.camera.position.distance_to(game.player().position + Vector2(0, -1)) < 1.3, "the first gameplay camera is already following Adam at the dock")
	_check(GameState.mission_step() == 0, "arriving at the dock never falsely completes Learn to move")
	var planner := ResidentRoutes.new(lobby)
	_check(planner.point_clear(game.player().position) and planner.segment_clear(game.player().position, lobby._layout.approach("jetty_landing")), "the first player-sized dock position and route ashore are physically clear")
	await RenderingServer.frame_post_draw
	_capture_view("village_handoff")
	var previous := game.player().position
	Input.action_press("move_right")
	var continuous := true
	for i in 65:
		await get_tree().physics_frame
		var current := game.player().position
		continuous = continuous and current.x >= previous.x - 0.01 and current.distance_to(previous) < 0.3
		previous = current
		if i in [0, 20, 40, 64]:
			await RenderingServer.frame_post_draw
			_capture_view("dock_walk_%02d" % i)
	Input.action_release("move_right")
	_check(continuous and game.player().position.x > lobby._layout.approach("jetty_deck").x + 3.0, "held movement walks continuously off the starting dock toward the village")
	_check(GameState.mission_step() > 0, "the first lesson completes through actual movement from the dock")
	# An interrupted introduction takes the same first-arrival route on Continue.
	GameState.data.campaign.intro_seen = false
	GameState.save_game()
	game._clear_world()
	game._on_continue_requested()
	await get_tree().process_frame
	var resumed: StorySequence
	for node in game.get_children():
		if node is StorySequence and not node.is_queued_for_deletion(): resumed = node
	_check(resumed != null, "Continue replays an interrupted introduction before first arrival")
	if resumed != null: resumed.finish()
	for i in 160:
		if game.world is Lobby and not game._transitioning: break
		await get_tree().create_timer(0.05).timeout
	_check(game.world is Lobby and game.world.arrive_at_dock and game.player().position.distance_to(game.world._layout.approach("jetty_deck")) < 0.05, "Continue after an unfinished intro also places Adam on the dock")
	GameState.save_game()
	game._clear_world()
	game._on_continue_requested()
	for i in 160:
		if game.world is Lobby and not game._transitioning: break
		await get_tree().create_timer(0.05).timeout
	_check(game.world is Lobby and not game.world.arrive_at_dock and game.player().position.distance_to(game.world.get_spawn_position()) < 0.05, "Continue after a completed intro keeps the existing saved-journey home arrival")

func _story(game: Game) -> StorySequence:
	var story := StorySequence.new()
	game.add_child(story)
	story.set_process(false)
	for i in StorySequence.INTRO_WELCOME_PAGE: story.advance()
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
			screen.index = 33
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
	_capture_view(label)

func _capture_view(label: String) -> void:
	var directory := OS.get_environment("TIDESWORN_TEST_ROOT").path_join("shots")
	DirAccess.make_dir_recursive_absolute(directory)
	var path := directory.path_join(label + ".png")
	_check(get_viewport().get_texture().get_image().save_png(path) == OK, "capture " + label)
	print("CAPTURE ", path)
