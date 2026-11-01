class_name ArjunRescueRenderer
extends RefCounted
## One continuous twelve-second rescue. Page changes replace captions, not actors.
const PAGE_SECONDS := 6.0
const FRAME := Vector2(480,224)
var _ship: Texture2D
var _prison: Texture2D
var _heroes: Dictionary = {}

func _init() -> void:
	_ship = PixelArt.ship_texture()
	_prison = KrakenArt.prison_texture(true)
	for id in ["adam","arjun"]:
		for pose in MeiLingRescueArt.Pose.size():
			for left in [false,true]:
				_heroes["%s/%d/%s" % [id,pose,left]] = MeiLingRescueArt.hero(id,pose,left)

static func _ease(t: float, begin: float, end: float) -> float:
	var u := clampf((t-begin)/(end-begin),0,1)
	return u*u*(3.0-2.0*u)

static func sample(page: int, elapsed: float, reduced: bool) -> Dictionary:
	var t := clampf(float(page)*PAGE_SECONDS+elapsed,0,12)
	if reduced: t = 3.6 if page == 0 else 10.7
	var release := _ease(t,1.0,2.8)
	var walking := _ease(t,3.8,7.1)
	var aboard := _ease(t,7.1,8.5)
	var sail := _ease(t,8.8,12)
	var scale := lerpf(1.0,0.88,sail)
	var ship := Vector2(360,148).lerp(Vector2(493,135),sail)
	if not reduced: ship.y += sin(t*2.0)*0.55*sail
	var adam := Vector2(153,176).lerp(Vector2(281,176),walking).lerp(ship+Vector2(-26,19)*scale,aboard)
	var arjun := Vector2(94,168).lerp(Vector2(127,176),release).lerp(Vector2(263,176),walking).lerp(ship+Vector2(10,19)*scale,aboard)
	var steps := (t > 1 and t < 2.8) or (t > 3.8 and t < 8.5)
	var pose := MeiLingRescueArt.Pose.WALK_A if int(t*6)%2 == 0 else MeiLingRescueArt.Pose.WALK_B
	var reaching := t >= 2.8 and t < 3.8
	return {"time":t,"gate":_ease(t,0.2,1.1),"adam":adam,"arjun":arjun,"ship":ship,"ship_scale":scale,
		"adam_pose":MeiLingRescueArt.Pose.REACH if reaching else (pose if steps and not reduced else MeiLingRescueArt.Pose.IDLE),
		"arjun_pose":MeiLingRescueArt.Pose.REACH if reaching else (pose if steps and not reduced else MeiLingRescueArt.Pose.IDLE),
		"aboard":aboard,"sail":sail,"reduced":reduced,"rope":t < 8.65}

func draw(canvas: CanvasItem, available: Rect2, state: Dictionary) -> void:
	var fitted := OpeningCaptureRenderer.fit_rect(available)
	var factor := fitted.size.x/FRAME.x
	canvas.draw_set_transform(Vector2.ZERO)
	canvas.draw_rect(available,Color("#102733"))
	canvas.draw_set_transform(fitted.position,0,Vector2.ONE*factor)
	canvas.draw_rect(Rect2(Vector2.ZERO,FRAME),Color("#21485c"))
	canvas.draw_rect(Rect2(0,0,480,82),Color("#687b8e"))
	for i in 8:
		canvas.draw_line(Vector2(230,103+i*15),Vector2(480,103+i*15),Color("#3c6575"),1)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(0,83),Vector2(204,83),Vector2(239,141),Vector2(241,224),Vector2(0,224)]),Color("#575462"))
	for row in 4:
		for col in 7:
			canvas.draw_rect(Rect2(col*31+(14 if row%2 else 0),88+row*19,29,17),Color("#686575"))
	canvas.draw_rect(Rect2(0,173,245,51),Color("#918571"))
	canvas.draw_texture_rect(_prison,Rect2(57,77,76,91),false)
	canvas.draw_rect(Rect2(207,169,99,14),Color("#614b3b"))
	for x in range(209,303,12): canvas.draw_line(Vector2(x,170),Vector2(x,181),Color("#bba17c"),1)
	var ship: Vector2 = state.ship
	var scale: float = state.ship_scale
	canvas.draw_texture_rect(_ship,Rect2(ship-Vector2(114,70)*scale,Vector2(228,140)*scale),false)
	if state.rope: canvas.draw_line(Vector2(239,175),ship+Vector2(-69,21)*scale,Color("#d5b988"),1.5)
	_hero(canvas,"adam",int(state.adam_pose),state.adam,float(state.time)<3.8,lerpf(1.0,scale,float(state.aboard)))
	_hero(canvas,"arjun",int(state.arjun_pose),state.arjun,false,lerpf(1.0,scale,float(state.aboard)))
	# The gate lifts into its lintel before Arjun steps outside.
	var gate_bottom := 158.0-float(state.gate)*56
	if gate_bottom > 102:
		for x in range(71,125,10):
			canvas.draw_line(Vector2(x,102),Vector2(x,gate_bottom),Color("#b9c5c9"),2)
	# Near hull masks feet after boarding, keeping both friends on the deck.
	if float(state.aboard) > 0:
		var hull := Rect2(0,82,208,30)
		var origin := ship-Vector2(114,70)*scale
		canvas.draw_texture_rect_region(_ship,Rect2(origin+Vector2(0,82)*Vector2(228.0/208,140.0/128)*scale,Vector2(228,30*140.0/128)*scale),hull)
	canvas.draw_set_transform(Vector2.ZERO)

func _hero(canvas: CanvasItem, id: String, pose: int, feet: Vector2, left: bool, scale: float) -> void:
	canvas.draw_texture_rect(_heroes["%s/%d/%s" % [id,pose,left]],Rect2(feet-Vector2(24,52)*scale,Vector2(48,52)*scale),false)
