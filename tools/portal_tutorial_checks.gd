extends RefCounted

static func run(game: Game, check: Callable) -> void:
	var snapshot := GameState.data.duplicate(true)
	var ticking := game.is_processing()
	game.set_process(false)
	GameState.data = GameState._make_default("adam")
	GameState._emit_all()
	game.hud.start_tutorial()
	check.call(not GameState.tutorial_complete() and game.hud.tutorial_guide.visible, "new journey begins with active tutorial")
	GameState.advance_world_clock(180)
	check.call(GameState.start_expedition("tidebound_grotto"), "tutorial battle starts in Portal 1 at night")
	GameState.record_mission_event("portal")
	GameState.advance_world_clock(180)
	check.call(not GameState.is_night() and not GameState.tutorial_complete(), "entering Portal 1 alone does not complete tutorial")
	GameState.complete_portal("tidebound_grotto")
	check.call(GameState.tutorial_complete() and GameState.mission_step() == MissionDB.STEPS.size(), "first portal clear completes tutorial after clock changes to day")
	check.call("boss" in GameState.data.completed_missions and not game.hud.tutorial_guide.visible, "daytime victory records boss lesson and hides tutorial")
	check.call(bool(GameState.portal_state("sunken_crypt").get("unlocked")) and not bool(GameState.portal_state("sunken_crypt").get("cleared")), "Portal 2 unlocks without being required for tutorial completion")
	check.call(not bool(GameState.portal_state("drowned_throne").get("cleared")) and not bool(GameState.campaign().get("mei_ling_rescued")), "tutorial victory preserves final boss and Mei Ling rescue campaign")
	GameState.advance_world_clock(180)
	game.hud.start_tutorial()
	check.call(GameState.tutorial_complete() and not game.hud.tutorial_guide.visible, "next night and show-tips cannot restart finished tutorial")
	GameState.data.completed_missions = []
	GameState.save_game()
	GameState.data = GameState._make_default("adam")
	check.call(GameState.load_game() and GameState.tutorial_complete() and GameState.mission_step() == MissionDB.STEPS.size(), "older save with first portal cleared needs no repeat battle")
	GameState.data = GameState._make_default("adam")
	GameState.complete_portal("sunken_crypt")
	check.call(not GameState.tutorial_complete(), "later portal clear cannot substitute for Portal 1")
	# The shorter campaign preserves its tutorial, final rescue and old save progress.
	var active := PortalDB.ordered_ids()
	check.call(active == ["tidebound_grotto", "sunken_crypt", "drowned_throne"] and PortalDB.PORTALS.size() == 3, "exactly three portal bosses remain in campaign order")
	check.call(FieldGuideDB.entries(2).size() == 3, "the field guide contains only the three active portal bosses")
	GameState.data = GameState._make_default("adam")
	check.call(GameState.data.portals.size() == 3 and not bool(GameState.portal_state("drowned_throne").unlocked), "new journeys have three portal records with the finale initially sealed")
	GameState.complete_portal("tidebound_grotto")
	GameState.complete_portal("sunken_crypt")
	check.call(bool(GameState.portal_state("drowned_throne").unlocked), "defeating the second boss unlocks Abyssal Throne directly")
	GameState.data.level = 4
	check.call(not GameState.can_enter_portal("drowned_throne"), "the final portal still enforces its level gate")
	GameState.data.level = 5
	check.call(GameState.can_enter_portal("drowned_throne") and int(PortalDB.get_portal("drowned_throne").monster_level) == 5 and int(PortalDB.get_portal("drowned_throne").boss_hp) == 1120, "the final encounter uses level-five pacing rather than the retired level-twenty-five stats")
	game.hud.portal_panel.open_portals()
	# ModalBase builds after a frame and retires old controls via queue_free.
	await game.get_tree().process_frame
	await game.get_tree().process_frame
	var cards := game.hud.portal_panel.content.get_children().filter(func(node: Node) -> bool: return node.has_meta("portal_id"))
	check.call(cards.size() == 3, "the post-tutorial portal menu shows exactly three boss cards")
	game.hud.portal_panel.close_panel()
	GameState.data = GameState._make_default("adam")
	GameState.data.portals.sunken_crypt.cleared = true
	GameState.save_game()
	check.call(GameState.load_game() and bool(GameState.portal_state("drowned_throne").unlocked), "an older second-boss clear unlocks the new finale after save reload")
	var retired := ["reef_hollow", "brine_cavern", "kelp_maze", "bone_gallery", "storm_shrine", "coral_throne", "abyss_gate"]
	for retired_id in retired:
		check.call(PortalDB.get_portal(retired_id).is_empty() and not GameState.start_expedition(retired_id), "%s is retired and cannot be entered" % retired_id)
		GameState.data = GameState._make_default("adam")
		GameState.data.gold = 777
		GameState.data.campaign.arjun_rescued = true
		GameState.data.portals[retired_id] = {"unlocked": true, "cleared": false, "attempts": 2}
		GameState.data.expedition = {"active": true, "portal_id": retired_id, "gold": 337, "diamonds": 4, "items": {"wood": 2}}
		GameState.save_game()
		var loaded := GameState.load_game()
		var bag := GameState.expedition_loot()
		check.call(loaded and GameState.expedition_portal() == "drowned_throne" and bool(GameState.portal_state("drowned_throne").unlocked) and not bool(GameState.portal_state("drowned_throne").cleared), "%s active save redirects to the uncleared final portal" % retired_id)
		check.call(GameState.gold() == 777 and int(bag.gold) == 337 and int(bag.diamonds) == 4 and int(bag.items.get("wood", 0)) == 2 and bool(GameState.campaign().arjun_rescued) and int(GameState.portal_state(retired_id).attempts) == 2, "%s migration preserves banked currency, carried loot, rescue flags and attempt history" % retired_id)
		GameState.save_game()
		check.call(GameState.load_game() and GameState.expedition_portal() == "drowned_throne" and GameState.gold() == 777 and int(GameState.expedition_loot().gold) == 337, "%s migration is idempotent on another save reload" % retired_id)
	GameState.data = GameState._make_default("adam")
	GameState.data.portals.drowned_throne = {"unlocked": true, "cleared": true, "attempts": 4}
	GameState.data.campaign.mei_ling_rescued = true
	GameState.data.gold = 888
	GameState.save_game()
	check.call(GameState.load_game() and bool(GameState.portal_state("drowned_throne").cleared) and bool(GameState.campaign().mei_ling_rescued) and GameState.gold() == 888, "existing final clears and Mei Ling rescue persist without replaying rewards")
	GameState.data = snapshot
	GameState._emit_all()
	GameState.save_game()
	game.set_process(ticking)
