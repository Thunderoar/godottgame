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
	var capture := _capture if "--capture" in OS.get_cmdline_user_args() else Callable()
	await preload("res://tools/urchin_arrival_checks.gd").run(game, _check, capture)
	await preload("res://tools/fire_arrival_checks.gd").run(game, _check, capture)
	print("--- fire arrival: %d checks, %s ---" % [checks, "PASS" if fails == 0 else "FAIL"])
	get_tree().quit(0 if fails == 0 else 1)

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: fails += 1
	print("[OK] " if ok else "[FAIL] ", message)

func _capture(label: String) -> void:
	var directory := OS.get_environment("TIDESWORN_TEST_ROOT").path_join("shots")
	DirAccess.make_dir_recursive_absolute(directory)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(directory.path_join(label + ".png"))
