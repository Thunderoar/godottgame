class_name SideQuestDB
extends RefCounted
## Location-bound introductions only. Acceptance, battles and rewards keep their owners.
const IDS := ["workshop", "bramble_cat", "dusk_moth"]
const RADIUS := 3.6

static func eligible(world: Node, id: String) -> bool:
	if not is_instance_valid(world) or world.is_queued_for_deletion(): return false
	if id == "workshop" and world is Lobby:
		var status := GameState.project_status()
		return bool(status.get("eligible", false)) and str(status.get("state", "")) == "not_started"
	if world is TwilightRealm and id in RealmDB.ENCOUNTERS:
		return not GameState.realm_pet_bonded(id) and GameState.get_pet(id).is_empty() and is_instance_valid(world.wildlife.get(id))
	return false

static func nearby(world: Node, actor: Node2D) -> Dictionary:
	if not is_instance_valid(actor): return {}
	if world is Lobby and eligible(world, "workshop"):
		if is_instance_valid(world.workshop) and actor.global_position.distance_to(world.workshop.workpoint()) <= RADIUS:
			return {"id": "workshop", "speaker": "West Workshop · Bram's notice", "lines": ["Adam: Someone has pinned a note beside the old workbench.", "Bram's note: Rami and I can restore this cottage for the village. Since the citadel is safe, the restoration is free. Visit the Construction Shop, or tap this workbench to commission it.", "A restored workshop licenses Garrick's advanced swords; weapons are purchased separately. Builders work by day when it is safe, and you can help at the bench."]}
		for npc in world.get_tree().get_nodes_in_group("ambient_shop"):
			if is_instance_valid(npc) and not npc.is_queued_for_deletion() and npc.get_parent().get_parent() == world and npc.shop_type == "house" and actor.global_position.distance_to(npc.global_position) <= RADIUS:
				return {"id": "workshop", "speaker": "Overheard · Construction Shop", "lines": ["Bram: That western cottage needn't stay a ruin. Rami and I could make a proper village workshop of it.", "Bram: With the citadel cleared, we can offer the restoration for free. Speak to me about village plans, or tap the workshop's workbench to commission it.", "A restored workshop licenses Garrick's advanced swords; weapons are purchased separately. Builders work by day when safe. You can help at the bench, too."]}
	if world is TwilightRealm:
		for id in ["bramble_cat", "dusk_moth"]:
			if eligible(world, id) and actor.global_position.distance_to(world.wildlife[id].global_position) <= RADIUS:
				if id == "bramble_cat":
					return {"id": id, "speaker": "Bramble Grove · A nearby rustle", "lines": ["A soft scratch comes from beneath the violet leaves. A watchful Bramble Cat studies Adam from the clearing.", "Adam: You're guarding this place, aren't you? Maybe we don't have to be enemies.", "Approach and tap Bramble Cat to choose its optional, manual pet challenge. Listening does not start a battle or spend anything."]}
				return {"id": id, "speaker": "Moonpool Hollow · Wings over water", "lines": ["A hush of wings drifts across the moonpool. A Dusk Moth settles nearby, curious rather than hostile.", "Adam: Easy. We can get to know one another without disturbing your home.", "Approach and tap Dusk Moth to choose its optional, manual pet challenge. You can leave and return whenever you are ready."]}
	return {}
