extends Node
var checks := 0
var failures := 0
func _ready() -> void:
	if not TestEnvironment.require_isolation(): get_tree().quit(1); return
	GameState.autosave_enabled = false
	GameState.new_game("adam")
	var game := load("res://scenes/game.tscn").instantiate() as Game
	add_child(game)
	game._remove_title()
	await game._load_lobby(false)
	if "--small-screen" in OS.get_cmdline_user_args(): get_window().size = Vector2i(832,480)
	await preload("res://tools/elemental_checks.gd").run(game,_check,_capture if DisplayServer.get_name() != "headless" else Callable())
	print("--- elemental test: %d checks, %s ---" % [checks,"PASS" if failures == 0 else "%d FAILURE(S)" % failures])
	get_tree().quit(0 if failures == 0 else 1)
func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("[OK] " if ok else "[FAIL] ",message)
func _capture(label: String) -> void:
	var directory := OS.get_environment("TIDESWORN_TEST_ROOT").path_join("shots")
	DirAccess.make_dir_recursive_absolute(directory)
	await get_tree().create_timer(0.12).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(directory.path_join(label+".png"))
