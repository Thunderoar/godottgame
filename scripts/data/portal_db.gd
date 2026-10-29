class_name PortalDB
extends RefCounted
## Three stable campaign stages. Twilight Wilds authors six local encounters for
## stage 1; the two later arenas retain the level-three/five rescue unlock chain.

## Retained only for save migration; these realms cannot be entered.
const RETIRED_IDS := ["reef_hollow", "brine_cavern", "kelp_maze", "bone_gallery", "storm_shrine", "coral_throne", "abyss_gate"]

const PORTALS := {
	"tidebound_grotto": {
		"name": "Chaos Citadel",
		"subtitle": "Demon Pembunuh Bayangan",
		"level_required": 1,
		"theme": "chaos",
		"monster_kind": "minion_chaos",
		"monster_level": 1,
		"monster_count": 6,
		"element": "chaos",
		"boss_id": "demon_chaos",
		"boss_name": "Shadow & Chaos Fiend",
		"hazard_damage": 5,
		"hazard_cycle": 4.60,
		"hazard_layout": 0,
		"boss_hp": 420,
		"boss_damage": 18,
		"boss_speed": 1.7,
		"boss_ability": "chaos",
		"boss_ability_name": "Dark Blaze / Mirage Assault / Chaos Crossfire",
		"boss_projectile_damage": 10,
		"boss_special_cooldown": 3.6,
		"unlocks": "sunken_crypt",
		"rewards_first": {"gold": 160, "diamonds": 8, "xp": 90, "pet": "luma"},
		"rewards_repeat": {"gold": 100, "diamonds": 3, "xp": 40},
		"lore": "Demon Pembunuh Bayangan. Three powers guard this realm: Dark Blaze, Mirage Assault, Chaos Crossfire.",
	},
	"sunken_crypt": {
		"name": "Tempest Spire",
		"subtitle": "Tuan Angin Pusaran",
		"level_required": 3,
		"theme": "wind",
		"monster_kind": "minion_wind",
		"monster_level": 3,
		"monster_count": 14,
		"element": "wind",
		"boss_id": "demon_wind",
		"boss_name": "Gale Tempest Demon",
		"hazard_damage": 7,
		"hazard_cycle": 4.45,
		"hazard_layout": 1,
		"boss_hp": 760,
		"boss_damage": 26,
		"boss_speed": 1.9,
		"boss_ability": "wind",
		"boss_ability_name": "Razor Tornado / Gale Blades / Cyclone Uplift",
		"boss_projectile_damage": 16,
		"boss_special_cooldown": 4.2,
		"unlocks": "drowned_throne",
		"rewards_first": {"gold": 360, "diamonds": 14, "xp": 180},
		"rewards_repeat": {"gold": 220, "diamonds": 6, "xp": 80},
		"lore": "Tuan Angin Pusaran. Three powers guard this realm: Razor Tornado, Gale Blades, Cyclone Uplift.",
	},
	"drowned_throne": {
		"name": "Abyssal Throne",
		"subtitle": "Raja Iblis Utama",
		"level_required": 5,
		"theme": "dark",
		"monster_kind": "minion_dark",
		"monster_level": 5,
		"monster_count": 12,
		"element": "dark",
		"boss_id": "demon_dark",
		"boss_name": "Abyss Monarch",
		"hazard_damage": 9,
		"hazard_cycle": 4.30,
		"hazard_layout": 2,
		"boss_hp": 1120,
		"boss_damage": 30,
		"boss_speed": 2.1,
		"boss_ability": "dark",
		"boss_ability_name": "Black-Hole Dominion / Sovereign Souls / Pure-Darkness Apocalypse",
		"boss_projectile_damage": 15,
		"boss_special_cooldown": 3.8,
		"unlocks": "",
		"rewards_first": {"gold": 650, "diamonds": 20, "xp": 320},
		"rewards_repeat": {"gold": 360, "diamonds": 9, "xp": 120},
		"lore": "Raja Iblis Utama. Three powers guard this realm: Black-Hole Dominion, Sovereign Souls, Pure-Darkness Apocalypse.",
	},
}


static func get_portal(portal_id: String) -> Dictionary:
	return (PORTALS.get(portal_id, {}) as Dictionary).duplicate(true)


static func ordered_ids() -> Array[String]:
	return [
		"tidebound_grotto",
		"sunken_crypt",
		"drowned_throne",
	]
