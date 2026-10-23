class_name Vfx
extends RefCounted
## Static facade over the world's pooled VFX nodes. Every world root adds one
## `VfxPool` (see `Vfx.ensure_pool`); call sites never allocate nodes per hit,
## they borrow one from the pool. Honours GameSettings reduce-motion and the
## effects-quality tier so low-end devices can shed ambient layers.


static func ensure_pool(world: Node) -> VfxPool:
	# Idempotent: returns the world's existing pool when present.
	if not _available(world):
		return null
	for node in world.get_children():
		if node is VfxPool and _available(node):
			return node
	var pool := VfxPool.new()
	pool.name = "VfxPool"
	world.add_child(pool)
	return pool


static func pool() -> VfxPool:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	for node in tree.get_nodes_in_group("vfx_pool"):
		if _available(node):
			return node as VfxPool
	return null


static func sparks(at: Vector2, dir: Vector2, color: Color = Color("#ffe7a1"), count: int = 6) -> void:
	var pool := pool()
	if pool == null:
		return
	pool.sparks(at, dir, color, count)


static func ring(at: Vector2, radius: float, color: Color = Color("#ffd47b"), duration: float = 0.45) -> void:
	var pool := pool()
	if pool == null:
		return
	pool.ring(at, radius, color, duration)


static func dust(at: Vector2, count: int = 3, color: Color = Color(0.78, 0.72, 0.6, 0.75)) -> void:
	var pool := pool()
	if pool == null:
		return
	pool.dust(at, count, color)


static func number(at: Vector2, amount: int, crit := false, color: Color = Color("#ffe7a1")) -> void:
	var pool := pool()
	if pool == null:
		return
	pool.number(at, amount, crit, color)


static func pop(at: Vector2, kind: String, color: Color = Color.WHITE) -> void:
	var pool := pool()
	if pool == null:
		return
	pool.pop(at, kind, color)


static func leaves(at: Vector2, count: int = 3, color: Color = Color("#c7e07a")) -> void:
	var pool := pool()
	if pool == null:
		return
	pool.leaves(at, count, color)


static func burst(at: Vector2, color: Color, count: int = 8) -> void:
	# Radial spark burst with no direction bias; used for deaths and pickups.
	sparks(at, Vector2.ZERO, color, count)


static func hit_stop(nodes: Array, seconds: float) -> void:
	# Holds participating visual poses briefly, while gameplay simulation continues.
	# Skipped entirely under reduce-motion or low effects quality.
	if seconds <= 0.0 or GameSettings.reduce_motion() or not GameSettings.effects_at_least("med"):
		return
	for node in nodes:
		if is_instance_valid(node) and node.has_method("apply_hit_stop"):
			node.call("apply_hit_stop", seconds)


static func _available(node: Node) -> bool:
	if not is_instance_valid(node) or not node.is_inside_tree():
		return false
	var ancestor := node
	while ancestor != null:
		if ancestor.is_queued_for_deletion():
			return false
		ancestor = ancestor.get_parent()
	return true
