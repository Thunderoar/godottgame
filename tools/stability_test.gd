extends Node
## 7.5 simulated minutes, including five minutes of boss combat, plus world churn.
## --fixed-fps accelerates headless runs; --realtime keeps native wall-clock pacing.

var game: Game
var checks := 0
var failures := 0
var samples: Array[Dictionary] = []

func _ready() -> void:
	if not TestEnvironment.require_isolation():
		get_tree().quit(1)
		return
	GameState.autosave_enabled = false
	GameState.new_game("adam")
	game = load("res://scenes/game.tscn").instantiate() as Game
	add_child(game)
	game._remove_title()
	game.hud.visible = true
	game.hud.tutorial_guide.hide()
	GameState.start_expedition(RealmDB.PORTAL)
	await game._load_dungeon(RealmDB.PORTAL, false)
	await _frames(3)
	var realm := game.world as TwilightRealm
	await _summon_regression(realm)
	if failures > 0:
		get_tree().quit(1)
		return
	realm.pet.set_physics_process(false) # Keep enemies alive to exercise repeated casts.
	var sites := [Vector2(33,37.8), Vector2(33.6,31.3), Vector2(28.1,29.8), RealmDB.BOSS_THRESHOLD, RealmDB.BOSS_THRESHOLD, RealmDB.CAMP]
	var durations := [30.0, 30.0, 30.0, 300.0, 30.0, 30.0]
	var actions := 0
	var boss_skills := 0
	var observed_boss_skills := 0
	for phase in sites.size():
		realm.player.position = sites[phase]
		realm.player.invulnerable = 1000 # Survival is a fixture, not a gameplay change.
		game._input_locked = true
		game._apply_input_lock()
		var removed := false
		var elapsed := 0.0
		var next_sample := 0.0
		var boss_warm: Dictionary = {}
		while elapsed < durations[phase]:
			await get_tree().physics_frame
			elapsed += get_physics_process_delta_time()
			# Hold the fixture on its test site despite body collision/attack push.
			realm.player.position = sites[phase]
			realm.player.velocity = Vector2.ZERO
			for pack in realm._packs:
				if is_instance_valid(pack.enemy):
					actions += maxi(0, pack.enemy.cast_serial - int(pack.get("observed_cast", 0)))
					pack.observed_cast = pack.enemy.cast_serial
			if is_instance_valid(realm.boss):
				var current := (realm.boss as ElementalBoss)._skill_index
				boss_skills += maxi(0, current - observed_boss_skills)
				observed_boss_skills = current
			if phase == 4 and elapsed > 5 and elapsed < 7: realm.player.position = RealmDB.CAMP
			if elapsed >= durations[phase] - 10 and not removed:
				print("[COMBAT] phase=", phase, " player=", realm.player.position, " active=", realm.combat.active_id, " boss_arrived=", realm._boss_arrived)
				removed = true
				if phase < 3:
					for pack in realm._packs:
						if is_instance_valid(pack.enemy) and pack.encounter == RealmCombatDB.PAIRS[phase].id:
							print("[RETIRE] ", pack.enemy.name, " mode=", pack.enemy.mode, " eligible=", realm.can_damage_actor(pack.enemy))
							pack.enemy.take_damage(99999, Vector2.ZERO, realm.player)
				elif phase == 4 and is_instance_valid(realm.boss):
					realm.boss.take_damage(99999, Vector2.ZERO, realm.player)
					for child in game.get_children():
						if child is StorySequence and child.kind == "mei": child.finish()
			if elapsed >= next_sample:
				var sample := _sample("phase_%d_second_%d" % [phase, int(elapsed)])
				if phase == 3 and elapsed >= 30 and boss_warm.is_empty(): boss_warm = sample
				if DisplayServer.get_name() != "headless" and int(elapsed) == 30 and phase == 3:
					await RenderingServer.frame_post_draw
					get_viewport().get_texture().get_image().save_png(OS.get_environment("TIDESWORN_TEST_ROOT").path_join("stability_boss.png"))
				next_sample += 30
		_check(game.world == realm and not game._defeat_pending, "phase %d completes %.0f seconds in its owned realm" % [phase + 1, durations[phase]])
		if phase < 3:
			_check(realm.combat._living(str(RealmCombatDB.PAIRS[phase].id)).is_empty(), "deleted pair stays retired across real physics frames")
		if phase == 3:
			var end := _sample("boss_soak_end")
			_check(int(end.nodes) <= int(boss_warm.nodes) + 40 and int(end.objects) <= int(boss_warm.objects) + 150 and int(end.static_bytes) <= int(boss_warm.static_bytes) + 16 * 1024 * 1024 and int(end.video_bytes) <= int(boss_warm.video_bytes) + 16 * 1024 * 1024, "five-minute boss fight keeps warmed node, object, CPU and GPU memory counts bounded")
	print("[COMBAT] guard_casts=", actions, " boss_skills=", boss_skills)
	_check(actions > 12 and boss_skills > 20, "sustained guard and boss attacks actually execute")
	_check(realm._boss_defeated and realm.combat.effects.is_empty(), "victory retires all guard casts before peaceful exploration")
	# Cold/warm builds and real deletion flushes expose retained world references.
	var warm: Dictionary = {}
	for cycle in 12:
		GameState.data = GameState._make_default("adam")
		GameState.start_expedition(RealmDB.PORTAL)
		await game._load_dungeon(RealmDB.PORTAL, false)
		await _frames(4)
		realm = game.world as TwilightRealm
		realm.player.invulnerable = 1000
		game._input_locked = true
		game._apply_input_lock()
		realm.player.position = Vector2(33,37.8)
		await _frames(30)
		realm.exit_to_lobby(true)
		while game._transitioning: await get_tree().process_frame
		await _frames(4)
		var sample := _sample("world_cycle_%d" % cycle)
		if cycle == 3: warm = sample
		if cycle > 3:
			_check(int(sample.nodes) <= int(warm.nodes) + 12 and int(sample.orphans) <= int(warm.orphans), "world cycle %d releases retired nodes" % cycle)
			_check(int(sample.objects) <= int(warm.objects) + 200 and int(sample.static_bytes) <= int(warm.static_bytes) + 8 * 1024 * 1024, "world cycle %d keeps warmed object/memory counts bounded" % cycle)
	var diagnostics_path: String = game.get_node("RuntimeDiagnostics").path
	game.queue_free()
	await _frames(4)
	# Stop test audio before teardown; active playback otherwise races exit.
	Sfx.stop_battle_music()
	for player in Sfx._players:
		player.stop()
		player.stream = null
	Sfx._music.stream = null
	await _frames(4)
	_sample("after_game_free")
	var diagnostic_lines := FileAccess.get_file_as_string(diagnostics_path).split("\n", false)
	_check(diagnostic_lines.size() >= 16 and JSON.parse_string(diagnostic_lines[-1]).get("event") == "session_end", "flushed session diagnostics preserve periodic samples and clean shutdown")
	var output := OS.get_environment("TIDESWORN_TEST_ROOT").path_join("stability_samples.json")
	var file := FileAccess.open(output, FileAccess.WRITE)
	file.store_string(JSON.stringify(samples, "\t"))
	print("--- stability test: %d checks, %s ---" % [checks, "PASS" if failures == 0 else "%d FAILURE(S)" % failures])
	get_tree().quit(0 if failures == 0 else 1)

func _frames(count: int) -> void:
	for frame in count: await get_tree().physics_frame
	await get_tree().process_frame

func _summon_regression(realm: TwilightRealm) -> void:
	var summoner := realm.boss as ElementalBoss
	summoner._player = realm.player
	summoner._execute_skill({"pattern": "summon"})
	_check(summoner._summons.size() == 3, "summon fixture creates three owned minions")
	for minion in summoner._summons: minion.queue_free()
	summoner._execute_skill({"pattern": "summon"})
	var replacements := 0
	for minion in summoner._summons:
		if is_instance_valid(minion) and not minion.is_queued_for_deletion():
			replacements += 1
			minion.queue_free()
	_check(replacements == 3, "queued summons immediately release their living minion budget")
	await _frames(3)
	summoner._execute_skill({"pattern": "summon"})
	var living := 0
	for minion in summoner._summons:
		if is_instance_valid(minion) and not minion.is_queued_for_deletion():
			living += 1
			minion.queue_free()
	_check(living == 3, "repeated summon survives actual deletion of its previous minions")
	await _frames(3)

func _sample(stage: String) -> Dictionary:
	var sample := {"stage": stage, "ticks_ms": Time.get_ticks_msec(), "static_bytes": OS.get_static_memory_usage(), "objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)), "nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), "orphans": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)), "resources": int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)), "video_bytes": int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)), "texture_keys": PixelArt.CACHE.size()}
	samples.append(sample)
	print("[SAMPLE] ", JSON.stringify(sample))
	return sample

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("[%s] %s" % ["OK" if ok else "FAIL", message])
