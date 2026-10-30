extends RefCounted
## Dock staging, explicit embark, cinematic continuity, persistence and title/free-play.

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
	check.call(not GameState.final_departure_available(), "fresh journey has no ending invitation")
	GameState.data.campaign.departure_seen = true
	GameState._sanitize_campaign()
	check.call(not bool(GameState.campaign().departure_seen), "sanitizer rejects departure without both rescues")
	for invalid in ["true",1,[],{}]:
		GameState.data.campaign.departure_seen = invalid
		GameState._sanitize_campaign()
		check.call(not bool(GameState.campaign().departure_seen), "malformed departure field is not treated as completion")
	GameState.rescue_friend("mei_ling")
	await game._load_lobby(false)
	await game.get_tree().physics_frame
	check.call(not GameState.final_departure_available() and _heroes(game).size() == 1, "one rescued friend retains ordinary village duty")
	var first: VillageHero = _heroes(game)[0]
	var first_at := first.position
	GameState.rescue_friend("arjun")
	game._check_campaign_ending()
	check.call(first.dock_waiting and first.position == first_at and first.home != first_at, "second rescue assigns the existing friend a dock route without teleporting")
	for frame in 600:
		if game.world.departure_friends_ready(): break
		await game.get_tree().physics_frame
	check.call(first.position.distance_to(first_at) > 2 and game.world.departure_friends_ready(), "friend walks continuously from the village and settles at a reachable dock post")
	check.call(_heroes(game).size() == 2 and _heroes(game)[0].position.distance_to(_heroes(game)[1].position) > 1, "two unique waiting friends leave a clear central approach")
	for i in 4: game._check_campaign_ending()
	check.call(_heroes(game).size() == 2 and game._active_story == null, "periodic readiness checks never duplicate friends or auto-start the ending")
	var home := game.world as Lobby
	var dock: FinalDeparture = home.final_departure
	check.call(home._departure_posts.size() == 2, "both dock posts are validated against collision and a connected route")
	var blocker := StaticBody2D.new()
	var block_shape := CollisionShape2D.new()
	var block_circle := CircleShape2D.new()
	block_circle.radius = 0.45
	block_shape.shape = block_circle
	blocker.add_child(block_shape)
	blocker.position = home.departure_post("arjun")
	home.add_child(blocker)
	await game.get_tree().physics_frame
	await game.get_tree().physics_frame
	home.invalidate_resident_routes()
	home._sync_rescued_friends()
	check.call(home._departure_posts.has("arjun") and home.departure_post("arjun").distance_to(blocker.position) > 0.7, "an obstructed waiting post resolves to a clear reachable alternative")
	blocker.queue_free()
	await game.get_tree().physics_frame
	home.invalidate_resident_routes()
	home._sync_rescued_friends()
	for friend in _heroes(game):
		friend.position = friend.home
		friend._target = null
	var waiting_time := float(GameState.data.world_time)
	game._process(0.4)
	check.call(float(GameState.data.world_time) > waiting_time and game._active_story == null, "village simulation continues while the friends wait")
	game.player().position = dock.position+Vector2(8,0)
	check.call(not dock.is_interactable_available() and not game.begin_final_departure(dock), "remote keyboard and direct entry cannot embark")
	await _world_pointer(game,dock.position,false)
	check.call(game._active_story == null, "remote mouse click cannot start the ending")
	game.player().position = dock.position+Vector2(0,0.7)
	game.player().velocity = Vector2.ZERO
	await game.get_tree().physics_frame
	dock._process(0)
	check.call(dock.available and dock._hint.visible and dock.get_prompt().contains("embark"), "nearby approach reveals the Embark invitation without starting a story")
	if capture.is_valid():
		game.world.camera.global_position = dock.position+Vector2(0,-0.6)
		game.world.camera.set_physics_process(false)
		game.world.camera.reset_physics_interpolation()
		game.world.camera.force_update_scroll()
		game.player().reset_physics_interpolation()
		for friend in _heroes(game): friend.reset_physics_interpolation()
		await game.get_tree().physics_frame
		await capture.call("dock_waiting")
	for field in ["_sailing","_transitioning","_portal_fx_active","_defeat_pending","_input_locked","_arjun_returning","_story_active","_game_over"]:
		game.set(field,true)
		check.call(not game.begin_final_departure(dock), "Embark revalidates %s ownership" % field)
		game.set(field,false)
	GameState.data.recovery_active = true
	check.call(not game.begin_final_departure(dock), "recovery blocks embark without consuming completion")
	GameState.data.recovery_active = false
	game.hud.mission_panel.open_missions()
	check.call(not game.begin_final_departure(dock), "a modal blocks embark")
	game.hud.hide_modals()
	game._on_modal_closed()
	game.player().sleeping = true
	check.call(not game.begin_final_departure(dock), "sleeping Adam cannot embark")
	game.player().sleeping = false
	game.player().attacking = true
	check.call(not game.begin_final_departure(dock), "an active weapon attack cannot enter the ending")
	game.player().attacking = false
	game.world._settlement_editor.active = true
	check.call(not game.begin_final_departure(dock), "settlement editing blocks embark")
	game.world._settlement_editor.active = false
	var burning: ForestTree = game.world._forest_trees[0]
	var tree_at := burning.position
	burning.position = dock.position
	burning.burning = true
	check.call(game.final_departure_reason(dock).contains("fire") and not game.begin_final_departure(dock), "a burning tree at the dock keeps the invitation pending")
	burning.burning = false
	burning.position = tree_at
	var threat := Enemy.new()
	threat.kind = "urchin"
	threat.max_hp = 200
	threat.position = first.home+Vector2(0.8,0)
	game.world.add_child(threat)
	threat.set_physics_process(false)
	check.call(game.final_departure_reason(dock).contains("danger") and not game.begin_final_departure(dock), "danger at a waiting friend blocks the ending")
	first._physics_process(1)
	check.call(is_instance_valid(first._target), "waiting friends still respond to a nearby threat")
	threat.position = first.home+Vector2(15,0)
	check.call(first.nearest_threat() == null, "dock defenders do not chase threats across the village")
	threat.queue_free()
	await game.get_tree().physics_frame
	for friend in _heroes(game):
		friend.position = friend.home
		friend._target = null
	game.player().position = dock.position+Vector2(0,0.7)
	game._check_campaign_ending()
	check.call(game._active_story == null, "clearing danger restores only the invitation")
	# Old completed reunions gain an optional departure; no rescue is reset.
	GameState.data.campaign.ending_seen = true
	GameState.data.campaign.erase("departure_seen")
	GameState._sanitize_campaign()
	check.call(GameState.final_departure_available() and bool(GameState.campaign().ending_seen), "old reunion-completed save gains a voluntary dock departure")
	GameState.data.campaign.ending_seen = false
	var before := GameState.data.duplicate(true)
	game.player()._update_nearby()
	check.call(game.player().nearby == dock, "boarding point selects Embark rather than Pak Rahim")
	# Real keyboard input through Player's proximity interaction.
	await _action(game,"interact",true)
	await _action(game,"interact",false)
	var story := game._active_story
	check.call(story != null and story.kind == "ending", "nearby E starts the dock conversation")
	if story == null: return
	story.set_process(false)
	check.call(not game.begin_final_departure(dock) and game.world.process_mode == Node.PROCESS_MODE_DISABLED and not game.hud.visible, "one ending owns the suspended world, HUD and duplicate entry guard")
	story._process(120)
	game._process(20)
	check.call(story.page == 0 and story._reunion_text_done and GameState.data.world_time == before.world_time, "long reading pauses never advance dialogue or village time")
	var copy := ReunionDialogueDB.turn(0)
	copy.text = "changed"
	check.call(ReunionDialogueDB.turn(0).text == "You're both here.", "dialogue accessors protect the authored script")
	if capture.is_valid():
		for page in [0,6,9,14,18,27,29]:
			story.page = page
			story._page_time = 3
			story._reunion_beat_time = 2
			story._render()
			story._caption.visible_characters = -1
			story._reunion_text_done = true
			story._canvas.queue_redraw()
			await capture.call("dock_reunion_%02d" % page)
		for beat in 7:
			for elapsed in ([0.5,2.2,3.8,5.8] if beat == 2 else [0.6,float(ReunionDialogueDB.DEPARTURE_DURATIONS[beat])]):
				story.page = ReunionDialogueDB.TURNS.size()+beat
				story._page_time = elapsed
				story._reunion_beat_time = elapsed
				story._render()
				story._process(0)
				story._canvas.queue_redraw()
				await capture.call("departure_%d_%02d" % [beat,int(elapsed*10)])
		story.reunion_night = true
		story._mei_reduced = true
		for beat in [0,2,4,5,6]:
			story.page = ReunionDialogueDB.TURNS.size()+beat
			story._page_time = 8
			story._reunion_beat_time = 8
			story._render()
			story._process(0)
			story._canvas.queue_redraw()
			await capture.call("departure_night_reduced_%d" % beat)
		story.reunion_night = false
		story._mei_reduced = false
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
	check.call(story.page == 9 and story._mei_reduced and not story._reunion_voice.playing, "live motion, low effects and mute preserve the full conversation")
	GameSettings.set_value("reduce_motion",motion,false)
	GameSettings.set_value("effects_quality",quality,false)
	GameSettings.set_value("mute_all",mute,false)
	story._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	check.call(not story._reunion_voice.playing and not story._ending_bed.playing and not story._departure_sound.playing, "focus loss stops all story-owned audio")
	story._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_IN)
	story.page = 0
	story._page_time = 0
	story._render()
	await _pointer(game,story._next,false)
	check.call(story.page == 0 and story._reunion_text_done, "mouse Next reveals the line first")
	story._process(0.25)
	await _pointer(game,story._next,true)
	check.call(story.page == 1, "touch and emulated mouse advance exactly one turn")
	story._process(0.25)
	story._next.grab_focus()
	await _enter(game)
	check.call(story.page == 1 and story._reunion_text_done, "keyboard activation reveals the current line")
	story._process(0.25)
	await _enter(game)
	check.call(story.page == 2, "fresh keyboard activation advances one turn")
	story._next.release_focus()
	# Every turn skips to the actual departure; never consumes completion.
	for index in ReunionDialogueDB.TURNS.size():
		story.page = index
		story._render()
		story._process(0.3)
		story._on_skip_pressed()
		check.call(story.page == ReunionDialogueDB.TURNS.size() and not bool(GameState.campaign().get("departure_seen",false)), "Skip conversation at turn %d reaches departure without completion" % (index+1))
	# Inspect sampled continuity in addition to rendered consecutive frames.
	for beat in 6:
		var page := ReunionDialogueDB.TURNS.size()+beat
		var a := ReunionRenderer.sample(page,0,false,"high",false)
		var b := ReunionRenderer.sample(page,float(ReunionDialogueDB.DEPARTURE_DURATIONS[beat]),false,"high",false)
		if beat == 2: check.call(int(a.boarded) == 0 and int(b.boarded) == 3, "boarding moves all three from dock posts onto the deck")
		if beat == 3: check.call(not a.rope_released and b.rope_released and b.ship_at.x > a.ship_at.x, "cast off releases mooring before visible sailing")
		if beat == 4: check.call(b.ship_at.x > a.ship_at.x and b.ship_scale < a.ship_scale, "ship separates from BESUT and recedes")
	var cast_off := ReunionRenderer.sample(33,4,false,"high",false)
	var departing := ReunionRenderer.sample(34,0,false,"high",false)
	check.call(cast_off.ship_at == departing.ship_at, "wide sailing shot continues from the cast-off position without jumping backward")
	for id in ["adam","arjun","mei_ling"]:
		var previous: Vector2 = ReunionRenderer.sample(32,0,false,"high",false).feet[id]
		var continuous := true
		for frame in range(1,361):
			var at: Vector2 = ReunionRenderer.sample(32,float(frame)/60,false,"high",false).feet[id]
			if at.distance_to(previous) > 8: continuous = false
			previous = at
		check.call(continuous, "%s follows continuous dock, gangplank and deck positions" % id)
	story.page = 0
	story._render()
	for index in ReunionDialogueDB.TURNS.size():
		story.advance()
		story.advance()
	check.call(story.page == ReunionDialogueDB.TURNS.size(), "natural reading reaches the departure sequence")
	for beat in 6:
		var previous := story.page
		story.advance()
		check.call(story.page == previous, "departure beat %d holds until its motion is complete" % beat)
		story._process(float(ReunionDialogueDB.DEPARTURE_DURATIONS[beat])+0.1)
		story.advance()
	check.call(story.page == ReunionDialogueDB.final_page() and not bool(GameState.campaign().get("departure_seen",false)), "sailing reaches the final card without premature save completion")
	# A cancelled ending preserves progress and restores normal controls.
	story.cancel()
	await game.get_tree().process_frame
	check.call(not game._story_active and not bool(GameState.campaign().get("departure_seen",false)) and not game.player().controls_locked and game.hud.visible, "cancel at final card restores the world without consuming departure")
	for phase in [0,30,31,32,33,34,35,36]:
		check.call(game.begin_final_departure(dock), "ending can start fresh after cancellation")
		var interrupted := game._active_story
		interrupted.set_process(false)
		interrupted.page = phase
		interrupted._render()
		interrupted.cancel()
		await game.get_tree().process_frame
		check.call(not game._story_active and not game.player().controls_locked and game.world.process_mode != Node.PROCESS_MODE_DISABLED and not bool(GameState.campaign().get("departure_seen",false)), "cancellation at phase %d restores controls and preserves pending departure" % phase)
	# Actual pointer entry, skip ending, durable save and covered title transition.
	await _pointer(game,dock._hint,true)
	check.call(game._active_story != null, "the visible contextual Embark banner also accepts a nearby touch")
	if game._active_story != null: game._active_story.cancel()
	await game.get_tree().process_frame
	await _world_pointer(game,dock.position,false)
	story = game._active_story
	check.call(story != null, "nearby mouse starts the same guarded ending")
	if story != null:
		story.set_process(false)
		story._process(0.4)
		await _pointer(game,story._skip,true)
		story._process(0.3)
		await _pointer(game,story._skip,false)
		check.call(story.page == ReunionDialogueDB.final_page(), "separate Skip ending reaches the final card")
		story._process(2.1)
		# Force a real, isolated file-open failure and verify final-card retry.
		var save_path := ProjectSettings.globalize_path(GameState.SAVE_PATH)
		var backup_path := save_path+".ending-check"
		check.call(DirAccess.rename_absolute(save_path,backup_path) == OK and DirAccess.make_dir_absolute(save_path) == OK, "save-failure fixture owns only its isolated path")
		story.advance()
		check.call(game._active_story == story and not bool(GameState.campaign().get("departure_seen",false)) and story._caption.text.contains("could not be saved"), "failed completion save retains the final card and rolls back completion flags")
		DirAccess.remove_absolute(save_path)
		DirAccess.rename_absolute(backup_path,save_path)
		await _pointer(game,story._next,false)
		for frame in 180:
			if is_instance_valid(game.title_screen) and not game._transitioning: break
			await game.get_tree().process_frame
	check.call(game.world == null and is_instance_valid(game.title_screen) and bool(GameState.campaign().get("departure_seen",false)), "final card saves once and returns to title")
	check.call(game.title_screen._continue_button.text.contains("Explore BESUT") and game.title_screen._saved_journey_text().contains("Before departure"), "completed title clearly offers earlier-time BESUT exploration")
	check.call(GameState.load_game() and bool(GameState.campaign().departure_seen) and bool(GameState.campaign().ending_seen), "departure and reunion completion survive an actual JSON reload")
	check.call(GameState.gold() == int(before.gold) and GameState.data.campaign.ocean_stage == before.campaign.ocean_stage and GameState.data.expedition == before.expedition and not GameState.sea_journey_available(), "ending pays no rewards and preserves the completed sea lock and checkpoints")
	for field in ["inventory","pets","structures","portals","forest_health","settlement_layout"]:
		# JSON numbers load as floats; compare both sides in the persisted format.
		check.call(JSON.parse_string(JSON.stringify(GameState.data.get(field))) == JSON.parse_string(JSON.stringify(before.get(field))), "departure preserves saved %s" % field)
	game._remove_title()
	await game._load_lobby(false)
	check.call(_heroes(game).size() == 2 and not _heroes(game)[0].dock_waiting and not game.world.final_departure.is_interactable_available(), "earlier-time free play restores defenders without another departure")
	# Opposite rescue order and legacy completion both reconstruct waiting on load.
	GameState.data.campaign.departure_seen = false
	GameState.data.campaign.mei_ling_rescued = false
	GameState.data.campaign.ending_seen = false
	await game._load_lobby(false)
	GameState.rescue_friend("mei_ling")
	await game._load_lobby(false)
	check.call(game._active_story == null and game.world.departure_friends_ready(), "Arjun-first order also waits at the dock after reload")
	game.player().position = game.world.final_departure.position
	await game.get_tree().physics_frame
	game._check_campaign_ending()
	await _world_pointer(game,game.world.final_departure.position,true)
	check.call(game._active_story != null, "nearby touch starts the ending once in the opposite rescue order (context: %s)" % game.final_departure_reason(game.world.final_departure))
	game._clear_world()
	await game.get_tree().process_frame
	check.call(not game._story_active and not bool(GameState.campaign().departure_seen), "world replacement cancels the ending without completion")
	# Mei Ling-first, then the real incoming Arjun passenger-to-dock handoff.
	game._arjun_returning = true
	game._return_to_harbour = true
	await game._load_lobby(false)
	var returning := game.world as Lobby
	var boarding := returning.ship_boarding
	var passenger := boarding.ship.get_node_or_null("ArjunPassenger") as PlayerSprite
	check.call(is_instance_valid(passenger) and _heroes(game).size() == 1 and game._sailing, "Mei Ling waits alone while the real returning ship still owns Arjun")
	boarding.ship.position = boarding._moored_position
	boarding._physics_process(0)
	game.player().position = boarding.position
	boarding._physics_process(0.01)
	check.call(game._arjun_returning and not game.begin_final_departure(returning.final_departure), "incoming dock walk keeps Embark locked until Arjun has landed")
	if game._arjun_walk != null and game._arjun_walk.is_valid():
		game._arjun_walk.pause()
		var from := passenger.global_position
		game._arjun_walk.custom_step(0.1)
		check.call(passenger.global_position.distance_to(from) <= Resident.WALK_SPEED*0.11 and passenger.scale == Vector2.ONE*PixelArt.PX, "incoming Arjun walks continuously at human scale")
		game._arjun_walk.custom_step(300)
	await game.get_tree().physics_frame
	await game.get_tree().process_frame
	game._check_campaign_ending()
	check.call(not game._arjun_returning and _heroes(game).size() == 2 and returning.departure_friends_ready() and game._active_story == null, "Mei Ling-first incoming return hands Arjun to exactly one dock actor without automatic ending")
	check.call(not boarding.available and not GameState.sea_journey_available() and game.final_departure_reason(returning.final_departure) == "Embark together", "final Embark becomes available while the completed turtle route remains closed")
	if capture.is_valid():
		returning.camera.set_physics_process(false)
		returning.camera.global_position = boarding.position
		returning.camera.reset_physics_interpolation()
		returning.camera.force_update_scroll()
		await capture.call("dock_after_incoming_rescue")
	GameState.data = saved
	GameState._emit_all()
	await game._load_lobby(false)
	GameState.autosave_enabled = autosave
	game._side_quest_auto_enabled = quests
	game.set_process(ticking)

static func _heroes(game: Game) -> Array[VillageHero]:
	var result: Array[VillageHero] = []
	for child in game.world.get_children():
		if child is VillageHero: result.append(child)
	return result

static func _action(game: Game, action: String, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_E
	event.keycode = KEY_E
	event.pressed = pressed
	Input.parse_input_event(event)
	await game.get_tree().physics_frame
	await game.get_tree().process_frame

static func _world_pointer(game: Game, world_point: Vector2, touch: bool) -> void:
	game.world.camera.set_physics_process(false)
	game.world.camera.global_position = game.player().global_position+Vector2(0,-0.6)
	game.world.camera.reset_physics_interpolation()
	game.world.camera.force_update_scroll()
	game.player().reset_physics_interpolation()
	await game.get_tree().physics_frame
	await game.get_tree().process_frame
	var at := game.get_viewport().get_final_transform()*(game.world.get_canvas_transform()*world_point)
	await _at(game,at,touch)

static func _pointer(game: Game, button: Button, touch: bool) -> void:
	await game.get_tree().process_frame
	await game.get_tree().process_frame
	var at := game.get_viewport().get_final_transform()*(button.get_global_transform_with_canvas()*(button.size/2))
	await _at(game,at,touch)

static func _at(game: Game, at: Vector2, touch: bool) -> void:
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
