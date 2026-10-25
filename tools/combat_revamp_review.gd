extends Node
## Reproducible renderer fixtures; source assets and real player data are untouched.
var game: Game
var _output := ""

func _ready() -> void:
	if not TestEnvironment.require_isolation():
		get_tree().quit(1)
		return
	_output = OS.get_environment("TIDESWORN_TEST_ROOT").path_join("shots")
	DirAccess.make_dir_recursive_absolute(_output)
	GameState.autosave_enabled = false
	game = load("res://scenes/game.tscn").instantiate() as Game
	add_child(game)
	await get_tree().process_frame
	game.title_screen._start_button.pressed.emit()
	await _shot("01_heroes")
	await game._on_character_selected("adam")
	game.set_process(false)
	game.hud.tutorial_guide._skip()
	_freeze(game.world)
	GameState.add_gold(2000)
	for duel in PetBattleDB.ordered_ids():
		GameState.complete_pet_battle(duel)
	GameState.buy_roof_gun("cottage")
	await get_tree().process_frame
	for gun in get_tree().get_nodes_in_group("roof_guns"):
		gun._process(0.0)
	game.world.camera.global_position = game.world._house_position + Vector2(0, 1)
	game.world.camera.reset_smoothing()
	await _shot("02_village_guardians_gun")
	game.open_house()
	await _shot("03_machine_gun_shop")
	game.hud.house_panel.close_panel()
	await game.enter_home()
	await _shot("04_main_house_bed")
	await game.leave_home()
	for hero in ["mei_ling", "arjun"]:
		GameState.new_game(hero)
		game._load_lobby(false)
		await get_tree().process_frame
		_freeze(game.world)
		game.hud.tutorial_guide._skip()
		game.world.camera.global_position = game.player().position
		game.world.camera.reset_smoothing()
		game.player().controls_locked = false
		game.player().facing = Vector2.RIGHT
		game.player().try_attack()
		game.player()._update_attack_phase(1.0)
		await _shot("05_" + hero + "_basic_attack")
	game.open_settings()
	await _shot("05c_settings_no_skills")
	game.hud.settings_panel.close_panel()
	game.open_shop("potion", "Mara")
	await _shot("05d_health_potion_shop")
	game.hud.shop_panel.close_panel()
	game.open_inventory()
	await _shot("05e_pack_no_mana")
	game.hud.inventory_panel.close_panel()
	GameState.start_expedition("tidebound_grotto")
	game._load_dungeon("tidebound_grotto", false)
	await get_tree().process_frame
	_freeze(game.world)
	game.world.camera.zoom = Vector2.ONE * 30
	game.world.camera.global_position = Vector2(24, 17)
	game.world.camera.reset_smoothing()
	for trap in get_tree().get_nodes_in_group("dungeon_hazards"):
		trap.clock = 1.2
		trap.queue_redraw()
	await _shot("06_boss_arrival_traps")
	GameState.leave_portal_safely()
	game._load_lobby(false)
	await get_tree().process_frame
	_freeze(game.world)
	game.open_pet_battles()
	await get_tree().create_timer(0.3).timeout
	game.hud.pet_battle_panel.start_battle("pet_duel_1")
	await _shot("07_english_pet_duel")
	game.hud.pet_battle_panel._finish_battle(true)
	await _shot("08_pet_recruit_reward")
	game.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	print("combat revamp review: PASS")
	get_tree().quit(0)

func _shot(id: String) -> void:
	await get_tree().create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_output.path_join(id + ".png"))
	print("Fixture: ", id)

func _freeze(node: Node) -> void:
	node.set_process(false)
	node.set_physics_process(false)
	for child in node.get_children():
		_freeze(child)
