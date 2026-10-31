class_name ObjectiveNavigation
extends RefCounted
## Resolve a selected objective against live actors/layout. Never changes progress.

static func target(world: Node2D, id: String) -> Dictionary:
	if not is_instance_valid(world) or world.is_queued_for_deletion(): return {}
	var player: Player = world.get_player() if world.has_method("get_player") else world.get("player")
	if not is_instance_valid(player): return {}
	if id == "lesson_inventory": return {"control": "inventory", "label": "Open Pack"}
	var game := world.get_tree().get_first_node_in_group("game") as Game
	if is_instance_valid(game) and is_instance_valid(game.home_interior):
		return _point(game.home_interior._exit.global_position + Vector2(0,-1.6), "Leave Home")
	if world is Lobby: return _village(world, id)
	if world is TwilightRealm: return _realm(world, id)
	if world is Dungeon:
		if id == "return":
			for node in world.get_children():
				if node is PortalExit: return _point(node.global_position, "Shore Gate")
		if is_instance_valid(world.boss) and not world.boss.dead:
			return _point(world.boss.global_position, "Boss")
	if world is KrakenIsland:
		if id == "free_arjun": return _point(world.cage.global_position + Vector2(0,2), "Arjun's Prison")
		if id == "kraken" and is_instance_valid(world.boss): return _point(world.boss.global_position, "Kraken King")
		if id == "shore":
			for node in world.get_children():
				if node is KrakenIsland.IslandExit: return _point(node.global_position, "Return to BESUT")
	return {}

static func _village(home: Lobby, id: String) -> Dictionary:
	if id == "arjun": return _point(home.ship_boarding.global_position, "Board the Ship")
	if id in ["mei_ling", "waystone", "lesson_portal", "lesson_boss"]:
		if not GameState.portal_opened() and not GameState.portal_key_received() and bool(GameState.portal_origin().get("site_examined", false)):
			var host := home.get_node_or_null("PakRahim") as DockHost
			if is_instance_valid(host): return _point(host.global_position + Vector2(0,1), "Pak Rahim · Portal Key")
		return _point(home._layout.approach("monster_portal"), "Dimension Portal" if GameState.portal_opened() else ("Unlock the Portal" if GameState.portal_key_received() else "Northern Clearing"))
	if id == "workshop":
		if str(GameState.project_status().state) == "working" and is_instance_valid(home.workshop):
			return _point(home.workshop.workpoint(), "West Workshop")
		return _shop(home, "house")
	if id in ["defend", "lesson_fire_kill"]:
		var enemies: Array[Node2D] = []
		for node in home.get_tree().get_nodes_in_group("enemies"):
			if _owned(home,node) and not node.dead and (id == "defend" or node.kind == "fire"): enemies.append(node)
		var enemy := _nearest(home.player.global_position, enemies)
		if enemy != null: return _point(enemy.global_position, "Defend BESUT")
		var fires: Array[Node2D] = []
		for tree in home._forest_trees:
			if _owned(home,tree) and tree.burning and tree.health > 0: fires.append(tree)
		var fire := _nearest(home.player.global_position, fires)
		if fire != null: return _point(fire.global_position + Vector2(0,1.4), "Burning Tree")
		return {}
	if id == "lesson_gather":
		var piles: Array[Node2D] = []
		for node in home.get_tree().get_nodes_in_group("interactable"):
			if node is ResourcePile and _owned(home,node) and node.is_interactable_available(): piles.append(node)
		var pile := _nearest(home.player.global_position, piles)
		return _point(pile.global_position, "Driftwood") if pile != null else {}
	var shops := {"lesson_buy":"potion", "lesson_services":"services", "lesson_house":"house", "lesson_feed":"pet"}
	if id in shops: return _shop(home, str(shops[id]))
	if id == "lesson_move": return _point(home.get_spawn_position() + Vector2(3.5,0), "Yard Marker")
	if id in ["recovery", "home", "phase"]:
		return _point(home._recovery_center if id == "recovery" else home._house_position + Vector2(0,2), "Cottage")
	return {}

static func _realm(realm: TwilightRealm, id: String) -> Dictionary:
	if id in ["arjun", "return", "restored"]: return _point(RealmDB.RETURN_RIFT, "Return to BESUT")
	if id == "checkpoint": return _point(RealmDB.CAMP, "Citadel Lantern")
	if id in ["citadel", "citadel_boss", "mei_ling"]:
		return _point(realm.boss.global_position if is_instance_valid(realm.boss) else RealmDB.BOSS_THRESHOLD, "Chaos Citadel")
	var landmarks: Array = GameState.realm_progress().get("landmarks", [])
	if id == "explore":
		for landmark in ["crossing", "grove", "watchpost", "pool", "approach", "citadel"]:
			if landmark not in landmarks:
				return _point(RealmDB.LANDMARKS[landmark].at, str(RealmDB.LANDMARKS[landmark].name))
	if id == "companions":
		var pets: Array[Node2D] = []
		for pair in [["grove","bramble_cat"],["pool","dusk_moth"]]:
			var pet: Variant = realm.wildlife.get(pair[1])
			if pair[0] in landmarks and _owned(realm,pet) and not GameState.realm_pet_bonded(pair[1]) and GameState.get_pet(pair[1]).is_empty(): pets.append(pet)
		var nearest := _nearest(realm.player.global_position, pets)
		if nearest != null: return _point(nearest.global_position, "Wild Companion")
	return {}

static func _shop(home: Lobby, kind: String) -> Dictionary:
	for node in home.get_tree().get_nodes_in_group("ambient_shop"):
		if _owned(home,node) and node.shop_type == kind: return _point(node.customer_position(), node.npc_name + "'s Shop")
	return {}

static func _point(at: Vector2, label: String) -> Dictionary:
	return {"position": at, "label": label, "color": GameUI.GOLD}

static func _owned(world: Node, actor: Variant) -> bool:
	return is_instance_valid(actor) and not actor.is_queued_for_deletion() and world.is_ancestor_of(actor)

static func _nearest(from: Vector2, actors: Array[Node2D]) -> Node2D:
	var best: Node2D
	var distance := INF
	for actor in actors:
		var next := from.distance_squared_to(actor.global_position)
		if next < distance:
			distance = next
			best = actor
	return best
