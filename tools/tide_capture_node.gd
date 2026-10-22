extends Node
## In-game capture harness. Run as a scene so project autoloads are present:
##   godot --path . res://tools/tide_capture.tscn -- --shots C:/path/to/shots

var game: Node
var shots := ""


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--shots" and i + 1 < args.size():
			shots = args[i + 1]
	if shots == "":
		shots = ProjectSettings.globalize_path("res://shots")
	DirAccess.make_dir_recursive_absolute(shots)
	GameState.delete_save()
	game = load("res://scenes/game.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	await _shot("tide_title.png")
	game.call("_on_character_selected", "qayyim")
	await get_tree().create_timer(0.5).timeout
	await _shot("tide_tutorial.png")
	if game.hud.get("tutorial_guide") != null:
		game.hud.tutorial_guide.call("_skip")
	await get_tree().create_timer(0.8).timeout
	await _shot("tide_lobby.png")
	game.call("open_menu")
	await get_tree().create_timer(0.25).timeout
	await _shot("tide_menu.png")
	game.hud.menu_panel.close_panel()
	await get_tree().create_timer(0.15).timeout
	game.call("open_settings")
	await get_tree().create_timer(0.3).timeout
	await _shot("tide_settings.png")
	game.hud.settings_panel.close_panel()
	await get_tree().create_timer(0.15).timeout
	game.call("open_dialogue", "Unisza Student", ["“Welcome to Unisza”", "“We are students from Unisza.”"])
	await get_tree().create_timer(0.25).timeout
	await _shot("tide_dialogue.png")
	game.hud.dialogue_panel.close_panel()
	await get_tree().create_timer(0.15).timeout
	game.call("toggle_build_mode")
	await get_tree().create_timer(0.35).timeout
	await _shot("tide_build.png")
	game.call("toggle_build_mode")
	await get_tree().create_timer(0.3).timeout
	game.call("open_shop", "potion", "Mara")
	await get_tree().create_timer(0.3).timeout
	await _shot("tide_shop.png")
	game.hud.hide_modals()
	game.call("open_shop", "pet", "Nia")
	await get_tree().create_timer(0.3).timeout
	game.hud.shop_panel.body.scroll_vertical = 10000
	await get_tree().create_timer(0.2).timeout
	await _shot("tide_pet_shop.png")
	game.hud.hide_modals()
	await get_tree().create_timer(0.2).timeout
	game.call("open_house")
	await get_tree().create_timer(0.3).timeout
	await _shot("tide_house.png")
	game.hud.hide_modals()
	await get_tree().create_timer(0.2).timeout
	game.call("open_inventory")
	await get_tree().create_timer(0.3).timeout
	await _shot("tide_inventory.png")
	game.hud.hide_modals()
	await get_tree().create_timer(0.2).timeout
	game.call("open_pet_battles")
	await get_tree().create_timer(0.4).timeout
	await _shot("tide_pet_battles.png")
	var pet_panel := game.hud.pet_battle_panel as PetBattlePanel
	var pet_started: bool = bool(pet_panel.start_battle("pet_duel_1"))
	if pet_started:
		await get_tree().create_timer(0.4).timeout
		pet_panel.choose_skill("attack")
		await get_tree().create_timer(0.55).timeout
		await _shot("tide_pet_duel.png")
		await get_tree().create_timer(1.2).timeout
		await _shot("tide_pet_resolution.png")
	game.hud.hide_modals()
	await get_tree().create_timer(0.2).timeout
	var forest_player: Node2D = game.call("player")
	forest_player.global_position = Vector2(46.8, 25.0)
	await get_tree().create_timer(0.8).timeout
	await _shot("tide_forest.png")
	for monster in get_tree().get_nodes_in_group("forest_monsters"):
		if is_instance_valid(monster):
			monster.set_physics_process(false)
	var ruin_player: Node2D = game.call("player")
	ruin_player.global_position = Vector2(19.0, 30.8)
	await get_tree().create_timer(0.7).timeout
	await _shot("tide_ruins.png")
	var sea_player: Node2D = game.call("player")
	sea_player.global_position = Vector2(13.5, 25.6)
	await get_tree().create_timer(0.7).timeout
	var system := get_tree().get_first_node_in_group("rubbish_system") as RubbishSystem
	if system != null:
		system.spawn_interval = 99999.0
		var piece := system.spawn_piece(0)
		piece.global_position = Vector2(7.2, 28.8)
	await get_tree().create_timer(0.25).timeout
	await _shot("tide_shore.png")
	game.call("open_portals", "tidebound_grotto")
	await get_tree().create_timer(0.4).timeout
	await _shot("tide_portals.png")
	game.hud.hide_modals()
	await get_tree().create_timer(0.3).timeout
	var player: Node2D = game.call("player")
	player.global_position = Vector2(34.0, 14.1)
	await get_tree().create_timer(0.5).timeout
	await _shot("tide_lobby_portal.png")
	game.call("enter_portal", "tidebound_grotto")
	await get_tree().create_timer(3.2).timeout
	game.set("_emergency_triggered", true)
	await _shot("tide_dungeon.png")
	player = game.call("player")
	var bosses := []
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.get("is_boss"):
			bosses.append(e)
	if not bosses.is_empty():
		player.global_position = bosses[0].global_position + Vector2(0, 4.0)
	await get_tree().create_timer(1.5).timeout
	await _shot("tide_boss.png")
	GameState.start_emergency(3)
	await get_tree().create_timer(0.8).timeout
	await _shot("tide_emergency.png")
	var dungeon: Dungeon = game.world
	dungeon.call("exit_to_lobby", true)
	await get_tree().create_timer(1.4).timeout
	await _shot("tide_settlement_attack.png")
	# Final visual-state capture: recovery ward.
	GameState.data.emergency_active = false
	GameState.data.emergency_monsters = 0
	GameState.data.emergency_damage = 0
	GameState.data.hp = 22
	GameState.data.recovery_active = true
	game.call("_load_lobby", false)
	await get_tree().create_timer(0.8).timeout
	await _shot("tide_recovery.png")
	# Final game-over capture: kill every remaining tree.
	for node in get_tree().get_nodes_in_group("forest_tree"):
		if node is ForestTree:
			var tree := node as ForestTree
			if tree.is_alive():
				tree.max_health = 10
				tree.health = 10
				tree.take_attack_damage(99)
	await get_tree().create_timer(0.35).timeout
	await _shot("tide_game_over.png")
	GameState.delete_save()
	print("captures done")
	get_tree().quit(0)


func _shot(name: String) -> void:
	for i in 4:
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	var path := shots.path_join(name)
	var err := img.save_png(path)
	print("shot -> %s (%s)" % [path, err])
