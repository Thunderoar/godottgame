class_name ControlOceanChecks
extends RefCounted

static func run(game: Game, check: Callable, capture: Callable = Callable()) -> void:
	var snapshot := GameState.data.duplicate(true)
	var ticking := game.is_processing()
	game.set_process(false)
	GameState.data = GameState._make_default("adam")
	GameState.data.portal_origin.opened = true # Existing combat/UI fixture starts after waystone restoration.
	GameState._emit_all()
	game.hud.hide_modals()
	await game._load_lobby(false)
	await game.get_tree().process_frame
	var lobby := game.world as Lobby
	for actor in lobby.get_children():
		if actor is Enemy or actor is Resident: actor.set_physics_process(false)
	var player := game.player()
	var student := lobby.get_node("UniszaStudent") as UniszaStudent
	await _context_actions(game, student, check, capture)
	lobby = game.world as Lobby
	player = game.player()
	student = lobby.get_node("UniszaStudent") as UniszaStudent
	player.position = student.position + Vector2(0,1.1)
	player._update_nearby()
	game.hud._update_prompt()
	check.call(game.hud._interact_button.action == "interact" and game.hud._interact_button.caption == "Talk", "Sprint becomes Talk beside the yellow student")
	game.hud._interact_button._press()
	check.call(Input.is_action_pressed("interact") and not Input.is_action_pressed("sprint"), "Talk presses the interaction action without sprinting")
	game.hud._interact_button.cancel()
	check.call(not Input.is_action_pressed("interact"), "Talk touch release clears the held action")
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
	player._update_nearby()
	game.hud._update_prompt()
	if capture.is_valid(): await capture.call("01_context_sprint")
	var boarding := lobby.ship_boarding
	player.position = boarding.position
	player._update_nearby()
	game.hud._update_prompt()
	check.call(game.hud._interact_button.caption == "Enter" and game.hud._interact_button.action == "interact", "nearby ship exposes Enter on the shared action button")
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
	ocean.dismiss_sea_guide()
	var full_moves: Array[float] = []
	for action in ["move_right","move_left","move_up","move_down"]:
		var start := ocean.turtle.position
		Input.action_press(action)
		ocean._process(0.2)
		Input.action_release(action)
		var movement := ocean.turtle.position-start
		full_moves.append(movement.length())
		check.call(movement.x > 0 if action == "move_right" else (movement.x < 0 if action == "move_left" else (movement.y < 0 if action == "move_up" else movement.y > 0)), "turtle responds to %s" % action)
	check.call(full_moves.all(func(distance: float) -> bool: return is_equal_approx(distance, OceanJourney.VERTICAL_SPEED * 0.2)), "forward, reverse and vertical swimming have the same fast speed")
	var fast_scroll := ocean.speed()
	ocean.fullness = OceanJourney.FAST_FULLNESS_THRESHOLD
	check.call(ocean.fullness_speed_multiplier() == 1.0, "50 percent fullness keeps the fast movement tier")
	ocean.fullness = 40
	check.call(is_equal_approx(ocean.speed(),fast_scroll * OceanJourney.HUNGRY_SPEED_MULTIPLIER), "below 50 percent fullness slows ocean travel by the same movement multiplier")
	for action in ["move_right","move_left","move_up","move_down"]:
		var start := ocean.turtle.position
		Input.action_press(action)
		ocean._process(0.1)
		Input.action_release(action)
		check.call(is_equal_approx(ocean.turtle.position.distance_to(start),OceanJourney.VERTICAL_SPEED * OceanJourney.HUNGRY_SPEED_MULTIPLIER * 0.1), "hungry swimming consistently slows %s" % action)
	ocean.fullness = 75
	check.call(ocean.swim_speed() > ocean.speed(), "fed reverse steering can catch rubbish drifting behind the turtle")
	var diagonal_start := ocean.turtle.position
	Input.action_press("move_right")
	Input.action_press("move_up")
	ocean._process(0.1)
	Input.action_release("move_right")
	Input.action_release("move_up")
	check.call(is_equal_approx(ocean.turtle.position.distance_to(diagonal_start),ocean.swim_speed()*0.1), "diagonal steering is normalized to the same swim speed")
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
	ocean.stage = 2 # Sharks are introduced only in the second sea level.
	var shark := ocean.spawn_item("shark",ocean.turtle.position.x+0.5)
	var hp := ocean.health
	ocean._update_run(0.05)
	check.call(ocean.health == hp-1 and not shark.resolved, "open-jaw shark bites cost a life while the shark continues swimming")
	ocean._update_run(0.05)
	check.call(ocean.health == hp-1, "blinking protection prevents repeated shark damage")
	check.call(ocean.actionable_item().get("kind","") != "shark", "Pick Up cannot consume a shark")
	ocean._resolve_item(shark,false)
	ocean.stage = 2
	ocean.elapsed = OceanJourney.STAGE_SECONDS/2
	ocean._refresh_ui()
	check.call(is_equal_approx(ocean._progress.progress,0.75), "halfway through level two is 75 percent of the two-level portrait timeline")
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
	await game.get_tree().physics_frame
	await game.get_tree().physics_frame
	var release := InputEventScreenTouch.new()
	release.index = 29
	release.position = touch.position
	Input.parse_input_event(release)
	await game.get_tree().process_frame
	await game.get_tree().physics_frame

static func _context_actions(game: Game, student: UniszaStudent, check: Callable, capture: Callable) -> void:
	var hud := game.hud
	var button := hud._interact_button
	var player := game.player()
	player.position = Vector2(23,30)
	player._update_nearby()
	hud._update_prompt()
	check.call(button.caption == "Sprint" and button.action == "sprint", "clear ground keeps the Sprint action")
	button._press()
	player.position = student.global_position
	player.velocity = Vector2.ZERO
	player._update_nearby()
	hud._update_prompt()
	check.call(button.caption == "Talk" and not Input.is_action_pressed("sprint") and not Input.is_action_pressed("interact") and not hud.dialogue_panel.visible, "approaching an NPC releases held Sprint and requires a fresh Talk press")
	if capture.is_valid(): await capture.call("00a_talk")
	await _tap(game, button.get_global_rect().get_center())
	hud._update_prompt()
	check.call(hud.dialogue_panel.visible and button.caption == "Exit" and button.action.is_empty(), "actual touch Talk opens dialogue and changes the same button to Exit")
	await _tap(game, button.get_global_rect().get_center())
	check.call(not hud.dialogue_panel.visible and not game._input_locked and not Input.is_action_pressed("interact"), "actual touch Exit closes dialogue without reopening it or holding interaction")
	var shop: ShopNPC
	var entrance: HomeEntrance
	var portal: PortalEntrance
	for node in game.get_tree().get_nodes_in_group("interactable"):
		if not game.world.is_ancestor_of(node): continue
		if node is ShopNPC and node.shop_type == "potion": shop = node
		if node is HomeEntrance: entrance = node
		if node is PortalEntrance and node.gate_kind == "monster": portal = node
	player.global_position = shop.global_position
	player.velocity = Vector2.ZERO
	player._update_nearby()
	hud._update_prompt()
	check.call(button.caption == "Enter", "nearby shop changes the action to Enter")
	await _tap(game, button.get_global_rect().get_center())
	hud._update_prompt()
	check.call(hud.shop_panel.visible and button.caption == "Exit", "touch Enter opens the shop with a shared Exit button")
	if capture.is_valid(): await capture.call("00b_shop_exit")
	await _tap(game, button.get_global_rect().get_center())
	check.call(not hud.shop_panel.visible and not game._input_locked, "touch Exit leaves the shop and restores world control")
	player.global_position = portal.global_position
	player.velocity = Vector2.ZERO
	player._update_nearby()
	hud._update_prompt()
	check.call(button.caption == "Enter", "nearby dimension portal changes the action to Enter")
	player.global_position = entrance.global_position
	player.velocity = Vector2.ZERO
	player._update_nearby()
	hud._update_prompt()
	check.call(button.caption == "Enter", "nearby cottage changes the action to Enter")
	await _tap(game, button.get_global_rect().get_center())
	for frame in 120:
		if not game._transitioning: break
		await game.get_tree().physics_frame
	check.call(is_instance_valid(game.home_interior), "touch Enter goes inside the cottage")
	if is_instance_valid(game.home_interior):
		player.global_position = game.home_interior._exit.global_position + Vector2(0,-1.6)
		player.velocity = Vector2.ZERO
		player._update_nearby()
		hud._update_prompt()
		check.call(button.caption == "Exit" and button.action == "interact", "inside cottage doorway changes the action to Exit")
		if capture.is_valid(): await capture.call("00c_home_exit")
		check.call(is_instance_valid(game.home_interior) and not game._transitioning, "Exit remains available before crossing the automatic doorway footprint")
		await _tap(game, button.get_global_rect().get_center())
		for frame in 120:
			if not game._transitioning: break
			await game.get_tree().physics_frame
		check.call(not is_instance_valid(game.home_interior) and not game._input_locked, "touch Exit returns from cottage to the village")
	player.position = Vector2(23,30)
	player._update_nearby()
	hud._update_prompt()
	button._press()
	button._notification(Control.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	check.call(not Input.is_action_pressed("sprint") and not button._active, "focus loss releases the shared Sprint action")
	# Ignore actors from a retiring world even if their old position overlaps.
	var stale := Interactable.new()
	stale.prompt = "Talk to a retired actor"
	game.add_child(stale)
	stale.global_position = player.global_position
	player._update_nearby()
	hud._update_prompt()
	check.call(player.nearby != stale and button.caption == "Sprint", "retired-world actors cannot take over the context button")
	stale.queue_free()
	player.global_position = portal.global_position
	player.velocity = Vector2.ZERO
	player._update_nearby()
	hud._update_prompt()
	await _tap(game, button.get_global_rect().get_center())
	for frame in 180:
		if game.world is TwilightRealm and not game._transitioning and not game._portal_fx_active: break
		await game.get_tree().physics_frame
	check.call(game.world is TwilightRealm, "touch Enter travels through the dimension portal")
	if game.world is TwilightRealm:
		var exit: RealmInteractable
		for node in game.world.get_children():
			if node is RealmInteractable and node.kind == "exit": exit = node
		player = game.player()
		player.global_position = exit.global_position
		player.velocity = Vector2.ZERO
		player._update_nearby()
		hud._update_prompt()
		check.call(button.caption == "Exit", "realm shore gate changes the action to Exit")
		if capture.is_valid(): await capture.call("00d_portal_exit")
		await _tap(game, button.get_global_rect().get_center())
		for frame in 180:
			if game.world is Lobby and not game._transitioning: break
			await game.get_tree().physics_frame
		check.call(game.world is Lobby and not game._input_locked, "touch Exit returns safely from the realm")

static func _no_clear_label(node: Node) -> bool:
	if node is Label and node.text.contains("CLEARED"): return false
	for child in node.get_children():
		if not _no_clear_label(child): return false
	return true
