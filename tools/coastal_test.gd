extends Node
var failures := 0
var checks := 0
var _shots := ""
func _ready() -> void:
	if not TestEnvironment.require_isolation():
		get_tree().quit(1)
		return
	if "--small-screen" in OS.get_cmdline_user_args():
		get_window().size = Vector2i(832, 480)
	_shots = OS.get_environment("TIDESWORN_TEST_ROOT").path_join("shots")
	var game := load("res://scenes/game.tscn").instantiate() as Game
	add_child(game)
	await get_tree().process_frame
	await game._on_character_selected("adam")
	await preload("res://tools/coastal_checks.gd").run(game, _check, _capture if DisplayServer.get_name() != "headless" else Callable())
	game.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	print("COASTAL_CHECKS: %d checks, %s" % [checks, "PASS" if failures == 0 else "%d failures" % failures])
	get_tree().quit(0 if failures == 0 else 1)
func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("[%s] %s" % ["OK" if ok else "FAIL", message])
func _capture(label: String) -> void:
	var game := get_tree().get_first_node_in_group("game") as Game
	if is_instance_valid(game) and game.world is OceanJourney:
		(game.world as OceanJourney)._refresh_ui()
	DirAccess.make_dir_recursive_absolute(_shots)
	await get_tree().create_timer(0.08).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_shots.path_join(label + ".png"))
	print("COAST_CAPTURE ", label)
