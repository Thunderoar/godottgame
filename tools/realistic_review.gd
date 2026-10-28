extends Node
## Actual renderer captures. Only the wrapper's verified disposable save is used.
var _checks := 0
var _failures := 0
var _directory := ""

func _ready() -> void:
	if not TestEnvironment.require_isolation(): get_tree().quit(1); return
	_directory=OS.get_environment("TIDESWORN_TEST_ROOT")
	GameState.autosave_enabled=false
	GameState.new_game("adam")
	GameState.data.mission_step=MissionDB.STEPS.size()
	GameState.data.world_time=90.0
	var game := load("res://scenes/game.tscn").instantiate() as Game
	add_child(game)
	game._remove_title()
	await game._load_lobby(false)
	game.set_process(false)
	game.hud.tutorial_guide.hide()
	await preload("res://tools/realistic_checks.gd").run(game,_check)
	var home := game.world as Lobby
	home.set_process(false)
	for actor in home.get_children():
		if actor is Resident or actor is Player or actor is Pet: actor.set_physics_process(false)
	home.camera.set_physics_process(false)
	home.camera.set_process(false)
	game.hud.hide()
	for view in [["village",Vector2(32,20),18.0],["market",Vector2(28,20),32.0],["coast",Vector2(17,29),32.0],["forest",Vector2(48,18),28.0]]:
		home.camera.position=view[1]
		home.camera.zoom=Vector2.ONE*float(view[2])
		await _capture(str(view[0]))
	GameState.data.world_time=240.0
	home._update_daylight()
	home.camera.position=Vector2(27,20)
	home.camera.zoom=Vector2.ONE*28
	await _capture("village_night")
	GameState.data.world_time=90.0
	home._update_daylight()
	game.hud.show()
	for kind in RealisticArt.SHOPS:
		var panel: ModalBase=game.hud.shop_panel
		if kind=="house":
			game.open_house()
			panel=game.hud.house_panel
		elif kind=="services":
			game.open_village_services()
			panel=game.hud.village_services_panel
		else: game.open_shop(kind,kind.capitalize()+" Keeper")
		await get_tree().process_frame
		await get_tree().process_frame
		if kind in ["house","services"]:
			_check(is_instance_valid(panel.get("_band")) and panel.get("_band").shop_type==kind,"%s interaction opens its actual matching merchant panel" % kind)
		await _capture("shop_"+kind)
		panel.hide()
		game._on_modal_closed()
	game.open_pet_battles()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(game.hud.pet_battle_panel.start_battle("pet_duel_1"),"realistic pet duel starts with normal battle rules")
	game.hud.pet_battle_panel.set_process(false)
	await get_tree().process_frame
	_check(is_instance_valid(game.hud.pet_battle_panel._arena_backdrop) and game.hud.pet_battle_panel._arena_backdrop.size.x>500,"duel background covers the arena after layout")
	await _capture("pet_duel")
	game.hud.pet_battle_panel.hide()
	game._on_modal_closed()
	await game.enter_home()
	await _capture("home_interior")
	await game.leave_home()
	game._clear_world()
	await get_tree().process_frame
	var ocean := OceanJourney.new()
	game.world=ocean
	game._world_holder.add_child(ocean)
	game.hud.hide()
	ocean.set_process(false)
	ocean._process(4)
	await _capture("sea_tutorial")
	ocean.dismiss_sea_guide()
	for pair in [["food",18],["trash",22],["bomb",26],["shark",31],["heart",35]]: ocean.spawn_item(str(pair[0]),float(pair[1]))
	await _capture("sea_swimming")
	get_window().size=Vector2i(832,480)
	await get_tree().process_frame
	ocean.show_sea_guide()
	await _capture("sea_tutorial_832x480")
	get_window().size=Vector2i(1280,720)
	game._clear_world()
	await get_tree().process_frame
	var island := KrakenIsland.new()
	game.world=island
	game._world_holder.add_child(island)
	island.set_process(false)
	island.boss.set_physics_process(false)
	island.player.set_physics_process(false)
	await _capture("kraken_island")
	print("realistic review: %d checks, %s" % [_checks,"PASS" if _failures==0 else "FAIL"])
	get_tree().quit(0 if _failures==0 else 1)

func _check(ok: bool, message: String) -> void:
	_checks+=1
	if not ok: _failures+=1
	print("[OK] " if ok else "[FAIL] ",message)

func _capture(label: String) -> void:
	await get_tree().create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_directory.path_join(label+".png"))
