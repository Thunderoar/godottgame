@tool
class_name AuthoredMap
extends Resource
## Sparse, versioned authoring layers; player settlement layout stays in GameState.
const LAYERS := ["Terrain", "Paths", "Water", "Shore", "Decoration", "Vegetation", "Buildings", "Gameplay", "Collision", "Foreground"]
const MATERIALS := ["grass", "grass_light", "grass_shadow", "path", "sand", "sea_shallow", "sea_deep", "stone", "flower"]
@export var version := 2
@export var layout: WorldLayout
@export var title := "Seaside Home"
@export var size := Vector2i(64, 40)
@export var seed_value := 4771
@export var layers: Dictionary = {}
@export var objects: Array[Dictionary] = []
@export var palette: WorldPalette
@export var editor_hidden: Dictionary = {}
@export var editor_locked: Dictionary = {}

func cell(layer: String, at: Vector2i) -> String:
	return str(layers.get(layer, {}).get(at, ""))

func paint(layer: String, at: Vector2i, material: String) -> void:
	if at.x < 0 or at.y < 0 or at.x >= size.x or at.y >= size.y:
		return
	if not layers.has(layer):
		layers[layer] = {}
	if material.is_empty():
		layers[layer].erase(at)
	else:
		layers[layer][at] = material
	emit_changed()

func snapshot() -> Dictionary:
	return {"layers": layers.duplicate(true), "objects": objects.duplicate(true), "seed": seed_value, "layout": {"anchors": layout.anchors.duplicate(true), "routes": layout.routes.duplicate(true), "zones": layout.zones.duplicate(true), "scenery": layout.scenery.duplicate(true), "version": layout.version, "terrain_bake_path": layout.terrain_bake_path, "terrain_bake": layout.terrain_bake, "terrain_bake_hash": layout.terrain_bake_hash, "terrain_palette_hash": layout.terrain_palette_hash} if layout else {}}

func restore(state: Dictionary) -> void:
	seed_value = int(state.get("seed", seed_value))
	var spatial: Dictionary = state.get("layout", {})
	layout = null
	if not spatial.is_empty():
		layout = WorldLayout.new()
		layout.anchors.assign(spatial.get("anchors", []).duplicate(true))
		layout.routes.assign(spatial.get("routes", []).duplicate(true))
		layout.zones.assign(spatial.get("zones", []).duplicate(true))
		layout.scenery.assign(spatial.get("scenery", []).duplicate(true))
		layout.version = int(spatial.get("version", 1))
		layout.terrain_bake_path = str(spatial.get("terrain_bake_path", ""))
		layout.terrain_bake = spatial.get("terrain_bake", null)
		layout.terrain_bake_hash = int(spatial.get("terrain_bake_hash", 0))
		layout.terrain_palette_hash = int(spatial.get("terrain_palette_hash", 0))
	layers = state.layers.duplicate(true)
	objects.assign(state.objects.duplicate(true))
	emit_changed()

func warnings() -> PackedStringArray:
	var spatial := resolved_layout()
	var result := spatial.warnings()
	var ids := {}
	var critical: Array[Vector2] = []
	for entry in spatial.anchors:
		if entry.get("destination", false): critical.append(spatial.approach(str(entry.id)))
	for object in objects:
		var id := str(object.get("id", ""))
		if id.is_empty() or ids.has(id):
			result.append("Missing or duplicate object ID: " + id)
		ids[id] = true
		var at: Vector2 = object.get("position", Vector2.ZERO)
		if not Rect2(Vector2.ZERO, Vector2(size)).has_point(at):
			result.append(id + ": outside map")
		if object.get("blocking", false):
			for point in critical:
				if at.distance_to(point) < 2.0:
					result.append(id + ": collision near protected destination " + str(point))
	for layer in ["Water", "Collision"]:
		for at in layers.get(layer, {}):
			for point in critical:
				if Vector2(at).distance_to(point) < 2.0:
					result.append(layer + ": painted over protected destination " + str(point))
	for object in objects:
		if not object.get("blocking", false): continue
		var at: Vector2 = object.get("position", Vector2.ZERO)
		var footprint: Vector2 = object.get("footprint", Vector2(0.7, 0.5))
		if spatial.conflicts(Rect2(at - footprint * 0.5, footprint).grow(WorldLayout.ACTOR_CLEARANCE)):
			result.append(str(object.get("id", "object")) + ": footprint obstructs reserved route or approach")
	for layer in ["Terrain", "Paths", "Water", "Shore", "Collision"]:
		for at in layers.get(layer, {}):
			var material := cell(layer, at)
			if layer in ["Water", "Collision"] or material.begins_with("sea"):
				if spatial.conflicts(Rect2(Vector2(at), Vector2.ONE)):
					result.append(layer + ": obstructs reserved route at " + str(at))
			elif layer in ["Terrain", "Paths", "Shore"] and (WorldTerrain.is_sea(Vector2(at) + Vector2.ONE * 0.5) or water_cell(at)):
				result.append(layer + ": land paint cannot reclaim water at " + str(at))
	# Reachability for authored geometry catches walls that do not touch a landmark.
	var blocked := {}
	for layer in ["Water", "Collision"]:
		for at in layers.get(layer, {}): blocked[at] = true
	for object in objects:
		if not object.get("blocking", false): continue
		var center: Vector2 = object.get("position", Vector2.ZERO)
		var footprint: Vector2 = object.get("footprint", Vector2(0.7, 0.5))
		var area := Rect2(center - footprint * 0.5 - Vector2.ONE * 0.25, footprint + Vector2.ONE * 0.5)
		for y in range(int(floor(area.position.y)), int(ceil(area.end.y))):
			for x in range(int(floor(area.position.x)), int(ceil(area.end.x))): blocked[Vector2i(x, y)] = true
	var start := Vector2i(spatial.position_of("arrival"))
	var reached := {start: true}
	var todo: Array[Vector2i] = [start]
	while not todo.is_empty():
		var at: Vector2i = todo.pop_back()
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = at + direction
			if Rect2i(Vector2i.ZERO, size).has_point(next) and not blocked.has(next) and not reached.has(next):
				reached[next] = true
				todo.append(next)
	for point in critical:
		if not reached.has(Vector2i(point)):
			result.append("Authored geometry disconnects destination " + str(point))
	return result


func resolved_layout(saved: Dictionary = {}) -> WorldLayout:
	var source := layout if layout else WorldLayout.village()
	return source.resolved(objects, saved)


func copy_map() -> AuthoredMap:
	var result := AuthoredMap.new()
	result.restore(snapshot())
	result.version = version
	result.title = title
	result.size = size
	result.palette = palette
	result.editor_hidden = editor_hidden.duplicate(true)
	result.editor_locked = editor_locked.duplicate(true)
	return result


func water_cell(at: Vector2i) -> bool:
	if not cell("Water", at).is_empty(): return true
	for layer in ["Terrain", "Paths", "Shore"]:
		if cell(layer, at).begins_with("sea"): return true
	return false
