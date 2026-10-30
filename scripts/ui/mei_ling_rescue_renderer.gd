class_name MeiLingRescueRenderer
extends RefCounted
## Seven deterministic shots; progression, input and audio remain owned by Game/StorySequence.
const DURATIONS := [2.0, 3.0, 3.0, 5.0, 5.0, 4.0, 2.0]
const TITLES := ["THE LAST STRIKE", "THE SEAL BREAKS", "A STEP INTO FREEDOM", "FOUND AT LAST", "A ROAD HOME", "BESUT WELCOMES HER", "THE WILDS RESTORED"]
const PRISON := Vector2(356, 174)
const RIFT := Vector2(425, 190)
const ZOOMS := [1.0, 1.55, 1.3, 1.6, 1.0, 1.15, 1.0]
const FOCUS := [Vector2(240,112), Vector2(350,126), Vector2(345,145), Vector2(288,166), Vector2(240,112), Vector2(260,155), Vector2(240,112)]
var _hall: Texture2D
var _restored: Texture2D
var _village: Texture2D
var _fiend: Texture2D
var _keeper: Texture2D
var _planter: Texture2D
var _heroes: Dictionary = {}

func _init() -> void:
	_hall = MeiLingRescueArt.hall(false)
	_restored = MeiLingRescueArt.hall(true)
	_village = MeiLingRescueArt.village()
	_fiend = PixelArt.enemy_texture("demon_chaos", true, 0)
	_keeper = OpeningRescueArt.villager("water_keeper", true)
	_planter = OpeningRescueArt.villager("tree_planter", true)
	# Warm finite poses before drawing; no cache generation or save writes in draw().
	for id in ["adam", "mei_ling", "arjun"]:
		for pose in MeiLingRescueArt.Pose.size():
			for left in [false, true]: _heroes["%s/%d/%s" % [id, pose, left]] = MeiLingRescueArt.hero(id, pose, left)
	MeiLingRescueArt.prison_back()
	MeiLingRescueArt.gate()

static func _ease(t: float, start: float, end: float) -> float:
	var u := clampf((t - start) / (end - start), 0, 1)
	return u * u * (3 - 2 * u)

static func sample(beat: int, elapsed: float, reduced: bool, quality: String, arjun_rescued: bool) -> Dictionary:
	var index := clampi(beat, 0, DURATIONS.size() - 1)
	var t := clampf(elapsed, 0, float(DURATIONS[index]))
	for previous in index: t += float(DURATIONS[previous])
	# Reduced motion retains a composed illustration of every event, without pans or flashes.
	if reduced: t = [1.7, 4.4, 7.9, 11.5, 15.0, 21.8, 23.9][index]
	var release := _ease(t, 6, 8)
	var meeting := _ease(t, 8, 10.8)
	var departure := _ease(t, 16, 18)
	var adam := Vector2(145, 190).lerp(Vector2(270, 190), meeting).round()
	var mei := (PRISON + Vector2(0,-10)).lerp(Vector2(356,190), release).lerp(Vector2(306,190), meeting).lerp(RIFT, departure).round()
	var contact := t >= 10.8 and t < 12.2
	var walking := (t > 6 and t < 10.8) or (t > 16 and t < 18)
	var step := MeiLingRescueArt.Pose.WALK_A if int(t * 5) % 2 == 0 else MeiLingRescueArt.Pose.WALK_B
	return {"beat": index, "time": t, "village": index == 5,
		"gate": _ease(t, 5, 6), "seal": 1.0 - _ease(t, 2.5, 5), "cracks": _ease(t, 2.2, 4),
		"fiend_alpha": 1.0 - _ease(t, 0.4, 1.8), "ash": 4 if quality == "low" else 14,
		"adam": adam, "mei": mei, "contact": contact,
		"adam_pose": MeiLingRescueArt.Pose.REACH if contact else (MeiLingRescueArt.Pose.POINT if index == 4 else (step if t > 8 and t < 10.8 else MeiLingRescueArt.Pose.IDLE)),
		"mei_pose": MeiLingRescueArt.Pose.REACH if contact else (step if walking and not reduced else MeiLingRescueArt.Pose.IDLE),
		"captive": t < 6, "mei_visible": index < 5 and t < 18,
		"restoration": _ease(t, 13, 14.5), "portal": _ease(t, 13, 14),
		"village_mei": Vector2(110,190).lerp(Vector2(240,190), _ease(t,18,20.8)).round(),
		"village_pose": step if t < 20.8 and not reduced else MeiLingRescueArt.Pose.IDLE,
		"arjun": arjun_rescued, "reduced": reduced, "zoom": float(ZOOMS[index]), "focus": FOCUS[index]}

func draw(canvas: CanvasItem, available: Rect2, state: Dictionary) -> void:
	var fitted := OpeningCaptureRenderer.fit_rect(available)
	canvas.draw_set_transform(Vector2.ZERO)
	canvas.draw_rect(available, Color("#151e2b"))
	var zoom: float = state.zoom
	var offset: Vector2 = Vector2(240,112) - Vector2(state.focus) * zoom
	offset = offset.clamp(Vector2(480,224) * (1.0 - zoom), Vector2.ZERO)
	var factor := fitted.size.x / 480.0
	canvas.draw_set_transform(fitted.position + offset * factor, 0, Vector2.ONE * factor * zoom)
	if state.village:
		canvas.draw_texture(_village, Vector2.ZERO)
		_portal(canvas, Vector2(86,190), 1.0)
		canvas.draw_texture(_keeper, Vector2(312,190) - Vector2(20,52))
		canvas.draw_texture(_planter, Vector2(378,190) - Vector2(20,52))
		if state.arjun: _hero(canvas, "arjun", MeiLingRescueArt.Pose.IDLE, Vector2(282,190), true)
		_hero(canvas, "mei_ling", int(state.village_pose), state.village_mei, false)
	else:
		canvas.draw_texture(_hall, Vector2.ZERO)
		canvas.draw_texture(_restored, Vector2.ZERO, Color(1,1,1,float(state.restoration)))
		MeiLingRescueArt.draw_prison(canvas, PRISON, float(state.gate), bool(state.captive), float(state.seal), float(state.cracks), MeiLingRescueArt.Pose.ALERT if float(state.time) >= 2.5 else MeiLingRescueArt.Pose.IDLE)
		if float(state.fiend_alpha) > 0:
			var collapse := _ease(float(state.time),0.1,1.8)
			canvas.draw_texture_rect(_fiend, Rect2(190 + collapse * 4,42 + collapse * 19,92 - collapse * 8,146 - collapse * 19), false, Color(1,1,1,float(state.fiend_alpha)))
		if int(state.beat) == 0 and not state.reduced:
			for i in int(state.ash):
				var travel := _ease(float(state.time),0.2,2)
				var at := Vector2(224 + (i % 5) * 7, 96 + (i % 4) * 15) + Vector2((i % 3 - 1) * 13,-24) * travel
				canvas.draw_rect(Rect2(at.round(),Vector2(2,3)),Color(0.74,0.53,0.69,1.0-travel))
		_portal(canvas, RIFT, float(state.portal))
		if int(state.beat) not in [1,2]: _hero(canvas, "adam", int(state.adam_pose), state.adam, false)
		if state.mei_visible and not state.captive:
			_hero(canvas, "mei_ling", int(state.mei_pose), state.mei, float(state.time) < 16)
	canvas.draw_set_transform(Vector2.ZERO)

func _hero(canvas: CanvasItem, id: String, pose: int, feet: Vector2, left: bool) -> void:
	canvas.draw_rect(Rect2(feet + Vector2(-11,-1), Vector2(22,2)), Color("#30333b"))
	canvas.draw_texture(_heroes["%s/%d/%s" % [id,pose,left]], feet - Vector2(24,52))

func _portal(canvas: CanvasItem, feet: Vector2, alpha: float) -> void:
	if alpha <= 0: return
	canvas.draw_rect(Rect2(feet + Vector2(-28,-2),Vector2(56,5)),Color(0.74,0.66,0.50,alpha))
	canvas.draw_arc(feet + Vector2(0,-34),31,PI,TAU,24,Color(0.83,0.76,0.59,alpha),5,false)
	for x in [-31,31]: canvas.draw_line(feet + Vector2(x,-34),feet + Vector2(x,0),Color(0.66,0.62,0.54,alpha),5,false)
	canvas.draw_circle(feet + Vector2(0,-30),27,Color(0.13,0.29,0.33,alpha))
	canvas.draw_arc(feet + Vector2(0,-30),22,0,TAU,24,Color(0.69,0.86,0.72,alpha),2,false)
