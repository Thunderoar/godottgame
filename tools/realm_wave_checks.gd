extends RefCounted
## Real wave actors, checkpoints and warning ownership; all state is isolated.
const POINTS := [Vector2(33,37.8),Vector2(33.6,31.3),Vector2(28.1,29.8)]

static func _freeze(realm: TwilightRealm) -> void:
	realm.set_physics_process(false)
	realm.player.set_physics_process(false)
	realm.pet.set_physics_process(false)
	realm.camera.set_physics_process(false)
	for pack in realm._packs:
		if is_instance_valid(pack.enemy): pack.enemy.set_physics_process(false)

static func _kill_wave(realm: TwilightRealm, id: String) -> void:
	for guard in realm.combat._living(id).duplicate(): guard.take_damage(99999,Vector2.ZERO,realm.player)

static func _arrival(realm: TwilightRealm, index: int) -> void:
	realm.player.position = POINTS[index]
	realm.combat.tick(0)
	realm.combat.tick(1.5)
	_freeze(realm)

static func run(game: Game, check: Callable, capture: Callable = Callable()) -> void:
	var snapshot := GameState.data.duplicate(true)
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
	_freeze(realm)
	await game.get_tree().physics_frame
	await game.get_tree().physics_frame
	var routes := ResidentRoutes.new(realm,realm.map_rect)
	var total := 0
	var planned_xp := 0
	for def in RealmCombatDB.PAIRS:
		for wave in RealmCombatDB.WAVE_SIZES.size():
			total += RealmCombatDB.wave_size(wave)
			planned_xp += RealmCombatDB.wave_size(wave)*RealmCombatDB.wave_xp(wave)
		for post in RealmCombatDB.WAVE_POSTS[def.id]:
			check.call(routes.point_clear(post) and not RealmCombatDB.protected(post,0.52) and (def.pursuit as Rect2).grow(-0.52).has_point(post),"wave arrival post is physically clear, inside pursuit and outside refuges: %s %s" % [def.id,post])
		var spaced := true
		var posts: Array = RealmCombatDB.WAVE_POSTS[def.id]
		for a in posts.size():
			for b in range(a+1,posts.size()): spaced = spaced and posts[a].distance_to(posts[b])>=1.05
		check.call(spaced,"six wave arrival posts have non-overlapping body clearance: "+str(def.id))
	check.call(total==36 and RealmCombatDB.WAVE_SIZES==[2,4,6],"three sectors each contain 2/4/6 guards: nine waves and 36 guards total")
	check.call(RealmCombatDB.guard_total()==36 and PortalPanel.population_summary(RealmDB.PORTAL)=="36 guards / 9 waves","portal card reports total guards and waves rather than only the initial patrols")
	check.call(planned_xp==84,"all 36 guards preserve the former six guards' total base player XP")
	check.call(realm._packs.size()==6,"only initial patrol waves are materialized; future waves are bounded reinforcements")
	realm.player.position = RealmDB.ARRIVAL
	realm.combat.tick(120)
	check.call(realm.combat.active_id.is_empty() and realm.combat.warning==null,"waiting in the arrival refuge cannot start distant reinforcements")
	realm.player.position = POINTS[0]
	realm.combat.tick(0.016)
	check.call(realm.combat._living("rootbound_patrol").size()==2,"crossing starts with its two readable first-wave guards")
	var observations: Array[bool] = []
	var observer := func() -> void:
		if int(GameState.data.kills)==2: observations.append(GameState.citadel_waves_cleared("rootbound_patrol")==1 and "rootbound_patrol" not in GameState.citadel_path().cleared_pairs)
	GameState.data_changed.connect(observer)
	GameState.autosave_enabled = true
	_kill_wave(realm,"rootbound_patrol")
	GameState.autosave_enabled = false
	GameState.data_changed.disconnect(observer)
	var disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GameState.save_path()))
	check.call(not observations.is_empty() and not observations.has(false) and int(disk.realm_progress.citadel_path.waves_cleared.rootbound_patrol)==1 and int(disk.kills)==2,"last death saves/signals kill, XP and completed-wave progress coherently")
	check.call(not bool(GameState.light_citadel_site("crossing").ok) and not GameState.citadel_road_ready(),"one cleared wave cannot light the road or bypass the boss gate")
	realm.combat.tick(0)
	check.call(is_instance_valid(realm.combat.warning) and realm.combat.warning.posts.size()==4,"next wave shows four real arrival marks before creating enemies")
	realm.combat.tick(0.7)
	check.call(realm.combat._living("rootbound_patrol").is_empty(),"reinforcements cannot damage or appear halfway through their warning")
	if capture.is_valid():
		realm.camera.position = Vector2(33,37.5)
		realm.camera.force_update_scroll()
		await capture.call("wave_01_arrival_warning")
	realm.player.position = RealmDB.CAMP
	realm.combat.tick(30)
	check.call(realm.combat.warning==null and realm.combat._living("rootbound_patrol").is_empty() and GameState.citadel_waves_cleared("rootbound_patrol")==1,"retreat to the lantern cancels arrivals without losing completed waves")
	realm.player.position = POINTS[0]
	realm.combat.tick(0)
	var serial := GameState.journey_serial
	GameState.journey_serial += 1
	realm.combat.tick(30)
	check.call(realm.combat.warning==null and realm.combat._living("rootbound_patrol").is_empty(),"old journey ownership cannot spawn a wave into freshly reset progression")
	GameState.journey_serial = serial
	realm.combat.tick(0)
	var old_mode := realm.process_mode
	realm.process_mode = Node.PROCESS_MODE_DISABLED
	realm.combat.tick(30)
	check.call(realm.combat.warning==null and realm.combat._living("rootbound_patrol").is_empty(),"disabled worlds cannot advance or create reinforcements even through a stale tick")
	realm.process_mode = old_mode
	realm.combat.tick(0)
	realm.combat.warning.queue_free()
	await game.get_tree().process_frame
	realm.combat.tick(10)
	check.call(is_instance_valid(realm.combat.warning) and realm.combat.warning_left==RealmCombatDB.REINFORCEMENT_WARNING and realm.combat._living("rootbound_patrol").is_empty(),"a retired arrival cue is replaced by a fresh full warning, never an instant wave")
	# The real shared pet arena must own cancellation before suspending the map.
	var cat := realm.wildlife.bramble_cat as RealmInteractable
	realm.player.position = cat.position+Vector2(0,1.5)
	realm.challenge_pet(cat)
	check.call(game.hud.pet_battle_panel.is_wild_challenge() and realm.process_mode==Node.PROCESS_MODE_DISABLED and realm.combat.warning==null,"accepting a habitat duel retires pending wave warnings before suspension")
	game.hud.pet_battle_panel.close_panel()
	check.call(realm.process_mode!=Node.PROCESS_MODE_DISABLED and GameState.citadel_waves_cleared("rootbound_patrol")==1,"leaving a habitat duel resumes the earned wave checkpoint")
	GameState.save_game()
	check.call(GameState.load_game(),"wave checkpoint reload reads actual isolated JSON")
	await game._load_dungeon(RealmDB.PORTAL,false)
	realm = game.world as TwilightRealm
	_freeze(realm)
	check.call(GameState.citadel_waves_cleared("rootbound_patrol")==1 and realm.combat._living("rootbound_patrol").is_empty(),"Continue does not respawn a completed wave and does not skip the next arrival warning")
	# Never create an enemy on top of the player's body.
	realm.player.position = RealmCombatDB.WAVE_POSTS.rootbound_patrol[0]
	realm.combat.tick(0)
	realm.combat.tick(2)
	check.call(realm.combat._living("rootbound_patrol").is_empty() and is_instance_valid(realm.combat.warning),"an occupied arrival post delays reinforcements until Adam steps clear")
	realm.player.position = POINTS[0]
	realm.combat.tick(0.21)
	_freeze(realm)
	check.call(realm.combat._living("rootbound_patrol").size()==4 and realm.combat._living("rootbound_patrol").all(func(g: RealmGuard) -> bool: return g.wave_index==1),"second wave creates exactly four wave-owned guards once the posts are clear")
	var count := realm._packs.size()
	realm.spawn_guard_wave("rootbound_patrol",1)
	check.call(realm._packs.size()==count,"repeated wave callbacks cannot duplicate living reinforcements")
	if capture.is_valid(): await _shot(realm,capture,"wave_02_four_guards",Vector2(33,37.5))
	_kill_wave(realm,"rootbound_patrol")
	check.call(GameState.citadel_waves_cleared("rootbound_patrol")==2 and "rootbound_patrol" not in GameState.citadel_path().cleared_pairs,"second wave advances its checkpoint but leaves the road bound")
	_arrival(realm,0)
	var final_wave := realm.combat._living("rootbound_patrol")
	check.call(final_wave.size()==6 and final_wave.all(func(g: RealmGuard) -> bool: return g.wave_index==2 and g.get_node_or_null("EnemyHealth") is WorldHealthBar),"third wave creates six guards with the existing shared numeric health display")
	check.call(final_wave[0].max_hp==CombatBalance.health(42,false) and final_wave[5].max_hp==CombatBalance.health(44,false),"later waves add bodies rather than multiplying enemy HP")
	var other_sector := realm.combat._living("watchpost_guard")[0]
	other_sector._physics_process(0)
	other_sector._health_bar._process(0)
	check.call(not other_sector._name_label.visible and not other_sector._health_bar.visible,"active-wave overheads do not compete with dormant neighboring sector labels")
	# The existing single committed-action budget remains readable in a crowd.
	var owned := 0
	for guard in final_wave:
		guard._cooldown = 0
		guard._state = Enemy.State.CHASE
		if guard.begin_action(): owned += 1
	check.call(owned==1 and realm.combat.effects.size()==1,"six attackers retain one committed warning/damaging action at a time")
	realm.combat.cancel_all()
	realm.combat.tick(0.016)
	if capture.is_valid(): await _shot(realm,capture,"wave_03_six_guards",Vector2(33,37.5))
	_kill_wave(realm,"rootbound_patrol")
	check.call(GameState.citadel_waves_cleared("rootbound_patrol")==3 and "rootbound_patrol" in GameState.citadel_path().cleared_pairs and int(GameState.data.kills)==12,"all three waves are required to finish the crossing sector with twelve one-time kills")
	check.call(bool(GameState.light_citadel_site("crossing").ok),"the crossing light becomes available only after its final wave")
	for index in [1,2]:
		for wave in RealmCombatDB.WAVE_SIZES.size():
			_arrival(realm,index)
			var id: String = CitadelApproachDB.PAIRS[index]
			check.call(realm.combat._living(id).size()==RealmCombatDB.wave_size(wave),"sector %s delivers wave %d with its exact authored size" % [id,wave+1])
			_kill_wave(realm,id)
	var player_xp := int(GameState.data.xp)
	for level in range(1,int(GameState.data.level)): player_xp += GameState.xp_for_level(level)
	check.call(int(GameState.data.kills)==36 and player_xp==252 and GameState.citadel_path().cleared_pairs.size()==3,"fresh completion pays 36 ordinary kills while preserving 252 total pre-boss player XP")
	GameState.save_game()
	GameState.load_game()
	await game._load_dungeon(RealmDB.PORTAL,false)
	realm = game.world as TwilightRealm
	_freeze(realm)
	realm.player.position = POINTS[0]
	realm.combat.tick(120)
	check.call(realm._packs.is_empty() and realm.combat.warning==null,"completed sectors do not regrow armies after Continue")
	# Malformed and old records cannot invent or erase earned progression.
	GameState.data.realm_progress.citadel_path = CitadelApproachDB.defaults()
	GameState.data.realm_progress.citadel_path.cleared_pairs = ["watchpost_guard"]
	GameState.data.realm_progress.citadel_path.waves_cleared = {"rootbound_patrol":1,"watchpost_guard":0}
	GameState._sanitize_realm_progress()
	check.call(GameState.citadel_waves_cleared("watchpost_guard")==3 and GameState.citadel_waves_cleared("rootbound_patrol")==1,"legacy completed pair IDs migrate to completed sectors without losing partial new wave progress")
	GameState.data.realm_progress.citadel_path = CitadelApproachDB.defaults()
	GameState.data.realm_progress.citadel_path.waves_cleared = {"rootbound_patrol":999,"watchpost_guard":1.5,"ashen_sentries":"3","unknown":3}
	GameState._sanitize_realm_progress()
	check.call(GameState.citadel_path().cleared_pairs.is_empty() and GameState.citadel_waves_cleared("rootbound_patrol")==0 and GameState.citadel_waves_cleared("watchpost_guard")==0 and GameState.citadel_waves_cleared("ashen_sentries")==0,"invalid, fractional, string and unknown wave records cannot fabricate sector victories")
	# An unfinished four-guard wave reconstructs, not its already-earned predecessor.
	GameState.data = GameState._make_default("adam")
	GameState.data.portal_origin.opened = true
	GameState.start_expedition(RealmDB.PORTAL)
	GameState.data.realm_progress.citadel_path.waves_cleared.rootbound_patrol = 1
	await game._load_dungeon(RealmDB.PORTAL,false)
	realm = game.world as TwilightRealm
	_freeze(realm)
	_arrival(realm,0)
	var partial := realm.combat._living("rootbound_patrol")
	partial[0].take_damage(99999,Vector2.ZERO,realm.player)
	GameState.save_game()
	GameState.load_game()
	await game._load_dungeon(RealmDB.PORTAL,false)
	realm = game.world as TwilightRealm
	_freeze(realm)
	_arrival(realm,0)
	check.call(GameState.citadel_waves_cleared("rootbound_patrol")==1 and realm.combat._living("rootbound_patrol").size()==4,"Continue reconstructs the unfinished wave without erasing its previous checkpoint")
	# Reject an unwritable final-kill checkpoint atomically, then accept one retry.
	var retry_wave := realm.combat._living("rootbound_patrol")
	for index in 3: retry_wave[index].take_damage(99999,Vector2.ZERO,realm.player)
	GameState.save_game()
	var save := ProjectSettings.globalize_path(GameState.save_path())
	var backup := save+".wave-fault-backup"
	check.call(DirAccess.rename_absolute(save,backup)==OK and DirAccess.make_dir_recursive_absolute(save)==OK,"wave save-failure fixture owns an isolated temporary destination")
	var before_kills := int(GameState.data.kills)
	GameState.autosave_enabled = true
	retry_wave[3].take_damage(99999,Vector2.ZERO,realm.player)
	check.call(not retry_wave[3].dead and int(GameState.data.kills)==before_kills and GameState.citadel_waves_cleared("rootbound_patrol")==1,"failed final-kill save rolls back kill/XP/wave credit without consuming the actor claim")
	DirAccess.remove_absolute(save)
	DirAccess.rename_absolute(backup,save)
	retry_wave[3].take_damage(1,Vector2.ZERO,realm.player)
	GameState.autosave_enabled = false
	check.call(retry_wave[3].dead and int(GameState.data.kills)==before_kills+1 and GameState.citadel_waves_cleared("rootbound_patrol")==2,"retry after save recovery accepts the final kill and checkpoint exactly once")
	retry_wave[3]._die()
	check.call(int(GameState.data.kills)==before_kills+1,"a repeated final-wave death callback cannot pay twice")
	realm.combat.tick(0)
	var retiring_director := realm.combat
	await game._load_lobby(false)
	await game.get_tree().process_frame
	retiring_director.tick(30)
	check.call(game.world is Lobby and retiring_director.warning==null,"world replacement cancels pending arrivals and stale director ticks safely")
	GameState.data = snapshot
	GameState.autosave_enabled = autosave
	GameState._emit_all()
	game.set_process(ticking)

static func _shot(realm: TwilightRealm, capture: Callable, name: String, at: Vector2) -> void:
	for pack in realm._packs:
		if is_instance_valid(pack.enemy):
			pack.enemy._physics_process(0)
			pack.enemy._health_bar._process(0)
	realm.camera.position = at
	realm.camera.force_update_scroll()
	await capture.call(name)
