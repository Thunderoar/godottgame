class_name OpeningWelcomeRenderer
extends RefCounted
## Shore continuity -> offered cloth -> invitation -> village path -> belonging.
const FRAME := Vector2(480, 224)
const OFFER := 1.5
const RECEIVED := 2.2
const WALK := 2.9
const SETTLE := 4.95
var _rescue: OpeningRescueRenderer
var _backdrop: Texture2D
var _adam: Array[Texture2D] = []
var _helper: Array[Texture2D] = []
var _planter: Array[Texture2D] = []
var _host: Texture2D
var _turtle: Texture2D
var _stern: Texture2D
var _cloth: Texture2D

func _init(rescue: OpeningRescueRenderer) -> void:
	_rescue = rescue
	_backdrop = OpeningWelcomeArt.backdrop()
	_adam = [OpeningRescueArt.adam(3), OpeningRescueArt.adam(0), OpeningWelcomeArt.adam_step(0), OpeningWelcomeArt.adam_step(1)]
	_helper = [OpeningRescueArt.villager("water_keeper", true), OpeningWelcomeArt.guide()]
	_planter = [OpeningRescueArt.villager("tree_planter", true), OpeningWelcomeArt.planter_empty()]
	_host = OpeningWelcomeArt.host()
	_turtle = OpeningRescueArt.turtle(0)
	_stern = OpeningRescueArt.stern()
	_cloth = OpeningWelcomeArt.cloth()

static func _ease(t: float, start: float, end: float) -> float:
	var u := clampf((t - start) / (end - start), 0, 1)
	return u * u * (3 - 2 * u)

static func sample(elapsed: float, reduced: bool, quality: String) -> Dictionary:
	var t := 6.0 if reduced else clampf(elapsed, 0, 6)
	var walk := _ease(t, WALK, SETTLE)
	var adam := OpeningRescueRenderer.LAND_FEET.lerp(Vector2(526, 187), walk).round()
	var helper := OpeningRescueRenderer.HELPER.lerp(Vector2(448, 210), _ease(t, 0.35, 1.0)).lerp(Vector2(568, 205), walk).round()
	var planter := OpeningRescueRenderer.NEIGHBOUR.lerp(Vector2(405, 187), _ease(t, 0.65, OFFER)).lerp(Vector2(430, 149), _ease(t, RECEIVED, 2.8)).round()
	var transfer := _ease(t, OFFER, RECEIVED)
	var cloth := (planter + Vector2(-5, -14)).lerp(adam + Vector2(8, -14), transfer).round()
	return {"time": t, "phase": "shore" if t < 0.35 else ("offer" if t < OFFER else ("receive" if t < RECEIVED else ("invite" if t < WALK else ("walk" if t < SETTLE else "home")))),
		"adam": adam, "helper": helper, "planter": planter, "host": Vector2(634, 177),
		"turtle": Vector2(270, 164), "camera": roundf(200 * _ease(t, 2.8, SETTLE)),
		"cloth": cloth, "separate_cloth": t >= OFFER, "received": t >= RECEIVED,
		"guided": t >= RECEIVED, "settled": t >= SETTLE,
		"adam_pose": (2 + int((t - WALK) * 6) % 2) if t > WALK and t < SETTLE else (1 if t >= RECEIVED else 0), "helper_pose": 1 if t >= 0.35 else 0,
		"ripples": 2 if quality == "low" else 6, "glints": quality != "low",
		"water_frame": 0 if reduced or t >= SETTLE else int(t * 3) % 3}

static func fit_rect(available: Rect2) -> Rect2:
	return OpeningRescueRenderer.fit_rect(available)

func draw(canvas: CanvasItem, available: Rect2, state: Dictionary) -> void:
	# The opening hold is literally the preceding promise's rendered final tableau.
	if state.time <= 0.35:
		_rescue.draw(canvas, available, OpeningRescueRenderer.sample(6, false, "low" if int(state.ripples) == 2 else "high"))
		return
	var fit := fit_rect(available)
	var factor := fit.size.x / FRAME.x
	var camera := float(state.camera)
	canvas.draw_set_transform(Vector2.ZERO)
	canvas.draw_rect(available, Color("#102733"))
	canvas.draw_set_transform(fit.position, 0, Vector2.ONE * factor)
	# Region drawing clips the panorama without leaking into caption/letterbox space.
	canvas.draw_texture_rect_region(_backdrop, Rect2(Vector2.ZERO, FRAME), Rect2(Vector2(camera, 0), FRAME))
	for i in int(state.ripples):
		var at := Vector2(334 - i * 4 - camera, 160 + i * 10)
		canvas.draw_rect(Rect2(at + Vector2(state.water_frame, 0), Vector2(7, 1)), Color("#c6debc"))
	if state.glints:
		for i in 8:
			canvas.draw_rect(Rect2(211 + i % 3 * 10 + state.water_frame - camera, 109 + i * 9, 7 + i % 4 * 3, 1), Color("#a4c2ac"))
	# The host becomes visible through the pan; there is no appearing/spawning actor.
	var actors := [
		{"feet": state.host, "texture": _host, "size": Vector2(40, 52)},
		{"feet": state.planter, "texture": _planter[1 if state.separate_cloth else 0], "size": Vector2(40, 52)},
		{"feet": state.helper, "texture": _helper[int(state.helper_pose)], "size": Vector2(40, 52)},
		{"feet": state.adam, "texture": _adam[int(state.adam_pose)], "size": Vector2(32, 48)}]
	actors.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.feet.y < b.feet.y)
	_clipped_texture(canvas, _stern, Rect2(OpeningRescueRenderer.WRECK - Vector2(camera, 0), Vector2(66, 27)))
	canvas.draw_texture(_turtle, state.turtle - Vector2(camera, 0))
	for actor in actors:
		var at: Vector2 = actor.feet - Vector2(camera, 0)
		var extent: Vector2 = actor.size
		var rect := Rect2(at - Vector2(extent.x * 0.5, extent.y), extent)
		# Keep offscreen actors fully outside until their sprite enters the stage.
		var clipped := rect.intersection(Rect2(Vector2.ZERO, FRAME))
		if not clipped.has_area(): continue
		canvas.draw_rect(Rect2(at + Vector2(-9, -1), Vector2(18, 2)).intersection(Rect2(Vector2.ZERO, FRAME)), Color("#bca479"))
		canvas.draw_texture_rect_region(actor.texture, clipped, Rect2(clipped.position - rect.position, clipped.size))
	if state.separate_cloth:
		if not state.received:
			canvas.draw_line(state.adam + Vector2(14 - camera, -22), state.cloth + Vector2(-7 - camera, -2), Color("#d9b18b"), 1, false)
			canvas.draw_line(state.planter + Vector2(-12 - camera, -18), state.cloth + Vector2(7 - camera, -2), Color("#d9b18b"), 1, false)
		canvas.draw_texture(_cloth, state.cloth - Vector2(camera + 9, 6))
	canvas.draw_set_transform(Vector2.ZERO)

func _clipped_texture(canvas: CanvasItem, texture: Texture2D, rect: Rect2) -> void:
	var clipped := rect.intersection(Rect2(Vector2.ZERO, FRAME))
	if not clipped.has_area(): return
	var ratio := Vector2(texture.get_size()) / rect.size
	canvas.draw_texture_rect_region(texture, clipped, Rect2((clipped.position - rect.position) * ratio, clipped.size * ratio))
