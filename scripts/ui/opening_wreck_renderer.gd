class_name OpeningWreckRenderer
extends RefCounted
## The same boat, a readable strike, three owned fragments and three diverging friends.
const FRAME := Vector2(480, 224)
const IMPACT := 1.45
const SCALE := 0.6
const BOAT := Vector2(2, 79)
const PIVOTS := [Vector2(72, 112), Vector2(217, 112), Vector2(365, 112)]
var _scene: OpeningKrakenRenderer
var _deck: Array[Texture2D] = []
var _rigging: Array[Texture2D] = []
var _hull: Array[Texture2D] = []
var _strikes: Array[Texture2D] = []
var _foam: Array[Texture2D] = []
var _heroes: Dictionary = {}
var _bucket: Texture2D

func _init(scene: OpeningKrakenRenderer) -> void:
	_scene = scene
	for i in 3:
		_deck.append(OpeningWreckArt.piece("deck", i))
		_rigging.append(OpeningWreckArt.piece("rigging", i))
		_hull.append(OpeningWreckArt.piece("hull", i))
	for i in OpeningWreckArt.STRIKE_FRAMES + 1: _strikes.append(OpeningWreckArt.strike(i))
	for i in 4: _foam.append(OpeningWreckArt.foam(i))
	for id in OpeningFishingRenderer.HEROES:
		_heroes[id] = [OpeningWreckArt.hero(id, 0), OpeningWreckArt.hero(id, 1)]
	_bucket = OpeningFishingArt.bucket()

static func _ease(t: float, start: float, end: float) -> float:
	var p := clampf((t - start) / (end - start), 0, 1)
	return p * p * (3.0 - 2.0 * p)

static func sample(elapsed: float, reduced: bool, quality: String) -> Dictionary:
	var t := 5.6 if reduced else clampf(elapsed, 0, 6)
	var spread := _ease(t, IMPACT, 4.2)
	var kick := sin(_ease(t, IMPACT, 2.9) * PI)
	var offsets := PackedVector2Array([Vector2(-21 * spread, 39 * spread - 7 * kick), Vector2(64 * spread, 4 * spread - 11 * kick), Vector2(102 * spread, 44 * spread - 5 * kick)])
	var turns := PackedFloat32Array([-0.15, 0.06, 0.17])
	var pivots := PackedVector2Array()
	var feet := PackedVector2Array()
	var angles := PackedFloat32Array()
	for i in 3:
		var bob := 0.0 if reduced or t < 4.2 else roundf(sin((t - 4.2) * 1.7 + i) * 0.7)
		var pivot: Vector2 = BOAT + PIVOTS[i] * SCALE + offsets[i].round() + Vector2(0, bob)
		var angle := float(turns[i]) * _ease(t, IMPACT, 3.3)
		pivots.append(pivot)
		angles.append(angle)
		var local: Vector2 = (OpeningFishingRenderer.FEET[i] * SCALE).round() - PIVOTS[i] * SCALE
		feet.append(pivot + local.rotated(angle))
	var frame := 0
	if t >= 0.55: frame = roundi(12 * _ease(t, 0.55, 1.25))
	if t >= 1.25: frame = 12 + roundi(6 * pow(clampf((t - 1.25) / 0.20, 0, 1), 2))
	if t >= IMPACT: frame = 18 + roundi(6 * _ease(t, IMPACT, 2.55))
	var debris := PackedVector2Array()
	if not reduced and t >= IMPACT and t < 3.0:
		var age := t - IMPACT
		for i in (3 if quality == "low" else 11):
			debris.append(Vector2(147 + (i - 5) * age * 21, 164 - (38 + i % 3 * 15) * age + 38 * age * age).round())
	return {"time": t, "broken": t >= IMPACT, "windup": t >= 0.55 and t < IMPACT,
		"phase": "hold" if t < 0.55 else ("windup" if t < 1.25 else ("impact" if t < 1.7 else ("separate" if t < 4.2 else "aftermath"))),
		"pivots": pivots, "feet": feet, "angles": angles, "piece_ids": PackedInt32Array([0, 1, 2]),
		"strike_frame": frame, "strike_tip": OpeningWreckArt.strike_tip(frame),
		"hero_pose": 1 if reduced or (t >= 3.0 and t < 4.8) else 0,
		"foam": not reduced and t >= IMPACT and t < 2.25,
		"foam_frame": mini(3, maxi(0, int((t - IMPACT) * 6))),
		"debris": debris, "ripples": 2 if quality == "low" else 4, "reduced": reduced}

func draw(canvas: CanvasItem, available: Rect2, state: Dictionary) -> void:
	var context := OpeningKrakenRenderer.sample(6, false, "low" if int(state.ripples) == 2 else "high")
	context.time = 6 + float(state.time)
	context.ripple_step = 0 if state.reduced else int(context.time * 5) % 4
	context.drops = not state.reduced and int(state.ripples) > 2 and state.time < 2.2
	var options := {}
	if state.time >= 0.55: options["free_arm"] = false
	if state.broken:
		options.merge({"ship": false, "fishing_line": false, "caught_arm": false})
	_scene.draw(canvas, available, context, options)
	# Frame zero delegates exactly to beat two's final keyframe.
	if state.time < 0.55: return
	var fit := OpeningKrakenRenderer.fit_rect(available)
	var factor := fit.size.x / FRAME.x
	canvas.draw_set_transform(fit.position, 0, Vector2.ONE * factor)
	canvas.draw_texture(_strikes[int(state.strike_frame)], Vector2.ZERO)
	if state.broken:
		# Currents sit behind the fragments, rather than crossing faces or captions.
		for i in 3:
			var at: Vector2 = state.pivots[i] + Vector2(-28, 24)
			for row in int(state.ripples):
				canvas.draw_rect(Rect2(at + Vector2(row * 9, row * 3), Vector2(28 - row * 3, 1)), Color("#75a7ad"))
		for i in 3: _draw_piece(canvas, fit.position, factor, state, i)
		canvas.draw_set_transform(fit.position, 0, Vector2.ONE * factor)
		for i in state.debris.size():
			canvas.draw_rect(Rect2(state.debris[i], Vector2(3 + i % 3, 2)), Color("#e1b665"))
		if state.foam:
			canvas.draw_texture(_foam[int(state.foam_frame)], Vector2(91, 132))
	canvas.draw_set_transform(Vector2.ZERO)

func _draw_piece(canvas: CanvasItem, origin: Vector2, factor: float, state: Dictionary, index: int) -> void:
	var pivot: Vector2 = state.pivots[index]
	canvas.draw_set_transform(origin + pivot * factor, float(state.angles[index]), Vector2.ONE * factor)
	var local: Vector2 = -PIVOTS[index] * SCALE
	var rect := Rect2(local, OpeningFishingArt.BOAT_SIZE * SCALE)
	canvas.draw_texture_rect(_deck[index], rect, false)
	canvas.draw_texture_rect(_rigging[index], rect, false)
	var foot: Vector2 = (OpeningFishingRenderer.FEET[index] * SCALE).round() + local
	canvas.draw_texture_rect(_heroes[OpeningFishingRenderer.HEROES[index]][int(state.hero_pose)], Rect2(foot - Vector2(14, 43), Vector2(29, 43)), false)
	if index == 2: canvas.draw_texture_rect(_bucket, Rect2(local + Vector2(210, 55), Vector2(13, 14)), false)
	canvas.draw_texture_rect(_hull[index], rect, false)
