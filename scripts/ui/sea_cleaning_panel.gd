class_name SeaCleaningPanel
extends ModalBase
## Persistent report for the Coastal Guard's sea-cleaning work. Replaces the old
## transient catch notification with readable, always-available information.

func open_sea_cleaning() -> void:
	open_panel("Coastal Sea Cleaning")


func _rebuild() -> void:
	_clear_content()
	var system := get_tree().get_first_node_in_group("rubbish_system") as RubbishSystem
	var cleaned := int(GameState.data.get("sea_cleaned", 0))
	add_body_text("The Coastal Guard nets drifting rubbish before it reaches the sand. Every safe catch is worth 1 Gold.", GameUI.TEXT, 17)
	add_body_text("Total cleaned: %d     Gold: %d" % [cleaned, GameState.gold()], GameUI.GOLD, 18)
	if system != null:
		add_body_text("This visit: %d netted safely, %d washed ashore for collection." % [system.caught_count, system.beached_count], GameUI.TEAL, 15)
	add_body_text("Walk up to rubbish on the sand and press Pick Up to earn 1 Gold. Each piece pays only once. Board the ship from the jetty for the turtle journey.", GameUI.MUTED, 14)
	content.add_child(GameUI.spacer(6))
	add_body_text("The guard keeps working automatically while you shop, build, explore portals or defend the village.", GameUI.MUTED, 13)
	var close := GameUI.button("Back to the Shore", Vector2(250, 46))
	close.pressed.connect(close_panel)
	content.add_child(close)
