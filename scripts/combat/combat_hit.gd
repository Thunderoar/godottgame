class_name CombatHit
extends RefCounted
## Incremental result adapter around the existing duck-typed damage API. Rules
## remain in take_damage; presentation reads this accepted transaction afterward.
var accepted := false
var damage_applied := 0
var hp_before := 0
var hp_after := 0
var lethal := false
var armored := false
var heavy := false
var attack_id := 0
var material := "flesh"
var position := Vector2.ZERO
var normal := Vector2.RIGHT
var world: Node
var victim: Node2D

static func world_of(actor: Node) -> Node:
	if not is_instance_valid(actor) or not actor.is_inside_tree(): return null
	var game := actor.get_tree().get_first_node_in_group("game") as Game
	if is_instance_valid(game):
		return game.world if is_instance_valid(game.world) and game.world.is_ancestor_of(actor) else null
	return actor.get_parent()

static func anchor(actor: Node2D, direction: Vector2, source: Node = null) -> Vector2:
	var fallback := actor.global_position+Vector2(0,-0.6)
	var image := actor.get_node_or_null("Sprite") as Sprite2D
	if image == null or image.texture == null: return fallback
	var local := image.get_rect()
	var center := image.to_global(local.get_center())
	var half := local.size*image.global_scale.abs()*0.38
	var desired := fallback-direction.normalized()*minf(half.x,0.6)
	if source is Node2D:
		desired = source.global_position+Vector2(0,-0.65)
	var point := Vector2(clampf(desired.x,center.x-half.x,center.x+half.x),clampf(desired.y,center.y-half.y,center.y+half.y))
	# Contact is a clamped visible-surface approximation, not a new hitbox.
	if direction.length_squared() > 0.001 and (point-center).length_squared() < 0.01:
		point = center-direction.normalized()*minf(half.x,half.y)
	return point

static func describe(actor: Node2D, before: int, after: int, direction: Vector2, source: Node = null, strong := false) -> CombatHit:
	var result := CombatHit.new()
	result.accepted = after < before
	result.hp_before = before
	result.hp_after = after
	result.damage_applied = maxi(0,before-after)
	result.lethal = result.accepted and after <= 0
	result.victim = actor
	result.world = world_of(actor)
	result.normal = direction.normalized() if direction.length_squared() > 0.001 else Vector2.RIGHT
	result.position = anchor(actor,direction,source)
	result.heavy = strong
	if actor is Enemy:
		result.armored = actor.is_boss
		result.material = "steel" if actor.is_boss or actor is RealmGuard else ("ash" if actor.kind == "fire" else ("stone" if actor.kind == "urchin" else "flesh"))
	if source is Player: result.attack_id = source.attack_serial
	return result

static func apply(actor: Node2D, amount: int, direction: Vector2, source: Node = null) -> CombatHit:
	if not is_instance_valid(actor) or actor.is_queued_for_deletion() or not actor.has_method("take_damage"):
		return CombatHit.new()
	var owner := world_of(actor)
	if owner == null or (is_instance_valid(source) and world_of(source) != owner): return CombatHit.new()
	var before: int = int(actor.get("hp"))
	actor.call("take_damage",amount,direction,source)
	if not is_instance_valid(actor): return CombatHit.new()
	var after: int = int(actor.get("hp"))
	if actor is Enemy and after < before and actor.last_hit_result != null:
		return actor.last_hit_result
	return describe(actor,before,after,direction,source)
