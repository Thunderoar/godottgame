extends RefCounted
## Progression, input ownership and rendered-layout coverage for the HUD accordion.

static func run(game: Game, check: Callable, capture: Callable = Callable()) -> void:
	var saved := GameState.data.duplicate(true)
	var autosave := GameState.autosave_enabled
	var ticking := game.is_processing()
	var hud_visible := game.hud.visible
	var settings := GameSettings._values.duplicate(true)
	var config_path := GameSettings.config_path
	var window_size := game.get_window().size
	var canvas_size := game.get_window().content_scale_size
	# Pointer injection below uses logical coordinates. Prior checks can leave a
	# stretched compact window, so establish a 1:1 viewport before those gestures.
	game.get_window().content_scale_size = Vector2i(1280, 720)
	game.get_window().size = Vector2i(1280, 720)
	game.hud.hide_modals()
	game.set_process(false)
	GameState.autosave_enabled = false
	game._clear_world()
	await game.get_tree().process_frame
	GameState.data = GameState._make_default("adam")
	GameState._emit_all()
	await game._load_lobby(false)
	game.world.process_mode = Node.PROCESS_MODE_DISABLED
	game.hud.visible = true
	game.hud.tutorial_guide._skip()
	GameSettings.set_value("objectives_collapsed", false, false)
	var tracker := game.hud.objective_tracker
	game.hud._refresh_objectives()
	await _settle(game)
	check.call(tracker.is_visible_in_tree() and tracker._entries[0].id == "lesson_move", "objective tracker starts expanded with the current village lesson")
	check.call(tracker._scroll.visible and not game.hud.any_modal_open() and not game._input_locked, "expanded objectives leave gameplay and simulation unlocked")
	var before := GameState.data.duplicate(true)
	for i in 5: game.hud._refresh_objectives()
	check.call(GameState.data == before, "objective refresh is read-only and creates no progression or reward mutations")
	Input.action_press("move_right")
	await _click(game, tracker._header)
	check.call(tracker.collapsed() and tracker._summary.visible and not tracker._scroll.visible, "touching the header collapses to a current-objective summary")
	check.call(Input.is_action_pressed("move_right") and not game._input_locked and not game.get_tree().paused, "collapsing objectives does not release held movement or pause the world")
	Input.action_release("move_right")
	GameState.record_mission_event("move")
	check.call(tracker.collapsed() and tracker._entries[0].id == "lesson_gather" and tracker._summary.text == tracker._entries[0].title, "progress updates a collapsed summary without reopening it")
	await _click(game, tracker._header)
	check.call(not tracker.collapsed(), "a second header touch restores expanded objectives")
	var header_center := _rect(tracker._header).get_center()
	await _touch(game, header_center, true)
	await _touch(game, Vector2(700, 400), false)
	check.call(not tracker.collapsed() and tracker._touch_id == -1, "dragging a header touch away cancels the toggle and releases its finger")
	await _touch(game, header_center, true)
	tracker.hide()
	await _touch(game, header_center, false)
	check.call(not tracker.collapsed() and tracker._touch_id == -1, "hiding the tracker cancels an in-progress header gesture")
	game.hud._update_objective_visibility()
	await _touch(game, header_center, true)
	tracker._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	await _touch(game, header_center, false)
	check.call(not tracker.collapsed() and tracker._touch_id == -1, "focus loss cancels an in-progress objective touch")
	for pressed in [true, false]:
		var mouse := InputEventMouseButton.new()
		mouse.button_index = MOUSE_BUTTON_LEFT
		mouse.position = header_center
		mouse.pressed = pressed
		Input.parse_input_event(mouse)
		await game.get_tree().process_frame
	check.call(tracker.collapsed(), "mouse clicks toggle the same objective header")
	GameSettings.set_value("objectives_collapsed", false, false)
	tracker._header.grab_focus()
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = KEY_ENTER
		event.pressed = pressed
		Input.parse_input_event(event)
		await game.get_tree().process_frame
	check.call(tracker.collapsed(), "focused objective header supports keyboard activation")
	tracker._header.release_focus()
	GameSettings.config_path = "user://objective-tracker-settings.cfg"
	GameSettings.save_settings()
	GameSettings.set_value("objectives_collapsed", false, false)
	GameSettings.load_settings()
	check.call(tracker.collapsed(), "collapse preference survives a device-settings reload")
	check.call(not GameState.data.settings.has("objectives_collapsed"), "collapse preference stays outside journey data")
	var legacy_config := ConfigFile.new()
	legacy_config.set_value(GameSettings.SECTION, "ui_scale", 100)
	legacy_config.save(GameSettings.config_path)
	GameSettings.load_settings()
	check.call(not tracker.collapsed(), "older device settings without the new key default to expanded objectives")
	GameSettings.set_value("objectives_collapsed", {}, false)
	check.call(not tracker.collapsed(), "invalid collapse preference values sanitize to the default")
	GameSettings.set_value("objectives_collapsed", false, false)
	GameSettings.config_path = config_path
	GameState.advance_world_clock(180)
	game.hud._refresh_objectives()
	check.call(tracker._entries.any(func(row: Dictionary) -> bool: return row.id == "lesson_fire_kill"), "night changes the displayed lesson to village defense")
	var danger := ObjectiveTrackerData.entries(game.world, {"fires": 1})
	check.call(danger[0].id == "defend" and bool(danger[0].urgent), "local burning trees take priority over normal village lessons")
	check.call(ObjectiveTrackerData.entries(game.world, {"monsters": 2})[0].id == "defend", "ordinary village attackers also take priority without requiring an expedition emergency")
	game.open_menu()
	game.hud._update_objective_visibility()
	check.call(not tracker.visible, "opening a full-screen modal hides the objective tracker")
	game.hud.menu_panel.close_panel()
	game.hud._update_objective_visibility()
	check.call(tracker.visible and not tracker.collapsed(), "closing a modal restores the chosen expansion state")
	game._story_active = true
	game.hud._update_objective_visibility()
	check.call(not tracker.visible, "story ownership suppresses the tracker")
	game._story_active = false
	# Retire the night attackers before presenting a peaceful workshop fixture.
	for child in game.world.get_children():
		if child is Enemy: child.queue_free()
	await game.get_tree().process_frame
	game.hud._status_strip.refresh_world(game.world)
	GameState.data.world_time = 0.0
	GameState.data.portals[RealmDB.PORTAL].cleared = true
	GameState.data.village_progression.projects[VillageProjectDB.WORKSHOP] = {"state": "working", "remaining": 5.0}
	GameState._emit_all()
	game.hud._refresh_objectives()
	check.call(tracker._entries[0].id == "workshop" and is_equal_approx(float(tracker._entries[0].progress), 0.5), "workshop objective uses actual remaining construction work")
	GameState.data.village_progression.projects[VillageProjectDB.WORKSHOP].remaining = 2.0
	var first_card: Label = tracker._cards[0].title
	game.hud._process(0.21)
	check.call(is_equal_approx(float(tracker._entries[0].progress), 0.8), "throttled refresh follows construction without requiring save signals")
	check.call(tracker._cards[0].title == first_card, "construction refresh updates cards in place instead of rebuilding the scroll content")
	GameState.data.campaign.arjun_rescued = true
	GameState.data.campaign.mei_ling_rescued = true
	GameState.data.village_progression.projects[VillageProjectDB.WORKSHOP].state = "complete"
	game.hud._refresh_objectives()
	check.call(tracker._entries.size() == 1 and tracker._entries[0].id == "home", "completed rescues and workshop retire their goals and leave peaceful village guidance")
	GameState.data.campaign.arjun_rescued = false
	GameState.data.campaign.mei_ling_rescued = false
	GameState.data.village_progression.projects[VillageProjectDB.WORKSHOP].state = "working"
	game.hud._refresh_objectives()
	await _layouts(game, check, capture)
	# Exercise context selection independently of an actor's temporary ready state.
	var realm := TwilightRealm.new()
	GameState.data = GameState._make_default("adam")
	check.call(ObjectiveTrackerData.entries(realm)[0].id == "explore", "realm arrival replaces village training with exploration without exposing an undiscovered ruler")
	GameState.data.realm_progress.landmarks.append("approach")
	var rows := ObjectiveTrackerData.entries(realm)
	check.call(rows[0].id == "checkpoint", "discovering the approach suggests the lantern before the boss")
	GameState.data.realm_progress.checkpoint = "camp"
	check.call(ObjectiveTrackerData.entries(realm)[0].id == "citadel", "saved lantern checkpoint advances guidance to the citadel arch")
	realm._boss_arrived = true
	check.call(ObjectiveTrackerData.entries(realm)[0].id == "citadel_boss", "crossing the boss threshold changes the immediate objective")
	realm._boss_arrived = false
	realm._boss_defeated = true
	GameState.data.realm_progress.landmarks.append("grove")
	rows = ObjectiveTrackerData.entries(realm)
	check.call(rows[0].id == "restored" and rows.any(func(row: Dictionary) -> bool: return row.id == "companions" and row.tag == "OPTIONAL"), "a restored realm offers peaceful exploration and discovered optional companions")
	GameState.data.realm_progress.bonded.append("bramble_cat")
	check.call(not ObjectiveTrackerData.entries(realm).any(func(row: Dictionary) -> bool: return row.id == "companions"), "bonded pets leave optional guidance without requiring tournament clears")
	realm.free()
	var island := KrakenIsland.new()
	check.call(ObjectiveTrackerData.entries(island)[0].id == "kraken", "island guidance starts with the Kraken encounter")
	island.defeated = true
	check.call(ObjectiveTrackerData.entries(island)[0].id == "free_arjun", "Kraken victory still requires the separate prison interaction")
	GameState.data.campaign.arjun_rescued = true
	check.call(ObjectiveTrackerData.entries(island)[0].id == "shore", "rescued Arjun is never presented as still imprisoned")
	island.free()
	var dungeon := Dungeon.new()
	dungeon.portal_id = "sunken_crypt"
	check.call(ObjectiveTrackerData.entries(dungeon)[0].title.contains("Gale Tempest Demon"), "later arenas identify their actual ruler")
	dungeon._boss_defeated = true
	check.call(ObjectiveTrackerData.entries(dungeon)[0].id == "return", "cleared later arenas stop asking the player to defeat a dead boss")
	dungeon.free()
	game._clear_world()
	await game.get_tree().process_frame
	GameState.data = GameState._make_default("adam")
	GameState._emit_all()
	GameState.start_expedition(RealmDB.PORTAL)
	await game._load_dungeon(RealmDB.PORTAL, false)
	game.world.process_mode = Node.PROCESS_MODE_DISABLED
	game.hud._refresh_objectives()
	check.call(tracker._entries[0].id == "explore" and not tracker.collapsed(), "real world handoff replaces the displayed objectives and keeps the panel preference")
	if capture.is_valid():
		await _settle(game)
		await capture.call("realm_exploration")
	game.hud.set_world(null)
	check.call(not tracker.visible and tracker._entries.is_empty(), "world removal immediately clears stale objectives")
	game._clear_world()
	await game.get_tree().process_frame
	GameState.data = saved
	GameState._emit_all()
	for key in settings: GameSettings.set_value(str(key), settings[key], false)
	GameSettings.save_settings()
	game.get_window().content_scale_size = canvas_size
	game.get_window().size = window_size
	await game._load_lobby(false)
	game.hud.visible = hud_visible
	GameState.autosave_enabled = autosave
	game.set_process(ticking)

static func _layouts(game: Game, check: Callable, capture: Callable) -> void:
	var tracker := game.hud.objective_tracker
	for dimensions in [Vector2i(1280, 720), Vector2i(832, 480)]:
		game.get_window().content_scale_size = dimensions
		game.get_window().size = dimensions
		for scale_percent in [75, 100, 130]:
			GameSettings.set_ui_scale(scale_percent, false)
			GameSettings.set_touch_controls("always", false)
			GameSettings.set_value("objectives_collapsed", false, false)
			game.hud._layout_gui()
			await _settle(game)
			var rect := _rect(tracker)
			var clear := game.hud._root.get_global_rect().encloses(rect)
			for control: Control in game.hud._control_nodes.values():
				if control.visible: clear = clear and not rect.intersects(_rect(control))
			if game.hud._progression_notice.visible: clear = clear and not rect.intersects(_rect(game.hud._progression_notice))
			check.call(clear, "expanded objectives fit and clear touch controls and reward guidance at %dx%d / %d%%" % [dimensions.x, dimensions.y, scale_percent])
			check.call(tracker._header.size.y * tracker.scale.y >= 43.9 and not tracker._scroll.get_h_scroll_bar().visible, "objective header stays touch-sized with no sideways scrolling at %dx%d / %d%%" % [dimensions.x, dimensions.y, scale_percent])
			if capture.is_valid() and scale_percent == 100:
				await capture.call("expanded_%dx%d" % [dimensions.x, dimensions.y])
			GameSettings.set_value("objectives_collapsed", true, false)
			await _settle(game)
			check.call(_rect(tracker).size.y < rect.size.y and tracker._summary.visible, "collapse reclaims space while keeping the current goal at %dx%d / %d%%" % [dimensions.x, dimensions.y, scale_percent])
			if capture.is_valid() and scale_percent == 100:
				await capture.call("collapsed_%dx%d" % [dimensions.x, dimensions.y])
	GameSettings.set_value("objectives_collapsed", false, false)
	GameSettings.set_ui_scale(130, false)
	var joystick := game.hud._joystick
	var original := joystick.position
	joystick.position.y = 280
	game.hud._layout_objectives()
	await _settle(game)
	check.call(not _rect(tracker).intersects(_rect(joystick)), "objective layout respects a relocated left joystick")
	joystick.position = original
	game.hud._layout_gui()
	GameSettings.set_ui_scale(100, false)

static func _rect(control: Control) -> Rect2:
	return Rect2(control.global_position, control.size * control.get_global_transform().get_scale())

static func _settle(game: Game) -> void:
	for frame in 6: await game.get_tree().process_frame

static func _click(game: Game, button: Button) -> void:
	for pressed in [true, false]:
		await _touch(game, _rect(button).get_center(), pressed)
	await _settle(game)

static func _touch(game: Game, at: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.position = at
	event.pressed = pressed
	event.index = 6
	Input.parse_input_event(event)
	await game.get_tree().process_frame
