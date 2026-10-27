class_name ControlOceanChecks
extends RefCounted

static func run(game: Game, check: Callable, capture: Callable = Callable()) -> void:
	var snapshot := GameState.data.duplicate(true)
	var ticking := game.is_processing()
	game.set_process(false)
	GameState.data = GameState._make_default("adam")
	GameState._emit_all()
	game.hud.hide_modals()
	await game._load_lobby(false)
	await game.get_tree().process_frame
	var lobby := game.world as Lobby
	for actor in lobby.get_children():
		if actor is Enemy or actor is Resident: actor.set_physics_process(false)
	var player := game.player()
	var student := lobby.get_node("UniszaStudent") as UniszaStudent
	player.position = student.position + Vector2(0,1.1)
	player._update_nearby()
	game.hud._update_prompt()
	check.call(game.hud._interact_button.action == "sprint" and game.hud._interact_button.caption == "Sprint", "Sprint stays Sprint beside the yellow student; no Talk/Use action button")
	game.hud._interact_button._press()
	check.call(Input.is_action_pressed("sprint") and not Input.is_action_pressed("interact"), "pressing the permanent Sprint button never talks or boards")
	game.hud._interact_button.cancel()
	check.call(not Input.is_action_pressed("sprint"), "Sprint touch release clears the held action")
	await _tap(game, student.get_global_transform_with_canvas() * Vector2(0,-0.7))
	check.call(game.hud.dialogue_panel.visible, "yellow UniSZA student still opens by direct screen tap")
	game.hud.hide_modals()
	player.position = Vector2(23,30)
	player.set_physics_process(false)
	Input.action_press("move_right")
	Input.action_press("sprint")
	player._physics_process(0.2)
	check.call(player.sprinting and player.stamina < Player.STAMINA_MAX and player.velocity.length() > GameState.move_speed(), "Sprint raises movement speed and drains the stamina below HP")
	player._update_stamina(10)
	check.call(player.exhausted and player.stamina == 0, "exhausted stamina stops sprinting")
	Input.action_release("sprint")
	Input.action_release("move_right")
	player._update_stamina(1)
	player._update_stamina(2)
	check.call(not player.exhausted and player.stamina > 25, "stamina recovers at rest and allows sprinting again")
	var portal := lobby.get_node("MonsterBattlePortal") as PortalEntrance
	GameState.data.portals.tidebound_grotto.cleared = true
	portal._refresh()
	check.call(not portal._banner.visible and portal._banner.text.is_empty(), "cleared progress never adds CLEARED above the portal name")
	check.call(bool(GameState.portal_state("tidebound_grotto").get("cleared",false)), "removing the portal banner preserves saved clear progress")
	game.open_portals("tidebound_grotto")
	await game.get_tree().process_frame
	check.call(_no_clear_label(game.hud.portal_panel), "monster portal card titles never append CLEARED")
	game.hud.portal_panel.close_panel()
	GameState.data.pet_battles["pet_duel_1"] = true
	game.open_pet_battles()
	await game.get_tree().process_frame
	check.call(_no_clear_label(game.hud.pet_battle_panel), "pet portal card titles never append CLEARED")
	game.hud.pet_battle_panel.close_panel()
	if capture.is_valid(): await capture.call("01_permanent_sprint")
	var boarding := lobby.ship_boarding
	check.call(boarding.get_prompt().is_empty() and not boarding.show_marker, "boarding exposes no Board button, prompt or interaction marker")
	player.position = boarding.position + Vector2(4,0)
	lobby.camera.set_process(false)
	lobby.camera.set_physics_process(false)
	lobby.camera.global_position = boarding.position + Vector2(-2,-2)
	lobby.camera.force_update_scroll()
	lobby.camera.reset_physics_interpolation()
	await game.get_tree().process_frame
	await game.get_tree().physics_frame
	check.call(player.position.distance_to(boarding.position) > boarding.interact_radius, "ship test starts beyond the old Board interaction distance")
	var at := boarding.ship.get_global_transform_with_canvas() * (boarding.ship.get_rect().get_center()+Vector2(15,15))
	if capture.is_valid(): await capture.call("01b_ship_tap_target")
	print("Ship tap fixture: at=",at," input_locked=",game._input_locked," available=",boarding.available," player_dist=",player.position.distance_to(boarding.position))
	await _tap(game,at)
	check.call(game._sailing and boarding.passenger == player and player.controls_locked, "a real tap on the ship boards immediately without pressing another button")
	check.call(not game.board_ship(boarding,true), "repeated boarding requests cannot start a second sailing transition")
	game._clear_world()
	var ocean := OceanJourney.new()
	game.world = ocean
	game._world_holder.add_child(ocean)
	game.hud.set_world(ocean)
	game.hud.visible = false
	ocean.set_process(false)
	ocean._process(4)
	for action in ["move_right","move_left","move_up","move_down"]:
		var start := ocean.turtle.position
		Input.action_press(action)
		ocean._process(0.2)
		Input.action_release(action)
		var movement := ocean.turtle.position-start
		check.call(movement.x > 0 if action == "move_right" else (movement.x < 0 if action == "move_left" else (movement.y < 0 if action == "move_up" else movement.y > 0)), "turtle responds to %s" % action)
	check.call(ocean.player.position.distance_to(ocean.turtle.position) < 1.5, "rider follows horizontal and vertical turtle movement")
	var kinds := ocean.scenery.life.map(func(a: Dictionary) -> String: return str(a.kind))
	check.call(["fish","whale","megalodon","mermaid","diver"].all(func(kind: String) -> bool: return kind in kinds), "marine background includes fish, whale, megalodon, mermaid and scuba diver")
	check.call(ocean.scenery.z_index > 0 and ocean.scenery.get_child_count() >= 29, "marine creatures and the decorated seabed render above the ocean background")
	var trash := ocean.spawn_item("trash",ocean.turtle.position.x-3)
	ocean._update_run(0.1)
	check.call(not trash.resolved, "missed objects stay alive after passing the turtle")
	(trash.node as Sprite2D).position.x = ocean.visible_left()-8
	ocean._update_run(0)
	check.call(trash.resolved, "objects are removed only after fully leaving the screen")
	ocean._hurt_time = 0
	var shark := ocean.spawn_item("shark",ocean.turtle.position.x+0.5)
	var hp := ocean.health
	ocean._update_run(0.05)
	check.call(ocean.health == hp-1 and not shark.resolved, "open-jaw shark bites cost a life while the shark continues swimming")
	ocean._update_run(0.05)
	check.call(ocean.health == hp-1, "blinking protection prevents repeated shark damage")
	check.call(ocean.actionable_item().get("kind","") != "shark", "Pick Up and Eat cannot consume a shark")
	ocean._resolve_item(shark,false)
	ocean.stage = 2
	ocean.elapsed = OceanJourney.STAGE_SECONDS/2
	ocean._refresh_ui()
	check.call(is_equal_approx(ocean._progress.progress,0.5), "Adam-to-Arjun portrait timeline covers all three routes")
	if capture.is_valid():
		ocean._hurt_time = 0
		ocean.spawn_item("shark",27)
		ocean.spawn_item("heart",23)
		ocean.spawn_item("bomb",31)
		await capture.call("02_four_direction_ocean_life")
	GameState.data = snapshot
	GameState._emit_all()
	await game._load_lobby(false)
	game.hud.visible = true
	for frame in 3: await game.get_tree().physics_frame
	game.set_process(ticking)

static func _tap(game: Game, at: Vector2) -> void:
	var touch := InputEventScreenTouch.new()
	touch.index = 29
	touch.position = game.get_viewport().get_final_transform() * at
	touch.pressed = true
	Input.parse_input_event(touch)
	await game.get_tree().process_frame
	var release := InputEventScreenTouch.new()
	release.index = 29
	release.position = touch.position
	Input.parse_input_event(release)
	await game.get_tree().process_frame

static func _no_clear_label(node: Node) -> bool:
	if node is Label and node.text.contains("CLEARED"): return false
	for child in node.get_children():
		if not _no_clear_label(child): return false
	return true
