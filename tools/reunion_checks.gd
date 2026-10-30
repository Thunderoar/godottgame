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
	var entry_snapshot := GameState.data.duplicate(true)
	check.call(not game.begin_final_departure(dock) and game.world.process_mode == Node.PROCESS_MODE_DISABLED and not game.hud.visible, "one ending owns the suspended world, HUD and duplicate entry guard")
	for action in ["interact","attack","ui_accept"]:
		story._mei_input_armed = false
		Input.action_press(action)
		story._process(1)
		story._on_next_pressed()
		check.call(story.page == 0 and not story._mei_input_armed, "held %s cannot consume the first exchange" % action)
		Input.action_release(action)
		story._process(0.4)
	story._process(120)
	game._process(20)
	check.call(story.page == 0 and story._reunion_text_done and GameState.data.world_time == before.world_time, "long reading pauses never advance dialogue or village time")
	var copy := ReunionDialogueDB.exchange(0)
	copy[0].text = "changed"
	check.call(ReunionDialogueDB.exchange(0)[0].id == "finally" and ReunionDialogueDB.exchange(0)[0].text != "changed", "exchange accessors protect the authored script")
	var word_count := 0
	var speaker_counts := {"adam":0,"arjun":0,"mei_ling":0}
	for row in ReunionDialogueDB.TURNS:
		word_count += str(row.text).split(" ",false).size()
		speaker_counts[row.speaker] += 1
	check.call(ReunionDialogueDB.TURNS.size() == 9 and word_count <= 60 and speaker_counts.values().all(func(n): return n == 3), "short banter gives each friend three lines within the reading budget")
	var motion := GameSettings.reduce_motion()
	var quality := GameSettings.effects_quality()
	var mute := GameSettings.mute_all()
	if capture.is_valid():
		for id in ReunionDialogueDB.EXCHANGES:
			story.page = ReunionDialogueDB.exchange_page(id)
			story._page_time = 2.2
			story._reunion_beat_time = 2.2
			story._render()
			story._canvas.queue_redraw()
			await capture.call("banter_"+id)
			var contained := true
			for label in story._reunion_lines:
				contained = contained and story._caption_panel.get_global_rect().encloses(label.get_global_rect()) and label.get_global_rect().end.y <= story._next.get_global_rect().position.y
			check.call(contained, "%s dialogue rows fit above the controls at this resolution" % id)
		for elapsed in [0.0,0.5,2.2,3.3,3.7,5.8,6.5,8.0,10.5,13.0,15.0,16.8]:
			story.page = ReunionDialogueDB.film_page()
			story._page_time = elapsed
			story._reunion_beat_time = elapsed
			story._render()
			story._canvas.queue_redraw()
			await capture.call("sailing_%03d" % int(elapsed*10))
		GameSettings.set_value("reduce_motion",true,false)
		GameSettings.set_value("effects_quality","low",false)
		story.reunion_night = true
		story._mei_reduced = true
		for elapsed in [0.5,3.3,5.8,10.5,15.0]:
			story.page = ReunionDialogueDB.film_page()
			story._reunion_beat_time = elapsed
			story._render()
			story._canvas.queue_redraw()
			await capture.call("sailing_night_reduced_%03d" % int(elapsed*10))
		story.ending_pet = ""
		story.page = ReunionDialogueDB.film_page()
		story._reunion_beat_time = 10.5
		story._render()
		await capture.call("sailing_without_companion")
		story.ending_pet = GameState.active_pet_id() if GameState.has_living_pet() else ""
		story.page = ReunionDialogueDB.final_page()
		story._render()
		await capture.call("ending_card_night")
		story.reunion_night = false
		story._render()
		await capture.call("ending_card_day")
	story.page = ReunionDialogueDB.exchange_page("captain_snacks")
	story._page_time = 0
	story._reunion_beat_time = 0
	story._render()
	GameSettings.set_value("reduce_motion",true,false)
	GameSettings.set_value("effects_quality","low",false)
	GameSettings.set_value("mute_all",true,false)
	story._process(1)
	check.call(story.page == ReunionDialogueDB.exchange_page("captain_snacks") and story._mei_reduced and not story._reunion_voice.playing and story._reunion_text_done, "live motion, low effects and mute preserve fully readable banter")
	GameSettings.set_value("reduce_motion",motion,false)
	GameSettings.set_value("effects_quality",quality,false)
	GameSettings.set_value("mute_all",mute,false)
	story._process(0)
	check.call(story._mei_reduced == motion, "Reduce Motion can also be turned off during the ending")
	story._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	check.call(not story._reunion_voice.playing and not story._ending_bed.playing and not story._departure_sound.playing, "focus loss stops all story-owned audio")
	story._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_IN)
	story.page = 0
	story._page_time = 0
	story._reunion_beat_time = 0
	story._render()
	await _pointer(game,story._next,false)
	check.call(story.page == 1 and story._reunion_text_done, "one mouse Next advances a full exchange without a reveal-text press")
	story._on_next_pressed()
	check.call(story.page == 1, "a repeated press in the same gesture cannot skip an exchange")
	story._process(0.25)
	await _pointer(game,story._next,true)
	check.call(story.page == 2 and story._next.text == "Set sail", "touch and emulated mouse advance exactly one exchange")
	story._process(0.25)
	story._next.grab_focus()
	await _enter(game)
	check.call(story.page == ReunionDialogueDB.film_page() and story._next.text == "Pause", "fresh keyboard Set sail starts the continuous film")
	story._next.release_focus()
	# Skip every exchange and every film shot, without committing completion.
	for index in ReunionDialogueDB.EXCHANGES.size():
		story.page = index
		story._render()
		story._process(0.3)
		story._on_skip_pressed()
		check.call(story.page == ReunionDialogueDB.film_page() and not bool(GameState.campaign().departure_seen), "Skip conversation at exchange %d starts the film without completion" % index)
	for index in ReunionDialogueDB.SHOTS.size():
		story.page = ReunionDialogueDB.film_page()
		story._reunion_beat_time = float(ReunionDialogueDB.SHOT_STARTS[index])+0.3
		story._render()
		story._process(0.4)
		story._on_skip_pressed()
		check.call(story.page == ReunionDialogueDB.final_page() and not bool(GameState.campaign().departure_seen), "Skip ending in %s reaches the card without completion" % ReunionDialogueDB.SHOTS[index])
	var film := ReunionDialogueDB.film_page()
	var start := ReunionRenderer.sample(film,0,false,"high",false)
	var aboard := ReunionRenderer.sample(film,5.8,false,"high",false)
	var released := ReunionRenderer.sample(film,6.5,false,"high",false)
	var away := ReunionRenderer.sample(film,13,false,"high",false)
	check.call(int(start.boarded) == 0 and int(aboard.boarded) == 3 and not aboard.rope_released and released.rope_released, "all three board before the mooring releases")
	check.call(released.ship_at == start.ship_at and away.ship_at.x > released.ship_at.x and away.ship_scale < released.ship_scale, "the mooring releases before the ship visibly departs and recedes")
	check.call(ReunionRenderer.sample(film,3.3,false,"low",false).steady and ReunionRenderer.sample(film,3.3,false,"low",false).bag_wobble != 0, "Mei's steadying gesture accompanies Arjun's bag gag even at low quality")
	check.call(ReunionRenderer.sample(film,3.3,true,"low",true).bag_wobble == 0 and ReunionRenderer.sample(film,3.3,true,"low",true).steady, "Reduce Motion preserves the teamwork without wobble")
	for reduced in [false,true]:
		for id in ["adam","arjun","mei_ling"]:
			var previous: Vector2 = ReunionRenderer.sample(film,0,reduced,"high",false).feet[id]
			var continuous := true
			for frame in range(1,1021):
				var at: Vector2 = ReunionRenderer.sample(film,float(frame)/60,reduced,"high",false).feet[id]
				if at.distance_to(previous) > 8: continuous = false
				previous = at
			check.call(continuous, "%s has continuous gangplank and sailing positions (reduced=%s)" % [id,reduced])
	var on_water := true
	for frame in range(402,1021):
		var state := ReunionRenderer.sample(film,float(frame)/60,false,"high",false)
		# The authored hull is 112px high and the sea begins at y=100.
		on_water = on_water and float(state.ship_at.y)+112.0*float(state.ship_scale) >= 100
	check.call(on_water, "the receding hull stays on the sea through the final horizon")
	# Named shot boundaries share one clock: no cast-off or horizon reset.
	for boundary in [6.0,9.0,13.0]:
		var a := ReunionRenderer.sample(film,boundary-0.001,false,"high",false)
		var b := ReunionRenderer.sample(film,boundary+0.001,false,"high",false)
		check.call(a.ship_at.distance_to(b.ship_at) < 0.1 and absf(a.ship_scale-b.ship_scale) < 0.01, "ship position and scale remain continuous at %.0fs" % boundary)
	story.page = 0
	story._reunion_beat_time = 0
	story._render()
	for index in ReunionDialogueDB.EXCHANGES.size():
		story._process(4.5)
		story.advance()
	check.call(story.page == film and story._reunion_beat_time == 0, "three natural advances reach the film after comfortable reading")
	story._process(3.3)
	var paused_at := story._reunion_beat_time
	story.advance()
	story._process(30)
	check.call(story._reunion_paused and story._reunion_beat_time == paused_at and story._next.text == "Resume", "Pause freezes the ship and bag gag indefinitely")
	story._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	story._process(30)
	story._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_IN)
	story._process(1)
	check.call(story._reunion_paused and story._reunion_beat_time == paused_at, "focus return respects an existing manual pause")
	story.advance()
	story._process(1)
	paused_at = story._reunion_beat_time
	story._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	story._process(30)
	story.advance()
	check.call(story._reunion_beat_time == paused_at and not story._reunion_paused and not bool(GameState.campaign().departure_seen), "focus loss freezes running film and blocks activation without changing manual pause")
	story._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_IN)
	story._process(ReunionDialogueDB.FILM_SECONDS-paused_at-0.01)
	check.call(story.page == film, "continuous film remains active until its final frame")
	story._process(0.02)
	check.call(story.page == ReunionDialogueDB.final_page() and not bool(GameState.campaign().departure_seen), "film automatically reaches the card at 17 seconds without saving")
	story.advance()
	check.call(game._active_story == story and not story.departure_committed, "arrival input cannot immediately dismiss the final card")
	Input.action_press("ui_accept")
	story._process(1)
	story._on_next_pressed()
	check.call(game._active_story == story and not story._mei_input_armed, "held arrival input remains blocked after the final-card time guard")
	Input.action_release("ui_accept")
	story._process(0.4)
	var owned_serial := GameState.journey_serial
	GameState.journey_serial += 1
	story.advance()
	check.call(game._active_story == story and not story.departure_committed and not bool(GameState.campaign().departure_seen), "a stale journey cannot commit from the ending card")
	GameState.journey_serial = owned_serial
	for field in ["inventory","pets","structures","portals","forest_health","settlement_layout","gold"]:
		check.call(JSON.parse_string(JSON.stringify(GameState.data.get(field))) == JSON.parse_string(JSON.stringify(entry_snapshot.get(field))), "long reading, capture, pause and skip preserve entry %s" % field)
	# A cancelled ending preserves progress and restores normal controls.
	story.cancel()
	await game.get_tree().process_frame
	check.call(not game._story_active and not bool(GameState.campaign().get("departure_seen",false)) and not game.player().controls_locked and game.hud.visible, "cancel at final card restores the world without consuming departure")
	for phase in range(ReunionDialogueDB.final_page()+1):
		check.call(game.begin_final_departure(dock), "ending can start fresh after cancellation")
		var interrupted := game._active_story
		interrupted.set_process(false)
		interrupted.page = phase
		interrupted._render()
		interrupted.cancel()
		await game.get_tree().process_frame
		check.call(not game._story_active and not game.player().controls_locked and game.world.process_mode != Node.PROCESS_MODE_DISABLED and not bool(GameState.campaign().get("departure_seen",false)), "cancellation at phase %d restores controls and preserves pending departure" % phase)
	for elapsed in ReunionDialogueDB.SHOT_STARTS:
		check.call(game.begin_final_departure(dock), "each film shot can start a cancellation fixture")
		var interrupted := game._active_story
		interrupted.set_process(false)
		interrupted.page = ReunionDialogueDB.film_page()
		interrupted._reunion_beat_time = float(elapsed)+0.2
		interrupted._render()
		interrupted.advance() # Cancel while manually paused.
		interrupted.cancel()
		await game.get_tree().process_frame
		check.call(not game._story_active and not game.player().controls_locked and not bool(GameState.campaign().departure_seen), "cancelling paused film at %.1fs preserves the pending ending" % float(elapsed))
	# Actual pointer entry, skip ending, durable save and covered title transition.
	await _pointer(game,dock._hint,true)
	check.call(game._active_story != null, "the visible contextual Embark banner also accepts a nearby touch")
	if game._active_story != null: game._active_story.cancel()
	await game.get_tree().process_frame
	await _world_pointer(game,dock.position,false)
	story = game._active_story
	check.call(story != null, "nearby mouse starts the same guarded ending")
	# Cancellation deliberately resumes village simulation between fixtures. Compare
	# each ending to its own entry, so legitimate intervening repairs are not failures.
	var completion_snapshot := GameState.data.duplicate(true)
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
		check.call(JSON.parse_string(JSON.stringify(GameState.data.get(field))) == JSON.parse_string(JSON.stringify(completion_snapshot.get(field))), "departure preserves its entry %s" % field)
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
	game._active_story.cancel()
	await game.get_tree().process_frame
	for phase in range(ReunionDialogueDB.final_page()+1):
		await game._load_lobby(false)
		var invitation := (game.world as Lobby).final_departure
		game.player().position = invitation.position
		check.call(game.begin_final_departure(invitation), "world-handoff fixture starts phase %d" % phase)
		var interrupted := game._active_story
		if interrupted == null: continue
		interrupted.set_process(false)
		interrupted.page = phase
		interrupted._reunion_beat_time = 10.5 if phase == ReunionDialogueDB.film_page() else 0.0
		interrupted._render()
		game._clear_world()
		await game.get_tree().process_frame
		check.call(game._active_story == null and not game._story_active and not bool(GameState.campaign().departure_seen), "world replacement cancels phase %d without saving completion" % phase)

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
