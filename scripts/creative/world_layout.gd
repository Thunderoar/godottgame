@tool
class_name WorldLayout
extends Resource
## Curated village geography, shared by terrain, gameplay and Map Studio.
## This resource is developer data. Runtime resolution never edits the source.
@export var version := 1
@export var terrain_bake_path := ""
var terrain_bake: Texture2D
@export var terrain_bake_hash := 0
@export var terrain_palette_hash := 0
@export var anchors: Array[Dictionary] = []
@export var routes: Array[Dictionary] = []
@export var zones: Array[Dictionary] = []
@export var scenery: Array[Dictionary] = []
const ACTOR_CLEARANCE := 0.38
var _route_buckets: Dictionary = {}
var _reserved_rects: Array[Rect2] = []
var _segments_a := PackedVector2Array()
var _segments_b := PackedVector2Array()
var _segments_width := PackedFloat32Array()
var _prepared := false
const BUCKET_SIZE := 4.0

static func village() -> WorldLayout:
	return load("res://data/maps/village_layout.tres") as WorldLayout

func anchor(id: String) -> Dictionary:
	for entry in anchors:
		if str(entry.get("id", "")) == id: return entry
	return {}

func position_of(id: String, fallback := Vector2.ZERO) -> Vector2:
	return anchor(id).get("position", fallback)

func approach(id: String) -> Vector2:
	var entry := anchor(id)
	return entry.get("position", Vector2.ZERO) + entry.get("approach", Vector2.ZERO)

func resolved(objects: Array[Dictionary], saved: Dictionary) -> WorldLayout:
	var result := copy_layout()
	for entry in result.anchors:
		var id := str(entry.get("id", ""))
		for object in objects:
			if str(object.get("base_id", "")) == id:
				entry.position = object.get("position", entry.position)
		var stored: Variant = saved.get(id)
		if bool(entry.get("movable", false)) and stored is Array and stored.size() >= 2:
			entry.position = Vector2(float(stored[0]), float(stored[1]))
	# Home-bound arrivals/recovery follow the whole cottage; never save defaults.
	var home_delta := result.position_of("house") - position_of("house")
	for id in ["arrival", "recovery"]:
		var entry := result.anchor(id)
		entry.position = position_of(id) + home_delta
	return result

func route_points(route: Dictionary) -> PackedVector2Array:
	var points := PackedVector2Array()
	points.append(approach(str(route.get("from", ""))))
	points.append_array(route.get("via", PackedVector2Array()))
	points.append(approach(str(route.get("to", ""))))
	return points

func route_distance(at: Vector2) -> float:
	if not _prepared: _prepare()
	var distance := INF
	for index in _route_buckets.get(Vector2i((at / BUCKET_SIZE).floor()), []):
		distance = minf(distance, at.distance_to(Geometry2D.get_closest_point_to_segment(at, _segments_a[index], _segments_b[index])) - _segments_width[index])
	return distance

func _prepare() -> void:
	_route_buckets.clear()
	_reserved_rects.clear()
	_segments_a.clear()
	_segments_b.clear()
	_segments_width.clear()
	for route in routes:
		var points := route_points(route)
		var width := float(route.get("width", 1.6)) * 0.5
		for i in points.size() - 1:
			var index := _segments_a.size()
			_segments_a.append(points[i])
			_segments_b.append(points[i + 1])
			_segments_width.append(width)
			var bounds := Rect2(points[i], Vector2.ZERO).expand(points[i + 1]).grow(width + 2.0)
			for y in range(int(floor(bounds.position.y / BUCKET_SIZE)), int(ceil(bounds.end.y / BUCKET_SIZE)) + 1):
				for x in range(int(floor(bounds.position.x / BUCKET_SIZE)), int(ceil(bounds.end.x / BUCKET_SIZE)) + 1):
					var cell := Vector2i(x, y)
					if not _route_buckets.has(cell): _route_buckets[cell] = []
					_route_buckets[cell].append(index)
	for entry in anchors:
		var p: Vector2 = entry.get("position", Vector2.ZERO)
		var footprint: Rect2 = entry.get("footprint", Rect2(-0.5, -0.5, 1, 1))
		_reserved_rects.append(Rect2(p + footprint.position, footprint.size))
		var size: Vector2 = entry.get("clearance", Vector2(1.5, 1.5))
		_reserved_rects.append(Rect2(approach(str(entry.id)) - size * 0.5, size))
	_prepared = true

func zone_record(at: Vector2) -> Dictionary:
	# Later regions take priority in overlap; polygons can be concave.
	for i in range(zones.size() - 1, -1, -1):
		if Geometry2D.is_point_in_polygon(at, zones[i].get("polygon", PackedVector2Array())):
			return zones[i]
	return {}

func zone_at(at: Vector2) -> String:
	return str(zone_record(at).get("id", "transition"))

func reserved(at: Vector2, radius: float = 0.4) -> bool:
	if route_distance(at) < radius: return true
	for rect in _reserved_rects:
		if rect.grow(radius).has_point(at): return true
	return false

func signature() -> int:
	# Explicit ordered geometry avoids Dictionary order and Color serialization
	# precision changing a bake hash after a normal ResourceSaver round trip.
	var geometry: Array = [version]
	for entry in anchors:
		var at: Vector2 = entry.get("position", Vector2.ZERO)
		var front: Vector2 = entry.get("approach", Vector2.ZERO)
		geometry.append([str(entry.get("id", "")), str(entry.get("kind", "")), _point_key(at), _point_key(front)])
	for route in routes:
		var points: Array = []
		for point in route.get("via", PackedVector2Array()): points.append(_point_key(point))
		geometry.append([str(route.get("id", "")), str(route.get("from", "")), str(route.get("to", "")), roundi(float(route.get("width", 1.6)) * 10000), str(route.get("material", "path")), points])
	for zone in zones:
		var points: Array = []
		for point in zone.get("polygon", PackedVector2Array()): points.append(_point_key(point))
		geometry.append([str(zone.get("id", "")), str(zone.get("material", "grass")), points])
	return hash(geometry)

static func _point_key(at: Vector2) -> Array:
	return [roundi(at.x * 10000), roundi(at.y * 10000)]

func warnings() -> PackedStringArray:
	var result := PackedStringArray()
	var ids := {}
	for collection in [anchors, routes, zones]:
		ids = {}
		for entry in collection:
			var id := str(entry.get("id", ""))
			if id.is_empty() or ids.has(id): result.append("Missing or duplicate spatial ID: " + id)
			ids[id] = true
	var reached := {"arrival": true}
	for iteration in anchors.size():
		var previous_count := reached.size()
		for route in routes:
			var first := str(route.get("from", ""))
			var last := str(route.get("to", ""))
			if anchor(first).is_empty() or anchor(last).is_empty():
				if iteration == 0: result.append(str(route.get("id", "route")) + ": unknown endpoint")
			if reached.has(first): reached[last] = true
			if reached.has(last): reached[first] = true
		if reached.size() == previous_count: break
	for entry in anchors:
		var id := str(entry.get("id", ""))
		if not Rect2(0, 0, 64, 40).has_point(position_of(id)) or not Rect2(0, 0, 64, 40).has_point(approach(id)):
			result.append(id + ": outside village")
		if entry.get("destination", false) and not reached.has(id): result.append(id + ": disconnected from arrival")
	for route in routes:
		if float(route.get("width", 0.0)) < ACTOR_CLEARANCE * 2.0:
			result.append(str(route.get("id", "route")) + ": narrower than actor clearance")
	return result


func copy_layout() -> WorldLayout:
	var result := WorldLayout.new()
	result.version = version
	result.terrain_bake_path = terrain_bake_path
	result.terrain_bake = terrain_bake
	result.terrain_bake_hash = terrain_bake_hash
	result.terrain_palette_hash = terrain_palette_hash
	result.anchors.assign(anchors.duplicate(true))
	result.routes.assign(routes.duplicate(true))
	result.zones.assign(zones.duplicate(true))
	result.scenery.assign(scenery.duplicate(true))
	return result


func world_footprint(id: String) -> Rect2:
	var entry := anchor(id)
	var rect: Rect2 = entry.get("footprint", Rect2())
	return Rect2(position_of(id) + rect.position, rect.size)


func conflicts(area: Rect2) -> bool:
	# Conservative authoring clearance for full footprints, not just centres.
	for entry in anchors:
		var id := str(entry.get("id", ""))
		if not entry.get("destination", false): continue
		var size: Vector2 = entry.get("clearance", Vector2.ONE)
		if area.intersects(Rect2(approach(id) - size * 0.5, size)): return true
	for route in routes:
		var rect := area.grow(float(route.get("width", 1.6)) * 0.5)
		var points := route_points(route)
		var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
		for i in points.size() - 1:
			if rect.has_point(points[i]) or rect.has_point(points[i + 1]): return true
			for edge in 4:
				if Geometry2D.segment_intersects_segment(points[i], points[i + 1], corners[edge], corners[(edge + 1) % 4]) != null: return true
	return false


func allows(zone_id: String, category: String) -> bool:
	for zone in zones:
		if str(zone.get("id", "")) == zone_id:
			return category in zone.get("allowed", [])
	return false


func baked_texture() -> Texture2D:
	if terrain_bake != null: return terrain_bake
	if terrain_bake_path.is_empty() or not ResourceLoader.exists(terrain_bake_path): return null
	# Map Studio may open during first import. An optional bake must not ask the
	# loader for a not-yet-imported source PNG or turn a fresh import into errors.
	if Engine.is_editor_hint():
		var import_config := ConfigFile.new()
		if import_config.load(terrain_bake_path + ".import") != OK: return null
		var imported := str(import_config.get_value("remap", "path", ""))
		if imported.is_empty() or not FileAccess.file_exists(imported): return null
	terrain_bake = load(terrain_bake_path) as Texture2D
	return terrain_bake
