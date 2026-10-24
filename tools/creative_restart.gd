extends Node
## Second process checks editor outputs after editor shutdown.
func _ready() -> void:
	if not TestEnvironment.require_isolation():
		get_tree().quit(1)
		return
	var game := load("res://scenes/game.tscn").instantiate() as Game
	add_child(game)
	await get_tree().process_frame
	game.call("_on_character_selected", "qayyim")
	await get_tree().process_frame
	await get_tree().physics_frame
	var passed := AssetRegistry.library().entries.has("demo/character")
	var authored := game.world.get_node_or_null("AuthoredMap") as AuthoredMapRenderer
	passed = passed and authored != null and authored.definition.objects.size() == 2
	var saved_layout := authored.definition.layout if authored else null
	passed = passed and saved_layout != null and saved_layout.position_of("shop_services") == Vector2(32.75, 28.25) and is_equal_approx(float(saved_layout.routes[0].width), 2.15)
	passed = passed and (game.world as Lobby)._layout.position_of("shop_services") == Vector2(32.75, 28.25)
	var imported := false
	if authored:
		for child in authored.get_children():
			if child is Node2D and child.has_meta("authored_id"):
				for sprite in child.get_children():
					if sprite is AuthoredSprite and sprite.frames.size() == 3:
						imported = sprite.frames[0].get_image().get_pixel(16, 16).is_equal_approx(Color.CYAN)
	passed = passed and imported
	var point := PhysicsPointQueryParameters2D.new()
	point.position = Vector2(26.5, 34.5)
	point.collision_mask = 1
	passed = passed and not game.world.get_world_2d().direct_space_state.intersect_point(point).is_empty()
	print("--- creative restart: ", "PASS" if passed else "FAIL", " ---")
	if DisplayServer.get_name() != "headless":
		var p := game.player()
		p.position = Vector2(30, 32)
		p.controls_locked = true
		game.hud.tutorial_guide.call("_skip")
		game.world.camera.position = Vector2(29, 32)
		game.world.camera.target = null
		await get_tree().create_timer(0.5).timeout
		RenderingServer.force_draw()
		get_viewport().get_texture().get_image().save_png(OS.get_environment("TIDESWORN_TEST_ROOT").path_join("evidence/authored-runtime.png"))
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit(0 if passed else 1)
