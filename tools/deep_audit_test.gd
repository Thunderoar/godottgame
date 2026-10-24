extends Node
var failures := 0
var checks := 0

func _ready() -> void:
	if not TestEnvironment.require_isolation():
		get_tree().quit(1)
		return
	var game: Node = load("res://scenes/game.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await game.call("_on_character_selected", "qayyim")
	await get_tree().process_frame
	game.hud.tutorial_guide.call("_skip")
	await DeepAuditChecks.run(game, _check)
	print("DEEP AUDIT: %d checks, %d failures" % [checks, failures])
	game.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(0 if failures == 0 else 1)

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("[OK] " if ok else "[FAIL] ", message)
