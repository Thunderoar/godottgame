class_name ReunionRenderer
extends RefCounted
## Finite dock gestures and one deterministic, continuous 17-second departure.
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

static func sample(page: int, elapsed: float, reduced: bool, quality: String, night: bool) -> Dictionary:
	var film := page >= ReunionDialogueDB.film_page()
	var card := page == ReunionDialogueDB.final_page()
	var t := clampf(elapsed,0,ReunionDialogueDB.FILM_SECONDS) if film else maxf(0,elapsed)
	if card: t = ReunionDialogueDB.FILM_SECONDS
	var stage := ReunionDialogueDB.shot_at(t) if film else -1
	var exchange := ReunionDialogueDB.exchange(page)
	var row_index := mini(2,int(t/1.8))
	var row: Dictionary = exchange[row_index] if not exchange.is_empty() else ReunionDialogueDB.turn(8)
	var ship_at := Vector2(230,31)
	var ship_scale := 1.25
	if film:
		var leave := _ease(t,6.7,13)
		var horizon := _ease(t,13,17)
		ship_at += Vector2(70,10)*leave+Vector2(55,15)*horizon
		ship_scale = lerpf(1.25,0.65,leave)-0.20*horizon
	var boarded := 0
	var boarding: Dictionary = {}
	var feet: Dictionary = {}
	for i in 3:
		var id: String = ["mei_ling","arjun","adam"][i]
		var progress := _ease(t,i*1.7,i*1.7+2.0) if film else 0.0
		if progress >= 1: boarded += 1
		boarding[id] = progress
		feet[id] = boarding_position(id,progress,ship_at,ship_scale)
	var bag_at: Vector2 = HOMES.arjun+Vector2(-17,-4)
	var bag_scale := 1.0
	var wobble := 0.0
	var steady := false
	if film:
		bag_scale = lerpf(1,ship_scale*0.57,float(boarding.arjun))
		bag_at = feet.arjun+Vector2(-12,-4)*bag_scale
		wobble = sin(clampf((t-3.0)/0.9,0,1)*TAU)*4 if not reduced and t < 3.9 else 0.0
		steady = t >= 3.2 and t < 3.9
		var stow := _ease(t,5.5,6.2)
		bag_at = bag_at.lerp(ship_at+Vector2(103,82)*ship_scale,stow)
	elif page == ReunionDialogueDB.exchange_page("captain_snacks"):
		bag_at.y -= 7*_ease(t,0,0.65)
	return {"stage":stage,"beat":page,"speaker":str(row.speaker),"mood":str(row.mood),"time":t,
		"film":film,"card":card,"night":night,"detail":quality != "low","reduced":reduced,
		"ship_at":ship_at,"ship_scale":ship_scale,"boarding":boarding,"feet":feet,"boarded":boarded,
		"rope_released":film and t >= 6.5,"bag_at":bag_at,"bag_scale":bag_scale,"bag_wobble":wobble,"steady":steady,
		"sea_blend":_ease(t,13,14.2) if film else 0.0,"card_time":maxf(0,elapsed) if card else 0.0,
		"zoom":1.1 if not film else 1.0}

func draw(canvas: CanvasItem, available: Rect2, state: Dictionary, pet_id: String = "") -> void:
	var fitted := OpeningCaptureRenderer.fit_rect(available)
	canvas.draw_set_transform(Vector2.ZERO)
	canvas.draw_rect(available,Color("#172830"))
	var zoom: float = state.zoom
	var offset := (Vector2(240,112)-Vector2(210,137)*zoom).clamp(Vector2(480,224)*(1-zoom),Vector2.ZERO) if zoom > 1 else Vector2.ZERO
	var factor := fitted.size.x/480.0
	canvas.draw_set_transform(fitted.position+offset*factor,0,Vector2.ONE*factor*zoom)
	var t: float = state.time
	var film: bool = state.film
	var sea: float = state.sea_blend
	canvas.draw_texture(_dock[1 if state.night else 0],Vector2.ZERO)
	if sea > 0: canvas.draw_texture(_sea[1 if state.night else 0],Vector2.ZERO,Color(1,1,1,sea))
	_draw_water(canvas,state)
	if film and sea < 1:
		var tint := Color(1,1,1,1-sea)
		canvas.draw_texture_rect(_rahim,Rect2(21,127,35,48),false,tint)
		canvas.draw_texture_rect(_villager,Rect2(61,136,31,40),false,tint)
		canvas.draw_texture_rect(_villager,Rect2(96,140,28,36),false,Color(0.77,0.82,0.69,1-sea))
		var wave := 0.0 if state.reduced else sin(t*3)*3
		canvas.draw_line(Vector2(48,147),Vector2(54,135+wave),Color(0.86,0.66,0.5,1-sea),3)
		canvas.draw_line(Vector2(85,153),Vector2(92,141-wave),Color(0.86,0.66,0.5,1-sea),2)
	var at: Vector2 = state.ship_at
	var ship_scale: float = state.ship_scale
	if film and t > 6.7 and state.detail:
		for i in 3:
			var wake := at+Vector2(19-i*13,104+i*2)*ship_scale
			canvas.draw_line(wake,wake+Vector2(22,0)*ship_scale,Color(0.84,0.91,0.8,0.45-i*0.1),ship_scale)
	canvas.draw_texture_rect(_ship,Rect2(at,_ship.get_size()*ship_scale),false,Color("#b3c4ce") if state.night else Color.WHITE)
	if film and t < 6.5:
		var top := at+Vector2(51,82)*ship_scale
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(268,191),Vector2(284,191),top+Vector2(8,0),top-Vector2(8,0)]),Color("#b49564"))
		for i in 9:
			var board := Vector2(276,189).lerp(top,float(i)/8)
			canvas.draw_line(board-Vector2(7,0),board+Vector2(7,0),Color("#705b43"),1)
	if not state.rope_released:
		canvas.draw_line(Vector2(283,171),at+Vector2(45,84)*ship_scale,Color("#d1ba87"),2)
	else:
		canvas.draw_arc(at+Vector2(49,83)*ship_scale,4*ship_scale,0,TAU,16,Color("#d1ba87"),ship_scale)
	for id in ["mei_ling","arjun","adam"]:
		var feet: Vector2 = state.feet[id]
		var mood := "smile"
		var posture := 2
		var scale := 1.0
		if film:
			var progress: float = state.boarding[id]
			var walking: bool = progress > 0 and progress < 1 and not state.reduced
			posture = 3+int(t*6)%2 if walking else 2
			scale = lerpf(1,ship_scale*0.57,clampf((progress-0.45)/0.55,0,1))
			if id == "arjun" and t >= 3 and t < 3.9: mood = "salute"
			if id == "mei_ling" and state.steady: mood = "steady"
			if id == "adam" and t >= 9 and t < 12.5: mood = "wave"
		else:
			# Finite gestures settle into listening smiles during long reading pauses.
			if state.speaker == id: mood = state.mood
			if state.beat == 1 and id == "mei_ling" and t >= 1.8 and t < 3.6: mood = "salute"
			if t >= 5.6 and mood in ["salute","wave"]: mood = "smile"
		_actor(canvas,id,mood,posture,feet,id == "arjun" and not film,scale)
	var bag_at: Vector2 = state.bag_at
	bag_at.x += float(state.bag_wobble)
	_bag(canvas,bag_at,float(state.bag_scale),(not film and state.beat >= 1) or (film and t < 5.5))
	if state.steady:
		# Mei's helping hand reaches the wobbling bag; no falling food or reward drops.
		var hand: Vector2 = state.feet.mei_ling+Vector2(13,-19)*ship_scale*0.57
		canvas.draw_line(hand,bag_at+Vector2(0,-5),Color("#4e7667"),3*ship_scale*0.57)
		canvas.draw_circle(bag_at+Vector2(0,-5),1.7*ship_scale*0.57,Color("#e2b58a"))
	if film:
		if not pet_id.is_empty() and is_instance_valid(_companion):
			var pet_progress: float = state.boarding.adam
			var pet_at: Vector2 = state.feet.adam+Vector2(18,-2).lerp(Vector2(20,-2)*ship_scale,pet_progress)
			var pet_size := Vector2(19,17)*lerpf(1,ship_scale*0.7,pet_progress)
			canvas.draw_texture_rect(_companion,Rect2(pet_at-Vector2(pet_size.x/2,pet_size.y),pet_size),false)
		# People and supplies sit behind the near gunwale.
		canvas.draw_texture_rect_region(_ship,Rect2(at+Vector2(0,84)*ship_scale,Vector2(208,28)*ship_scale),Rect2(0,84,208,28),Color("#b3c4ce") if state.night else Color.WHITE)
	if state.card:
		canvas.draw_rect(Rect2(0,0,480,224),Color(0.025,0.07,0.10,0.65))
		canvas.draw_line(Vector2(164,97),Vector2(316,97),GameUI.GOLD,1)
		canvas.draw_string(ThemeDB.fallback_font,Vector2(120,125),"PB · PROTECT BESUT",HORIZONTAL_ALIGNMENT_CENTER,240,20,GameUI.GOLD)
		canvas.draw_string(ThemeDB.fallback_font,Vector2(65,156),ReunionDialogueDB.DOCK_TEXT,HORIZONTAL_ALIGNMENT_CENTER,350,16,Color("#e7e6cf"))
		canvas.draw_string(ThemeDB.fallback_font,Vector2(100,185),"Adam · Arjun · Mei Ling",HORIZONTAL_ALIGNMENT_CENTER,280,12,Color("#b6ccca"))
	elif film and t > 16.25 and not state.reduced:
		canvas.draw_rect(Rect2(0,0,480,224),Color(0.025,0.07,0.10,_ease(t,16.25,17)*0.65))
	canvas.draw_set_transform(Vector2.ZERO)

func _actor(canvas: CanvasItem, id: String, mood: String, posture: int, feet: Vector2, left: bool, scale: float) -> void:
	canvas.draw_rect(Rect2(feet+Vector2(-10,-1)*scale,Vector2(20,2)*scale),Color(0.1,0.17,0.18,0.3))
	canvas.draw_texture_rect(_actors["%s/%s/%d/%s" % [id,mood,posture,left]],Rect2(feet-Vector2(24,60)*scale,Vector2(48,60)*scale),false)

func _bag(canvas: CanvasItem, at: Vector2, scale: float, open: bool = false) -> void:
	canvas.draw_rect(Rect2(at+Vector2(-9,-15)*scale,Vector2(18,15)*scale),Color("#b89b69"))
	canvas.draw_line(at+Vector2(-5,-17)*scale,at+Vector2(5,-17)*scale,Color("#ead5a2"),2*scale)
	canvas.draw_rect(Rect2(at+Vector2(-1,-13)*scale,Vector2(3,11)*scale),Color("#6a5341"))
	if open:
		# Three distinct leaf-wrapped lunches, with pale string ties.
		for i in 3:
			var lunch := at+Vector2(-7+i*6,-18-(3 if i == 1 else 0))*scale
			canvas.draw_rect(Rect2(lunch,Vector2(5,7)*scale),Color("#729b60"))
			canvas.draw_line(lunch+Vector2(2,0)*scale,lunch+Vector2(2,7)*scale,Color("#f4db9c"),scale)

func _draw_water(canvas: CanvasItem, state: Dictionary) -> void:
	if not state.detail: return
	for i in 18:
		var x := float(posmod(i*71,470))
		var y := 111.0+posmod(i*17,99)
		if float(state.sea_blend) < 0.8 and x < 300 and y > 170: continue
		var drift: float = 0 if state.reduced else roundf(sin(float(state.time)*0.8+i)*3)
		canvas.draw_line(Vector2(x+drift,y),Vector2(x+drift+8+i%5,y),Color(0.72,0.85,0.80,0.28),1)
