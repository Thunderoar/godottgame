class_name CombatVisuals
extends Sprite2D
## Actor-owned, geometry-only weapon presentation. Never moves the actor or
## applies damage. The inherited Slash Sprite2D API remains available to probes.
var stage := "idle"
var arc := "lr"
var style := "sword"
var direction := Vector2.RIGHT
var reach := 2.05
var elapsed := 0.0
var duration := 0.22
var _windup := 0.06

func _ready() -> void:
	add_to_group("combat_visual_effects")
	z_as_relative = false
	z_index = 690
	texture = null
	visible = false

func anticipate(aim: Vector2, weapon: String, kind: String, seconds: float, radius: float) -> void:
	direction = aim.normalized() if aim.length_squared() > 0.001 else Vector2.RIGHT
	style = weapon
	arc = kind
	reach = radius
	_windup = maxf(seconds,0.01)
	elapsed = 0
	stage = "anticipation"
	visible = true
	queue_redraw()

func strike(aim: Vector2, weapon: String, kind: String, radius: float) -> void:
	direction = aim.normalized() if aim.length_squared() > 0.001 else Vector2.RIGHT
	style = weapon
	arc = kind
	reach = radius
	elapsed = 0
	duration = 0.26 if kind == "thrust" or kind == "slam" else 0.22
	stage = "active"
	visible = true
	queue_redraw()

func cancel() -> void:
	stage = "idle"
	visible = false
	queue_redraw()

func _process(delta: float) -> void:
	advance(delta)

func advance(delta: float) -> void:
	if stage == "idle": return
	elapsed += delta
	if stage == "active" and elapsed >= duration:
		cancel()
	else:
		queue_redraw()

func _draw() -> void:
	if stage == "idle": return
	var quiet := GameSettings.reduce_motion()
	var low := not GameSettings.effects_at_least("med")
	var high := GameSettings.effects_at_least("high") and not quiet
	var tint := Color("#8ee8e0")
	if style == "scythe": tint = Color("#c4b4ff")
	if style == "bow": tint = Color("#adefb9")
	if arc == "slam": tint = Color("#ffc476")
	var aa := not VisualStyle.is_pixel()
	draw_set_transform(Vector2(0,-0.62), direction.angle(), Vector2(1,0.64))
	if stage == "anticipation":
		# A small held edge, not a range/area telegraph that could imply damage.
		var charge := clampf(elapsed/_windup,0,1)
		var tip := Vector2(0.68,-0.18 if arc == "rl" else 0.18)
		draw_line(tip-Vector2(0.2,0),tip+Vector2(0.14,0),Color(tint,0.7),0.035,aa)
		if not low:
			draw_line(tip-Vector2(0,0.08),tip+Vector2(0,0.08),Color(1,0.98,0.83,0.5+charge*0.4),0.025,aa)
		return
	var t := clampf(elapsed/duration,0,1)
	var opacity := pow(1.0-t,0.8)
	if quiet:
		# Essential direction and weapon identity remain, but no moving sweep,
		# orbiting glints, large flare or expanding halo.
		if arc == "thrust" or style == "bow":
			draw_line(Vector2(0.45,0),Vector2(reach,0),Color(tint,opacity*0.8),0.055,aa)
		else:
			draw_arc(Vector2.ZERO,reach*0.82,-0.78,0.78,12,Color(tint,opacity*0.8),0.055,aa)
		return
	if arc == "thrust" or style == "bow":
		var length := reach*(0.75+0.25*sin(t*PI*0.5))
		var width := 0.16 if arc == "thrust" else 0.09
		_polygon(PackedVector2Array([Vector2(0.25,0),Vector2(length*0.6,-width),Vector2(length,0),Vector2(length*0.6,width)]),Color("#123c48"),opacity*0.85)
		_polygon(PackedVector2Array([Vector2(0.45,0),Vector2(length*0.65,-width*0.6),Vector2(length,0),Vector2(length*0.65,width*0.6)]),tint,opacity)
		draw_line(Vector2(0.5,0),Vector2(length-0.06,0),Color(1,0.98,0.89,opacity),0.035,aa)
		if high:
			for side in [-1,1]:
				draw_line(Vector2(0.5,side*0.25),Vector2(length*0.8,side*0.12),Color(tint,opacity*0.45),0.025,aa)
		return
	var sign_dir := -1.0 if arc == "rl" else 1.0
	var head := lerpf(-0.6,0.9,minf(t/0.55,1.0))*sign_dir
	var tail := head-1.25*sign_dir
	var radius := reach*0.83
	if arc == "slam":
		radius = reach*0.7
		head = 1.3
		tail = -1.3
	var segments := 12 if low else (28 if high else 20)
	# Dark silhouette prevents the ivory edge vanishing against sand/daylight.
	_ribbon(radius,tail,head,0.2,Color("#173d49"),opacity*0.78,segments)
	_ribbon(radius,tail,head,0.14,tint,opacity*0.9,segments)
	_ribbon(radius+0.035,tail,head,0.04,Color("#fff7dc"),opacity,segments)
	if not low:
		_ribbon(radius-0.18,tail-sign_dir*0.2,head-sign_dir*0.22,0.05,Color("#eeb66d"),opacity*0.55,segments)
	if high:
		for i in 3:
			var angle := head-sign_dir*(0.3+i*0.38)
			var a := Vector2.from_angle(angle)*(radius+0.09)
			draw_line(a,a+Vector2.from_angle(angle+sign_dir*1.2)*0.16,Color(tint,opacity*0.5),0.025,aa)

func _polygon(points: PackedVector2Array, color: Color, alpha: float) -> void:
	draw_colored_polygon(points,Color(color,alpha))

func _ribbon(radius: float, start: float, end: float, width: float, color: Color, alpha: float, segments: int) -> void:
	var points := PackedVector2Array()
	for i in segments+1:
		var u := float(i)/segments
		var w := width*sin(u*PI*0.9)
		points.append(Vector2.from_angle(lerpf(start,end,u))*(radius+w))
	for i in range(segments,-1,-1):
		var u := float(i)/segments
		var w := width*sin(u*PI*0.9)
		points.append(Vector2.from_angle(lerpf(start,end,u))*(radius-w))
	_polygon(points,color,alpha)
