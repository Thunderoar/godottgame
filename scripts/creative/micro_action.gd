class_name MicroAction
extends RefCounted
## Bounded presentation state. Requests cannot interrupt higher-priority actions.
const ACTIONS := {
	"idle": {"duration": 2.0, "priority": 0, "tilt": 0.0, "lift": 0.0},
	"work": {"duration": 2.4, "priority": 1, "tilt": 0.08, "lift": 0.02},
	"rest": {"duration": 2.8, "priority": 1, "tilt": -0.04, "lift": 0.01},
	"greet": {"duration": 1.1, "priority": 2, "tilt": -0.06, "lift": 0.05},
	"shop": {"duration": 1.4, "priority": 2, "tilt": 0.05, "lift": 0.03},
	"celebrate": {"duration": 0.7, "priority": 3, "tilt": 0.03, "lift": 0.08},
	"alert": {"duration": 0.8, "priority": 5, "tilt": 0.0, "lift": 0.0},
	"hurt": {"duration": 0.3, "priority": 8, "tilt": -0.1, "lift": 0.0}
}
var definitions: Dictionary = ACTIONS
var state := "idle"
var elapsed := 0.0
var tilt := 0.0
var lift := 0.0
var transitions := 0

func request(next: String) -> bool:
	if not definitions.has(next) or state == next: return false
	if int(definitions[next].priority) < int(definitions[state].priority): return false
	state = next
	elapsed = 0.0
	transitions += 1
	return true

func clear() -> void:
	state = "idle"
	elapsed = 0.0
	tilt = 0.0
	lift = 0.0

func tick(delta: float, reduced: bool) -> void:
	elapsed += delta
	var action: Dictionary = definitions[state]
	if elapsed >= float(action.duration):
		clear()
		return
	var weight := sin(PI * elapsed / float(action.duration))
	tilt = float(action.tilt) * weight if not reduced else 0.0
	lift = float(action.lift) * weight if not reduced else 0.0
