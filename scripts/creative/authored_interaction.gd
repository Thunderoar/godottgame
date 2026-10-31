class_name AuthoredInteraction
extends Interactable
var speaker := "Village detail"
var lines: Array = []

func get_touch_verb() -> String:
	return "Talk"

func interact(_player: Node) -> void:
	var game := get_tree().get_first_node_in_group("game")
	if game and game.has_method("open_dialogue"):
		var project_lines := GameState.village_npc_lines(speaker)
		game.call("open_dialogue", speaker, project_lines if not project_lines.is_empty() else lines)
