extends RefCounted
## Actual pointer input, saved layout round trips and a fatal shark capture.

static func run(game: Game, check: Callable, capture: Callable = Callable()) -> void:
	var saved := GameState.data.duplicate(true)
	var autosave := GameState.autosave_enabled
	var scale := GameSettings.ui_scale()
	var tips := game.hud.tutorial_guide._tips_enabled
	GameState.autosave_enabled = false
	game.hud.hide_modals()
	GameState.data = GameState._make_default("adam")
	GameState.data.campaign.intro_seen = true
	GameState.data.campaign.dock_welcome_seen = true
	GameState.data.portal_origin.opened = true
	GameState._emit_all()
	await game._load_lobby(false)
	# Hide the overlay for pointer tests without changing the device's Skip setting.
	game.hud.tutorial_guide._tips_enabled = false
	game.hud.tutorial_guide.hide()
	game._input_locked = false
	game._apply_input_lock()
	var lobby := game.world as Lobby
	lobby.player.set_physics_process(false)
	lobby.player.velocity = Vector2.ZERO
	var pan: Node = lobby.camera.get_node("VillageCameraPan")
	var view := game.get_viewport().get_visible_rect().size
	await game.get_tree().physics_frame
	var player_at := lobby.player.position
	var before := lobby.camera.global_position
	var at := Vector2(view.x * 0.65, view.y * 0.48)
	await _drag(game, at, at + Vector2(-110,35), false, false)
	check.call(lobby.camera.manual_pan and lobby.camera.global_position.distance_to(before) > 0.5, "mouse dragging empty village scenery pans the camera")
	check.call(lobby.player.position == player_at and pan._dragging and game.hud._root.get_node_or_null("FollowAdam") == null, "held inspection leaves Adam in place without requiring a Follow Adam button")
	if capture.is_valid(): await capture.call("03_village_camera_pan")
	await _release(game, at + Vector2(-110,35), false)
	check.call(not lobby.camera.manual_pan and pan._pointer == -2, "releasing the mouse immediately restores Adam camera ownership")
	await _drag(game, at, at + Vector2(100,-30), true, false)
	check.call(lobby.camera.manual_pan and pan._dragging and pan._pointer != -2, "holding a touch drag inspects the village")
	await _release(game, at + Vector2(100,-30), true)
	check.call(not lobby.camera.manual_pan and pan._pointer == -2, "lifting the touch automatically returns the camera to Adam")
	pan._begin(at,-1)
	pan._drag(at+Vector2(100,0))
	Input.action_press("move_right")
	pan._physics_process(0.01)
	Input.action_release("move_right")
	check.call(not lobby.camera.manual_pan, "walking returns camera ownership to Adam")
	pan._begin(at,-1)
	pan._drag(Vector2(-10000,-10000))
	var half := view / lobby.camera.zoom * 0.5
	check.call(lobby.camera.pan_center.x <= lobby.camera.bounds.end.x - half.x + 0.01 and lobby.camera.pan_center.y <= lobby.camera.bounds.end.y - half.y + 0.01, "inspection clamps the whole viewport inside village bounds")
	pan._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	check.call(not lobby.camera.manual_pan and pan._pointer == -2, "focus loss clears the camera gesture")
	game.open_settings()
	await _drag(game,at,at+Vector2(-100,30),true)
	check.call(not lobby.camera.manual_pan, "Settings blocks world inspection gestures")
	game.hud.settings_panel.close_panel()
	GameSettings.set_ui_scale(130,false)
	game.hud.set_control_layout("attack",150,view.y-135,96)
	check.call(game.hud._attack_button.position.is_equal_approx(Vector2(150,view.y-135)) and game.hud._attack_button.size.is_equal_approx(Vector2(96,96)) and game.hud._attack_button.scale == Vector2.ONE, "custom land controls match saved pixels even at 130 percent GUI scale")
	var editor := ControlLayoutEditor.new()
	game.get_tree().root.add_child(editor)
	await game.get_tree().process_frame
	editor._select("attack")
	editor.move_handle("attack", Vector2(225,view.y-145))
	editor._resize_selected(110)
	editor._commit_all()
	var land_at: Vector2 = editor._handles.attack.position
	check.call(game.hud._attack_button.position.is_equal_approx(land_at) and is_equal_approx(game.hud._attack_button.size.x,110), "drag editor and live attack button agree exactly on position and size")
	editor.queue_free()
	GameState.save_game()
	check.call(GameState.load_game() and game.hud._attack_button.position.is_equal_approx(land_at), "custom control placement survives actual save and load")
	await game._load_dungeon(RealmDB.PORTAL,false)
	check.call(game.hud._attack_button.position.is_equal_approx(land_at) and is_equal_approx(game.hud._attack_button.size.x,110), "portal gameplay keeps the same saved land controls")
	check.call(game.world.camera.get_node_or_null("VillageCameraPan") == null, "portal combat does not inherit village inspection gestures")
	if capture.is_valid(): await capture.call("04_portal_saved_controls")
	game._clear_world()
	var ocean := OceanJourney.new()
	game.world = ocean
	game._world_holder.add_child(ocean)
	game.hud.set_world(ocean)
	game.hud.hide()
	ocean.set_process(false)
	ocean._process(4)
	ocean.dismiss_sea_guide()
	game.hud.set_control_layout("ocean_pickup", view.x-180,view.y-165,112)
	game.hud.set_control_layout("ocean_joystick",40,view.y-220,160)
	check.call(ocean._pickup.position.is_equal_approx(Vector2(view.x-180,view.y-165)) and ocean._pickup.size == Vector2(112,112), "sea settings apply saved position and size immediately")
	editor = ControlLayoutEditor.new()
	game.get_tree().root.add_child(editor)
	await game.get_tree().process_frame
	check.call(editor._handles.ocean_pickup.position.is_equal_approx(ocean._pickup.position) and editor._handles.ocean_pickup.size.is_equal_approx(ocean._pickup.size), "sea drag editor previews the exact runtime controls")
	editor._select("ocean_pickup")
	editor.move_handle("ocean_pickup",Vector2(view.x-220,view.y-150))
	editor._resize_selected(100)
	editor._commit_all()
	check.call(ocean._pickup.position.is_equal_approx(editor._handles.ocean_pickup.position) and ocean._pickup.size == Vector2(100,100), "sea drag edits update the live controls without GUI scaling drift")
	editor.queue_free()
	GameSettings.set_ui_scale(75,false)
	ocean._apply_ocean_layout()
	check.call(ocean._pickup.size == Vector2(100,100) and game.hud._attack_button.size == Vector2(110,110), "changing GUI scale preserves custom sea and portal control sizes")
	if capture.is_valid(): await capture.call("07_ocean_saved_controls")
	var fish := ocean.spawn_item("food",ocean.mouth_position().x)
	var cursor := Sfx._next_player
	ocean._update_run(0)
	check.call(fish.resolved and Sfx._next_player == (cursor+1)%Sfx.PLAYER_POOL and Sfx.has_sound("turtle_eat"), "automatic fish feeding plays one dedicated eating sound")
	ocean._consume_item(fish)
	check.call(Sfx._next_player == (cursor+1)%Sfx.PLAYER_POOL, "a resolved fish cannot replay its eating sound")
	ocean.stage = 2
	ocean._hurt_time = 1.0 # Shark contact remains fatal during bomb blink immunity.
	var checkpoint := int(GameState.campaign().ocean_stage)
	var shark := ocean.spawn_item("shark",ocean.turtle.position.x+0.5)
	ocean._update_run(0)
	check.call(ocean.health == 0 and ocean.phase == OceanJourney.Phase.FINISHED and shark.resolved, "shark contact is immediately fatal even with three lives and blink immunity")
	check.call(not ocean._retry.visible and not Input.is_action_pressed("ocean_pickup"), "capture releases pickup and waits for the film before showing retry")
	ocean._process(0.25)
	if capture.is_valid(): await capture.call("05_shark_bite")
	var bite_at := ocean.turtle.position
	ocean._process(0.9)
	check.call(ocean.turtle.position.x < bite_at.x and is_equal_approx(ocean.turtle.position.y,bite_at.y) and is_instance_valid(ocean._caught_shark), "the biting shark carries the turtle horizontally toward the left edge")
	if capture.is_valid(): await capture.call("06_shark_drag")
	ocean._process(2)
	var left := ocean.camera.position.x-view.x/ocean.camera.zoom.x*0.5
	check.call(ocean.turtle.position.x < left-5 and ocean._caught_shark.position.x < left-5 and ocean._retry.visible and int(GameState.campaign().ocean_stage) == checkpoint, "the shark carries both actors fully beyond the side edge before retry without advancing the checkpoint")
	check.call(ocean._retry.get_global_rect().get_center().is_equal_approx(view*0.5), "Ride Again appears at the exact screen centre")
	if capture.is_valid(): await capture.call("08_retry_centre")
	ocean.restart()
	check.call(ocean._caught_shark == null and ocean.health == 3 and ocean.player.rotation == 0 and ocean.phase == OceanJourney.Phase.DIVE, "retry removes the captured shark and restores the rider and turtle")
	GameSettings.set_ui_scale(scale,false)
	GameState.data = saved
	GameState._emit_all()
	await game._load_lobby(false)
	game.hud.tutorial_guide._tips_enabled = tips
	GameState.autosave_enabled = autosave

static func _drag(game: Game, start: Vector2, end: Vector2, touch: bool, release_pointer: bool = true) -> void:
	var press: InputEvent = InputEventScreenTouch.new() if touch else InputEventMouseButton.new()
	press.position = game.get_viewport().get_final_transform() * start
	press.pressed = true
	if touch: press.index = 42
	else: press.button_index = MOUSE_BUTTON_LEFT
	Input.parse_input_event(press)
	await game.get_tree().process_frame
	var motion: InputEvent = InputEventScreenDrag.new() if touch else InputEventMouseMotion.new()
	motion.position = game.get_viewport().get_final_transform() * end
	motion.relative = end-start
	if touch: motion.index = 42
	else: motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(motion)
	await game.get_tree().process_frame
	if release_pointer: await _release(game,end,touch)

static func _release(game: Game, end: Vector2, touch: bool) -> void:
	var release: InputEvent = InputEventScreenTouch.new() if touch else InputEventMouseButton.new()
	release.position = game.get_viewport().get_final_transform() * end
	release.pressed = false
	if touch: release.index = 42
	else: release.button_index = MOUSE_BUTTON_LEFT
	Input.parse_input_event(release)
	await game.get_tree().process_frame
