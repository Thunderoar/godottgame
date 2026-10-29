class_name NpcInfo
extends Node
## Tap real villagers to inspect their actual job, powers and working rules.
static func description(role: String) -> String:
	match role:
		"water", "water_keeper": return "WATER KEEPER · Throws water at fire monsters and extinguishes burning trees. Walks to a tree before healing it. Hire more at the Worker Shop."
		"builder", "construction_worker": return "BUILDER · Repairs damaged houses and fences during the day. Work takes 10 seconds after reaching the structure. The main-house level raises the worker baseline."
		"planter", "tree_planter": return "TREE PLANTER · Plants a new sapling at a lost tree. Saplings are protected while growing for 30 seconds. Protect every tree: losing the entire forest ends the journey."
		"fighter", "swordsman", "defender": return "SWORDSMAN · Patrols BESUT and attacks nearby sea urchins. Protect the houses where vulnerable residents shelter."
		"potion": return "POTION MERCHANT · Sells health potions. Buy with Gold, then use them from Pack. Mana and player skills are no longer used."
		"equipment": return "WEAPONS & TOWER DEFENSE · Basic swords, armour and shields are available from arrival. Restore Bram's West Workshop after Chaos Citadel to license advanced swords. Buy rooftop machine guns for intact houses here. Guns target fire monsters and sea urchins. Sell gathered wood for Gold."
		"pet": return "PET KEEPER · Feed and select your owned companions here. Bond with wild companions in Twilight Wilds to recruit village guardians. Luma joins after Chaos Citadel."
		"house": return "CONSTRUCTION MERCHANT · Upgrade the main house using Diamonds. Its level improves village houses, worker baselines, fences and purchased rooftop guns. After Chaos Citadel, commission the free West Workshop restoration. Builders work there by day, or you can help at its workbench."
		"services": return "WORKER SHOP · Hire Water Keepers, Builders, Tree Planters and Swordsmen. Each specialist has a different job."
		"guard": return "COASTAL GUARD · Catches floating rubbish for one Gold. If rubbish reaches the beach, approach it and press Pick Up. Each piece pays only once."
		"mission_guide": return "MISSION GUIDE · Follow the current task's dotted arrows. Day lessons cover village life; night lessons teach defense and the first portal boss. Use Menu to reopen tips."
		"arjun": return "ARJUN · Rescued from the Kraken King's prison. His powerful scythe now guards BESUT against fire monsters and sea urchins."
		"mei_ling": return "MEI LING · Rescued from the final portal boss. She now protects BESUT with ranged bow attacks against fire monsters and sea urchins."
		"student": return "UNISZA STUDENT · A friendly visitor in BESUT. Talk to learn about the students who made this adventure."
	return "BESUT RESIDENT · Works around the village during peaceful hours. Runs to an intact house when threatened. Builders repair damaged homes by day."

func _unhandled_input(event: InputEvent) -> void:
	var at := Vector2.ZERO
	if event is InputEventScreenTouch and event.pressed: at = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed: at = event.position
	else: return
	var game := get_tree().get_first_node_in_group("game") as Game
	if not is_instance_valid(game) or not game.world is Lobby or game._input_locked or game._transitioning or game.world._settlement_editor.active: return
	var point := game.world.get_canvas_transform().affine_inverse() * at
	var selected: Node2D
	var best := INF
	for group in ["residents", "village_heroes", "village_pets", "interactable"]:
		for node in get_tree().get_nodes_in_group(group):
			if not is_instance_valid(node) or not node is Node2D or node.is_queued_for_deletion() or not game.world.is_ancestor_of(node): continue
			if group == "interactable" and not (node is MissionNPC or node is AuthoredInteraction or node is CoastalGuard or node is UniszaStudent): continue
			if node is Resident and (node.dead or node.sheltered): continue
			if node.get_parent() is Resident and (node.get_parent().dead or node.get_parent().sheltered): continue
			var distance: float = (node.global_position + Vector2(0, -0.6)).distance_to(point)
			if distance < 0.85 and distance < best:
				selected = node
				best = distance
	if not is_instance_valid(selected): return
	if selected is UniszaStudent:
		selected.interact(game.player())
		get_viewport().set_input_as_handled()
		return
	var title := "BESUT Resident"
	var role := "resident"
	if selected is Resident:
		title = selected.resident_name
		role = selected.worker_role if not selected.worker_role.is_empty() else ("water" if selected.water_power else selected.role)
	elif selected is VillageHero:
		role = selected.hero_id
		title = CharacterDB.get_character(role).get("name", "Friend")
	elif selected is VillagePet:
		title = PetDB.name_of(selected.pet_id)
		game.open_dialogue(title, ["BONDED GUARDIAN · Recruited through a companion challenge. Cannot die. Patrols the village and attacks fire monsters and sea urchins."])
		get_viewport().set_input_as_handled()
		return
	elif selected is CoastalGuard: title = "Coastal Guard"; role = "guard"
	elif selected is MissionNPC: title = "Mission Guide"; role = "mission_guide"
	elif selected is AuthoredInteraction:
		title = selected.speaker
		role = "student" if title.to_lower().contains("unisza") else "resident"
	var project_lines := GameState.village_npc_lines(title)
	game.open_dialogue(title, project_lines if not project_lines.is_empty() else [description(role)] + ([str(selected.activity)] if selected is Resident else []))
	get_viewport().set_input_as_handled()
