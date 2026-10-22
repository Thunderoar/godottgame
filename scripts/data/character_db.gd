class_name CharacterDB
extends RefCounted
## Three male heroes sharing one storyline and three distinct weapons.

const CHARACTERS := [
	{
		"id": "qayyim",
		"name": "Qayyim",
		"title": "Coastblade",
		"hp": 105,
		"mana": 45,
		"attack": 1,
		"defense": 0,
		"speed": 4.4,
		"weapon": "Sword",
		"weapon_style": "sword",
		"starter_weapon": "rusty_sword",
		"attack_cooldown": 0.38,
		"attack_range": 2.05,
		"attack_mult": 1.0,
		"tint": Color("#d9ad83"),
		"hair": Color("#513326"),
		"accent": Color("#3f7f72"),
		"description": "A balanced swordhand. Quick steel, clean footwork, no wasted motion.",
	},
	{
		"id": "farhan",
		"name": "Farhan",
		"title": "Forgeguard",
		"hp": 135,
		"mana": 28,
		"attack": 0,
		"defense": 3,
		"speed": 3.9,
		"weapon": "Hammer",
		"weapon_style": "hammer",
		"starter_weapon": "smith_hammer",
		"attack_cooldown": 0.64,
		"attack_range": 2.55,
		"attack_mult": 1.35,
		"tint": Color("#b9845c"),
		"hair": Color("#252426"),
		"accent": Color("#a45632"),
		"description": "A blacksmith built like a door. Slow swings, crushing weight, stubborn health.",
	},
	{
		"id": "ayiz",
		"name": "Ayiz",
		"title": "Reedshot",
		"hp": 92,
		"mana": 65,
		"attack": 1,
		"defense": -1,
		"speed": 4.6,
		"weapon": "Bow",
		"weapon_style": "bow",
		"starter_weapon": "reed_bow",
		"attack_cooldown": 0.55,
		"attack_range": 8.0,
		"attack_mult": 0.95,
		"tint": Color("#c99570"),
		"hair": Color("#3a2b22"),
		"accent": Color("#587b42"),
		"description": "A reed-runner with a hunting bow. Keep distance and make every arrow count.",
	},
]


static func get_character(character_id: String) -> Dictionary:
	for c in CHARACTERS:
		if str(c.id) == character_id:
			return c.duplicate(true)
	return CHARACTERS[0].duplicate(true)


static func ids() -> Array[String]:
	var out: Array[String] = []
	for c in CHARACTERS:
		out.append(str(c.id))
	return out


static func weapon_style(character_id: String) -> String:
	return str(get_character(character_id).get("weapon_style", "sword"))
