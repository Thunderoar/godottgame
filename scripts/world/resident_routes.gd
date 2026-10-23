class_name ResidentRoutes
extends RefCounted
## Obstacle-aware planning only: collision bodies travel continuously between
## visible corners; cells are never assigned to an actor's logical position.

const CELL := 0.5
const CLEARANCE := 0.25
var _grid := AStarGrid2D.new()
var _world: Node2D
var _bounds: Rect2
var _built := false
var revision := 0


func _init(world: Node2D, bounds: Rect2 = Rect2(0, 0, 64, 40)) -> void:
	_world = world
	_bounds = bounds


func invalidate() -> void:
	_built = false
	revision += 1


func _query(at: Vector2) -> PhysicsShapeQueryParameters2D:
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = CLEARANCE
	query.shape = shape
	query.transform = Transform2D(0.0, at)
	query.collision_mask = 1
	return query


func point_clear(at: Vector2) -> bool:
	if not _bounds.has_point(_world.to_local(at)):
		return false
	return _world.get_world_2d().direct_space_state.intersect_shape(_query(at), 1).is_empty()


func segment_clear(from: Vector2, to: Vector2) -> bool:
	if not point_clear(from) or not point_clear(to):
		return false
	var query := _query(from)
	query.motion = to - from
	var fractions := _world.get_world_2d().direct_space_state.cast_motion(query)
	return fractions[0] >= 0.999


func _build() -> void:
	_grid.region = Rect2i(Vector2i.ZERO, Vector2i((_bounds.size / CELL).ceil()))
	_grid.cell_size = Vector2.ONE * CELL
	_grid.offset = _bounds.position + Vector2.ONE * CELL * 0.5
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_grid.update()
	var query := _query(Vector2.ZERO)
	(query.shape as CircleShape2D).radius = 0.35
	for y in _grid.region.size.y:
		for x in _grid.region.size.x:
			var cell := Vector2i(x, y)
			query.transform = Transform2D(0.0, _world.to_global(_grid.get_point_position(cell)))
			_grid.set_point_solid(cell, not _world.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty())
	_built = true


func _cell(at: Vector2) -> Vector2i:
	return Vector2i(((_world.to_local(at) - _bounds.position) / CELL).floor()).clamp(Vector2i.ZERO, _grid.region.size - Vector2i.ONE)


func _nearest_open(at: Vector2i, from: Vector2, require_visible: bool) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_distance := INF
	for radius in range(0, 5):
		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				var cell := at + Vector2i(x, y)
				if not _grid.is_in_boundsv(cell) or _grid.is_point_solid(cell):
					continue
				var point := _world.to_global(_grid.get_point_position(cell))
				var distance := from.distance_squared_to(point)
				if distance < best_distance and (not require_visible or segment_clear(from, point)):
					best = cell
					best_distance = distance
		if best.x >= 0:
			return best
	return best


func path(from: Vector2, to: Vector2, allow_nearest_goal: bool = true) -> PackedVector2Array:
	if not point_clear(to) and not allow_nearest_goal:
		return PackedVector2Array()
	if segment_clear(from, to):
		return PackedVector2Array([to])
	if not _built:
		_build()
	var start := _nearest_open(_cell(from), from, true)
	var end := _nearest_open(_cell(to), to, false)
	if start.x < 0 or end.x < 0:
		return PackedVector2Array()
	var cells := _grid.get_point_path(start, end)
	if cells.is_empty():
		return PackedVector2Array()
	var points := PackedVector2Array()
	for point in cells:
		points.append(_world.to_global(point))
	if segment_clear(points[-1], to):
		points.append(to)
	elif not allow_nearest_goal:
		return PackedVector2Array()
	# Follow visible corners rather than decelerating toward every planning cell.
	var result := PackedVector2Array()
	var origin := from
	var index := 0
	while index < points.size():
		var furthest := index
		for next in range(index, points.size()):
			if not segment_clear(origin, points[next]):
				break
			furthest = next
		if not segment_clear(origin, points[furthest]):
			return PackedVector2Array()
		result.append(points[furthest])
		origin = points[furthest]
		index = furthest + 1
	return result
