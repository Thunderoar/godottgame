extends RefCounted

static func run(game: Game, check: Callable, capture: Callable = Callable()) -> void:
	var snapshot := GameState.data.duplicate(true)
	var autosave := GameState.autosave_enabled
	var ticking := game.is_processing()
	var settings := [GameSettings.reduce_motion(), GameSettings.effects_quality()]
	var saved_file := FileAccess.get_file_as_string(GameState.SAVE_PATH) if FileAccess.file_exists(GameState.SAVE_PATH) else ""
	game.set_process(false)
	game.hud.hide_modals()
	GameState.autosave_enabled = false
	var home := await _fresh(game)
	var state := home._rng.state
	var points := home.fire_entry_points(24)
	var separate := points.size() == 24
	for i in points.size():
		separate = separate and home.fire_entry_clear(points[i])
		for j in i: separate = separate and points[i].distance_to(points[j]) >= 1.3
	check.call(separate and home._rng.state == state, "gradual portals reserve separate valid land without changing the forest RNG")
	Input.action_press("attack")
	GameState.advance_world_clock(1)
	var intro := game._urchin_arrival
	check.call(intro != null and intro.duration() == 14.5 and intro.introduce_shore and intro.introduce_fire, "the gradual night keeps one coordinated 14.5-second first reveal")
	if intro != null:
		intro.set_process(false)
		var clock := float(GameState.data.world_time)
		var player_position := home.player.position
		for time in [1.2, 3.8, 6.7, 7.15, 8.2, 9.3, 10.2, 11.4, 12.8, 14.2]:
			intro.sample(float(time))
			if capture.is_valid(): await capture.call("gradual_intro_%04d" % int(time * 10))
		check.call(home.capture_monsters().is_empty() and GameState.data.world_time == clock and home.player.position == player_position and not Input.is_action_pressed("attack"), "the lead reveal has no hidden simulation or held attack")
		intro.sample(12.8)
		check.call(intro._fire._bodies.filter(func(body: Sprite2D) -> bool: return body.visible).size() == 1 and intro._sprites.filter(func(body: Sprite2D) -> bool: return body.visible).size() == 1, "the first scene previews only one monster of each species, leaving followers for play")
		intro.finish()
		_freeze(home)
		check.call(home._forest_monsters.size() == 1 and home.capture_monsters().size() == 2 and GameState.campaign().fire_intro_seen and GameState.campaign().urchin_intro_seen and not game._story_active and not home.player.controls_locked, "Skip introduces just the lead pair and restores gameplay without draining the queue")
		home._forest_monsters[0].hp = 19
		GameState.save_game()
		check.call(GameState.load_game() and GameState.pending_home_arrival().resolved_fire == [0] and GameState.pending_home_arrival().resolved_shore == [0], "partial lead delivery and introduction flags survive a real save/load")
		await game._load_lobby(false)
		await game.get_tree().physics_frame
		await game.get_tree().physics_frame
		home = game.world as Lobby
		_freeze(home)
		check.call(home._forest_monsters.size() == 1 and home._forest_monsters[0].hp == 19 and game._urchin_arrival == null, "the lead survivor restores without another cinematic or duplicate portal")
	for size in [1, 3, 8, 24]:
		home = await _fresh(game, true)
		GameState.data.world_time = 180.0
		var allocated := home.fire_entry_points(size)
		check.call(game.try_urchin_introduction(home, size, PackedVector2Array(), allocated), "fire-only gradual fixture accepts %d reservations" % size)
		var solo := game._urchin_arrival
		if solo == null: continue
		solo.set_process(false)
		if size == 3:
			for time in [1.2, 2.5, 3.2, 3.8, 4.4, 5.9, 7.2, 9.2]:
				solo.sample(float(time))
				if capture.is_valid(): await capture.call("gradual_fire_%04d" % int(time * 10))
			GameSettings.set_reduce_motion(true, false)
			GameSettings.set_effects_quality("low", false)
			solo.sample(3.8)
			check.call(solo._fire._bodies[0].rotation == 0 and solo._fire._portals[0].visible, "low effects and live Reduce Motion retain the individual crossing")
			if capture.is_valid(): await capture.call("gradual_fire_reduced")
			GameSettings.set_reduce_motion(false, false)
			GameSettings.set_effects_quality("high", false)
		solo.sample(10.5)
		solo.finish()
		_freeze(home)
		check.call(home._forest_monsters.size() == 1 and bool(GameState.campaign().fire_intro_seen), "a %d-member reservation releases only its lead during the introduction" % size)
		if size == 1: await _combat(home, check)
	for time in [0.2, 3.8, 7.1, 9.4, 11.4, 14.4]:
		home = await _fresh(game)
		GameState.advance_world_clock(1)
		var skipping := game._urchin_arrival
		if skipping == null: check.call(false, "combined Skip fixture starts"); continue
		skipping.set_process(false)
		skipping.sample(float(time))
		skipping.finish()
		_freeze(home)
		check.call(home.capture_monsters().size() == 2 and not home.player.controls_locked and not game._story_active, "Skip at %.1f preserves the gradual remaining allocation" % time)
	await preload("res://tools/gradual_arrival_checks.gd").run(game, check, capture)
	await _migration(game, check)
	GameSettings.set_reduce_motion(bool(settings[0]), false)
	GameSettings.set_effects_quality(str(settings[1]), false)
	game._clear_world()
	GameState.data = snapshot
	GameState._emit_all()
	await game._load_lobby(false)
	await game.get_tree().physics_frame
	await game.get_tree().physics_frame
	preload("res://tools/urchin_arrival_checks.gd")._restore_file(saved_file)
	GameState.autosave_enabled = autosave
	game.set_process(ticking)

static func _combat(home: Lobby, check: Callable) -> void:
	var fire := home._forest_monsters[0]
	var tree: ForestTree
	for candidate in home._forest_trees:
		if candidate.is_attackable(): tree = candidate; break
	if tree == null: check.call(false, "fire combat fixture has a mature tree"); return
	var sound_cursor := Sfx._next_player
	fire.position = tree.position + Vector2(0.8, 0)
	fire._target = tree
	fire._enter(Enemy.State.WINDUP)
	check.call(fire._state_time == 0.42 and fire.max_hp == 58 and fire.damage == 4 and is_equal_approx(fire.attack_interval, 1.44) and fire.collision_mask == 1, "revealed fires use tougher stats with the original windup and faster attack interval and world-only collision")
	var hp := tree.health
	fire._enter(Enemy.State.ATTACK)
	fire._attack_active(0)
	fire._attack_active(0)
	check.call(tree.burning and tree.health == hp - fire.damage, "the first real fire strike ignites a mature tree and resolves exactly once")
	var gold := GameState.gold()
	fire.take_damage(99999)
	fire.take_damage(99999)
	var burning_hp := tree.health
	tree._process(1)
	check.call(GameState.gold() == gold + 6 and tree.burning and tree.health == burning_hp - 2 and Sfx._next_player == sound_cursor, "fire death pays once while the actual tree continues burning silently")
	tree.water(tree.max_health)
	check.call(not tree.burning, "Water Keepers can still extinguish the surviving fire")

static func _migration(game: Game, check: Callable) -> void:
	var home := await _fresh(game, true)
	var legacy := GameState._make_default("adam")
	legacy.campaign.erase("fire_intro_seen")
	legacy.home_monsters = [{"kind": "fire", "x": 47.0, "y": 8.0, "hp": 17, "raid": false}]
	var file := FileAccess.open(GameState.SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	check.call(GameState.load_game() and bool(GameState.campaign().fire_intro_seen) and int(GameState.data.home_monsters[0].hp) == 17, "legacy saves with fire survivors migrate as introduced without changing their HP")
	legacy.erase("home_monsters")
	file = FileAccess.open(GameState.SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	check.call(GameState.load_game() and not bool(GameState.campaign().fire_intro_seen), "a legacy save without monster records remains valid and does not invent prior exposure")
	GameState.data.world_time = 181.0
	GameState.data.home_arrival = {"night": GameState.night_number(), "fires": 3, "points": [[10, 29]], "started": 180.0}
	GameState._sanitize()
	var shore := PackedVector2Array([Vector2(10, 29)])
	var points := home.fire_entry_points(3)
	var upgraded := GameState.stage_home_arrival(3, shore, false, points)
	check.call(upgraded.fire_points.size() == 3 and float(upgraded.started) == 180 and not str(upgraded.id).is_empty(), "a legacy pending count acquires fixed portal points once while retaining its warning origin")

static func _fresh(game: Game, shore_seen: bool = false, fire_seen: bool = false) -> Lobby:
	game._clear_world()
	GameState.data = GameState._make_default("adam")
	GameState.data.campaign.dock_welcome_seen = true
	GameState.data.campaign.urchin_intro_seen = shore_seen
	GameState.data.campaign.fire_intro_seen = fire_seen
	GameState.data.world_time = 179.0
	GameState._emit_all()
	await game._load_lobby(false)
	await game.get_tree().physics_frame
	await game.get_tree().physics_frame
	var home := game.world as Lobby
	_freeze(home)
	return home

static func _freeze(home: Lobby) -> void:
	preload("res://tools/urchin_arrival_checks.gd")._freeze(home)
