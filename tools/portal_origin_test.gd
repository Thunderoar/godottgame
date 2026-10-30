extends Node

var checks := 0
var failures := 0

func _ready() -> void:
	if not TestEnvironment.require_isolation():
		get_tree().quit(1)
		return
	GameState.autosave_enabled = false
	var game := load("res://scenes/game.tscn").instantiate() as Game
	add_child(game)
	await get_tree().process_frame
	game._remove_title()
	game.hud.visible = true
	await preload("res://tools/portal_origin_checks.gd").run(game,_check,_shot if "--capture" in OS.get_cmdline_user_args() else Callable())
	await get_tree().create_timer(0.8).timeout
	game.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	print("--- portal origin: %d checks, %s ---" % [checks,"PASS" if failures == 0 else "%d FAILURE(S)" % failures])
	get_tree().quit(0 if failures == 0 else 1)

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("[%s] %s" % ["OK" if ok else "FAIL",message])

func _shot(id: String) -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("TIDESWORN_TEST_ROOT").path_join("portal_origin_"+id+".png"))
