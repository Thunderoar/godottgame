class_name OpeningCaptureRenderer
extends RefCounted
## Two separate shores, sequential action, then a shared readable captivity hold.
const FRAME := Vector2(480, 224)
const DOOR_START := 1.55
const DOOR_SHUT := 2.05
const ESCORT_START := 3.70
const HOLD_START := 4.65
var _backdrops: Array[Texture2D] = []
var _arms: Array[Texture2D] = []
var _guards: Array[Texture2D] = []
var _heroes: Dictionary = {}
var _fragments: Array[Texture2D] = []
var _king: Texture2D
var _cage_back: Texture2D
var _cage_front: Texture2D
var _cage_frame: Texture2D
var _lock: Texture2D

func _init() -> void:
	_backdrops = [OpeningCaptureArt.backdrop(false), OpeningCaptureArt.backdrop(true)]
	_king = OpeningKrakenArt.body(1)
	_cage_back = OpeningCaptureArt.cage(false)
	_cage_front = OpeningCaptureArt.cage(true)
	_cage_frame = OpeningCaptureArt.cage_frame()
	_lock = OpeningCaptureArt.lock_texture()
	for frame in OpeningCaptureArt.ARM_FRAMES + 1: _arms.append(OpeningCaptureArt.arm(frame))
	for frame in 2: _guards.append(OpeningCaptureArt.guard(frame))
	for id in ["arjun", "mei_ling"]:
		var poses: Array[Texture2D] = []
		for pose in 3: poses.append(OpeningCaptureArt.hero(id, pose))
		_heroes[id] = poses
	for index in [1, 2]:
		# Trim transparent padding from a COPY of the original owned hull fragment.
		var img := OpeningWreckArt.piece("hull", index).get_image().duplicate() as Image
		_fragments.append(ImageTexture.create_from_image(img.get_region(Rect2i(140 if index == 1 else 288, 103, 150, 61))))

static func _ease(t: float, start: float, end: float) -> float:
	var u := clampf((t - start) / (end - start), 0, 1)
	return u * u * (3 - 2 * u)

static func sample(elapsed: float, reduced: bool, quality: String) -> Dictionary:
	var t := 5.3 if reduced else clampf(elapsed, 0, 6)
	# The finite raster arm and its captive share the very same sampled contact.
	var frame := roundi(clampf(t / 2.25, 0, 1) * OpeningCaptureArt.ARM_FRAMES)
	var arm_time := float(frame) * 2.25 / OpeningCaptureArt.ARM_FRAMES
	var arjun := OpeningCaptureArt.arjun_feet(arm_time)
	var retreat := _ease(t, 2.65, ESCORT_START)
	var escort := _ease(t, ESCORT_START, HOLD_START)
	var mei := Vector2(335 + 15 * retreat + 73 * escort, 188 - 7 * escort).round()
	var lead := Vector2(459 - 73 * _ease(t, 2.25, 2.65) + 73 * escort, 188 - 7 * escort).round()
	var rear := Vector2(269 + 45 * retreat + 73 * escort, 188 - 7 * escort).round()
	var walking := (t > 2.25 and t < 2.65) or (t > 2.65 and t < HOLD_START)
	return {"time": t, "phase": "establish" if t < 0.45 else ("pull" if t < DOOR_START else ("lock" if t < 2.25 else ("surround" if t < ESCORT_START else ("escort" if t < HOLD_START else "hold")))),
		"arjun": arjun, "arm_frame": frame, "arm_tip": OpeningCaptureArt.arm_tip(frame),
		"gripping": t < DOOR_SHUT, "door": _ease(t, DOOR_START, DOOR_SHUT),
		"locked": t >= DOOR_SHUT, "arjun_pose": 2 if t < DOOR_START else 1,
		"mei": mei, "lead": lead, "rear": rear,
		"mei_pose": 0 if t < 2.65 else 1,
		"guard_frame": int(t * 5) % 2 if walking and not reduced else 0,
		"right_focus": _ease(t, 2.25, 2.65),
		"details": 2 if quality == "low" else 6,
		"water_frame": 0 if reduced or t >= HOLD_START else int(t * 3) % 3}

static func fit_rect(available: Rect2) -> Rect2:
	var factor := maxf(0.001, minf(available.size.x / FRAME.x, available.size.y / FRAME.y))
	var extent := FRAME * factor
	return Rect2((available.position + (available.size - extent) * 0.5).floor(), extent)

func draw(canvas: CanvasItem, available: Rect2, state: Dictionary) -> void:
	var fitted := fit_rect(available)
	canvas.draw_set_transform(Vector2.ZERO)
	canvas.draw_rect(available, Color("#102733"))
	canvas.draw_set_transform(fitted.position, 0, Vector2.ONE * (fitted.size.x / FRAME.x))
	canvas.draw_texture(_backdrops[0], Vector2.ZERO)
	canvas.draw_texture(_backdrops[1], Vector2(248, 0))
	# A quiet gutter separates places, while both friends remain visible throughout.
	canvas.draw_rect(Rect2(237, 12, 1, 200), Color("#526571"))
	canvas.draw_rect(Rect2(242, 12, 1, 200), Color("#526571"))
	canvas.draw_texture_rect(_king, Rect2(4, 17, 108, 118), false, Color("#b5b5c7"))
	# Two recognizable pieces of the same yellow boat grounded on separate shores.
	canvas.draw_texture_rect(_fragments[0], Rect2(47, 195, 64, 26), false)
	canvas.draw_line(Vector2(77, 196), Vector2(72, 181), Color("#bd965e"), 2)
	canvas.draw_texture_rect(_fragments[1], Rect2(264, 195, 66, 27), false)
	canvas.draw_texture(_cage_back, OpeningCaptureArt.CAGE)
	canvas.draw_texture(_arms[int(state.arm_frame)], Vector2.ZERO)
	_shadow(canvas, state.arjun, 13)
	_hero(canvas, "arjun", int(state.arjun_pose), state.arjun)
	if state.gripping:
		canvas.draw_rect(Rect2(state.arm_tip - Vector2(2, 3), Vector2(5, 7)), Color("#b59aa5"))
	# A falling portcullis is clipped to the doorway, never drawn above the roof.
	var visible := roundf(73 * float(state.door))
	if visible > 0:
		canvas.draw_texture_rect_region(_cage_front,
			Rect2(OpeningCaptureArt.CAGE + Vector2(0, 25), Vector2(94, visible)),
			Rect2(0, 98 - visible, 94, visible))
	canvas.draw_texture(_cage_frame, OpeningCaptureArt.CAGE)
	if state.locked: canvas.draw_texture(_lock, OpeningCaptureArt.CAGE + Vector2(39, 69))
	_shadow(canvas, state.rear, 16)
	_guard(canvas, state.rear, int(state.guard_frame), false)
	_shadow(canvas, state.mei, 13)
	_hero(canvas, "mei_ling", int(state.mei_pose), state.mei)
	_shadow(canvas, state.lead, 16)
	_guard(canvas, state.lead, int(state.guard_frame), true)
	# Selective local shade directs attention without hiding either face.
	var focus := float(state.right_focus)
	canvas.draw_rect(Rect2(0, 0, 232, 224), Color(0.04, 0.09, 0.16, 0.08 * focus))
	canvas.draw_rect(Rect2(248, 0, 232, 224), Color(0.04, 0.06, 0.14, 0.16 * (1 - focus)))
	for side in [0, 248]:
		for i in int(state.details):
			canvas.draw_rect(Rect2(side + 8 + i * 7 + state.water_frame, 186 + i * 5, 10 + i * 2, 1), Color("#78a0a0"))
	canvas.draw_set_transform(Vector2.ZERO)

func _hero(canvas: CanvasItem, id: String, pose: int, feet: Vector2) -> void:
	canvas.draw_texture(_heroes[id][pose], feet - Vector2(16, 48))

func _guard(canvas: CanvasItem, feet: Vector2, frame: int, face_left: bool) -> void:
	if face_left:
		canvas.draw_texture_rect(_guards[frame], Rect2(feet - Vector2(19, 58), Vector2(-38, 58)), false)
	else:
		canvas.draw_texture(_guards[frame], feet - Vector2(19, 58))

func _shadow(canvas: CanvasItem, feet: Vector2, width: float) -> void:
	canvas.draw_rect(Rect2(feet + Vector2(-width, -1), Vector2(width * 2, 3)), Color("#24323f"))
