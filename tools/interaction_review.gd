extends Node
## Native mouse/touch checks for tutorial focus, shops, previews and manual duels.

var _shots := ""
var _failures := 0


func _ready() -> void:
	if not TestEnvironment.require_isolation():
		get_tree().quit(1)
		return
	_shots = OS.get_environment("TIDESWORN_TEST_ROOT").path_join("shots")
	DirAccess.make_dir_recursive_absolute(_shots)
	var game := load("res://scenes/game.tscn").instantiate() as Game
	add_child(game)
	await get_tree().process_frame
	await game._on_character_selected("qayyim")
	await get_tree().create_timer(0.4).timeout
	var lobby := game.world as Lobby
	var hud := game.hud
	var focus := hud._root.get_node("TutorialSpotlight") as TutorialSpotlight
	print("tutorial layout: guide=", hud.tutorial_guide.get_global_rect(), " visible=", hud.tutorial_guide.is_visible_in_tree(), " focus=", focus.get_global_rect(), " z=", hud.tutorial_guide.z_index)
	_check(get_viewport().get_visible_rect().encloses(hud.tutorial_guide.get_global_rect()), "tutorial instructions remain on screen")
	_check(focus.visible and focus.target_rect.intersects(hud._joystick.get_global_rect()), "tutorial points to movement controls")
	await _shot("01_movement_spotlight")
	GameState.record_mission_event("move")
	GameState.record_mission_event("gather")
	var potion: ShopNPC
	for shop in get_tree().get_nodes_in_group("ambient_shop"):
		if shop.shop_type == "potion":
			potion = shop
	lobby.player.global_position = potion.customer_position()
	lobby.camera.global_position = potion.global_position
	await get_tree().create_timer(0.4).timeout
	await _shot("02_shop_spotlight")
	var screen := lobby.get_global_transform_with_canvas() * (potion.global_position + Vector2(0, -0.8))
	await _click(screen)
	_check(hud.shop_panel.visible and hud.shop_panel.shop_type == "potion", "clicking the stall opens its shop without Talk")
	var buy := focus._find_action(hud.shop_panel.content, "health_potion")
	_check(is_instance_valid(buy) and focus.target_rect.intersects(buy.get_global_rect()), "tutorial brightens the exact potion Buy button")
	await _shot("03_buy_spotlight")
	await _click(buy.get_global_rect().get_center())
	_check(GameState.mission_step() == 3, "highlighted Buy button advances the potion mission")
	await _click(hud.shop_panel._close_button.get_global_rect().get_center())
	_check(not hud.shop_panel.visible and focus.target_rect.intersects(hud._inventory_button.get_global_rect()), "tutorial moves to Pack after closing the shop")
	await _shot("04_pack_spotlight")
	hud.tutorial_guide._skip()
	for kind in ["equipment", "pet", "services", "house"]:
		var merchant: ShopNPC
		for shop in get_tree().get_nodes_in_group("ambient_shop"):
			if shop.shop_type == kind:
				merchant = shop
		lobby.player.global_position = merchant.customer_position()
		lobby.camera.global_position = merchant.global_position
		await get_tree().create_timer(0.3).timeout
		var position := lobby.get_global_transform_with_canvas() * (merchant.global_position + Vector2(0, -0.8))
		await _click(position, true)
		var modal: ModalBase = hud.house_panel if kind == "house" else (hud.village_services_panel if kind == "services" else hud.shop_panel)
		_check(modal.visible, "touching %s stall opens its own panel" % kind)
		if kind == "house":
			var diamonds := GameState.diamonds()
			var level := GameState.house_level()
			for preview in [5, 1, 3]:
				var button := _preview_button(modal.content, preview)
				await _click(button.get_global_rect().get_center())
				_check(hud.house_panel._preview_level == preview, "level %d button changes house preview" % preview)
				await _shot("05_house_level_%d" % preview)
			_check(GameState.house_level() == level and GameState.diamonds() == diamonds, "browsing house designs makes no purchase")
		await _click(modal._close_button.get_global_rect().get_center())
		_check(not modal.visible and not game._input_locked, "Close restores player controls")
	game.open_pet_battles()
	await get_tree().create_timer(0.2).timeout
	var duel := hud.pet_battle_panel
	_check(duel.start_battle("pet_duel_1"), "pet duel starts")
	var player_hp := duel._player_hp
	var enemy_hp := duel._opponent_hp
	await get_tree().create_timer(3.0).timeout
	_check(duel._player_hp == player_hp and duel._opponent_hp == enemy_hp, "both pets remain idle beyond the old timeout")
	await _shot("06_manual_pet_turn")
	duel._enemy_choice = "attack"
	await _click(duel._skill_buttons[1].get_global_rect().get_center())
	_check(duel._player_hp < player_hp and duel._opponent_hp == enemy_hp, "Defend acts once and reduces incoming damage without attacking")
	await get_tree().create_timer(1.0).timeout
	player_hp = duel._player_hp
	await get_tree().create_timer(2.5).timeout
	_check(duel._player_hp == player_hp and duel._opponent_hp == enemy_hp, "the following round also waits for input")
	duel.close_panel()
	GameState.advance_world_clock(GameState.DAY_PHASE_SECONDS)
	for child in lobby.get_children():
		if child is Enemy:
			child.set_physics_process(false)
	await get_tree().create_timer(3.1).timeout
	_check(GameState.is_night() and lobby._grade.color.is_equal_approx(Lobby.NIGHT_GRADE), "night visibly darkens the village")
	await _shot("07_night")
	var count := lobby.capture_monsters().size()
	GameState.advance_world_clock(GameState.DAY_PHASE_SECONDS)
	await get_tree().create_timer(3.1).timeout
	_check(not GameState.is_night() and lobby.capture_monsters().size() == count, "sunrise keeps all surviving monsters")
	await _shot("08_dawn_survivors")
	var repair: StructureRepairPoint
	for point in get_tree().get_nodes_in_group("structure_repairs"):
		if point.target.structure_id == "cottage":
			repair = point
	repair.target.take_attack_damage(9999)
	lobby.player.global_position = repair.global_position
	lobby.player._update_nearby()
	var gold := GameState.gold()
	_check(lobby.player.nearby == repair, "damaged doorway selects Betulkan")
	await _shot("09_free_repair_prompt")
	Input.action_press("interact")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release("interact")
	_check(not repair.target.is_intact() and GameState.gold() == gold and float(GameState.structure_state(repair.target.structure_id).get("repair_remaining", 0)) > 0, "Use at the damaged house requests a free builder repair")
	print("interaction review: %s" % ("PASS" if _failures == 0 else "FAIL"))
	get_tree().quit(0 if _failures == 0 else 1)


func _preview_button(node: Node, level: int) -> Button:
	if node is Button and int(node.get_meta("house_preview_level", 0)) == level:
		return node
	for child in node.get_children():
		var found := _preview_button(child, level)
		if found:
			return found
	return null


func _click(position: Vector2, touch: bool = false) -> void:
	for pressed in [true, false]:
		if touch:
			var event := InputEventScreenTouch.new()
			event.position = position
			event.pressed = pressed
			event.index = 7
			Input.parse_input_event(event)
		else:
			var event := InputEventMouseButton.new()
			event.button_index = MOUSE_BUTTON_LEFT
			event.position = position
			event.pressed = pressed
			Input.parse_input_event(event)
		await get_tree().process_frame
	await get_tree().create_timer(0.15).timeout


func _check(ok: bool, message: String) -> void:
	print("[OK] " if ok else "[FAIL] ", message)
	if not ok:
		_failures += 1


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_shots.path_join(name + ".png"))
