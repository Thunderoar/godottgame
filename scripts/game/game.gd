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

const EMERGENCY_DELAY := 14.0
const SETTLEMENT_DAMAGE_TICK := 5.0


func _ready() -> void:
	add_to_group("game")
	_world_holder = Node2D.new()
	_world_holder.name = "WorldHolder"
	add_child(_world_holder)
	hud = GameHUD.new()
	hud.name = "HUD"
	add_child(hud)
	hud.visible = false
	_connect_hud()
	GameState.player_defeated.connect(_on_player_defeated)
	GameState.game_over_triggered.connect(_on_game_over)
	_show_title()


func _process(delta: float) -> void:
	if is_instance_valid(world) and not _game_over:
		GameState.advance_world_clock(delta)
	if world is Dungeon and GameState.expedition_active():
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


func _on_character_selected(character_id: String) -> void:
	if _transitioning:
		return
	GameState.autosave_enabled = true
	GameState.new_game(character_id)
	_remove_title()
	hud.visible = true
	_game_over = false
	_load_lobby(false)
	hud.start_tutorial()


func _on_continue_requested() -> void:
	if not GameState.continue_game():
		return
	_remove_title()
	hud.visible = true
	if GameState.mission_step() < MissionDB.STEPS.size():
		hud.start_tutorial()
	if GameState.expedition_active():
		var portal_id := GameState.expedition_portal()
		_load_dungeon(portal_id, false)
	else:
		_load_lobby(false)


func _remove_title() -> void:
	if title_screen and is_instance_valid(title_screen):
		title_screen.queue_free()
	if _title_layer and is_instance_valid(_title_layer):
		_title_layer.queue_free()
	title_screen = null
	_title_layer = null


# ------------------------------------------------------------------ world switching

func _clear_world() -> void:
	if is_instance_valid(world) and world is Lobby and world.journey_serial == GameState.journey_serial:
		GameState.store_home_monsters(world.capture_monsters())
	if world and is_instance_valid(world):
		world.queue_free()
	world = null
	hud.set_world(null)


func _load_lobby(transition: bool = true) -> void:
	if _transitioning:
		return
	_transitioning = true
	_input_locked = true
	if transition:
		await hud.fade_to_black(0.25)
	_clear_world()
	hud.set_build_mode(false)
	var lobby := Lobby.new()
	lobby.name = "Lobby"
	world = lobby
	_world_holder.add_child(lobby)
	hud.set_world(lobby)
	_restore_player_visual()
	hud.set_sleep_state(false, 0.0, "")
	if GameState.health() <= 0:
		GameState.set_health(GameState.health_max())
	_input_locked = false
	_apply_input_lock()
	if transition:
		await hud.fade_from_black(0.3)
	_transitioning = false


func _load_dungeon(portal_id: String, transition: bool = true) -> void:
	if _transitioning:
		return
	_transitioning = true
	_input_locked = true
	if transition:
		await hud.fade_to_black(0.3)
	_clear_world()
	hud.set_build_mode(false)
	var dungeon := Dungeon.new()
	dungeon.setup(portal_id)
	dungeon.name = "Dungeon"
	world = dungeon
	_world_holder.add_child(dungeon)
	hud.set_world(dungeon)
	_restore_player_visual()
	hud.set_sleep_state(false, 0.0, "")
	_input_locked = false
	_apply_input_lock()
	if transition:
		await hud.fade_from_black(0.35)
	_transitioning = false


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
	var reason := GameState.portal_clear_reason(portal_id)
	if not bool(reason.ok):
		GameState.toast_requested.emit(str(reason.reason), "bad")
		return
	if not GameState.start_expedition(portal_id):
		return
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
	_load_dungeon(portal_id, true)


func _nearest_gate_center(from: Vector2) -> Vector2:
	# Drift slightly toward the paired gates so the pull reads as "into them".
	if world is Lobby:
		return (Lobby.MONSTER_GATE + Lobby.PET_GATE) * 0.5
	return from


func return_to_lobby(from_defeat: bool = false) -> void:
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
	hud.defeat_panel.show_defeat(portal_name, lost.replace("Unbanked: ", ""), companion)


func _on_player_defeated() -> void:
	if world is Dungeon:
		handle_portal_defeat()
	elif world is Lobby:
		handle_home_defeat()


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
	hud.victory_panel.show_victory(summary, portal_id)


func _on_modal_closed() -> void:
	if hud.any_modal_open():
		return
	_input_locked = false
	_apply_input_lock()


func _apply_input_lock() -> void:
	var p := player()
	if p != null:
		p.controls_locked = _input_locked or p.dead


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
	return get_tree().get_first_node_in_group("player") as Player


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
