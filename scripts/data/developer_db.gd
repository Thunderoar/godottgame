class_name DeveloperDB
extends RefCounted
## A closed action catalog: no arbitrary commands or save-field editing.
const GROUPS := ["Travel", "Scenes", "Progress"]
const ACTIONS := [
	["travel_village","Travel","BESUT village","Return to the cottage and village services."],
	["travel_dock","Travel","BESUT dock","Stand on the jetty near the ship."],
	["travel_twilight","Travel","Twilight Wilds","Explore a fresh first-realm rescue attempt."],
	["travel_citadel","Travel","Chaos Citadel boss","Start at the chamber threshold to test Mei Ling's rescue."],
	["travel_tempest","Travel","Tempest Spire","Test the optional wind boss without level gates."],
	["travel_abyss","Travel","Abyssal Throne","Test the optional final portal boss."],
	["travel_sea_1","Travel","Sea level 1","Restart the first turtle route with Arjun still missing."],
	["travel_sea_2","Travel","Sea level 2","Skip to the shark route before Kraken Island."],
	["travel_kraken","Travel","Kraken Island fight","Test all ten crabs and the Kraken encounter."],
	["travel_prison","Travel","Arjun's unlocked prison","Defeat the Kraken, then interact with Arjun's cage yourself."],
	["scene_intro","Scenes","Opening story","Replay the illustrated fishing trip, wreck and welcome."],
	["scene_arjun","Scenes","Arjun rescue preview","Preview his illustrated rescue and return."],
	["scene_mei","Scenes","Mei Ling rescue preview","Preview all seven citadel rescue beats."],
	["scene_welcome","Scenes","Pak Rahim dock welcome","Replay the opening dock conversation."],
	["scene_ending","Scenes","Full dock ending","Prepare both friends, then play the reunion and voyage."],
	["progress_dock","Progress","Prepare dock ending","Rescue both friends and wait at the dock for manual Embark."],
	["progress_arjun","Progress","Mark Arjun rescued","Add Arjun to the test village without replaying the sea."],
	["progress_mei","Progress","Mark Mei Ling rescued","Add Mei Ling to the test village without a boss fight."],
	["progress_reset","Progress","Reset both rescue routes","Reopen the sea and citadel rescue in the test journey."],
	["progress_boss","Progress","Finish current boss","Use the current boss's real defeat and rescue flow."],
	["progress_heal","Progress","Restore Adam and companion","Restore health, revive the companion and end recovery."],
	["progress_supplies","Progress","Add test supplies","Add 5,000 Gold, 100 Diamonds and 50 health potions."],
	["progress_day","Progress","Set daytime","Advance the village clock to the next day."],
	["progress_night","Progress","Set nighttime","Advance the clock to the next night and test arrivals."],
]

static func action(id: String) -> Array:
	for row in ACTIONS:
		if str(row[0]) == id: return row.duplicate()
	return []

static func actions(group: String) -> Array:
	var result: Array = []
	for row in ACTIONS:
		if str(row[1]) == group: result.append(row.duplicate())
	return result
