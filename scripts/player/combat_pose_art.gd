class_name CombatPoseArt
extends RefCounted
## Four hand-authored keys × three combo steps × four logical facings. Pixel
## art uses PixelArt's existing body; illustrated art deforms a COPY of its own
## source silhouette. Dedicated stable keys bypass the old frame-blind resolver.
static var _cache: Dictionary = {}

static func texture(hero: String, facing: int, step: int, key: int) -> Texture2D:
	step = posmod(step,3)
	key = clampi(key,0,3)
	var id := "combat_pose/%s/%d/%d/%d/%s/%d" % [hero,facing,step,key,"pixel" if VisualStyle.is_pixel() else "illustrated",WorldPalette.generation]
	var override := AssetRegistry.get_texture(id)
	if override != null: return override
	if _cache.has(id): return _cache[id]
	var img: Image
	if VisualStyle.is_pixel():
		img = PixelArt.character_texture(hero,facing,7+step*4+key).get_image().duplicate()
	else:
		# Never recolor/resize shared imported images. Logical dimensions and feet
		# remain 32×48 while the illustrated silhouette keeps a denser canvas.
		var src := PixelArt.character_texture(hero,facing,4).get_image().duplicate() as Image
		src.resize(64,96,Image.INTERPOLATE_LANCZOS)
		img = PixelArt.image(64,96)
		var lean: int = int([-1,2,3,1][key]) * (1 if facing != 1 else -1)
		for y in 96:
			var torso := clampf((88.0-y)/38.0,0,1) if y > 38 else 1.0
			var shift := roundi(float(lean)*torso) if facing == 2 else 0
			for x in 64:
				var target := x+shift
				if target >= 0 and target < 64: img.set_pixel(target,y,src.get_pixel(x,y))
		draw_weapon(img,hero,facing,step,key)
	var result := ImageTexture.create_from_image(img)
	result.set_size_override(Vector2i(32,48))
	result.set_meta("combat_pose",Vector3i(facing,step,key))
	if _cache.size() >= 144: _cache.clear()
	_cache[id] = result
	return result

static func draw_weapon(img: Image, hero: String, facing: int, step: int, key: int) -> void:
	var scale := float(img.get_width())/32.0
	var definition := CharacterDB.get_character(hero)
	var skin: Color = definition.get("tint",Color("#e8c7a3"))
	var sleeve := Color("#3f7f72") if hero == "adam" else (Color("#7a3f2b") if hero == "arjun" else Color("#4e7667"))
	var shoulder := Vector2(20,28) if facing == 2 else Vector2(17,28)
	var hand: Vector2
	var tip: Vector2
	# Screen-plane keys deliberately differ: load/contact/overshoot/return.
	if facing == 2:
		hand = [Vector2(16,25),Vector2(25,30),Vector2(26,33),Vector2(21,32)][key]
		tip = [Vector2(10,14),Vector2(31,20),Vector2(30,41),Vector2(27,24)][key]
		if step == 1: tip.y = 58-tip.y
		if step == 2:
			hand = [Vector2(18,31),Vector2(25,29),Vector2(26,29),Vector2(22,31)][key]
			tip = [Vector2(12,29),Vector2(31,29),Vector2(31,28),Vector2(28,29)][key]
	else:
		var down := facing == 0
		hand = [Vector2(12,25),Vector2(22,32),Vector2(23,35),Vector2(18,31)][key]
		tip = [Vector2(6,17),Vector2(29,39),Vector2(26,45),Vector2(25,32)][key]
		if step == 1:
			hand.x = 32-hand.x
			tip.x = 32-tip.x
		if step == 2:
			hand = Vector2(16,[26,33,35,30][key])
			tip = Vector2(16,[19,45,47,37][key])
		if not down:
			hand.y = 56-hand.y
			tip.y = 56-tip.y
	var elbow := shoulder.lerp(hand,0.6)+Vector2(-2,2)
	_stroke(img,shoulder,elbow,PixelArt.OUTLINE,3,scale)
	_stroke(img,shoulder,elbow,sleeve,2,scale)
	_stroke(img,elbow,hand,skin,2,scale)
	var axis := (tip-hand).normalized()
	if hero == "mei_ling":
		_stroke(img,hand+Vector2(0,-7),hand+Vector2(4,0),Color("#a37849"),2,scale)
		_stroke(img,hand+Vector2(4,0),hand+Vector2(0,7),Color("#a37849"),2,scale)
		_stroke(img,hand+Vector2(0,-7),hand+Vector2(0,7),Color("#e9dfbd"),1,scale)
	else:
		_stroke(img,hand-axis*2,tip,PixelArt.OUTLINE,3,scale)
		_stroke(img,hand+axis*2,tip,Color("#f2f3db"),1,scale)
		var cross := axis.orthogonal()*3
		_stroke(img,hand+axis+cross,hand+axis-cross,Color("#d8ae69"),2,scale)
		if hero == "arjun": _stroke(img,tip,tip+axis.orthogonal()*6,Color("#d5e7dd"),2,scale)

static func _stroke(img: Image, a: Vector2, b: Vector2, color: Color, width: int, scale: float) -> void:
	var steps := maxi(1,ceili(a.distance_to(b)*scale))
	var size := maxi(1,roundi(width*scale))
	for i in steps+1:
		var at := a.lerp(b,float(i)/steps)*scale
		PixelArt.rect(img,roundi(at.x)-size/2,roundi(at.y)-size/2,size,size,color)
