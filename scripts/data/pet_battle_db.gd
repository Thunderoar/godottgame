class_name PetBattleDB
extends RefCounted
## Five-level 1v1 companion tournament reached through the Pet Battle Portal.
## Each duel uses the active companion's real level and rewards pet XP + gold.

const LEVELS := {
	"pet_duel_1": {
		"order": 1,
		"name": "Clover Ring",
		"subtitle": "First Duel",
		"lore": "A friendly sparring circle behind the cottage. Every champion starts here.",
		"pet_level": 1,
		"opponent_name": "Sparring Ember",
		"opponent_pet": "ember",
		"opponent_tint": Color("#f3b16d"),
		"hp": 42,
		"damage": 5,
		"interval": 1.55,
		"gold": 25,
		"xp": 35,
	},
	"pet_duel_2": {
		"order": 2,
		"name": "Bramble Court",
		"subtitle": "Second Duel",
		"lore": "Marsh cats duel among the brambles. Patience wins more bouts than speed.",
		"pet_level": 2,
		"opponent_name": "Bramble Cat",
		"opponent_pet": "moss",
		"opponent_tint": Color("#a8c275"),
		"hp": 58,
		"damage": 7,
		"interval": 1.42,
		"gold": 45,
		"xp": 55,
	},
	"pet_duel_3": {
		"order": 3,
		"name": "Moonlit Ring",
		"subtitle": "Third Duel",
		"lore": "The moth's wings scatter pale light across the sand. Keep your footing.",
		"pet_level": 3,
		"opponent_name": "Dusk Moth",
		"opponent_pet": "luma",
		"opponent_tint": Color("#c3b4ff"),
		"hp": 76,
		"damage": 9,
		"interval": 1.3,
		"gold": 70,
		"xp": 80,
	},
	"pet_duel_4": {
		"order": 4,
		"name": "Storm Terrace",
		"subtitle": "Fourth Duel",
		"lore": "A storm fox guards the high terrace. Its paws crackle before every lunge.",
		"pet_level": 4,
		"opponent_name": "Storm Fox",
		"opponent_pet": "ember",
		"opponent_tint": Color("#9fd7ff"),
		"hp": 96,
		"damage": 11,
		"interval": 1.18,
		"gold": 100,
		"xp": 110,
	},
	"pet_duel_5": {
		"order": 5,
		"name": "Tideworn Crown",
		"subtitle": "Final Duel",
		"lore": "The tide-cat waits at the crown of the arena. Only a max-level companion can answer.",
		"pet_level": 5,
		"opponent_name": "Tidecat Sovereign",
		"opponent_pet": "moss",
		"opponent_tint": Color("#74e0d7"),
		"hp": 124,
		"damage": 14,
		"interval": 1.05,
		"gold": 150,
		"xp": 150,
	},
}


static func get_level(level_id: String) -> Dictionary:
	return (LEVELS.get(level_id, {}) as Dictionary).duplicate(true)


const ORDER := [
	"pet_duel_1", "pet_duel_2", "pet_duel_3", "pet_duel_4", "pet_duel_5",
]


static func ordered_ids() -> Array[String]:
	var ids: Array[String] = []
	for level_id in ORDER:
		if LEVELS.has(level_id):
			ids.append(level_id)
	return ids


static func name_of(level_id: String) -> String:
	return str(LEVELS.get(level_id, {}).get("name", level_id.capitalize()))
