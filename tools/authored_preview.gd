extends Node
## Isolated authoring preview enters the real game immediately.
func _ready() -> void:
	if not TestEnvironment.require_isolation():
		get_tree().quit(1)
		return
	var game := load("res://scenes/game.tscn").instantiate() as Game
	add_child(game)
	await get_tree().process_frame
	game.call("_on_character_selected", "qayyim")
	await get_tree().process_frame
	game.hud.tutorial_guide.call("_skip")
