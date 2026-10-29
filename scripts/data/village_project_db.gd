class_name VillageProjectDB
extends RefCounted
## Stable project identities. Civic progress is separate from shared house quality.

const WORKSHOP := "west_workshop"
const WORKSHOP_ANCHOR := "AbandonedHouse"
const WORKSHOP_STRUCTURE := "home_abandoned_house"
const WORK_SECONDS := 10.0
const ADVANCED_SWORDS := ["tideblade", "emberfang", "glacial_edge", "tempest_saber", "thorncrown_blade", "stormbreaker", "soulrender", "monarch_slayer"]

static func get_project(id: String) -> Dictionary:
	if id != WORKSHOP: return {}
	return {"id": WORKSHOP, "name": "A Roof for the Workshop", "place": "West Workshop", "anchor": WORKSHOP_ANCHOR, "structure": WORKSHOP_STRUCTURE, "portal": "tidebound_grotto", "seconds": WORK_SECONDS, "gold": 0,
		"description": "Bram and Rami can turn the abandoned western cottage into a shared workshop. A place to work, and another roof for BESUT.",
		"benefit": "Licenses Garrick's advanced swords, starting with Tideblade (240 Gold). Weapons are purchased separately. The completed cottage also shelters villagers.",
		"work": "A builder works here by day. You can also approach and tap the workbench to help for free. Work pauses at night or when danger is nearby."}

static func ordered_ids() -> Array[String]:
	return [WORKSHOP]

static func default_progression(legacy: bool = false) -> Dictionary:
	return {"schema": 1, "legacy_access": legacy, "tracked_project": "", "projects": {WORKSHOP: {"state": "not_started", "remaining": WORK_SECONDS}}}

static func npc_lines(speaker: String) -> Array:
	if speaker == "Rami":
		return ["Bram has a plan for the abandoned western cottage. A shared workshop would give us room to make better blades."]
	return []
