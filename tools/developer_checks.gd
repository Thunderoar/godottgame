extends RefCounted
## All writes are inside the harness user directory; the normal save is byte-checked.

static func run(game: Game, check: Callable, capture: Callable = Callable()) -> void:
	var saved := GameState.data.duplicate(true)
	var had_save := GameState.has_existing_save
	var autosave := GameState.autosave_enabled
	var ticking := game.is_processing()
	var state_ticking := GameState.is_processing()
	var quests := game._side_quest_auto_enabled
	var settings := GameSettings._values.duplicate(true)
	var access_before := GameSettings.is_developer_unlocked()
	var existed := FileAccess.file_exists(GameState.SAVE_PATH)
	var old_bytes := FileAccess.get_file_as_bytes(GameState.SAVE_PATH) if existed else PackedByteArray()
	game.set_process(false)
	GameState.set_process(false)
	game._side_quest_auto_enabled = false
	game.hud.hide_modals()
	game._clear_world()
	game._remove_title()
	await game.get_tree().process_frame
	GameState.autosave_enabled = false
	GameState.data = GameState._make_default("adam")
	GameState.data.campaign.intro_seen = true
	GameState.data.campaign.dock_welcome_seen = true
	GameState.data.portal_origin.opened = true
	GameSettings.set_value("tutorial_hidden",true,false)
	GameSettings.lock_developer()
	await game._load_lobby(false)
	GameState.save_game()
	var normal := FileAccess.get_file_as_bytes(GameState.SAVE_PATH)
	var baseline := GameState.data.duplicate(true)
	check.call(not game.open_developer_tools() and not GameState.begin_developer_session(), "locked access rejects workbench and test-session entry")
	check.call(not GameState.developer_prepare("progress_supplies") and not GameState.set_developer_option("invulnerable",true), "locked state APIs cannot change progress or protection")
	var denied := await game.run_developer_action("travel_prison")
	check.call(not bool(denied.ok), "locked direct action API cannot bypass the code")
	check.call(not DeveloperAccess.matches("") and not GameSettings.unlock_developer("incorrect-developer-code"), "empty and incorrect codes remain locked")
	check.call(GameSettings._developer_next_attempt_ms > Time.get_ticks_msec(), "incorrect code applies a short retry delay")
	game.open_settings()
	await game.get_tree().process_frame
	await game.get_tree().process_frame
	var access: DeveloperAccessControl
	for child in game.hud.settings_panel.content.get_children():
		if child is DeveloperAccessControl and not child.is_queued_for_deletion(): access = child
	check.call(is_instance_valid(access) and access.code_input.secret, "Settings exposes a masked developer-code field")
	if capture.is_valid(): await capture.call("developer_01_locked_settings")
	# The real phrase is supplied externally; it is never embedded in tests or captures.
	var code := OS.get_environment("PB_DEVELOPER_TEST_CODE")
	if not code.is_empty():
		GameSettings._developer_next_attempt_ms = 0
		access.code_input.text = code
		await _pointer(game,access._locked.get_child(0).get_child(1),false)
		check.call(GameSettings.is_developer_unlocked() and access.code_input.text.is_empty(), "correct code unlocks through Settings and clears the entry")
		GameSettings.save_settings()
		check.call(not FileAccess.get_file_as_string(GameSettings.config_path).contains(code), "settings persistence never contains the unlock phrase")
	else:
		# CI without the private phrase still exercises tools against an explicit fixture.
		GameSettings._developer_unlocked = true
		GameSettings.changed.emit("developer_access")
	check.call(GameSettings.is_developer_unlocked(), "developer access is available for this process only")
	await _pointer(game,access._unlocked.get_child(0),true)
	await game.get_tree().process_frame
	check.call(game.hud.developer_panel.visible and game.hud.any_modal_open() and game.world.process_mode == Node.PROCESS_MODE_DISABLED, "workbench is registered as a modal and explicitly suspends its owning world")
	var time := float(GameState.data.world_time)
	game._process(5)
	check.call(GameState.data.world_time == time, "workbench also suspends the shared world clock")
	# A failed fork must leave both the main file and live world generation intact.
	var dev_path := ProjectSettings.globalize_path(GameState.DEVELOPER_SAVE_PATH)
	var had_test := FileAccess.file_exists(dev_path)
	if had_test: DirAccess.rename_absolute(dev_path,dev_path+".check-backup")
	DirAccess.make_dir_absolute(dev_path)
	var serial_before := GameState.journey_serial
	check.call(not await game.start_developer_test() and not GameState.developer_session_active() and GameState.journey_serial == serial_before and game.world.journey_serial == serial_before, "failed test-save creation keeps the normal world owned and the session inactive")
	check.call(FileAccess.get_file_as_bytes(GameState.SAVE_PATH) == normal, "failed test-session creation leaves the normal save byte-identical")
	DirAccess.remove_absolute(dev_path)
	if had_test: DirAccess.rename_absolute(dev_path+".check-backup",dev_path)
	var started := await game.start_developer_test()
	await game.get_tree().process_frame
	check.call(started and GameState.developer_session_active() and GameState.save_path() == GameState.DEVELOPER_SAVE_PATH, "starting a test forks progression to a separate save path")
	check.call(FileAccess.get_file_as_bytes(GameState.SAVE_PATH) == normal, "starting the test never rewrites the normal save")
	check.call(game.hud.developer_panel.visible and not game.hud.developer_panel._busy, "test session opens the usable workbench")
	if capture.is_valid(): await capture.call("developer_02_travel")
	var view := Rect2(Vector2.ZERO,game.get_viewport_rect().size)
	check.call(view.encloses(game.hud.developer_panel.panel.get_global_rect()) and view.encloses(game.hud.developer_panel._close_button.get_global_rect()), "workbench and Close remain inside the supported viewport")
	GameState.set_developer_option("invulnerable",true)
	var hp := GameState.health()
	GameState.damage_player(5000)
	check.call(GameState.health() == hp, "Protect Adam prevents damage only inside the test session")
	GameState.set_developer_option("invulnerable",false)
	GameState.damage_player(3)
	check.call(GameState.health() < hp, "turning protection off restores ordinary damage")
	GameState.set_developer_option("freeze_time",true)
	game.hud.developer_panel.close_panel()
	time = float(GameState.data.world_time)
	game._process(2)
	check.call(GameState.data.world_time == time, "Freeze world clock works after closing the workbench")
	GameState.set_developer_option("freeze_time",false)
	game._process(0.25)
	check.call(float(GameState.data.world_time) > time, "closing the workbench resumes ordinary simulation when time is unfrozen")
	var healed := await game.run_developer_action("progress_heal")
	check.call(bool(healed.ok) and GameState.health() == GameState.health_max() and GameState.has_living_pet(), "health shortcut restores Adam and his companion")
	var gold := GameState.gold()
	var result := await game.run_developer_action("progress_supplies")
	check.call(bool(result.ok) and GameState.gold() == gold+5000 and GameState.item_count("health_potion") >= 50, "test supplies use an accepted GameState transaction")
	check.call(FileAccess.get_file_as_bytes(GameState.SAVE_PATH) == normal and FileAccess.file_exists(GameState.DEVELOPER_SAVE_PATH), "test rewards write only the separate test save")
	check.call(GameState.load_game() and GameState.gold() == gold+5000, "Continue/load inside a test session reads the separate test save")
	GameState.delete_save()
	check.call(not FileAccess.file_exists(GameState.DEVELOPER_SAVE_PATH) and FileAccess.get_file_as_bytes(GameState.SAVE_PATH) == normal, "deleting test progress cannot delete the normal journey")
	GameState.save_game()
	denied = await game.run_developer_action("unknown-test-command")
	check.call(not bool(denied.ok), "only catalogued developer actions are accepted")
	# The first-night introductions have separate acceptance coverage. Keep this
	# phase-switch check on the ordinary nonblocking arrival route.
	GameState.data.campaign.urchin_intro_seen = true
	GameState.data.campaign.fire_intro_seen = true
	result = await game.run_developer_action("progress_night")
	check.call(bool(result.ok) and GameState.is_night(), "night shortcut advances to a real nighttime phase")
	result = await game.run_developer_action("progress_day")
	check.call(bool(result.ok) and not GameState.is_night(), "day shortcut advances to the next day")
	for preset in ["progress_arjun","progress_mei","progress_reset"]:
		result = await game.run_developer_action(preset)
		if preset == "progress_arjun": check.call(bool(result.ok) and bool(GameState.campaign().arjun_rescued) and not GameState.sea_journey_available(), "marking Arjun rescued closes only the test sea route")
		if preset == "progress_mei": check.call(bool(result.ok) and GameState.friends_reunited() and game._active_story == null, "marking Mei Ling rescued prepares a voluntary test reunion")
		if preset == "progress_reset": check.call(bool(result.ok) and not GameState.friends_reunited() and GameState.sea_journey_available() and not bool(GameState.portal_state(PortalDB.MEI_LING_PORTAL).cleared), "reset shortcut reopens both real rescue routes in the test journey")
	# Reach all world families through Game-owned construction, not scene replacement.
	for id in ["travel_dock","travel_twilight","travel_citadel","travel_tempest","travel_abyss","travel_sea_1","travel_sea_2","travel_kraken","travel_prison"]:
		result = await game.run_developer_action(id)
		check.call(bool(result.ok) and is_instance_valid(game.world), "%s reaches a live owned test world" % id)
		if id == "travel_dock": check.call(game.player().position.distance_to(game.world.ship_boarding.position) < 2, "dock travel places Adam on the real jetty")
		if id == "travel_twilight": check.call(game.world is TwilightRealm and not game.world._boss_arrived, "Wilds travel preserves exploration before the boss threshold")
		if id == "travel_citadel": check.call(game.world is TwilightRealm and game.world._boss_arrived and game.world.boss.active, "citadel travel activates the real chamber encounter")
		if id == "travel_tempest": check.call(game.world is Dungeon and game.world.portal_id == "sunken_crypt", "wind arena jump bypasses gates only in the test journey")
		if id == "travel_abyss": check.call(game.world is Dungeon and game.world.portal_id == "drowned_throne", "final portal jump uses the existing optional arena")
		if id in ["travel_tempest","travel_abyss"]:
			var boss_result := await game.run_developer_action("progress_boss")
			check.call(bool(boss_result.ok) and bool(GameState.portal_state("sunken_crypt" if id == "travel_tempest" else "drowned_throne").cleared), "optional arena boss shortcut goes through the normal clear transaction")
		if id.begins_with("travel_sea_"):
			check.call(game.world is OceanJourney and game.world.stage == (1 if id.ends_with("1") else 2), "sea jump configures the selected route checkpoint")
			game.open_developer_tools()
			await game.get_tree().process_frame
			check.call(game.hud.developer_panel.is_visible_in_tree() and game.world.process_mode == Node.PROCESS_MODE_DISABLED, "developer tools remain usable above the sea's independent HUD")
			if capture.is_valid() and id.ends_with("2"): await capture.call("developer_03_ocean_tools")
		if id == "travel_kraken": check.call(game.world.crabs.size() == 10 and not game.world.defeated and not game.world.cage.available, "Kraken jump retains the full fight and locked cage")
		if id == "travel_prison": check.call(game.world.defeated and game.world.cage.available and not bool(GameState.campaign().arjun_rescued), "prison shortcut defeats the real boss but leaves the separate rescue interaction")
		check.call(FileAccess.get_file_as_bytes(GameState.SAVE_PATH) == normal, "normal save remains byte-identical after %s" % id)
	# Actually rescue Arjun and complete the incoming passenger handoff.
	game.player().position = game.world.cage.position
	game.world.cage.interact(game.player())
	check.call(bool(GameState.campaign().arjun_rescued) and game._active_story != null, "developer prison visit can perform the actual Arjun rescue")
	if game._active_story != null: game._active_story.finish()
	for step in 160:
		if game.world is Lobby and not game._transitioning: break
		await game.get_tree().create_timer(0.02).timeout
	if game.world is Lobby:
		var boarding: ShipDeparture = game.world.ship_boarding
		boarding.ship.position = boarding._moored_position
		boarding._physics_process(0)
		game.player().position = boarding.position
		boarding._physics_process(0.01)
		if game._arjun_walk != null and game._arjun_walk.is_valid():
			game._arjun_walk.pause()
			game._arjun_walk.custom_step(300)
		await game.get_tree().process_frame
	check.call(game.world is Lobby and not game._sailing and not game._arjun_returning, "developer rescue still docks and hands Arjun to the village normally")
	result = await game.run_developer_action("travel_citadel")
	result = await game.run_developer_action("progress_boss")
	check.call(bool(result.ok) and bool(GameState.campaign().mei_ling_rescued) and game._active_story != null and game._active_story.kind == "mei", "Finish current boss follows the real Mei Ling rescue transaction and animatic")
	if game._active_story != null: game._active_story.finish()
	await game.get_tree().process_frame
	for id in ["scene_intro","scene_arjun","scene_mei","scene_welcome"]:
		result = await game.run_developer_action(id)
		check.call(bool(result.ok) and (game._active_story != null or is_instance_valid(game._dock_conversation)), "%s starts its owned story preview" % id)
		if game._active_story != null: game._active_story.finish()
		if is_instance_valid(game._dock_conversation): game._dock_conversation.finish()
		await game.get_tree().process_frame
	result = await game.run_developer_action("progress_dock")
	check.call(bool(result.ok) and GameState.friends_reunited() and game.world.departure_friends_ready() and game._active_story == null, "dock preset prepares both live friends for manual Embark")
	game.open_developer_tools()
	await game.get_tree().process_frame
	game.hud.developer_panel._tab = "Progress"
	game.hud.developer_panel._rebuild()
	await game.get_tree().process_frame
	if capture.is_valid(): await capture.call("developer_04_progress")
	result = await game.run_developer_action("scene_ending")
	var ending := game._active_story
	check.call(bool(result.ok) and ending != null and ending.kind == "ending", "full ending action uses the actual dock readiness and story entry")
	if ending != null:
		ending.set_process(false)
		ending._process(0.4)
		ending._on_skip_pressed()
		ending._process(0.3)
		ending._on_skip_pressed()
		ending._process(2.1)
		ending.advance()
		for step in 160:
			if is_instance_valid(game.title_screen) and not game._transitioning: break
			await game.get_tree().create_timer(0.02).timeout
	check.call(GameState.developer_session_active() and bool(GameState.campaign().departure_seen) and is_instance_valid(game.title_screen), "test ending can save and return to title without ending the protected session")
	game._refresh_developer_overlay()
	check.call(game._developer_bar.visible and game._developer_label.text.contains("TEST JOURNEY"), "a test journey remains clearly labelled and accessible at title")
	check.call(FileAccess.get_file_as_bytes(GameState.SAVE_PATH) == normal, "full reunion and sailing completion never rewrite normal progress")
	GameState.new_game("adam")
	check.call(GameState.developer_session_active() and FileAccess.get_file_as_bytes(GameState.SAVE_PATH) == normal, "even New Journey inside developer testing stays on the test save")
	game._on_game_over("Developer isolation fixture")
	check.call(not FileAccess.file_exists(GameState.DEVELOPER_SAVE_PATH) and FileAccess.get_file_as_bytes(GameState.SAVE_PATH) == normal, "test game over cannot delete the protected normal journey")
	check.call(await game.end_developer_test(true), "ending the developer session restores the original journey")
	check.call(not GameState.developer_session_active() and not GameSettings.is_developer_unlocked() and GameState.save_path() == GameState.SAVE_PATH and not GameState.developer_option("invulnerable"), "restore-and-lock removes access and every session-only option")
	check.call(GameState.gold() == int(baseline.gold) and GameState.campaign() == baseline.campaign and FileAccess.get_file_as_bytes(GameState.SAVE_PATH) == normal, "normal currency, rescue flags and save bytes survive all developer actions")
	# Title settings also support creating and restoring a test session directly.
	await game.return_to_title()
	var title_normal := FileAccess.get_file_as_bytes(GameState.SAVE_PATH)
	game.title_screen._open_settings()
	await game.get_tree().process_frame
	var title_access := false
	for child in game.title_screen._overlay_body.get_children():
		if child is DeveloperAccessControl: title_access = child.code_input.secret
	check.call(title_access, "title Settings includes the same masked access control")
	GameSettings._developer_unlocked = true
	GameSettings.changed.emit("developer_access")
	game.open_developer_tools()
	check.call(await game.start_developer_test(), "a test journey can start directly from title settings")
	await game.run_developer_action("progress_supplies")
	check.call(await game.end_developer_test(true) and game.world == null and is_instance_valid(game.title_screen) and FileAccess.get_file_as_bytes(GameState.SAVE_PATH) == title_normal, "ending a title-started test restores title and the untouched normal save")
	# Prefer a newer normal record written by another game while testing.
	GameSettings._developer_unlocked = true
	GameSettings.changed.emit("developer_access")
	game.open_developer_tools()
	await game.start_developer_test()
	var newer := baseline.duplicate(true)
	newer.gold = int(baseline.gold)+321
	var concurrent := FileAccess.open(GameState.SAVE_PATH,FileAccess.WRITE)
	concurrent.store_string(JSON.stringify(newer))
	concurrent.close()
	var newer_bytes := FileAccess.get_file_as_bytes(GameState.SAVE_PATH)
	await game.end_developer_test(true)
	check.call(GameState.gold() == int(newer.gold) and FileAccess.get_file_as_bytes(GameState.SAVE_PATH) == newer_bytes, "ending a test prefers a newer normal save without overwriting it with the old snapshot")
	game._remove_title()
	await game._load_lobby(false)
	GameSettings._developer_unlocked = true
	GameSettings.changed.emit("developer_access")
	game.open_developer_tools()
	await game.start_developer_test()
	concurrent = FileAccess.open(GameState.SAVE_PATH,FileAccess.WRITE)
	concurrent.store_string("unreadable concurrent save fixture")
	concurrent.close()
	await game.end_developer_test(true)
	game._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	check.call(game.world == null and is_instance_valid(game.title_screen) and not GameState.autosave_enabled and FileAccess.get_file_as_string(GameState.SAVE_PATH) == "unreadable concurrent save fixture", "an unreadable changed normal save stays untouched and returns safely to title")
	concurrent = FileAccess.open(GameState.SAVE_PATH,FileAccess.WRITE)
	concurrent.store_string(JSON.stringify(newer))
	concurrent.close()
	GameState._developer_return_autosave = true
	check.call(GameState.continue_game() and GameState.autosave_enabled and not GameState.developer_restore_requires_title(), "retrying Continue after a repaired normal save restores normal autosaving")
	# A developer starting from a never-played title must not create a journey.
	var normal_path := ProjectSettings.globalize_path(GameState.SAVE_PATH)
	DirAccess.rename_absolute(normal_path,normal_path+".no-save-check")
	GameState.data = GameState._make_default("adam")
	GameState.has_existing_save = false
	GameState.autosave_enabled = true
	game._remove_title()
	game._show_title()
	GameSettings._developer_unlocked = true
	GameSettings.changed.emit("developer_access")
	game.open_developer_tools()
	await game.start_developer_test()
	await game.end_developer_test(true)
	game._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	check.call(game.world == null and not GameState.has_existing_save and not FileAccess.file_exists(GameState.SAVE_PATH), "a title-started test with no normal journey leaves no save behind, including on focus loss")
	DirAccess.rename_absolute(normal_path+".no-save-check",normal_path)
	game._remove_title()
	GameSettings.save_settings()
	GameSettings._developer_unlocked = true
	GameSettings.load_settings()
	check.call(not GameSettings.is_developer_unlocked(), "reloading device settings always starts with developer access locked")
	game.hud.hide_modals()
	game._clear_world()
	await game.get_tree().process_frame
	GameState.data = saved
	GameState.autosave_enabled = autosave
	GameState.has_existing_save = had_save
	GameState._emit_all()
	await game._load_lobby(false)
	if existed:
		var file := FileAccess.open(GameState.SAVE_PATH,FileAccess.WRITE)
		file.store_buffer(old_bytes)
		file.close()
	else: DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.SAVE_PATH))
	GameState.has_existing_save = had_save
	GameSettings._values = settings
	GameSettings._apply_all()
	GameSettings.save_settings()
	GameSettings._developer_unlocked = access_before
	game._side_quest_auto_enabled = quests
	game.set_process(ticking)
	GameState.set_process(state_ticking)

static func _pointer(game: Game, button: Button, touch: bool) -> void:
	await game.get_tree().process_frame
	await game.get_tree().process_frame
	var at := game.get_viewport().get_final_transform()*(button.get_global_transform_with_canvas()*(button.size/2))
	for pressed in [true,false]:
		if touch:
			var event := InputEventScreenTouch.new()
			event.index = 12
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
