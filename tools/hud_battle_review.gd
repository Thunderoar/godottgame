extends "res://tools/pb_test.gd"

var _shots := ""

func _ready() -> void:
	if not TestEnvironment.require_isolation():
		get_tree().quit(1)
		return
	_shots = OS.get_environment("TIDESWORN_TEST_ROOT").path_join("shots")
	DirAccess.make_dir_recursive_absolute(_shots)
	game = load("res://scenes/game.tscn").instantiate() as Game
	add_child(game)
	await get_tree().process_frame
	await game._on_character_selected("qayyim")
	await get_tree().create_timer(0.3).timeout
	var lobby := game.world as Lobby
	_freeze(lobby)
	game.hud.tutorial_guide._skip()
	await _shot("01_minimal_hud")
	for dimensions in [Vector2i(1280, 720), Vector2i(832, 480)]:
		get_window().content_scale_size = dimensions
		get_window().size = dimensions
		await get_tree().create_timer(0.2).timeout
		game.open_pet_battles()
		await get_tree().create_timer(0.2).timeout
		var panel := game.hud.pet_battle_panel
		_check(panel.start_battle("pet_duel_1"), "manual three-power duel starts at %dx%d" % [dimensions.x, dimensions.y])
		panel._opponent_hp = 500
		panel._opponent_max = 500
		panel._update_bars()
		await get_tree().create_timer(0.15).timeout
		var viewport := get_viewport().get_visible_rect()
		_check(viewport.encloses(panel._close_button.get_global_rect()) and panel._skill_buttons.all(func(b: Button) -> bool: return viewport.encloses(b.get_global_rect())), "Close and all three powers fit onscreen")
		_check(not panel.body.get_h_scroll_bar().visible, "arena has no sideways scrolling")
		await _shot("02_arena_%dx%d" % [dimensions.x, dimensions.y])
		var player_hp := panel._player_hp
		panel._enemy_choice = "attack"
		await _click(panel._skill_buttons[0].get_global_rect().get_center())
		_check(panel._opponent_hp < 500 and panel._player_hp == player_hp, "touching power one makes player act first")
		await get_tree().create_timer(0.8).timeout
		_check(panel._player_hp < player_hp and float(panel._enemy_cooldowns.attack) > 0, "rival replies after the player's animation")
		await get_tree().create_timer(0.6).timeout
		var enemy_hp := panel._opponent_hp
		await _click(panel._skill_buttons[0].get_global_rect().get_center())
		_check(panel._opponent_hp == enemy_hp and panel._turn_active, "touching a cooling-down power cannot trigger it")
		panel._enemy_choice = "burst"
		player_hp = panel._player_hp
		await _click(panel._skill_buttons[1].get_global_rect().get_center())
		await get_tree().create_timer(0.8).timeout
		_check(player_hp - panel._player_hp <= panel._enemy_damage and float(panel._player_cooldowns.defend) > 0, "power two shields and displays its cooldown")
		await get_tree().create_timer(0.6).timeout
		enemy_hp = panel._opponent_hp
		await _click(panel._skill_buttons[2].get_global_rect().get_center())
		_check(enemy_hp - panel._opponent_hp == panel._player_damage * 2 and float(panel._player_cooldowns.burst) > 0, "power three deals double damage and cools down")
		await _shot("03_cooldowns_%dx%d" % [dimensions.x, dimensions.y])
		await _click(panel._close_button.get_global_rect().get_center())
		_check(not panel.visible and not game._input_locked, "Close exits full arena and restores input")
	get_window().content_scale_size = Vector2i(1280, 720)
	get_window().size = Vector2i(1280, 720)
	await get_tree().create_timer(0.2).timeout
	game.open_menu()
	await get_tree().create_timer(0.15).timeout
	await _shot("04_build_inside_menu")
	var build := _button(game.hud.menu_panel, "Build settlement")
	await _click(build.get_global_rect().get_center())
	_check(lobby._settlement_editor.active and game.hud._build_button == null, "Menu Build enters editor without a HUD shortcut")
	game.open_menu()
	await get_tree().create_timer(0.15).timeout
	var finish := _button(game.hud.menu_panel, "Finish building")
	await _click(finish.get_global_rect().get_center())
	_check(not lobby._settlement_editor.active, "Menu Finish building exits editor")
	game.hud.start_tutorial()
	await get_tree().process_frame
	_check(game.hud.tutorial_guide._counter.text.begins_with("SIANG"), "daytime tips identify the day track")
	await _shot("05_day_training")
	GameState.advance_world_clock(180)
	_freeze(lobby)
	await get_tree().create_timer(0.15).timeout
	_check(game.hud.tutorial_guide.visible and game.hud.tutorial_guide._counter.text.begins_with("MALAM") and GameState.mission_step() == 4, "night switches tutorial to combat automatically")
	await _shot("06_night_training")
	print("PB review: %s" % ("PASS" if failures == 0 else "FAIL"))
	get_tree().quit(0 if failures == 0 else 1)

func _button(node: Node, caption: String) -> Button:
	if node is Button and node.text == caption:
		return node
	for child in node.get_children():
		var found := _button(child, caption)
		if found:
			return found
	return null

func _click(point: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventScreenTouch.new()
		event.position = point
		event.pressed = pressed
		event.index = 6
		Input.parse_input_event(event)
		await get_tree().process_frame
	await get_tree().create_timer(0.15).timeout

func _shot(label: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_shots.path_join(label + ".png"))
