class_name RealmDB
extends RefCounted
## Authored first realm. Legacy portal IDs remain the campaign/save authority.

const PORTAL := "tidebound_grotto"
const SIZE := Vector2(56, 52)
const GRID_SIZE := 6
const CELL_SIZE := SIZE / float(GRID_SIZE)
const ARRIVAL := Vector2(26, 46)
const RETURN_RIFT := Vector2(26, 48)
const CAMP := Vector2(26, 22)
const BOSS := Vector2(26, 10)
const BOSS_THRESHOLD := Vector2(26, 16)
const BOSS_TRIGGER := Rect2(18, 1, 16, 16)
const BOSS_ARENA := Rect2(16, 1, 20, 20)
const BOSS_FRAME := Rect2(15, 0, 22, 21)
const ROOTWAY := Vector2(17, 29)
const WINCH := Vector2(37, 32)
const MINIONS := [Vector2(31,36),Vector2(36,34),Vector2(35,30),Vector2(31,27),Vector2(23,26),Vector2(28,26)]
const LANDMARKS := {
	"arrival": {"name": "Arrival Glade", "at": Vector2(26, 45), "hint": "Follow the old stones. Your return rift stays open."},
	"crossing": {"name": "Rootbound Crossing", "at": Vector2(33, 40), "hint": "Pawprints turn west beneath the violet leaves."},
	"grove": {"name": "Bramble Grove", "at": Vector2(12, 35), "hint": "A watchful cat guards this quiet clearing. Approach to challenge."},
	"watchpost": {"name": "Broken Watchpost", "at": Vector2(35, 31), "hint": "An old winch opens the path back through the roots."},
	"pool": {"name": "Moonpool Hollow", "at": Vector2(44, 27), "hint": "Pale wings gather over the water. A gentle rival awaits."},
	"approach": {"name": "Ashen Approach", "at": Vector2(26, 25), "hint": "Rest at the lantern. The fiend waits beyond the citadel arch."},
	"citadel": {"name": "Chaos Citadel", "at": Vector2(26, 12), "hint": "Cross the inner threshold when you are ready."},
}
const ENCOUNTERS := {
	"bramble_cat": {"duel": "pet_duel_2", "name": "Bramble Cat", "at": Vector2(12, 35), "hp": 30, "damage": 4, "gold": 25, "xp": 50},
	"dusk_moth": {"duel": "pet_duel_3", "name": "Dusk Moth", "at": Vector2(44, 27), "hp": 42, "damage": 5, "gold": 35, "xp": 65},
}
const PATHS := [
	[Vector2(26, 48), Vector2(26, 43), Vector2(33, 40), Vector2(33, 36), Vector2(35, 33), Vector2(35, 31), Vector2(32, 27), Vector2(26, 25), Vector2(26, 9)],
	[Vector2(33, 36), Vector2(25, 36), Vector2(19, 34), Vector2(12, 35), Vector2(12, 40), Vector2(19, 43), Vector2(26, 43)],
	[Vector2(12, 35), Vector2(12, 32), Vector2(17, 28), Vector2(26, 25)],
	[Vector2(35, 31), Vector2(40, 32), Vector2(45, 30), Vector2(44, 27), Vector2(39, 24), Vector2(32, 27)],
	[Vector2(26, 15), Vector2(38, 15), Vector2(53, 15)],
	[Vector2(41, 8), Vector2(53, 8)],
	[Vector2(41, 22), Vector2(53, 22)],
	[Vector2(47, 8), Vector2(47, 22)],
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
	return "%d:%d" % [clampi(floori(at.x / CELL_SIZE.x), 0, GRID_SIZE-1), clampi(floori(at.y / CELL_SIZE.y), 0, GRID_SIZE-1)]
