extends Node
var checks := 0
var failures := 0

func _ready() -> void:
	if not TestEnvironment.require_isolation(): get_tree().quit(1); return
	GameState.autosave_enabled = false
	GameState.data = GameState._make_default("adam")
	var game := load("res://scenes/game.tscn").instantiate() as Game
	add_child(game)
	await get_tree().process_frame
	game._remove_title()
	await preload("res://tools/reunion_checks.gd").run(game,_check,_capture if "--capture" in OS.get_cmdline_user_args() else Callable())
	game.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	print("--- reunion: %d checks, %s ---" % [checks,"PASS" if failures == 0 else "FAIL"])
	get_tree().quit(0 if failures == 0 else 1)

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("[OK] " if ok else "[FAIL] ",message)

func _capture(label: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("TIDESWORN_TEST_ROOT").path_join(label+".png"))
