class_name ElementDB
extends RefCounted
## Ten demon realms; stable portal IDs remain in PortalDB.
const ELEMENTS := {
	"chaos": {
		"name": "Shadow & Chaos Fiend",
		"title_ms": "Demon Pembunuh Bayangan",
		"body": "#d1507a",
		"glow": "#ff9478",
		"floor": "#392532",
		"arena": "Chaos Citadel",
		"minion_name": "Darkfire Imp",
		"minion_attack": "dash",
		"skills": [
			{
				"id": "darkfire",
				"name": "Dark Blaze",
				"pattern": "fan"
			},
			{
				"id": "illusion",
				"name": "Mirage Assault",
				"pattern": "dash"
			},
			{
				"id": "chaos_cross",
				"name": "Chaos Crossfire",
				"pattern": "cross"
			}
		]
	},
	"wind": {
		"name": "Gale Tempest Demon",
		"title_ms": "Tuan Angin Pusaran",
		"body": "#8cbcca",
		"glow": "#e0f5df",
		"floor": "#34454e",
		"arena": "Tempest Spire",
		"minion_name": "Gale Harpy",
		"minion_attack": "ranged",
		"skills": [
			{
				"id": "tornado",
				"name": "Razor Tornado",
				"pattern": "whirl"
			},
			{
				"id": "wind_blades",
				"name": "Gale Blades",
				"pattern": "fan"
			},
			{
				"id": "updraft",
				"name": "Cyclone Uplift",
				"pattern": "wave"
			}
		]
	},
	"ice": {
		"name": "Glacial Frost Demon",
		"title_ms": "Jeneral Ais Beku",
		"body": "#75c9e8",
		"glow": "#d9faff",
		"floor": "#456277",
		"arena": "Glacial Necropolis",
		"minion_name": "Frost Revenant",
		"minion_attack": "ranged",
		"skills": [
			{
				"id": "ice_shards",
				"name": "Crystal Barrage",
				"pattern": "fan"
			},
			{
				"id": "frost_nova",
				"name": "Eternal Frost",
				"pattern": "nova"
			},
			{
				"id": "ice_prison",
				"name": "Glacial Prison",
				"pattern": "snare"
			}
		]
	},
	"earth": {
		"name": "Tectonic Earth Titan",
		"title_ms": "Raksasa Tanah Bebatuan",
		"body": "#b08863",
		"glow": "#ffbb69",
		"floor": "#554b42",
		"arena": "Tectonic Crucible",
		"minion_name": "Magma Golem",
		"minion_attack": "slam",
		"skills": [
			{
				"id": "faultline",
				"name": "Rupture Fault",
				"pattern": "line"
			},
			{
				"id": "magma",
				"name": "Magma Bombardment",
				"pattern": "volley"
			},
			{
				"id": "quake",
				"name": "Titan Earthquake",
				"pattern": "nova"
			}
		]
	},
	"fire": {
		"name": "Infernal Blaze Lord",
		"title_ms": "Pahlawan Api Neraka",
		"body": "#ed713e",
		"glow": "#ffe29a",
		"floor": "#593c39",
		"arena": "Infernal Forge",
		"minion_name": "Cinder Swordsman",
		"minion_attack": "dash",
		"skills": [
			{
				"id": "magma_blade",
				"name": "Magma Sword Cleave",
				"pattern": "cleave"
			},
			{
				"id": "blaze_rush",
				"name": "Infernal Rush",
				"pattern": "dash"
			},
			{
				"id": "fire_ring",
				"name": "Hellfire Crown",
				"pattern": "ring"
			}
		]
	},
	"lightning": {
		"name": "Voltage Lightning Demon",
		"title_ms": "Pangeran Kilat Petir",
		"body": "#6fafff",
		"glow": "#e4faff",
		"floor": "#354a68",
		"arena": "Voltage Sanctum",
		"minion_name": "Volt Wraith",
		"minion_attack": "dash",
		"skills": [
			{
				"id": "volt_dash",
				"name": "Lightning Step",
				"pattern": "dash"
			},
			{
				"id": "thunder",
				"name": "Thunder Judgment",
				"pattern": "strikes"
			},
			{
				"id": "chain_bolt",
				"name": "Voltaic Arcs",
				"pattern": "fan"
			}
		]
	},
	"forest": {
		"name": "Thorn Forest Queen",
		"title_ms": "Ratu Hutan Berduri",
		"body": "#75a75e",
		"glow": "#c0e884",
		"floor": "#344c3b",
		"arena": "Thornwood Court",
		"minion_name": "Thorn Stalker",
		"minion_attack": "snare",
		"skills": [
			{
				"id": "roots",
				"name": "Root Prison",
				"pattern": "snare"
			},
			{
				"id": "poison_bloom",
				"name": "Venom Blossom",
				"pattern": "pool"
			},
			{
				"id": "vine_lash",
				"name": "Thorn Lash",
				"pattern": "line"
			}
		]
	},
	"water": {
		"name": "Abyssal Tsunami Demon",
		"title_ms": "Panglima Lautan Bergelora",
		"body": "#4fbdcd",
		"glow": "#c2f4ed",
		"floor": "#345663",
		"arena": "Tsunami Palace",
		"minion_name": "Trident Marauder",
		"minion_attack": "wave",
		"skills": [
			{
				"id": "tsunami",
				"name": "Tsunami Wall",
				"pattern": "wave"
			},
			{
				"id": "hydro_spear",
				"name": "Hydro Trident",
				"pattern": "volley"
			},
			{
				"id": "whirlpool",
				"name": "Pressure Whirlpool",
				"pattern": "whirl"
			}
		]
	},
	"decay": {
		"name": "Necromancer of Decay",
		"title_ms": "Penyihir Puaka Hijau",
		"body": "#96bb4e",
		"glow": "#e0f5a7",
		"floor": "#3e4835",
		"arena": "Sepulchre of Decay",
		"minion_name": "Plague Acolyte",
		"minion_attack": "pool",
		"skills": [
			{
				"id": "acid",
				"name": "Corrosive Plague",
				"pattern": "pool"
			},
			{
				"id": "soul_curse",
				"name": "Soul Corruption",
				"pattern": "homing"
			},
			{
				"id": "raise_dead",
				"name": "Raise the Fallen",
				"pattern": "summon"
			}
		]
	},
	"dark": {
		"name": "Abyss Monarch",
		"title_ms": "Raja Iblis Utama",
		"body": "#3b304a",
		"glow": "#e5baff",
		"floor": "#352940",
		"arena": "Abyssal Throne",
		"minion_name": "Soulbound Knight",
		"minion_attack": "homing",
		"skills": [
			{
				"id": "gravity",
				"name": "Black-Hole Dominion",
				"pattern": "whirl"
			},
			{
				"id": "soul_rule",
				"name": "Sovereign Souls",
				"pattern": "homing"
			},
			{
				"id": "darkness",
				"name": "Pure-Darkness Apocalypse",
				"pattern": "strikes"
			}
		]
	}
}

static func get_element(element: String) -> Dictionary:
	return (ELEMENTS.get(element, {}) as Dictionary).duplicate(true)

static func element_for_kind(kind: String) -> String:
	for prefix in ["demon_", "minion_"]:
		if kind.begins_with(prefix) and ELEMENTS.has(kind.trim_prefix(prefix)):
			return kind.trim_prefix(prefix)
	return ""

static func palette(element: String) -> Dictionary:
	var def := get_element(element)
	var glow := Color(str(def.get("glow", "#c99fee")))
	var floor_color := Color(str(def.get("floor", "#404354")))
	return {"stone":floor_color,"stone_light":floor_color.lightened(0.25),"glow":glow,"glow_light":glow.lightened(0.3),"mote":glow}
