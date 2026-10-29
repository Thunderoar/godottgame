extends Node

var checks := 0
var failures := 0
var _capture := false

func _ready() -> void:
	if not TestEnvironment.require_isolation():
		get_tree().quit(1)
		return
	_capture = "--capture" in OS.get_cmdline_user_args()
	GameState.autosave_enabled = false
	var game := load("res://scenes/game.tscn").instantiate() as Game
	add_child(game)
	await get_tree().process_frame
	game._remove_title()
	game.hud.visible = true
	await preload("res://tools/twilight_checks.gd").run(game,_check,_shot if _capture else Callable())
	# Let final route refresh and short-lived visual callbacks retire before
	# tearing the fixture down, then drain its queued deletions before quitting.
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().create_timer(0.75).timeout
	await get_tree().process_frame
	game.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	print("--- twilight test: %d checks, %s ---" % [checks,"PASS" if failures == 0 else "%d FAILURE(S)" % failures])
	get_tree().quit(0 if failures == 0 else 1)

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("[%s] %s" % ["OK" if ok else "FAIL",message])

func _shot(id: String) -> void:
	await get_tree().create_timer(0.35).timeout # Let the owned UI entry fade finish.
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var root := OS.get_environment("TIDESWORN_TEST_ROOT")
	get_viewport().get_texture().get_image().save_png(root.path_join("twilight_"+id+".png"))
