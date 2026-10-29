class_name OpeningLandfallRenderer
extends RefCounted
## Wreck -> drift -> grounded bow -> climb ashore -> existing sentries notice.
## One page clock, no gameplay actors/RNG/timers, and no new magical crossing.
const FRAME := Vector2(480, 224)
const GROUNDED := 3.3
const ASHORE := 4.4
const NOTICE := 4.5
const HOLD := 5.3
var _backdrop: Texture2D
var _fragment: Texture2D
var _heroes: Array[Texture2D] = []
var _guards: Array[Texture2D] = []

func _init() -> void:
	_backdrop = PixelArt.cached_texture("opening/landfall/backdrop/v1", func() -> Image:
		var img := PixelArt.image(480, 224)
		for i in 4: PixelArt.rect(img, 0, i * 23, 480, 23, Color(["#302f4b", "#45405e", "#5d5572", "#7b7287"][i]))
		for i in 6: PixelArt.rect(img, 0, 93 + i * 25, 480, 25, Color(["#467886", "#356575", "#295365", "#213f53", "#213f53", "#213f53"][i]))
		for i in 58:
			PixelArt.hline(img, posmod(i * 61, 471), 99 + posmod(i * 17, 121), 4 + i % 12, Color("#5b8d94") if i % 3 == 0 else Color("#3e6a79"))
		# Exactly the same occupied landing and architecture as the next montage.
		img.blit_rect(OpeningCaptureArt.backdrop(true).get_image(), Rect2i(0, 0, 232, 224), Vector2i(248, 0))
		return img)
	var source := OpeningWreckArt.piece("hull", 2).get_image().duplicate() as Image
	_fragment = ImageTexture.create_from_image(source.get_region(Rect2i(288, 103, 150, 61)))
	for pose in 3: _heroes.append(OpeningCaptureArt.hero("mei_ling", pose))
	for frame in 2: _guards.append(OpeningCaptureArt.guard(frame))

static func _ease(t: float, start: float, end: float) -> float:
	var u := clampf((t - start) / (end - start), 0, 1)
	return u * u * (3 - 2 * u)

static func sample(elapsed: float, reduced: bool, quality: String) -> Dictionary:
	var t := 5.8 if reduced else clampf(elapsed, 0, 6)
	var drift := _ease(t, 0.3, GROUNDED)
	var fragment := Vector2(48, 171).lerp(Vector2(264, 195), drift).round()
	var attached := fragment + Vector2(45, 6)
	var climb := _ease(t, GROUNDED, ASHORE)
	var mei := attached.lerp(Vector2(360, 210), climb).round()
	var notice := _ease(t, NOTICE, HOLD)
	return {"time": t, "phase": "drift" if t < GROUNDED else ("land" if t < ASHORE else ("notice" if t < HOLD else "hold")),
		"fragment": fragment, "piece_id": 2, "mei": mei, "attached": t <= GROUNDED,
		"grounded": t >= GROUNDED, "ashore": t >= ASHORE, "noticed": t >= NOTICE,
		"mei_pose": 2 if t < GROUNDED else (0 if t < NOTICE else 1),
		"rear": Vector2(340, 168).lerp(Vector2(317, 202), notice).round(),
		"lead": Vector2(435, 188).lerp(Vector2(459, 188), notice).round(),
		"guard_frame": int(t * 5) % 2 if not reduced and t > NOTICE and t < HOLD else 0,
		"ripples": 2 if quality == "low" else 5, "water_frame": 0 if reduced or t >= HOLD else int(t * 3) % 3}

func draw(canvas: CanvasItem, available: Rect2, state: Dictionary) -> void:
	var fitted := OpeningCaptureRenderer.fit_rect(available)
	canvas.draw_set_transform(Vector2.ZERO)
	canvas.draw_rect(available, Color("#102733"))
	canvas.draw_set_transform(fitted.position, 0, Vector2.ONE * (fitted.size.x / FRAME.x))
	canvas.draw_texture(_backdrop, Vector2.ZERO)
	# The posted sentries exist before they notice the shipwreck survivor.
	for key in ["rear", "lead"]:
		var at: Vector2 = state[key]
		canvas.draw_rect(Rect2(at + Vector2(-15, -1), Vector2(30, 3)), Color("#24323f"))
		canvas.draw_texture(_guards[int(state.guard_frame)], at - Vector2(19, 58))
	for i in int(state.ripples):
		var at: Vector2 = state.fragment + Vector2(-9 - i * 7, 17 + i * 3)
		canvas.draw_rect(Rect2(at + Vector2(state.water_frame, 0), Vector2(14 + i * 3, 1)), Color("#78a0a0"))
	canvas.draw_texture_rect(_fragment, Rect2(state.fragment, Vector2(66, 27)), false)
	canvas.draw_texture(_heroes[int(state.mei_pose)], state.mei - Vector2(16, 48))
	canvas.draw_set_transform(Vector2.ZERO)
