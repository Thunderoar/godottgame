class_name Game
extends Node2D
## Top-level flow controller: title -> character select -> lobby <-> dungeon.
## Systems own their own data; Game only coordinates scene lifetimes and the
## handful of cross-world actions.

var hud: GameHUD
var world: Node2D
var title_screen: TitleScreen
var _title_layer: CanvasLayer
var _world_holder: Node2D
var _input_locked := false
var _defeat_pending := false
var _transitioning := false
var _portal_elapsed := 0.0
var _emergency_triggered := false
var _settlement_damage_accum := 0.0
var _game_over := false
var home_interior: HomeInterior
var _outdoor_position := Vector2.ZERO
var loading_screen: LoadingScreen
var _sailing := false
var _return_to_harbour := false
var _story_active := false
var _side_quest_intro: Dictionary = {}
var _side_quest_timer := 0.0
var _side_quest_auto_enabled := true # Fixtures can isolate unrelated gameplay paths.
var _dock_conversation: DockConversation
var _portal_awakening: PortalAwakening
var _portal_world_mode := Node.PROCESS_MODE_INHERIT
var _portal_hud_visible := true
var _urchin_arrival: UrchinArrival
var _urchin_world_mode := Node.PROCESS_MODE_INHERIT
var _urchin_hud_visible := true
var _arjun_returning := false
var _arjun_walk: Tween

const EMERGENCY_DELAY := 14.0
const SETTLEMENT_DAMAGE_TICK := 5.0


func _ready() -> void:
	add_to_group("game")
	var diagnostics := preload("res://scripts/core/runtime_diagnostics.gd").new()
	diagnostics.name = "RuntimeDiagnostics"
	add_child(diagnostics)
	_world_holder = Node2D.new()
	_world_holder.name = "WorldHolder"
	add_child(_world_holder)
	hud = GameHUD.new()
	hud.name = "HUD"
	add_child(hud)
	hud.visible = false
	loading_screen = LoadingScreen.new()
	add_child(loading_screen)
	add_child(NpcInfo.new())
	_connect_hud()
	GameState.player_defeated.connect(_on_player_defeated)
	GameState.game_over_triggered.connect(_on_game_over)
	_show_title()


func _process(delta: float) -> void:
	_side_quest_timer += delta
	if _side_quest_auto_enabled and _side_quest_timer >= 0.3:
		_side_quest_timer = 0.0
		_try_side_quest_introduction()
	if is_instance_valid(world) and not _game_over and not _story_active and not hud.pet_battle_panel.is_wild_challenge():
		GameState.advance_world_clock(delta)
	if world is Dungeon and not world is TwilightRealm and GameState.expedition_active():
		if not _emergency_triggered:
			_portal_elapsed += delta
			if _portal_elapsed >= EMERGENCY_DELAY and GameState.is_night():
				_emergency_triggered = true
				GameState.start_emergency(3)
		if GameState.emergency_active():
			_settlement_damage_accum += delta
			if _settlement_damage_accum >= SETTLEMENT_DAMAGE_TICK:
				_settlement_damage_accum = 0.0
				GameState.damage_settlement(5)


func _connect_hud() -> void:
	hud.map_panel.closed.connect(_on_modal_closed)
	hud.field_guide_panel.closed.connect(_on_modal_closed)
	hud.mission_panel.closed.connect(_on_modal_closed)
	hud.village_services_panel.closed.connect(_on_modal_closed)
	hud.shop_panel.closed.connect(_on_modal_closed)
	hud.inventory_panel.closed.connect(_on_modal_closed)
	hud.portal_panel.closed.connect(_on_modal_closed)
	hud.pet_battle_panel.closed.connect(_on_modal_closed)
	hud.sea_cleaning_panel.closed.connect(_on_modal_closed)
	hud.house_panel.closed.connect(_on_modal_closed)
	hud.victory_panel.closed.connect(_on_modal_closed)
	hud.defeat_panel.closed.connect(_on_modal_closed)
	hud.menu_panel.closed.connect(_on_modal_closed)
	hud.settings_panel.closed.connect(_on_modal_closed)
	hud.dialogue_panel.closed.connect(_on_modal_closed)
	hud.inventory_requested.connect(open_inventory)
	hud.build_mode_requested.connect(toggle_build_mode)
	hud.menu_requested.connect(open_menu)


func _show_title() -> void:
	_title_layer = CanvasLayer.new()
	_title_layer.name = "TitleLayer"
	_title_layer.layer = 200
	add_child(_title_layer)
	title_screen = TitleScreen.new()
	title_screen.save_available = GameState.has_existing_save
	title_screen.character_selected.connect(_on_character_selected)
	title_screen.continue_requested.connect(_on_continue_requested)
	_title_layer.add_child(title_screen)


func _on_character_selected(_character_id: String) -> void:
	if _transitioning or _story_active:
		return
	GameState.autosave_enabled = true
	GameState.new_game("adam")
	hud.visible = true
	_game_over = false
	await play_story("intro", true)
	await _load_lobby(true, true)
	var arrival_world := world
	var arrival_serial := GameState.journey_serial
	await play_dock_conversation(true)
	if world != arrival_world or not is_instance_valid(arrival_world) or arrival_serial != GameState.journey_serial or not bool(GameState.campaign().get("dock_welcome_seen", false)): return
	hud.start_tutorial()


func _on_continue_requested() -> void:
	if _transitioning or _story_active:
		return
	if not GameState.continue_game():
		if is_instance_valid(title_screen):
			title_screen.show_continue_error()
		return
	var first_arrival := not bool(GameState.campaign().get("intro_seen", false))
	var dock_pending := not bool(GameState.campaign().get("dock_welcome_seen", true))
	if first_arrival:
		await play_story("intro", true)
	else:
		_remove_title()
	hud.visible = true
	if bool(GameState.realm_progress().visit_active):
		await _load_dungeon(RealmDB.PORTAL, true)
	elif GameState.expedition_active():
		var portal_id := GameState.expedition_portal()
		await _load_dungeon(portal_id, true)
	else:
		await _load_lobby(true, first_arrival or dock_pending)
		if first_arrival or dock_pending:
			var arrival_world := world
			var arrival_serial := GameState.journey_serial
			await play_dock_conversation(true)
			if world != arrival_world or not is_instance_valid(arrival_world) or arrival_serial != GameState.journey_serial or not bool(GameState.campaign().get("dock_welcome_seen", false)): return
	if GameState.completed_mission_count() < MissionDB.STEPS.size():
		hud.start_tutorial()


func _remove_title() -> void:
	if title_screen and is_instance_valid(title_screen):
		title_screen.queue_free()
	if _title_layer and is_instance_valid(_title_layer):
		_title_layer.queue_free()
	title_screen = null
	_title_layer = null


func _remove_title_if_owner(expected: CanvasLayer) -> void:
	if _title_layer == expected:
		_remove_title()


# ------------------------------------------------------------------ world switching

func _clear_world() -> void:
	if not _side_quest_intro.is_empty():
		_side_quest_intro.cancelled = true
		hud.dialogue_panel.close_panel()
	if is_instance_valid(_portal_awakening): _portal_awakening.cancel()
	if is_instance_valid(_urchin_arrival): _urchin_arrival.cancel()
	if is_instance_valid(_dock_conversation): _dock_conversation.cancel()
	if hud.pet_battle_panel.is_wild_challenge(): hud.pet_battle_panel.close_panel()
	hud.release_world_controls()
	if _arjun_walk and _arjun_walk.is_valid(): _arjun_walk.kill()
	if world is Lobby: _arjun_returning = false
	_portal_elapsed = 0.0
	_emergency_triggered = false
	_settlement_damage_accum = 0.0
	_sailing = false
	Sfx.stop_battle_music()
	home_interior = null
	if is_instance_valid(world) and world is Lobby and world.journey_serial == GameState.journey_serial:
		GameState.store_home_monsters(world.capture_monsters())
	if world and is_instance_valid(world):
		world.queue_free()
	world = null
	hud.set_world(null)


func _load_lobby(transition: bool = true, arrive_at_dock: bool = false) -> void:
	if _transitioning:
		return
	_transitioning = true
	_input_locked = true
	_apply_input_lock()
	if transition:
		await loading_screen.begin("Besut Village · Dock" if arrive_at_dock else "Besut Village")
	_clear_world()
	hud.set_build_mode(false)
	var lobby := Lobby.new()
	lobby.name = "Lobby"
	lobby.arrive_at_dock = arrive_at_dock
	world = lobby
	_world_holder.add_child(lobby)
	hud.set_world(lobby)
	hud.visible = true
	if _return_to_harbour:
		_sailing = true
		hud.visible = false
		lobby.pet.visible = false
		lobby.ship_boarding.begin_return(lobby.player)
		lobby.camera.global_position = lobby.player.global_position
		lobby.camera.reset_physics_interpolation()
		_return_to_harbour = false
	_restore_player_visual()
	_apply_input_lock()
	hud.set_sleep_state(false, 0.0, "")
	if GameState.health() <= 0:
		GameState.set_health(GameState.health_max())
	if transition:
		await loading_screen.finish()
	_transitioning = false
	_input_locked = hud.any_modal_open() or _sailing
	_apply_input_lock()
	call_deferred("_check_campaign_ending")


func _load_dungeon(portal_id: String, transition: bool = true) -> void:
	if _transitioning:
		return
	_transitioning = true
	_input_locked = true
	_apply_input_lock()
	if transition:
		await loading_screen.begin("Twilight Wilds" if portal_id == RealmDB.PORTAL else str(PortalDB.get_portal(portal_id).get("name", "Portal")))
	_clear_world()
	hud.set_build_mode(false)
	var dungeon: Dungeon = TwilightRealm.new() if portal_id == RealmDB.PORTAL else Dungeon.new()
	dungeon.setup(portal_id)
	dungeon.name = "Dungeon"
	world = dungeon
	_world_holder.add_child(dungeon)
	hud.set_world(dungeon)
	_restore_player_visual()
	_apply_input_lock()
	hud.set_sleep_state(false, 0.0, "")
	if transition:
		await loading_screen.finish()
	_transitioning = false
	_input_locked = hud.any_modal_open()
	_apply_input_lock()

func _restore_player_visual() -> void:
	# Undo any pull-in shrink from the portal transition.
	var p := player()
	if p != null:
		var visual: CanvasItem = p.get_node_or_null("Sprite")
		if visual != null:
			visual.scale = Vector2(PixelArt.PX, PixelArt.PX)
			visual.rotation = 0.0
			visual.modulate.a = 1.0


var _portal_fx_active := false


func enter_portal(portal_id: String) -> void:
	if _transitioning or _portal_fx_active or _input_locked or _defeat_pending or _game_over or _sailing or is_instance_valid(home_interior) or hud.any_modal_open():
		return
	if not world is Lobby and not world is TwilightRealm:
		return
	var reason := GameState.portal_clear_reason(portal_id)
	if not bool(reason.ok):
		GameState.toast_requested.emit(str(reason.reason), "bad")
		return
	if world is TwilightRealm:
		GameState.leave_portal_safely()
	if not GameState.start_expedition(portal_id):
		return
	if portal_id == PortalDB.ordered_ids()[0]:
		GameState.record_mission_event("portal")
	_defeat_pending = false
	_portal_elapsed = 0.0
	_emergency_triggered = false
	_settlement_damage_accum = 0.0
	_portal_entry_transition(portal_id)


func _portal_entry_transition(portal_id: String) -> void:
	# The player is pulled into the gate, the screen flashes, then the normal
	# _load_dungeon flow takes over (guards and all). Direct _load_dungeon
	# callers (tests, continue) skip this effect entirely.
	if _portal_fx_active or _transitioning:
		_load_dungeon(portal_id, true)
		return
	_portal_fx_active = true
	var expected_world := world
	var expected_journey := GameState.journey_serial
	_input_locked = true
	_apply_input_lock()
	Sfx.play("portal_in", -6.0)
	var p := player()
	if p != null and not GameSettings.reduce_motion():
		var visual: CanvasItem = p.get_node_or_null("Sprite")
		if visual != null:
			var tween := visual.create_tween().set_parallel(true)
			tween.tween_property(visual, "scale", Vector2(PixelArt.PX * 0.15, PixelArt.PX * 0.15), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.tween_property(visual, "rotation", 4.5, 0.3)
			tween.tween_property(visual, "modulate:a", 0.1, 0.3)
	await get_tree().create_timer(0.28).timeout
	_portal_fx_active = false
	if world != expected_world or GameState.journey_serial != expected_journey or _game_over or _defeat_pending: return
	_load_dungeon(portal_id, true)


func _nearest_gate_center(from: Vector2) -> Vector2:
	# Drift slightly toward the paired gates so the pull reads as "into them".
	if world is Lobby:
		return (world as Lobby)._layout.position_of("monster_portal")
	return from


func return_to_lobby(from_defeat: bool = false) -> void:
	if world is TwilightRealm:
		GameState.end_realm_visit()
	hud.hide_modals()
	_defeat_pending = false
	_portal_elapsed = 0.0
	_emergency_triggered = false
	_settlement_damage_accum = 0.0
	GameState.boss_health_changed.emit(false, "", 0, 0)
	if from_defeat:
		GameState.set_health(GameState.health())  # already set by defeat_in_portal
	_load_lobby(true)


func handle_portal_defeat() -> void:
	if _defeat_pending:
		return
	_defeat_pending = true
	var defeated_world := world
	if player() != null:
		player().controls_locked = true
		player().die()
	var portal_id := GameState.expedition_portal()
	var lost := GameState.expedition_loot_summary()
	var portal_name := str(PortalDB.get_portal(portal_id).get("name", "the portal"))
	var companion := PetDB.name_of(GameState.active_pet_id())
	GameState.boss_health_changed.emit(false, "", 0, 0)
	GameState.defeat_in_portal()
	await get_tree().create_timer(0.7).timeout
	if world != defeated_world or _game_over: return
	hud.defeat_panel.show_defeat(portal_name, lost.replace("Unbanked: ", ""), companion)


func _on_player_defeated() -> void:
	if world is Dungeon:
		handle_portal_defeat()
	elif world is Lobby:
		handle_home_defeat()
	elif world is KrakenIsland:
		_handle_island_defeat()


func handle_home_defeat() -> void:
	if _defeat_pending or _game_over:
		return
	_defeat_pending = true
	var home := world
	_input_locked = true
	_apply_input_lock()
	# Let Player.take_damage finish its collapse before rebuilding the ward.
	await get_tree().create_timer(0.7).timeout
	while _transitioning and world == home and not _game_over:
		await get_tree().process_frame
	if world != home or _game_over:
		_defeat_pending = false
		return
	hud.hide_modals()
	GameState.defeat_at_home()
	await _load_lobby(true)
	_defeat_pending = false


func show_victory(summary: Dictionary, portal_id: String) -> void:
	if portal_id == PortalDB.MEI_LING_PORTAL and str(summary.get("rescued_friend", "")) == "mei_ling":
		if not world is Dungeon or world.portal_id != portal_id or not bool(GameState.campaign().get("mei_ling_rescued", false)): return
		await _rescue_mei_ling()
		return
	hud.victory_panel.show_victory(summary, portal_id)


func _on_modal_closed() -> void:
	if hud.any_modal_open() or _transitioning or _sailing or _story_active or is_instance_valid(_dock_conversation) or world is OceanJourney:
		return
	_input_locked = false
	_apply_input_lock()


func _apply_input_lock() -> void:
	var p := player()
	if p != null:
		p.controls_locked = _input_locked or p.dead or _sailing or world is OceanJourney


# ------------------------------------------------------------------ HUD API

func open_shop(kind: String, keeper: String) -> void:
	if world is Dungeon:
		return
	_input_locked = true
	_apply_input_lock()
	hud.shop_panel.open_shop(kind, keeper)


func open_house() -> void:
	if world is Dungeon:
		return
	GameState.record_mission_event("house")
	_input_locked = true
	_apply_input_lock()
	hud.house_panel.open_house()


func open_portals(focus_id: String = "tidebound_grotto") -> void:
	if world is Dungeon:
		return
	_input_locked = true
	_apply_input_lock()
	hud.portal_panel.open_portals(focus_id)


func open_pet_battles() -> void:
	if world is Dungeon:
		return
	_input_locked = true
	_apply_input_lock()
	hud.pet_battle_panel.open_pet_battles()


func open_sea_cleaning() -> void:
	if world is Dungeon:
		return
	_input_locked = true
	_apply_input_lock()
	hud.sea_cleaning_panel.open_sea_cleaning()


func open_menu() -> void:
	if _game_over or world == null:
		return
	_input_locked = true
	_apply_input_lock()
	hud.menu_panel.open_menu()


func open_village_services(repairs: bool = false) -> void:
	if not world is Lobby or _game_over:
		return
	_input_locked = true
	_apply_input_lock()
	hud.village_services_panel.open_services(repairs)


func open_settings() -> void:
	if _game_over:
		return
	_input_locked = true
	_apply_input_lock()
	hud.settings_panel.open_settings()


func open_dialogue(speaker: String, lines: Array) -> void:
	if world is Dungeon or _game_over:
		return
	_input_locked = true
	_apply_input_lock()
	hud.dialogue_panel.open_dialogue(speaker, lines)


func _on_game_over(reason: String) -> void:
	if _game_over:
		return
	_game_over = true
	_input_locked = true
	GameState.autosave_enabled = false
	GameState.delete_save()
	GameState.has_existing_save = false
	var p := player()
	if p != null:
		p.controls_locked = true
	hud.hide_modals()
	if world is Lobby:
		var ruined_world := world as Lobby
		hud.visible = false
		ruined_world.begin_devastation()
		await get_tree().create_timer(Lobby.DEVASTATION_SECONDS).timeout
		if world != ruined_world or not _game_over:
			return
		hud.visible = true
	hud.game_over_panel.show_game_over(reason)


func return_to_title(from_game_over: bool = false) -> void:
	if _transitioning:
		return
	_transitioning = true
	_input_locked = true
	_apply_input_lock()
	await loading_screen.begin("PB • Protect BESUT")
	hud.hide_modals()
	hud.game_over_panel.force_close()
	_clear_world()
	hud.visible = false
	_input_locked = false
	_game_over = false
	_defeat_pending = false
	GameState.game_over_active = false
	if not from_game_over:
		GameState.save_game()
		GameState.autosave_enabled = true
	_remove_title()
	_show_title()
	await loading_screen.finish()
	_transitioning = false


func open_inventory() -> void:
	if _input_locked and not hud.inventory_panel.visible:
		return
	GameState.record_mission_event("inventory")
	_input_locked = true
	_apply_input_lock()
	hud.inventory_panel.open_inventory()


func toggle_build_mode() -> void:
	if not (world is Lobby):
		GameState.toast_requested.emit("Settlement editing is only available at home.", "bad")
		return
	if _input_locked or hud.any_modal_open() or GameState.recovery_active() or GameState.emergency_active():
		GameState.toast_requested.emit("Finish the current activity before editing the settlement.", "bad")
		return
	var active: bool = bool(world.call("toggle_build_mode"))
	hud.set_build_mode(active)


func set_sleep_state(active: bool, progress: float, label: String) -> void:
	hud.set_sleep_state(active, progress, label)


func refresh_world_ui() -> void:
	hud.refresh_all()


func player() -> Player:
	if world == null:
		return null
	if world.has_method("get_player"):
		return world.call("get_player") as Player
	# A queued previous world can retain its player group until frame end.
	return world.get("player") as Player


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if GameState.autosave_enabled:
			GameState.save_game()


func _exit_tree() -> void:
	# Resource-owning static caches otherwise keep their own script resources alive.
	PersonalityProfile._default = null
	WorldPalette.active = null
	AssetRegistry.catalog = null
	AssetRegistry._cache.clear()
	PixelArt.CACHE.clear()


func enter_home() -> void:
	if not world is Lobby or _game_over or _input_locked or _transitioning or is_instance_valid(home_interior):
		return
	if int(GameState.structure_state("cottage").get("health", 0)) <= 0:
		return
	var p := player()
	if not is_instance_valid(p):
		return
	_transitioning = true
	_input_locked = true
	_apply_input_lock()
	await loading_screen.begin("Main House")
	_outdoor_position = world._house_position + Vector2(0, 2.0)
	home_interior = HomeInterior.new()
	home_interior.game = self
	world.add_child(home_interior)
	p.global_position = home_interior.global_position
	p.velocity = Vector2.ZERO
	p.reset_physics_interpolation()
	_place_home_pet(p.global_position)
	world.camera.target = p
	_set_home_camera(Rect2(89, 19, 14, 10))
	world.camera.global_position = p.global_position
	world.camera.set_physics_process(false)
	world.camera.zoom = Vector2.ONE * minf(get_viewport_rect().size.x / 16.0, get_viewport_rect().size.y / 12.0)
	await loading_screen.finish()
	_transitioning = false
	_input_locked = hud.any_modal_open()
	_apply_input_lock()

func leave_home() -> void:
	if not world is Lobby or not is_instance_valid(home_interior) or GameState.recovery_active() or _transitioning:
		return
	_transitioning = true
	_input_locked = true
	_apply_input_lock()
	await loading_screen.begin("Besut Village")
	var p := player()
	p.global_position = _outdoor_position
	p.velocity = Vector2.ZERO
	p.reset_physics_interpolation()
	_place_home_pet(p.global_position)
	home_interior.queue_free()
	home_interior = null
	world.camera.set_physics_process(true)
	world.camera.zoom = Vector2.ONE * GameSettings.camera_zoom()
	_set_home_camera(Lobby.MAP_RECT)
	world.camera.global_position = p.global_position
	await loading_screen.finish()
	_transitioning = false
	_input_locked = hud.any_modal_open()
	_apply_input_lock()

func _set_home_camera(bounds: Rect2) -> void:
	world.camera.bounds = bounds
	world.camera.limit_left = int(bounds.position.x)
	world.camera.limit_top = int(bounds.position.y)
	world.camera.limit_right = int(bounds.end.x)
	world.camera.limit_bottom = int(bounds.end.y)


func open_missions() -> void:
	if not world is Lobby or _game_over:
		return
	_input_locked = true
	_apply_input_lock()
	hud.mission_panel.open_missions()


func _place_home_pet(at: Vector2) -> void:
	if is_instance_valid(world.pet):
		world.pet.global_position = at + Vector2(-1, 0.5)
		world.pet.velocity = Vector2.ZERO
		world.pet._follow_velocity = Vector2.ZERO
		world.pet._follow_path.clear()
		world.pet.reset_physics_interpolation()


func open_field_guide() -> void:
	if _transitioning:
		return
	_input_locked = true
	_apply_input_lock()
	hud.field_guide_panel.open_book()


func board_ship(boarding: ShipDeparture, direct_tap: bool = false) -> bool:
	if not world is Lobby or _transitioning or _input_locked or _sailing or _game_over or is_instance_valid(home_interior) or GameState.recovery_active() or GameState.emergency_active():
		return false
	var p := player()
	if not is_instance_valid(boarding) or boarding.get_parent() != world or not is_instance_valid(p) or p.dead or p.sleeping or (not direct_tap and p.global_position.distance_to(boarding.global_position) > boarding.interact_radius):
		return false
	_sailing = true
	_input_locked = true
	_apply_input_lock()
	hud.release_world_controls()
	hud.visible = false
	if not boarding.begin(p):
		_sailing = false
		_input_locked = false
		hud.visible = true
		_apply_input_lock()
		return false
	world.pet.visible = false
	GameState.save_game()
	return true

func enter_ocean(boarding: ShipDeparture) -> void:
	if _transitioning or not _sailing or not is_instance_valid(boarding) or boarding.get_parent() != world or not boarding.arrived:
		return
	_transitioning = true
	_input_locked = true
	await loading_screen.begin("Below the Waves")
	_clear_world()
	var ocean := OceanJourney.new()
	ocean.name = "OceanJourney"
	world = ocean
	_world_holder.add_child(ocean)
	hud.set_world(ocean)
	hud.visible = false
	_apply_input_lock()
	await loading_screen.finish()
	_transitioning = false

func return_from_ocean() -> void:
	if not (world is OceanJourney or world is KrakenIsland) or _transitioning:
		return
	_return_to_harbour = true
	GameState.save_game()
	await _load_lobby(true)
	var returning_lobby := world as Lobby
	while is_instance_valid(returning_lobby) and world == returning_lobby and _sailing:
		await get_tree().physics_frame


func finish_ship_return(boarding: ShipDeparture) -> void:
	if not world is Lobby or not _sailing or boarding != world.ship_boarding or not boarding.landed:
		return
	_sailing = false
	hud.visible = true
	_place_home_pet(player().global_position)
	world.pet.visible = true
	world._on_presentation_changed("")
	_on_modal_closed()
	if _arjun_returning:
		await _land_arjun(boarding)
	_check_campaign_ending()


func try_urchin_introduction(home: Lobby, fire_count: int, points: PackedVector2Array, fire_points: PackedVector2Array = PackedVector2Array()) -> bool:
	if world != home or _transitioning or _story_active or _sailing or _game_over or _defeat_pending or _input_locked or hud.any_modal_open() or is_instance_valid(home_interior): return false
	if is_instance_valid(_urchin_arrival) or is_instance_valid(home._fire_cue) or is_instance_valid(_dock_conversation) or home._settlement_editor.active or GameState.recovery_active() or GameState.emergency_active(): return false
	if not bool(GameState.campaign().get("dock_welcome_seen", false)): return false
	var shore_intro := not points.is_empty() and not bool(GameState.campaign().get("urchin_intro_seen", false))
	var fire_intro := fire_count > 0 and not bool(GameState.campaign().get("fire_intro_seen", false))
	if not shore_intro and not fire_intro: return false
	if not GameState.is_night() or not is_instance_valid(player()) or player().dead or player().sleeping: return false
	# A cinematic must not hide urgent damage elsewhere in the village.
	if not home.capture_monsters().is_empty() or home._forest_trees.any(func(tree: ForestTree) -> bool: return is_instance_valid(tree) and tree.burning): return false
	if fire_count > 0 and fire_points.is_empty(): fire_points = home.fire_entry_points(fire_count)
	if points.is_empty() and fire_points.is_empty(): return false
	var pending := GameState.stage_home_arrival(fire_count, points, false, fire_points)
	if pending.is_empty(): return false
	if not pending.resolved_fire.is_empty() or not pending.resolved_shore.is_empty(): return false
	_urchin_world_mode = home.process_mode
	_urchin_hud_visible = hud.visible
	_story_active = true
	_input_locked = true
	hud.release_world_controls()
	_apply_input_lock()
	home.process_mode = Node.PROCESS_MODE_DISABLED
	hud.visible = false
	var arrival := UrchinArrival.new()
	arrival.home = home
	arrival.configure(pending)
	arrival.introduce_shore = shore_intro
	arrival.introduce_fire = fire_intro and not arrival.fire_points.is_empty()
	arrival.full_intro = true
	_urchin_arrival = arrival
	arrival.completed.connect(_on_urchin_introduction_completed.bind(arrival))
	add_child(arrival)
	return true

func _on_urchin_introduction_completed(arrival: UrchinArrival) -> void:
	if _urchin_arrival != arrival: return
	_urchin_arrival = null
	var owned := is_instance_valid(arrival.home) and world == arrival.home and arrival.serial == GameState.journey_serial
	if owned:
		if not arrival.cancelled and not _transitioning: arrival.home.finish_urchin_arrival(arrival)
		arrival.home.process_mode = _urchin_world_mode
	_story_active = false
	if owned:
		hud.visible = _urchin_hud_visible
		_input_locked = hud.any_modal_open() or _sailing or _transitioning
		_apply_input_lock()

func _side_quest_context_safe() -> bool:
	if not is_instance_valid(world) or world.is_queued_for_deletion() or not (world is Lobby or world is TwilightRealm): return false
	if _transitioning or _story_active or _sailing or _input_locked or _game_over or _defeat_pending or is_instance_valid(title_screen): return false
	if not _side_quest_intro.is_empty() or hud.any_modal_open() or is_instance_valid(home_interior): return false
	var actor := player()
	if not is_instance_valid(actor) or actor.dead or actor.sleeping or actor.controls_locked or actor.attacking or Input.is_action_pressed("attack"): return false
	if GameState.recovery_active() or GameState.emergency_active(): return false
	if world is Lobby and (GameState.is_night() or world._settlement_editor.active or world.journey_serial != GameState.journey_serial): return false
	if world is TwilightRealm and (world._boss_arrived or world._camp_resting or world._reading_panel.visible or not world.combat.active_id.is_empty()): return false
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or enemy.get_parent() != world or enemy.dead: continue
		if world is TwilightRealm and not world.can_target_actor(enemy): continue
		if enemy.global_position.distance_to(actor.global_position) < 10.0: return false
	for tree in get_tree().get_nodes_in_group("forest_tree"):
		if is_instance_valid(tree) and tree.get_parent() == world and tree.burning and tree.global_position.distance_to(actor.global_position) < 10.0: return false
	return true

func _try_side_quest_introduction() -> bool:
	if not _side_quest_context_safe(): return false
	var entry := SideQuestDB.nearby(world, player())
	if entry.is_empty() or GameState.side_quest_intro_seen(str(entry.id)): return false
	# This is an owned story beat, not a globally pausing menu or quest acceptance.
	_side_quest_intro = {"id": str(entry.id), "world": world, "serial": GameState.journey_serial, "mode": world.process_mode, "cancelled": false}
	_input_locked = true
	_story_active = true
	hud.release_world_controls()
	player().velocity = Vector2.ZERO
	_apply_input_lock()
	world.process_mode = Node.PROCESS_MODE_DISABLED
	hud.dialogue_panel.closed.connect(_finish_side_quest_introduction, CONNECT_ONE_SHOT)
	hud.dialogue_panel.open_dialogue(str(entry.speaker), entry.lines)
	return true

func _finish_side_quest_introduction() -> void:
	if _side_quest_intro.is_empty(): return
	var record := _side_quest_intro
	_side_quest_intro = {}
	var expected: Node = record.world
	var owned := is_instance_valid(expected) and world == expected and int(record.serial) == GameState.journey_serial
	if is_instance_valid(expected): expected.process_mode = int(record.mode)
	_story_active = false
	if owned:
		if not bool(record.cancelled): GameState.mark_side_quest_intro_seen(str(record.id))
		_input_locked = hud.any_modal_open() or _sailing or _transitioning
		_apply_input_lock()

func awaken_portal(site: PortalOriginSite, replay: bool = false) -> bool:
	if not is_instance_valid(site) or not site.valid_actor(player()) or not world is Lobby: return false
	if is_instance_valid(_portal_awakening) or is_instance_valid(_urchin_arrival) or is_instance_valid(world._urchin_cue) or is_instance_valid(world._fire_cue) or is_instance_valid(_dock_conversation): return false
	if GameState.recovery_active() or GameState.emergency_active():
		site.set_message("Recover and protect BESUT before tending the waystone.")
		return false
	for pending in [GameState.pending_home_arrival(),GameState.pending_home_arrival(true)]:
		for point in pending.get("points", [])+pending.get("fire_points", []):
			if Vector2(float(point[0]),float(point[1])).distance_to(site.position) < 8.0:
				site.set_message("Let the nearby arrival settle before tending the waystone.")
				return false
	for actor in world.get_children():
		if actor is Enemy and not actor.dead and not actor.is_queued_for_deletion() and actor.global_position.distance_to(site.global_position) < 8.0:
			site.set_message("Clear the nearby creatures before tending the waystone.")
			return false
	if replay:
		if not GameState.portal_opened() or bool(GameState.portal_origin().reveal_seen): return false
	elif not GameState.open_waystone(): return false
	var home := world as Lobby
	home.refresh_dimension_portal()
	_portal_world_mode = home.process_mode
	_portal_hud_visible = hud.visible
	_story_active = true
	_input_locked = true
	hud.release_world_controls()
	_apply_input_lock()
	home.process_mode = Node.PROCESS_MODE_DISABLED
	hud.visible = false
	var reveal := PortalAwakening.new()
	reveal.home = home
	reveal.site = site
	_portal_awakening = reveal
	reveal.completed.connect(_on_portal_awakened.bind(reveal))
	add_child(reveal)
	return true


func _on_portal_awakened(reveal: PortalAwakening) -> void:
	if _portal_awakening != reveal: return
	_portal_awakening = null
	var owned := is_instance_valid(reveal.home) and world == reveal.home and reveal.serial == GameState.journey_serial
	if is_instance_valid(reveal.home): reveal.home.process_mode = _portal_world_mode
	_story_active = false
	if not owned: return
	if not reveal.cancelled and not _game_over and not _defeat_pending: GameState.finish_portal_reveal()
	if is_instance_valid(reveal.site): reveal.site.refresh()
	hud.release_world_controls()
	hud.visible = _portal_hud_visible and not _game_over
	_input_locked = hud.any_modal_open() or _sailing or _transitioning or _game_over or _defeat_pending
	_apply_input_lock()


func play_dock_conversation(introduction: bool = false) -> void:
	if not world is Lobby or is_instance_valid(home_interior) or _transitioning or _story_active or _sailing or hud.any_modal_open() or is_instance_valid(_dock_conversation): return
	if _game_over or _defeat_pending or world._settlement_editor.active or not is_instance_valid(player()) or player().dead or player().sleeping: return
	if GameState.recovery_active() or (introduction and bool(GameState.campaign().get("dock_welcome_seen", false))): return
	var dock_world := world as Lobby
	var serial := GameState.journey_serial
	var previous_mode := dock_world.process_mode
	var was_visible := hud.visible
	_input_locked = true
	_apply_input_lock()
	hud.release_world_controls()
	# The opening is a story; later voluntary chats follow normal menu rules.
	if introduction:
		_story_active = true
		dock_world.process_mode = Node.PROCESS_MODE_DISABLED
	hud.visible = false
	var conversation := DockConversation.new()
	conversation.introduction = introduction
	conversation.waystone = not introduction and bool(GameState.portal_origin().site_examined) and not bool(GameState.portal_origin().rahim_consulted)
	if not introduction:
		conversation.road_reminder = "open" if GameState.portal_opened() else ("ready" if bool(GameState.portal_origin().rahim_consulted) else "")
	_dock_conversation = conversation
	add_child(conversation)
	await conversation.completed
	var still_owned := is_instance_valid(dock_world) and world == dock_world and serial == GameState.journey_serial
	if still_owned and introduction and not conversation.cancelled:
		GameState.mark_story_seen("dock_welcome_seen")
	if still_owned and conversation.waystone and not conversation.cancelled and not _game_over and not _defeat_pending:
		GameState.consult_waystone()
	if introduction and is_instance_valid(dock_world): dock_world.process_mode = previous_mode
	if _dock_conversation != conversation: return
	_dock_conversation = null
	if introduction: _story_active = false
	if still_owned:
		hud.visible = was_visible
		_input_locked = hud.any_modal_open() or _sailing or _transitioning
		_apply_input_lock()


func play_story(kind: String, from_title: bool = false) -> void:
	_story_active = true
	_input_locked = true
	_apply_input_lock()
	hud.release_world_controls()
	var story_world := world
	var old_mode := story_world.process_mode if is_instance_valid(story_world) else Node.PROCESS_MODE_INHERIT
	if is_instance_valid(story_world): story_world.process_mode = Node.PROCESS_MODE_DISABLED
	var was_visible := hud.visible
	hud.visible = false
	var story := StorySequence.new()
	story.kind = kind
	var departing_title := _title_layer
	story.arrive_from_title = from_title and is_instance_valid(departing_title)
	story.include_loading_screen = story.arrive_from_title
	if story.arrive_from_title:
		story.departure_covered.connect(_remove_title_if_owner.bind(departing_title), CONNECT_ONE_SHOT)
	add_child(story)
	await story.completed
	if kind == "intro": GameState.mark_story_seen("intro_seen")
	if kind == "ending": GameState.mark_story_seen("ending_seen")
	if is_instance_valid(story_world): story_world.process_mode = old_mode
	_story_active = false
	hud.visible = was_visible
	_input_locked = hud.any_modal_open() or _sailing
	_apply_input_lock()

func enter_kraken_island() -> void:
	if not world is OceanJourney or _transitioning: return
	_transitioning = true
	await loading_screen.begin("Kraken King's Island")
	_clear_world()
	var island := KrakenIsland.new()
	world = island
	_world_holder.add_child(island)
	hud.set_world(island)
	hud.visible = true
	_input_locked = false
	_apply_input_lock()
	await loading_screen.finish()
	_transitioning = false

func _handle_island_defeat() -> void:
	if _defeat_pending: return
	_defeat_pending = true
	_input_locked = true
	_apply_input_lock()
	await get_tree().create_timer(0.8).timeout
	if not world is KrakenIsland: return
	GameState.defeat_at_home()
	await _load_lobby(true)
	_defeat_pending = false

func _rescue_mei_ling() -> void:
	var dungeon := world as Dungeon
	if not is_instance_valid(dungeon): return
	var journey := GameState.journey_serial
	hud.hide_modals()
	var companion := Sprite2D.new()
	companion.name = "RescuedMeiLing"
	companion.texture = PixelArt.character_texture("mei_ling", 0)
	companion.scale = Vector2.ONE * PixelArt.PX
	companion.position = dungeon.player.position + Vector2(-2, 0)
	dungeon.add_child(companion)
	await play_story("mei")
	if is_instance_valid(companion): companion.queue_free()
	if world != dungeon or GameState.journey_serial != journey: return
	# Mei Ling returns home in the story. Keep the restored exploration realm,
	# its wildlife and optional passages available until Adam chooses to leave.
	_apply_input_lock()

func _check_campaign_ending() -> void:
	if not world is Lobby or _sailing or _transitioning or _story_active or not GameState.friends_reunited() or bool(GameState.campaign().get("ending_seen", false)): return
	await play_story("ending")

func _land_arjun(boarding: ShipDeparture) -> void:
	var home := world as Lobby
	var actor := boarding.ship.get_node_or_null("ArjunPassenger") as PlayerSprite
	if is_instance_valid(actor):
		actor.reparent(home)
		actor.base_scale = Vector2.ONE * PixelArt.PX
		actor.scale = actor.base_scale
		actor.set_meta("passenger_onboard", false)
		var landing := boarding.global_position + Vector2(0.6, 0)
		var destination := home._house_position + Vector2(-3, 3)
		var route := home.resident_path(landing, destination)
		_arjun_walk = actor.create_tween()
		var from := actor.global_position
		var points := PackedVector2Array([landing])
		points.append_array(route)
		for point in points:
			var direction := point - from
			var facing := (2 if direction.x > 0 else 3) if absf(direction.x) > absf(direction.y) else (0 if direction.y > 0 else 1)
			_arjun_walk.tween_callback(func() -> void:
				actor.motion_ratio = 1.0
				actor.set_facing(facing, true))
			_arjun_walk.tween_property(actor, "global_position", point, direction.length() / Resident.WALK_SPEED)
			from = point
		await _arjun_walk.finished
		actor.queue_free()
	if is_instance_valid(home) and world == home:
		_arjun_returning = false
		home._sync_rescued_friends()

func open_map() -> void:
	if not is_instance_valid(world) or _transitioning or _story_active or _sailing or _game_over or hud.any_modal_open(): return
	_input_locked = true
	_apply_input_lock()
	hud.release_world_controls()
	hud.map_panel.open_map()
