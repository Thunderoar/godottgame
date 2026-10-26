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
			{"name": "Tournament Guardians", "actor": "pet", "rows": [["pet", "enemy:fire", "hp_down"], ["pet", "enemy:urchin", "shield"]]},
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
			{"name": "Bogling", "actor": "enemy:bogling", "rows": [["enemy:bogling", "path", "player"], ["boss:grotto_warden", "call", "enemy:bogling"]]},
			{"name": "Drowned", "actor": "enemy:drowned", "rows": [["enemy:drowned", "path", "player"], ["boss:drowned_king", "call", "enemy:drowned"]]},
		]
	elif category == 2:
		for id in PortalDB.ordered_ids():
			var boss := PortalDB.get_portal(id)
			pages.append({"name": boss.get("boss_name", "Boss"), "actor": "boss:" + str(boss.get("boss_id", "grotto_warden")), "rows": [["ability:" + str(boss.get("boss_ability", "punch")), "player", "hp_down"], ["call", "enemy:" + str(boss.get("monster_kind", "bogling")), "player"]]})
	else:
		pages = [
			{"name": "Three Friends · Another Dimension", "actor": "hero:adam", "rows": [["hero:adam", "hero:arjun", "hero:mei_ling"], ["ship", "kraken", "house"]], "description": "Arjun hooks the Kraken while fishing. Their ship breaks into three pieces. The Kraken imprisons Arjun; monsters capture Mei Ling. A turtle saves Adam and brings him to BESUT in another dimension."},
			{"name": "Turtle Journey · Three Sea Routes", "actor": "turtle", "rows": [["turtle", "bomb", "hp_down"], ["food", "heart", "hp_up"]], "description": "Start at 2.5x speed with 3 lives. Use the joystick or W/S to move vertically. Pick Up rubbish for Gold. Eat food without healing; Eat a pink heart to restore one life. Dodge moving bombs. A hit makes the turtle blink briefly; losing every life flips and sinks it. Complete three 45-second routes to reach Kraken Island."},
			{"name": "Rescue Arjun", "actor": "hero:arjun", "rows": [["turtle", "kraken", "prison"], ["hero:arjun", "ship", "house"]], "description": "Reach the last sea destination, defeat Vorath the Kraken King, then walk to the prison and press Use. Arjun boards the ship, returns to BESUT, and becomes a scythe defender."},
			{"name": "Rescue Mei Ling", "actor": "hero:mei_ling", "rows": [["player", "boss:abyss_sovereign", "hero:mei_ling"], ["hero:mei_ling", "portal", "house"]], "description": "Clear the final Monster Portal: Drowned Throne. Mei Ling follows Adam through the exit and becomes a bow defender in BESUT. Rescue both friends to see the ending; village life continues afterward."},
		]
	return pages

static func description(entry: Dictionary) -> String:
	if entry.has("description"): return str(entry.description)
	var actor := str(entry.get("actor", ""))
	if actor.begins_with("npc:"): return NpcInfo.description(actor.get_slice(":", 1))
	if actor == "hut": return "TOWER DEFENSE · Buy rooftop machine guns at the Weapons Shop. Choose an intact house. Each paid mount attacks fire monsters and sea urchins; the central house tier improves fire rate."
	if actor == "pet": return "TOURNAMENT GUARDIANS · Win pet duels to recruit the rival. Recruits stay in BESUT, cannot die, and defend the village from both fire monsters and sea urchins."
	if actor == "enemy:fire": return "FIRE MONSTER · Ignites mature trees and can attack exposed residents or the player. Water Keepers extinguish fire. Fire-monster combat and burning-tree sound effects are silent."
	if actor == "enemy:urchin": return "SEA URCHIN · A physical attacker from the sea. It threatens trees, buildings, residents and the player. Intact houses shelter residents; defenders, guns and allies fight back."
	if actor.begins_with("boss:"): return "PORTAL BOSS · Pursues you after its arrival warning. Dodge its marked special attack and the arena rune traps. Defeat it to bank rewards and unlock the next portal. The final boss holds Mei Ling captive."
	return "Stay moving and attack with your basic weapon. Drops are collected automatically. Learn each warning and keep health potions ready."
