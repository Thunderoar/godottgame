extends RefCounted

static func run(game: Game, check: Callable, capture: Callable = Callable()) -> void:
	var snapshot := GameState.data.duplicate(true)
	var autosave := GameState.autosave_enabled
	var ticking := game.is_processing()
	var old_settings := [GameSettings.reduce_motion(), GameSettings.effects_quality(), GameSettings.effects_volume(), GameSettings.mute_all()]
	var saved_file := FileAccess.get_file_as_string(GameState.SAVE_PATH) if FileAccess.file_exists(GameState.SAVE_PATH) else ""
	GameState.autosave_enabled = false
	game.set_process(false)
	game.hud.hide_modals()
	GameState.data = GameState._make_default("adam")
	GameState.data.campaign.dock_welcome_seen = true
	GameState.data.world_time = 179.0
	GameState._emit_all()
	await game._load_lobby(false)
	await game.get_tree().physics_frame
	await game.get_tree().physics_frame
	var home := game.world as Lobby
	_freeze(home)
	Input.action_press("attack")
	GameState.advance_world_clock(1)
	var arrival := game._urchin_arrival
	check.call(arrival != null, "first eligible night starts the in-world sea urchin introduction")
	if arrival == null:
		_restore_file(saved_file)
		GameState.data = snapshot
		GameState.autosave_enabled = autosave
		game.set_process(ticking)
		return
	arrival.set_process(false)
	var start_player := home.player.position
	var clock := float(GameState.data.world_time)
	game._process(3)
	check.call(game._story_active and home.process_mode == Node.PROCESS_MODE_DISABLED and game.player().controls_locked and not game.hud.visible and not Input.is_action_pressed("attack"), "Game suspends the village and releases held actions during the first reveal")
	check.call(float(GameState.data.world_time) == clock and home.player.position == start_player and home.capture_monsters().is_empty(), "previews cannot move actors, advance the clock or become live attackers")
	check.call(arrival.points.size() == Lobby.NIGHT_URCHIN_COUNT, "the legacy dusk allocation has six explicitly validated shore positions")
	var clear := true
	for point in arrival.points: clear = clear and home.urchin_entry_clear(point) and not WorldTerrain.is_sea(point)
	check.call(clear and game.get_tree().get_nodes_in_group("enemies").is_empty(), "all preview destinations are valid land while no preview enters combat groups")
	var camera_before := home.camera
	for index in 8:
		var time: float = [0.4, 1.4, 2.6, 3.8, 5.2, 6.7, 7.3, 7.8][index]
		arrival.sample(time)
		if capture.is_valid(): await capture.call("urchin_%02d" % index)
	check.call(arrival._sprites.all(func(actor: Sprite2D) -> bool: return actor.visible) and arrival._sprites.size() == arrival.points.size(), "the group reveal shows exactly the real allocated number of urchins")
	GameSettings.set_reduce_motion(true, false)
	GameSettings.set_effects_quality("low", false)
	arrival.sample(3.8)
	check.call(arrival._sprites.all(func(actor: Sprite2D) -> bool: return actor.rotation == 0 and actor.texture != null) and float(GameState.data.world_time) == clock, "live Reduce Motion and low effects preserve the pose and suspended gameplay without wobble")
	if capture.is_valid(): await capture.call("urchin_reduced_low")
	GameSettings.set_mute_all(true, false)
	check.call(not arrival._voice.playing, "live mute immediately stops the owned arrival sound")
	GameSettings.set_reduce_motion(false, false)
	arrival.sample(3.8)
	if capture.is_valid():
		var scale := float(game.get_window().size.y) / game.get_viewport_rect().size.y
		check.call(arrival._skip.get_global_rect().size.y * scale >= 43.9, "Skip retains a physical 44-pixel touch target")
		var touch := InputEventScreenTouch.new()
		touch.index = 41
		touch.position = game.get_viewport().get_final_transform() * arrival._skip.get_global_rect().get_center()
		touch.pressed = true
		Input.parse_input_event(touch)
		touch = touch.duplicate() as InputEventScreenTouch
		touch.pressed = false
		Input.parse_input_event(touch)
		await game.get_tree().process_frame
	else:
		arrival.finish()
	check.call(game._urchin_arrival == null and not game._story_active and not game.player().controls_locked and game.hud.visible and game.get_viewport().get_camera_2d() == camera_before, "Skip returns camera, HUD and controls to the correct world")
	_freeze(home)
	check.call(home.capture_monsters().size() == Lobby.FIRE_MONSTER_COUNT + Lobby.NIGHT_URCHIN_COUNT and bool(GameState.campaign().urchin_intro_seen) and GameState.pending_home_arrival().is_empty(), "successful handoff delivers and commits the exact legacy wave and first-seen flag once")
	if is_instance_valid(arrival): arrival.finish()
	check.call(home.capture_monsters().size() == 30, "a late second completion cannot duplicate the wave")
	var urchins := _urchins(home)
	urchins[0].hp = 17
	GameState.save_game()
	check.call(GameState.load_game() and bool(GameState.campaign().urchin_intro_seen), "first introduction completion survives actual save/load")
	await game._load_lobby(false)
	await game.get_tree().physics_frame
	home = game.world as Lobby
	_freeze(home)
	check.call(game._urchin_arrival == null and home._urchin_cue == null and _urchins(home).size() == 6 and _urchins(home)[0].hp == 17, "saved survivors retain HP without replaying their entrance")
	for enemy in _urchins(home).slice(0, 3): enemy.queue_free()
	await game.get_tree().physics_frame
	GameState.advance_world_clock(360)
	var cue := home._urchin_cue
	check.call(cue != null and not cue.full_intro and not game._story_active and home.process_mode != Node.PROCESS_MODE_DISABLED, "later shore arrivals use a running-world warning with no camera takeover")
	if cue != null:
		cue.set_process(false)
		var pending := GameState.pending_home_arrival()
		home._on_day_phase_changed(true)
		check.call(home._urchin_cue == cue and _urchins(home).size() == 3, "repeated phase signals cannot deliver early or create another warning")
		GameState.advance_world_clock(3)
		GameState.save_game()
		check.call(GameState.load_game() and _same_points(GameState.pending_home_arrival().points, pending.points), "a save during the warning retains its landing positions through JSON precision")
		await game._load_lobby(false)
		await game.get_tree().physics_frame
		home = game.world as Lobby
		_freeze(home)
		cue = home._urchin_cue
		check.call(cue != null, "an unfinished warning reconstructs on return")
		if cue != null:
			cue.set_process(false)
			cue._process(0)
			check.call(is_equal_approx(cue.elapsed, 3), "reconstructed warning resumes its saved clock instead of restarting")
			GameState.advance_world_clock(5)
			cue._process(0)
			_freeze(home)
			check.call(_urchins(home).size() == 6 and GameState.pending_home_arrival().is_empty(), "the pending remainder materializes only once at its actual deadline")
	# A preview cannot survive a replaced world or claim that the player saw it.
	for enemy in home.get_children():
		if enemy is Enemy: enemy.queue_free()
	await game.get_tree().physics_frame
	GameState.data.campaign.urchin_intro_seen = false
	GameState.data.home_arrival = {}
	GameState.data.home_wave = -1
	var points := home.urchin_entry_points(3)
	check.call(game.try_urchin_introduction(home, 0, points), "a safe unintroduced journey can present a three-member batch")
	var abandoned := game._urchin_arrival
	if abandoned != null:
		abandoned.set_process(false)
		await game._load_lobby(false)
		check.call((not is_instance_valid(abandoned) or abandoned.cancelled) and not bool(GameState.campaign().urchin_intro_seen) and not game._story_active, "world replacement cancels the preview without recording a viewing or freezing its replacement")
		home = game.world as Lobby
		_freeze(home)
		if is_instance_valid(home._urchin_cue): home._urchin_cue.cancel()
	for size in [1, 2]:
		for actor in home.get_children():
			if actor is Enemy: actor.queue_free()
		await game.get_tree().physics_frame
		GameState.data.home_wave = -1
		GameState.data.home_arrival = {}
		GameState.data.campaign.urchin_intro_seen = false
		var small_points := home.urchin_entry_points(size)
		var started := game.try_urchin_introduction(home, 0, small_points)
		check.call(started, "a safe first introduction accepts batch size %d" % size)
		if started:
			var small := game._urchin_arrival
			small.set_process(false)
			small.sample(6.7)
			check.call(small._sprites.size() == size, "the preview cannot invent extra group members for size %d" % size)
			small.finish()
			small.finish()
			_freeze(home)
			check.call(_urchins(home).size() == size, "a repeated completion still delivers size %d only once" % size)
	for skip_time in [0.4, 1.4, 2.6, 3.8, 5.2, 6.7, 7.3, 7.8]:
		for actor in home.get_children():
			if actor is Enemy: actor.queue_free()
		await game.get_tree().physics_frame
		GameState.data.home_wave = -1
		GameState.data.home_arrival = {}
		GameState.data.campaign.urchin_intro_seen = false
		var skip_points := home.urchin_entry_points(1)
		var started := game.try_urchin_introduction(home, 0, skip_points)
		check.call(started, "Skip fixture can enter storyboard beat %.1f" % skip_time)
		if started:
			var skipping := game._urchin_arrival
			skipping.set_process(false)
			skipping.sample(float(skip_time))
			skipping.finish()
			_freeze(home)
			check.call(_urchins(home).size() == 1 and not game._story_active and not home.player.controls_locked, "Skip at %.1f delivers one actor and releases ownership" % skip_time)
	var blocked_at := home.urchin_entry_points(1)
	if not blocked_at.is_empty():
		var blocker := StaticBody2D.new()
		blocker.position = blocked_at[0]
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 0.8
		shape.shape = circle
		blocker.add_child(shape)
		home.add_child(blocker)
		await game.get_tree().physics_frame
		check.call(not home.urchin_entry_clear(blocked_at[0]), "a newly blocked landing is rejected instead of teleporting through it")
		blocker.queue_free()
		await game.get_tree().physics_frame
	# Invalid save values never become executable preview data.
	GameState.data.home_arrival = {"night": {}, "points": "bad"}
	GameState.data.campaign.urchin_intro_seen = "yes"
	GameState._sanitize()
	check.call(GameState.pending_home_arrival().is_empty() and not bool(GameState.campaign().urchin_intro_seen), "malformed saved pending arrivals and intro flags sanitize safely")
	await _combat(home, check, capture)
	GameSettings.set_reduce_motion(bool(old_settings[0]), false)
	GameSettings.set_effects_quality(str(old_settings[1]), false)
	GameSettings.set_effects_volume(int(old_settings[2]), false)
	GameSettings.set_mute_all(bool(old_settings[3]), false)
	GameState.data = snapshot
	GameState._emit_all()
	await game._load_lobby(false)
	await game.get_tree().physics_frame
	await game.get_tree().physics_frame
	_restore_file(saved_file)
	GameState.autosave_enabled = autosave
	game.set_process(ticking)

static func _combat(home: Lobby, check: Callable, capture: Callable) -> void:
	var game := home.get_tree().get_first_node_in_group("game") as Game
	var points := home.urchin_entry_points(1)
	if points.is_empty(): return
	var enemy := home.spawn_sea_urchin(points[0], false, false, true)
	enemy.set_physics_process(false)
	await home.get_tree().create_timer(0.36).timeout
	home.player.position = points[0] + Vector2(0.8, 0)
	game.hud.visible = true
	home.camera.global_position = points[0] + Vector2(0, -1.5)
	home.camera.set_physics_process(false)
	home.camera.zoom = Vector2.ONE * 64
	home.camera.make_current()
	home.camera.reset_physics_interpolation()
	home.player.reset_physics_interpolation()
	enemy.reset_physics_interpolation()
	home.camera.force_update_scroll()
	await home.get_tree().physics_frame
	GameState.set_health(GameState.health_max())
	GameState.data.shield = 0
	home.player.invulnerable = 0
	enemy._target = home.player
	enemy._enter(Enemy.State.WINDUP)
	enemy._update_urchin_pose(0)
	check.call(enemy.max_hp == 30 and enemy.damage == 6 and enemy.speed == 1.35 and enemy._state_time == 0.42, "ordinary stats and 0.42-second melee windup are preserved")
	if capture.is_valid(): await capture.call("urchin_combat_windup")
	var hp := GameState.health()
	enemy._enter(Enemy.State.ATTACK)
	enemy._attack_active(0)
	enemy._update_urchin_pose(0)
	var after_first := GameState.health()
	home.player.invulnerable = 0
	enemy._attack_active(0)
	check.call(after_first < hp and GameState.health() == after_first and enemy._state_time == 0.14, "the active visual still resolves exactly one existing melee hit even without blink protection")
	if capture.is_valid(): await capture.call("urchin_combat_hit")
	enemy._enter(Enemy.State.RECOVER)
	enemy._update_urchin_pose(0)
	check.call(enemy._state_time == 0.5 and enemy.collision_mask == 1, "recovery timing and world-only body collision remain intact")
	if capture.is_valid(): await capture.call("urchin_combat_recover")
	var gold := GameState.gold()
	enemy.take_damage(999999)
	enemy.take_damage(999999)
	check.call(GameState.gold() == gold + 7 and enemy.dead and enemy.collision_layer == 0, "death presentation cannot pay twice or leave a damaging corpse")
	var raid := home.spawn_sea_urchin(points[0], true)
	raid.set_physics_process(false)
	check.call(raid.max_hp == 60 and raid.damage == 9 and raid.speed == 1.75, "emergency urchins keep their stronger existing stats")

static func _urchins(home: Lobby) -> Array[Enemy]:
	var result: Array[Enemy] = []
	for child in home.get_children():
		if child is Enemy and child.kind == "urchin" and not child.dead and not child.is_queued_for_deletion(): result.append(child)
	return result

static func _same_points(first: Array, second: Array) -> bool:
	if first.size() != second.size(): return false
	for i in first.size():
		if Vector2(float(first[i][0]), float(first[i][1])).distance_to(Vector2(float(second[i][0]), float(second[i][1]))) > 0.0001: return false
	return true

static func _freeze(home: Lobby) -> void:
	home.player.set_physics_process(false)
	home.pet.set_physics_process(false)
	for child in home.get_children():
		if child is Enemy or child is Resident: child.set_physics_process(false)
	for gun in home.get_tree().get_nodes_in_group("house_defenses"): gun.set_process(false)

static func _restore_file(contents: String) -> void:
	if contents.is_empty(): DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.SAVE_PATH))
	else:
		var file := FileAccess.open(GameState.SAVE_PATH, FileAccess.WRITE)
		file.store_string(contents)
		file.close()
