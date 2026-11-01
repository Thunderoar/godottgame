extends RefCounted
## Fresh-world progression is exercised here; legacy suites use explicit prepared fixtures.
static func prepare_fixture(realm: TwilightRealm) -> void:
	var path := CitadelApproachDB.defaults()
	path.cleared_pairs = CitadelApproachDB.PAIRS.duplicate()
	path.crossing_lit = true
	path.watchpost_lit = true
	path.lantern_prepared = true
	GameState.data.realm_progress.citadel_path = path
	GameState.data.realm_progress.shortcut = true
	realm.player.position = RealmDB.BOSS_THRESHOLD
	realm.approach_phase = TwilightRealm.ApproachPhase.INTRO
	realm.begin_citadel_combat()

static func _kill_pair(realm: TwilightRealm, index: int) -> void:
	var points := [Vector2(33,37.8),Vector2(33.6,31.3),Vector2(28.1,29.8)]
	realm.player.position = points[index]
	realm.combat.tick(0.016)
	for pack in realm._packs:
		if is_instance_valid(pack.enemy) and not pack.enemy.dead and pack.encounter == CitadelApproachDB.PAIRS[index]:
			pack.enemy.take_damage(99999,Vector2.ZERO,realm.player)

static func run(game: Game, check: Callable, capture: Callable = Callable()) -> void:
	var saved := GameState.data.duplicate(true)
	var autosave := GameState.autosave_enabled
	var ticking := game.is_processing()
	game.set_process(false)
	game.hud.hide_modals()
	GameState.autosave_enabled = false
	GameState.data = GameState._make_default("adam")
	GameState.data.portal_origin.opened = true
	GameState.start_expedition(RealmDB.PORTAL)
	await game._load_dungeon(RealmDB.PORTAL,false)
	var realm := game.world as TwilightRealm
	realm.player.set_physics_process(false)
	realm.pet.set_physics_process(false)
	await game.get_tree().physics_frame
	check.call(not realm.boss.visible and not realm.mei_prison.visible and realm.approach_phase == TwilightRealm.ApproachPhase.SEALED,"citadel fresh arrival conceals the boss/prison behind a sealed ward")
	var hp := realm.boss.hp
	realm.player.position = RealmDB.BOSS_THRESHOLD
	realm._physics_process(0.016)
	realm.boss.take_damage(99999,Vector2.ZERO,realm.pet)
	check.call(not realm._boss_arrived and realm.boss.hp == hp and realm.player.position == RealmDB.CAMP,"citadel direct rush/forced position cannot activate or damage the ruler")
	var ray := PhysicsRayQueryParameters2D.create(Vector2(26,21),Vector2(26,16),1)
	check.call(not realm.get_world_2d().direct_space_state.intersect_ray(ray).is_empty(),"citadel front ward is real world collision")
	ray = PhysicsRayQueryParameters2D.create(Vector2(38,15),Vector2(32,15),1)
	check.call(not realm.get_world_2d().direct_space_state.intersect_ray(ray).is_empty(),"citadel eastern approach cannot bypass the ward")
	var routes := ResidentRoutes.new(realm,realm.map_rect)
	var path := routes.path(RealmDB.CAMP,Vector2(41,8),false)
	check.call(not path.is_empty() and path[-1].distance_to(Vector2(41,8))<0.1,"citadel ward preserves the outside route to onward passages")
	GameState.discover_realm_landmark("citadel")
	var icons: Array = game.hud._minimap.map_icons(realm)
	check.call(not icons.any(func(icon: Dictionary) -> bool: return icon.id == "boss") and icons.any(func(icon: Dictionary) -> bool: return icon.id == "citadel_ward"),"citadel discovered-but-unrevealed map uses an entrance icon, not a boss spoiler")
	if capture.is_valid():
		var following := realm.camera.is_physics_processing()
		realm.camera.set_physics_process(false)
		realm.camera.position = RealmDB.CAMP-Vector2(0,3)
		realm.camera.force_update_scroll()
		await capture.call("21_citadel_sealed")
		realm.camera.set_physics_process(following)
	var permutations: Array = []
	_orders([], ["root", "crossing", "watch", "winch", "ashen", "prepare"], permutations)
	var legal_orders := 0
	var order_ok := true
	for order in permutations:
		var row := CitadelApproachDB.defaults()
		var valid := true
		for action in order:
			if action == "root": row.cleared_pairs.append("rootbound_patrol")
			elif action == "watch": row.cleared_pairs.append("watchpost_guard")
			elif action == "ashen": row.cleared_pairs.append("ashen_sentries")
			elif action == "crossing":
				if "rootbound_patrol" not in row.cleared_pairs: valid = false; break
				row.crossing_lit = true
				if row.watchpost_lit: order_ok = order_ok and not CitadelApproachDB.followup(row).contains("winch")
			elif action == "winch":
				if "watchpost_guard" not in row.cleared_pairs: valid = false; break
				row.watchpost_lit = true
			else:
				if not CitadelApproachDB.can_prepare(row,true): valid = false; break
				row.lantern_prepared = true
		if valid:
			legal_orders += 1
			order_ok = order_ok and CitadelApproachDB.ready(row,true) and str(CitadelApproachDB.next_step(row).id)=="enter"
	check.call(legal_orders==30 and order_ok,"citadel all 30 legal task orders reach admission with accurate out-of-order follow-up")
	var truth_ok := true
	for mask in 128:
		var row := CitadelApproachDB.defaults()
		for i in 3:
			if mask & (1<<i): row.cleared_pairs.append(CitadelApproachDB.PAIRS[i])
		row.crossing_lit = bool(mask & 8)
		row.watchpost_lit = bool(mask & 16)
		row.lantern_prepared = bool(mask & 64)
		truth_ok = truth_ok and CitadelApproachDB.ready(row,bool(mask & 32)) == (mask == 127)
	check.call(truth_ok,"citadel all 128 road prerequisite combinations reject every incomplete readiness state")
	check.call(not RealmCombatDB.protected(CitadelApproachDB.CROSSING),"citadel crossing mechanism adds no optional-reading combat refuge")
	# Early lantern remains a refuge/rest, not free admission.
	realm.player.position = RealmDB.CAMP
	realm.rest_at_camp()
	realm._physics_process(2.1)
	check.call(GameState.realm_progress().checkpoint == "camp" and not GameState.citadel_road_ready() and not realm._camp_resting,"citadel early rest completes without a suspended-timer deadlock or granting readiness")
	# Deliberately complete watchpost before crossing; a legacy open shortcut isn't a light.
	GameState.data.realm_progress.shortcut = true
	_kill_pair(realm,1)
	var result := GameState.light_citadel_site("watchpost")
	check.call(bool(result.ok) and GameState.citadel_path().watchpost_lit,"citadel already-open legacy winch can still restore the new watchpost light")
	var kills := int(GameState.data.kills)
	var xp := int(GameState.data.xp)
	result = GameState.light_citadel_site("watchpost")
	check.call(bool(result.ok) and not bool(result.changed) and int(GameState.data.kills)==kills and int(GameState.data.xp)==xp,"citadel repeated mechanism input is idempotent and pays no quest XP")
	# Both guards are accepted through their real damage/death path, not missing-node inference.
	_kill_pair(realm,0)
	check.call("rootbound_patrol" in GameState.citadel_path().cleared_pairs and int(GameState.data.kills)==4,"citadel actual guard deaths commit four kills and two completed pairs once")
	# An unwritable save destination must roll back the accepted light transaction.
	GameState.save_game()
	var save := ProjectSettings.globalize_path(GameState.save_path())
	var backup := save+".citadel-fault-backup"
	DirAccess.rename_absolute(save,backup)
	DirAccess.make_dir_recursive_absolute(save)
	GameState.autosave_enabled = true
	var failed := GameState.light_citadel_site("crossing")
	GameState.autosave_enabled = false
	check.call(not bool(failed.ok) and not GameState.citadel_path().crossing_lit,"citadel save failure rolls back light acceptance and reports failure, not success")
	DirAccess.remove_absolute(save)
	DirAccess.rename_absolute(backup,save)
	result = GameState.light_citadel_site("crossing")
	check.call(bool(result.ok) and str(result.message).contains("last pair") and not str(result.message).contains("winch"),"citadel out-of-order crossing follow-up points ahead, not back to the restored winch")
	GameState.save_game()
	check.call(GameState.load_game() and GameState.citadel_path().cleared_pairs.size()==2 and GameState.citadel_path().crossing_lit,"citadel road accomplishments survive an actual JSON reload")
	await game._load_dungeon(RealmDB.PORTAL,false)
	realm = game.world as TwilightRealm
	realm.player.set_physics_process(false)
	realm.pet.set_physics_process(false)
	check.call(realm._packs.size()==2 and realm._packs[0].enemy.max_hp == CombatBalance.health(50,false) and realm._packs[1].enemy.max_hp == CombatBalance.health(52,false),"citadel reconstruction skips completed pairs without reindexing remaining HP")
	# Observe final death: pair and XP are coherent by the first notification and on disk.
	var observations: Array[bool] = []
	var observe := func() -> void:
		if int(GameState.data.kills)==6: observations.append("ashen_sentries" in GameState.citadel_path().cleared_pairs)
	GameState.data_changed.connect(observe)
	GameState.autosave_enabled = true
	_kill_pair(realm,2)
	GameState.autosave_enabled = false
	GameState.data_changed.disconnect(observe)
	var disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GameState.save_path()))
	check.call(not observations.is_empty() and not observations.has(false) and "ashen_sentries" in disk.realm_progress.citadel_path.cleared_pairs and int(disk.kills)==6,"citadel final kill saves and signals XP/kill/pair completion as one coherent transaction")
	var phase_ok := true
	for phase in TwilightRealm.ApproachPhase.values():
		for ready in [false,true]:
			var old_prepared: bool = GameState.data.realm_progress.citadel_path.lantern_prepared
			GameState.data.realm_progress.citadel_path.lantern_prepared = ready
			realm.approach_phase = phase
			realm._boss_arrived = phase == TwilightRealm.ApproachPhase.COMBAT
			phase_ok = phase_ok and realm.can_damage_actor(realm.boss) == (ready and phase == TwilightRealm.ApproachPhase.COMBAT)
			GameState.data.realm_progress.citadel_path.lantern_prepared = old_prepared
	realm._boss_arrived = false
	realm.approach_phase = TwilightRealm.ApproachPhase.READY
	check.call(phase_ok,"citadel every lifecycle phase rejects boss damage except a ready current combat attempt")
	var before := int(GameState.data.kills)
	for pack in realm._packs:
		if is_instance_valid(pack.enemy): pack.enemy._die()
	check.call(int(GameState.data.kills)==before,"citadel duplicate death callbacks cannot pay or complete twice")
	realm.player.position = RealmDB.CAMP
	realm.rest_at_camp()
	realm._physics_process(2.1)
	check.call(GameState.citadel_road_ready() and game._story_active and realm.process_mode==Node.PROCESS_MODE_DISABLED and not realm._boss_arrived,"citadel rest finishes and commits readiness BEFORE the suspended preparation reveal")
	if capture.is_valid(): await capture.call("18_citadel_preparation")
	game._citadel_conversation.finish()
	await game.get_tree().process_frame
	check.call(not game._story_active and not game._input_locked and realm.approach_phase==TwilightRealm.ApproachPhase.READY,"citadel preparation restores control without starting combat")
	check.call(not GameState.realm_progress().waykeeper_met and GameState.realm_progress().bonded.is_empty() and GameState.realm_progress().read_fragments.is_empty(),"citadel readiness requires no Wisp conversation, companion win or memory collection")
	realm.player.position = CitadelApproachDB.ENTRANCE
	realm.request_citadel_entry()
	var sequence := game._citadel_conversation
	sequence.advance()
	check.call(is_instance_valid(sequence) and not sequence.accepted and not realm._boss_arrived,"citadel held/initial input cannot accidentally accept entrance")
	await game.get_tree().process_frame
	var display_scale := float(game.get_window().size.y)/maxf(1,game.get_viewport_rect().size.y) if DisplayServer.get_name() != "headless" else 1.0
	check.call(game.get_viewport_rect().encloses(sequence._panel.get_global_rect()) and sequence._next.get_global_rect().size.y*display_scale>=43.9,"citadel dialogue fits the viewport with a physical 44-pixel entrance action")
	if capture.is_valid(): await capture.call("19_citadel_entry_choice")
	sequence._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	sequence._process(3)
	sequence.advance()
	check.call(not sequence.accepted and not sequence._armed,"citadel focus loss cannot arm or advance the entrance dialogue")
	sequence._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	sequence._process(0.4)
	if capture.is_valid():
		await _tap(game,sequence._skip.get_global_rect().get_center())
	else: sequence.finish(false)
	await game.get_tree().process_frame
	check.call(realm.approach_phase==TwilightRealm.ApproachPhase.READY and not game._story_active,"citadel Not yet leaves the player safe and ready")
	realm.request_citadel_entry()
	var accept_sequence := game._citadel_conversation
	await game.get_tree().process_frame # Wait for the new container/button layout before real pointer input.
	accept_sequence._process(0.4)
	if capture.is_valid():
		await _tap(game,accept_sequence._next.get_global_rect().get_center())
	else:
		var key := InputEventKey.new()
		key.keycode = KEY_ENTER
		key.physical_keycode = KEY_ENTER
		key.pressed = true
		Input.parse_input_event(key)
		await game.get_tree().process_frame
		key = InputEventKey.new()
		key.keycode = KEY_ENTER
		key.physical_keycode = KEY_ENTER
		Input.parse_input_event(key)
		await game.get_tree().process_frame
	await game.get_tree().process_frame
	check.call(realm.approach_phase==TwilightRealm.ApproachPhase.ENTRY_GRANTED and not realm._boss_arrived,"citadel fresh consent opens traversal but does not make the boss attackable")
	realm.player.position = RealmDB.BOSS_THRESHOLD
	realm._physics_process(0.016)
	check.call(game._story_active and realm.citadel_revealed() and realm.boss.visible and realm.boss.modulate.a == 1.0 and not realm.can_damage_actor(realm.boss) and not realm._boss_arrived,"citadel threshold reveals a suspended first meeting, not instant combat")
	if capture.is_valid(): await capture.call("20_citadel_first_meeting")
	game._citadel_conversation.finish(true)
	await game.get_tree().process_frame
	check.call(realm._boss_arrived and realm.approach_phase==TwilightRealm.ApproachPhase.COMBAT and realm.can_damage_actor(realm.boss) and GameState.citadel_path().intro_seen,"citadel intro completion arms exactly one authorized fight and saves presentation history")
	realm.pet.position = RealmDB.BOSS_THRESHOLD
	realm.player.position = RealmDB.CAMP
	realm._physics_process(0.016)
	check.call(not realm._boss_arrived and not realm.can_damage_actor(realm.boss) and GameState.citadel_road_ready(),"citadel retreat clears combat permission without losing road progress")
	check.call(realm.ward.front.collision_layer==0,"citadel retreat never seals a following companion behind the ward")
	realm.pet.position = RealmDB.CAMP
	realm.ward._physics_process(0.016)
	check.call(realm.ward.front.collision_layer==1,"citadel ward closes safely after the companion clears its opening")
	realm.player.position = CitadelApproachDB.ENTRANCE
	realm.request_citadel_entry()
	game._citadel_conversation.finish(true)
	await game.get_tree().process_frame
	realm.player.position = RealmDB.BOSS_THRESHOLD
	realm._physics_process(0.016)
	check.call(game._citadel_conversation.pages.size()==1,"citadel retries use a short exchange instead of repeating the full introduction")
	await game._load_lobby(false)
	check.call(not game._story_active and not is_instance_valid(game._citadel_conversation) and game.world is Lobby and not game.player().controls_locked,"citadel world replacement cancels the owned conversation without combat or lock leaks")
	# Old camp/open-shortcut saves gain no invented victories and retain progress.
	GameState.data = GameState._make_default("adam")
	GameState.data.realm_progress.shortcut = true
	GameState.data.realm_progress.checkpoint = "camp"
	GameState.data.realm_progress.erase("citadel_path")
	GameState.save_game()
	check.call(GameState.load_game() and GameState.realm_progress().shortcut and GameState.realm_progress().checkpoint=="camp" and GameState.citadel_path().cleared_pairs.is_empty() and not GameState.citadel_road_ready(),"citadel real old JSON preserves an open winch/camp without fabricating road eligibility")
	GameState.data.realm_progress.citadel_path = {"cleared_pairs":["unknown","watchpost_guard","watchpost_guard"],"crossing_lit":"true","watchpost_lit":true,"lantern_prepared":true,"intro_seen":true}
	GameState._sanitize_realm_progress()
	check.call(GameState.citadel_path().cleared_pairs==["watchpost_guard"] and not GameState.citadel_path().crossing_lit and not GameState.citadel_path().lantern_prepared and not GameState.citadel_path().intro_seen,"citadel malformed records deduplicate IDs, reject truthy strings and reconcile prerequisites")
	GameState.data.portals.tidebound_grotto.cleared = true
	GameState.data.realm_progress.visit_active = true
	GameState.data.realm_progress.shortcut = false
	GameState.data.realm_progress.citadel_path = CitadelApproachDB.defaults()
	GameState.save_game()
	GameState.load_game() # Exercise real legacy clear -> rescued-friend migration.
	await game._load_dungeon(RealmDB.PORTAL,false)
	realm = game.world as TwilightRealm
	var restored_labels := true
	for child in realm.get_children():
		if child is CitadelRoadSite: restored_labels = restored_labels and not child.label.text.contains("Free the crossing") and not child.label.text.contains("Relight")
	realm.open_shortcut()
	var restored_rest := GameState.finish_citadel_rest(false)
	check.call(restored_labels and realm._boss_defeated and not is_instance_valid(realm.boss) and GameState.realm_progress().shortcut and str(restored_rest.message).contains("peaceful"),"citadel old cleared worlds retain peaceful labels, rest and optional shortcut without new quest debt")
	GameState.data = saved
	GameState.autosave_enabled = autosave
	GameState._emit_all()
	game.set_process(ticking)

static func _tap(game: Game, point: Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = game.get_viewport().get_final_transform()*point
	event.pressed = true
	Input.parse_input_event(event)
	await game.get_tree().process_frame
	var release := InputEventScreenTouch.new()
	release.index = 0
	release.position = event.position
	Input.parse_input_event(release)
	await game.get_tree().process_frame

static func _orders(prefix: Array, remaining: Array, result: Array) -> void:
	if remaining.is_empty():
		result.append(prefix)
		return
	for index in remaining.size():
		var next := prefix.duplicate()
		next.append(remaining[index])
		var rest := remaining.duplicate()
		rest.remove_at(index)
		_orders(next,rest,result)
