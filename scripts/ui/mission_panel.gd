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
	var hud := get_tree().get_first_node_in_group("hud") as GameHUD
	if is_instance_valid(hud):
		add_section("CHOOSE A MISSION · SHOW DIRECTION", GameUI.GOLD)
		for entry in ObjectiveTrackerData.entries(hud.world, hud._status_strip.counts):
			var follow := GameUI.button(str(entry.title), Vector2(0,44))
			follow.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			follow.pressed.connect(_follow.bind(str(entry.id)))
			content.add_child(follow)
	if bool(GameState.portal_state(RealmDB.PORTAL).get("cleared", false)):
		add_section("CHAOS CITADEL RESTORED", GameUI.GOLD)
		add_body_text(GameState.first_clear_notice_text(), GameUI.TEXT, 15)
	add_section("GROWING BESUT", GameUI.GOLD)
	content.add_child(VillageProjectCard.new())
	add_section("RESCUE YOUR FRIENDS", GameUI.GOLD)
	add_body_text(GameState.campaign_objective(), GameUI.TEXT, 16)
	if not GameState.portal_opened():
		add_section(GameState.portal_origin_title().to_upper(), GameUI.GOLD)
		add_body_text(GameState.portal_origin_instruction(), GameUI.TEXT, 16)
	var lesson := MissionDB.step(GameState.mission_step())
	if GameState.tutorial_complete():
		add_section("Tutorial complete", GameUI.PURPLE)
		add_body_text("Chaos Citadel completes training. Onward passages have level requirements: defend BESUT or replay cleared later stages to prepare. The restored Twilight Wilds stay peaceful. " + ("Your friends are safe in BESUT." if GameState.friends_reunited() else ("Mei Ling is safe. Continue the sea journey to rescue Arjun." if bool(GameState.campaign().get("mei_ling_rescued", false)) else "Defeat Shadow & Chaos Fiend to free Mei Ling from his prison.")), GameUI.TEXT, 17)
	elif lesson.is_empty():
		add_section("Night training complete" if GameState.is_night() else "Day training complete", GameUI.PURPLE)
		add_body_text("Training changes with the time of day. Protect the village and prepare for the next lesson.", GameUI.TEXT, 17)
	else:
		add_section(str(lesson.get("title", "Current mission")), GameUI.PURPLE)
		add_body_text(str(lesson.get("text", "")), GameUI.TEXT, 17)
		add_body_text("Completed: %d / %d" % [GameState.completed_mission_count(), MissionDB.STEPS.size()], GameUI.MUTED, 14)
		var guide := GameUI.button("Show direction", Vector2(0, 48))
		guide.pressed.connect(_follow.bind("lesson_" + str(lesson.event)))
		content.add_child(guide)

func _follow(id: String) -> void:
	close_panel()
	var hud := get_tree().get_first_node_in_group("hud") as GameHUD
	if is_instance_valid(hud): hud.track_objective(id)
