class_name OpeningRescueRenderer
extends RefCounted
## The sixth beat performs the rescue: stranded -> offered shell -> ride -> welcome.
const FRAME := Vector2(480, 224)
const MEET := 1.25
const BOARDED := 2.1
const DEPART := 2.3
const ARRIVE := 4.25
const STEP := 4.4
const HOLD := 5.15
const SEAT := Vector2(41, 9)
const WRECK := Vector2(65, 178)
const WRECK_FEET := Vector2(101, 184)
const LAND_FEET := Vector2(368, 187)
const HELPER := Vector2(404, 184)
const NEIGHBOUR := Vector2(447, 167)
var _backdrop: Texture2D
var _stern: Texture2D
var _turtles: Array[Texture2D] = []
var _adam: Array[Texture2D] = []
var _helpers: Array[Texture2D] = []
var _neighbour: Texture2D

func _init() -> void:
	_backdrop = OpeningRescueArt.backdrop()
	_stern = OpeningRescueArt.stern()
	for frame in 4: _turtles.append(OpeningRescueArt.turtle(frame))
	for pose in 4: _adam.append(OpeningRescueArt.adam(pose))
	for welcome in [false, true]: _helpers.append(OpeningRescueArt.villager("water_keeper", welcome))
	_neighbour = OpeningRescueArt.villager("tree_planter", true)

static func _ease(t: float, start: float, end: float) -> float:
	var u := clampf((t - start) / (end - start), 0, 1)
	return u * u * (3 - 2 * u)

static func sample(elapsed: float, reduced: bool, quality: String) -> Dictionary:
	var t := 5.8 if reduced else clampf(elapsed, 0, 6)
	var approach := _ease(t, 0.25, MEET)
	var ride := _ease(t, DEPART, ARRIVE)
	var turtle := Vector2(10, 175).lerp(Vector2(108, 175), approach).lerp(Vector2(270, 164), ride).round()
	var seat := turtle + SEAT
	var board := _ease(t, MEET, BOARDED)
	var adam := WRECK_FEET.lerp(seat, board).round()
	if t >= BOARDED: adam = seat
	if t >= STEP: adam = seat.lerp(LAND_FEET, _ease(t, STEP, HOLD)).round()
	return {"time": t, "phase": "stranded" if t < 0.25 else ("approach" if t < MEET else ("board" if t < BOARDED else ("ride" if t < ARRIVE else ("land" if t < HOLD else "welcome")))),
		"piece_id": 0, "wreck": WRECK, "turtle": turtle, "seat": seat, "adam": adam,
		"boarded": t >= BOARDED, "departed": t >= DEPART, "arrived": t >= ARRIVE, "ashore": t >= HOLD,
		"helper": HELPER, "neighbour": NEIGHBOUR, "welcoming": t >= ARRIVE,
		"pose": 0 if t < MEET else (1 if t < BOARDED else (2 if t < STEP else 3)),
		"stroke": 0 if reduced or (t >= MEET and t < DEPART) or t >= ARRIVE else int(t * 5) % 4,
		"ripples": 2 if quality == "low" else 6, "glints": quality != "low",
		"water_frame": 0 if reduced or t >= HOLD else int(t * 3) % 3}

static func fit_rect(available: Rect2) -> Rect2:
	return OpeningCaptureRenderer.fit_rect(available)

static func supported(state: Dictionary) -> bool:
	var at: Vector2 = state.adam
	if state.ashore: return OpeningRescueArt.on_sand(at)
	if state.time < MEET: return at == WRECK_FEET
	if state.time < BOARDED:
		# The stern (65..131) and offered shell (119..177) overlap; no water gap.
		return at.y == WRECK_FEET.y and at.x >= WRECK_FEET.x and at.x <= state.seat.x
	if state.time < STEP: return at == state.seat
	return OpeningRescueArt.on_sand(at) or (at.x >= state.turtle.x + 15 and at.x <= state.turtle.x + 72 and absf(at.y - state.seat.y) <= 16)

func draw(canvas: CanvasItem, available: Rect2, state: Dictionary) -> void:
	var fitted := fit_rect(available)
	canvas.draw_set_transform(Vector2.ZERO)
	canvas.draw_rect(available, Color("#102733"))
	canvas.draw_set_transform(fitted.position, 0, Vector2.ONE * (fitted.size.x / FRAME.x))
	canvas.draw_texture(_backdrop, Vector2.ZERO)
	# Quiet surf follows the diagonal shore; optional detail never covers faces.
	for i in int(state.ripples):
		var at := Vector2(334 - i * 4, 160 + i * 10)
		canvas.draw_rect(Rect2(at + Vector2(state.water_frame, 0), Vector2(7, 1)), Color("#c6debc"))
	if state.glints:
		for i in 8:
			canvas.draw_rect(Rect2(211 + i % 3 * 10 + state.water_frame, 109 + i * 9, 7 + i % 4 * 3, 1), Color("#a4c2ac"))
	canvas.draw_texture(_neighbour, state.neighbour - Vector2(20, 52))
	canvas.draw_texture(_helpers[1 if state.welcoming else 0], state.helper - Vector2(20, 52))
	canvas.draw_texture_rect(_stern, Rect2(state.wreck, Vector2(66, 27)), false)
	for i in int(state.ripples):
		var at: Vector2 = state.turtle + Vector2(-9 - i * 6, 36 + i % 2 * 3)
		if at.x >= 1 and at.x + 10 <= FRAME.x:
			canvas.draw_rect(Rect2(at, Vector2(10, 1)), Color("#83b8ac"))
	canvas.draw_texture(_turtles[int(state.stroke)], state.turtle)
	if state.ashore: canvas.draw_rect(Rect2(state.adam + Vector2(-9, -1), Vector2(18, 2)), Color("#bca479"))
	canvas.draw_texture(_adam[int(state.pose)], state.adam - Vector2(16, 48))
	if state.ashore:
		# The reaching hands meet; neither actor slides or teleports into the other.
		canvas.draw_line(state.adam + Vector2(15, -22), state.helper + Vector2(-19, -21), Color("#d9b18b"), 1, false)
	canvas.draw_set_transform(Vector2.ZERO)
