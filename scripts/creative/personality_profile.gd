@tool
class_name PersonalityProfile
extends Resource
## Character/occupation configuration used by one shared presentation state machine.
@export var heroes: Dictionary = {
	"qayyim": {"stride": 1.0, "breath": 0.008, "rest": 0.015},
	"farhan": {"stride": 0.86, "breath": 0.006, "rest": -0.018},
	"ayiz": {"stride": 1.15, "breath": 0.009, "rest": 0.025}
}
@export var occupations: Dictionary = {
	"fisher": {"action": "work", "tool": "fishing_rod", "line": "The tide is gentle today. The turtles know the best fishing spots."},
	"gardener": {"action": "work", "tool": "watering_can", "line": "A little water, a little sunshine. These flowers welcome everyone home."},
	"carpenter": {"action": "work", "tool": "hammer", "line": "Warm timber and a sound roof. That is a good beginning."},
	"guard": {"action": "alert", "tool": "shield", "line": "The forest shelters us. We will shelter it."},
	"defender": {"action": "alert", "tool": "shield", "line": "I am keeping an eye on the treeline."},
	"trader": {"action": "shop", "tool": "gold", "line": "Fresh goods from the harbour! Have a look around the market."}
}
static var _default: PersonalityProfile
static func current() -> PersonalityProfile:
	if _default == null: _default = load("res://data/personality.tres") as PersonalityProfile
	return _default
