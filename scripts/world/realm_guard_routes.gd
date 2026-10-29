class_name RealmGuardRoutes
extends ResidentRoutes
## Player routes stay open; only these monster grids exclude abstract refuges.

func _init(world: Node2D, region: Rect2) -> void:
	super(world,region)
	clearance = 0.55

func point_clear(at: Vector2) -> bool:
	return _bounds.grow(-clearance).has_point(_world.to_local(at)) and not RealmCombatDB.protected(_world.to_local(at),clearance) and super.point_clear(at)

func segment_clear(from: Vector2, to: Vector2) -> bool:
	if RealmCombatDB.allowed_fraction(_world.to_local(from),_world.to_local(to),_bounds,clearance) < 0.999: return false
	return super.segment_clear(from,to)

func _build() -> void:
	super._build()
	for y in _grid.region.size.y:
		for x in _grid.region.size.x:
			var cell := Vector2i(x,y)
			var point := _grid.get_point_position(cell)
			if not _bounds.grow(-clearance).has_point(point) or RealmCombatDB.protected(point,clearance): _grid.set_point_solid(cell,true)
