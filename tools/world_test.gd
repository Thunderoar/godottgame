extends Node
var failures := 0
var checks := 0
func _ready() -> void:
	if not TestEnvironment.require_isolation(): get_tree().quit(1); return
	var game := load("res://scenes/game.tscn").instantiate() as Game
	add_child(game)
	await get_tree().process_frame
	game.call("_on_character_selected", "qayyim")
	game.hud.tutorial_guide.call("_skip")
	game.set_process(false)
	for resident in (game.world as Lobby)._residents: resident.set_physics_process(false)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var completed := await WorldChecks.run(game, _check)
	if completed != true: _check(false, "spatial verification did not complete")
	print("WORLD_CHECKS: %d checks, %d failures" % [checks, failures])
	game.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(0 if failures == 0 else 1)
func _check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1
	print("[%s] %s" % ["OK" if value else "FAIL", message])
