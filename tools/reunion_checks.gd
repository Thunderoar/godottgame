extends RefCounted
## Real Game-owned reunion, reader-paced input, pending safety and dock-only epilogue.

static func run(game: Game, check: Callable, capture: Callable = Callable()) -> void:
	var saved := GameState.data.duplicate(true)
	var autosave := GameState.autosave_enabled
	var ticking := game.is_processing()
	var quests := game._side_quest_auto_enabled
	game.set_process(false)
	game._side_quest_auto_enabled = false
	GameState.autosave_enabled = false
	game.hud.hide_modals()
	game._clear_world()
	await game.get_tree().process_frame
	GameState.data = GameState._make_default("adam")
	GameState.data.portal_origin.opened = true
	GameState.data.campaign.intro_seen = true
	GameState.data.campaign.dock_welcome_seen = true
	GameState.rescue_friend("mei_ling")
	await game._load_lobby(false)
	await game.get_tree().process_frame
	check.call(game._active_story == null, "one rescued friend cannot start the three-person conversation")
	GameState.rescue_friend("arjun")
	game._arjun_returning = true
	game._check_campaign_ending()
	check.call(game._active_story == null, "reunion waits until Arjun has finished real disembarkation")
	game._arjun_returning = false
	for field in ["_sailing","_transitioning","_defeat_pending","_input_locked"]:
		game.set(field,true)
		game._check_campaign_ending()
		check.call(game._active_story == null, "pending reunion respects %s ownership" % field)
		game.set(field,false)
	GameState.data.recovery_active = true
	game._check_campaign_ending()
	check.call(game._active_story == null, "recovery defers the reunion without consuming its completion")
	GameState.data.recovery_active = false
	game.hud.mission_panel.open_missions()
	game._check_campaign_ending()
	check.call(game._active_story == null, "an open modal is not interrupted by the reunion")
	game.hud.hide_modals()
	game._on_modal_closed()
	var threat := Enemy.new()
	threat.kind = "fire"
	threat.position = game.player().position+Vector2(2,0)
	game.world.add_child(threat)
	threat.set_physics_process(false)
	game._check_campaign_ending()
	check.call(game._active_story == null and not bool(GameState.campaign().ending_seen), "nearby danger leaves the reunion pending rather than pausing a fight")
	threat.queue_free()
	await game.get_tree().process_frame
	var before := GameState.data.duplicate(true)
	var player_at := game.player().position
	game._process(0.8)
	var story := game._active_story
	check.call(story != null and story.kind == "ending", "safe retry starts the pending reunion automatically")
	if story == null: return
	story.set_process(false)
	check.call(game.world.process_mode == Node.PROCESS_MODE_DISABLED and game.player().controls_locked and not game.hud.visible, "conversation owns world, controls and HUD")
	story._process(120)
	check.call(story.page == 0 and story._reunion_text_done, "a long reading pause never auto-advances reunion dialogue")
	check.call(not bool(GameState.campaign().ending_seen) and GameState.data.world_time == before.world_time, "reading dialogue cannot mark completion or advance the village clock")
	var speakers: Array[String] = []
	for row in ReunionDialogueDB.TURNS:
		if str(row.speaker) not in speakers: speakers.append(str(row.speaker))
	check.call(speakers.size() == 3 and speakers.has("adam") and speakers.has("arjun") and speakers.has("mei_ling"), "all three friends participate in the approved conversation")
	var copy := ReunionDialogueDB.turn(0)
	copy.text = "changed"
	check.call(ReunionDialogueDB.turn(0).text == "You're both here.", "dialogue accessors protect the authored script from callers")
	check.call(not " ".join(story.lines()).contains("THE END") and not GameState.campaign_objective().contains("new home"), "chapter close leaves the next journey open without permanent-settlement wording")
	if capture.is_valid():
		for time in [0.2,0.8,1.4,1.8]:
			story.page = 0
			story._reunion_beat_time = float(time)
			story._render()
			story._caption.visible_characters = -1
			story._reunion_text_done = true
			story._next.text = "Next"
			story._canvas.queue_redraw()
			await capture.call("reunion_settle_%02d" % int(time*10))
		for index in [0,4,6,9,12,14,18,23,24,27,29,30]:
			story.page = index
			story._page_time = 3
			story._reunion_beat_time = 2
			story._render()
			story._caption.visible_characters = -1
			story._reunion_text_done = true
			story._next.text = "Continue" if index == ReunionDialogueDB.TURNS.size() else "Next"
			story._process(0)
			story._canvas.queue_redraw()
			await capture.call("reunion_%02d" % index)
		for time in [0.2,0.8,1.5]:
			story.page = 29
			story._reunion_beat_time = float(time)
			story._render()
			story._caption.visible_characters = -1
			story._reunion_text_done = true
			story._next.text = "Next"
			story._canvas.queue_redraw()
			await capture.call("reunion_rise_%02d" % int(time*10))
		story.reunion_night = true
		story.page = 9
		story._render()
		story._caption.visible_characters = -1
		story._reunion_text_done = true
		story._next.text = "Next"
		story._mei_reduced = true
		story._canvas.queue_redraw()
		await capture.call("reunion_night_reduced")
		story.page = 30
		story._render()
		story._canvas.queue_redraw()
		await capture.call("reunion_dock_night")
		story._mei_reduced = false
		story.reunion_night = false
	var motion := GameSettings.reduce_motion()
	var quality := GameSettings.effects_quality()
	var mute := GameSettings.mute_all()
	story.page = 9
	story._page_time = 0
	story._render()
	GameSettings.set_value("reduce_motion",true,false)
	GameSettings.set_value("effects_quality","low",false)
	GameSettings.set_value("mute_all",true,false)
	story._process(1)
	check.call(story.page == 9 and story._mei_reduced and not story._reunion_voice.playing, "live motion, low effects and mute preserve dialogue and stop its owned voice")
	GameSettings.set_value("reduce_motion",motion,false)
	GameSettings.set_value("effects_quality",quality,false)
	GameSettings.set_value("mute_all",mute,false)
	story._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	check.call(not story._reunion_voice.playing, "focus loss stops the owned dialogue voice")
	story._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_IN)
	story.page = 0
	story._page_time = 0
	story._render()
	await _pointer(game,story._next,false)
	check.call(story.page == 0 and story._reunion_text_done, "first mouse Next reveals the line without skipping it (page %d, revealed %s, armed %s, disabled %s)" % [story.page,story._reunion_text_done,story._mei_input_armed,story._next.disabled])
	story._process(0.25)
	await _pointer(game,story._next,true)
	check.call(story.page == 1, "primary touch and emulated mouse advance exactly one dialogue turn (page %d)" % story.page)
	story._process(0.25)
	story._next.grab_focus()
	await _enter(game)
	check.call(story.page == 1 and story._reunion_text_done, "keyboard activation reveals the current line first")
	story._process(0.25)
	await _enter(game)
	check.call(story.page == 2, "a fresh keyboard activation advances the revealed line")
	story._next.release_focus()
	story._process(0.25)
	await _pointer(game,story._skip,true)
	check.call(story.page == ReunionDialogueDB.TURNS.size() and not story._skip.visible and not bool(GameState.campaign().ending_seen), "Skip conversation reaches the dock tag without prematurely completing the scene")
	story.advance()
	check.call(game._story_active, "dock tag cannot be dismissed before its preparation beat")
	story._process(2.1)
	await _pointer(game,story._next,false)
	await game.get_tree().process_frame
	check.call(not game._story_active and bool(GameState.campaign().ending_seen) and game.hud.visible and not game.player().controls_locked, "dock Continue saves the reunion and restores normal village play")
	check.call(game.player().position == player_at and not game._sailing and GameState.data.expedition == before.expedition and GameState.data.campaign.ocean_stage == before.campaign.ocean_stage and GameState.gold() == int(before.gold), "dock illustration cannot teleport actors, sail, alter ocean checkpoints or pay rewards")
	GameState.save_game()
	check.call(GameState.load_game() and bool(GameState.campaign().ending_seen), "reunion completion survives an actual JSON reload")
	game._check_campaign_ending()
	check.call(game._active_story == null, "completed reunion does not repeat on a later safety check")
	# Every dialogue position can be skipped through the same non-sailing tag.
	for index in ReunionDialogueDB.TURNS.size():
		GameState.data.campaign.ending_seen = false
		game.play_story("ending")
		story = game._active_story
		story.set_process(false)
		story.page = index
		story._render()
		story._process(0.4)
		story._on_skip_pressed()
		var tagged := story.page == ReunionDialogueDB.TURNS.size() and not bool(GameState.campaign().ending_seen)
		story._process(2.1)
		story.advance()
		await game.get_tree().process_frame
		check.call(tagged and not game._story_active and bool(GameState.campaign().ending_seen), "Skip at dialogue turn %d retains the dock tag and completes once" % (index+1))
	GameState.data.campaign.ending_seen = false
	game.play_story("ending")
	story = game._active_story
	story.set_process(false)
	for index in ReunionDialogueDB.TURNS.size():
		story.advance() # reveal
		story.advance() # next turn
	story._process(2.1)
	story.advance()
	await game.get_tree().process_frame
	check.call(bool(GameState.campaign().ending_seen) and not game._story_active, "reading every dialogue turn naturally reaches and completes the dock tag")
	GameState.data.campaign.ending_seen = false
	game.play_story("ending")
	game._clear_world()
	await game.get_tree().process_frame
	check.call(not bool(GameState.campaign().ending_seen) and not game._story_active, "world replacement cancels the conversation without consuming completion")
	# The other rescue order also uses the same saved completion gate.
	GameState.data = GameState._make_default("adam")
	GameState.data.portal_origin.opened = true
	GameState.data.campaign.intro_seen = true
	GameState.data.campaign.dock_welcome_seen = true
	GameState.rescue_friend("arjun")
	await game._load_lobby(false)
	await game.get_tree().process_frame
	check.call(game._active_story == null, "Arjun-first journey also waits for the missing friend")
	GameState.rescue_friend("mei_ling")
	game._check_campaign_ending()
	check.call(game._active_story != null and game._active_story.kind == "ending", "Mei Ling-second journey starts the same shared conversation")
	if game._active_story != null: game._active_story.finish()
	GameState.data = saved
	GameState._emit_all()
	await game._load_lobby(false)
	GameState.autosave_enabled = autosave
	game._side_quest_auto_enabled = quests
	game.set_process(ticking)

static func _pointer(game: Game, button: Button, touch: bool) -> void:
	# Headless runs reach this helper before the first container layout pass;
	# captures already yield frames. Inject at the settled button in either mode.
	await game.get_tree().process_frame
	await game.get_tree().process_frame
	var at := game.get_viewport().get_final_transform()*button.get_global_rect().get_center()
	for pressed in [true,false]:
		if touch:
			var event := InputEventScreenTouch.new()
			event.index = 0
			event.position = at
			event.pressed = pressed
			Input.parse_input_event(event)
		else:
			var event := InputEventMouseButton.new()
			event.button_index = MOUSE_BUTTON_LEFT
			event.position = at
			event.pressed = pressed
			Input.parse_input_event(event)
		await game.get_tree().process_frame

static func _enter(game: Game) -> void:
	for pressed in [true,false]:
		var event := InputEventKey.new()
		event.keycode = KEY_ENTER
		event.physical_keycode = KEY_ENTER
		event.pressed = pressed
		Input.parse_input_event(event)
		await game.get_tree().process_frame
