extends Node
var checks := 0
var failures := 0
func _ready() -> void:
	if not TestEnvironment.require_isolation(): get_tree().quit(1); return
	if "--reduced" in OS.get_cmdline_user_args():
		GameSettings.set_reduce_motion(true,false)
		GameSettings.set_effects_quality("low",false)
	GameState.autosave_enabled = false
	var game := load("res://scenes/game.tscn").instantiate() as Game
	add_child(game)
	game._side_quest_auto_enabled = false
	await get_tree().process_frame
	game._remove_title()
	game.hud.visible = true
	await preload("res://tools/realm_wave_checks.gd").run(game,_check,_capture if "--capture" in OS.get_cmdline_user_args() else Callable())
	await get_tree().create_timer(0.75).timeout
	game.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	print("--- realm waves: %d checks, %s ---" % [checks,"PASS" if failures==0 else "FAIL"])
	get_tree().quit(0 if failures==0 else 1)
func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("[%s] %s" % ["OK" if ok else "FAIL",message])
func _capture(label: String) -> void:
	await get_tree().create_timer(1.2).timeout # Let real death/XP feedback retire before inspecting persistent wave UI.
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("TIDESWORN_TEST_ROOT").path_join(label+".png"))
