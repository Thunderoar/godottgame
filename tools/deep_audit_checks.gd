class_name DeepAuditChecks
extends RefCounted
## Behavioral edge cases missed by the initial visual repair suite.

static func run(game: Node, check: Callable) -> void:
	var tree := game.get_tree()
	var hud: GameHUD = game.hud
	var lobby: Lobby = game.world
	var old_scale := hud.get_gui_scale()
	var old_layout := GameState.control_layout()
	var old_locked := lobby.player.controls_locked
	lobby.player.controls_locked = true
	for monster in lobby._forest_monsters:
		monster.set_physics_process(false)
	for resident in lobby._residents:
		resident.set_physics_process(false)
		resident._end_visit()
	lobby.pet.set_physics_process(false)
	lobby._rubbish_system.set_process(false)
	var joy := hud._joystick
	# Migration must become a device preference before an old journey is removed.
	var old_config := GameSettings.config_path
	var settings_before: Dictionary = GameState.data.settings.duplicate(true)
	GameSettings.config_path = "user://audit_legacy_settings.cfg"
	GameState.data.settings.gui_scale = 1.25
	GameSettings.load_settings()
	GameState.data.settings.gui_scale = 1.0
	GameSettings.load_settings()
	check.call(GameSettings.ui_scale() == 125, "audit: legacy GUI migration persists independently of a later new journey")
	GameState.data.settings = settings_before
	GameSettings.config_path = old_config
	GameSettings.load_settings()
	for gui in [0.75, 1.0, 1.3]:
		hud.set_gui_scale(gui, false)
		await tree.process_frame
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = true
		event.position = joy.size * 0.5
		# _gui_input's position is already local; engine dispatches it this way.
		joy._gui_input(event)
		check.call(joy._value.length() < 0.01, "audit: joystick centre stays neutral at GUI %.2f" % gui)
		joy._end()
		event.position = joy.size * 0.5 + Vector2(joy.radius * 0.75, 0)
		joy._gui_input(event)
		check.call(joy._value.x > 0.65 and absf(joy._value.y) < 0.01, "audit: joystick right press has no vertical component at GUI %.2f" % gui)
		joy._end()
		var touch := InputEventScreenTouch.new()
		touch.index = 77
		touch.pressed = true
		touch.position = joy.size * 0.5 + Vector2(joy.radius * 0.75, 0)
		joy._gui_input(touch)
		var drag := InputEventScreenDrag.new()
		drag.index = 77
		drag.position = joy.get_global_transform_with_canvas() * touch.position
		var value := joy._value
		joy._input(drag)
		check.call(joy._value.distance_to(value) < 0.01, "audit: press and drag use consistent coordinate spaces at GUI %.2f" % gui)
		joy._end()
	hud.set_gui_scale(1.0, false)
	joy._begin(joy.size * 0.5 + Vector2(50, 0))
	joy.hide()
	check.call(not joy._active and not Input.is_action_pressed("move_right"), "audit: hidden joystick releases synthetic movement input")
	joy.show()
	var touch_button := TouchActionButton.new()
	touch_button.action = "attack"
	hud._root.add_child(touch_button)
	touch_button._press()
	touch_button.queue_free()
	await tree.process_frame
	check.call(not Input.is_action_pressed("attack"), "audit: freed touch button releases its synthetic action")
	hud.set_control_layout("attack", 500, 300, 220)
	hud.set_control_layout("joystick", 20, 400, 260)
	hud.reset_control_layout()
	await tree.process_frame
	check.call(hud._attack_button.size.is_equal_approx(Vector2(102, 102)), "audit: resetting enlarged Strike restores its actual rectangle")
	check.call(joy.size.is_equal_approx(Vector2(190, 190)), "audit: resetting enlarged joystick restores its actual rectangle")
	# Translate the unchanged obstacle fixtures into the clear western pasture.
	# Their old (35,36) site is now the authored farmhouse; never test through it.
	# A cached route must change after editor invalidation, even with the same goal.
	var walker := Resident.new()
	walker.resident_name = "Audit walker"
	walker.position = Vector2(26, 36)
	lobby.add_child(walker)
	walker.set_physics_process(false)
	walker._walk_to(Vector2(32, 36), 1.0, 1.0 / 60.0)
	var blocker := _box(lobby, Vector2(28, 36), Vector2(1, 1))
	await tree.physics_frame
	await tree.physics_frame
	lobby._resident_routes.invalidate()
	walker._walk_to(Vector2(32, 36), 1.0, 1.0 / 60.0)
	var crosses_block := false
	for point in walker._path:
		crosses_block = crosses_block or Rect2(27.5, 35.5, 1, 1).has_point(point)
	check.call(not crosses_block, "audit: resident replans cached path after obstacles change")
	var clear_segments := true
	var cursor := walker.global_position
	for point in walker._path:
		clear_segments = clear_segments and lobby._resident_routes.segment_clear(cursor, point)
		cursor = point
	check.call(clear_segments, "audit: planned corner segments respect actor collision clearance")
	walker.queue_free()
	blocker.queue_free()
	await tree.physics_frame
	await tree.physics_frame
	lobby._resident_routes.invalidate()
	# Let a moving pet negotiate a real blocking wall, including both ends of its path.
	var p := lobby.player
	var player_at := p.global_position
	var player_facing := p.facing
	var pet_at := lobby.pet.global_position
	p.global_position = Vector2(31, 36)
	p.facing = Vector2.RIGHT
	p.reset_physics_interpolation()
	lobby.pet.global_position = Vector2(26, 36.5)
	lobby.pet._follow_velocity = Vector2.ZERO
	lobby.pet._follow_path.clear()
	lobby.pet._route_timer = 0.0
	lobby.pet.reset_physics_interpolation()
	blocker = _box(lobby, Vector2(28, 36), Vector2(1, 2))
	await tree.physics_frame
	await tree.physics_frame
	lobby.invalidate_resident_routes()
	var pet_continuous := true
	var crossed_wall := false
	for frame in 300:
		await tree.physics_frame
		var before := lobby.pet.global_position
		lobby.pet._follow(1.0 / float(Engine.physics_ticks_per_second))
		pet_continuous = pet_continuous and before.distance_to(lobby.pet.global_position) <= 0.155
		crossed_wall = crossed_wall or Rect2(27.5, 35, 1, 2).has_point(lobby.pet.global_position)
	check.call(lobby.pet.global_position.distance_to(p.global_position + Vector2(-0.95, 0.5)) < 0.5, "audit: pet completes a detour around a blocking wall")
	check.call(pet_continuous and not crossed_wall, "audit: pet detour stays continuous and does not cross the wall")
	blocker.queue_free()
	await tree.physics_frame
	await tree.physics_frame
	lobby.invalidate_resident_routes()
	p.global_position = player_at
	p.facing = player_facing
	p.reset_physics_interpolation()
	lobby.pet.global_position = pet_at
	lobby.pet.reset_physics_interpolation()
	# A newly fallen tree invalidates the shared grid after disabling collision.
	var tree_fixture := ForestTree.new()
	tree_fixture.position = Vector2(28, 36)
	tree_fixture.felled.connect(lobby._on_forest_tree_felled)
	var trunk := StaticBody2D.new()
	trunk.name = "Body"
	var trunk_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 0.45
	trunk_shape.shape = circle
	trunk.add_child(trunk_shape)
	tree_fixture.add_child(trunk)
	lobby.add_child(tree_fixture)
	await tree.physics_frame
	await tree.physics_frame
	lobby.invalidate_resident_routes()
	lobby.resident_path(Vector2(26, 36), Vector2(32, 36))
	var old_revision := lobby.resident_routes_revision()
	tree_fixture.take_attack_damage(999)
	await tree.physics_frame
	await tree.physics_frame
	check.call(lobby.resident_routes_revision() > old_revision and lobby._resident_routes.point_clear(tree_fixture.global_position), "audit: tree falling invalidates route obstacles after releasing its collider")
	tree_fixture.queue_free()
	# An occupied counter is not a valid shopping destination, even if a nearby cell is free.
	var shops := tree.get_nodes_in_group("ambient_shop")
	var shop := shops[0] as ShopNPC
	blocker = _box(lobby, shop.customer_position(), Vector2(1.4, 1.4))
	await tree.physics_frame
	await tree.physics_frame
	lobby._resident_routes.invalidate()
	var customer := Resident.new()
	customer.resident_name = "Audit customer"
	customer.position = shop.customer_position() + Vector2(0, 1.8)
	customer.waypoints = [customer.position]
	lobby.add_child(customer)
	customer.set_physics_process(false)
	for seed_value in 100:
		var random := RandomNumberGenerator.new()
		random.seed = seed_value
		random.randf_range(24, 50)
		if random.randi_range(0, shops.size() - 1) == 0:
			customer._shopping_rng.seed = seed_value
			break
	customer.begin_shop_visit()
	check.call(customer._shop != shop, "audit: shopper rejects an obstructed counter instead of buying at a fallback point")
	customer._end_visit()
	customer.queue_free()
	blocker.queue_free()
	await tree.physics_frame
	await tree.physics_frame
	lobby._resident_routes.invalidate()
	# A direct attack must release a customer's slot just like an emergency signal.
	customer = Resident.new()
	customer.resident_name = "Audit attacked shopper"
	customer.position = shop.customer_position() + Vector2(0, 1.8)
	lobby.add_child(customer)
	customer.set_physics_process(false)
	customer.begin_shop_visit()
	var reserved := customer._shop
	customer.take_attack_damage(1)
	check.call(customer.shopping_state == Resident.Shopping.ROUTINE and (reserved == null or reserved._customer == null), "audit: directly frightened customer releases its shop reservation")
	customer.queue_free()
	# Merchants are now seated behind the stall counter rather than outside it.
	var counter_art := shop.get_parent().get_children().filter(func(node: Node) -> bool: return node is Sprite2D)[0] as Sprite2D
	check.call(shop.position.y < 0 and _effective_z(shop.sprite) < _effective_z(counter_art), "audit: merchant is inside the stall behind its counter art")
	# Low->high must work without rebuilding the dungeon.
	var old_quality := GameSettings.effects_quality()
	var old_motion := GameSettings.reduce_motion()
	var ward := lobby._recovery_ward
	check.call(RecoveryWard.OUTER_WIDTH * 64.0 <= 4.1 and SettlementEditor.BORDER_WIDTH * 64.0 <= 4.1 and SettlementEditor.GRID_WIDTH * 64.0 <= 2.1 and lobby._placeables[0]._outline.width * 64.0 <= 4.1, "audit: ward, build grid and selection outlines stay proportionate at maximum zoom")
	GameSettings.set_reduce_motion(true, false)
	var ward_time := ward._t
	ward._process(0.25)
	check.call(ward._t == ward_time, "audit: Reduce Motion stops optional recovery ward rotation and pulse")
	GameSettings.set_effects_quality("low", false)
	GameSettings.set_reduce_motion(false, false)
	var dungeon := Dungeon.new()
	dungeon.setup("tidebound_grotto")
	game.add_child(dungeon)
	dungeon.set_process(false)
	for child in dungeon.get_children():
		child.set_physics_process(false)
	GameSettings.set_effects_quality("high", false)
	dungeon._process(1.0 / 60.0)
	check.call(dungeon._ambient != null and dungeon._ambient.emitting, "audit: enabling high effects creates dungeon ambience live")
	var ambient := dungeon._ambient
	GameSettings.set_reduce_motion(true, false)
	dungeon._process(1.0 / 60.0)
	check.call(not ambient.visible and not ambient.emitting, "audit: Reduce Motion immediately hides existing dungeon particles")
	GameSettings.set_reduce_motion(false, false)
	dungeon._process(1.0 / 60.0)
	check.call(dungeon._ambient == ambient and ambient.visible, "audit: dungeon restores the same emitter without allocation churn")
	dungeon.queue_free()
	await tree.process_frame
	await tree.process_frame
	GameSettings.set_effects_quality(old_quality, false)
	GameSettings.set_reduce_motion(old_motion, false)
	# Optional hit-stop may freeze a pose, never the simulation/cooldowns.
	var cooldowns: Array[float] = []
	var travel: Array[float] = []
	for reduced in [false, true]:
		GameSettings.set_effects_quality("high", false)
		GameSettings.set_reduce_motion(reduced, false)
		var enemy := Enemy.new()
		enemy.position = Vector2(33, 36)
		lobby.add_child(enemy)
		enemy.set_physics_process(false)
		enemy._state = Enemy.State.RECOVER
		enemy._state_time = 1.0
		enemy._attack_timer = 1.0
		enemy.velocity = Vector2(1, 0)
		var start := enemy.global_position
		Vfx.hit_stop([enemy], 0.08)
		for frame in 6:
			await tree.physics_frame
			enemy._physics_process(1.0 / float(Engine.physics_ticks_per_second))
		cooldowns.append(enemy._attack_timer)
		travel.append(start.distance_to(enemy.global_position))
		enemy.queue_free()
		await tree.process_frame
	check.call(absf(cooldowns[0] - cooldowns[1]) < 0.001, "audit: Reduce Motion never changes enemy attack cooldown progression")
	check.call(absf(travel[0] - travel[1]) < 0.001, "audit: optional hit-stop never changes ordinary enemy travel")
	GameSettings.set_effects_quality(old_quality, false)
	GameSettings.set_reduce_motion(old_motion, false)
	# Deferred world deletion must never steal effects into a dying pool.
	var old_pool := Vfx.ensure_pool(lobby)
	old_pool.queue_free()
	var effect_world := Node2D.new()
	game.add_child(effect_world)
	var doomed_world := Node2D.new()
	game.add_child(doomed_world)
	Vfx.ensure_pool(doomed_world)
	doomed_world.queue_free()
	var live_pool := Vfx.ensure_pool(effect_world)
	check.call(Vfx.pool() == live_pool, "audit: VFX skips queued pools and children of queued worlds")
	effect_world.queue_free()
	await tree.process_frame
	Vfx.ensure_pool(lobby)
	if DisplayServer.get_name() != "headless":
		await _check_physical_layout(game, check)
	# Put every live control and world controller back into its incoming state.
	hud.reset_control_layout()
	for control_id in old_layout:
		var values: Dictionary = old_layout[control_id]
		hud.set_control_layout(control_id, float(values.x), float(values.y), float(values.size))
	hud.set_gui_scale(old_scale, false)
	for monster in lobby._forest_monsters:
		monster.set_physics_process(true)
	for resident in lobby._residents:
		resident.set_physics_process(true)
	lobby.player.controls_locked = old_locked
	lobby.pet.set_physics_process(true)
	lobby._rubbish_system.set_process(true)
	await _check_home_defeat(game, check)


static func _check_home_defeat(game: Node, check: Callable) -> void:
	var saved: Dictionary = GameState.data.duplicate(true)
	var locked: bool = game.player().controls_locked
	var old_home: Lobby = game.world
	var old_deaths := int(saved.get("deaths", 0))
	game.player().invulnerable = 0.0
	game.player().take_damage(GameState.health_max() * 10)
	# Repeated signal delivery must not double-count or start a second transition.
	GameState.player_defeated.emit()
	var deadline := Time.get_ticks_msec() + 6000
	while Time.get_ticks_msec() < deadline:
		await game.get_tree().process_frame
		if game.world != old_home and not game._transitioning:
			break
	var alive: bool = game.world is Lobby and game.world != old_home and not game.player().dead and GameState.health() > 0
	check.call(alive, "audit: lethal lobby damage returns a living player to recovery")
	check.call(GameState.recovery_active() and int(GameState.data.deaths) == old_deaths + 1 and not game._defeat_pending, "audit: home defeat starts exactly one completed recovery transition")
	check.call(GameState.data.inventory == saved.inventory and GameState.data.gold == saved.gold and GameState.data.diamonds == saved.diamonds and GameState.data.xp == saved.xp, "audit: home recovery preserves inventory, currencies and player progression")
	# Restore this fixture so later acceptance scenarios begin with the same state.
	GameState.data = saved
	GameState.data_changed.emit()
	GameState.pet_changed.emit()
	if game.world is Lobby:
		game.world._recovery_ward.set_active(GameState.recovery_active())
		game.world._rubbish_system.spawn_interval = 99999.0
		game.world._rubbish_system.set("_timer", 0.0)
		game.player().controls_locked = locked


static func _box(world: Node2D, at: Vector2, extent: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = at
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = extent
	shape.shape = rect
	body.add_child(shape)
	world.add_child(body)
	return body


static func _effective_z(node: CanvasItem) -> int:
	var result := node.z_index
	if node.z_as_relative and node.get_parent() is CanvasItem:
		result += _effective_z(node.get_parent())
	return result


static func _check_physical_layout(game: Node, check: Callable) -> void:
	var hud: GameHUD = game.hud
	var window := game.get_window()
	var old_size := window.size
	for resolution in [Vector2i(1280, 720), Vector2i(832, 468), Vector2i(832, 480)]:
		hud.set_gui_scale(0.75, false)
		window.size = resolution
		for frame in 3:
			await game.get_tree().process_frame
		var resized_scale := minf(float(window.size.x) / hud._root.size.x, float(window.size.y) / hud._root.size.y)
		check.call(hud._health_potion_button.get_global_rect().size.x * resized_scale >= 43.9, "audit: window resize refreshes physical hit areas without changing GUI scale at %dx%d" % [resolution.x, resolution.y])
		for gui in [0.75, 1.0, 1.3]:
			hud.set_gui_scale(gui, false)
			await game.get_tree().process_frame
			var display_scale := minf(float(window.size.x) / hud._root.size.x, float(window.size.y) / hud._root.size.y)
			var accessible := true
			for control: Control in hud._control_nodes.values():
				var extent := control.get_global_rect().size * display_scale
				accessible = accessible and minf(extent.x, extent.y) >= 43.9
			accessible = accessible and hud._menu_button.get_global_rect().size.y * display_scale >= 43.9
			check.call(accessible, "audit: physical touch minimum at %dx%d GUI %.2f" % [resolution.x, resolution.y, gui])
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			click.pressed = true
			click.position = hud._joystick.get_global_transform_with_canvas() * (hud._joystick.size * 0.5)
			click.global_position = click.position
			window.push_input(click, true)
			await game.get_tree().process_frame
			check.call(hud._joystick._active and hud._joystick._value.length() < 0.01, "audit: native GUI dispatch keeps a centred joystick neutral at %dx%d GUI %.2f" % [resolution.x, resolution.y, gui])
			click = click.duplicate()
			click.pressed = false
			window.push_input(click, true)
			hud._joystick.cancel()
			hud.set_control_layout("attack", 500, 300, 102)
			var pack_right := hud._inventory_button.get_global_rect().end.x
			check.call(hud._build_button.position.x >= pack_right, "audit: customizing Strike preserves Pack/Build separation at GUI %.2f" % gui)
			hud.reset_control_layout()
	window.size = old_size
	for frame in 3:
		await game.get_tree().process_frame

	var shot_dir := OS.get_environment("TIDESWORN_AUDIT_SHOTS")
	if not shot_dir.is_empty():
		DirAccess.make_dir_recursive_absolute(shot_dir)
		hud.set_gui_scale(1.0, false)
		var lobby: Lobby = game.world
		lobby._recovery_ward.set_active(true)
		await RenderingServer.frame_post_draw
		game.get_viewport().get_texture().get_image().save_png(shot_dir.path_join("recovery_ward.png"))
		lobby._recovery_ward.set_active(false)
		lobby._settlement_editor.active = true
		lobby._settlement_editor.set_process(true)
		lobby._placeables[0].set_selected(true)
		await game.get_tree().process_frame
		await RenderingServer.frame_post_draw
		game.get_viewport().get_texture().get_image().save_png(shot_dir.path_join("settlement_editor.png"))
		lobby._placeables[0].set_selected(false)
		lobby._settlement_editor.active = false
		lobby._settlement_editor.set_process(false)
		lobby._settlement_editor.queue_redraw()
