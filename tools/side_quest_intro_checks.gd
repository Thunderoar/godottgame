extends RefCounted
## Real map triggers, lifecycle ownership and save-compatible one-time discovery.
static func run(game: Game, check: Callable, capture: Callable = Callable()) -> void:
	var saved := GameState.data.duplicate(true)
	var processing := game.is_processing()
	var autosave := GameState.autosave_enabled
	var auto_enabled := game._side_quest_auto_enabled
	var was_visible := game.hud.visible
	var dimensions := game.get_window().size
	var canvas := game.get_window().content_scale_size
	game.set_process(false)
	game._side_quest_auto_enabled = false
	game.hud.hide_modals()
	GameState.autosave_enabled = false
	GameState.data = GameState._make_default("adam")
	GameState._emit_all()
	await game._load_lobby(false)
	game.world.process_mode = Node.PROCESS_MODE_DISABLED
	game.hud.visible = true
	var home := game.world as Lobby
	var actor := game.player()
	actor.global_position = home.workshop.workpoint() + Vector2(0, 2)
	check.call(not game._try_side_quest_introduction(), "a locked workshop cannot introduce an unavailable side quest")
	GameState.data.portals[RealmDB.PORTAL].cleared = true
	var origin := actor.global_position
	actor.global_position += Vector2(0, 12)
	check.call(not game._try_side_quest_introduction(), "available side quests do not interrupt distant players")
	actor.global_position = origin
	var project := GameState.project_status().duplicate(true)
	var gold := GameState.gold()
	var diamonds := GameState.diamonds()
	home.process_mode = Node.PROCESS_MODE_INHERIT
	var mode := home.process_mode
	actor.velocity = Vector2(2, 0)
	Input.action_press("move_right")
	check.call(game._try_side_quest_introduction(), "approaching the eligible workshop triggers its nearby notice introduction")
	check.call(game._story_active and actor.controls_locked and actor.velocity == Vector2.ZERO and home.process_mode == Node.PROCESS_MODE_DISABLED, "introduction immediately stops the player and owns local world suspension")
	check.call(not Input.is_action_pressed("move_right") and not game.get_tree().paused, "introduction releases held synthetic controls without globally pausing the tree")
	var clock := float(GameState.data.world_time)
	var position := actor.global_position
	game._process(2)
	check.call(float(GameState.data.world_time) == clock and actor.global_position == position, "reading cannot advance village time or move the player")
	check.call(not game._try_side_quest_introduction(), "an active introduction cannot nest or open twice")
	check.call(not GameState.side_quest_intro_seen("workshop") and GameState.project_status() == project, "displaying the introduction neither records completion nor commissions restoration")
	if capture.is_valid():
		for size in [Vector2i(1280,720), Vector2i(832,480)]:
			game.get_window().content_scale_size = size
			game.get_window().size = size
			for frame in 6: await game.get_tree().process_frame
			await capture.call("workshop_%dx%d" % [size.x,size.y])
			check.call(game.hud.dialogue_panel.get_viewport_rect().encloses(game.hud.dialogue_panel.panel.get_global_rect()), "discovery dialogue fits %dx%d" % [size.x,size.y])
	game.hud.dialogue_panel._close_button.pressed.emit()
	check.call(GameState.side_quest_intro_seen("workshop") and not actor.controls_locked and not game._story_active and home.process_mode == mode, "closing or skipping records only the introduction and restores control ownership")
	check.call(GameState.project_status() == project and GameState.gold() == gold and GameState.diamonds() == diamonds, "listening spends nothing and never starts construction or grants rewards")
	check.call(not game._try_side_quest_introduction() and not GameState.mark_side_quest_intro_seen("workshop"), "the same introduction never repeats or commits twice")
	check.call(not GameState.mark_side_quest_intro_seen("unknown"), "unknown discovery IDs cannot enter saved progression")
	GameState.save_game()
	GameState.data.side_quest_intros_seen = []
	check.call(GameState.load_game() and GameState.side_quest_intro_seen("workshop"), "heard introductions survive the actual JSON save/load path")
	GameState.data.side_quest_intros_seen = ["workshop", "workshop", "unknown", 5]
	GameState._sanitize_side_quest_intros()
	check.call(GameState.data.side_quest_intros_seen == ["workshop"], "malformed, duplicate and unknown saved introduction IDs are sanitized")
	GameState.data.side_quest_intros_seen = {"workshop": true}
	GameState._sanitize_side_quest_intros()
	check.call(GameState.data.side_quest_intros_seen.is_empty(), "a malformed saved introduction container falls back safely")
	GameState.data.side_quest_intros_seen = []
	GameState.data.world_time = 180.0
	check.call(not game._try_side_quest_introduction(), "nighttime village danger cannot stop the player for side content")
	GameState.data.world_time = 0.0
	game.open_menu()
	check.call(not game._try_side_quest_introduction(), "open menus defer unsolicited side-quest introductions")
	game.hud.menu_panel.close_panel()
	actor.sleeping = true
	check.call(not game._try_side_quest_introduction(), "sleeping players are not interrupted")
	actor.sleeping = false
	actor.attacking = true
	check.call(not game._try_side_quest_introduction(), "active weapon attacks cannot be interrupted by discovery")
	actor.attacking = false
	actor.controls_locked = true
	check.call(not game._try_side_quest_introduction(), "another owner's player lock cannot be replaced by side content")
	actor.controls_locked = false
	var enemy := Enemy.new()
	enemy.position = actor.position + Vector2(1,0)
	home.add_child(enemy)
	check.call(not game._try_side_quest_introduction(), "nearby living threats defer an otherwise eligible introduction")
	enemy.queue_free()
	await game.get_tree().process_frame
	var tree: ForestTree = home._forest_trees[0]
	var tree_position := tree.position
	tree.position = actor.position + Vector2(1,0)
	tree.burning = true
	check.call(not game._try_side_quest_introduction(), "nearby burning trees defer the introduction instead of freezing a rescue situation")
	tree.burning = false
	tree.position = tree_position
	var shop: ShopNPC
	for npc in game.get_tree().get_nodes_in_group("ambient_shop"):
		if npc.get_parent().get_parent() == home and npc.shop_type == "house": shop = npc
	check.call(shop != null, "the real Construction Shop merchant can introduce the workshop")
	if shop != null:
		actor.global_position = shop.global_position + Vector2(0,2)
		check.call(game._try_side_quest_introduction() and game.hud.dialogue_panel._speaker.contains("Overheard"), "approaching Bram's actual counter triggers the overheard variant")
		game.hud.dialogue_panel.close_panel()
	GameState.data.side_quest_intros_seen = []
	actor.global_position = home.workshop.workpoint() + Vector2(0,2)
	game._side_quest_auto_enabled = true
	game._side_quest_timer = 0.0
	game._process(0.31)
	check.call(not game._side_quest_intro.is_empty(), "normal Game processing discovers the quest through proximity without a tap")
	game._side_quest_auto_enabled = false
	await game._load_lobby(false)
	check.call(game._side_quest_intro.is_empty() and not game._story_active and not GameState.side_quest_intro_seen("workshop"), "world replacement cancels the old introduction without marking it heard")
	game.world.process_mode = Node.PROCESS_MODE_DISABLED
	GameState.data.side_quest_intros_seen = []
	GameState.start_expedition(RealmDB.PORTAL)
	await game._load_dungeon(RealmDB.PORTAL, false)
	var realm := game.world as TwilightRealm
	realm.process_mode = Node.PROCESS_MODE_DISABLED
	for id in ["bramble_cat", "dusk_moth"]:
		game.player().position = realm.wildlife[id].position + Vector2(0,2)
		check.call(game._try_side_quest_introduction(), "approaching the habitat introduces " + id)
		check.call(not game.hud.pet_battle_panel.is_wild_challenge() and GameState.get_pet(id).is_empty(), "habitat introduction never starts a battle or recruits " + id)
		if capture.is_valid():
			for frame in 6: await game.get_tree().process_frame
			await capture.call(id)
		game.hud.dialogue_panel.close_panel()
		check.call(GameState.side_quest_intro_seen(id) and not game._try_side_quest_introduction(), "heard habitat introduction does not repeat: " + id)
	GameState.data.side_quest_intros_seen = []
	GameState.data.realm_progress.bonded.append("bramble_cat")
	game.player().position = realm.wildlife.bramble_cat.position + Vector2(0,2)
	check.call(not game._try_side_quest_introduction(), "bonded companions do not advertise an unfinished recruitment quest")
	GameState.data = GameState._make_default("adam")
	check.call(GameState.data.side_quest_intros_seen.is_empty(), "new journeys start with fresh discoveries rather than device-level heard flags")
	game._clear_world()
	await game.get_tree().process_frame
	GameState.data = saved
	GameState._emit_all()
	game.get_window().content_scale_size = canvas
	game.get_window().size = dimensions
	await game._load_lobby(false)
	game._side_quest_auto_enabled = auto_enabled
	game.hud.visible = was_visible
	GameState.autosave_enabled = autosave
	game.set_process(processing)
