class_name RealmDB
extends RefCounted
## Authored first realm. Legacy portal IDs remain the campaign/save authority.

const PORTAL := "tidebound_grotto"
const SIZE := Vector2(72, 72)
const ARRIVAL := Vector2(36, 64)
const CAMP := Vector2(36, 22)
const BOSS := Vector2(36, 10)
const LANDMARKS := {
	"arrival": {"name": "Arrival Glade", "at": Vector2(36, 63), "hint": "Follow the old stones. Your return rift stays open."},
	"crossing": {"name": "Rootbound Crossing", "at": Vector2(43, 49), "hint": "Pawprints turn west beneath the violet leaves."},
	"grove": {"name": "Bramble Grove", "at": Vector2(17, 43), "hint": "A watchful cat guards this quiet clearing. Approach to challenge."},
	"watchpost": {"name": "Broken Watchpost", "at": Vector2(46, 35), "hint": "An old winch opens the path back through the roots."},
	"pool": {"name": "Moonpool Hollow", "at": Vector2(57, 29), "hint": "Pale wings gather over the water. A gentle rival awaits."},
	"approach": {"name": "Ashen Approach", "at": Vector2(36, 26), "hint": "Rest at the lantern. The fiend waits beyond the citadel arch."},
	"citadel": {"name": "Chaos Citadel", "at": Vector2(36, 12), "hint": "Cross the inner threshold when you are ready."},
}
const ENCOUNTERS := {
	"bramble_cat": {"duel": "pet_duel_2", "name": "Bramble Cat", "at": Vector2(17, 43), "hp": 30, "damage": 4, "gold": 25, "xp": 50},
	"dusk_moth": {"duel": "pet_duel_3", "name": "Dusk Moth", "at": Vector2(57, 29), "hp": 42, "damage": 5, "gold": 35, "xp": 65},
}
const PATHS := [
	[Vector2(36, 66), Vector2(36, 60), Vector2(43, 54), Vector2(43, 46), Vector2(46, 39), Vector2(46, 35), Vector2(43, 30), Vector2(36, 26), Vector2(36, 9)],
	[Vector2(43, 46), Vector2(32, 46), Vector2(25, 42), Vector2(17, 43), Vector2(15, 49), Vector2(24, 55), Vector2(36, 60)],
	[Vector2(17, 43), Vector2(18, 35), Vector2(24, 30), Vector2(36, 26)],
	[Vector2(46, 35), Vector2(53, 36), Vector2(58, 33), Vector2(57, 29), Vector2(51, 25), Vector2(43, 30)],
	[Vector2(36, 15), Vector2(48, 15), Vector2(60, 15)],
]

static func checkpoint_position(id: String) -> Vector2:
	return CAMP if id == "camp" else ARRIVAL

static func path_distance(point: Vector2) -> float:
	var distance := INF
	for path in PATHS:
		for i in range(1, path.size()):
			distance = minf(distance, Geometry2D.get_closest_point_to_segment(point, path[i - 1], path[i]).distance_to(point))
	return distance

static func cell_id(at: Vector2) -> String:
	return "%d:%d" % [clampi(floori(at.x / 12.0), 0, 5), clampi(floori(at.y / 12.0), 0, 5)]
