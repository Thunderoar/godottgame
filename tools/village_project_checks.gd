class_name VillageProjectChecks
extends RefCounted

static func run(game: Game, check: Callable) -> void:
	var saved := GameState.data.duplicate(true)
	var autosave := GameState.autosave_enabled
	var ticking := game.is_processing()
	game.set_process(false)
	game.hud.hide_modals()
	game._clear_world()
	await game.get_tree().process_frame
	GameState.autosave_enabled = false
	GameState.data = GameState._make_default("adam")
	GameState._emit_all()
	await game._load_lobby(false)
	await game.get_tree().physics_frame
	await game.get_tree().physics_frame
	var home := game.world as Lobby
	var site := home.workshop
	site.set_physics_process(false)
	for child in home.get_children():
		if child is CharacterBody2D: child.set_physics_process(false)
	game.hud.tutorial_guide._skip()
	await _builder_recovery(game, check)
	var player := game.player()
	var id := VillageProjectDB.WORKSHOP
	var structure := VillageProjectDB.WORKSHOP_STRUCTURE
	check.call(site != null and home.forest_alive_count() == 64, "workshop uses an existing site without changing the 64-tree forest")
	check.call(WorldLayout.village().anchor(VillageProjectDB.WORKSHOP_ANCHOR).footprint.size.is_equal_approx(Vector2(5.2, 2.1)) and home._layout.anchor(VillageProjectDB.WORKSHOP_ANCHOR).footprint.size.is_equal_approx(Vector2(5.6, 4.3)), "future workshop space is reserved on a runtime copy without modifying source layout")
	check.call(not GameState.village_legacy_access() and not bool(GameState.project_status().eligible), "new journeys have explicit project state and a first-portal prerequisite")
	GameState.data.gold = 100000
	for item in VillageProjectDB.ADVANCED_SWORDS:
		var gold := GameState.gold()
		check.call(not bool(GameState.buy_item(item).ok) and GameState.gold() == gold and GameState.item_count(item) == 0, "%s cannot bypass the workshop purchase gate" % item)
	check.call(bool(GameState.buy_item("iron_sword").ok) and bool(GameState.upgrade_weapon("rusty_sword").ok), "basic sword purchases and upgrades remain available")
	check.call(not GameState.repair_structure(structure).ok and not GameState.start_structure_work(structure) and not GameState.work_structure(structure, 100), "ordinary repair APIs cannot build a pending project")
	check.call(not site.target.is_intact() and not GameState.buy_roof_gun(structure).ok, "pending workshop offers neither shelter nor a purchased gun")
	check.call(not GameState.start_village_project(id).ok and not GameState.start_village_project("unknown").ok, "unearned and unknown commissions are rejected")
	GameState.complete_portal("tidebound_grotto")
	check.call(bool(GameState.project_status().eligible) and str(GameState.project_status().state) == "not_started", "real portal completion reveals the durable commission without starting work")
	var balance := GameState.gold()
	var gems := GameState.diamonds()
	game._transitioning = true
	check.call(not GameState.start_village_project(id).ok, "commissioning requires a stable current Lobby")
	game._transitioning = false
	var placeable := home._placeables[0]
	check.call(not home.project_placement_allowed(placeable, site.get_parent().global_position), "placement cannot overlap the future workshop footprint")
	check.call(site.commission_blocker().is_empty(), "default site has a clear exact builder approach")
	check.call(GameState.start_village_project(id).ok and GameState.gold() == balance and GameState.diamonds() == gems, "introductory commission is free and starts once")
	check.call(not GameState.start_village_project(id).ok and float(GameState.project_status().remaining) == 10, "repeat commission cannot reset work or charge")
	player.global_position = site.workpoint() + Vector2(0, 0.4)
	check.call(site.begin_player_work(player), "player can supply real on-site fallback work")
	await game.get_tree().physics_frame
	check.call(GameState.work_village_project(id, 100, player), "a valid on-site lease accepts one physics tick of work")
	var remaining := float(GameState.project_status().remaining)
	check.call(remaining > 9.8 and not GameState.work_village_project(id, 100, player), "large deltas and duplicate submissions cannot accelerate a project")
	player.global_position += Vector2(0.3, 0)
	site._physics_process(0.02)
	check.call(site.current_worker() == null and not GameState.work_village_project(id, 1, player), "movement cancels player work and stale submissions")
	player.global_position = site.workpoint() + Vector2(0, 0.4)
	site.begin_player_work(player)
	GameState.damage_player(1)
	check.call(site.current_worker() == null, "damage interrupts work even when shield or auto-heal absorbs the visible HP change")
	site.begin_player_work(player)
	site._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check.call(site.current_worker() == null, "focus loss releases player construction ownership")
	site.begin_player_work(player)
	game.open_menu()
	site._physics_process(0.02)
	check.call(site.current_worker() == null, "opening a modal cancels player labor without pausing builders globally")
	game.hud.hide_modals()
	game._on_modal_closed()
	GameState.save_game()
	GameState.data.village_progression.projects[id].remaining = 1.0
	check.call(GameState.load_game() and is_equal_approx(float(GameState.project_status().remaining), remaining), "partial construction survives a real JSON save/reload")
	check.call(not GameState.village_legacy_access(), "a current schema reload never acquires legacy unlocks")
	var banked_work := float(GameState.project_status().remaining)
	site.begin_player_work(player)
	var retiring_player := player
	await game._load_dungeon("tidebound_grotto", false)
	check.call(not GameState.work_village_project(id, 100, retiring_player), "retiring Lobby actors cannot submit work during world replacement")
	await game.get_tree().physics_frame
	GameState.advance_world_clock(360)
	check.call(is_equal_approx(float(GameState.project_status().remaining), banked_work), "world clock and time away cannot advance physical construction")
	await game._load_lobby(false)
	home = game.world as Lobby
	site = home.workshop
	player = game.player()
	# Freeze the new crew before its first physics tick: a fresh builder may
	# legitimately claim the job immediately, which is not a revived old lease.
	site.set_physics_process(false)
	for child in home.get_children():
		if child is CharacterBody2D: child.set_physics_process(false)
	await game.get_tree().physics_frame
	await game.get_tree().physics_frame
	player.global_position = site.workpoint() + Vector2(0, 0.4)
	check.call(site.current_worker() == null and is_equal_approx(float(GameState.project_status().remaining), banked_work), "return rebuilds the project from saved work without reviving a stale lease")
	GameState.data.world_time = 180.0
	check.call(not site.begin_player_work(player) and not GameState.work_village_project(id, 1, player), "night suspends construction")
	GameState.data.world_time = 0.0
	var builder: Resident
	for resident in home._residents:
		if resident.worker_role == "builder": builder = resident
	builder._release_build_task()
	builder.global_position = site.workpoint() + Vector2(0, 3)
	builder._path_goal = Vector2(INF, INF)
	builder.set_physics_process(true)
	var walk_start := builder.global_position
	await game.get_tree().create_timer(0.4).timeout
	var walk_middle := builder.global_position
	check.call(walk_start.distance_to(walk_middle) > 0.1 and is_equal_approx(float(GameState.project_status().remaining), banked_work), "builder travels continuously before contributing on-site labor")
	await game.get_tree().create_timer(0.3).timeout
	check.call(walk_middle.distance_to(builder.global_position) > 0.1, "builder advances over consecutive physics intervals without snapping")
	builder.set_physics_process(false)
	builder._release_build_task()
	builder.global_position = site.workpoint()
	site.release_worker()
	await game.get_tree().physics_frame
	site.work_builder(builder, 0.016)
	check.call(site.current_worker() == builder and float(GameState.project_status().remaining) < remaining, "the real builder contributes through the same guarded work API")
	GameState.damage_resident(builder.resident_name, 1000)
	check.call(site.current_worker() == null and site.begin_player_work(player), "a dead builder releases the lease and player fallback remains available")
	site.release_worker()
	GameState.data.village_progression.projects[id].remaining = 0.0
	player.global_position = site.get_parent().global_position + Vector2(0, -0.5)
	check.call(not GameState.complete_village_project(id), "completion waits instead of activating collision around an actor")
	player.global_position = site.workpoint() + Vector2(0, 0.6)
	game.open_shop("equipment", "Garrick")
	for frame in 3: await game.get_tree().process_frame
	var locked_card: ItemCard
	for card in game.hud.shop_panel._cards:
		if card.item_id == "tideblade": locked_card = card
	check.call(locked_card != null and locked_card._action_button.disabled and locked_card._action_button.text.contains("locked"), "forge visibly explains locked stock before completion")
	check.call(GameState.complete_village_project(id), "clear on-site completion restores the workshop once")
	for frame in 3: await game.get_tree().process_frame
	var unlocked_card: ItemCard
	for card in game.hud.shop_panel._cards:
		if card.item_id == "tideblade": unlocked_card = card
	check.call(unlocked_card != null and not unlocked_card._action_button.disabled, "already-open forge refreshes unlocked stock")
	check.call(GameState.buy_item("tideblade").ok and site.target.is_intact(), "completed workshop unlocks an actual purchase and becomes a shelter")
	check.call(not GameState.complete_village_project(id) and not GameState.start_village_project(id).ok, "completed projects cannot repeat their completion or commission")
	GameState.damage_structure(structure, 10000)
	check.call(GameState.item_purchase_status("monarch_slayer").ok and str(GameState.project_status().state) == "complete", "damage never revokes the permanent stock license")
	check.call(GameState.repair_structure(structure).ok and site.target.is_intact(), "a completed damaged annex uses ordinary free repair")
	home.refresh_spatial_layout()
	var rami: Resident
	for resident in home._residents:
		if resident.resident_name == "Rami": rami = resident
	check.call(rami.waypoints.size() == 2 and rami.waypoints[0].distance_to(site.workpoint()) < 2, "Rami's workshop routine survives layout refresh")
	check.call(not GameState.village_npc_lines("Rami").is_empty(), "mouse/touch and normal NPC dialogue share project-aware lines")
	var map := VillageMinimap.new()
	check.call(map.map_icons(home).any(func(icon: Dictionary) -> bool: return icon.id == VillageProjectDB.WORKSHOP_ANCHOR and icon.get("project_state", "") == "complete"), "picture map exposes the completed workshop identity")
	map.free()
	GameState.save_game()
	check.call(GameState.load_game() and str(GameState.project_status().state) == "complete", "completion and licensing survive reload")
	game.hud.hide_modals()
	var legacy := GameState._make_default("adam")
	legacy.erase("village_progression")
	legacy.structures[structure] = {"health": 123, "maximum": 200, "kind": "house", "name": "Old cottage", "level": 1}
	legacy.roof_guns[structure] = true
	_write_save(legacy)
	check.call(GameState.load_game() and GameState.village_legacy_access() and GameState.item_purchase_status("monarch_slayer").ok, "legacy saves retain their entire prior stock access")
	check.call(int(GameState.structure_state(structure).health) == 123 and GameState.has_roof_gun(structure) and site.target.is_intact(), "legacy repaired cottages retain HP, shelter and bought rooftop guns")
	GameState.save_game()
	check.call(GameState.load_game() and GameState.village_legacy_access(), "legacy migration remains stable after a second load")
	var current := GameState._make_default("adam")
	current.village_progression.erase("first_clear_acknowledged")
	for ruin in ["home_damaged_house", "home_destroyed_house", "home_ruined_house"]:
		current.structures[ruin] = {"health": 123, "maximum": 200, "kind": "house", "name": ruin, "level": 1, "repair_remaining": 4.0}
		current.roof_guns[ruin] = true
	_write_save(current)
	check.call(GameState.load_game() and not GameState.village_legacy_access() and not bool(GameState.data.village_progression.first_clear_acknowledged), "existing schema-1 saves gain the notice default without a broad legacy entitlement")
	for ruin in ["home_damaged_house", "home_destroyed_house", "home_ruined_house"]:
		check.call(int(GameState.structure_state(ruin).health) == 123 and GameState.has_roof_gun(ruin) and not GameState.structure_project_locked(ruin) and float(GameState.structure_state(ruin).repair_remaining) == 4.0, "current-schema residential HP, gun and partial repair survive: " + ruin)
	GameState.data.village_progression = {"schema": 1, "legacy_access": "true", "first_clear_acknowledged": "true", "projects": {id: {"state": "working", "remaining": -100}, "unknown": {"state": "complete"}}}
	GameState._sanitize()
	check.call(not GameState.village_legacy_access() and str(GameState.project_status().state) == "not_started" and GameState.data.village_progression.projects.size() == 1, "malformed project records cannot fabricate work or legacy access")
	check.call(not bool(GameState.data.village_progression.first_clear_acknowledged), "malformed acknowledgement strings never hide unread first-clear rewards")
	var future := GameState.data.duplicate(true)
	future.village_progression.schema = 99
	_write_save(future)
	var disk := FileAccess.get_file_as_string(GameState.SAVE_PATH)
	check.call(not GameState.load_game() and FileAccess.get_file_as_string(GameState.SAVE_PATH) == disk, "unsupported future project schemas are rejected without overwriting the save")
	game._clear_world()
	await game.get_tree().process_frame
	GameState.data = saved
	GameState._emit_all()
	await game._load_lobby(false)
	GameState.autosave_enabled = autosave
	game.set_process(ticking)
	GameState.save_game()

static func _write_save(value: Dictionary) -> void:
	var file := FileAccess.open(GameState.SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(value))
	file.close()

static func _builder_recovery(game: Game, check: Callable) -> void:
	var saved := GameState.data.duplicate(true)
	var home := game.world as Lobby
	var builder: Resident
	var blocked: SettlementTarget
	var reachable: SettlementTarget
	for actor in home._residents:
		if actor.worker_role == "builder": builder = actor
	for node in game.get_tree().get_nodes_in_group("structures"):
		if node.structure_id == "home_ruined_house": blocked = node
		if node.structure_id == "home_destroyed_house": reachable = node
	var original_position := builder.position
	builder._release_build_task()
	for id in GameState.data.structures: GameState.data.structures[id].health = int(GameState.data.structures[id].maximum)
	GameState._emit_all()
	await game.get_tree().physics_frame
	await game.get_tree().physics_frame
	GameState.damage_structure(blocked.structure_id, 100000)
	GameState.damage_structure(reachable.structure_id, 100000)
	var point := builder._build_workpoint(blocked)
	var barrier := StaticBody2D.new()
	barrier.collision_layer = 1
	home.add_child(barrier)
	for rect in [Rect2(-1.3,-1.3,2.6,0.35), Rect2(-1.3,0.95,2.6,0.35), Rect2(-1.3,-1.3,0.35,2.6), Rect2(0.95,-1.3,0.35,2.6)]:
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = rect.size
		shape.shape = box
		shape.position = point + rect.get_center()
		barrier.add_child(shape)
	builder.position = point + Vector2(0,3)
	await game.get_tree().physics_frame
	await game.get_tree().physics_frame
	home.invalidate_resident_routes()
	check.call(home.resident_path(builder.position, point, false).is_empty(), "builder regression fixture encloses the exact repair workpoint")
	check.call(not home.resident_path(builder.position, builder._build_workpoint(reachable), false).is_empty(), "builder regression retains another reachable repair")
	builder._repair_buildings(0.016)
	check.call(builder._build_target == reachable and blocked.builder == null, "builder skips an unreachable nearest ruin and claims reachable work")
	check.call(float(GameState.structure_state(reachable.structure_id).get("repair_remaining", 0)) == 0, "selecting a distant reachable job supplies no remote labour")
	builder._release_build_task()
	builder._build_target = blocked
	blocked.builder = builder
	builder._path_goal = Vector2(INF,INF)
	builder._repair_buildings(0.016)
	check.call(builder._build_target == null and blocked.builder == null, "a previously owned repair releases its claim when its exact route becomes blocked")
	GameState.complete_portal(RealmDB.PORTAL)
	check.call(bool(GameState.start_village_project(VillageProjectDB.WORKSHOP).ok), "blocked ordinary repairs do not prevent a valid civic commission")
	builder._run_worker(0.016)
	check.call(home.workshop.current_worker() == builder and float(GameState.project_status().remaining) == 10, "released builder can travel to queued workshop work without supplying remote labour")
	home.workshop.release_worker(false)
	# A stale route ending short of the actual workpoint must time out as well.
	builder._build_target = reachable
	reachable.builder = builder
	var destination := builder._build_workpoint(reachable)
	builder._path_goal = destination
	builder._path_exact = true
	builder._path_revision = home.resident_routes_revision()
	builder._path = PackedVector2Array([builder.position])
	builder._path_index = 0
	builder._build_last_position = builder.position
	for step in 22: builder._repair_buildings(0.1)
	check.call(builder._build_target == null and reachable.builder == null, "a stalled short route releases the ordinary repair lease and backs off")
	barrier.queue_free()
	await game.get_tree().physics_frame
	await game.get_tree().physics_frame
	home.invalidate_resident_routes()
	builder._release_build_task()
	builder._build_retry_after[blocked.get_instance_id()] = Time.get_ticks_msec() + 30000
	GameState.data.structures[reachable.structure_id].health = int(GameState.data.structures[reachable.structure_id].maximum)
	builder.position = point + Vector2(0,3)
	builder._repair_buildings(0.016)
	check.call(builder._build_target == blocked, "geometry revision clears retry backoff and makes a newly opened repair available")
	GameState.data.world_time = 180.0
	builder._repair_buildings(0.016)
	check.call(builder._build_target == null and blocked.builder == null, "night releases the recovered ordinary repair without discarding its saved work")
	builder.position = original_position
	builder.velocity = Vector2.ZERO
	builder._build_retry_after.clear()
	builder._path_goal = Vector2(INF,INF)
	GameState.data = saved
	GameState._emit_all()
	await game.get_tree().physics_frame
	await game.get_tree().physics_frame
