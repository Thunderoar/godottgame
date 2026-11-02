class_name CombatImpact
extends Node2D
## Reusable contact silhouette. Bounded local geometry, no full-screen flash,
## no timers/tweens to outlive pool reuse, no gameplay RNG consumption.
var age := 0.0
var duration := 0.2
var direction := Vector2.RIGHT
var tint := Color("#ffe7a1")
var kind := "normal"
var serial := 0

func _ready() -> void:
	add_to_group("combat_visual_effects")
	z_as_relative = false
	z_index = 710
	visible = false
	set_process(false)

func play(at: Vector2, aim: Vector2, color: Color, variant: String) -> void:
	global_position = at
	direction = aim.normalized() if aim.length_squared() > 0.001 else Vector2.RIGHT
	tint = color
	kind = variant
	age = 0
	duration = 0.28 if kind in ["critical","finisher","defeat"] else 0.2
	serial += 1
	visible = true
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	advance(delta)

func advance(delta: float) -> void:
	age += delta
	if age >= duration:
		visible = false
		set_process(false)
	queue_redraw()

func _draw() -> void:
	if not visible: return
	var t := clampf(age/duration,0,1)
	var fade := pow(1.0-t,1.4)
	var quiet := GameSettings.reduce_motion()
	var low := not GameSettings.effects_at_least("med")
	var high := GameSettings.effects_at_least("high") and not quiet
	var size := 1.45 if kind in ["finisher","defeat"] else (1.25 if kind == "critical" else 1.0)
	var color := tint
	if kind == "armor": color = Color("#b9d9ef")
	if kind == "hurt": color = Color("#ff9b85")
	if kind in ["finisher","defeat"]: color = Color("#ffd28a")
	var aa := not VisualStyle.is_pixel()
	draw_set_transform(Vector2.ZERO,direction.angle(),Vector2.ONE*size)
	# Held lozenge is the accessible low-motion fallback.
	var r := 0.12 if quiet else lerpf(0.19,0.06,t)
	if not kind.begins_with("material_"):
		draw_colored_polygon(PackedVector2Array([Vector2(-r*1.4,0),Vector2(0,-r),Vector2(r*1.4,0),Vector2(0,r)]),Color(color,fade))
	if quiet: return
	if kind.begins_with("material_"):
		# Four compact deterministic fragments; secondary and lower contrast than
		# damage cores/telegraphs. No new nodes, gameplay RNG or ground writes.
		for i in 4:
			var axis := Vector2.from_angle(-1.2+float(i)*0.8)
			var at := axis*(0.08+t*0.42)+Vector2(0,t*t*0.18)
			if kind == "material_ash":
				draw_circle(at,0.025,Color(tint,fade*0.45))
			else:
				draw_line(at,at+axis*(0.04 if kind == "material_steel" else 0.025),Color(tint,fade*0.65),0.025,aa)
		return
	# An ivory fracture along the impact direction reads as force rather than a
	# circular magic spell. The dark under-edge remains visible on bright sand.
	var cut_length := (0.62 if kind in ["finisher","defeat"] else 0.4)*(1.0-t)
	var cut := PackedVector2Array([Vector2(-cut_length,0),Vector2(-0.06,-0.065),Vector2(cut_length*1.25,0),Vector2(0.06,0.065)])
	draw_colored_polygon(cut,Color("#173d49",fade*0.8))
	draw_line(Vector2(-cut_length,0),Vector2(cut_length*1.25,0),Color(1,0.99,0.9,fade),0.045,aa)
	if kind == "armor":
		# Two broken brackets mean armor, never a false BLOCK/miss label.
		for side in [-1,1]:
			var x: float = float(side)*(0.22+t*0.15)
			draw_polyline(PackedVector2Array([Vector2(x*0.6,-0.2),Vector2(x,0),Vector2(x*0.6,0.2)]),Color(color,fade),0.045,aa)
	else:
		var count := 4 if low else (8 if kind in ["critical","finisher","defeat"] else 6)
		for i in count:
			var angle := TAU*float(i)/count+0.2
			var axis := Vector2.from_angle(angle)
			var distance := 0.1+t*(0.5 if high else 0.32)
			var length := (0.3 if i%2 == 0 else 0.16)*(1-t)
			draw_line(axis*distance,axis*(distance+length),Color(color,fade),0.045 if i%2 == 0 else 0.025,aa)
	if not low:
		draw_line(Vector2(-0.21,0),Vector2(0.25,0),Color(1,0.99,0.91,fade),0.045,aa)
	if kind in ["finisher","defeat"] and not low:
		# Directional pressure front, not a gameplay shockwave/hitbox.
		draw_arc(Vector2.ZERO,0.32+t*0.55,-1.0,1.0,14,Color(color,fade*0.65),0.035,aa)
	if high:
		# Short, broken contact halo; the center stays transparent/readable.
		for i in 3:
			var angle := i*TAU/3+0.2
			draw_arc(Vector2.ZERO,0.24+t*0.34,angle,angle+0.65,7,Color(color,fade*0.35),0.02,aa)
