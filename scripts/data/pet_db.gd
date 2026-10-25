class_name PetDB
extends RefCounted
## Companions now provide combat support instead of portal lighting:
## gradual healing, automatic attacks and periodic shields.

const PETS := {
	"ember": {
		"name": "Ember",
		"species": "Ember Fox",
		"cost": 0,
		"starter": true,
		"hp": 55,
		"description": "A warm fox that frets over the player's wounds.",
		"focus": "Healing",
		"heal": 3,
		"heal_interval": 2.4,
		"attack": 5,
		"attack_interval": 3.0,
		"shield": 6,
		"shield_interval": 12.0,
		"body": Color("#d8783f"),
		"accent": Color("#ffd27a"),
		"tiers": {"aura": 3, "glow": 5},
	},
	"moss": {
		"name": "Moss",
		"species": "Marsh Cat",
		"cost": 140,
		"hp": 70,
		"description": "A patient hunter that punishes anything near the player.",
		"focus": "Attacking",
		"heal": 2,
		"heal_interval": 3.0,
		"attack": 9,
		"attack_interval": 2.2,
		"shield": 4,
		"shield_interval": 15.0,
		"body": Color("#748d58"),
		"accent": Color("#d6e79c"),
		"tiers": {"aura": 3, "glow": 5},
	},
	"luma": {
		"name": "Luma",
		"species": "Tide Moth",
		"cost": 0,
		"hp": 62,
		"description": "A rare tide-moth whose wings shimmer into a protective ward.",
		"focus": "Shielding",
		"heal": 2,
		"heal_interval": 2.6,
		"attack": 7,
		"attack_interval": 2.7,
		"shield": 10,
		"shield_interval": 10.0,
		"body": Color("#9fdcff"),
		"accent": Color("#fff3ad"),
		"tiers": {"aura": 3, "glow": 5},
	},
	"sparring_ember": {
		"name": "Sparring Ember", "species": "Village Guardian", "base_pet": "ember",
		"cost": 0, "hp": 65, "focus": "Village Defense",
		"description": "A tournament rival won in battle. Protects residents from fire monsters and sea urchins.",
		"heal": 2, "heal_interval": 2.8, "attack": 8, "attack_interval": 2.4,
		"shield": 6, "shield_interval": 12.0,
		"body": Color("#f3b16d"), "accent": Color("#fff3ad"),
	},
	"bramble_cat": {
		"name": "Bramble Cat", "species": "Village Guardian", "base_pet": "moss",
		"cost": 0, "hp": 65, "focus": "Village Defense",
		"description": "A tournament rival won in battle. Protects residents from fire monsters and sea urchins.",
		"heal": 2, "heal_interval": 2.8, "attack": 8, "attack_interval": 2.4,
		"shield": 6, "shield_interval": 12.0,
		"body": Color("#a8c275"), "accent": Color("#fff3ad"),
	},
	"dusk_moth": {
		"name": "Dusk Moth", "species": "Village Guardian", "base_pet": "luma",
		"cost": 0, "hp": 65, "focus": "Village Defense",
		"description": "A tournament rival won in battle. Protects residents from fire monsters and sea urchins.",
		"heal": 2, "heal_interval": 2.8, "attack": 8, "attack_interval": 2.4,
		"shield": 6, "shield_interval": 12.0,
		"body": Color("#c3b4ff"), "accent": Color("#fff3ad"),
	},
	"storm_fox": {
		"name": "Storm Fox", "species": "Village Guardian", "base_pet": "ember",
		"cost": 0, "hp": 65, "focus": "Village Defense",
		"description": "A tournament rival won in battle. Protects residents from fire monsters and sea urchins.",
		"heal": 2, "heal_interval": 2.8, "attack": 8, "attack_interval": 2.4,
		"shield": 6, "shield_interval": 12.0,
		"body": Color("#9fd7ff"), "accent": Color("#fff3ad"),
	},
	"tidecat_sovereign": {
		"name": "Tidecat Sovereign", "species": "Village Guardian", "base_pet": "moss",
		"cost": 0, "hp": 65, "focus": "Village Defense",
		"description": "A tournament rival won in battle. Protects residents from fire monsters and sea urchins.",
		"heal": 2, "heal_interval": 2.8, "attack": 8, "attack_interval": 2.4,
		"shield": 6, "shield_interval": 12.0,
		"body": Color("#74e0d7"), "accent": Color("#fff3ad"),
	},
}

const MAX_LEVEL := 5
const LEVEL_XP := [0, 50, 130, 250, 420]


static func get_pet(pet_id: String) -> Dictionary:
	return (PETS.get(pet_id, {}) as Dictionary).duplicate(true)


static func name_of(pet_id: String) -> String:
	return str(PETS.get(pet_id, {}).get("name", pet_id.capitalize()))


static func max_health(pet_id: String, level: int) -> int:
	var base := int(PETS.get(pet_id, {}).get("hp", 50))
	return base + (level - 1) * 12


static func heal_amount(pet_id: String, level: int) -> int:
	var base := int(PETS.get(pet_id, {}).get("heal", 2))
	return base + (level - 1)


static func heal_interval(pet_id: String, level: int) -> float:
	var base := float(PETS.get(pet_id, {}).get("heal_interval", 2.5))
	return maxf(1.0, base - float(level - 1) * 0.12)


static func attack_damage(pet_id: String, level: int) -> int:
	var base := int(PETS.get(pet_id, {}).get("attack", 5))
	return base + (level - 1) * 3


static func attack_interval(pet_id: String, level: int) -> float:
	var base := float(PETS.get(pet_id, {}).get("attack_interval", 3.0))
	return maxf(1.0, base - float(level - 1) * 0.1)


static func shield_amount(pet_id: String, level: int) -> int:
	var base := int(PETS.get(pet_id, {}).get("shield", 5))
	return base + (level - 1) * 2


static func shield_interval(pet_id: String, level: int) -> float:
	var base := float(PETS.get(pet_id, {}).get("shield_interval", 12.0))
	return maxf(6.0, base - float(level - 1) * 0.8)


static func xp_for_level(level: int) -> int:
	if level <= 0:
		return 0
	return int(LEVEL_XP[clampi(level - 1, 0, LEVEL_XP.size() - 1)])


static func shop_stock() -> Array[String]:
	return ["moss"]
