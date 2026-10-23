extends Node
## Exercises the actual close button with pet ownership, scrolling and resizing.


func _ready() -> void:
	if not TestEnvironment.require_isolation():
		get_tree().quit(1)
		return
	var game := load("res://scenes/game.tscn").instantiate() as Game
	add_child(game)
	await get_tree().process_frame
	game._on_character_selected("qayyim")
	await get_tree().create_timer(0.3).timeout
	game.hud.tutorial_guide._skip()
	GameState.add_gold(100000)
	for pet_id in PetDB.shop_stock():
		GameState.purchase_pet(pet_id)
	for dimensions in [Vector2i(1280, 720), Vector2i(832, 480)]:
		get_window().content_scale_size = dimensions
		get_window().size = dimensions
		await get_tree().create_timer(0.2).timeout
		game.open_shop("pet", "Nia")
		await get_tree().create_timer(0.4).timeout
		var shop := game.hud.shop_panel
		var close_rect := shop._close_button.get_global_rect()
		var viewport := get_viewport().get_visible_rect()
		print("shop close review: viewport=", viewport, " panel=", shop.panel.get_global_rect(), " close=", close_rect)
		var shots := OS.get_environment("TIDESWORN_TEST_ROOT").path_join("shots")
		DirAccess.make_dir_recursive_absolute(shots)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(shots.path_join("pet_shop_%dx%d.png" % [dimensions.x, dimensions.y]))
		if not viewport.encloses(close_rect):
			push_error("Pet Shop close button is outside the viewport.")
			get_tree().quit(1)
			return
		if shop.body.get_h_scroll_bar().visible:
			push_error("Pet cards still require sideways scrolling.")
			get_tree().quit(1)
			return
		shop.body.scroll_vertical = 999999
		await get_tree().process_frame
		for pressed in [true, false]:
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			click.position = close_rect.get_center()
			click.pressed = pressed
			Input.parse_input_event(click)
			await get_tree().process_frame
		if shop.visible or game.player().controls_locked:
			push_error("Pet Shop close click did not close and restore movement.")
			get_tree().quit(1)
			return
		game.open_shop("pet", "Nia")
		shop.close_panel()
		await get_tree().process_frame
		await get_tree().process_frame
		if shop.visible or shop.content.get_child_count() != 0:
			push_error("Deferred shop rebuild ran after a fast close.")
			get_tree().quit(1)
			return
	print("shop close review: PASS")
	get_tree().quit()
