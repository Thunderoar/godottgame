class_name ObjectiveTrackerData
extends RefCounted
## Read-only HUD guidance. World context takes precedence over village lessons.

const LESSON_HINTS := {
	"move": "Walk to the yard marker. Use WASD or the joystick; Shift or Sprint runs.",
	"gather": "Approach the driftwood, then tap it or press E to collect wood.",
	"buy": "Visit Mara's Potion Shop and buy a Health Potion.",
	"inventory": "Open Pack or press I to inspect your equipment and supplies.",
	"fire_kill": "Find a fire monster and defeat it with F or Attack. Protect the trees.",
	"services": "Visit the Worker Shop to meet the water keepers.",
	"house": "Visit Bram's Construction Shop to learn about repairs and upgrades.",
	"feed": "Buy Pet Food at Nia's, then feed your companion from the shop or Pack.",
	"portal": "Enter the Dimension Portal to explore Twilight Wilds.",
	"boss": "Return through the Dimension Portal and continue toward the citadel.",
}

static func entries(world: Node, counts: Dictionary = {}) -> Array[Dictionary]:
	if not is_instance_valid(world) or world.is_queued_for_deletion(): return []
	if world is TwilightRealm: return _twilight(world)
	if world is Dungeon:
		if world._boss_defeated:
			return [_entry("return", "Return to BESUT", "Use the exit rift, or explore the onward passage.", "EXPEDITION")]
		var definition := PortalDB.get_portal(world.portal_id)
		return [_entry("boss", "Defeat %s" % str(definition.get("boss_name", "the ruler")), "Dodge the marked attacks. Your companion fights beside you.", "EXPEDITION")]
	if world is KrakenIsland:
		if bool(GameState.campaign().get("arjun_rescued", false)):
			return [_entry("shore", "Return to BESUT" if world.defeated else "Challenge the Kraken King", "Arjun is safe. You can return through the shore exit.", "ISLAND")]
		if world.defeated:
			return [_entry("free_arjun", "Free Arjun", "Approach and tap his prison. Defeating the Kraken unlocks the cage.", "RESCUE")]
		return [_entry("kraken", "Defeat the Kraken King", "Avoid his marked strikes to unlock Arjun's prison.", "RESCUE")]
	if world is Lobby: return _village(counts)
	return []

static func _village(counts: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if GameState.recovery_active():
		out.append(_entry("recovery", "Recover at the cottage", "Rest in the recovery ward before heading out again.", "RECOVERY"))
	elif GameState.emergency_active() or int(counts.get("fires", 0)) > 0 or int(counts.get("monsters", 0)) > 0:
		out.append(_entry("defend", "Defend BESUT", "Fight the attackers and protect the residents and burning trees.", "URGENT", true))
	var lesson := MissionDB.step(GameState.mission_step())
	if not lesson.is_empty():
		var title := str(lesson.get("title", "Learn to play"))
		if title.contains(". "): title = title.substr(title.find(". ") + 2)
		out.append(_entry("lesson_" + str(lesson.event), title, str(LESSON_HINTS.get(str(lesson.event), "Follow the village path markers.")), "NIGHT TRAINING" if GameState.is_night() else "DAY TRAINING"))
	elif not GameState.tutorial_complete():
		out.append(_entry("phase", "Prepare for dawn" if GameState.is_night() else "Prepare for night", "This phase's lessons are complete. Help the village and keep supplies ready.", "TRAINING"))
	else:
		var project := GameState.project_status()
		if bool(project.get("eligible", false)) and str(project.state) != "complete":
			var working := str(project.state) == "working"
			var detail := "Visit Bram's Construction Shop to commission the free restoration."
			var row := _entry("workshop", "Restore the West Workshop", detail, "VILLAGE")
			if working:
				row.detail = "Work resumes by day. You can help at the workbench." if GameState.is_night() else "Builders work on site when it is safe. Help at the workbench."
				row.progress = clampf(1.0 - float(project.remaining) / VillageProjectDB.WORK_SECONDS, 0, 1)
			out.append(row)
		out.append_array(_rescue_entries())
		if out.is_empty():
			out.append(_entry("home", "Care for BESUT", "Your friends are home. Explore, improve the village and protect its forest.", "VILLAGE"))
	return out.slice(0, 3)

static func _rescue_entries() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var story := GameState.campaign()
	if not bool(story.get("arjun_rescued", false)):
		out.append(_entry("arjun", "Rescue Arjun", "Board the ship. Sea route %d of 3 leads toward Kraken Island." % int(story.get("ocean_stage", 1)), "STORY"))
	if not bool(story.get("mei_ling_rescued", false)):
		out.append(_entry("mei_ling", "Rescue Mei Ling", "Follow the onward passages beyond the restored citadel to the final ruler.", "STORY"))
	return out

static func _twilight(realm: TwilightRealm) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var progress := GameState.realm_progress()
	var landmarks: Array = progress.get("landmarks", [])
	if realm._boss_defeated:
		out.append(_entry("restored", "Explore the restored Wilds", "The citadel is peaceful. Return through a rift whenever you are ready.", "EXPLORE"))
		if not bool(GameState.campaign().get("mei_ling_rescued", false)):
			out.append(_entry("onward", "Continue Mei Ling's rescue", "The onward passages have level requirements. Check the signs before entering.", "STORY"))
	elif realm._boss_arrived:
		out.append(_entry("citadel_boss", "Defeat Shadow & Chaos Fiend", "Dodge his marked attacks. Leaving the arena resets this encounter.", "BOSS"))
	elif "citadel" in landmarks or "approach" in landmarks:
		if str(progress.get("checkpoint", "arrival")) != "camp":
			out.append(_entry("checkpoint", "Rest at the lantern", "Use the lantern to recover and save your checkpoint before the citadel.", "PREPARE"))
		out.append(_entry("citadel", "Enter Chaos Citadel", "Cross the inner arch when you are ready to face its ruler.", "EXPLORE"))
	else:
		out.append(_entry("explore", "Explore Twilight Wilds", "Follow the old stones and discover the paths. The arrival rift leads home.", "EXPLORE"))
	var known_pets: Array[String] = []
	for pair in [["grove", "bramble_cat"], ["pool", "dusk_moth"]]:
		if pair[0] in landmarks and not GameState.realm_pet_bonded(str(pair[1])) and GameState.get_pet(str(pair[1])).is_empty():
			known_pets.append(str(RealmDB.ENCOUNTERS[pair[1]].name))
	if not known_pets.is_empty():
		out.append(_entry("companions", "Befriend a wild companion", "Approach %s to choose a challenge." % " or ".join(known_pets), "OPTIONAL"))
	return out.slice(0, 3)

static func _entry(id: String, title: String, detail: String, tag: String, urgent: bool = false) -> Dictionary:
	return {"id": id, "title": title, "detail": detail, "tag": tag, "urgent": urgent, "progress": -1.0}
