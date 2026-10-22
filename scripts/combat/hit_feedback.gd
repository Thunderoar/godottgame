class_name HitFeedback
extends RefCounted
## Shared hit pipeline: white flash on the victim, directional sparks, a damage
## number, hit-stop and a camera micro-shake — all quality-gated through
## GameSettings and pooled through Vfx, so a busy fight allocates nothing.
##
## Callers only pass what they know; everything else has a sensible default.


static func impact(victim: Node2D, from_dir: Vector2, damage: int, opts := {}) -> void:
	if victim == null or not is_instance_valid(victim):
		return
	var at: Vector2 = victim.global_position + Vector2(0, -0.6)
	var color: Color = opts.get("color", Color("#ffe7a1"))
	var shake: float = opts.get("shake", 0.0)
	var shake_time: float = opts.get("shake_time", 0.12)
	var hitstop: float = opts.get("hitstop", 0.0)
	var crit := bool(opts.get("crit", false))
	# Victim flash (its own sprite, not the pool).
	var sprite: CanvasItem = victim.get("sprite") if victim.get("sprite") is CanvasItem else null
	if sprite != null:
		flash_white(sprite, 0.09)
	# Sparks fly opposite the swing direction.
	var spark_dir := -from_dir if from_dir != Vector2.ZERO else Vector2.ZERO
	Vfx.sparks(at, spark_dir, color, 5 if not crit else 8)
	Vfx.number(at + Vector2(0, -0.35), damage, crit, color)
	if hitstop > 0.0:
		Vfx.hit_stop([victim], hitstop)
	if shake > 0.0:
		var tree := Engine.get_main_loop() as SceneTree
		if tree != null:
			for cam in tree.get_nodes_in_group("camera"):
				if is_instance_valid(cam) and cam.has_method("shake"):
					cam.call("shake", shake, shake_time)
					break


static func flash_white(item: CanvasItem, duration := 0.09) -> void:
	# Short white flash layered on top of any running tint.
	if item == null or not is_instance_valid(item):
		return
	item.modulate = Color(1.9, 1.75, 1.6)
	var tween := item.create_tween()
	tween.tween_property(item, "modulate", Color.WHITE, duration)


static func stagger_pose(sprite: CanvasItem, base_scale: Vector2) -> void:
	# Squash on impact; the FSM's RECOVER state restores the scale.
	if sprite == null or not is_instance_valid(sprite):
		return
	var tween := sprite.create_tween()
	tween.tween_property(sprite, "scale", Vector2(base_scale.x * 1.14, base_scale.y * 0.88), 0.05)
	tween.tween_property(sprite, "scale", base_scale, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
