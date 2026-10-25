class_name CharacterDB
extends RefCounted
## Three Malaysian heroes sharing one storyline and three distinct weapons.

const CHARACTERS := [
	{
		"id": "adam",
		"name": "Adam",
		"gender": "male",
		"heritage": "Malay",
		"title": "Coastblade",
		"hp": 105,
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
		"description": "A Malay swordsman. Swift steel and precise sword strikes.",
	},
	{
		"id": "arjun",
		"name": "Arjun",
		"gender": "male",
		"heritage": "Indian",
		"title": "Dusk Reaper",
		"hp": 135,
		"attack": 0,
		"defense": 3,
		"speed": 3.9,
		"weapon": "Scythe",
		"weapon_style": "scythe",
		"starter_weapon": "smith_hammer",
		"attack_cooldown": 0.64,
		"attack_range": 2.55,
		"attack_mult": 1.35,
		"tint": Color("#b9845c"),
		"hair": Color("#252426"),
		"accent": Color("#a45632"),
		"description": "An Indian scythe wielder. Wide, powerful sweeps.",
	},
	{
		"id": "mei_ling",
		"name": "Mei Ling",
		"gender": "female",
		"heritage": "Chinese",
		"title": "Reedshot",
		"hp": 92,
		"attack": 1,
		"defense": -1,
		"speed": 4.6,
		"weapon": "Bow",
		"weapon_style": "bow",
		"starter_weapon": "reed_bow",
		"attack_cooldown": 0.55,
		"attack_range": 8.0,
		"attack_mult": 0.95,
		"tint": Color("#ebc5a3"),
		"hair": Color("#25212d"),
		"accent": Color("#587b42"),
		"description": "A Chinese archer. Precise arrows from a light coastal bow.",
	},
]


static func get_character(character_id: String) -> Dictionary:
	var canonical := canonical_id(character_id)
	for c in CHARACTERS:
		if str(c.id) == canonical:
			return c.duplicate(true)
	return CHARACTERS[0].duplicate(true)


static func ids() -> Array[String]:
	var out: Array[String] = []
	for c in CHARACTERS:
		out.append(str(c.id))
	return out


static func weapon_style(character_id: String) -> String:
	return str(get_character(character_id).get("weapon_style", "sword"))


static func canonical_id(character_id: String) -> String:
	# Old save IDs retain their weapon discipline and progression.
	return str({"qayyim": "adam", "farhan": "arjun", "ayiz": "mei_ling"}.get(character_id, character_id))
