extends Node
## Fresh process proves spatial edits and new features reach the real runtime.
func _ready() -> void:
	if not TestEnvironment.require_isolation():
		get_tree().quit(1)
		return
	var game := load("res://scenes/game.tscn").instantiate() as Game
	add_child(game)
	await get_tree().process_frame
	game.call("_on_character_selected", "qayyim")
	for frame in 4: await get_tree().physics_frame
	var lobby := game.world as Lobby
	var source := lobby._authored_map
	var passed := source != null and source.layout != null
	var landmark := ""
	if passed:
		for entry in source.layout.anchors:
			if entry.get("editor_created", false): landmark = str(entry.id)
	passed = passed and not landmark.is_empty()
	passed = passed and lobby._layout.position_of("shop_house").is_equal_approx(Vector2(27, 13.15))
	var shop_found := false
	for placeable in lobby._placeables:
		if placeable.placeable_id == "shop_house": shop_found = placeable.position.is_equal_approx(Vector2(27, 13.15))
	passed = passed and shop_found
	var road_found := false
	var district_found := false
	for road in lobby._layout.routes:
		if road.get("to", "") == landmark: road_found = is_equal_approx(float(road.get("width", 0)), 2.4) and is_equal_approx(float(road.get("feather", 0)), 0.3)
	for zone in lobby._layout.zones:
		if zone.get("label", "") == "New district": district_found = zone.get("polygon", PackedVector2Array()).size() == 5 and is_equal_approx(float(zone.get("feather", 0)), 4) and is_equal_approx(float(zone.get("strength", 0)), 0.35)
	passed = passed and road_found and district_found
	var worker_found := false
	for resident in lobby._residents:
		if resident.resident_name == "Sami": worker_found = resident.waypoints[0].is_equal_approx(lobby._layout.activity_points(lobby._layout.activity("Sami"))[0])
	passed = passed and worker_found
	var renderer := lobby.get_node_or_null("AuthoredMap") as AuthoredMapRenderer
	var bench_found := false
	if renderer:
		for object in renderer.get_children():
			if object is Node2D and object.position.is_equal_approx(Vector2(28.5, 34.5)): bench_found = true
	passed = passed and bench_found
	print("--- workbench restart: ", "PASS" if passed else "FAIL", " ---")
	if not passed: print("WORKBENCH RESTART DETAIL ", JSON.stringify({"landmark": landmark, "shop": shop_found, "road": road_found, "district": district_found, "worker": worker_found, "bench": bench_found, "shop_at": str(lobby._layout.position_of("shop_house"))}))
	if DisplayServer.get_name() != "headless":
		game.player().controls_locked = true
		game.hud.tutorial_guide.call("_skip")
		lobby.camera.target = null
		lobby.camera.position = Vector2(30, 24)
		await get_tree().create_timer(0.25).timeout
		RenderingServer.force_draw()
		get_viewport().get_texture().get_image().save_png(OS.get_environment("TIDESWORN_TEST_ROOT").path_join("evidence/workbench-runtime.png"))
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit(0 if passed else 1)
