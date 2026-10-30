extends RefCounted
## Exercise real story ownership plus finite-pose geometry and rendered beat captures.

static func inspect_story(game: Game, realm: TwilightRealm, story: StorySequence, check: Callable, capture: Callable) -> void:
	story.set_process(false)
	var gold := GameState.gold()
	var diamonds := GameState.diamonds()
	var before_clock := float(GameState.data.world_time)
	check.call(story.lines().size() == 7 and story._canvas._mei != null, "Mei Ling rescue uses seven authored beats rather than the generic portal slide")
	check.call(is_equal_approx(MeiLingRescueRenderer.DURATIONS.reduce(func(total: float, value: float) -> float: return total + value, 0.0),24.0), "rescue has its own 24-second timeline without changing other stories")
	check.call(story._next.disabled and story._skip.disabled, "killing input cannot immediately skip the rescue")
	Input.action_press("attack")
	story._process(0.4)
	check.call(story._skip.disabled, "held combat attack keeps rescue buttons guarded")
	Input.action_release("attack")
	story._process(0.01)
	check.call(not story._skip.disabled, "releasing combat input restores story controls")
	check.call(story.lines()[4].contains("I'm still looking") and not story._mei_arjun_rescued, "Mei Ling-first dialogue does not claim Arjun is safe")
	story._mei_arjun_rescued = true
	check.call(story.lines()[4].contains("He's safe in BESUT"), "Arjun-first dialogue recognizes his actual rescue")
	story._mei_arjun_rescued = false
	var stepping_safe := true
	var smooth := true
	var previous := MeiLingRescueRenderer.sample(2, 0, false, "high", false)
	for frame in 61:
		var state := MeiLingRescueRenderer.sample(2, float(frame)/20, false, "high", false)
		if state.mei != previous.mei and float(state.gate) < 1: stepping_safe = false
		if Vector2(state.mei).distance_to(previous.mei) > 3: smooth = false
		previous = state
	check.call(stepping_safe and smooth, "consecutive release frames clear the gate before grounded steps, without teleporting")
	var contact := MeiLingRescueRenderer.sample(3, 3.3, false, "high", false)
	check.call(contact.contact and contact.adam_pose == MeiLingRescueArt.Pose.REACH and contact.mei_pose == MeiLingRescueArt.Pose.REACH and absf((float(contact.adam.x)+18)-(float(contact.mei.x)-18)) < 1, "both reaching hands meet at the reunion contact pose")
	check.call(not MeiLingRescueRenderer.sample(5,3,false,"high",false).arjun and MeiLingRescueRenderer.sample(5,3,false,"high",true).arjun, "village insert includes Arjun only after his independent rescue")
	var original := OpeningCaptureArt.hero("mei_ling",0).get_image().get_data()
	MeiLingRescueArt.hero("mei_ling",MeiLingRescueArt.Pose.REACH,true)
	check.call(original == OpeningCaptureArt.hero("mei_ling",0).get_image().get_data(), "rescue poses do not repaint shared opening character pixels")
	for beat in 7:
		story.page = beat
		story._page_time = float(MeiLingRescueRenderer.DURATIONS[beat]) * 0.8
		story._render()
		story._canvas.queue_redraw()
		var normal := MeiLingRescueRenderer.sample(beat, story._page_time, false, "high", false)
		var reduced := MeiLingRescueRenderer.sample(beat, story._page_time, true, "low", false)
		check.call(normal.beat == reduced.beat and normal.village == reduced.village and reduced.ash == 4, "beat %d remains readable in reduced motion and low effects" % (beat+1))
		if capture.is_valid(): await capture.call("animatic_%02d" % (beat+1))
	if capture.is_valid():
		# Consecutive action frames, not just endpoints, for visual continuity review.
		for pair in [[2,0.8],[2,1.1],[2,1.6],[3,2.7],[3,3.2],[4,3.5],[4,4.3]]:
			story.page = int(pair[0])
			story._page_time = float(pair[1])
			story._render()
			story._canvas.queue_redraw()
			await capture.call("motion_%d_%02d" % [int(pair[0]),roundi(float(pair[1])*10)])
		story.page = 5
		story._page_time = 3.5
		story._mei_arjun_rescued = true
		story._render()
		story._canvas.queue_redraw()
		await capture.call("animatic_arjun_home")
		story._mei_arjun_rescued = false
		story._mei_reduced = true
		story.page = 3
		story._render()
		story._canvas.queue_redraw()
		await capture.call("animatic_reduced")
		story._mei_reduced = false
	var old_motion := GameSettings.reduce_motion()
	var old_quality := GameSettings.effects_quality()
	var old_mute: bool = GameSettings.get_value("mute_all")
	story.page = 3
	story._page_time = 2
	GameSettings.set_value("reduce_motion",true,false)
	GameSettings.set_value("effects_quality","low",false)
	GameSettings.set_value("mute_all",true,false)
	story._process(0.01)
	check.call(story._mei_reduced and story.page == 3 and realm.process_mode == Node.PROCESS_MODE_DISABLED and GameSettings.effects_quality() == "low", "live Reduce Motion, low effects and mute preserve the current rescue beat and ownership")
	GameSettings.set_value("reduce_motion",false,false)
	story._process(0.01)
	check.call(story._mei_reduced, "turning motion back on does not rewind a composed rescue shot")
	GameSettings.set_value("reduce_motion",old_motion,false)
	GameSettings.set_value("effects_quality",old_quality,false)
	GameSettings.set_value("mute_all",old_mute,false)
	story._mei_reduced = old_motion
	check.call(game.world == realm and realm.process_mode == Node.PROCESS_MODE_DISABLED and is_equal_approx(float(GameState.data.world_time),before_clock), "all rescue beats leave the real world and village clock suspended")
	check.call(GameState.gold() == gold and GameState.diamonds() == diamonds and bool(GameState.campaign().mei_ling_rescued), "rendering both branches and advancing shots cannot change saved rescue rewards")
	story.page = 0
	story._page_time = 0
	story._render()
	for pressed in [true,false]:
		var mouse := InputEventMouseButton.new()
		mouse.button_index = MOUSE_BUTTON_LEFT
		mouse.position = game.get_viewport().get_final_transform() * story._next.get_global_rect().get_center()
		mouse.pressed = pressed
		Input.parse_input_event(mouse)
		await game.get_tree().process_frame
	check.call(story.page == 1 and story._page_time == 0, "actual mouse Next moves to the next authored beat boundary")
	story._process(0.25)
	for pressed in [true,false]:
		var touch := InputEventScreenTouch.new()
		touch.index = 0
		touch.position = game.get_viewport().get_final_transform() * story._next.get_global_rect().get_center()
		touch.pressed = pressed
		Input.parse_input_event(touch)
		await game.get_tree().process_frame
	check.call(story.page == 2, "actual touch Next advances exactly one beat and releases (page %d)" % story.page)
	story._process(0.25)
	story._next.grab_focus()
	for pressed in [true,false]:
		var key := InputEventKey.new()
		key.keycode = KEY_ENTER
		key.physical_keycode = KEY_ENTER
		key.pressed = pressed
		Input.parse_input_event(key)
		await game.get_tree().process_frame
	check.call(story.page == 3, "focused rescue Next supports keyboard activation (page %d)" % story.page)
	story._next.release_focus()
	story.set_process(true)

static func completion_paths(game: Game, check: Callable) -> void:
	var realm := game.world as TwilightRealm
	var gold := GameState.gold()
	# Every skip position restores the actual Game-owned suspension exactly once.
	for beat in 7:
		game.play_story("mei")
		var story := game._active_story
		story.set_process(false)
		story.page = beat
		story._render()
		story.finish()
		story.finish()
		await game.get_tree().process_frame
		check.call(not game._story_active and not realm.player.controls_locked and realm.process_mode != Node.PROCESS_MODE_DISABLED and game.hud.visible and GameState.gold() == gold, "skipping beat %d safely restores gameplay once without rewards" % (beat+1))
	game.play_story("mei")
	var natural := game._active_story
	natural.set_process(false)
	for duration in MeiLingRescueRenderer.DURATIONS: natural._process(float(duration))
	await game.get_tree().process_frame
	check.call(not game._story_active and not realm.player.controls_locked and bool(GameState.campaign().mei_ling_rescued), "natural seven-beat completion preserves rescue and returns control")
	# Replacement cancels an old sequence instead of unlocking or marking the new journey.
	game.play_story("mei")
	var old_story := game._active_story
	game._clear_world()
	await game.get_tree().process_frame
	check.call(not game._story_active and game._active_story == null and not is_instance_valid(old_story), "world replacement cancels and removes the owned rescue sequence")
	await game._load_dungeon(RealmDB.PORTAL,false)
