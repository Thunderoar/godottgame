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
	_show_title()


func _process(delta: float) -> void:
	if world is Dungeon and GameState.expedition_active():
		if not _emergency_triggered:
			_portal_elapsed += delta
			if _portal_elapsed >= EMERGENCY_DELAY:
				_emergency_triggered = true
				GameState.start_emergency(3)
		if GameState.emergency_active():
			_settlement_damage_accum += delta
			if _settlement_damage_accum >= SETTLEMENT_DAMAGE_TICK:
				_settlement_damage_accum = 0.0
				GameState.damage_settlement(5)


func _connect_hud() -> void:
	hud.shop_panel.closed.connect(_on_modal_closed)
	hud.inventory_panel.closed.connect(_on_modal_closed)
	hud.portal_panel.closed.connect(_on_modal_closed)
	hud.pet_battle_panel.closed.connect(_on_modal_closed)
	hud.sea_cleaning_panel.closed.connect(_on_modal_closed)
	hud.house_panel.closed.connect(_on_modal_closed)
	hud.victory_panel.closed.connect(_on_modal_closed)
	hud.defeat_panel.closed.connect(_on_modal_closed)
	hud.inventory_requested.connect(open_inventory)
	hud.build_mode_requested.connect(toggle_build_mode)


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
	GameState.new_game(character_id)
	_remove_title()
	hud.visible = true
	_load_lobby(false)
	hud.start_tutorial()


func _on_continue_requested() -> void:
	if not GameState.continue_game():
		return
	_remove_title()
	hud.visible = true
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
	hud.set_sleep_state(false, 0.0, "")
	_input_locked = false
	_apply_input_lock()
	if transition:
		await hud.fade_from_black(0.35)
	_transitioning = false


func enter_portal(portal_id: String) -> void:
	var reason := GameState.portal_clear_reason(portal_id)
	if not bool(reason.ok):
		GameState.toast_requested.emit(str(reason.reason), "bad")
		return
	if not GameState.start_expedition(portal_id):
		return
	_defeat_pending = false
	_portal_elapsed = 0.0
	_emergency_triggered = false
	_settlement_damage_accum = 0.0
	_load_dungeon(portal_id, true)


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


func open_inventory() -> void:
	if _input_locked and not hud.inventory_panel.visible:
		return
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
		GameState.save_game()
