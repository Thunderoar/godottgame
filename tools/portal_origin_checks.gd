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
	game.play_dock_conversation()
	check.call(is_instance_valid(game._dock_conversation) and not game._dock_conversation.waystone, "Rahim gives ordinary reminders before discovering the stone")
	game._dock_conversation.finish()
	site.interact(game.player())
	check.call(not bool(GameState.portal_origin().site_examined), "remote examination cannot advance the discovery")
	game.player().position = site.position+Vector2(0,1.6)
	home.camera.position = site.position+Vector2(0,-1)
	home.camera.force_update_scroll()
	home.camera.reset_physics_interpolation()
	await game.get_tree().physics_frame
	await game.get_tree().physics_frame
	await game.get_tree().process_frame
	if capture.is_valid(): await capture.call("01_broken_stones")
	await _tap_world(game,site.global_position+Vector2(0,-0.5))
	check.call(bool(GameState.portal_origin().site_examined) and not GameState.portal_opened() and not GameState.expedition_active(), "actual nearby screen tap examines the broken line without entering or opening a gate")
	check.call(_icon(game,home,"old_waystone") and not _icon(game,home,"monster_portal"), "discovery reveals a waystone picture rather than a usable portal")
	game.player()._update_nearby()
	game.player().try_interact()
	check.call(site.caption.text.contains("line breaks") and not game.player().controls_locked, "nearby E interaction rereads the discovery without pausing or locking movement")
	check.call(not GameState.open_waystone() and not GameState.portal_opened(), "repair requires Rahim's conversation after examining the site")
	GameState.save_game()
	check.call(GameState.load_game() and bool(GameState.portal_origin().site_examined) and not bool(GameState.portal_origin().rahim_consulted), "save/load keeps examined-but-unexplained discovery distinct")
	game.player().position = host.position+Vector2(0,1)
	home.camera.position = host.position+Vector2(0,-1)
	home.camera.force_update_scroll()
	home.camera.reset_physics_interpolation()
	await game.get_tree().physics_frame
	game.play_dock_conversation()
	var dialogue := game._dock_conversation
	if not is_instance_valid(dialogue):
		check.call(false,"contextual dialogue was created")
		return
	dialogue.set_process(false)
	dialogue.reveal_line()
	check.call(dialogue.waystone and dialogue.entries().size() == 5 and not game._story_active and home.process_mode != Node.PROCESS_MODE_DISABLED, "discovery selects the five-line Rahim exchange without pausing village simulation")
	var clock := float(GameState.data.world_time)
	game._process(0.25)
	check.call(float(GameState.data.world_time) > clock and not bool(GameState.portal_origin().rahim_consulted), "later chat keeps the world clock running and grants the lantern only on completion")
	if capture.is_valid(): await capture.call("02_rahim")
	dialogue.cancel()
	check.call(not bool(GameState.portal_origin().rahim_consulted), "cancelled contextual conversation cannot grant the lantern")
	game.play_dock_conversation()
	dialogue = game._dock_conversation
	for page in DockConversation.WAYSTONE.size():
		dialogue.reveal_line()
		dialogue.advance()
	check.call(bool(GameState.portal_origin().rahim_consulted) and not GameState.portal_opened(), "completing or explicitly skipping Rahim's exchange prepares the free repair")
	GameState.save_game()
	check.call(GameState.load_game() and bool(GameState.portal_origin().rahim_consulted) and not GameState.portal_opened(), "the lantern conversation survives Continue without prematurely opening the road")
	game.player().position = site.position+Vector2(0,1.6)
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
	check.call(not GameState.portal_opened() and not bool(GameState.portal_origin().rahim_consulted), "malformed values cannot fabricate an open gate or an unearned lantern")

static func _write(data: Dictionary) -> void:
	var file := FileAccess.open(GameState.SAVE_PATH,FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

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
