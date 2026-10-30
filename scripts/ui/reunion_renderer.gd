class_name ReunionRenderer
extends RefCounted
## Deterministic dock conversation and seven authored departure shots.
const HOMES := {"adam":Vector2(168,204),"arjun":Vector2(248,198),"mei_ling":Vector2(116,187)}
const DECK := {"mei_ling":Vector2(66,83),"arjun":Vector2(111,83),"adam":Vector2(153,83)}
var _dock: Array[Texture2D] = []
var _sea: Array[Texture2D] = []
var _actors: Dictionary = {}
var _ship: Texture2D
var _rahim: Texture2D
var _villager: Texture2D
var _companion: Texture2D
var _companion_id := ""

func _init(pet_id: String = "") -> void:
	if not pet_id.is_empty():
		_companion_id = pet_id
		_companion = PixelArt.pet_texture(pet_id)
	for night in [false,true]:
		_dock.append(ReunionArt.departure_backdrop(night,false))
		_sea.append(ReunionArt.departure_backdrop(night,true))
	for id in HOMES:
		for mood in ReunionArt.MOODS:
			for posture in [2,3,4]:
				for left in [false,true]: _actors["%s/%s/%d/%s" % [id,mood,posture,left]] = ReunionArt.actor(id,mood,posture,left)
	_ship = PixelArt.ship_texture()
	_rahim = DockHost.texture()
	_villager = OpeningRescueArt.villager("water_keeper",true)

static func _ease(t: float, start: float, end: float) -> float:
	var u := clampf((t-start)/(end-start),0,1)
	return u*u*(3-2*u)

static func boarding_position(id: String, progress: float, at: Vector2, scale: float) -> Vector2:
	var foot := Vector2(276,189)
	var top := at+Vector2(51,82)*scale
	if progress < 0.45: return HOMES[id].lerp(foot,progress/0.45)
	if progress < 0.8: return foot.lerp(top,(progress-0.45)/0.35)
	return top.lerp(at+DECK[id]*scale,(progress-0.8)/0.2)

static func sample(turn_index: int, elapsed: float, reduced: bool, quality: String, night: bool) -> Dictionary:
	var row := ReunionDialogueDB.turn(turn_index)
	var stage := turn_index-ReunionDialogueDB.TURNS.size()
	var t := maxf(0,elapsed)
	var beat := int(row.beat)
	var time := float(ReunionDialogueDB.DEPARTURE_DURATIONS[clampi(stage,0,6)]) if reduced and stage >= 0 else t
	var ship_at := Vector2(230,31)
	var ship_scale := 1.25
	if stage == 3:
		ship_at += Vector2(38,-4)*_ease(time,1.4,4)
	elif stage == 4:
		var progress := _ease(time,0,5)
		ship_at += Vector2(38,-4)+Vector2(34,-20)*progress
		ship_scale = lerpf(1.25,0.8,progress)
	elif stage >= 5:
		ship_at = Vector2(76,18) if stage == 5 else Vector2(185,44)
		ship_scale = 1.6 if stage == 5 else 0.55
		if not reduced: ship_at.y += roundf(sin(t*1.2))
	var boarded := 0
	var boarding: Dictionary = {}
	var feet: Dictionary = {}
	for i in 3:
		var id: String = ["mei_ling","arjun","adam"][i]
		var progress := _ease(time,i*1.7,i*1.7+2.0) if stage == 2 else (1.0 if stage >= 3 else 0.0)
		if progress >= 1: boarded += 1
		boarding[id] = progress
		feet[id] = boarding_position(id,progress,ship_at,ship_scale)
	return {"beat":beat,"stage":stage,"speaker":str(row.speaker),"mood":str(row.mood),"time":time,
		"adam":Vector2(143,216).lerp(HOMES.adam,1.0 if reduced else _ease(t,0,1.4)).round(),
		"adam_posture":3+int(t*5)%2 if beat == 0 and t < 1.4 and not reduced else 2,
		"rise":2,"dock":true,"night":night,"detail":quality != "low","reduced":reduced,
		"bag":_ease(time,0.3,2),"ship_at":ship_at,"ship_scale":ship_scale,
		"boarding":boarding,"feet":feet,"boarded":boarded,"rope_released":stage > 3 or (stage == 3 and time >= 1.4),
		"zoom":1.22 if stage < 0 and beat in [1,2,3] else 1.0}

func draw(canvas: CanvasItem, available: Rect2, state: Dictionary, pet_id: String = "") -> void:
	var fitted := OpeningCaptureRenderer.fit_rect(available)
	canvas.draw_set_transform(Vector2.ZERO)
	canvas.draw_rect(available,Color("#172830"))
	var zoom: float = state.zoom
	var offset := (Vector2(240,112)-Vector2(210,137)*zoom).clamp(Vector2(480,224)*(1-zoom),Vector2.ZERO) if zoom > 1 else Vector2.ZERO
	var factor := fitted.size.x/480.0
	canvas.draw_set_transform(fitted.position+offset*factor,0,Vector2.ONE*factor*zoom)
	var stage := int(state.stage)
	canvas.draw_texture((_sea if stage >= 5 else _dock)[1 if state.night else 0],Vector2.ZERO)
	_draw_water(canvas,state)
	if stage in [1,2,3,4]:
		canvas.draw_texture_rect(_rahim,Rect2(21,127,35,48),false)
		canvas.draw_texture_rect(_villager,Rect2(61,136,31,40),false)
		canvas.draw_texture_rect(_villager,Rect2(96,140,28,36),false,Color("#c4d0b0"))
		if not state.reduced:
			canvas.draw_line(Vector2(48,147),Vector2(52,139+sin(float(state.time)*2)*3),Color("#dba880"),3)
	var at: Vector2 = state.ship_at
	var ship_scale: float = state.ship_scale
	canvas.draw_texture_rect(_ship,Rect2(at,_ship.get_size()*ship_scale),false,Color("#b3c4ce") if state.night else Color.WHITE)
	if stage == 2:
		var top := at+Vector2(51,82)*ship_scale
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(268,191),Vector2(284,191),top+Vector2(8,0),top-Vector2(8,0)]),Color("#b49564"))
		for i in 9:
			var board := Vector2(276,189).lerp(top,float(i)/8)
			canvas.draw_line(board-Vector2(7,0),board+Vector2(7,0),Color("#705b43"),1)
	if stage < 3 or not state.rope_released:
		canvas.draw_line(Vector2(283,171),at+Vector2(45,84)*ship_scale,Color("#d1ba87"),2)
	else:
		# Coil aboard: the shore line visibly disappears before the ship moves.
		canvas.draw_arc(at+Vector2(49,83)*ship_scale,4*ship_scale,0,TAU,16,Color("#d1ba87"),ship_scale)
	if stage < 0:
		for id in ["arjun","mei_ling","adam"]:
			var feet: Vector2 = state.adam if id == "adam" and int(state.beat) == 0 else HOMES[id]
			var mood: String = state.mood if state.speaker == id else "soft"
			_actor(canvas,id,mood,int(state.adam_posture) if id == "adam" else 2,feet,id == "arjun",1)
		_bag(canvas,Vector2(95,193),1)
	elif stage <= 2:
		for id in ["mei_ling","arjun","adam"]:
			var progress: float = state.boarding[id]
			var feet: Vector2 = state.feet[id]
			var walking: bool = progress > 0 and progress < 1 and not state.reduced
			_actor(canvas,id,"resolved" if stage == 0 else "smile",3+int(float(state.time)*6)%2 if walking else 2,feet,id == "arjun",lerpf(1,ship_scale*0.57,clampf((progress-0.45)/0.55,0,1)))
		var bag_progress: float = state.boarding.mei_ling if stage == 2 else 0.0
		var bag_at := Vector2(95,193).lerp(at+Vector2(55,81)*ship_scale,bag_progress)
		if stage == 2:
			bag_at = Vector2(95,193).lerp(state.feet.mei_ling+Vector2(-11,-6),clampf(bag_progress*6,0,1))
			bag_at = bag_at.lerp(at+Vector2(55,81)*ship_scale,clampf((bag_progress-0.9)*10,0,1))
		if stage == 0: bag_at.y -= sin(float(state.bag)*PI)*7
		_bag(canvas,bag_at,lerpf(1,0.6,bag_progress))
	elif stage <= 6:
		for id in ["mei_ling","arjun","adam"]:
			_actor(canvas,id,"smile",2,at+DECK[id]*ship_scale,false,ship_scale*0.57)
	if stage >= 2:
		if not pet_id.is_empty() and is_instance_valid(_companion):
			var pet_progress: float = state.boarding.adam
			var pet_at: Vector2 = state.feet.adam+Vector2(18,-2)
			if stage >= 3: pet_at = at+Vector2(173,81)*ship_scale
			var pet_size := Vector2(19,17)*lerpf(1,ship_scale*0.7,pet_progress)
			canvas.draw_texture_rect(_companion,Rect2(pet_at-Vector2(pet_size.x/2,pet_size.y),pet_size),false)
		# Redraw the near hull after people so feet sit behind the gunwale.
		canvas.draw_texture_rect_region(_ship,Rect2(at+Vector2(0,84)*ship_scale,Vector2(208,28)*ship_scale),Rect2(0,84,208,28),Color("#b3c4ce") if state.night else Color.WHITE)
	if stage == 6:
		canvas.draw_rect(Rect2(0,0,480,224),Color(0.025,0.07,0.10,0.5))
		canvas.draw_line(Vector2(164,116),Vector2(316,116),GameUI.GOLD,1)
		canvas.draw_string(ThemeDB.fallback_font,Vector2(120,146),"PB · PROTECT BESUT",HORIZONTAL_ALIGNMENT_CENTER,240,20,GameUI.GOLD)
		canvas.draw_string(ThemeDB.fallback_font,Vector2(65,174),"Together, wherever the tide leads.",HORIZONTAL_ALIGNMENT_CENTER,350,16,Color("#e7e6cf"))
		canvas.draw_string(ThemeDB.fallback_font,Vector2(100,200),"Adam · Arjun · Mei Ling",HORIZONTAL_ALIGNMENT_CENTER,280,12,Color("#b6ccca"))
	# A short dissolve softens every shot change without altering world time.
	var veil := 1.0-_ease(float(state.time),0,0.35)
	if state.reduced: veil = 0
	if veil > 0: canvas.draw_rect(Rect2(0,0,480,224),Color(0.06,0.14,0.18,veil))
	canvas.draw_set_transform(Vector2.ZERO)

func _actor(canvas: CanvasItem, id: String, mood: String, posture: int, feet: Vector2, left: bool, scale: float) -> void:
	canvas.draw_rect(Rect2(feet+Vector2(-10,-1)*scale,Vector2(20,2)*scale),Color(0.1,0.17,0.18,0.3))
	canvas.draw_texture_rect(_actors["%s/%s/%d/%s" % [id,mood,posture,left]],Rect2(feet-Vector2(24,60)*scale,Vector2(48,60)*scale),false)

func _bag(canvas: CanvasItem, at: Vector2, scale: float) -> void:
	canvas.draw_rect(Rect2(at+Vector2(-7,-12)*scale,Vector2(14,12)*scale),Color("#b89b69"))
	canvas.draw_line(at+Vector2(-4,-13)*scale,at+Vector2(4,-13)*scale,Color("#ead5a2"),2*scale)
	canvas.draw_rect(Rect2(at+Vector2(-1,-10)*scale,Vector2(3,8)*scale),Color("#6a5341"))

func _draw_water(canvas: CanvasItem, state: Dictionary) -> void:
	if not state.detail: return
	for i in 18:
		var x := float(posmod(i*71,470))
		var y := 111.0+posmod(i*17,99)
		if int(state.stage) < 5 and x < 300 and y > 170: continue
		var drift: float = 0 if state.reduced else roundf(sin(float(state.time)*0.8+i)*3)
		canvas.draw_line(Vector2(x+drift,y),Vector2(x+drift+8+i%5,y),Color(0.72,0.85,0.80,0.28),1)
