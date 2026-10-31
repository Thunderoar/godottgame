class_name PortalOriginChecks
extends RefCounted
## Actual discovery -> dock conversation -> world reveal -> expedition handoff.

static func run(game: Game, check: Callable, capture: Callable = Callable()) -> void:
	var saved := GameState.data.duplicate(true)
	var autosave := GameState.autosave_enabled
	var ticking := game.is_processing()
	var settings := GameSettings._values.duplicate(true)
	var disk_before := FileAccess.get_file_as_string(GameState.SAVE_PATH) if FileAccess.file_exists(GameState.SAVE_PATH) else ""
	var save_available := GameState.has_existing_save
	game.hud.hide_modals()
	game.set_process(false)
	GameState.autosave_enabled = false
	GameState.data = GameState._make_default("adam")
	GameState.data.campaign.intro_seen = true
	GameState.data.campaign.dock_welcome_seen = true
	GameState._emit_all()
	await game._load_lobby(false)
	await game.get_tree().physics_frame
	var home := game.world as Lobby
	var site := home.get_node("OldWaystone") as PortalOriginSite
	var host := home.get_node("PakRahim") as DockHost
	game.player().set_physics_process(false)
	home.pet.set_physics_process(false)
	home.camera.set_physics_process(false)
	check.call(not GameState.portal_opened() and home.get_node_or_null("MonsterBattlePortal") == null and game.get_tree().get_nodes_in_group("battle_portal").is_empty(), "new journey has only broken stones, with no usable gate or battle-portal actor")
	check.call(not GameState.start_expedition(RealmDB.PORTAL) and not GameState.can_enter_portal("sunken_crypt"), "all expedition entry validates the unopened road, including direct API calls")
	check.call(not _icon(game,home,"monster_portal") and not _icon(game,home,"old_waystone"), "both undiscovered gate and waystone are absent from the picture map")
	var route := ResidentRoutes.new(home,home.get_map_rect()).path(home.player.position,site.position+Vector2(0,1.6),false)
	check.call(not route.is_empty(), "the old waystone has a physical route from the village spawn")
	var cue_snapshot := GameState.data.duplicate(true)
	var cue_quality := GameSettings.effects_quality()
	var cue_motion := GameSettings.reduce_motion()
	GameSettings.set_effects_quality("low",false)
	GameSettings.set_reduce_motion(true,false)
	site._process(0.1)
	var cue_position := site.glimmers[0].position
	site._process(8)
	check.call(site.glimmers[0].visible and site.glimmers[0].position == cue_position and site.ribbons.all(func(ribbon: Sprite2D) -> bool: return ribbon.rotation == 0), "low effects and Reduce Motion retain a steady socket cue and readable wayfarer ribbons")
	check.call(GameState.data == cue_snapshot, "decorative cues never discover the site, open the road or write journey progress")
	if capture.is_valid():
		home.camera.position = site.position+Vector2(0,3)
		home.camera.force_update_scroll()
		await capture.call("00_low_motion_cue")
		var cue_time := float(GameState.data.world_time)
		GameState.data.world_time = GameState.DAY_PHASE_SECONDS+30 # Quiet lighting fixture; do not stage a wave.
		home._update_daylight()
		site._process(0)
		await capture.call("00_night_cue")
		GameState.data.world_time = cue_time
		home._update_daylight()
	GameSettings.set_effects_quality(cue_quality,false)
	GameSettings.set_reduce_motion(cue_motion,false)
	check.call(not GameState.portal_key_received() and not GameState.consult_waystone() and not GameState.open_waystone(), "a fresh journey cannot skip exploration or unlock the portal")
	var main_rows := ObjectiveTrackerData.entries(home)
	check.call(main_rows[0].id == "waystone" and main_rows[0].title == "Explore the northern clearing", "the first village mission explores the missing portal's location")
	var direction := ObjectiveNavigation.target(home,"waystone")
	check.call(direction.label == "Northern Clearing" and (direction.position as Vector2).distance_to(site.global_position) < 3, "the first mission arrow points to the clearing rather than Rahim")
	check.call(home.get_guidance_targets()[0].label == direction.label, "the automatic trail also leads to exploration first")
	check.call(FieldGuideDB.entries(0)[0].name == "Pak Rahim · Portal Key" and FieldGuideDB.description(FieldGuideDB.entries(3)[4]).contains("Explore the northern clearing"), "Field Guide explains exploration before the key")
	game.hud.track_objective("waystone")
	game.hud._update_mission_guide()
	if capture.is_valid(): await capture.call("01_explore_mission")
	game.player().position = host.position+Vector2(0,1)
	game.play_dock_conversation()
	check.call(is_instance_valid(game._dock_conversation) and not game._dock_conversation.waystone, "speaking to Rahim before discovery only offers his normal reminder")
	if is_instance_valid(game._dock_conversation): game._dock_conversation.finish()
	check.call(not GameState.portal_key_received(), "an early dock chat cannot bypass exploration")
	site.interact(game.player())
	check.call(not bool(GameState.portal_origin().site_examined), "remote portal interaction cannot advance discovery")
	game.player().position = site.position+Vector2(0,1.6)
	home.camera.position = site.position+Vector2(0,-1)
	home.camera.force_update_scroll()
	home.camera.reset_physics_interpolation()
	Input.action_press("sprint")
	site._process(0)
	await game.get_tree().create_timer(0.3).timeout
	var discovery := game.hud.dialogue_panel
	check.call(bool(GameState.portal_origin().site_examined) and not GameState.portal_opened() and not GameState.portal_key_received(), "arriving discovers remains, without creating a portal or key")
	check.call(discovery.visible and discovery._lines.any(func(line: String) -> bool: return line.contains("Find Pak Rahim at the dock")), "arrival opens a persistent readable clue naming Pak Rahim")
	check.call(discovery.z_index > game.hud.tutorial_guide.z_index, "the clue draws above tutorial cards regardless of sibling ordering")
	check.call(not game.hud._navigation_box.visible and not Input.is_action_pressed("sprint"), "the clue hides navigation and releases held controls")
	check.call(Rect2(Vector2.ZERO,game.get_viewport_rect().size).encloses(discovery.panel.get_global_rect()), "the clue panel stays entirely inside the viewport")
	check.call(not discovery.body.get_v_scroll_bar().visible and not discovery.body.get_h_scroll_bar().visible, "all discovery text fits without scrolling or concealed lines")
	if capture.is_valid(): await capture.call("01_discovery_clue")
	discovery.close_panel()
	game.hud._update_mission_guide()
	direction = ObjectiveNavigation.target(home,"waystone")
	check.call(direction.label == "Pak Rahim · Portal Key" and GameState.portal_origin_title() == "Meet Pak Rahim" and game.hud._tracked_target.label == direction.label, "discovery redirects both the mission and its selected live arrow to Rahim")
	GameState.save_game()
	check.call(GameState.load_game() and bool(GameState.portal_origin().site_examined) and not GameState.portal_key_received(), "the discovered clue and Rahim objective survive Continue")
	if capture.is_valid(): await _guide_capture(game,3,4,capture,"01_field_guide_rahim")
	game.player().position = host.position+Vector2(0,1)
	home.camera.position = host.position+Vector2(0,-1)
	home.camera.force_update_scroll()
	await game.get_tree().physics_frame
	game.play_dock_conversation()
	var dialogue := game._dock_conversation
	if not is_instance_valid(dialogue):
		check.call(false,"key conversation was created")
		return
	dialogue.set_process(false)
	dialogue.reveal_line()
	check.call(dialogue.waystone and dialogue.entries().size() == 5 and not game._story_active and home.process_mode != Node.PROCESS_MODE_DISABLED, "Rahim continues the portal story after discovery without pausing simulation")
	var clock := float(GameState.data.world_time)
	game._process(0.25)
	check.call(float(GameState.data.world_time) > clock and not GameState.portal_key_received(), "the key conversation runs the world and grants nothing before completion")
	if capture.is_valid():
		dialogue.page = 3
		dialogue._render()
		dialogue.reveal_line()
		await capture.call("02_rahim_key")
	dialogue.cancel()
	check.call(not GameState.portal_key_received(), "cancelling Rahim's conversation cannot grant the key")
	game.play_dock_conversation()
	dialogue = game._dock_conversation
	for page in DockConversation.WAYSTONE.size():
		dialogue.reveal_line()
		dialogue.advance()
	check.call(GameState.portal_key_received() and not GameState.portal_opened(), "finishing Rahim's conversation grants the key for the return to the clearing")
	check.call(not GameState.consult_waystone(), "the permanent key cannot be awarded twice")
	GameState.save_game()
	check.call(GameState.load_game() and GameState.portal_key_received() and not GameState.portal_opened(), "the earned key survives Continue")
	check.call(_icon(game,home,"old_waystone") and not _icon(game,home,"monster_portal"), "the discovered site is mapped while the actual portal remains absent")
	game.hud._update_mission_guide()
	check.call(game.hud._tracked_target.label == "Unlock the Portal" and GameState.portal_origin_title() == "Unlock the Dimension Portal", "the selected mission redirects to the clearing after Rahim gives the key")
	if capture.is_valid(): await _guide_capture(game,3,4,capture,"02_field_guide_key_received")
	game.player().position = site.position+Vector2(0,1.6)
	site.refresh()
	home.camera.position = site.position+Vector2(0,-1)
	home.camera.force_update_scroll()
	await game.get_tree().physics_frame
	if capture.is_valid(): await capture.call("03_key_ready_portal")
	var enemy := Enemy.new()
	enemy.kind = "urchin"
	enemy.position = site.position+Vector2(2,1)
	home.add_child(enemy)
	enemy.set_physics_process(false)
	check.call(not game.awaken_portal(site) and site.caption.text.contains("nearby") and not GameState.portal_opened(), "nearby real danger blocks the reveal with persistent local feedback")
	enemy.position = Vector2(10,25)
	var before_gold := GameState.gold()
	var before_diamonds := GameState.diamonds()
	var before_xp := int(GameState.data.xp)
	var before_inventory: Dictionary = GameState.data.inventory.duplicate(true)
	Input.action_press("attack")
	Input.action_press("sprint")
	site.interact(game.player())
	var reveal := game._portal_awakening
	check.call(is_instance_valid(reveal) and GameState.portal_opened() and not GameState.expedition_active(), "the prepared nearby action opens the road in daylight with no kill quota or automatic travel")
	if not is_instance_valid(reveal): return
	reveal.set_process(false)
	check.call(game._story_active and home.process_mode == Node.PROCESS_MODE_DISABLED and game.player().controls_locked and not Input.is_action_pressed("attack") and not Input.is_action_pressed("sprint"), "reveal owns world suspension, player locks and held-action cleanup")
	clock = float(GameState.data.world_time)
	game._process(30)
	check.call(float(GameState.data.world_time) == clock and GameState.gold() == before_gold and GameState.diamonds() == before_diamonds and int(GameState.data.xp) == before_xp and GameState.data.inventory == before_inventory, "the opening freezes the shared clock and costs or rewards no currency, items or XP")
	GameState.save_game()
	var committed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GameState.SAVE_PATH))
	check.call(bool(committed.portal_origin.opened) and not bool(committed.portal_origin.reveal_seen), "the road is saved before the reveal completes, independently of its seen flag")
	var stone_start := site.stone.rotation
	reveal.sample(0.7)
	var halfway := site.stone.rotation
	reveal.sample(1.4)
	check.call(halfway > stone_start and site.stone.rotation > halfway, "consecutive reveal samples physically align the fallen marker before the answering light")
	reveal.sample(2.5)
	if capture.is_valid(): await capture.call("03_lantern")
	reveal.sample(4.0)
	check.call(reveal._road.modulate.a > 0 and reveal._frame.modulate.a == 0, "a glimpse of the distant road answers before the arch appears")
	if capture.is_valid(): await capture.call("04_answer")
	reveal.sample(6.0)
	if capture.is_valid(): await capture.call("05_arch")
	GameSettings.set_value("reduce_motion",true,false)
	reveal.sample(5.5)
	check.call(site.stone.rotation == 0 and reveal._frame.modulate.a == 1, "live Reduce Motion switches to readable completed tableaux")
	GameSettings.set_value("reduce_motion",false,false)
	if capture.is_valid(): await _tap_ui(game,reveal._skip.get_global_rect().get_center())
	else: reveal.finish()
	check.call(not game._story_active and not game.player().controls_locked and home.process_mode != Node.PROCESS_MODE_DISABLED and bool(GameState.portal_origin().reveal_seen), "Skip/completion saves the reveal and restores world, HUD and controls")
	check.call(home.get_node("MonsterBattlePortal").visible and _icon(game,home,"monster_portal"), "the completed reveal leaves one visible portal and publishes its map picture")
	check.call(site.glimmers.all(func(glimmer: Sprite2D) -> bool: return not glimmer.visible), "the discovery glimmer retires when the portal opens, leaving the decorated road peaceful")
	if capture.is_valid(): await capture.call("06_open_road")
	enemy.queue_free()
	GameState.save_game()
	check.call(GameState.load_game() and GameState.portal_opened() and bool(GameState.portal_origin().reveal_seen), "the opened road and completed reveal survive an actual file reload")
	game.player().position = site.position+Vector2(0,1.6)
	home.get_node("MonsterBattlePortal").interact(game.player())
	for frame in 180:
		if game.world is TwilightRealm and not game._transitioning: break
		await game.get_tree().create_timer(0.03).timeout
	check.call(game.world is TwilightRealm and GameState.expedition_active(), "the newly formed portal uses the existing real entry transition into Twilight Wilds")
	if game.world is TwilightRealm:
		var realm := game.world as TwilightRealm
		realm.player.set_physics_process(false)
		realm.player.position = realm.interests.waykeeper.position+Vector2(0,1)
		realm.interests.waykeeper.interact(realm.player)
		check.call(realm._reading_text.text.contains("village lantern"), "Wisp recognizes the light that reopened his road on the first visit")
		GameState.leave_portal_safely()
		GameState.end_realm_visit()
	await game._load_lobby(false)
	await game.get_tree().physics_frame
	home = game.world as Lobby
	site = home.get_node("OldWaystone") as PortalOriginSite
	GameState.data.portal_origin.reveal_seen = false # Model a crash after the opening commit.
	game.player().set_physics_process(false)
	game.player().position = site.position+Vector2(0,1.6)
	site.refresh()
	check.call(game.awaken_portal(site,true), "an interrupted reveal offers a nearby optional replay without closing the usable gate")
	await game._load_lobby(false)
	await game.get_tree().process_frame
	check.call(not is_instance_valid(game._portal_awakening) and not game._story_active and not game.player().controls_locked and not bool(GameState.portal_origin().reveal_seen), "world replacement cancels the owned reveal without marking it seen or locking the replacement player")
	await _migration(game,check)
	game._clear_world()
	await game.get_tree().process_frame
	GameState.data = saved
	GameState._emit_all()
	GameSettings._values = settings
	GameSettings.changed.emit("reduce_motion")
	await game._load_lobby(false)
	GameState.autosave_enabled = autosave
	await game.get_tree().physics_frame
	await game.get_tree().physics_frame
	if disk_before.is_empty(): GameState.delete_save()
	else:
		var file := FileAccess.open(GameState.SAVE_PATH,FileAccess.WRITE)
		file.store_string(disk_before)
		file.close()
	GameState.has_existing_save = save_available
	game.set_process(ticking)

static func _migration(game: Game, check: Callable) -> void:
	var old := GameState._make_default("adam")
	old.erase("portal_origin")
	_write(old)
	check.call(GameState.load_game() and GameState.portal_opened() and bool(GameState.portal_origin().reveal_seen), "old saves lacking origin fields retain their existing portal access without a forced reveal")
	var key_only := GameState._make_default("adam")
	key_only.portal_origin.rahim_consulted = true
	_write(key_only)
	check.call(GameState.load_game() and GameState.portal_key_received() and not bool(GameState.portal_origin().site_examined) and not GameState.portal_opened(), "a key-only checkpoint loads without requiring or fabricating a stone visit")
	var old_lantern := GameState._make_default("adam")
	old_lantern.portal_origin.site_examined = true
	old_lantern.portal_origin.rahim_consulted = true
	_write(old_lantern)
	check.call(GameState.load_game() and GameState.portal_key_received() and not GameState.portal_opened(), "old completed lantern conversations retain their earned portal access as the key")
	var interrupted := GameState._make_default("adam")
	interrupted.portal_origin.opened = true
	_write(interrupted)
	check.call(GameState.load_game() and GameState.portal_opened() and not bool(GameState.portal_origin().reveal_seen), "interrupted reveal reload retains an open usable road with optional replay")
	var inconsistent := GameState._make_default("adam")
	inconsistent.realm_progress.visit_active = true
	_write(inconsistent)
	check.call(GameState.load_game() and GameState.portal_opened(), "saved realm presence repairs contradictory origin flags")
	var future := GameState._make_default("adam")
	future.portal_origin.schema = 99
	_write(future)
	var before := FileAccess.get_file_as_string(GameState.SAVE_PATH)
	check.call(not GameState.load_game() and FileAccess.get_file_as_string(GameState.SAVE_PATH) == before, "future origin schemas are rejected without overwriting the save")
	GameState.data = GameState._make_default("adam")
	GameState.data.portal_origin = {"opened":"false","site_examined":[],"rahim_consulted":true}
	GameState._sanitize()
	check.call(not GameState.portal_opened() and not bool(GameState.portal_origin().rahim_consulted), "malformed values cannot fabricate an open gate or an unearned key")

static func _write(data: Dictionary) -> void:
	var file := FileAccess.open(GameState.SAVE_PATH,FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

static func _guide_capture(game: Game, category: int, page: int, capture: Callable, name: String) -> void:
	game.hud.field_guide_panel._category = category
	game.hud.field_guide_panel._page = page
	game.open_field_guide()
	await game.get_tree().create_timer(0.25).timeout
	await capture.call(name)
	game.hud.field_guide_panel.close_panel()

static func _icon(game: Game, home: Lobby, id: String) -> bool:
	return game.hud._minimap.map_icons(home).any(func(icon: Dictionary) -> bool: return icon.id == id)

static func _tap_world(game: Game, at: Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 37
	event.position = game.player().get_canvas_transform()*at
	if DisplayServer.get_name() != "headless": event.position = game.get_viewport().get_final_transform()*event.position
	event.pressed = true
	if DisplayServer.get_name() == "headless":
		# The native capture route verifies full viewport routing. A headless
		# display has no physical window transform; exercise the same touch handler.
		(game.world.get_node("OldWaystone") as PortalOriginSite)._unhandled_input(event)
		await game.get_tree().process_frame
		return
	Input.parse_input_event(event)
	await game.get_tree().process_frame
	var release := InputEventScreenTouch.new()
	release.index = 37
	release.position = event.position
	Input.parse_input_event(release)
	await game.get_tree().process_frame

static func _tap_ui(game: Game, at: Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 38
	event.position = game.get_viewport().get_final_transform()*at
	event.pressed = true
	Input.parse_input_event(event)
	await game.get_tree().process_frame
	var release := InputEventScreenTouch.new()
	release.index = 38
	release.position = event.position
	Input.parse_input_event(release)
	await game.get_tree().process_frame
