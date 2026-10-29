class_name WorldTally
extends RefCounted
## Read only, current-world census. Never infer living actors from visibility/groups.
static func snapshot(world: Node) -> Dictionary:
	if not is_instance_valid(world) or not world.is_inside_tree() or world.is_queued_for_deletion(): return {}
	if not (world is Lobby or world is Dungeon or world is KrakenIsland): return {}
	var result := {"village": world is Lobby, "npc_alive": 0, "npc_total": 0,
		"workers_alive": 0, "workers_total": 0, "monsters": 0, "fire_monsters": 0,
		"urchins": 0, "trees_alive": 0, "trees_total": 0, "saplings": 0,
		"fires": 0, "homes_intact": 0, "homes_total": 0}
	var pending: Array[Node] = [world]
	while not pending.is_empty():
		var node := pending.pop_back() as Node
		if not is_instance_valid(node) or node.is_queued_for_deletion(): continue
		if node is Enemy:
			if not node.dead and node.hp > 0:
				result.monsters += 1
				if node.kind == "fire": result.fire_monsters += 1
				if node.kind == "urchin": result.urchins += 1
		elif node is Resident:
			result.npc_total += 1
			if not node.dead: result.npc_alive += 1
			if not node.worker_role.is_empty():
				result.workers_total += 1
				if not node.dead: result.workers_alive += 1
		elif node is ShopNPC or node is CoastalGuard or node is MissionNPC or node is UniszaStudent or node is VillageHero:
			result.npc_total += 1
			result.npc_alive += 1
		elif node is ForestTree:
			# Fallen trees leave the forest_tree group but remain replantable nodes.
			result.trees_total += 1
			if node.is_alive():
				result.trees_alive += 1
				if node.growth_remaining > 0: result.saplings += 1
				if node.burning and node.is_attackable(): result.fires += 1
		elif node is SettlementTarget and node.structure_kind == "house" and not node.structure_id.is_empty():
			result.homes_total += 1
			if node.is_intact(): result.homes_intact += 1
		pending.append_array(node.get_children())
	return result
