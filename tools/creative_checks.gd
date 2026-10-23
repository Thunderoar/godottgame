class_name CreativeChecks
extends RefCounted

static func run(game: Game, check: Callable) -> void:
	var palette := WorldPalette.current()
	check.call(palette.world.has("grass") and palette.ui.has("panel"), "creative palette separates named world and UI roles")
	check.call(WorldPalette.color("sand").get_luminance() > WorldPalette.color("sea_deep").get_luminance(), "sand and deep water preserve material contrast")
	var resource := ResourceLoader.load("res://data/palettes/forest.tres") as WorldPalette
	check.call(resource != null and resource.world.grass != palette.world.grass, "area palette variant loads with distinct grass")
	var tex_before := PixelArt.grass_tuft_texture()
	WorldPalette.use_palette(resource)
	var tex_after := PixelArt.grass_tuft_texture()
	check.call(tex_before != tex_after, "palette switch invalidates generated textures")
	WorldPalette.use_palette(palette)
	var doc := TidePixelDocument.new()
	doc.new_image(Vector2i(32, 32))
	check.call(doc.image().get_pixel(0, 0).a == 0.0, "pixel document starts transparent")
	doc.checkpoint()
	doc.rectangle(Vector2i(2, 2), Vector2i(12, 12), Color.RED)
	doc.fill(Vector2i(4, 4), Color.BLUE)
	check.call(doc.image().get_pixel(4, 4) == Color.BLUE and doc.image().get_pixel(2, 2) == Color.RED, "rectangle and bounded flood fill preserve the outline")
	doc.undo()
	check.call(doc.image().get_pixel(2, 2).a == 0.0, "pixel undo restores transparency")
	doc.redo()
	check.call(doc.image().get_pixel(2, 2) == Color.RED, "pixel redo restores painted artwork")
	doc.checkpoint()
	doc.line(Vector2i(3, 3), Vector2i(10, 10), Color.TRANSPARENT)
	check.call(doc.image().get_pixel(5, 5).a == 0.0, "eraser draws exact transparent pixels")
	doc.selection = Rect2i(2, 2, 11, 11)
	doc.checkpoint()
	doc.move_selection(Vector2i(8, 8))
	check.call(doc.image().get_pixel(2, 2).a == 0.0 and doc.image().get_pixel(10, 10) == Color.RED, "selection moves without scaling or antialiasing")
	doc.add_frame(true)
	doc.durations[1] = 0.24
	doc.reorder(-1)
	check.call(doc.frames.size() == 2 and is_equal_approx(doc.durations[0], 0.24), "frame duplication and ordering preserve durations")
	var source := "user://creative-sheet.png"
	check.call(doc.save_png(source) == OK, "sprite sheet and duration metadata export")
	var reopened := TidePixelDocument.new()
	check.call(reopened.load_png(source, Vector2i(32, 32)) == OK and reopened.frames.size() == 2 and is_equal_approx(reopened.durations[0], 0.24), "sprite sheet and durations survive restart-style reload")
	var old_catalog := AssetRegistry.library()
	var temporary := AssetCatalog.new()
	var imported_path := "user://creative-texture.tres"
	ResourceSaver.save(ImageTexture.create_from_image(doc.image()), imported_path)
	temporary.entries["test/prop"] = {"path": imported_path, "frame_size": Vector2i(16, 16), "columns": 2, "frames": 4}
	AssetRegistry.catalog = temporary
	AssetRegistry.invalidate()
	check.call(AssetRegistry.get_texture("test/prop", 3).get_size() == Vector2(16, 16), "asset registry crops configured sprite frames")
	temporary.entries["missing"] = {"path": "res://missing-art.png", "required": true}
	check.call(AssetRegistry.diagnostics().size() == 1, "missing required asset has a specific diagnostic")
	AssetRegistry.catalog = old_catalog
	AssetRegistry.invalidate()
	var map := AuthoredMap.new()
	map.paint("Terrain", Vector2i(28, 31), "grass_light")
	map.paint("Paths", Vector2i(28, 32), "path")
	map.paint("Water", Vector2i(29, 33), "sea_shallow")
	map.paint("Water", Vector2i(30, 33), "sea_deep")
	map.objects.append({"id": "test_stable_tree", "asset": "tree", "position": Vector2(32, 32), "blocking": true, "footprint": Vector2(0.7, 0.5)})
	map.objects.append({"id": "test_imported_prop", "asset": "coastal/planter", "position": Vector2(31, 32)})
	var base_tree: ForestTree = game.world._forest_trees[0]
	var base_position := base_tree.position
	map.objects.append({"id": "override_" + base_tree.tree_id, "base_id": base_tree.tree_id, "position": base_position + Vector2(0.8, 0)})
	var before := map.snapshot()
	map.paint("Terrain", Vector2i(28, 31), "sand")
	map.seed_value = 99
	map.restore(before)
	check.call(map.cell("Terrain", Vector2i(28, 31)) == "grass_light" and map.seed_value == 4771, "map snapshot restores authored paint and decoration seed")
	check.call(ResourceSaver.save(map, "user://creative-map.tres") == OK, "versioned map resource saves")
	var loaded := ResourceLoader.load("user://creative-map.tres", "", ResourceLoader.CACHE_MODE_IGNORE) as AuthoredMap
	check.call(loaded.objects[0].id == "test_stable_tree" and loaded.cell("Water", Vector2i(30, 33)) == "sea_deep", "map reload preserves object identities and terrain layers")
	loaded.paint("Collision", Vector2i(34, 24), "blocked")
	check.call(not loaded.warnings().is_empty(), "map validator detects protected spawn obstruction")
	loaded.paint("Collision", Vector2i(34, 24), "")
	var layer := AuthoredMapRenderer.new()
	layer.definition = loaded
	game.world.add_child(layer)
	await game.get_tree().physics_frame
	await game.get_tree().physics_frame
	var query := PhysicsPointQueryParameters2D.new()
	query.position = Vector2(29.5, 33.5)
	query.collision_mask = 1
	check.call(not game.world.get_world_2d().direct_space_state.intersect_point(query).is_empty(), "authored water blocks actual runtime collision")
	query.position = Vector2(32, 32)
	check.call(not game.world.get_world_2d().direct_space_state.intersect_point(query).is_empty(), "authored object footprint creates actual runtime collision")
	check.call(base_tree.position.distance_to(base_position + Vector2(0.8, 0)) < 0.01 and base_tree.tree_id == "forest_0", "base-object override moves the existing tree without renumbering it")
	check.call(layer.get_node_or_null("Terrain") is TileMapLayer and layer.get_node_or_null("Water") is TileMapLayer, "authored terrain is batched into native TileMapLayers")
	var object := layer.get_node_or_null("test_imported_prop")
	check.call(object != null and (object.get_child(0) as Sprite2D).texture != null, "saved imported asset appears on actual world object")
	var routes := ResidentRoutes.new(game.world)
	check.call(not routes.point_clear(Vector2(29.5, 33.5)), "resident routing reads authored water collision")
	base_tree.position = base_position
	layer.queue_free()
	await game.get_tree().process_frame
	var action := MicroAction.new()
	action.request("work")
	action.request("hurt")
	check.call(not action.request("greet") and action.state == "hurt", "micro-action priority safely interrupts work and rejects lower priority")
	action.tick(0.1, true)
	check.call(action.tilt == 0 and action.lift == 0, "Reduce Motion suppresses optional action movement")
	action.tick(1, false)
	check.call(action.state == "idle" and action.tilt == 0, "micro-action returns to clean idle state")
	var p := game.player()
	p._visual.set_motion(Vector2.ZERO, GameState.move_speed())
	check.call(not p._visual.moving and p._visual.motion_ratio == 0, "player walk cycle stops at zero actual motion")
	p._visual.set_motion(Vector2.ONE, GameState.move_speed())
	check.call(p._visual.moving and p._visual.motion_ratio > 0, "player animation follows actual velocity")
