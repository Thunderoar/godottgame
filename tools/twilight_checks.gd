extends RefCounted

static func run(game: Game, check: Callable, capture: Callable = Callable()) -> void:
	var snapshot := GameState.data.duplicate(true)
	var autosave := GameState.autosave_enabled
	var ticking := game.is_processing()
	game.hud.hide_modals()
	GameState.autosave_enabled = false
	game.set_process(false)
	GameState.data = GameState._make_default("adam")
	GameState._emit_all()
	await game._load_lobby(false)
	await game.get_tree().process_frame
	check.call(game.get_tree().get_nodes_in_group("battle_portal").size() == 1, "one dimension entrance replaces the paired village gates")
	var gate := game.world.get_node("MonsterBattlePortal") as PortalEntrance
	gate.interact(game.player())
	for frame in 200:
		if game.world is TwilightRealm and not game._transitioning: break
		await game.get_tree().create_timer(0.03).timeout
	check.call(game.world is TwilightRealm and not game.hud.portal_panel.visible, "village portal enters the explorable realm without a destination list")
	var realm := game.world as TwilightRealm
	if not is_instance_valid(realm): return
	realm.player.set_physics_process(false)
	realm.pet.set_physics_process(false)
	check.call(realm.player.position.is_equal_approx(RealmDB.ARRIVAL), "new visitors arrive beside the return rift")
	check.call(realm.map_rect.size == Vector2(56,52) and RealmDB.SIZE.x * RealmDB.SIZE.y < 72 * 72 * 0.57, "compact realm removes over 43 percent of the original map area")
	check.call(RealmDB.BOSS_ARENA.size == Vector2(20,20), "compaction preserves full-size boss movement and dodge space")
	var content_inside := RealmDB.ENCOUNTERS.values().all(func(def: Dictionary) -> bool: return realm.map_rect.grow(-2).has_point(def.at))
	for place in realm.get_children():
		if place is RealmInteractable: content_inside = content_inside and realm.map_rect.grow(-1).has_point(place.position)
	check.call(content_inside, "both pet habitats, checkpoint, exits and all onward passages fit inside the compact boundary")
	var main_route := PackedVector2Array(RealmDB.PATHS[0])
	check.call(_length(main_route) < 52, "authored main road is shorter than 52 units instead of the original roughly 66-unit walk")
	check.call(not realm._boss_arrived and not realm.boss.active, "citadel boss remains dormant at arrival")
	var boss_hp := realm.boss.hp
	realm.boss.take_damage(9999,Vector2.ZERO,realm.pet)
	check.call(realm.boss.hp == boss_hp and not realm._boss_arrived, "weapons and companions cannot wake or damage the dormant ruler")
	realm._physics_process(30)
	check.call(not realm._boss_arrived and realm._packs.all(func(pack: Dictionary) -> bool: return not pack.active), "waiting at arrival never triggers global pursuit")
	GameState.advance_world_clock(180)
	game._process(30)
	check.call(not GameState.emergency_active() and GameState.is_night(), "long nighttime realm exploration advances the shared clock without starting an offscreen raid")
	GameState.advance_world_clock(150)
	var before := realm.player.position
	Input.action_press("move_right")
	var positions: Array[float] = []
	for step in 4:
		realm.player._physics_process(0.016)
		positions.append(realm.player.position.x)
	Input.action_release("move_right")
	check.call(positions[1] > positions[0] and positions[2] > positions[1] and positions[3] > positions[2], "realm movement remains continuous across consecutive physics steps")
	realm.player.position = before
	realm.player.velocity = Vector2.ZERO
	var map := game.hud._minimap
	check.call(not map.map_icons(realm).any(func(icon: Dictionary) -> bool: return icon.id == "boss"), "undiscovered citadel ruler is hidden from both map sizes")
	if capture.is_valid():
		realm.camera.set_physics_process(false)
		realm.camera.position = RealmDB.ARRIVAL + Vector2(0,-4)
		realm.camera.force_update_scroll()
		await capture.call("01_arrival")
	var routes := ResidentRoutes.new(realm, realm.map_rect)
	for destination in [RealmDB.ENCOUNTERS.bramble_cat.at, RealmDB.ENCOUNTERS.dusk_moth.at, RealmDB.CAMP]:
		var path := routes.path(RealmDB.ARRIVAL, destination, false)
		check.call(not path.is_empty() and path[-1].distance_to(destination) < 0.1, "arrival has a complete collision-clear route to %s" % destination)
	for place in realm.get_children():
		if place is RealmInteractable and place.kind == "passage":
			var path := routes.path(RealmDB.CAMP,place.position,false)
			check.call(not path.is_empty() and path[-1].distance_to(place.position) < 0.1, "compact layout preserves a complete route to %s" % place.caption)
	var cat := realm.wildlife.bramble_cat as RealmInteractable
	await preload("res://tools/realm_life_checks.gd").run(game, realm, check, capture)
	realm.player.position = cat.position + Vector2(0,2)
	realm.survey()
	check.call(bool(GameState.wild_encounter_reason("bramble_cat").ok) and int(GameState.get_active_pet().level) == 1, "starter Ember can challenge the cat without tournament clears or paid levels")
	var original_player := realm.player.position
	var original_pet := realm.pet.position
	var tournament_before: Dictionary = GameState.data.pet_battles.duplicate(true)
	cat.interact(realm.player)
	var panel := game.hud.pet_battle_panel
	check.call(panel.visible and panel.is_wild_challenge() and realm.process_mode == Node.PROCESS_MODE_DISABLED and game.player().controls_locked, "habitat opens the pre-existing PetBattlePanel and suspends world combat")
	check.call(panel._arena_backdrop.texture != null and panel._battle_level == "pet_duel_2" and panel._enemy_sprite.texture != null, "cat uses the existing Bramble Court arena, sprites and battle widgets")
	check.call(not panel.start_battle("pet_duel_1") and panel._battle_level == "pet_duel_2", "tournament entry cannot replace an owned habitat challenge")
	check.call(not game.hud._map_button.visible and realm.player.position == original_player and realm.pet.position == original_pet, "arena hides world controls without moving either map participant")
	await game.get_tree().process_frame
	var viewport := game.get_viewport().get_visible_rect()
	check.call(panel._skill_buttons.size() == 3 and panel._skill_buttons.all(func(button: Button) -> bool: return viewport.encloses(button.get_global_rect())), "all three existing arena powers remain inside the viewport")
	game.open_settings()
	await game.get_tree().process_frame
	var original_touch := GameSettings.touch_controls()
	GameSettings.set_touch_controls("always", false)
	var paused_hp := panel._opponent_hp
	panel._process(30)
	check.call(panel._opponent_hp == paused_hp and realm.process_mode == Node.PROCESS_MODE_DISABLED, "Settings preserves the protected challenge and its turn")
	check.call(not game.hud._joystick.visible, "live touch-setting changes cannot expose world controls during a challenge")
	GameSettings.set_touch_controls(original_touch, false)
	game.hud.settings_panel.close_panel()
	check.call(game.player().controls_locked, "closing Settings does not release the challenge lock")
	var hp := GameState.health()
	var arena_hp := panel._player_hp
	panel._process(20)
	check.call(panel._player_hp == arena_hp and GameState.health() == hp and panel._turn_active, "existing manual battle waits indefinitely without damaging saved player or pet")
	if capture.is_valid():
		realm.camera.force_update_scroll()
		await capture.call("02_bramble_challenge")
	var rival_hp := panel._opponent_hp
	var battle_sprite := panel._player_sprite
	GameState.data_changed.emit()
	check.call(panel._player_sprite == battle_sprite and panel._opponent_hp == rival_hp, "progress refresh preserves the active shared arena and its local HP")
	panel._enemy_choice = "attack"
	await _tap(game, panel._skill_buttons[0].get_global_rect().get_center())
	check.call(panel._opponent_hp < rival_hp and panel._player_hp == arena_hp, "player choice lands before the rival reply")
	game.open_settings()
	await game.get_tree().process_frame
	var reply_wait := panel._enemy_wait
	var cooldowns := panel._player_cooldowns.duplicate()
	var clock := float(GameState.data.world_time)
	panel._process(30)
	panel.choose_skill("burst")
	game._process(3)
	check.call(panel._enemy_pending and panel._enemy_wait == reply_wait and panel._player_cooldowns == cooldowns and float(GameState.data.world_time) == clock, "Settings suspends pending replies, cooldowns, input and the realm clock")
	game.hud.settings_panel.close_panel()
	panel._process(0.71)
	check.call(panel._player_hp < arena_hp and panel._awaiting_next, "wild rival uses the existing delayed reply after the explicit choice")
	panel.close_panel()
	panel._finish_battle(true)
	check.call(not panel.visible and realm.process_mode != Node.PROCESS_MODE_DISABLED and not game.player().controls_locked, "cancel restores the world, controls and music")
	check.call(realm.player.position == original_player and realm.pet.position == original_pet and Sfx.battle_track.is_empty(), "cancel restores participant positions without reward")
	check.call(GameState.get_pet("bramble_cat").is_empty(), "unfinished challenge grants no recruit")
	check.call(GameState.data.pet_battles == tournament_before, "late completion after cancel cannot award or clear a tournament duel")
	cat.interact(realm.player)
	panel._opponent_hp = 1
	var gold := GameState.gold()
	panel.choose_skill("burst")
	panel._process(0)
	check.call(GameState.realm_pet_bonded("bramble_cat") and GameState.gold() == gold + 25, "winning commits a unique cat recruit and first reward")
	check.call(not panel.get_children().any(func(child: Node) -> bool: return child is PetHitEffect and child.visible), "resolved arena clears old impact effects before showing the bond result")
	check.call(GameState.data.pet_battles == tournament_before, "habitat win keeps its reward rules separate from tournament unlocks and guaranteed levels")
	if capture.is_valid(): await capture.call("16_cat_bond_result")
	var token := panel._wild_token
	check.call(not bool(GameState.complete_wild_encounter(token).ok), "duplicate victory callback cannot pay a second reward")
	panel.close_panel()
	cat.interact(realm.player)
	panel._opponent_hp = 1
	var pet_level := int(GameState.get_active_pet().level)
	gold = GameState.gold()
	panel.choose_skill("burst")
	panel._process(0)
	panel.close_panel()
	check.call(GameState.gold() == gold and int(GameState.get_active_pet().level) == pet_level, "friendly repeat sparring cannot farm Gold or guaranteed levels")
	var moth := realm.wildlife.dusk_moth as RealmInteractable
	realm.player.position = moth.position + Vector2(0,2)
	moth.interact(realm.player)
	if capture.is_valid(): await capture.call("17_moth_arena")
	panel._player_hp = 1
	panel._enemy_choice = "defend"
	panel.choose_skill("attack")
	panel._process(0.71)
	check.call(not panel._battle_resolved and panel._enemy_guard, "habitat rival uses the existing shield action and turn engine")
	panel._process(0.61)
	panel._enemy_choice = "attack"
	panel.choose_skill("burst")
	panel._process(0.71)
	check.call(panel._battle_resolved and not bool(panel._last_result.ok) and GameState.get_pet("dusk_moth").is_empty(), "losing peacefully grants no wild recruit")
	panel.close_panel()
	check.call(GameState.health() == hp and GameState.has_living_pet(), "wild challenge loss does not damage persistent health or companion readiness")
	moth.interact(realm.player)
	panel._opponent_hp = 1
	panel.choose_skill("burst")
	panel._process(0)
	panel.close_panel()
	check.call(GameState.unbonded_realm_pets().is_empty() and not bool(GameState.pet_battle_state("pet_duel_1").cleared), "both habitat bonds finish wild guidance without fabricating a legacy tournament clear")
	var blocked_path := routes.path(Vector2(12,32), RealmDB.CAMP, false)
	var blocked_length := _length(blocked_path)
	realm.open_shortcut()
	await game.get_tree().process_frame
	await game.get_tree().physics_frame
	check.call(bool(GameState.realm_progress().shortcut) and not is_instance_valid(realm._shortcut_body), "watchpost winch opens and persists the rootway")
	routes.invalidate()
	var opened_path := routes.path(Vector2(12,32), RealmDB.CAMP, false)
	check.call(not opened_path.is_empty() and _length(opened_path) < blocked_length, "the opened rootway creates a physically shorter collision-clear return path")
	if capture.is_valid():
		game.open_map()
		await game.get_tree().process_frame
		await game.get_tree().process_frame
		await capture.call("05_discovered_map")
		game.hud.map_panel.close_panel()
	realm.player.position = RealmDB.CAMP
	realm.rest_at_camp()
	realm._physics_process(2.1)
	check.call(GameState.realm_progress().checkpoint == "camp" and GameState.health() == GameState.health_max(), "citadel lantern saves a checkpoint and completes a safe rest")
	GameState.save_game()
	check.call(GameState.load_game() and GameState.realm_pet_bonded("bramble_cat") and bool(GameState.realm_progress().shortcut), "bonded pets, shortcut and discoveries survive save/load")
	var saved_progress := GameState.realm_progress()
	GameState.data.realm_progress.cells = ["0:0","3:4","5:5"]
	GameState._sanitize()
	check.call(GameState.realm_progress().cells == ["0:0","3:4","5:5"] and GameState.realm_progress().checkpoint == "camp" and GameState.realm_pet_bonded("bramble_cat"), "old six-by-six discovery IDs, checkpoint and bonds survive map compaction")
	GameState.data.erase("realm_progress")
	GameState._sanitize()
	check.call(bool(GameState.realm_progress().visit_active) and GameState.realm_progress().checkpoint == "arrival", "old active first-portal saves migrate to a safe realm arrival")
	GameState.data.realm_progress = saved_progress
	await game._load_dungeon(RealmDB.PORTAL,false)
	await game.get_tree().physics_frame
	realm = game.world as TwilightRealm
	if capture.is_valid(): realm.camera.set_physics_process(false)
	realm.player.set_physics_process(false)
	realm.pet.set_physics_process(false)
	check.call(realm.player.position.distance_to(RealmDB.CAMP) < 0.1 and not realm._boss_arrived, "Continue reconstruction uses the safe checkpoint and resets unfinished boss")
	var hollow := realm.interests[RealmContentDB.CACHE] as RealmInterest
	realm.player.position = hollow.position + Vector2(0,1.8)
	hollow.interact(realm.player)
	check.call(RealmContentDB.CACHE in GameState.expedition_loot().get("pending_caches", []), "an actual hollow interaction carries its pending gift toward citadel victory")
	realm.player.position = RealmDB.BOSS_THRESHOLD
	realm._physics_process(0.1)
	check.call(realm._boss_arrived and realm.boss.active and Sfx.battle_track == RealmDB.PORTAL, "crossing the citadel threshold activates the boss and battle track")
	check.call(realm.boss._boss_notified, "citadel threshold arms the boss special-attack lifecycle")
	check.call(realm.camera.framing_bounds.has_area() and realm.camera.zoom.y <= game.get_viewport_rect().size.y / 23.0 + 0.01, "boss encounter frames the whole chamber and overhead warnings even at high preferred zoom")
	realm.player.position = RealmDB.CAMP
	realm._physics_process(0.1)
	check.call(not realm._boss_arrived and realm.boss.hp == realm.boss.max_hp and Sfx.battle_track.is_empty(), "retreat resets the unfinished boss without moving through walls")
	check.call(not realm.camera.framing_bounds.has_area(), "retreat releases encounter framing back to the exploration camera")
	realm.player.position = RealmDB.BOSS_THRESHOLD
	realm._physics_process(0.1)
	realm.player.position = (RealmDB.BOSS_ARENA.position + Vector2(21,14))
	realm._physics_process(0.1)
	check.call(not realm._boss_arrived and not realm.camera.framing_bounds.has_area(), "retreat through the eastern passage also releases the boss and camera leash")
	realm.player.position = RealmDB.BOSS_THRESHOLD
	realm._physics_process(0.1)
	if capture.is_valid():
		realm.camera.position = realm.camera.framing_bounds.get_center()
		realm.camera.force_update_scroll()
		await capture.call("03_citadel")
	realm.boss.take_damage(999999,Vector2.ZERO,realm.player)
	await game.get_tree().process_frame
	check.call(realm._boss_defeated and bool(GameState.portal_state(RealmDB.PORTAL).cleared) and not game.hud.victory_panel.visible, "boss victory restores the realm without forcing a results modal")
	check.call(bool(GameState.realm_progress().visit_active) and not GameState.expedition_active() and not realm.player.controls_locked, "post-victory exploration has explicit saved presence after loot is banked")
	check.call(bool(GameState.portal_state("sunken_crypt").unlocked) and not bool(GameState.campaign().mei_ling_rescued), "first dimension victory preserves later progression and separate final rescue")
	check.call(GameState.realm_pet_bonded("bramble_cat") and not GameState.get_pet("luma").is_empty(), "wild bonds and the distinct legacy boss reward coexist")
	check.call(RealmContentDB.CACHE in GameState.realm_progress().banked_caches and not bool(GameState.claim_realm_cache(RealmContentDB.CACHE).ok), "actual boss victory banks the hollow's pending claim without a duplicate payout")
	var stone := realm.interests.memory_road_lights as RealmInterest
	realm.player.position = stone.position + Vector2(0,1.6)
	stone.interact(realm.player)
	check.call(realm._reading_panel.visible and RealmContentDB.FRAGMENTS[0] in GameState.realm_progress().read_fragments, "memories can be read immediately after victory without reloading the restored world")
	var keeper := realm.interests.waykeeper as RealmInterest
	realm.player.position = keeper.position + Vector2(0,2)
	keeper.interact(realm.player)
	check.call(realm._reading_text.text.contains("breathing again"), "Waykeeper recognizes restoration in the same continuous visit")
	realm.close_reading()
	cat = realm.wildlife.bramble_cat
	realm.player.position = cat.position + Vector2(0,2)
	cat.interact(realm.player)
	check.call(game.hud.pet_battle_panel.visible, "friendly habitats become available immediately after boss victory")
	game.hud.pet_battle_panel.close_panel()

	game.hud._refresh_progression_notice()
	check.call(GameState.first_clear_notice_pending() and game.hud._progression_notice.visible and game.hud._progression_text.text.contains("Luma") and game.hud._progression_text.text.contains("FREE"), "actual boss victory visibly explains Luma and the free village workshop without a modal")
	check.call(not game.hud._gui_layout.has(game.hud._progression_notice), "reward reminder owns its responsive layout independently of saved touch controls")
	if capture.is_valid():
		await capture.call("06_first_clear_rewards")
		check.call(game.get_viewport_rect().encloses(game.hud._progression_notice.get_global_rect()) and game.hud._progression_notice.get_global_rect().size.y < game.get_viewport_rect().size.y * 0.46, "rendered first-clear reminder fits its content and leaves most of the world visible")
	realm.survey()
	check.call(GameState.first_clear_notice_pending() and game.hud._progression_notice.visible, "landmark hints cannot erase the durable first-clear reward reminder")
	var level_reason := GameState.portal_clear_reason("sunken_crypt")
	check.call(not bool(level_reason.ok) and str(level_reason.reason).contains("70 XP") and str(level_reason.reason).contains("Defend BESUT"), "boss-only clear explains the exact remaining player XP and a preparation route")
	var passage_labels := {}
	for child in realm.get_children():
		if child is RealmInteractable and child.kind == "passage": passage_labels[child.stable_id] = child.label.text
	check.call(str(passage_labels.get("sunken_crypt", "")).contains("70 XP") and str(passage_labels.get("drowned_throne", "")).contains("previous guardian"), "passage labels distinguish an earned level gate from a still-sealed predecessor gate")
	check.call(GameState.xp_to_level(1) == 0 and GameState.xp_to_level(4) == 220, "level preparation sums all intervening thresholds without negative XP")
	GameState.save_game()
	check.call(GameState.load_game() and bool(GameState.realm_progress().visit_active), "safe post-boss presence survives reload")
	check.call(GameState.first_clear_notice_pending(), "unread first-clear rewards survive real save/reload")
	await game._load_dungeon(RealmDB.PORTAL,false)
	await game.get_tree().process_frame
	realm = game.world as TwilightRealm
	if capture.is_valid(): realm.camera.set_physics_process(false)
	check.call(realm._boss_defeated and not is_instance_valid(realm.boss), "revisiting the restored realm does not respawn a defeated boss")
	realm.survey()
	check.call(realm._hint_label.text.contains("peaceful"), "restored landmarks describe the peaceful realm rather than a living fiend")
	if capture.is_valid():
		realm.camera.position = (RealmDB.BOSS + Vector2(0,4))
		realm.camera.force_update_scroll()
		await capture.call("04_restored")
	realm.exit_to_lobby(true)
	for frame in 100:
		if game.world is Lobby and not game._transitioning: break
		await game.get_tree().create_timer(0.03).timeout
	check.call(game.world is Lobby and not bool(GameState.realm_progress().visit_active), "return rift clears realm presence and returns to the village")
	game.hud._refresh_progression_notice()
	check.call(game.hud._progression_notice.visible and game.hud._progression_plan.visible and str(game.world.get_guidance_targets()[0].label) == "FREE WEST WORKSHOP", "return from the actual boss offers village plans and directs unread restoration guidance to the workshop")
	game.hud._progression_plan.pressed.emit()
	game.hud._refresh_progression_notice()
	check.call(game.hud.mission_panel.visible and game.player().controls_locked and not game.hud._progression_notice.visible, "village plans opens the registered journal and hides the reminder behind modal ownership")
	game.hud.mission_panel.close_panel()
	game.hud._refresh_progression_notice()
	check.call(game.hud._progression_notice.visible and not game.player().controls_locked, "closing plans restores controls and leaves the unread reminder available")
	if capture.is_valid():
		await capture.call("07_village_reward_plans")
		var display_scale := float(game.get_window().size.y) / game.get_viewport_rect().size.y
		check.call(game.hud._progression_dismiss.get_global_rect().size.y * display_scale >= 43.9, "rendered Got it action retains a 44-pixel touch target")
		var at := game.get_viewport().get_final_transform() * game.hud._progression_dismiss.get_global_rect().get_center()
		var touch := InputEventScreenTouch.new()
		touch.index = 0
		touch.position = at
		touch.pressed = true
		Input.parse_input_event(touch)
		await game.get_tree().process_frame
		touch = InputEventScreenTouch.new()
		touch.index = 0
		touch.position = at
		touch.pressed = false
		Input.parse_input_event(touch)
		await game.get_tree().process_frame
	else:
		game.hud._progression_dismiss.pressed.emit()
	GameState.save_game()
	check.call(GameState.load_game() and not GameState.first_clear_notice_pending(), "explicit Got it acknowledgement persists without recommissioning or granting rewards")
	for portal_id in PortalDB.ordered_ids(): GameState.data.portals[portal_id].cleared = true
	GameState.data.campaign.mei_ling_rescued = true
	GameState.data.house_level = HouseDB.max_level()
	check.call(not game.world.get_guidance_targets().any(func(target: Dictionary) -> bool: return str(target.label) == "WILD PETS"), "completed habitat content never leaves an unreachable old-duel objective in village guidance")
	GameState.start_expedition(RealmDB.PORTAL)
	await game._load_dungeon(RealmDB.PORTAL,false)
	await game.get_tree().process_frame
	realm = game.world as TwilightRealm
	cat = realm.wildlife.bramble_cat
	realm.player.position = cat.position + Vector2(0,2)
	cat.interact(realm.player)
	check.call(game.hud.pet_battle_panel.visible, "a peaceful cleared realm still supports friendly challenges")
	await game._load_lobby(false)
	await game.get_tree().process_frame
	check.call(not game.hud.pet_battle_panel.visible and not game.player().controls_locked and Sfx.battle_track.is_empty(), "world replacement cancels a challenge and restores controls without leaking its music")
	GameState.data.realm_progress = {"checkpoint":"invalid", "cells":["-1:2","0:0","0:0"], "landmarks":["bad"], "bonded":["missing"]}
	GameState._sanitize()
	check.call(GameState.realm_progress().checkpoint == "arrival" and GameState.realm_progress().cells == ["0:0"] and GameState.realm_progress().bonded.is_empty(), "malformed exploration records sanitize without invalid destinations or duplicate discoveries")
	game._clear_world()
	await game.get_tree().process_frame
	GameState.data = snapshot
	GameState._emit_all()
	await game._load_lobby(false)
	await game.get_tree().process_frame
	await game.get_tree().process_frame
	GameState.autosave_enabled = autosave
	game.set_process(ticking)
	await preload("res://tools/realm_combat_checks.gd").run(game,check,capture)

static func _length(points: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, points.size()): total += points[i - 1].distance_to(points[i])
	return total

static func _tap(game: Game, point: Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 17
	event.position = game.get_viewport().get_final_transform() * point
	event.pressed = true
	Input.parse_input_event(event)
	await game.get_tree().process_frame
	var release := InputEventScreenTouch.new()
	release.index = 17
	release.position = event.position
	Input.parse_input_event(release)
	await game.get_tree().process_frame
