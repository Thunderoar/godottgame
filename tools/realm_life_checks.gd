extends RefCounted
## Runs in TwilightChecks' isolated fixture, then restores its progression/actors.

static func run(game: Game, realm: TwilightRealm, check: Callable, capture: Callable) -> void:
	var snapshot := GameState.data.duplicate(true)
	var actor_at := realm.player.position
	var pet_at := realm.pet.position
	var camera_at := realm.camera.position
	var camera_processing := realm.camera.is_physics_processing()
	var reduce_motion := GameSettings.reduce_motion()
	var quality := GameSettings.effects_quality()
	var routes := ResidentRoutes.new(realm, realm.map_rect)
	var cat := realm.wildlife.bramble_cat as RealmWildPet
	var moth := realm.wildlife.dusk_moth as RealmWildPet
	cat.set_process(false)
	moth.set_process(false)
	realm.camera.set_physics_process(false)
	check.call(realm.interests.size() == 5 and RealmContentDB.FRAGMENTS.size() == 3, "compact expansion has one Waykeeper, exactly three memories and one hollow")
	var clear_floors := true
	for child in realm.get_children():
		if not child is Sprite2D or str(child.get_meta("realm_prop", "")) not in ["trunk", "bloom"]: continue
		var footprint: Rect2 = child.transform * child.get_rect()
		for def in RealmDB.ENCOUNTERS.values():
			clear_floors = clear_floors and not footprint.intersects(Rect2(def.at + Vector2(-4,-3), Vector2(8,7)))
	check.call(clear_floors, "timber and bloom sprites stay entirely outside both reserved 8x7 duel floors")
	check.call(not game.hud._minimap.map_icons(realm).any(func(icon: Dictionary) -> bool: return icon.id == RealmContentDB.CACHE), "terrain discovery alone does not reveal the hidden hollow marker")
	check.call(not RealmContentDB.journal(GameState.realm_progress()).contains("beneath the citadel"), "unread journal slots conceal memory titles and story text")
	for id in realm.interests:
		var interest := realm.interests[id] as RealmInterest
		var path := routes.path(RealmDB.ARRIVAL, interest.position + Vector2(0,1), false)
		check.call(not path.is_empty() and path[-1].distance_to(interest.position + Vector2(0,1)) < 0.1, "optional interest has a collision-clear approach: " + id)
	for wild in [cat,moth]:
		var home: Vector2 = RealmDB.ENCOUNTERS[wild.stable_id].at
		realm.player.position = RealmDB.ARRIVAL
		wild.position = home
		wild._rest = 0
		GameSettings.set_reduce_motion(false, false)
		var previous: Vector2 = wild.position
		var moving := true
		for i in 4:
			wild._process(0.1)
			moving = moving and wild.position.distance_to(previous) > 0.001 and wild.position.distance_to(previous) < 0.07
			previous = wild.position
		check.call(moving and wild.position.distance_to(home) < 1.3, "living pet takes consecutive slow steps within its home: " + wild.stable_id)
		realm.player.position = wild.position + Vector2(0,2)
		previous = wild.position
		wild._process(1)
		check.call(wild.position == previous and wild.pose == "notice", "approachable pet stops and notices Adam without fleeing: " + wild.stable_id)
		GameSettings.set_reduce_motion(true, false)
		wild._process(1)
		check.call(wild.position == home and is_equal_approx(wild.art.position.y, -0.65), "Reduce Motion gives a stable, reachable habitat pose: " + wild.stable_id)
		GameSettings.set_reduce_motion(false, false)
		wild._rest = 0
		realm.player.position = RealmDB.ARRIVAL
		wild._process(0.5)
		var moving_at: Vector2 = wild.position
		realm.player.position = moving_at + Vector2(0,2)
		realm.player._update_nearby()
		wild._process(0)
		realm.survey()
		realm.camera.position = home + Vector2(0,1)
		realm.camera.reset_physics_interpolation()
		realm.camera.force_update_scroll()
		await game.get_tree().physics_frame
		await game.get_tree().process_frame
		await game.get_tree().process_frame
		if capture.is_valid(): await capture.call("10_habitat_" + wild.stable_id)
		await _touch(game, wild.get_global_transform_with_canvas() * Vector2(0,-0.65))
		check.call(game.hud.wild_challenge.visible and wild.position == home + Vector2(2.2,0.7), "moving pet stages its duel on the fixed clear floor: " + wild.stable_id)
		game.hud.wild_challenge.close_panel()
		check.call(wild.position == moving_at, "cancel restores the exact pre-duel pet patrol position: " + wild.stable_id)
		wild.position = home
		wild._rest = 4
	var wisp := realm.interests.waykeeper as RealmInterest
	realm.player.position = wisp.position + Vector2(0,2)
	realm.player._update_nearby()
	realm.player.try_interact()
	check.call(GameState.realm_progress().waykeeper_met and realm._reading_panel.visible and not game._input_locked, "E interaction meets the optional Waykeeper without locking or pausing exploration")
	check.call(realm._reading_text.text.contains("Old stones"), "Waykeeper begins with a short road-and-creatures hint")
	if capture.is_valid():
		realm.camera.position = wisp.position + Vector2(0,0.3)
		realm.camera.force_update_scroll()
		await capture.call("06_waykeeper")
	realm.close_reading()
	var gold := GameState.gold()
	var xp: int = GameState.get_active_pet().xp
	# Fragments can be read in any order, including a repeated fragment.
	for id in [RealmContentDB.FRAGMENTS[2],RealmContentDB.FRAGMENTS[0],RealmContentDB.FRAGMENTS[0],RealmContentDB.FRAGMENTS[1]]:
		var stone := realm.interests[id] as RealmInterest
		realm.player.position = stone.position + Vector2(0,1.6)
		realm.player._update_nearby()
		realm.camera.position = stone.position + Vector2(0,1)
		realm.camera.reset_physics_interpolation()
		realm.camera.force_update_scroll()
		await game.get_tree().physics_frame
		await game.get_tree().process_frame
		await game.get_tree().process_frame
		await _touch(game, stone.get_global_transform_with_canvas() * Vector2(0,-0.65))
		check.call(id in GameState.realm_progress().read_fragments and realm._reading_text.text.contains(str(RealmContentDB.INTERESTS[id].text)), "direct touch reads and journals memory: " + id)
		realm.survey()
		check.call(realm._reading_panel.visible and realm._reading_title.text == RealmContentDB.INTERESTS[id].name, "landmark survey cannot overwrite the owned memory caption")
	check.call(GameState.realm_progress().read_fragments.size() == 3 and GameState.gold() == gold and int(GameState.get_active_pet().xp) == xp, "three unique memories give knowledge without repeat Gold or XP")
	GameSettings.set_effects_quality("low", false)
	GameSettings.set_reduce_motion(true, false)
	check.call(realm.interests.values().all(func(interest: RealmInterest) -> bool: return interest.art.texture != null and interest.art.visible), "Waykeeper, memory stones and hollow remain readable on low effects and Reduce Motion")
	GameSettings.set_effects_quality(quality, false)
	GameSettings.set_reduce_motion(false, false)
	if capture.is_valid(): await capture.call("07_memory")
	await game.get_tree().process_frame
	check.call(game.get_viewport().get_visible_rect().encloses(realm._reading_panel.get_global_rect()), "memory caption and Close fit the current viewport")
	var close := realm._reading_panel.get_child(0).get_child(0).get_child(1) as Button
	await _touch(game, close.get_global_rect().get_center())
	check.call(not realm._reading_panel.visible and not game.player().controls_locked, "actual touch closes a memory caption without leaving a held input or lock")
	realm.player.position = wisp.position + Vector2(0,2)
	wisp.interact(realm.player)
	check.call(realm._reading_text.text.contains("citadel gathered"), "Waykeeper recognizes all three memories without a mandatory quest")
	realm.player.position = RealmDB.CAMP
	realm.survey()
	check.call(not realm._reading_panel.visible, "walking away dismisses reading without a control lock")
	game.hud.field_guide_panel._category = 3
	game.hud.field_guide_panel._page = 5
	game.open_field_guide()
	await game.get_tree().process_frame
	await game.get_tree().process_frame
	check.call(FieldGuideDB.description(FieldGuideDB.entries(3)[5]).contains("3 / 3") and FieldGuideDB.description(FieldGuideDB.entries(3)[5]).contains("beneath the citadel"), "Field Guide reopens the full saved three-memory journal")
	if capture.is_valid(): await capture.call("08_journal")
	game.hud.field_guide_panel.close_panel()
	var cache := realm.interests[RealmContentDB.CACHE] as RealmInterest
	realm.player.position = cache.position + Vector2(0,1.8)
	realm.player._update_nearby()
	# A temporary wall proves proximity is insufficient for either E or touch.
	var wall := StaticBody2D.new()
	realm.add_child(wall)
	realm._add_box(wall, cache.position + Vector2(0,0.9), Vector2(4,0.3))
	await game.get_tree().physics_frame
	await game.get_tree().process_frame
	cache.interact(realm.player)
	check.call(not GameState.realm_cache_opened(RealmContentDB.CACHE), "nearby cache refuses interaction through a physics wall")
	realm.camera.position = cache.position + Vector2(0,1)
	realm.camera.force_update_scroll()
	await _touch(game, cache.get_global_transform_with_canvas() * Vector2(0,-0.65))
	check.call(not GameState.realm_cache_opened(RealmContentDB.CACHE), "direct touch also refuses the cache through a physics wall")
	wall.queue_free()
	await game.get_tree().process_frame
	await game.get_tree().physics_frame
	cache.interact(realm.player)
	cache.interact(realm.player)
	check.call(GameState.gold() == gold and int(GameState.expedition_loot().gold) == 25 and GameState.expedition_loot().pending_caches == [RealmContentDB.CACHE], "double interaction carries exactly 25 Gold with one pending claim")
	GameState.save_game()
	check.call(GameState.load_game() and GameState.realm_cache_opened(RealmContentDB.CACHE) and int(GameState.expedition_loot().gold) == 25 and GameState.realm_progress().read_fragments.size() == 3, "pending cache and memories survive save/load without repaying")
	GameState.lose_expedition_loot()
	check.call(not GameState.realm_cache_opened(RealmContentDB.CACHE) and GameState.realm_progress().read_fragments.size() == 3 and GameState.realm_progress().waykeeper_met, "losing carried loot reopens the hollow but preserves knowledge and Waykeeper meeting")
	GameState.start_expedition(RealmDB.PORTAL)
	GameState.claim_realm_cache(RealmContentDB.CACHE)
	GameState.bank_expedition_loot()
	check.call(GameState.gold() == gold + 25 and RealmContentDB.CACHE in GameState.realm_progress().banked_caches and not bool(GameState.claim_realm_cache(RealmContentDB.CACHE).ok), "banking transfers the pending cache claim and reward atomically, once per journey")
	GameState.save_game()
	check.call(GameState.load_game() and not bool(GameState.claim_realm_cache(RealmContentDB.CACHE).ok) and GameState.gold() == gold + 25, "a banked hollow stays empty after a real save/load")
	for active in [false,true]:
		GameState.data.realm_progress.banked_caches = []
		GameState.data.portals[RealmDB.PORTAL].cleared = true
		if active: GameState.start_expedition(RealmDB.PORTAL)
		gold = GameState.gold()
		var result := GameState.claim_realm_cache(RealmContentDB.CACHE)
		check.call(bool(result.ok) and GameState.gold() == gold + 25 and int(GameState.expedition_loot().gold) == 0 and str(result.message).contains("banked"), "restored hollow banks immediately with expedition active = " + str(active))
	GameState.data.realm_progress.read_fragments = [RealmContentDB.FRAGMENTS[0],"missing",RealmContentDB.FRAGMENTS[0]]
	GameState.data.realm_progress.discovered_content = ["missing",RealmContentDB.CACHE,RealmContentDB.CACHE]
	GameState.data.realm_progress.banked_caches = [RealmContentDB.CACHE,RealmContentDB.CACHE,"missing"]
	GameState.data.expedition.pending_caches = [RealmContentDB.CACHE,"missing"]
	GameState._sanitize()
	check.call(GameState.realm_progress().read_fragments == [RealmContentDB.FRAGMENTS[0]] and GameState.realm_progress().banked_caches == [RealmContentDB.CACHE] and GameState.expedition_loot().pending_caches.is_empty(), "sanitization rejects unknown/duplicate IDs and pending claims already banked")
	GameState.data.realm_progress.read_fragments = {"bad":true}
	GameState.data.realm_progress.discovered_content = "invalid"
	GameState.data.realm_progress.banked_caches = 12
	GameState.data.expedition.pending_caches = {"bad":true}
	GameState._sanitize()
	check.call(GameState.realm_progress().read_fragments.is_empty() and GameState.realm_progress().banked_caches.is_empty() and GameState.expedition_loot().pending_caches.is_empty(), "non-array memory, discovery and cache ledgers sanitize to safe empty lists")
	GameState.data = snapshot.duplicate(true)
	GameState._recruit_duel_pet("pet_duel_2", false)
	GameState.set_active_pet("bramble_cat")
	cat.refresh()
	realm.player.position = cat._home + Vector2(0,2)
	cat.interact(realm.player)
	check.call(cat._companion_here and not game.hud.wild_challenge.visible and realm._reading_text.text.contains("companion settles"), "bringing the same companion home replaces its duplicate with a peaceful bond wreath")
	check.call(not bool(GameState.wild_encounter_reason("bramble_cat").ok), "self-duels are rejected by the transaction API as well as the habitat")
	# Render the hollow with its discovery/reading state, then restore this fixture.
	GameState.data = snapshot.duplicate(true)
	GameState._emit_all()
	realm.player.position = cache.position + Vector2(0,1.8)
	cache.interact(realm.player)
	realm.survey()
	realm.camera.position = cache.position + Vector2(0,1)
	realm.camera.force_update_scroll()
	check.call(game.hud._minimap.map_icons(realm).any(func(icon: Dictionary) -> bool: return icon.id == RealmContentDB.CACHE), "hollow marker appears only after physically finding its pocket")
	if capture.is_valid(): await capture.call("09_hollow")
	realm.close_reading()
	GameState.data = snapshot
	GameState._emit_all()
	realm.player.position = actor_at
	realm.pet.position = pet_at
	realm.camera.position = camera_at
	realm.camera.set_physics_process(camera_processing)
	GameSettings.set_reduce_motion(reduce_motion, false)
	GameSettings.set_effects_quality(quality, false)
	for wild in [cat,moth]:
		wild.position = RealmDB.ENCOUNTERS[wild.stable_id].at
		wild.refresh()
		wild.set_process(true)
	for interest in realm.interests.values(): interest.refresh()

static func _touch(game: Game, point: Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 19
	event.pressed = true
	event.position = game.get_viewport().get_final_transform() * point
	Input.parse_input_event(event)
	await game.get_tree().process_frame
	var release := InputEventScreenTouch.new()
	release.index = event.index
	release.position = event.position
	Input.parse_input_event(release)
	await game.get_tree().process_frame
