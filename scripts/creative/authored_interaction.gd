class_name AuthoredInteraction
extends Interactable
var speaker := "Village detail"
var lines: Array = []

func interact(_player: Node) -> void:
	var game := get_tree().get_first_node_in_group("game")
	if game and game.has_method("open_dialogue"):
		game.call("open_dialogue", speaker, lines)
