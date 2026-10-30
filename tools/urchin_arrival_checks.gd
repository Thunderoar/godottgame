extends RefCounted

static func run(game: Game, check: Callable, capture: Callable = Callable()) -> void:
	var snapshot := GameState.data.duplicate(true)
	var autosave := GameState.autosave_enabled
	var ticking := game.is_processing()
	var saved_file := FileAccess.get_file_as_string(GameState.SAVE_PATH) if FileAccess.file_exists(GameState.SAVE_PATH) else ""
	game.set_process(false)
	GameState.autosave_enabled = false
	game.hud.hide_modals()
	game._clear_world()
	GameState.data = GameState._make_default("adam")
	GameState.data.campaign.dock_welcome_seen = true
	GameState.data.campaign.fire_intro_seen = true
	GameState.data.world_time = 179.0
	GameState._emit_all()
	await game._load_lobby(false)
	await game.get_tree().physics_frame
	await game.get_tree().physics_frame
	var home := game.world as Lobby
	_freeze(home)
	GameState.advance_world_clock(1)
	var arrival := game._urchin_arrival
	check.call(arrival != null and arrival.duration() == 8, "an already introduced fire species leaves the eight-second shore introduction intact")
	if arrival != null:
		arrival.set_process(false)
		var camera := home.camera
		for index in 8:
			arrival.sample(float([0.4, 1.4, 2.6, 3.8, 5.2, 6.7, 7.3, 7.8][index]))
			if capture.is_valid(): await capture.call("urchin_%02d" % index)
		check.call(arrival._sprites.filter(func(actor: Sprite2D) -> bool: return actor.visible).size() == 1 and home.capture_monsters().is_empty(), "only the lead urchin previews while the entire village is suspended")
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
		else: arrival.finish()
		_freeze(home)
		check.call(_urchins(home).size() == 1 and home._forest_monsters.size() == 1 and game.get_viewport().get_camera_2d() == camera and not game.player().controls_locked, "touch/keyboard Skip releases the lead pair and restores camera and controls")
		var count := home.capture_monsters().size()
		arrival.finish()
		check.call(home.capture_monsters().size() == count, "a duplicate completion cannot release another member")
	await _combat(home, check, capture)
	game._clear_world()
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
