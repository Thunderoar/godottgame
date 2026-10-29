class_name OpeningKrakenRenderer
extends RefCounted
## Pure six-second shot: catch -> tension -> emergence -> waking fury -> hold.
const FRAME := Vector2(480, 224)
const WATERLINE := 197.0
const BOAT_SCALE := 0.6
var _skies: Array[Texture2D] = []
var _bodies: Array[Texture2D] = []
var _heroes: Dictionary = {}
var _caught_arms: Array[Texture2D] = []
var _free_arms: Array[Texture2D] = []
var _deck: Texture2D
var _hull: Texture2D
var _rigging: Texture2D
var _bucket: Texture2D

func _init() -> void:
	for frame in OpeningKrakenArt.ARM_FRAMES + 1:
		_caught_arms.append(OpeningKrakenArt.arm(frame, true))
		_free_arms.append(OpeningKrakenArt.arm(frame, false))
	for pose in 3:
		_skies.append(OpeningKrakenArt.backdrop(pose))
		_bodies.append(OpeningKrakenArt.body(pose))
	for id in OpeningFishingRenderer.HEROES:
		var frames: Array[Texture2D] = []
		for pose in 3: frames.append(OpeningKrakenArt.hero(id, pose))
		_heroes[id] = frames
	_deck = OpeningFishingArt.deck()
	_hull = OpeningFishingArt.hull()
	_rigging = OpeningFishingArt.rigging(0)
	_bucket = OpeningFishingArt.bucket()

static func _ease(t: float, start: float, end: float) -> float:
	var p := clampf((t - start) / (end - start), 0.0, 1.0)
	return p * p * (3.0 - 2.0 * p)

static func sample(elapsed: float, reduced: bool, quality: String) -> Dictionary:
	# Accessibility shows the complete readable key pose without bob/recoil/drops.
	var t := 4.8 if reduced else clampf(elapsed, 0.0, 6.0)
	var catch := _ease(t, 0.5, 1.4)
	var rise := _ease(t, 1.6, 3.6)
	var awake := t >= 3.4
	var pose := 2 if t >= 4.2 else (1 if awake else 0)
	var boat := Vector2(4 - roundf(catch * 2.0), 78 + (0.0 if reduced else roundf(sin(t * 1.3))))
	var feet := PackedVector2Array()
	for foot in OpeningFishingRenderer.FEET: feet.append(boat + (foot * BOAT_SCALE).round())
	var hand := boat + Vector2(149, 51)
	var tip := boat + Vector2(212 - roundf(catch * 14), 23 + roundf(catch * 12))
	var arm_step := roundi(rise * OpeningKrakenArt.ARM_FRAMES)
	var hook := OpeningKrakenArt.hook_at(arm_step)
	var line := PackedVector2Array()
	for i in 17:
		var u := float(i) / 16.0
		line.append((tip.lerp(hook, u) + Vector2(0, sin(u * PI) * lerpf(14, 1, catch))).round())
	return {"time": t, "phase": "catch" if t < 1.4 else ("tension" if t < 1.6 else ("emerge" if t < 3.4 else "fury")),
		"boat": boat, "feet": feet, "hand": hand, "rod_tip": tip, "hook": hook,
		"line": line, "catch": catch, "rise": rise, "awake": awake, "pose": pose,
		"body_at": Vector2(310, roundf(200 - rise * 180)), "arm_step": arm_step,
		"sky": 2 if awake else (1 if t >= 1.6 else 0),
		"hero_pose": 0 if t < 0.7 else (1 if t < 3.4 else 2),
		"drops": not reduced and quality != "low" and t >= 1.6,
		"ripples": 2 if quality == "low" else 5,
		"ripple_step": 0 if reduced else int(t * 5) % 4}

static func fit_rect(available: Rect2) -> Rect2:
	var factor := maxf(0.001, minf(available.size.x / FRAME.x, available.size.y / FRAME.y))
	var extent := FRAME * factor
	return Rect2((available.position + (available.size - extent) * 0.5).floor(), extent)

func draw(canvas: CanvasItem, available: Rect2, state: Dictionary, options: Dictionary = {}) -> void:
	var fitted := fit_rect(available)
	canvas.draw_set_transform(Vector2.ZERO)
	canvas.draw_texture_rect(_skies[int(state.sky)], available, false)
	canvas.draw_set_transform(fitted.position, 0, Vector2.ONE * (fitted.size.x / FRAME.x))
	canvas.draw_texture_rect(_skies[int(state.sky)], Rect2(Vector2.ZERO, FRAME), false)
	# A shadow, not a fully visible monster, precedes the water breaking.
	if state.catch > 0:
		for i in 5:
			canvas.draw_rect(Rect2(299 - i * 7, 185 + i * 5, 136 + i * 9, 3), Color("#284a66"))
	if state.rise > 0:
		var at: Vector2 = state.body_at
		var visible_height := clampf(WATERLINE - at.y, 0, 170)
		if visible_height > 0:
			canvas.draw_texture_rect_region(_bodies[int(state.pose)], Rect2(at, Vector2(156, visible_height)), Rect2(0, 0, 156, visible_height))
		if bool(options.get("free_arm", true)):
			canvas.draw_texture(_free_arms[int(state.arm_step)], Vector2.ZERO)
	# Keep the ship whole until beat three. Mast, hands, boots and rail share one offset.
	var boat: Vector2 = state.boat
	var extent := OpeningFishingArt.BOAT_SIZE * BOAT_SCALE
	if bool(options.get("ship", true)):
		canvas.draw_texture_rect(_deck, Rect2(boat, extent), false)
		canvas.draw_texture_rect(_rigging, Rect2(boat, extent), false)
		for i in 3:
			var id: String = OpeningFishingRenderer.HEROES[i]
			canvas.draw_texture_rect(_heroes[id][int(state.hero_pose)], Rect2(state.feet[i] - Vector2(14, 43), Vector2(29, 43)), false)
		canvas.draw_texture_rect(_bucket, Rect2(boat + Vector2(210, 55), Vector2(13, 14)), false)
		_draw_rod(canvas, state)
		canvas.draw_texture_rect(_hull, Rect2(boat, extent), false)
	# The caught tip rises on the SAME anchor as the hook/line, never a detached stroke.
	if state.catch > 0 and bool(options.get("caught_arm", true)):
		canvas.draw_texture(_caught_arms[int(state.arm_step)], Vector2.ZERO)
	if bool(options.get("fishing_line", true)):
		canvas.draw_polyline(state.line, Color("#efe3b8"), 1, false)
		var hook: Vector2 = state.hook
		canvas.draw_polyline(PackedVector2Array([hook + Vector2(0, -3), hook + Vector2(0, 4), hook + Vector2(4, 4), hook + Vector2(5, 0)]), Color("#f5d998"), 1, false)
	_draw_water(canvas, state)
	canvas.draw_set_transform(Vector2.ZERO)

func _draw_rod(canvas: CanvasItem, state: Dictionary) -> void:
	var hand: Vector2 = state.hand
	var tip: Vector2 = state.rod_tip
	var bend := float(state.catch) * 8
	var rod := PackedVector2Array([hand + Vector2(-6, 4), hand, (hand.lerp(tip, 0.45) + Vector2(0, -9)).round(), (hand.lerp(tip, 0.75) + Vector2(0, -7 + bend)).round(), tip])
	canvas.draw_polyline(rod, Color("#443d36"), 3, false)
	canvas.draw_polyline(rod, Color("#d4af70"), 1, false)
	canvas.draw_rect(Rect2(hand + Vector2(-3, 2), Vector2(4, 4)), Color("#a4b1a0"))

func _draw_water(canvas: CanvasItem, state: Dictionary) -> void:
	for i in int(state.ripples):
		var x := 290 - i * 8 - int(state.ripple_step)
		var y := 199 + i * 5
		canvas.draw_rect(Rect2(x, y, 15 + i * 3, 2), Color("#94c2bd"))
		canvas.draw_rect(Rect2(415 + i * 3, y - 3, 16, 2), Color("#7ca9ac"))
	# Fixed arithmetic droplets: no physics, randomness, emitters or flashing overlay.
	if state.drops:
		for i in 9:
			var age := fposmod(float(state.time) * 1.2 + float(i) * 0.19, 1.0)
			var at := Vector2(286 + i * 18, 180 - sin(age * PI) * (12 + i % 4 * 6))
			canvas.draw_rect(Rect2(at.round(), Vector2(2, 3)), Color("#9ac6c2"))
