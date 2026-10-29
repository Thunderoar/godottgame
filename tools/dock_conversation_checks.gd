class_name DockConversationChecks
extends RefCounted

static func run(game: Game, check: Callable, capture: Callable = Callable()) -> void:
	var snapshot := GameState.data.duplicate(true)
	var autosave := GameState.autosave_enabled
	var save_available := GameState.has_existing_save
	var tips_enabled := game.hud.tutorial_guide._tips_enabled
	GameState.autosave_enabled = false
	GameState.data = GameState._make_default("adam")
	GameState._emit_all()
	check.call(not bool(GameState.campaign().dock_welcome_seen), "new journeys wait for their dock welcome")
	# Exercise the actual pre-merge save migration, not just the sanitizer.
	var existing_save := FileAccess.get_file_as_string(GameState.SAVE_PATH) if FileAccess.file_exists(GameState.SAVE_PATH) else ""
	var old_save := GameState.data.duplicate(true)
	old_save.campaign.intro_seen = true
	old_save.campaign.erase("dock_welcome_seen")
	var file := FileAccess.open(GameState.SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(old_save))
	file.close()
	check.call(GameState.load_game() and bool(GameState.campaign().dock_welcome_seen), "old saves that finished the opening keep their ordinary home arrival")
	GameState.data = GameState._make_default("adam")
	GameState.mark_story_seen("intro_seen")
	GameState.save_game()
	check.call(GameState.load_game() and not bool(GameState.campaign().dock_welcome_seen), "Continue preserves an interrupted opening's pending dock conversation")
	await game._load_lobby(false, true)
	var lobby := game.world as Lobby
	var previous_mode := lobby.process_mode
	var host := lobby.get_node_or_null("PakRahim") as DockHost
	check.call(host != null and host.position.distance_to(lobby.player.position) < host.interact_radius, "Pak Rahim is a real reachable character beside Adam on the resolved dock")
	game.play_dock_conversation(true)
	var dialogue := game._dock_conversation
	await game.get_tree().process_frame
	check.call(dialogue != null and game._story_active and game.player().controls_locked and lobby.process_mode == Node.PROCESS_MODE_DISABLED and not game.hud.visible, "first dock conversation owns story suspension, held controls and the hidden tutorial HUD")
	var clock := float(GameState.data.world_time)
	var position := game.player().position
	game._process(30)
	await game.get_tree().physics_frame
	check.call(float(GameState.data.world_time) == clock and game.player().position == position and dialogue.page == 0, "reading neither advances the village clock nor moves Adam nor times out a line")
	check.call(dialogue._portrait.texture != null and dialogue._portrait.texture.get_image().get_pixel(0, 0).a == 0, "original anime portrait loads with a transparent background")
	check.call(dialogue._adam_portrait != null and dialogue._adam_portrait != dialogue._rahim_portrait and dialogue._adam_portrait.get_image().get_pixel(0, 0).a == 0, "Adam has his own imported transparent dialogue portrait")
	var expression_assets_valid := dialogue._adam_expressions.size() == 3
	for texture: Texture2D in dialogue._adam_expressions.values():
		expression_assets_valid = expression_assets_valid and texture != null and texture.get_size() == dialogue._adam_portrait.get_size() and texture.get_image().get_pixel(0, 0).a == 0
	check.call(expression_assets_valid, "all three Adam expressions load with transparent backgrounds and matching canvas dimensions")
	game.play_dock_conversation(true)
	check.call(game._dock_conversation == dialogue, "duplicate conversation requests cannot create another story owner")
	dialogue.set_process(false)
	await _check_presentation(dialogue, check, capture)
	dialogue.reveal_line()
	if capture.is_valid(): await capture.call("dock_welcome")
	for page in DockConversation.WELCOME.size():
		dialogue.page = page
		dialogue._render()
		dialogue.reveal_line()
		await game.get_tree().process_frame
		var viewport := dialogue._root.get_global_rect()
		var expected_portrait := DockConversation.ADAM_PORTRAIT_PATH if DockConversation.WELCOME[page].speaker == "Adam" else DockConversation.PORTRAIT_PATH
		if page == 6: expected_portrait = DockConversation.ADAM_SURPRISED_PATH
		if page == 9: expected_portrait = DockConversation.ADAM_RESOLVED_PATH
		check.call(dialogue._portrait.texture.resource_path == expected_portrait and dialogue._portrait.modulate == Color.WHITE, "dock line %d shows its named speaker's artwork in its original colours" % page)
		check.call(viewport.encloses(dialogue._panel.get_global_rect()) and viewport.encloses(dialogue._portrait.get_global_rect()), "dock line %d keeps its box and right-hand portrait in the viewport" % page)
		check.call(dialogue._line.get_minimum_size().y <= dialogue._line.size.y + 1 and dialogue._line.get_global_rect().end.x < dialogue._portrait.get_global_rect().position.x and dialogue._line.get_global_rect().end.y <= dialogue._next.get_global_rect().position.y, "dock line %d fits fully above the buttons and beside the portrait" % page)
		if capture.is_valid() and page in [1, 6, 9]:
			await capture.call({1: "dock_adam_reply", 6: "dock_adam_surprised", 9: "dock_adam_promise"}[page])
	if capture.is_valid(): await capture.call("dock_promise")
	dialogue.page = 0
	dialogue._render()
	_send_key(true)
	await game.get_tree().process_frame
	check.call(dialogue.page == 0 and not dialogue._revealing and _all_words_at(dialogue, 1.0), "first keyboard press reveals the full line without skipping it")
	_send_key(false)
	await game.get_tree().process_frame
	_send_key(true)
	await game.get_tree().process_frame
	check.call(dialogue.page == 1, "keyboard interaction advances one conversation line")
	_send_key(false)
	await game.get_tree().process_frame
	dialogue._previous()
	check.call(dialogue.page == 0 and dialogue._back.disabled, "Back rereads the prior line without going before the opening")
	var touch := InputEventScreenTouch.new()
	touch.index = 32
	touch.position = game.get_viewport().get_final_transform() * dialogue._next.get_global_rect().get_center()
	touch.pressed = true
	Input.parse_input_event(touch)
	touch = touch.duplicate() as InputEventScreenTouch
	touch.pressed = false
	Input.parse_input_event(touch)
	await game.get_tree().process_frame
	check.call(dialogue.page == 0 and not dialogue._revealing, "first screen tap completes the fade without skipping dialogue")
	touch.pressed = true
	Input.parse_input_event(touch)
	touch = touch.duplicate() as InputEventScreenTouch
	touch.pressed = false
	Input.parse_input_event(touch)
	await game.get_tree().process_frame
	check.call(dialogue.page == 1, "a real screen touch advances exactly one line without a world action")
	while dialogue.page < dialogue.entries().size() - 1: dialogue.advance()
	dialogue.reveal_line()
	_send_key(true)
	await game.get_tree().process_frame
	check.call(not Input.is_action_pressed("interact"), "the final E is consumed before world physics can reopen the dock conversation")
	await game.get_tree().physics_frame
	await game.get_tree().physics_frame
	_send_key(false)
	check.call(bool(GameState.campaign().dock_welcome_seen) and lobby.process_mode == previous_mode and not game._story_active and not game.player().controls_locked and game.hud.visible and game._dock_conversation == null, "finishing once saves the welcome and restores the correct world and controls")
	GameState.save_game()
	check.call(GameState.load_game() and bool(GameState.campaign().dock_welcome_seen), "completed dock welcome survives an actual save and load")
	game.play_dock_conversation(true)
	check.call(game._dock_conversation == null, "completed journeys do not automatically repeat the welcome")
	host.interact(game.player())
	var repeat := game._dock_conversation
	check.call(repeat != null and not repeat.introduction and not game._story_active and lobby.process_mode == previous_mode, "talking to Rahim later uses a short chat and normal running simulation")
	clock = float(GameState.data.world_time)
	game._process(0.25)
	check.call(float(GameState.data.world_time) > clock, "later voluntary chats preserve normal menu clock rules")
	repeat.finish()
	check.call(not repeat._voice.playing and not repeat._revealing, "closing mid-fade stops the owned talking voice immediately")
	await game.get_tree().process_frame
	GameState.data.campaign.dock_welcome_seen = false
	game.play_dock_conversation(true)
	var abandoned := game._dock_conversation
	await game._load_lobby(false)
	check.call(abandoned.cancelled and not bool(GameState.campaign().dock_welcome_seen) and not game._story_active and game._dock_conversation == null and game.world.process_mode != Node.PROCESS_MODE_DISABLED, "world replacement cancels the old dock conversation without completing it or freezing the new world")
	game.hud.tutorial_guide._tips_enabled = false
	game.hud.tutorial_guide.hide()
	game._on_character_selected("adam")
	var opening: StorySequence
	for child in game.get_children():
		if child is StorySequence and not child.is_queued_for_deletion(): opening = child
	check.call(opening != null, "New Journey still starts with the existing opening beats")
	if opening != null: opening.finish()
	var arrival := await _wait_for_dock(game)
	check.call(arrival != null and game.world.arrive_at_dock and not game.hud.tutorial_guide._tips_enabled, "the actual New Journey handoff opens Rahim on the dock before movement lessons")
	if arrival != null: arrival.finish()
	await game.get_tree().process_frame
	check.call(bool(GameState.campaign().dock_welcome_seen) and game.hud.tutorial_guide._tips_enabled and not game._story_active, "Skip conversation also hands the actual New Journey to its first lesson")
	GameState.data.campaign.dock_welcome_seen = false
	GameState.save_game()
	game._on_continue_requested()
	var resumed := await _wait_for_dock(game)
	check.call(resumed != null and resumed.introduction and game.world.arrive_at_dock, "the actual Continue route resumes an unfinished dock welcome at the dock")
	game.hud.tutorial_guide._tips_enabled = false
	await game._load_lobby(false)
	check.call(not bool(GameState.campaign().dock_welcome_seen) and not game.hud.tutorial_guide._tips_enabled, "cancelling the actual Continue handoff cannot start lessons in a replacement world")
	game._on_continue_requested()
	resumed = await _wait_for_dock(game)
	check.call(resumed != null and resumed.introduction, "a cancelled Continue handoff can resume its still-pending dock welcome")
	if resumed != null: resumed.finish()
	await game.get_tree().process_frame
	game._on_continue_requested()
	var deadline := Time.get_ticks_msec() + 8000
	while game._transitioning and Time.get_ticks_msec() < deadline: await game.get_tree().process_frame
	check.call(not game._transitioning and game._dock_conversation == null and not game.world.arrive_at_dock and game.player().position == game.world.get_spawn_position(), "Continue after the welcome uses the ordinary home spawn without another conversation")
	GameState.autosave_enabled = false
	game.hud.tutorial_guide._tips_enabled = tips_enabled
	GameState.data = snapshot
	GameState._emit_all()
	await game._load_lobby(false)
	if existing_save.is_empty():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.SAVE_PATH))
	else:
		file = FileAccess.open(GameState.SAVE_PATH, FileAccess.WRITE)
		file.store_string(existing_save)
		file.close()
	GameState.autosave_enabled = autosave
	GameState.has_existing_save = save_available

static func _send_key(pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_E
	event.physical_keycode = KEY_E
	event.pressed = pressed
	Input.parse_input_event(event)

static func _all_words_at(dialogue: DockConversation, alpha: float) -> bool:
	for word in dialogue._words:
		if not is_equal_approx(word.modulate.a, alpha): return false
	return not dialogue._words.is_empty()

static func _check_presentation(dialogue: DockConversation, check: Callable, capture: Callable) -> void:
	var settings := [GameSettings.reduce_motion(), GameSettings.effects_volume(), GameSettings.master_volume(), GameSettings.mute_all()]
	GameSettings.set_reduce_motion(false, false)
	GameSettings.set_effects_volume(100, false)
	GameSettings.set_master_volume(100, false)
	GameSettings.set_mute_all(false, false)
	dialogue._render()
	check.call(_all_words_at(dialogue, 0.0) and dialogue._revealing and dialogue._next.text == "Reveal", "all words start transparent while their final layout is reserved")
	check.call(dialogue._voice.get_parent() == dialogue and dialogue._voice.playing and dialogue._voice.stream == Sfx.dialogue_voice("Pak Rahim"), "Rahim's fade starts an owned cached talking sound")
	if capture.is_valid(): await capture.call("dock_fade_0")
	await dialogue.get_tree().process_frame
	var positions: Array[Vector2] = []
	for word in dialogue._words: positions.append(word.position)
	dialogue._process(DockConversation.WORD_FADE_SECONDS * 0.5)
	check.call(is_equal_approx(dialogue._words[0].modulate.a, 0.5) and dialogue._words[1].modulate.a == 0 and dialogue._words[-1].modulate.a == 0 and dialogue.page == 0, "only the first word fades in while the rest of the sentence remains invisible")
	if capture.is_valid(): await capture.call("dock_fade_half")
	dialogue._process(dialogue._word_starts[1])
	check.call(dialogue._words[0].modulate.a == 1 and is_equal_approx(dialogue._words[1].modulate.a, 0.5) and dialogue._words[2].modulate.a == 0, "the next word fades independently while its predecessor remains fully readable")
	if capture.is_valid(): await capture.call("dock_word_second")
	var stable := true
	for i in dialogue._words.size(): stable = stable and dialogue._words[i].position == positions[i]
	check.call(stable, "successive rendered word fades preserve the final wrapping and word positions")
	check.call(DockConversation.word_seconds("now,") > DockConversation.word_seconds("now") and DockConversation.word_seconds("Adam.") > DockConversation.word_seconds("Adam,") and DockConversation.word_seconds("just...") > DockConversation.word_seconds("just."), "commas, sentence endings and ellipses give the speaker progressively longer pauses")
	check.call(DockConversation.word_seconds("introduction") > DockConversation.word_seconds("a"), "longer spoken words receive more time than short connecting words")
	dialogue._process(dialogue._reveal_duration)
	check.call(_all_words_at(dialogue, 1.0) and not dialogue._revealing and not dialogue._voice.playing and dialogue._next.text == "Next", "the fade settles at fully readable text and stops talking")
	if capture.is_valid(): await capture.call("dock_fade_full")
	dialogue._render()
	var syllables := dialogue._syllable
	dialogue._process(dialogue._word_starts[5] + DockConversation.WORD_FADE_SECONDS * 0.5)
	check.call(dialogue._voice_word == 5 and dialogue._syllable == syllables + 1, "a slow frame voices only the current word without replaying missed words")
	dialogue.reveal_line()
	dialogue._process(60)
	check.call(dialogue.page == 0 and not dialogue._voice.playing, "a completed line waits silently for the player indefinitely")
	dialogue._render()
	dialogue.advance()
	check.call(dialogue.page == 0 and _all_words_at(dialogue, 1.0) and not dialogue._voice.playing, "Reveal completes a fade immediately and silences its remaining syllables")
	dialogue.advance()
	check.call(dialogue.page == 1 and _all_words_at(dialogue, 0.0) and dialogue._voice.stream == Sfx.dialogue_voice("Adam"), "Adam's response fades in with a distinct lighter voice")
	dialogue._previous()
	check.call(dialogue.page == 0 and _all_words_at(dialogue, 0.0) and dialogue._voice.stream == Sfx.dialogue_voice("Pak Rahim"), "Back restarts the correct line and voice without leaving the old sound playing")
	check.call(dialogue._portrait.texture == dialogue._rahim_portrait, "Back from Adam's reply restores Rahim's portrait with his voice")
	dialogue.page = 9
	dialogue._render()
	dialogue._previous()
	dialogue._previous()
	dialogue._previous()
	check.call(dialogue.page == 6 and dialogue._portrait.texture.resource_path == DockConversation.ADAM_SURPRISED_PATH, "Back across speaker changes restores Adam's earlier surprise instead of his later resolve")
	dialogue.page = 0
	dialogue._render()
	GameSettings.set_effects_volume(0, false)
	check.call(not dialogue._voice.playing and dialogue._revealing, "live zero effects volume silences talking without cancelling the text fade")
	dialogue._process(0.2)
	check.call(not dialogue._voice.playing and dialogue._words[0].modulate.a > 0, "muted effects continue revealing text without restarting voice")
	GameSettings.set_effects_volume(50, false)
	check.call(is_equal_approx(dialogue._voice.volume_db, -12.0 + GameSettings.volume_percent_to_db(50)), "talking volume follows the existing effects preference")
	dialogue._process(dialogue._word_starts[2] + DockConversation.WORD_FADE_SECONDS * 0.5 - dialogue._reveal_elapsed)
	check.call(dialogue._voice.playing, "restoring effects volume resumes only the current line's remaining syllables")
	GameSettings.set_mute_all(true, false)
	check.call(not dialogue._voice.playing, "live master mute immediately stops a talking syllable")
	GameSettings.set_mute_all(false, false)
	GameSettings.set_reduce_motion(true, false)
	check.call(not dialogue._revealing and _all_words_at(dialogue, 1.0) and not dialogue._voice.playing, "live Reduce Motion immediately resolves the fade into readable silent text")
	dialogue._render()
	dialogue._process(DockConversation.REDUCED_FADE_SECONDS)
	check.call(not dialogue._revealing and _all_words_at(dialogue, 1.0), "Reduce Motion uses a shorter gentle fade for the next line")
	var rahim := Sfx.dialogue_voice("Pak Rahim")
	var adam := Sfx.dialogue_voice("Adam")
	var peak := 0
	for i in rahim.data.size() / 2: peak = maxi(peak, absi(rahim.data.decode_s16(i * 2)))
	check.call(peak > 1000 and peak < 32767 and rahim.data.decode_s16(0) == 0 and absi(rahim.data.decode_s16(rahim.data.size() - 2)) < 10, "talking PCM contains audible unclipped samples with soft silent edges")
	check.call(rahim.data != adam.data and rahim == Sfx.dialogue_voice("Pak Rahim", 3) and rahim.data != Sfx.dialogue_voice("Pak Rahim", 1).data, "bounded voice cache keeps distinct speakers and three varied vowel sounds")
	GameSettings.set_reduce_motion(bool(settings[0]), false)
	GameSettings.set_effects_volume(int(settings[1]), false)
	GameSettings.set_master_volume(int(settings[2]), false)
	GameSettings.set_mute_all(bool(settings[3]), false)
	dialogue.page = 0
	dialogue._render()

static func _wait_for_dock(game: Game) -> DockConversation:
	var deadline := Time.get_ticks_msec() + 8000
	while not is_instance_valid(game._dock_conversation) and Time.get_ticks_msec() < deadline:
		await game.get_tree().process_frame
	return game._dock_conversation
