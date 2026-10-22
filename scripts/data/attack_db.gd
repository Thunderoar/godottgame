class_name AttackDB
extends RefCounted
## Data-driven weapon attacks: anticipation -> active -> recovery per step.
## Damage is applied on the ACTIVE frame (see Player._begin_active_phase), and
## `attack_cooldown` (CharacterDB) restarts at each hit frame, so the time
## between successive hits never drops below the pre-overhaul pacing — DPS is
## preserved while every swing gains wind-up and follow-through.


const ENABLE_SWORD_COMBO := true
const COMBO_WINDOW := 0.34

const CHAINS := {
	"sword": {
		"hitstop": 0.045,
		"shake": 0.07,
		"shake_time": 0.1,
		"steps": [
			{"anticipation": 0.06, "active": 0.08, "recovery": 0.14, "lunge": 0.55, "arc": "lr"},
			{"anticipation": 0.05, "active": 0.08, "recovery": 0.14, "lunge": 0.55, "arc": "rl"},
			{"anticipation": 0.09, "active": 0.10, "recovery": 0.24, "lunge": 0.95, "arc": "thrust"},
		],
	},
	"hammer": {
		"hitstop": 0.085,
		"shake": 0.2,
		"shake_time": 0.2,
		"steps": [
			{"anticipation": 0.20, "active": 0.10, "recovery": 0.30, "lunge": 0.18, "arc": "slam", "shockwave": true},
		],
	},
	"bow": {
		"hitstop": 0.0,
		"shake": 0.03,
		"shake_time": 0.08,
		"steps": [
			{"anticipation": 0.12, "active": 0.04, "recovery": 0.12, "lunge": 0.0, "arc": "shot"},
		],
	},
}


static func chain(style: String) -> Dictionary:
	var data: Dictionary = CHAINS.get(style, CHAINS["sword"]) as Dictionary
	if style == "sword" and not ENABLE_SWORD_COMBO:
		return {"hitstop": data.get("hitstop", 0.045), "shake": data.get("shake", 0.07), "shake_time": data.get("shake_time", 0.1), "steps": [data["steps"][0]]}
	return data


static func step(style: String, index: int) -> Dictionary:
	var data := chain(style)
	var steps: Array = data["steps"]
	return steps[index % steps.size()] as Dictionary


static func step_count(style: String) -> int:
	return (chain(style)["steps"] as Array).size()
