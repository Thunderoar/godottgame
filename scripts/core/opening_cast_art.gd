class_name OpeningCastArt
extends RefCounted
## Finite cutscene-only sprite frames. Shared fishing/combat images are never edited.
## Private bounded cache avoids evicting PixelArt's world-art cache.
static var FRAMES: Dictionary = {}
const ACTIONS := 6
const MOUTHS := 4

static func key(action: int, mouth: int, blink: bool, gaze: int) -> int:
	return (((clampi(action,0,5)*4+clampi(mouth,0,3))*2+int(blink))*3+clampi(gaze,0,2))

static func frame(id: String, action: int, mouth: int, blink: bool, gaze: int) -> Texture2D:
	var cache_key := "%s/%d" % [id,key(action,mouth,blink,gaze)]
	if FRAMES.has(cache_key): return FRAMES[cache_key]
	var gesture := 0 if action == 5 else action
	var c := CharacterDB.get_character(id)
	var skin: Color = c.tint
	var tunic: Color = Color("#4e7667") if id == "mei_ling" else c.accent
	var outline := Color("#34474a")
	var base := OpeningFishingArt.hero(id,0).get_image()
	var img := PixelArt.image(32,48)
	var seated := id == "mei_ling"
	var torso := 30 if seated else 25
	var leg_y := 38 if seated else 36
	img.blit_rect(base,Rect2i(0,leg_y,32,48-leg_y),Vector2i(0,leg_y))
	PixelArt.rect(img,9,torso-1,17,10 if seated else 14,outline)
	PixelArt.rect(img,10,torso,15,8 if seated else 12,tunic.darkened(0.12))
	PixelArt.rect(img,11,torso,5,7 if seated else 10,tunic.lightened(0.14))
	PixelArt.hline(img,10,torso+(6 if seated else 10),15,Color("#63503b"))
	PixelArt.rect(img,17,torso+(5 if seated else 9),3,2,Color("#deb96c"))
	PixelArt.hline(img,12,torso,10,tunic.lightened(0.35))
	var left := Vector2i(8,36)
	var right := Vector2i(24,36)
	var left_elbow := Vector2i(8,32)
	var right_elbow := Vector2i(25,32)
	if id == "adam":
		var hands := [[Vector2i(8,36),Vector2i(24,36)],[Vector2i(10,35),Vector2i(21,34)],[Vector2i(16,31),Vector2i(22,33)],[Vector2i(12,38),Vector2i(21,37)],[Vector2i(9,38),Vector2i(23,36)]]
		left = hands[gesture][0]; right = hands[gesture][1]
		left_elbow = Vector2i(8,31) if gesture != 2 else Vector2i(10,30)
		var coil := Vector2i(8,40) if gesture == 0 or gesture == 4 else (Vector2i(17,32) if gesture == 2 else Vector2i(16,36 if gesture == 1 else 39))
		if action != 5:
			for row in 3:
				var loop := [Vector2i(-6,0),Vector2i(-4,-2),Vector2i(0,-3),Vector2i(4,-2),Vector2i(6,0),Vector2i(4,2),Vector2i(0,3),Vector2i(-4,2),Vector2i(-6,0)]
				for segment in loop.size()-1:
					var a: Vector2i = coil+loop[segment]-Vector2i(0,row)
					var b: Vector2i = coil+loop[segment+1]-Vector2i(0,row)
					PixelArt.line(img,a.x,a.y,b.x,b.y,Color("#d8bd85") if row != 1 else Color("#9f8255"))
			PixelArt.line(img,coil.x-5,coil.y+1,6,47,Color("#a78c5d"))
	elif id == "arjun":
		right = Vector2i(OpeningCastPerformance.right_wrist(gesture))
		left = [Vector2i(22,33),Vector2i(22,31),Vector2i(24,29),Vector2i(25,32),Vector2i(22,34)][gesture]
		left_elbow = Vector2i(17,34)
		right_elbow = Vector2i(25,29)
	else:
		left = Vector2i(11,38)
		right = [Vector2i(22,38),Vector2i(23,33),Vector2i(19,34),Vector2i(23,38),Vector2i(26,29)][gesture]
		left_elbow = Vector2i(9,35)
		right_elbow = Vector2i(26,34) if gesture != 4 else Vector2i(27,33)
		var paper_y := 31 if gesture in [1,2] else 36
		if action != 5:
			PixelArt.rect(img,10,paper_y,15,7,Color("#655e4a"))
			PixelArt.rect(img,11,paper_y,13,6,Color("#ecd9a5"))
			PixelArt.vline(img,17,paper_y,6,Color("#b99868"))
			PixelArt.line(img,12,paper_y+3,15,paper_y+1,Color("#668887"))
			PixelArt.line(img,19,paper_y+4,22,paper_y+2,Color("#668887"))
			PixelArt.px(img,21,paper_y+3,Color("#b97759"))
	_arm(img,Vector2i(11,torso+2),left_elbow,left,tunic,skin)
	_arm(img,Vector2i(23,torso+2),right_elbow,right,tunic,skin)
	# Preserve the original character identity/head pixels, then change only face marks.
	var head_y := 21 if seated else 16
	var nod := 1 if id != "arjun" and gesture in [1,2] else 0
	img.blit_rect(base,Rect2i(0,0,32,head_y+10),Vector2i(0,nod))
	head_y += nod
	PixelArt.px(img,20,head_y,skin)
	PixelArt.hline(img,18,head_y-1,3,outline)
	if blink:
		PixelArt.hline(img,18,head_y,3,outline)
	else:
		PixelArt.px(img,19 if gaze == 1 else 20,head_y+(1 if gaze == 2 else 0),Color("#f6e6be"))
	var lip_y := head_y+5 if id == "arjun" else head_y+4
	if mouth == 1:
		PixelArt.hline(img,19,lip_y,3,Color("#5a3936"))
	elif mouth == 2:
		PixelArt.rect(img,19,lip_y-1,3,3,Color("#533536"))
		PixelArt.hline(img,20,lip_y+1,2,Color("#c6887a"))
	elif mouth == 3:
		PixelArt.hline(img,18,lip_y,4,Color("#8f584c"))
		PixelArt.px(img,22,lip_y-1,Color("#8f584c"))
	var texture := PixelArt.texture(img)
	FRAMES[cache_key] = texture
	return texture

static func _arm(img: Image, shoulder: Vector2i, elbow: Vector2i, wrist: Vector2i, cloth: Color, skin: Color) -> void:
	PixelArt.line(img,shoulder.x-1,shoulder.y,elbow.x-1,elbow.y,Color("#34474a"))
	PixelArt.line(img,shoulder.x,shoulder.y,elbow.x,elbow.y,cloth.lightened(0.15))
	PixelArt.line(img,shoulder.x+1,shoulder.y,elbow.x+1,elbow.y,cloth)
	PixelArt.line(img,elbow.x,elbow.y,wrist.x,wrist.y,skin.darkened(0.08))
	PixelArt.rect(img,wrist.x-1,wrist.y-1,3,3,skin)
