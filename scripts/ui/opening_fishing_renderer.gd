class_name OpeningFishingRenderer
extends RefCounted
## One deterministic, presentation-only shot. No timers, nodes, saves or world RNG.

const FRAME := Vector2(640, 270)
const FEET := [Vector2(105, 112), Vector2(235, 112), Vector2(318, 112)]
const HEROES := ["adam", "arjun", "mei_ling"]
var _backdrop: Texture2D
var _cloud: Texture2D
var _deck: Texture2D
var _hull: Texture2D
var _bucket: Texture2D
var _rigging: Array[Texture2D] = []
var _heroes: Dictionary = {}

func _init() -> void:
	# Warm every finite frame once before the timed shot; _draw never builds images.
	_backdrop = OpeningFishingArt.backdrop()
	_cloud = OpeningFishingArt.cloud()
	_deck = OpeningFishingArt.deck()
	_hull = OpeningFishingArt.hull()
	_bucket = OpeningFishingArt.bucket()
	for frame in 3: _rigging.append(OpeningFishingArt.rigging(frame))
	for id in HEROES:
		var poses: Array[Texture2D] = []
		for pose in 3: poses.append(OpeningFishingArt.hero(id, pose))
		_heroes[id] = poses

static func sample(elapsed: float, reduced: bool, quality: String) -> Dictionary:
	var t := 0.0 if reduced else clampf(elapsed, 0.0, 6.0)
	var boat := Vector2(100, 48 + roundf(sin(t * 1.15) * 1.5))
	var poses := PackedInt32Array([0, 0, 0])
	if not reduced:
		poses[0] = 1 if t >= 2.6 and t < 4.2 else (2 if t >= 0.6 and t < 0.8 else 0)
		poses[1] = 1 if t >= 1.0 and t < 2.6 else (2 if t >= 3.1 and t < 3.3 else 0)
		poses[2] = 1 if t >= 2.8 and t < 4.4 else (2 if t >= 4.6 and t < 4.8 else 0)
	var lift := 1.5 if poses[1] == 1 else 0.0
	var hand := boat + Vector2(249, 85 - lift)
	var tip := boat + Vector2(354, 38 - lift * 2)
	return {
		"boat": boat, "poses": poses,
		"feet": PackedVector2Array([boat + FEET[0], boat + FEET[1], boat + FEET[2]]),
		"hand": hand, "rod_tip": tip,
		"float": Vector2(593, 228 + roundf(sin(t * 2.1))),
		"cloud_shift": roundf(t * 0.6), "flag": 0 if reduced else int(t * 2) % 3,
		"ripple": 0 if reduced else int(t * 3) % 3,
		"glints": 4 if quality == "low" else (9 if quality == "med" else 16),
		"reflection": quality != "low", "phase": t,
	}

static func fit_rect(available: Rect2) -> Rect2:
	var factor := minf(available.size.x / FRAME.x, available.size.y / FRAME.y)
	factor = maxf(0.001, factor)
	var extent := FRAME * factor
	return Rect2(available.position + (available.size - extent) * 0.5, extent)

func draw(canvas: CanvasItem, available: Rect2, state: Dictionary) -> void:
	var fitted := fit_rect(available)
	var factor := fitted.size.x / FRAME.x
	canvas.draw_set_transform(Vector2.ZERO)
	# Only empty sky/water extend with aspect ratio; ship and actors stay uniform.
	canvas.draw_texture_rect(_backdrop, available, false)
	canvas.draw_set_transform(fitted.position, 0, Vector2.ONE * factor)
	canvas.draw_texture_rect(_backdrop, Rect2(Vector2.ZERO, FRAME), false)
	canvas.draw_texture(_cloud, Vector2(48 + state.cloud_shift, 25))
	canvas.draw_texture_rect(_cloud, Rect2(Vector2(345 - state.cloud_shift, 18), Vector2(108, 24)), false)
	_draw_water(canvas, state)
	var boat: Vector2 = state.boat
	# Hull reflection is water-relative and stays underneath the boat.
	if state.reflection:
		for i in 5:
			var width := 265.0 - i * 34
			var x := boat.x + 220 - width * 0.5 + (int(state.ripple) - 1) * (i % 2)
			canvas.draw_rect(Rect2(x, 214 + i * 5, width, 2), Color(0.73, 0.72, 0.40, 0.23 - i * 0.025))
	canvas.draw_line(Vector2(boat.x + 74, 213), Vector2(boat.x + 373, 207), Color("#286c78"), 3)
	canvas.draw_texture(_deck, boat)
	canvas.draw_texture(_rigging[int(state.flag)], boat)
	for i in HEROES.size():
		var foot: Vector2 = state.feet[i]
		var at := foot - Vector2(OpeningFishingArt.HERO_SIZE.x * 0.5, OpeningFishingArt.HERO_SIZE.y)
		canvas.draw_texture_rect(_heroes[HEROES[i]][int(state.poses[i])], Rect2(at, OpeningFishingArt.HERO_SIZE), false)
	canvas.draw_texture(_bucket, boat + Vector2(350, 92))
	_draw_fishing(canvas, state)
	canvas.draw_texture(_hull, boat)
	# Broken foam hugs the hull instead of scrolling through it.
	for i in 6:
		var x := boat.x + 87 + i * 45
		canvas.draw_line(Vector2(x, 214 - i), Vector2(x + 20, 214 - i), Color("#b6d9c3"), 1)
	canvas.draw_set_transform(Vector2.ZERO)

func _draw_water(canvas: CanvasItem, state: Dictionary) -> void:
	for i in int(state.glints):
		var x := float(posmod(i * 137 + 31, 620))
		var y := float(111 + posmod(i * 23, 148))
		var on := posmod(int(float(state.phase) * 2) + i, 4) != 0
		if on:
			canvas.draw_line(Vector2(x, y), Vector2(x + 4 + i % 9, y), Color("#c1dcc5"), 1)
	# Two tiny distant seabirds; never a flock across the characters.
	if int(state.glints) > 9:
		for i in 2:
			var at := Vector2(350 + i * 27 + state.cloud_shift, 65 + i * 8)
			canvas.draw_polyline(PackedVector2Array([at + Vector2(-4, 0), at + Vector2(-2, -1), at, at + Vector2(2, -1), at + Vector2(4, 0)]), Color("#72989d"), 1)

func _draw_fishing(canvas: CanvasItem, state: Dictionary) -> void:
	var hand: Vector2 = state.hand
	var tip: Vector2 = state.rod_tip
	var bobber: Vector2 = state.float
	var rod := PackedVector2Array([hand + Vector2(-8, 5), hand, hand.lerp(tip, 0.35) + Vector2(0, -3), hand.lerp(tip, 0.7) + Vector2(0, -2), tip])
	canvas.draw_polyline(rod, Color("#5d4835"), 2)
	canvas.draw_polyline(rod, Color("#dbb773"), 1)
	canvas.draw_rect(Rect2(hand + Vector2(-4, 2), Vector2(4, 4)), Color("#a8b6a6"))
	# Fishing line is derived from the actual tip and float, not unrelated strokes.
	var fishing_line := PackedVector2Array()
	for i in 17:
		var u := float(i) / 16.0
		fishing_line.append(tip.lerp(bobber, u) + Vector2(0, sin(u * PI) * 12))
	canvas.draw_polyline(fishing_line, Color("#f5e9bc"), 1)
	var ripple := 7 + int(state.ripple) * 3
	canvas.draw_polyline(PackedVector2Array([bobber + Vector2(-ripple, 1), bobber + Vector2(-ripple + 3, 3), bobber + Vector2(ripple - 3, 3), bobber + Vector2(ripple, 1)]), Color("#a8d4c5"), 1)
	canvas.draw_rect(Rect2(bobber + Vector2(-1, -4), Vector2(3, 4)), Color("#c06b50"))
	canvas.draw_rect(Rect2(bobber + Vector2(-1, 0), Vector2(3, 3)), Color("#f6e6ba"))
