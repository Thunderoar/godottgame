class_name ReunionRenderer
extends RefCounted
## Player-paced three-person conversation; all state is sampled, never persisted here.
const HOMES := {"adam":Vector2(184,197),"arjun":Vector2(251,172),"mei_ling":Vector2(316,197)}
var _yard: Array[Texture2D] = []
var _dock: Array[Texture2D] = []
var _actors: Dictionary = {}
var _table: Texture2D
var _ship: Texture2D
var _villager: Texture2D

func _init() -> void:
	for night in [false,true]:
		_yard.append(ReunionArt.courtyard(night))
		_dock.append(ReunionArt.dock(night))
	for id in HOMES:
		for mood in ReunionArt.MOODS:
			for posture in 5:
				for left in [false,true]: _actors["%s/%s/%d/%s" % [id,mood,posture,left]] = ReunionArt.actor(id,mood,posture,left)
	_table = ReunionArt.table()
	_ship = PixelArt.ship_texture()
	_villager = OpeningRescueArt.villager("water_keeper",false)

static func _ease(t: float, start: float, end: float) -> float:
	var u := clampf((t-start)/(end-start),0,1)
	return u*u*(3-2*u)

static func sample(turn_index: int, elapsed: float, reduced: bool, quality: String, night: bool) -> Dictionary:
	var row := ReunionDialogueDB.turn(turn_index)
	var beat := int(row.beat)
	var t := maxf(0,elapsed)
	var adam: Vector2 = HOMES.adam
	var posture := 0
	if beat == 0:
		adam = Vector2(140,197).lerp(HOMES.adam,1.0 if reduced else _ease(t,0,1.4)).round()
		if not reduced: posture = 3+int(t*5)%2 if t < 1.4 else (1 if t < 1.7 else 0)
	var rising := beat == 6 and turn_index == ReunionDialogueDB.TURNS.size()-1
	var rise := 2 if reduced and rising else (mini(2,floori(maxf(0,t-0.4)*2)) if rising else 0)
	return {"beat":beat,"speaker":str(row.speaker),"mood":str(row.mood),"time":t,
		"adam":adam,"adam_posture":posture,"rise":rise,"dock":beat == 7,"night":night,
		"bag":1.0 if reduced else _ease(t,0.3,1.4),"detail":quality != "low","reduced":reduced,
		"zoom":1.3 if beat in [1,2,3] else 1.0}

func draw(canvas: CanvasItem, available: Rect2, state: Dictionary) -> void:
	var fitted := OpeningCaptureRenderer.fit_rect(available)
	canvas.draw_set_transform(Vector2.ZERO)
	canvas.draw_rect(available,Color("#172830"))
	var zoom: float = state.zoom
	var offset := Vector2(240,112)-Vector2(250,145)*zoom
	if is_equal_approx(zoom,1): offset = Vector2.ZERO
	offset = offset.clamp(Vector2(480,224)*(1-zoom),Vector2.ZERO)
	var factor := fitted.size.x/480.0
	canvas.draw_set_transform(fitted.position+offset*factor,0,Vector2.ONE*factor*zoom)
	if state.dock:
		_draw_dock(canvas,state)
	else:
		canvas.draw_texture(_yard[1 if state.night else 0],Vector2.ZERO)
		if int(state.beat) == 4:
			var passing := Vector2(349,156).lerp(Vector2(407,156),0.5 if state.reduced else _ease(float(state.time),0,4)).round()
			canvas.draw_texture(_villager,passing-Vector2(20,52),Color("#b7bda8") if state.night else Color.WHITE)
		for id in ["arjun","adam","mei_ling"]:
			var feet: Vector2 = state.adam if id == "adam" else HOMES[id]
			var posture: int = state.rise
			if id == "adam" and int(state.beat) == 0: posture = int(state.adam_posture)
			var mood: String = state.mood if state.speaker == id else "soft"
			if int(state.beat) == 2 and id == "mei_ling" and state.speaker != id: mood = "cup"
			var bench: Vector2 = HOMES[id]
			canvas.draw_rect(Rect2(bench+Vector2(-18,-8),Vector2(36,5)),Color("#8f754f"))
			for x in [-13,11]: canvas.draw_rect(Rect2(bench+Vector2(x,-3),Vector2(3,5)),Color("#64523e"))
			_actor(canvas,id,mood,posture,feet,id == "mei_ling" or (id == "arjun" and state.speaker != "mei_ling"))
		canvas.draw_texture(_table,Vector2(207,178))
		# The lantern's steady core survives low effects, mute and reduced motion.
		if state.night:
			if state.detail: canvas.draw_circle(Vector2(278,171),22,Color(0.94,0.72,0.38,0.10))
			canvas.draw_rect(Rect2(274,162,8,15),Color("#594936"))
			canvas.draw_rect(Rect2(276,164,4,9),Color("#ffe1a1"))
	canvas.draw_set_transform(Vector2.ZERO)

func _actor(canvas: CanvasItem, id: String, mood: String, posture: int, feet: Vector2, left: bool) -> void:
	canvas.draw_rect(Rect2(feet+Vector2(-12,-1),Vector2(24,2)),Color("#4a4b3e"))
	canvas.draw_texture(_actors["%s/%s/%d/%s" % [id,mood,posture,left]],feet-Vector2(24,60))

func _draw_dock(canvas: CanvasItem, state: Dictionary) -> void:
	canvas.draw_texture(_dock[1 if state.night else 0],Vector2.ZERO)
	canvas.draw_texture_rect(_ship,Rect2(249,48,220,135),false,Color("#adb8ba") if state.night else Color.WHITE)
	# Fixed mooring lines: this is preparation, never an automatic sailing transition.
	canvas.draw_line(Vector2(294,168),Vector2(323,151),Color("#d1ba87"),2,false)
	canvas.draw_polyline(PackedVector2Array([Vector2(229,183),Vector2(250,185),Vector2(279,176),Vector2(294,168)]),Color("#d1ba87"),1,false)
	_actor(canvas,"mei_ling","resolved" if float(state.bag) < 1 else "soft",2,Vector2(133,203),float(state.bag) < 1)
	_actor(canvas,"adam","resolved",2,Vector2(211,204),false)
	_actor(canvas,"arjun","resolved",2,Vector2(261,197),false)
	var bag := Vector2(115,181).lerp(Vector2(97,171),float(state.bag)).round()
	canvas.draw_rect(Rect2(bag-Vector2(7,7),Vector2(14,13)),Color("#74604b"))
	canvas.draw_rect(Rect2(bag-Vector2(6,6),Vector2(12,10)),Color("#bea77b"))
	canvas.draw_line(bag+Vector2(-3,-7),bag+Vector2(3,-7),Color("#e4c58a"),2,false)
	canvas.draw_rect(Rect2(bag+Vector2(-1,-3),Vector2(3,4)),Color("#80613d"))
