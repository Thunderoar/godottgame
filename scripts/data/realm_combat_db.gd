class_name RealmCombatDB
extends RefCounted
## Runtime combat definitions. No enemy HP, cast token or encounter state is saved.

const PROFILES := {
	"imp": {"name":"Darkfire Imp", "windup":0.65, "active":0.38, "recovery":0.60, "cooldown":3.6},
	"watcher": {"name":"Ember Watcher", "windup":0.90, "active":1.20, "recovery":0.65, "cooldown":3.6},
	"keeper": {"name":"Rune Keeper", "windup":1.05, "active":0.30, "recovery":0.80, "cooldown":4.5},
}
const PAIRS := [
	{"id":"rootbound_patrol", "hint":"Rootbound patrol · read the rush, step aside, then counter.", "core":Rect2(29.2,36,8.6,3.6), "pursuit":Rect2(27.5,35.3,12,4.7),
		"homes":[Vector2(31,37),Vector2(34.6,36.8)], "profiles":["imp","imp"]},
	{"id":"watchpost_guard", "hint":"Ember Watcher · find a fan gap, use stone cover, or approach from the side.", "core":Rect2(31,29.8,8,5.5), "pursuit":Rect2(29,29.3,11,7),
		"homes":[Vector2(34.8,33),Vector2(38.3,30.2)], "profiles":["imp","watcher"]},
	{"id":"ashen_sentries", "hint":"Rune Keeper · leave the marked cross. The lantern remains a refuge.", "core":Rect2(22.6,25.5,9,4.8), "pursuit":Rect2(22.4,25.4,11,7),
		"homes":[Vector2(24.1,27.4),Vector2(28.4,28.1)], "profiles":["imp","keeper"]},
]
const COVER := Vector2(38.4,35)
const COVER_SIZE := Vector2(0.8,1.2)
const SHOT_SPEED := 5.0
const SHOT_RADIUS := 0.18
const CROSS_RADIUS := 0.35
const CROSS_HALF := 1.8
const ATTACK_GAP := 0.35

static func pair(id: String) -> Dictionary:
	for definition in PAIRS:
		if str(definition.id) == id: return definition
	return {}

static func safe_rects() -> Array[Rect2]:
	var result: Array[Rect2] = [RealmDB.BOSS_ARENA, Rect2(40,1,15,23)]
	for def in RealmDB.ENCOUNTERS.values(): result.append(Rect2(def.at+Vector2(-4,-3),Vector2(8,7)).grow(0.75))
	return result

static func safe_circles() -> Array[Dictionary]:
	var result: Array[Dictionary] = [{"at":RealmDB.CAMP,"radius":3.5},{"at":RealmDB.ARRIVAL,"radius":4.5}]
	for def in RealmDB.ENCOUNTERS.values(): result.append({"at":def.at,"radius":4.0})
	for def in RealmContentDB.INTERESTS.values(): result.append({"at":def.at,"radius":2.6})
	return result

static func protected(at: Vector2, padding: float = 0.0) -> bool:
	for rect in safe_rects():
		if rect.grow(padding).has_point(at): return true
	for circle in safe_circles():
		if at.distance_to(circle.at) <= float(circle.radius)+padding: return true
	return false

static func _rect_entry(from: Vector2, to: Vector2, rect: Rect2) -> float:
	if rect.has_point(from): return 0.0
	var best := 1.0
	var corners := [rect.position,rect.position+Vector2(rect.size.x,0),rect.end,rect.position+Vector2(0,rect.size.y)]
	for i in 4:
		var hit: Variant = Geometry2D.segment_intersects_segment(from,to,corners[i],corners[(i+1)%4])
		if hit != null: best = minf(best,from.distance_to(hit)/maxf(0.00001,from.distance_to(to)))
	return best

static func allowed_fraction(from: Vector2, to: Vector2, region: Rect2, padding: float = 0.0) -> float:
	var inside := region.grow(-padding)
	if not inside.has_point(from) or protected(from,padding): return 0.0
	var best := 1.0
	if not inside.has_point(to):
		# Entry from the outside in the reverse direction is this segment's exit.
		best = 1.0-_rect_entry(to,from,inside)
	for rect in safe_rects(): best = minf(best,_rect_entry(from,to,rect.grow(padding)))
	var motion := to-from
	var a := motion.length_squared()
	if a > 0.000001:
		for circle in safe_circles():
			var offset: Vector2 = from-circle.at
			var radius := float(circle.radius)+padding
			var b := 2.0*offset.dot(motion)
			var discriminant := b*b-4.0*a*(offset.length_squared()-radius*radius)
			if discriminant < 0: continue
			var entry := (-b-sqrt(discriminant))/(2.0*a)
			if entry >= 0 and entry <= 1: best = minf(best,entry)
	return clampf(best,0,1)

static func scenery_reserved(at: Vector2) -> bool:
	for def in PAIRS:
		if (def.pursuit as Rect2).grow(0.9).has_point(at): return true
	return false
