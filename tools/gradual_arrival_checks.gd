extends RefCounted

static func run(game: Game, check: Callable, capture: Callable) -> void:
	var fixture := preload("res://tools/fire_arrival_checks.gd")
	var home: Lobby = await fixture._fresh(game, true, true)
	GameState.advance_world_clock(1)
	var cue := home._urchin_cue
	check.call(cue != null and game._urchin_arrival == null and not game._story_active and home.capture_monsters().is_empty(), "an ordinary night reserves its allowance without spawning a crowd at dusk")
	if cue == null: return
	var batch := cue.batch_id
	home._on_day_phase_changed(true)
	check.call(home._urchin_cue == cue and GameState.pending_home_arrival().fire_points.size() == 24 and GameState.pending_home_arrival().points.size() == 6, "duplicate dusk signals keep one bounded 24-fire/six-urchin allowance")
	_step(home, 8)
	check.call(home._forest_monsters.size() == 1 and _shore(home) == 0, "only one real fire monster crosses at the first ordinary deadline")
	for i in 4: cue._process(0)
	check.call(home.capture_monsters().size() == 1, "repeated ticks at the same clock cannot release the next creature")
	_step(home, 2)
	check.call(home._forest_monsters.size() == 1 and _shore(home) == 1, "the first sea urchin arrives two world seconds after the first fire")
	_step(home, 10)
	check.call(home.capture_monsters().size() == 2 and not cue._caption.visible, "a quiet interval follows the first pair instead of immediately replacing kills")
	_step(home, 4)
	check.call(cue._fire._roots[1].visible and not cue._fire._roots[0].visible and not game.player().controls_locked, "the next individual ember warning appears eight seconds ahead while its delivered predecessor stays real")
	if capture.is_valid(): await capture.call("gradual_next_ember")
	_step(home, 8)
	check.call(home._forest_monsters.size() == 2 and _shore(home) == 1, "the next small forest pulse begins at night second 32")
	if capture.is_valid(): await capture.call("gradual_second_fire")
	_step(home, 2)
	check.call(home._forest_monsters.size() == 3, "members of the forest pulse become real two seconds apart")
	_step(home, 2)
	_step(home, 4)
	check.call(home._forest_monsters.size() == 4 and _shore(home) == 2 and home.capture_monsters().size() == 6, "the first forty seconds contain four fires and two shoreline arrivals")
	var pending := GameState.pending_home_arrival()
	GameState.save_game()
	check.call(GameState.load_game() and str(GameState.pending_home_arrival().id) == batch and GameState.pending_home_arrival().resolved_fire == pending.resolved_fire and GameState.pending_home_arrival().resolved_shore == pending.resolved_shore, "a partially delivered pulse saves exact member completion and batch identity")
	await game._load_lobby(false)
	await game.get_tree().physics_frame
	await game.get_tree().physics_frame
	home = game.world as Lobby
	fixture._freeze(home)
	if is_instance_valid(home._urchin_cue): home._urchin_cue._process(0)
	check.call(home.capture_monsters().size() == 6 and home._urchin_cue != null and is_equal_approx(home._urchin_cue.elapsed, 40), "reloading mid-night restores six survivors and resumes the same absolute timeline")
	for i in 59: _step(home, 2)
	check.call(home._forest_monsters.size() == 24 and _shore(home) == 6 and GameState.pending_home_arrival().is_empty(), "a continuously attended night gradually delivers exactly its original allowance by second 158")
	var total := home.capture_monsters().size()
	home._on_day_phase_changed(true)
	check.call(home.capture_monsters().size() == total and home._urchin_cue == null, "completing the night's queue cannot schedule another top-up")
	_step(home, 22)
	check.call(not GameState.is_night() and home.capture_monsters().size() == total, "dawn preserves the gradually delivered survivors")
	# Return after missed deadlines: no accumulated army and no timing reset.
	home = await fixture._fresh(game, true, true)
	GameState.advance_world_clock(1)
	_step(home, 8)
	GameState.advance_world_clock(102)
	await game._load_lobby(false)
	await game.get_tree().physics_frame
	await game.get_tree().physics_frame
	home = game.world as Lobby
	fixture._freeze(home)
	# Two physics frames can precede the first idle tick in a busy full suite.
	# Deliver that first cue tick explicitly, as in the mid-night reload above.
	if is_instance_valid(home._urchin_cue): home._urchin_cue._process(0)
	check.call(home.capture_monsters().size() <= 2 and GameState.pending_home_arrival().resolved_fire.size() >= 15, "a late return expires missed members instead of dumping the night's queue into one frame")
	var before := home.capture_monsters().size()
	for i in 8:
		if is_instance_valid(home._urchin_cue): home._urchin_cue._process(0)
	check.call(home.capture_monsters().size() == before, "late-return catch-up cannot trickle a backlog out over consecutive frames")
	_step(home, 70)
	check.call(GameState.pending_home_arrival().is_empty(), "dawn discards all unfinished ordinary reservations")
	# Recovery skips due members, rather than banking a new attack for waking.
	home = await fixture._fresh(game, true, true)
	GameState.advance_world_clock(1)
	GameState.data.recovery_active = true
	_step(home, 8)
	_step(home, 2)
	check.call(home.capture_monsters().is_empty() and GameState.pending_home_arrival().resolved_fire == [0] and GameState.pending_home_arrival().resolved_shore == [0], "recovery skips actual due arrivals without creating deferred threats")
	GameState.data.recovery_active = false
	_step(home, 22)
	check.call(home._forest_monsters.size() == 1 and _shore(home) == 0, "leaving recovery resumes future pulses without replacing skipped creatures")
	await _raid(game, check)
	# Saved timings are canonical, not arbitrary executable data.
	home = await fixture._fresh(game, true, true)
	GameState.data.world_time = 180.0
	var points := home.fire_entry_points(3)
	GameState.data.home_arrival = {"night": 0, "id": "malformed", "fires": 3, "fire_points": [[points[0].x, points[0].y], [points[1].x, points[1].y], [points[2].x, points[2].y]], "points": [], "started": 180, "fire_times": [0, 0, 0], "resolved_fire": [0, 0, -1, "bad", 99, 1.5], "resolved_shore": true, "last_delivery": "bad"}
	GameState._sanitize()
	var clean := GameState.pending_home_arrival()
	check.call(clean.fire_times == [8.0, 32.0, 34.0] and clean.resolved_fire == [0] and clean.resolved_shore.is_empty() and clean.last_delivery < 0, "malformed member progress is bounded and saved timing cannot bypass gradual spacing")

static func _raid(game: Game, check: Callable) -> void:
	var fixture := preload("res://tools/fire_arrival_checks.gd")
	var home: Lobby = await fixture._fresh(game, true, true)
	GameState.data.world_time = 180.0
	GameState.mark_home_wave()
	GameState.start_emergency(3)
	var cue := home._fire_cue
	check.call(cue != null and cue.points.size() == 3 and cue.fire_points.size() == 6 and home.capture_monsters().is_empty(), "an emergency reserves three raiders and six separate fire portals instead of spawning them together")
	if cue == null: return
	_step(home, 8)
	check.call(home._emergency_monsters.size() == 1 and home._forest_monsters.is_empty() and GameState.emergency_monsters() == 3, "only the first raid attacker becomes live at the warning deadline")
	_step(home, 2)
	var id := cue.batch_id
	GameState.save_game()
	check.call(GameState.load_game() and GameState.pending_home_arrival(true).resolved_shore == [0, 1], "partly arrived emergency attackers save separately from ordinary night progress")
	await game._load_lobby(false)
	await game.get_tree().physics_frame
	await game.get_tree().physics_frame
	home = game.world as Lobby
	fixture._freeze(home)
	check.call(home._emergency_monsters.size() == 2 and home._fire_cue != null and home._fire_cue.batch_id == id, "emergency reconstruction keeps living raiders and the remaining saved queue")
	for i in 7: _step(home, 2)
	check.call(home._emergency_monsters.size() == 3 and home._forest_monsters.size() == 6 and GameState.pending_home_arrival(true).is_empty(), "raid members and their individual fire portals finish gradually with the same quota and stats")
	var raider := home._emergency_monsters[0]
	check.call(raider.max_hp == 87 and raider.damage == 12 and raider.speed == 1.75, "gradual raid arrivals preserve the stronger emergency variant")
	# A blocked arrival is not a kill, and must not leave an impossible quota.
	home = await fixture._fresh(game, true, true)
	GameState.data.world_time = 180.0
	GameState.mark_home_wave()
	GameState.start_emergency(3)
	cue = home._fire_cue
	if cue == null: check.call(false, "blocked raid fixture starts"); return
	var blocker := StaticBody2D.new()
	blocker.position = cue.points[0]
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 0.8
	shape.shape = circle
	blocker.add_child(shape)
	home.add_child(blocker)
	await game.get_tree().physics_frame
	var gold := GameState.gold()
	var kills := int(GameState.data.kills)
	_step(home, 8)
	check.call(home._emergency_monsters.is_empty() and GameState.emergency_monsters() == 2 and GameState.gold() == gold and int(GameState.data.kills) == kills, "a blocked raider is removed from the undelivered quota without fake kills or rewards")
	_step(home, 2)
	_step(home, 170)
	check.call(home._emergency_monsters.size() == 1 and GameState.emergency_monsters() == 1, "dawn cancels undelivered raid members while retaining the actual living attacker")
	home._emergency_monsters[0].take_damage(99999)
	check.call(not GameState.emergency_active(), "defeating the final delivered raider resolves the adjusted emergency without phantom targets")

static func _shore(home: Lobby) -> int:
	return preload("res://tools/urchin_arrival_checks.gd")._urchins(home).size()

static func _step(home: Lobby, delta: float) -> void:
	GameState.advance_world_clock(delta)
	for cue in [home._urchin_cue, home._fire_cue]:
		if is_instance_valid(cue) and not cue._done:
			cue.set_process(false)
			cue._process(0)
	preload("res://tools/fire_arrival_checks.gd")._freeze(home)
