class_name ArrivalDB
extends RefCounted
## Fixed nightly allowance, delivered in readable pulses. No extra spawn rolls.
const WARNING := 8.0
const MEMBER_GAP := 2.0
const LATE_GRACE := 2.5
const FIRE_TIMES := [8.0, 32.0, 34.0, 36.0, 56.0, 58.0, 60.0, 62.0, 80.0, 82.0, 84.0, 86.0, 104.0, 106.0, 108.0, 110.0, 128.0, 130.0, 132.0, 134.0, 152.0, 154.0, 156.0, 158.0]
const SHORE_TIMES := [10.0, 40.0, 64.0, 88.0, 112.0, 136.0]

static func times(fires: int, shores: int, reinforcement: bool = false) -> Dictionary:
	var fire: Array = []
	var shore: Array = []
	if reinforcement:
		# The raid's actual quota arrives first, one physical attacker at a time.
		for i in shores: shore.append(WARNING + i * MEMBER_GAP)
		for i in fires: fire.append(WARNING + (i + shores) * MEMBER_GAP)
	else:
		for i in fires: fire.append(FIRE_TIMES[mini(i, FIRE_TIMES.size() - 1)])
		for i in shores: shore.append(SHORE_TIMES[mini(i, SHORE_TIMES.size() - 1)])
	return {"fire": fire, "shore": shore}
