extends RefCounted
## State, save migration and both rescue orders; all saves belong to isolated fixtures.

static func run(game: Game, check: Callable, capture: Callable = Callable()) -> void:
	var saved := GameState.data.duplicate(true)
	var autosave := GameState.autosave_enabled
	var ticking := game.is_processing()
	game.set_process(false)
	GameState.autosave_enabled = false
	game.hud.hide_modals()
	game._clear_world()
	await game.get_tree().process_frame
	GameState.data = GameState._make_default("adam")
	check.call(PortalDB.MEI_LING_PORTAL == RealmDB.PORTAL and str(PortalDB.get_portal(PortalDB.MEI_LING_PORTAL).boss_name) == "Shadow & Chaos Fiend", "Mei Ling belongs to Shadow & Chaos Fiend in the first realm")
	check.call(not bool(GameState.campaign().mei_ling_rescued), "fresh journeys keep Mei Ling missing")
	for id in ["sunken_crypt", "drowned_throne"]:
		GameState.data = GameState._make_default("adam")
		var later := GameState.complete_portal(id)
		check.call(not bool(GameState.campaign().mei_ling_rescued) and str(later.rescued_friend).is_empty(), "%s no longer owns Mei Ling's rescue" % id)
	GameState.data = GameState._make_default("adam")
	var observations: Array[bool] = []
	var observe := func() -> void:
		if bool(GameState.portal_state(PortalDB.MEI_LING_PORTAL).cleared): observations.append(bool(GameState.campaign().mei_ling_rescued))
	GameState.data_changed.connect(observe)
	var first := GameState.complete_portal(PortalDB.MEI_LING_PORTAL)
	GameState.data_changed.disconnect(observe)
	check.call(not observations.is_empty() and not observations.has(false), "every clear-state notification already contains Mei Ling rescue")
	check.call(first.first and first.rescued_friend == "mei_ling" and bool(GameState.campaign().mei_ling_rescued), "the clear transaction itself rescues Mei Ling before presentation")
	check.call(not bool(GameState.campaign().arjun_rescued) and not GameState.friends_reunited(), "Mei Ling's rescue never bypasses Arjun's separate prison")
	check.call(not bool(GameState.portal_state("sunken_crypt").cleared) and not bool(GameState.portal_state("drowned_throne").cleared), "later bosses remain uncleared optional challenges")
	var repeat := GameState.complete_portal(PortalDB.MEI_LING_PORTAL)
	check.call(not repeat.first and str(repeat.rescued_friend).is_empty() and str(repeat.pet).is_empty(), "repeated clears cannot replay rescue or grant first-clear pets")
	GameState.save_game()
	check.call(GameState.load_game() and bool(GameState.campaign().mei_ling_rescued), "first-boss rescue persists through actual JSON reload")
	# Existing peaceful realms do not respawn the boss, so their clear earns the moved rescue.
	GameState.data = GameState._make_default("adam")
	GameState.data.portals.tidebound_grotto = {"cleared": true, "unlocked": true, "attempts": 7}
	GameState.data.gold = 777
	GameState.data.diamonds = 33
	GameState.data.xp = 12
	GameState.data.campaign.arjun_rescued = true
	GameState.save_game()
	var legacy_pets: Dictionary = GameState.data.pets.duplicate(true)
	check.call(GameState.load_game() and GameState.friends_reunited(), "an old first-clear save credits Mei Ling without requiring an impossible rematch")
	check.call(GameState.gold() == 777 and GameState.diamonds() == 33 and int(GameState.data.xp) == 12 and JSON.parse_string(JSON.stringify(GameState.data.pets)) == JSON.parse_string(JSON.stringify(legacy_pets)) and int(GameState.portal_state(PortalDB.MEI_LING_PORTAL).attempts) == 7, "rescue migration preserves currency, XP, pets and attempt history without rewards")
	GameState.save_game()
	check.call(GameState.load_game() and GameState.friends_reunited() and GameState.gold() == 777, "moved-rescue migration is idempotent on a second reload")
	GameState.data = GameState._make_default("adam")
	GameState.data.campaign.mei_ling_rescued = true
	GameState.save_game()
	check.call(GameState.load_game() and bool(GameState.campaign().mei_ling_rescued), "previously rescued Mei Ling remains rescued even without a first-clear record")
	GameState.data = GameState._make_default("adam")
	GameState.save_game()
	check.call(GameState.load_game() and not bool(GameState.campaign().mei_ling_rescued), "loading an uncleared save does not rescue Mei Ling")
	# Real first-boss signal, player-paced story and peaceful continuation: Mei Ling first.
	GameState.data = GameState._make_default("adam")
	GameState.data.portal_origin.opened = true # Rescue fixture begins after the separately tested waystone restoration.
	GameState.data.campaign.intro_seen = true
	GameState.data.campaign.dock_welcome_seen = true
	GameState._emit_all()
	check.call(GameState.start_expedition(PortalDB.MEI_LING_PORTAL), "Mei Ling's rescue is accessible at level one after restoring the waystone")
	await game._load_dungeon(PortalDB.MEI_LING_PORTAL, false)
	var realm := game.world as TwilightRealm
	check.call(is_instance_valid(realm.mei_prison) and not realm.mei_prison.opened and realm.mei_prison.position == RealmDB.MEI_PRISON and realm.mei_prison.get_child_count() == 0, "fiend's arena contains a visible nonblocking captive prison")
	realm.player.invulnerable = 1000
	realm.player.position = RealmDB.BOSS_THRESHOLD
	realm._physics_process(0.1)
	if capture.is_valid(): await capture.call("00_captive_arena")
	realm.boss.take_damage(999999, Vector2.ZERO, realm.player)
	await game.get_tree().process_frame
	var story := _story(game)
	check.call(bool(GameState.campaign().mei_ling_rescued) and story != null and story.kind == "mei", "actual fiend defeat immediately frees Mei Ling and starts her rescue scene")
	check.call(realm._boss_defeated and game._story_active and realm.process_mode == Node.PROCESS_MODE_DISABLED and realm.player.controls_locked, "rescue scene owns input and safely suspends the restored realm")
	check.call(realm.mei_prison.opened, "boss-clear transaction immediately leaves an open empty prison in the restored world")
	check.call(not realm.boss.visible, "suspended death tween cannot reveal the fiend's corpse after his animated defeat")
	if story != null: await preload("res://tools/mei_ling_animatic_checks.gd").inspect_story(game, realm, story, check, capture)
	if capture.is_valid(): await capture.call("01_mei_freed")
	if story != null: story.finish()
	await game.get_tree().process_frame
	check.call(game.world == realm and not game._story_active and not realm.player.controls_locked and not game.hud.victory_panel.visible, "closing rescue restores peaceful exploration without a victory modal or forced exit")
	check.call(not bool(GameState.campaign().ending_seen) and not GameState.friends_reunited(), "Mei Ling-first order cannot trigger a premature reunion")
	var gold := GameState.gold()
	realm._on_boss_finished(null)
	check.call(GameState.gold() == gold and _story(game) == null, "duplicate boss-finished signals cannot duplicate rescue scenes or rewards")
	await preload("res://tools/mei_ling_animatic_checks.gd").completion_paths(game, check)
	realm = game.world as TwilightRealm
	GameState.save_game()
	check.call(GameState.load_game() and bool(GameState.campaign().mei_ling_rescued), "interrupted post-rescue visit retains the saved rescue")
	await game._load_dungeon(PortalDB.MEI_LING_PORTAL, false)
	realm = game.world as TwilightRealm
	check.call(realm._boss_defeated and not is_instance_valid(realm.boss) and _story(game) == null, "revisiting the restored citadel respawns neither boss nor rescue scene")
	check.call(realm.mei_prison.opened, "reloaded peaceful realm retains the open empty prison")
	if capture.is_valid(): await capture.call("02_peaceful_revisit")
	realm.exit_to_lobby(true)
	for frame in 120:
		if game.world is Lobby and not game._transitioning: break
		await game.get_tree().create_timer(0.025).timeout
	await game.get_tree().process_frame
	check.call(game.world is Lobby and _heroes(game.world, "mei_ling") == 1 and _heroes(game.world, "arjun") == 0, "Mei Ling returns as exactly one bow defender while Arjun is still missing")
	if capture.is_valid(): await capture.call("03_mei_home")
	GameState.rescue_friend("arjun")
	game.world._sync_rescued_friends()
	game._check_campaign_ending()
	story = _story(game)
	check.call(story != null and story.kind == "ending", "rescuing Arjun second triggers the same reunion ending")
	if story != null: story.finish()
	await game.get_tree().process_frame
	check.call(bool(GameState.campaign().ending_seen) and _heroes(game.world, "mei_ling") == 1 and _heroes(game.world, "arjun") == 1, "Mei Ling-first ending persists with exactly two village defenders")
	game._check_campaign_ending()
	check.call(_story(game) == null, "completed reunion never replays")
	GameState.data = saved
	GameState._emit_all()
	await game._load_lobby(false)
	GameState.autosave_enabled = autosave
	game.set_process(ticking)

static func _story(game: Game) -> StorySequence:
	for child in game.get_children():
		if child is StorySequence and not child.is_queued_for_deletion(): return child
	return null

static func _heroes(world: Node, id: String) -> int:
	var count := 0
	for child in world.get_children():
		if child is VillageHero and child.hero_id == id: count += 1
	return count
