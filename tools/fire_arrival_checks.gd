extends RefCounted

static func run(game: Game, check: Callable, capture: Callable = Callable()) -> void:
	var snapshot := GameState.data.duplicate(true)
	var autosave := GameState.autosave_enabled
	var ticking := game.is_processing()
	var old_settings := [GameSettings.reduce_motion(), GameSettings.effects_quality()]
	var saved_file := FileAccess.get_file_as_string(GameState.SAVE_PATH) if FileAccess.file_exists(GameState.SAVE_PATH) else ""
	GameState.autosave_enabled = false
	game.set_process(false)
	game.hud.hide_modals()
	var home := await _fresh(game)
	var rng_state := home._rng.state
	var points := home.fire_entry_points(24)
	check.call(points.size() == 24 and home._rng.state == rng_state, "24 distinct fire entries allocate without consuming the historical forest RNG")
	var spaced := true
	for i in points.size():
		spaced = spaced and home.fire_entry_clear(points[i])
		for j in i: spaced = spaced and points[i].distance_to(points[j]) >= 1.3
	check.call(spaced, "every fire portal reserves clear land and a separate body footprint")
	Input.action_press("attack")
	GameState.advance_world_clock(1)
	var combined := game._urchin_arrival
	check.call(combined != null and combined.introduce_fire and combined.introduce_shore and combined.duration() == 14.5, "the first dusk selects a single 14.5-second shore-to-forest introduction")
	if combined != null:
		combined.set_process(false)
		var player_position := home.player.position
		var hp := GameState.health()
		var clock := float(GameState.data.world_time)
		var forest: Dictionary = GameState.data.forest_health.duplicate(true)
		for time in [1.4, 3.8, 6.7, 7.15, 8.2, 9.3, 10.2, 11.1, 12.3, 13.2, 14.2]:
			combined.sample(float(time))
			game._process(0.2)
			if capture.is_valid(): await capture.call("combined_%04d" % int(time * 10))
		check.call(home.capture_monsters().is_empty() and GameState.health() == hp and GameState.data.forest_health == forest and GameState.data.world_time == clock and home.player.position == player_position, "both chapters stay cosmetic with no hidden damage, clock advance or actor movement")
		check.call(combined._fire._portals.size() == 24 and combined._sprites.size() == 6 and not Input.is_action_pressed("attack"), "each allocated fire has one portal while shoreline members and released controls remain exact")
		combined.sample(10.5)
		var close_zoom := combined._camera.zoom.x
		combined.sample(13.2)
		check.call(combined._camera.zoom.x < close_zoom, "the forest camera widens for follower portals before its single return")
		combined.sample(13.5)
		var landed := true
		for i in combined.points.size(): landed = landed and combined._feet[i].distance_to(home.to_global(combined.points[i])) < 0.0001
		check.call(landed, "every shore follower has landed before the forest chapter hands over to real enemies")
		check.call(combined._fire._bodies.all(func(body: Sprite2D) -> bool: return body.visible and body.texture == FireArt.body()) and combined._fire._portals.all(func(portal: Sprite2D) -> bool: return not portal.visible), "all individual portals seal and all preview bodies match their live rest frame before handoff")
		combined.finish()
		_freeze(home)
		var matched := home._forest_monsters.size() == combined.fire_points.size()
		for i in home._forest_monsters.size():
			matched = matched and home._forest_monsters[i].position.distance_to(combined.fire_points[i]) < 0.0001 and home._forest_monsters[i].sprite.flip_h == combined._fire._bodies[i].flip_h and home._forest_monsters[i].modulate.a == 1.0
		check.call(matched, "live fire feet, facing and opacity match the final previews without a second fade")
		check.call(home.capture_monsters().size() == 30 and bool(GameState.campaign().fire_intro_seen) and bool(GameState.campaign().urchin_intro_seen) and game._urchin_arrival == null and not game._story_active, "one combined Skip delivers exactly 24 fires and six urchins and commits both seen flags")
		var count := home.capture_monsters().size()
		check.call(not home.finish_urchin_arrival(combined) and home.capture_monsters().size() == count, "a duplicate chapter completion cannot deliver any creature twice")
		var fire := home._forest_monsters[0]
		fire.hp = 19
		GameState.save_game()
		check.call(GameState.load_game() and bool(GameState.campaign().fire_intro_seen), "the fire introduction flag survives an actual save/load")
		await game._load_lobby(false)
		await game.get_tree().physics_frame
		home = game.world as Lobby
		_freeze(home)
		check.call(home._forest_monsters.size() == 24 and home._forest_monsters[0].hp == 19 and home._urchin_cue == null and home._fire_cue == null, "saved fire survivors keep HP without a second portal or warning")
	# Solo batches retain their counts, timing, settings and one-payment combat.
	for size in [1, 3, 8, 24]:
		home = await _fresh(game, true)
		GameState.data.world_time = 180.0
		var allocated := home.fire_entry_points(size)
		var started := game.try_urchin_introduction(home, size, PackedVector2Array(), allocated)
		check.call(started, "a fire-only first reveal accepts %d allocated members" % size)
		if not started: continue
		var solo := game._urchin_arrival
		solo.set_process(false)
		check.call(solo.duration() == 10.5 and solo._fire._portals.size() == size and solo.points.is_empty(), "the solo fire reveal has one small portal per member and no invented shore chapter")
		if size == 3:
			for time in [1.2, 2.5, 3.2, 3.8, 4.4, 5.9, 7.2, 8.7, 10.2]:
				solo.sample(float(time))
				if capture.is_valid(): await capture.call("fire_%04d" % int(time * 10))
			GameSettings.set_reduce_motion(true, false)
			GameSettings.set_effects_quality("low", false)
			solo.sample(3.8)
			check.call(solo._fire._bodies.all(func(body: Sprite2D) -> bool: return body.rotation == 0 and body.texture != null) and solo._fire._portals[0].visible, "low effects and live Reduce Motion retain the threshold and crossing without wobble")
			if capture.is_valid(): await capture.call("fire_reduced_low")
			GameSettings.set_reduce_motion(false, false)
			GameSettings.set_effects_quality("high", false)
		solo.sample(10.5)
		solo.finish()
		_freeze(home)
		check.call(home._forest_monsters.size() == size and bool(GameState.campaign().fire_intro_seen) and not game.player().controls_locked and game.hud.visible, "solo completion delivers %d fires and restores the current world" % size)
		if size == 1: await _combat(home, check)
	# Every Skip beat must reach the same allocation, even before the forest chapter.
	for time in [0.2, 3.8, 7.1, 8.5, 9.4, 10.3, 11.4, 12.5, 14.4]:
		home = await _fresh(game)
		GameState.advance_world_clock(1)
		var skipping := game._urchin_arrival
		if skipping == null:
			check.call(false, "combined Skip fixture starts")
			continue
		skipping.set_process(false)
		skipping.sample(float(time))
		skipping.finish()
		_freeze(home)
		check.call(home.capture_monsters().size() == 30 and not game._story_active and not home.player.controls_locked, "combined Skip at %.1f finishes both allocations without another camera takeover" % time)
	# Repeats run with the real clock; persist the exact fire positions and deadline.
	home = await _fresh(game, true, true)
	GameState.advance_world_clock(1)
	var cue := home._urchin_cue
	check.call(cue != null and not game._story_active and game.get_viewport().get_camera_2d() == home.camera, "repeat fire portals warn without taking the gameplay camera or input")
	if cue != null:
		cue.set_process(false)
		var pending := GameState.pending_home_arrival()
		GameState.advance_world_clock(7)
		cue._process(0)
		check.call(cue._fire._portals[0].visible and home.capture_monsters().is_empty(), "repeat portals open before delivery while their previews remain outside combat")
		check.call(not cue._caption.get_global_rect().intersects(game.hud.objective_tracker.get_global_rect()) and cue._caption.text.contains("Embers · east") and cue._caption.text.contains("Spines · west"), "mixed warning captions clear the objective panel and give each species its actual bearing")
		if capture.is_valid(): await capture.call("fire_repeat_warning")
		GameState.save_game()
		check.call(GameState.load_game() and preload("res://tools/urchin_arrival_checks.gd")._same_points(GameState.pending_home_arrival().fire_points, pending.fire_points), "pending fire member positions round-trip through JSON precision")
		await game._load_lobby(false)
		await game.get_tree().physics_frame
		home = game.world as Lobby
		_freeze(home)
		cue = home._urchin_cue
		check.call(cue != null and cue.batch_id == str(pending.id), "an interrupted repeat reconstructs the same batch")
		if cue != null:
			cue.set_process(false)
			cue._process(0)
			check.call(is_equal_approx(cue.elapsed, 7), "a restored fire warning resumes instead of restarting")
			GameState.advance_world_clock(1)
			cue._process(0)
			_freeze(home)
			check.call(home._forest_monsters.size() == 24 and GameState.pending_home_arrival().is_empty(), "the restored warning delivers once at its original deadline")
	# Emergency fire additions also use distinct saved portals, bounded by the cap.
	home._spawn_forest_monsters(6)
	var extra := home._fire_cue
	check.call(extra != null and extra.fire_points.size() == 6 and extra.reinforcement and home._forest_monsters.size() == 24, "six emergency reinforcements receive six previews before becoming real enemies")
	if extra != null:
		extra.set_process(false)
		home._spawn_forest_monsters(6)
		check.call(home._fire_cue == extra and GameState.pending_home_arrival(true).fire_points.size() == 6, "repeated emergency callbacks cannot allocate extra portals")
		var extra_pending := GameState.pending_home_arrival(true)
		GameState.advance_world_clock(3)
		GameState.save_game()
		check.call(GameState.load_game() and str(GameState.pending_home_arrival(true).id) == str(extra_pending.id), "emergency portal reservations persist independently of the completed dusk wave")
		await game._load_lobby(false)
		await game.get_tree().physics_frame
		await game.get_tree().physics_frame
		home = game.world as Lobby
		_freeze(home)
		extra = home._fire_cue
		if extra == null:
			check.call(false, "pending emergency portals reconstruct on return")
		else:
			extra.set_process(false)
			extra._process(0)
			check.call(is_equal_approx(extra.elapsed, 3) and extra.fire_points.size() == 6 and home._forest_monsters.size() == 24, "emergency reconstruction retains its original positions, clock and existing survivors")
		if extra != null: extra.finish()
		_freeze(home)
		check.call(home._forest_monsters.size() == 30 and GameState.pending_home_arrival(true).is_empty(), "emergency portals commit once within the 30-fire ceiling")
	await _interruptions(game, check)
	await _migration(game, check)
	GameSettings.set_reduce_motion(bool(old_settings[0]), false)
	GameSettings.set_effects_quality(str(old_settings[1]), false)
	game._clear_world()
	GameState.data = snapshot
	GameState._emit_all()
	await game._load_lobby(false)
	await game.get_tree().physics_frame
	await game.get_tree().physics_frame
	preload("res://tools/urchin_arrival_checks.gd")._restore_file(saved_file)
	GameState.autosave_enabled = autosave
	game.set_process(ticking)

static func _interruptions(game: Game, check: Callable) -> void:
	var home := await _fresh(game, true)
	GameState.data.world_time = 180.0
	var points := home.fire_entry_points(1)
	check.call(game.try_urchin_introduction(home, 1, PackedVector2Array(), points), "blocked handoff fixture starts a first fire reveal")
	var reveal := game._urchin_arrival
	if reveal != null:
		reveal.set_process(false)
		var blocker := StaticBody2D.new()
		# Keep this injected collider in the physics space while the story suspends
		# its parent; otherwise CollisionObject2D's default disable mode removes it.
		blocker.process_mode = Node.PROCESS_MODE_ALWAYS
		blocker.position = points[0]
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 1.0
		shape.shape = circle
		blocker.add_child(shape)
		home.add_child(blocker)
		await game.get_tree().physics_frame
		check.call(not home.fire_entry_clear(points[0]), "the injected portal blocker is present in the real physics space")
		reveal.finish()
		check.call(home._forest_monsters.is_empty() and not bool(GameState.campaign().fire_intro_seen) and GameState.pending_home_arrival().is_empty(), "a blocked portal cannot relocate its enemy or falsely mark the introduction seen")
	home = await _fresh(game)
	GameState.advance_world_clock(1)
	var abandoned := game._urchin_arrival
	if abandoned != null:
		abandoned.set_process(false)
		abandoned.sample(10.4)
		await game._load_lobby(false)
		check.call((not is_instance_valid(abandoned) or abandoned.cancelled) and not bool(GameState.campaign().fire_intro_seen) and not game._story_active, "world replacement during the forest chapter cancels ownership without recording a viewing")
	home = await _fresh(game, true, true)
	GameState.advance_world_clock(1)
	var cue := home._urchin_cue
	if cue != null:
		cue.set_process(false)
		GameState.advance_world_clock(180)
		cue._process(0)
		check.call(home._forest_monsters.is_empty() and home._urchin_cue == null, "dawn cancels pending fire portals without daytime delivery")
	GameState.data.home_fire_arrival = {"night": GameState.night_number(), "fire_points": [[], [NAN, 4]], "fires": "bad"}
	GameState.data.campaign.fire_intro_seen = "yes"
	GameState._sanitize()
	check.call(GameState.pending_home_arrival(true).is_empty() and not bool(GameState.campaign().fire_intro_seen), "malformed fire allocations and seen flags sanitize safely")

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
	check.call(fire._state_time == 0.42 and fire.max_hp == 40 and fire.damage == 3 and fire.attack_interval == 1.6 and fire.collision_mask == 1, "revealed fires retain their actual stats, windup, attack interval and world-only collision")
	var hp := tree.health
	fire._enter(Enemy.State.ATTACK)
	fire._attack_active(0)
	fire._attack_active(0)
	check.call(tree.burning and tree.health == hp - 3, "the first real fire strike ignites a mature tree and resolves exactly once")
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
