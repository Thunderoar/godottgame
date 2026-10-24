class_name WorldChecks
extends RefCounted
## Spatial regression checks run in the same isolated gate as gameplay.
static func run(game: Game, check: Callable) -> bool:
	var lobby := game.world as Lobby
	var layout := lobby._layout
	check.call(layout.warnings().is_empty(), "canonical village IDs, bounds, route widths and graph connectivity validate: " + str(layout.warnings()))
	_check_authoring_blends(check)
	var expected := ["arrival", "house", "recovery", "market", "shop_potion", "shop_equipment", "shop_pet", "shop_house", "shop_services", "monster_portal", "pet_portal", "waterfront", "jetty_landing", "beach_turtle", "cleaning", "besut", "garden_walk", "forest_defence", "forest_clearing", "stable"]
	for id in expected:
		check.call(not layout.anchor(id).is_empty(), "required spatial landmark exists: " + id)
	check.call(layout.allows("waterfront", "fishing_net") and not layout.allows("forest_interior", "fishing_net"), "semantic zones admit fishing tools at the waterfront and reject them in woodland")
	var planner := ResidentRoutes.new(lobby)
	var query := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = WorldLayout.ACTOR_CLEARANCE
	query.shape = circle
	query.collision_mask = 1
	var space := lobby.get_world_2d().direct_space_state
	var start := layout.position_of("arrival")
	for entry in layout.anchors:
		if not entry.get("destination", false): continue
		var id := str(entry.id)
		var at := layout.approach(id)
		query.transform = Transform2D(0.0, at)
		query.motion = Vector2.ZERO
		var hits := space.intersect_shape(query, 4)
		check.call(hits.is_empty(), "player-sized destination approach is clear: " + id + _hits(hits))
		var path := planner.path(start, at, false)
		check.call(not path.is_empty(), "actual physics route reaches exact destination: " + id)
	var entrances_clear := true
	for entry in layout.anchors:
		if entry.get("kind", "") not in ["house", "shop", "residence", "portal"]: continue
		var rectangle := RectangleShape2D.new()
		rectangle.size = entry.get("clearance", Vector2.ONE)
		query.shape = rectangle
		query.transform = Transform2D(0, layout.approach(str(entry.id)))
		query.motion = Vector2.ZERO
		var hits := space.intersect_shape(query, 4)
		if not hits.is_empty(): print("ENTRANCE ", entry.id, _hits(hits))
		entrances_clear = entrances_clear and hits.is_empty()
	query.shape = circle
	check.call(entrances_clear, "full declared entrance rectangles remain free of physical obstacles")
	for route in layout.routes:
		var points := layout.route_points(route)
		var blocked := PackedStringArray()
		for i in points.size() - 1:
			query.transform = Transform2D(0.0, points[i])
			query.motion = Vector2.ZERO
			var hits := space.intersect_shape(query, 4)
			query.motion = points[i + 1] - points[i]
			var fraction := space.cast_motion(query)[0]
			if not hits.is_empty() or fraction < 0.999:
				var contact := points[i].lerp(points[i + 1], minf(1, fraction + 0.02))
				query.transform = Transform2D(0.0, contact)
				query.motion = Vector2.ZERO
				hits = space.intersect_shape(query, 4)
				blocked.append(str(i) + ":" + str(points[i]) + "→" + str(points[i + 1]) + " at=" + str(contact) + _hits(hits))
		check.call(blocked.is_empty(), "painted route has continuous actor clearance: " + str(route.id) + " " + str(blocked))
	# The coastline contract is probed using both rendered samples and physics.
	var water_query := PhysicsPointQueryParameters2D.new()
	water_query.collision_mask = 1
	for x in [2.0, 5.0, 9.0, 14.0, 18.0, 22.0]:
		var shore := WorldTerrain.shore_y(x)
		if shore > 38.0: continue
		var wet := Vector2(x, shore + 0.6)
		if layout.world_footprint("jetty_deck").has_point(wet): wet.y = layout.world_footprint("jetty_deck").end.y + 0.6
		water_query.position = wet
		check.call(not space.intersect_point(water_query).is_empty(), "sea collision agrees with painted shoreline at x=" + str(x))
	check.call(planner.segment_clear(layout.approach("jetty_landing"), layout.approach("jetty_deck")), "visible jetty planks are walkable from the landing")
	water_query.position = Vector2(8, layout.world_footprint("jetty_deck").end.y + 0.3)
	check.call(not space.intersect_point(water_query).is_empty(), "sea remains solid immediately beyond the visible jetty")
	var turtle := lobby.get_node("BeachTurtle") as Node2D
	check.call(turtle.position.y < WorldTerrain.shore_y(turtle.position.x) - 0.7 and turtle.position.y > WorldTerrain.shore_y(turtle.position.x) - 3.0, "turtle remains grounded on shared beach shelf")
	var map := lobby._authored_map
	var original := map.snapshot()
	var copy := map.copy_map()
	var changed := copy.layout.anchor("shop_potion")
	changed.position = Vector2(25, 22)
	copy.objects.append({"id": "developer_service", "base_id": "shop_potion", "position": Vector2(24, 23)})
	var resolved := copy.resolved_layout({"shop_potion": [26.0, 24.0]})
	check.call(resolved.position_of("shop_potion") == Vector2(26, 24), "saved player service position wins over developer override and anchor")
	check.call(copy.resolved_layout().position_of("shop_potion") == Vector2(24, 23), "developer base override wins over canonical default")
	check.call(map.snapshot() == original, "resolving and editing a copy never mutates source layout")
	var moved := layout.resolved([], {"house": [35.0, 22.4]})
	check.call(moved.position_of("arrival").distance_to(start + Vector2(1, 1)) < 0.001 and moved.position_of("recovery").distance_to(layout.position_of("recovery") + Vector2(1, 1)) < 0.001, "home arrival, ward and route endpoints follow relocated cottage")
	copy.restore(original)
	check.call(copy.snapshot() == original, "layout anchors, routes and zones participate in snapshot undo/redo")
	var legacy := AuthoredMap.new()
	check.call(legacy.resolved_layout().signature() == WorldLayout.village().signature(), "old authored maps inherit versioned village layout without save migration")
	check.call(WorldTerrain._make_terrain_texture(layout) == layout.terrain_bake, "unchanged shipped geometry selects its imported terrain bake")
	var generated := WorldTerrain._make_terrain_image(layout)
	var baked := layout.terrain_bake.get_image()
	generated.convert(Image.FORMAT_RGBA8)
	baked.convert(Image.FORMAT_RGBA8)
	check.call(generated.get_data() == baked.get_data(), "imported default terrain and live Map Studio generator have exact pixel parity")
	var edited_layout := layout.copy_layout()
	edited_layout.anchors[0].position += Vector2(0.25, 0)
	check.call(WorldTerrain._make_terrain_texture(edited_layout) != layout.terrain_bake, "geometry edits reject a stale bake and render directly from authored data")
	var path_before := WorldTerrain._make_terrain_texture(layout)
	check.call(path_before == WorldTerrain._make_terrain_texture(layout), "unchanged resolved layout reuses terrain cache")
	copy.layout.anchors.append(copy.layout.anchors[0].duplicate(true))
	check.call(not copy.layout.warnings().is_empty(), "validator rejects duplicate canonical IDs")
	for route in layout.routes:
		for point in layout.route_points(route):
			if not layout.reserved(point, 0.3):
				check.call(false, "route is protected from decorative placement")
	var clear_flowers := true
	for node in game.get_tree().get_nodes_in_group("flowers"):
		if not lobby.is_ancestor_of(node): continue
		if node.has_meta("scenery_id"):
			for detail in layout.scenery:
				if detail.get("id", "") == node.get_meta("scenery_id") and not layout.scenery_fits(detail): clear_flowers = false
		elif layout.reserved(node.global_position, 0.45): clear_flowers = false
	check.call(clear_flowers, "flowers frame districts without occupying approaches or lanes")
	var shore_map := AuthoredMap.new()
	shore_map.paint("Shore", Vector2i(3, 28), "sand")
	var shore_tile := AuthoredMapRenderer.tile_image("sand", Vector2i(3, 28), shore_map, "Shore")
	check.call(shore_tile.get_used_rect().size == Vector2i.ZERO and not shore_map.warnings().is_empty(), "land paint cannot hide permanent sea collision")
	var water_map := AuthoredMap.new()
	water_map.paint("Water", Vector2i(40, 35), "sea_shallow")
	water_map.paint("Shore", Vector2i(40, 35), "grass")
	check.call(AuthoredMapRenderer.tile_image("grass", Vector2i(40, 35), water_map, "Shore").get_used_rect().size == Vector2i.ZERO, "shore paint cannot disguise authored water as walkable land")
	var barrier := AuthoredMap.new()
	barrier.objects.append({"id": "wall_across_market", "position": Vector2(28, 24.1), "blocking": true, "footprint": Vector2(6, 0.5)})
	check.call(not barrier.warnings().is_empty(), "footprint validation catches a wall across a road away from destinations")
	var spawn_clear := true
	for at in [Vector2(45.8, 18), Vector2(12.2, 25.8), Vector2(16.2, 29), Vector2(46.8, 25.2), Vector2(24, 24.2), Vector2(41.5, 23.4), Vector2(47.4, 8.8), Vector2(50.8, 14.2), Vector2(49, 21.2), Vector2(53.2, 26)]:
		query.transform = Transform2D(0, lobby.safe_spawn(at, 0.45))
		query.motion = Vector2.ZERO
		spawn_clear = spawn_clear and space.intersect_shape(query, 1).is_empty()
	check.call(spawn_clear, "emergency, coastal and forest spawns resolve onto clear land")
	await _runtime_overrides(game, check)
	return true

static func _hits(hits: Array[Dictionary]) -> String:
	var names := PackedStringArray()
	for hit in hits:
		var collider := hit.get("collider") as Node
		if collider: names.append(str(collider.get_path()))
	return " " + str(names) if not names.is_empty() else ""


static func _runtime_overrides(game: Game, check: Callable) -> void:
	var map := (game.world as Lobby)._authored_map.copy_map()
	map.layout.anchor("house").position = Vector2(34.5, 21.4)
	map.layout.anchor("shop_potion").position = Vector2(24.2, 22.2)
	map.seed_value = 999
	var path := "user://world-override-test.tres"
	check.call(ResourceSaver.save(map, path) == OK, "developer spatial data saves outside source checkout")
	AuthoredMapRenderer.override_path = path
	GameState.set_placeable_position("house", Vector2(35, 21.9))
	GameState.set_placeable_position("shop_potion", Vector2(24.8, 23.0))
	GameState.save_game()
	check.call(GameState.load_game(), "existing-format settlement save reloads")
	game.call("_load_lobby", false)
	for frame in 6: await game.get_tree().physics_frame
	var lobby := game.world as Lobby
	var house: SettlementPlaceable
	var shop: SettlementPlaceable
	for node in lobby._placeables:
		if node.placeable_id == "house": house = node
		if node.placeable_id == "shop_potion": shop = node
	check.call(house.position == Vector2(35, 21.9) and shop.position == Vector2(24.8, 23), "actual runtime player placements override developer source positions")
	var merchant := shop.get_node("Mara") as ShopNPC
	check.call(merchant.global_position.distance_to(shop.position + Vector2(0, -0.65)) < 0.001 and shop.get_node("CounterBody").global_position == shop.position, "merchant, stall collider and local workspace travel with service owner")
	check.call(lobby._recovery_center.distance_to(house.position + Vector2(0, 2.3)) < 0.001 and lobby._recovery_ward.position == lobby._recovery_center, "actual recovery ward follows saved house position")
	var expected: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tools/fixtures/monsoon_forest.json"))
	var forest_ok := lobby._forest_trees.size() == expected.size()
	for i in mini(expected.size(), lobby._forest_trees.size()):
		var tree := lobby._forest_trees[i]
		forest_ok = forest_ok and tree.tree_id == str(expected[i].id) and tree.position.distance_to(Vector2(expected[i].position[0], expected[i].position[1])) < 0.0001
	check.call(forest_ok, "developer layout, saved buildings and decorative seed changes preserve original forest associations")
	var signature := lobby._layout.signature()
	var planner := ResidentRoutes.new(lobby)
	check.call(not planner.path(lobby.get_spawn_position(), merchant.customer_position(), false).is_empty(), "relocated shop remains reachable in actual physics")
	game.call("_load_lobby", false)
	for frame in 6: await game.get_tree().physics_frame
	check.call((game.world as Lobby)._layout.signature() == signature, "re-entering a customized village produces deterministic resolved routes")
	AuthoredMapRenderer.override_path = ""
	GameState.new_game("qayyim")
	game.call("_load_lobby", false)
	for frame in 4: await game.get_tree().physics_frame


static func _check_authoring_blends(check: Callable) -> void:
	var source := WorldLayout.new()
	source.zones.assign([{"id": "test_blend", "material": "stone", "polygon": PackedVector2Array([Vector2(1, 1), Vector2(7, 1), Vector2(7, 7), Vector2(1, 7)]), "feather": 0.5, "strength": 0.8}])
	var broad := source.copy_layout()
	broad.zones[0].feather = 3.0
	check.call(source.signature() != broad.signature(), "authoring: district blend width invalidates terrain caches")
	var a := Image.create_empty(256, 256, false, Image.FORMAT_RGBA8)
	var b := Image.create_empty(256, 256, false, Image.FORMAT_RGBA8)
	var grass := WorldPalette.color("grass")
	a.fill(grass)
	b.fill(grass)
	WorldTerrain._paint_zones(a, source)
	WorldTerrain._paint_zones(b, broad)
	var baseline := Vector3(grass.r, grass.g, grass.b)
	var near_a := a.get_pixel(64, 128)
	var near_b := b.get_pixel(64, 128)
	check.call(Vector3(near_b.r, near_b.g, near_b.b).distance_to(baseline) < Vector3(near_a.r, near_a.g, near_a.b).distance_to(baseline), "authoring: broader district blend visibly softens the ground transition")
	var fainter := broad.copy_layout()
	fainter.zones[0].strength = 0.2
	check.call(fainter.signature() != broad.signature(), "authoring: district ground tint invalidates terrain caches")
	var road := WorldLayout.village().copy_layout()
	var before := road.signature()
	road.routes[0].feather = 0.8
	check.call(road.signature() != before, "authoring: custom road softness invalidates terrain caches")
	var hard_path := Image.create_empty(256, 256, false, Image.FORMAT_RGBA8)
	var soft_path := Image.create_empty(256, 256, false, Image.FORMAT_RGBA8)
	WorldTerrain._paint_path(hard_path, [Vector2(1, 4), Vector2(7, 4)], 2, "path", "secondary", 0.1)
	WorldTerrain._paint_path(soft_path, [Vector2(1, 4), Vector2(7, 4)], 2, "path", "secondary", 0.8)
	check.call(soft_path.get_pixel(128, 104).a < hard_path.get_pixel(128, 104).a, "authoring: road softness changes edge coverage without widening navigation ribbons")
