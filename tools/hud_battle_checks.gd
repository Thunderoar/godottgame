extends RefCounted

static func run(game: Game, check: Callable) -> void:
	var hud := game.hud
	var lobby := game.world as Lobby
	check.call(hud._xp_bar == null and hud._pet_xp_bar == null, "XP bars removed from screen HUD")
	check.call(hud._gold_label.text == str(GameState.gold()) and hud._diamond_label.text == str(GameState.diamonds()) and hud._identity_label == null, "top-left HUD displays current gold and diamonds")
	check.call(hud._health_potion_button == null and hud._build_button == null, "potion shortcuts and screen Build button removed")
	check.call(hud._control_nodes.size() == 5 and hud._clock_label.is_visible_in_tree(), "four gameplay controls plus customizable Menu remain and clock is visible")
	check.call(lobby.get_node("MonsterBattlePortal").position == lobby._layout.position_of("monster_portal") and lobby.get_node("PetBattlePortal").position == lobby._layout.position_of("pet_portal") and lobby.get_node_or_null("TwinCaveHill") == null, "standalone portals follow the authored sanctuary positions")
	game.open_menu()
	await game.get_tree().process_frame
	await game.get_tree().process_frame
	check.call(_find_button(hud.menu_panel, "Build settlement") != null, "Build is available inside Menu")
	hud.menu_panel.close_panel()
	game.open_shop("potion", "Mara")
	await game.get_tree().process_frame
	await game.get_tree().process_frame
	check.call(hud.shop_panel._gold_label != null, "shop still displays the player's money")
	hud.shop_panel.close_panel()
	check.call(GameState.item_count("health_potion") > 0 and not ItemDB.exists("mana_potion"), "health potions remain available in Pack; mana potions are retired")
	var count := GameState.completed_mission_count()
	GameState.record_mission_event("fire_kill")
	check.call(GameState.mission_step() == 0 and GameState.completed_mission_count() == count, "day training ignores night combat events")
	GameState.record_mission_event("move")
	GameState.record_mission_event("gather")
	check.call(GameState.mission_step() == 2, "day lessons advance in order")
	GameState.advance_world_clock(180)
	_quiet(lobby)
	check.call(GameState.is_night() and GameState.mission_step() == 4, "night immediately selects the combat tutorial")
	GameState.record_mission_event("fire_kill")
	check.call(GameState.mission_step() == 8, "night tutorial advances to the monster portal")
	GameState.advance_world_clock(180)
	check.call(GameState.mission_step() == 2, "unfinished day tutorial resumes next day")
	while GameState.mission_step() < MissionDB.STEPS.size():
		GameState.record_mission_event(str(MissionDB.step(GameState.mission_step()).get("event", "")))
	check.call(GameState.completed_mission_count() == 8, "all seven day lessons complete separately from night training")
	GameState.advance_world_clock(180)
	_quiet(lobby)
	GameState.record_mission_event("portal")
	GameState.record_mission_event("boss")
	check.call(GameState.completed_mission_count() == 10, "night lessons complete the remaining training")
	GameState.advance_world_clock(180)
	game.open_pet_battles()
	await game.get_tree().process_frame
	await game.get_tree().process_frame
	var panel := hud.pet_battle_panel
	check.call(panel.start_battle("pet_duel_1"), "three-power duel starts")
	panel._opponent_max = 500
	panel._opponent_hp = 500
	check.call(panel._skill_buttons.size() == 3 and PetBattlePanel.SKILLS.size() == 3, "both pets have three available powers")
	check.call(panel.panel.get_node_or_null("FullArenaBackground") != null and panel.content.find_child("BattleArena", true, false) == null, "one full arena backdrop replaces boxed pet cards")
	var hp := panel._player_hp
	panel._process(30)
	check.call(panel._player_hp == hp and panel._opponent_hp == 500, "both duelists wait while no power is chosen")
	panel._enemy_choice = "attack"
	panel.choose_skill("attack")
	check.call(panel._opponent_hp < 500 and panel._player_hp == hp and panel._enemy_pending, "player acts first while enemy waits its turn")
	check.call(float(panel._player_cooldowns.attack) > 0 and float(panel._player_cooldowns.defend) == 0 and float(panel._player_cooldowns.burst) == 0, "using one power starts only its own cooldown")
	var enemy_hp := panel._opponent_hp
	panel.choose_skill("burst")
	check.call(panel._opponent_hp == enemy_hp, "cannot act twice before the rival reply")
	panel._process(0.71)
	check.call(panel._player_hp < hp and float(panel._enemy_cooldowns.attack) > 0, "enemy replies later and starts its own cooldown")
	panel._process(0.61)
	panel.choose_skill("attack")
	check.call(panel._turn_active and panel._opponent_hp == enemy_hp, "a cooling-down player power cannot be used")
	panel._enemy_choice = "burst"
	hp = panel._player_hp
	panel.choose_skill("defend")
	panel._process(0.71)
	check.call(panel._opponent_hp == enemy_hp and hp - panel._player_hp <= panel._enemy_damage, "second power shields against the enemy special attack")
	panel._process(0.61)
	panel.choose_skill("burst")
	check.call(enemy_hp - panel._opponent_hp == panel._player_damage * 2 and float(panel._player_cooldowns.burst) > 0, "third power deals double damage and has a separate cooldown")
	panel._enemy_cooldowns = {"attack": 4.0, "defend": 4.0, "burst": 4.0}
	hp = panel._player_hp
	panel._process(0.71)
	check.call(panel._player_hp == hp and panel._enemy_pending, "enemy cannot ignore its own cooldowns")
	panel._process(3.3)
	check.call(not panel._enemy_pending, "enemy resumes when one of its powers is ready")
	panel.close_panel()
	check.call(not hud.any_modal_open() and not game._input_locked, "closing full arena restores world controls")

static func _quiet(lobby: Lobby) -> void:
	for child in lobby.get_children():
		if child is Enemy or child is Resident or child is Pet:
			child.set_physics_process(false)
	for gun in lobby.get_tree().get_nodes_in_group("house_defenses"):
		gun.set_process(false)

static func _find_button(node: Node, caption: String) -> Button:
	if node is Button and node.text == caption:
		return node
	for child in node.get_children():
		var found := _find_button(child, caption)
		if found:
			return found
	return null
