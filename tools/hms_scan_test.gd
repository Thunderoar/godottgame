extends Node
## Run using isolated user data; Android exports must use a separate test package.
var checks := 0
var failures := 0


func _ready() -> void:
	if not OS.has_feature("android") and not TestEnvironment.require_isolation():
		get_tree().quit(1)
		return
	HmsScanChecks.run(_check)
	var game := load("res://scenes/game.tscn").instantiate() as Game
	add_child(game)
	await get_tree().process_frame
	var before := GameState.data.duplicate(true)
	game.title_screen._open_settings()
	await get_tree().process_frame
	var control := _find_control(game.title_screen)
	_check(control != null, "HMS: title Settings includes message QR")
	if control != null:
		_check(control._generate.disabled == not HmsScanService.available(), "HMS: QR button follows platform availability")
		if HmsScanService.available():
			control._generate.pressed.emit()
			_check(control._code.visible and control._code.texture != null, "HMS: real Settings action displays native QR")
			if control._code.texture != null:
				_check(control._code.texture.get_image().save_png("user://hms-message-qr.png") == OK, "HMS: save generated QR for independent decode review")
		game.title_screen._close_overlay()
		_check(control._code.texture == null and not control._code.visible, "HMS: closing Settings releases the QR texture")
	var after := GameState.data.duplicate(true)
	# The existing title timer advances independently of this feature.
	before.erase("play_time")
	after.erase("play_time")
	_check(after == before and not GameState.has_existing_save, "HMS: title preview and message QR do not create a journey")
	if "--capture" in OS.get_cmdline_user_args():
		game.title_screen._open_settings()
		for size in [Vector2i(1280, 720), Vector2i(832, 480)]:
			get_window().size = size
			get_window().content_scale_size = size
			await get_tree().create_timer(0.3).timeout
			var qr_control := _find_control(game.title_screen)
			var scroll := game.title_screen._overlay_body.get_parent() as ScrollContainer
			scroll.ensure_control_visible(qr_control)
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var root := OS.get_environment("TIDESWORN_TEST_ROOT")
			_check(get_viewport().get_texture().get_image().save_png(root.path_join("hms-settings-%dx%d.png" % [size.x, size.y])) == OK, "HMS: capture settings at %s" % size)
	print("--- HMS scan: %d checks, %s ---" % [checks, "PASS" if failures == 0 else "FAIL"])
	get_tree().quit(0 if failures == 0 else 1)


func _find_control(root: Node) -> HmsScanControl:
	if root is HmsScanControl:
		return root as HmsScanControl
	for child in root.get_children():
		var found := _find_control(child)
		if found != null:
			return found
	return null


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("[%s] %s" % ["OK" if ok else "FAIL", message])
