class_name HouseDB
extends RefCounted
## Five-level cottage progression. Diamonds are the only accepted currency.

const LEVELS: Array[Dictionary] = [
	{
		"level": 1,
		"name": "The Wreck",
		"cost": 0,
		"recovery": 10.0,
		"benefit": "A dry corner, a crooked bed, and a place to respawn.",
		"description": "Salt has eaten the paint. The roof sighs in the wind.",
	},
	{
		"level": 2,
		"name": "Patched Roof",
		"cost": 8,
		"recovery": 8.0,
		"benefit": "Repaired walls and a clean porch. Rest is a little easier.",
		"description": "Fresh boards close the worst of the gaps.",
	},
	{
		"level": 3,
		"name": "Seaboard Cottage",
		"cost": 18,
		"recovery": 6.0,
		"benefit": "A wider hearth and a proper bed. Health returns faster.",
		"description": "Flower boxes and a bright window make it feel like home.",
	},
	{
		"level": 4,
		"name": "Warden's Rest",
		"cost": 32,
		"recovery": 4.0,
		"benefit": "A walled garden and a deep porch speed your recovery.",
		"description": "The cottage now watches the tide with quiet confidence.",
	},
	{
		"level": 5,
		"name": "The Lantern House",
		"cost": 54,
		"recovery": 2.0,
		"benefit": "The finest home on the coast. Full health in two seconds.",
		"description": "Warm light spills from every window. The sea feels farther away.",
	},
]


static func get_level(level: int) -> Dictionary:
	return LEVELS[clampi(level, 1, LEVELS.size()) - 1].duplicate(true)


static func max_level() -> int:
	return LEVELS.size()


static func next_level(level: int) -> Dictionary:
	if level >= LEVELS.size():
		return {}
	return LEVELS[level].duplicate(true)


static func upgrade_cost(level: int) -> int:
	var nxt := next_level(level)
	return int(nxt.get("cost", 0))


static func recovery_time(level: int) -> float:
	return float(get_level(level).get("recovery", 10.0))
