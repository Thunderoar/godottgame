class_name MissionPanel
extends ModalBase

func _ready() -> void:
	_panel_size = Vector2(620, 480)
	super._ready()
	GameState.data_changed.connect(func() -> void:
		if visible: _rebuild())

func open_missions() -> void:
	open_panel("Missions - BESUT Guide")

func _rebuild() -> void:
	_clear_content()
	add_section("GROWING BESUT", GameUI.GOLD)
	content.add_child(VillageProjectCard.new())
	add_section("RESCUE YOUR FRIENDS", GameUI.GOLD)
	add_body_text(GameState.campaign_objective(), GameUI.TEXT, 16)
	var lesson := MissionDB.step(GameState.mission_step())
	if GameState.tutorial_complete():
		add_section("Tutorial complete", GameUI.PURPLE)
		add_body_text("Portal 1 is the only Monster Battle Portal required for training. Continue your adventure to rescue Arjun and Mei Ling.", GameUI.TEXT, 17)
	elif lesson.is_empty():
		add_section("Night training complete" if GameState.is_night() else "Day training complete", GameUI.PURPLE)
		add_body_text("Training changes with the time of day. Protect the village and prepare for the next lesson.", GameUI.TEXT, 17)
	else:
		add_section(str(lesson.get("title", "Current mission")), GameUI.PURPLE)
		add_body_text(str(lesson.get("text", "")), GameUI.TEXT, 17)
		add_body_text("Completed: %d / %d" % [GameState.completed_mission_count(), MissionDB.STEPS.size()], GameUI.MUTED, 14)
		var guide := GameUI.button("Show arrows and tutorial", Vector2(360, 48))
		guide.pressed.connect(func() -> void:
			close_panel()
			var hud := get_tree().get_first_node_in_group("hud") as GameHUD
			if is_instance_valid(hud):
				hud.start_tutorial())
		content.add_child(guide)
