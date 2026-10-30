class_name FieldGuideDB
extends RefCounted
## Names identify pages; all behavior is explained by the illustrated rows.

static func entries(category: int) -> Array[Dictionary]:
	var pages: Array[Dictionary] = []
	if category == 0:
		pages = [
			{"name": "Water Keeper", "actor": "npc:water_keeper", "rows": [["water", "tree_fire", "tree_heal"], ["water", "enemy:fire", "hp_down"]]},
			{"name": "Builder", "actor": "npc:construction_worker", "rows": [["house_broken", "hammer", "house"], ["sun", "time:10s", "fence"]]},
			{"name": "Tree Planter", "actor": "npc:tree_planter", "rows": [["stump", "seed", "sapling"], ["sapling", "time:30s", "tree"]]},
			{"name": "Swordsman", "actor": "npc:swordsman", "rows": [["sword", "enemy:urchin", "hp_down"], ["enemy:urchin", "shield", "house"]]},
			{"name": "Rooftop Machine Gun", "actor": "hut", "rows": [["gold", "house", "hut"], ["hut", "enemy:urchin", "hp_down"]]},
			{"name": "Bonded Guardians", "actor": "pet", "rows": [["pet", "enemy:fire", "hp_down"], ["pet", "enemy:urchin", "shield"]]},
			{"name": "Mission Guide", "actor": "npc:mission_guide", "rows": [["question", "touch", "path"], ["sun", "moon", "question"]]},
			{"name": "Mara · Potion Shop", "actor": "npc:potion", "rows": [["gold", "touch", "potion"], ["potion", "pack", "hp_up"]]},
			{"name": "Ilan · Equipment Shop", "actor": "npc:equipment", "rows": [["gold", "touch", "sword"], ["wood", "touch", "gold"]]},
			{"name": "Nia · Pet Shop", "actor": "npc:pet", "rows": [["gold", "touch", "pet"], ["food", "pet", "level_up"]]},
			{"name": "Bram · Construction Shop", "actor": "npc:builder", "rows": [["diamond", "house", "level_up"], ["hut", "fence", "workers"]]},
			{"name": "Worker Shop", "actor": "npc:construction_worker", "rows": [["gold", "touch", "workers"], ["house", "level_up", "workers"]]},
			{"name": "UniSZA Student", "actor": "npc:student", "rows": [["touch", "dialogue", "university"], ["npc:student", "player", "dialogue"]]},
			{"name": "Coastal Guard", "actor": "npc:guard", "rows": [["trash", "net", "gold"], ["player", "trash", "gold"]]},
		]
		var residents := [["Sami", "fisher", "fish"], ["Hana & Laila", "gardener", "garden"], ["Rami", "carpenter", "hammer"], ["Daud", "woodcutter", "wood"], ["Noor", "keeper", "goat"], ["Bilal", "farmer", "garden"], ["Yusuf", "trader", "shop"], ["Tomas & Sora", "defender", "fence"], ["Amir", "stablehand", "horse"], ["Zara", "resident", "house"]]
		for npc in residents:
			pages.append({"name": npc[0], "actor": "npc:" + str(npc[1]), "rows": [["sun", str(npc[2]), "npc:" + str(npc[1])], ["enemy:urchin", "house", "shield"]]})
	elif category == 1:
		pages = [
			{"name": "Fire Monster", "actor": "enemy:fire", "rows": [["tree", "flame", "stump"], ["player", "enemy:fire", "hp_down"]]},
			{"name": "Sea Urchin", "actor": "enemy:urchin", "rows": [["tree", "fence", "house_broken"], ["player", "enemy:urchin", "hp_down"]]},
			{"name": "Sea Urchins · Residents", "actor": "enemy:urchin", "rows": [["enemy:urchin", "house", "shield"], ["house_broken", "enemy:urchin", "grave"]]},
			{"name": "Bogling", "actor": "enemy:bogling", "rows": [["enemy:bogling", "path", "player"], ["boss:demon_chaos", "call", "enemy:bogling"]]},
			{"name": "Drowned", "actor": "enemy:drowned", "rows": [["enemy:drowned", "path", "player"], ["boss:drowned_king", "call", "enemy:drowned"]]},
			{"name": "Kraken Island Crab", "actor": "enemy:crab", "rows": [["enemy:crab", "path", "player"], ["player", "sword", "enemy:crab"]], "description": "Ten armoured crabs guard the Kraken fortress. Entering the arena makes all ten crabs and the Kraken King attack Adam immediately. Crabs skitter toward him and raise their claws before pinching. Dodge the warning or interrupt with a hit. Defeated crabs drop Gold. Surviving guards retreat when the Kraken King falls, leaving Arjun's prison safe to approach."},
		]
	elif category == 2:
		for id in PortalDB.ordered_ids():
			var boss := PortalDB.get_portal(id)
			pages.append({"description": str(boss.get("lore","")), "name": boss.get("boss_name", "Boss"), "actor": "boss:" + str(boss.get("boss_id", "grotto_warden")), "rows": [["ability:" + str(boss.get("boss_ability", "punch")), "player", "hp_down"], ["call", "enemy:" + str(boss.get("monster_kind", "bogling")), "player"]]})
	else:
		pages = [
			{"name": "Three Friends · Another Dimension", "actor": "hero:adam", "rows": [["hero:adam", "hero:arjun", "hero:mei_ling"], ["ship", "kraken", "house"]], "description": "Arjun hooks the Kraken while fishing. Their ship breaks into three pieces. The Kraken imprisons Arjun. Mei Ling washes ashore on the broken bow at a guarded ruin; its sentries take the outsider alive for their ruler. A turtle saves Adam and brings him to BESUT in another dimension."},
			{"name": "Turtle Journey · Two Sea Levels", "actor": "turtle", "rows": [["food", "fullness", "turtle"], ["trash_missed", "turtle", "hp_down"]], "description": "Start at 2.5x travel speed with 3 lives. Swim equally fast forwards, backwards, up and down. Below 50% FULLNESS, swimming and travel slow by 30%; 0% FULLNESS is fatal. Use the joystick or WASD to swim up, down, forwards and backwards. Collect every piece of rubbish for Gold: each uncollected piece that escapes or is left at route end costs one life, even while blinking. Swim near fish: the turtle eats automatically to refill FULLNESS instead of healing. Use Pick Up/E only for rubbish. Keep eating fish before FULLNESS empties. Nearby pink hearts are collected automatically to restore one life. Level 1 has bombs, rubbish, pink hearts and fish. Level 2 adds open-jaw sharks; dodge both hazards. Missed objects continue offscreen, and the portrait timeline shows progress toward Arjun. A hit makes the turtle blink briefly; losing every life flips and sinks it. After the first 45-second level, the turtle swims forwards into level 2. Completing level 2 carries Adam onward to Kraken Island."},
			{"name": "Rescue Arjun", "actor": "hero:arjun", "rows": [["turtle", "kraken", "prison"], ["hero:arjun", "ship", "house"]], "description": "Reach the last sea destination and defeat Vorath the Kraken King in his stone fortress. Dodge the orange warning before the tentacle extends; its hook can catch and drag Adam. Another arm holds Arjun's prison. After victory, walk to the prison and tap it. Arjun boards the ship, returns to BESUT, and becomes a scythe defender. His rescue completes the sea journey. After returning, the ship stays moored and cannot be boarded again in this journey."},
			{"name": "Rescue Mei Ling", "actor": "hero:mei_ling", "rows": [["player", "boss:demon_chaos", "hero:mei_ling"], ["hero:mei_ling", "portal", "house"]], "description": "Enter the Dimension Portal, explore Twilight Wilds and defeat Shadow & Chaos Fiend in Chaos Citadel. His defeat breaks her prison seal. Watch Adam reach Mei Ling, then see her pass through the rift to safety in BESUT. She becomes a bow defender while Adam may keep exploring. Later bosses are optional challenges, not rescue requirements. Rescue both friends, then return safely to BESUT for their reunion conversation. A quiet dock scene hints at their next journey; village life continues afterward."},
			{"name": "Twilight Wilds", "actor": "pet", "rows": [["portal", "path", "pet"], ["player", "boss:demon_chaos", "house"]], "description": "Enter the Dimension Portal directly. Follow old stones, pawprints and pool lights to explore. Challenge wild pets with Attack, Shield and Special; outside combat waits during the challenge, and losing is peaceful. First bonds persist even if a later expedition fails. The watchpost winch opens a shortcut. Rest at the citadel lantern to heal and save a checkpoint. The fiend awakens only after crossing the inner arch. Retreat to reset an unfinished fight. Victory restores the realm and opens onward passages. The arrival rift always banks carried loot and returns to BESUT. Wisp, the optional Waykeeper, notices your discoveries. Read three weathered stones to keep their memories in this Field Guide. A rootway hollow holds one small Gold gift: return safely to bank it."},
		]
		var lights: Array = []
		if not GameState.portal_opened():
			pages[3] = {"name": "Looking for Mei Ling", "actor": "hero:mei_ling", "rows": [["hero:adam","question","hero:mei_ling"]], "description": "Adam does not yet know where to search. Meet the villagers and examine the old stones in the northern clearing. Pak Rahim may recognize their markings."}
			pages[4] = {"name": "The Old Waystone", "actor": "spark", "rows": [["question","path","spark"]], "description": GameState.portal_origin_instruction()}
		for id in RealmContentDB.FRAGMENTS:
			lights.append("spark" if id in GameState.realm_progress().get("read_fragments", []) else "question")
		pages.append({"name": "Memories of Twilight", "actor": "portal", "rows": [lights], "memory_journal": true})
	if category == 1:
		pages.append({"name":"Darkfire Imp", "actor":"realm_guard:imp", "rows":[["path","player","sword"]], "description":"TWILIGHT PATROL · The Imp stops to mark a rush, then charges along that fixed line. Step sideways and counter during recovery. Only one local pair pursues you; pet clearings and the citadel lantern are refuges."})
		pages.append({"name":"Ember Watcher", "actor":"realm_guard:watcher", "rows":[["bow","path","player"]], "description":"WATCHPOST GUARD · Three marked lanes show the Watcher's fan before it fires. Its aim stays fixed. Walk into a gap, approach from the side, or use the stone cover. A whole volley can hit once. Its lantern dims during recovery."})
		pages.append({"name":"Rune Keeper", "actor":"realm_guard:keeper", "rows":[["spark","path","player"]], "description":"ASHEN SENTRY · The Keeper marks a short cross at your position, then briefly activates it. Walk diagonally into a clear quadrant. The mark never follows you, and its intersection is one hit. Returning to the lantern ends pursuit."})
	return pages

static func description(entry: Dictionary) -> String:
	if bool(entry.get("memory_journal", false)): return RealmContentDB.journal(GameState.realm_progress())
	if entry.has("description"): return str(entry.description)
	var actor := str(entry.get("actor", ""))
	if actor.begins_with("npc:"): return NpcInfo.description(actor.get_slice(":", 1))
	if actor == "hut": return "TOWER DEFENSE · Buy rooftop machine guns at the Weapons Shop. Choose an intact house. Each paid mount attacks fire monsters and sea urchins; the central house tier improves fire rate."
	if actor == "pet": return "BONDED GUARDIANS · Explore Twilight Wilds through the Dimension Portal. Approach Bramble Cat or Dusk Moth and challenge them in their habitat. Win a manual duel to form a lasting bond. Recruits also defend BESUT from fire monsters and sea urchins; existing tournament recruits remain yours."
	if actor == "enemy:fire": return "FIRE MONSTER · Each new arrival crosses its own small ember portal, which seals behind it. Ignites mature trees and can attack exposed residents or the player. Defeating it does not extinguish a burning tree; Water Keepers do. Fire-monster combat and burning-tree sound effects are silent."
	if actor == "enemy:urchin": return "SEA URCHIN · A physical attacker from the sea. It threatens trees, buildings, residents and the player. Intact houses shelter residents; defenders, guns and allies fight back."
	if actor.begins_with("boss:"): return "PORTAL BOSS · Pursues you after its arrival warning. Dodge its marked special attack and the arena rune traps. Defeat it to bank rewards and unlock the next portal. Shadow & Chaos Fiend holds Mei Ling captive in Chaos Citadel."
	return "Stay moving and attack with your basic weapon. Drops are collected automatically. Learn each warning and keep health potions ready."
