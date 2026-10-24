class_name FieldGuideDB
extends RefCounted
## Names identify pages; all behavior is explained by the illustrated rows.

static func entries(category: int) -> Array[Dictionary]:
	var pages: Array[Dictionary] = []
	if category == 0:
		pages = [
			{"name": "Penjaga Air", "actor": "npc:water_keeper", "rows": [["water", "tree_fire", "tree_heal"], ["water", "enemy:fire", "hp_down"]]},
			{"name": "Pekerja Binaan", "actor": "npc:construction_worker", "rows": [["house_broken", "hammer", "house"], ["sun", "time:10s", "fence"]]},
			{"name": "Penanam", "actor": "npc:tree_planter", "rows": [["stump", "seed", "sapling"], ["sapling", "time:30s", "tree"]]},
			{"name": "Pendekar", "actor": "npc:swordsman", "rows": [["sword", "enemy:urchin", "hp_down"], ["enemy:urchin", "shield", "house"]]},
			{"name": "Pemanah", "actor": "hut", "rows": [["bow", "enemy:urchin", "hp_down"], ["house", "level_up", "hut"]]},
			{"name": "Panduan Misi", "actor": "npc:mission_guide", "rows": [["question", "touch", "path"], ["sun", "moon", "question"]]},
			{"name": "Mara · Kedai Potion", "actor": "npc:potion", "rows": [["gold", "touch", "potion"], ["potion", "pack", "hp_up"]]},
			{"name": "Ilan · Kedai Peralatan", "actor": "npc:equipment", "rows": [["gold", "touch", "sword"], ["wood", "touch", "gold"]]},
			{"name": "Nia · Kedai Pet", "actor": "npc:pet", "rows": [["gold", "touch", "pet"], ["food", "pet", "level_up"]]},
			{"name": "Bram · Kedai Binaan", "actor": "npc:builder", "rows": [["diamond", "house", "level_up"], ["hut", "fence", "workers"]]},
			{"name": "Kedai Pekerja", "actor": "npc:construction_worker", "rows": [["gold", "touch", "workers"], ["house", "level_up", "workers"]]},
			{"name": "Pelajar UniSZA", "actor": "npc:student", "rows": [["touch", "dialogue", "university"], ["npc:student", "player", "dialogue"]]},
			{"name": "Penjaga Pantai", "actor": "npc:guard", "rows": [["trash", "net", "gold"], ["sea", "trash", "enemy:urchin"]]},
		]
		var residents := [["Sami", "fisher", "fish"], ["Hana & Laila", "gardener", "garden"], ["Rami", "carpenter", "hammer"], ["Daud", "woodcutter", "wood"], ["Noor", "keeper", "goat"], ["Bilal", "farmer", "garden"], ["Yusuf", "trader", "shop"], ["Tomas & Sora", "defender", "fence"], ["Amir", "stablehand", "horse"], ["Zara", "resident", "house"]]
		for npc in residents:
			pages.append({"name": npc[0], "actor": "npc:" + str(npc[1]), "rows": [["sun", str(npc[2]), "npc:" + str(npc[1])], ["enemy:urchin", "house", "shield"]]})
	elif category == 1:
		pages = [
			{"name": "Monster Api", "actor": "enemy:fire", "rows": [["moon", "enemy:fire", "enemy_day:fire"], ["tree", "flame", "stump"]]},
			{"name": "Landak Laut", "actor": "enemy:urchin", "rows": [["sea", "moon", "enemy:urchin"], ["tree", "fence", "house_broken"]]},
			{"name": "Landak Laut · Penduduk", "actor": "enemy:urchin", "rows": [["enemy:urchin", "house", "shield"], ["house_broken", "enemy:urchin", "grave"]]},
			{"name": "Bogling", "actor": "enemy:bogling", "rows": [["enemy:bogling", "path", "player"], ["boss:grotto_warden", "call", "enemy:bogling"]]},
			{"name": "Drowned", "actor": "enemy:drowned", "rows": [["enemy:drowned", "path", "player"], ["boss:drowned_king", "call", "enemy:drowned"]]},
		]
	else:
		for id in PortalDB.ordered_ids():
			var boss := PortalDB.get_portal(id)
			pages.append({"name": boss.get("boss_name", "Boss"), "actor": "boss:" + str(boss.get("boss_id", "grotto_warden")), "rows": [["ability:" + str(boss.get("boss_ability", "punch")), "player", "hp_down"], ["call", "enemy:" + str(boss.get("monster_kind", "bogling")), "player"]]})
	return pages
