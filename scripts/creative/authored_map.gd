@tool
class_name AuthoredMap
extends Resource
## Sparse, versioned authoring layers; player settlement layout stays in GameState.
const LAYERS := ["Terrain", "Paths", "Water", "Shore", "Decoration", "Vegetation", "Buildings", "Gameplay", "Collision", "Foreground"]
const MATERIALS := ["grass", "grass_light", "grass_shadow", "path", "sand", "sea_shallow", "sea_deep", "stone", "flower"]
@export var version := 1
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
	return {"layers": layers.duplicate(true), "objects": objects.duplicate(true)}

func restore(state: Dictionary) -> void:
	layers = state.layers.duplicate(true)
	objects.assign(state.objects.duplicate(true))
	emit_changed()

func warnings() -> PackedStringArray:
	var result := PackedStringArray()
	var ids := {}
	var critical := [Vector2(34, 24.3), Vector2(34, 23.7), Vector2(30.8, 11.3), Vector2(37.2, 11.3), Vector2(41.2, 16.2), Vector2(23.8, 22.2), Vector2(26.8, 18.8), Vector2(21.3, 20.5)]
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
	var start := Vector2i(34, 24)
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
