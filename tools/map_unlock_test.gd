extends Node
var checks := 0
var fails := 0
func _ready() -> void:
	if not TestEnvironment.require_isolation(): get_tree().quit(1); return
	GameState.autosave_enabled = false
	GameState.new_game("adam")
	var game := load("res://scenes/game.tscn").instantiate() as Game
	add_child(game)
	game._remove_title()
	await game._load_lobby(false)
	if "--small-screen" in OS.get_cmdline_user_args(): get_window().size = Vector2i(832, 480)
	await MapUnlockChecks.run(game, _check, _capture if DisplayServer.get_name() != "headless" else Callable())
	if DisplayServer.get_name() != "headless":
		get_window().size=Vector2i(832,480)
		await get_tree().process_frame
		await get_tree().process_frame
		var button := game.hud._map_button
		var physical := game.get_viewport().get_final_transform()*button.get_global_rect()
		_check(physical.size.y>=43.5 and not button.get_global_rect().intersects(game.hud._menu_button.get_global_rect()),"small-screen Map remains a 44px target separated from Menu")
		await _capture("06_map_button_832x480")
		await _click(button)
		_check(game.hud.map_panel.visible and game.player().controls_locked,"small-screen mouse click opens the map and locks world input")
		await _capture("07_expanded_map_832x480")
		await _click(game.hud.map_panel._close_button)
		_check(not game.hud.map_panel.visible and not game.player().controls_locked and not game.hud._minimap.visible,"small-screen Close returns to gameplay without a minimap")
	print("--- map unlock test: %d checks, %s ---" % [checks, "PASS" if fails == 0 else "FAIL"])
	get_tree().quit(0 if fails == 0 else 1)
func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: fails += 1
	print("[OK] " if ok else "[FAIL] ", message)

func _capture(label: String) -> void:
	var directory := OS.get_environment("TIDESWORN_TEST_ROOT").path_join("shots")
	DirAccess.make_dir_recursive_absolute(directory)
	await get_tree().create_timer(0.1).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(directory.path_join(label + ".png"))

func _click(control: Control) -> void:
	var press := InputEventMouseButton.new()
	press.button_index=MOUSE_BUTTON_LEFT
	press.position=get_viewport().get_final_transform()*control.get_global_rect().get_center()
	press.pressed=true
	Input.parse_input_event(press)
	await get_tree().process_frame
	var release := InputEventMouseButton.new()
	release.button_index=MOUSE_BUTTON_LEFT
	release.position=press.position
	Input.parse_input_event(release)
	await get_tree().process_frame
	await get_tree().process_frame
