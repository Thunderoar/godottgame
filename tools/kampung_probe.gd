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
	for frame in 4: await get_tree().physics_frame
	await KampungChecks.run(game, _check)
	await WorldChecks.run(game, _check)
	print("KAMPUNG_PROBE: %d checks, %d failures" % [checks, failures])
	game.queue_free()
	for frame in 2: await get_tree().process_frame
	get_tree().quit(0 if failures == 0 else 1)

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("[OK] " if ok else "[FAIL] ", message)
