class_name ReunionArt
extends RefCounted
## Finite original pixels; courtyard, listening poses and a moored dock epilogue.
const MOODS := ["soft", "smile", "neck", "down", "cup", "resolved", "proud", "salute", "wave", "steady"]

static func courtyard(night: bool) -> Texture2D:
	return PixelArt.cached_texture("reunion/courtyard/%s/v1" % night, func() -> Image:
		var img := PixelArt.image(480,224)
		img.fill(Color("#243447") if night else Color("#c4d1bb"))
		for i in 7:
			PixelArt.ellipse(img,i*82,112,62,69,Color("#354d4c") if night else Color("#66836b"))
			PixelArt.ellipse(img,i*82+24,121,45,48,Color("#425c52") if night else Color("#8b9b70"))
		PixelArt.rect(img,0,149,480,75,Color("#3b5146") if night else Color("#799064"))
		PixelArt._fill_polygon(img,[Vector2i(118,160),Vector2i(331,151),Vector2i(480,194),Vector2i(480,224),Vector2i(60,224)],Color("#756c59") if night else Color("#c9b68a"))
		# Adam's cottage and its warm open doorway ground the gathering in BESUT.
		PixelArt.rect(img,118,53,200,103,Color("#61523f") if night else Color("#8e704b"))
		for y in range(58,155,7): PixelArt.hline(img,122,y,192,Color("#9b7e52"))
		PixelArt._fill_polygon(img,[Vector2i(101,59),Vector2i(148,17),Vector2i(285,17),Vector2i(335,59)],Color("#31463f"))
		for y in range(24,58,6): PixelArt.hline(img,148-(y-24),y,137+(y-24)*2,Color("#768366"))
		for x in [142,266]:
			PixelArt.rect(img,x,79,27,31,Color("#3d4238"))
			PixelArt.rect(img,x+2,81,23,27,Color("#ecc888"))
			PixelArt.vline(img,x+13,81,27,Color("#8a744d"))
			PixelArt.hline(img,x+2,93,23,Color("#8a744d"))
		PixelArt.rect(img,201,92,36,64,Color("#293c3e"))
		PixelArt.rect(img,200,152,40,4,Color("#d6bd87"))
		for y in [155,160]: PixelArt.rect(img,111-(y-155),y,215+(y-155)*2,4,Color("#ad946c"))
		# A village garden and the coastal path stay secondary to the listeners.
		for x in [358,381,404,427,450]:
			PixelArt.rect(img,x,123,4,34,Color("#aa9061"))
		for y in [131,144]: PixelArt.hline(img,353,y,110,Color("#aa9061"))
		for i in 18:
			var x := 350 + posmod(i*31,115)
			var y := 160 + posmod(i*13,24)
			PixelArt.rect(img,x,y,2,3,Color("#a6b77c"))
			PixelArt.rect(img,x-1,y-2,4,2,Color("#c7a2a2") if i%2 else Color("#d9bf7b"))
		for i in 35: PixelArt.rect(img,posmod(i*53,470),205+i%17,3,1,Color("#8f9570"))
		return img)

static func actor(id: String, mood: String, posture: int, left: bool) -> Texture2D:
	return PixelArt.cached_texture("reunion/actor/%s/%s/%d/%s/v3" % [id,mood,posture,left],func() -> Image:
		var img := PixelArt.image(48,60)
		var pose := MeiLingRescueArt.Pose.IDLE
		if posture >= 3: pose = MeiLingRescueArt.Pose.WALK_A if posture == 3 else MeiLingRescueArt.Pose.WALK_B
		var base := MeiLingRescueArt.hero(id,pose).get_image()
		var offset := 14-mini(posture,2)*3
		img.blit_rect(base,Rect2i(0,0,48,52 if posture >= 2 else 42),Vector2i(0,offset))
		if posture < 2:
			PixelArt.rect(img,18,52,19,4,Color("#30424a"))
			for x in [18,31]:
				PixelArt.rect(img,x,54,5,5,Color("#30424a"))
				PixelArt.rect(img,x-2,58,9,2,Color("#594938"))
		var c := CharacterDB.get_character(id)
		var shirt: Color = Color("#4e7667") if id == "mei_ling" else c.accent
		if mood in ["cup","neck","resolved","proud","salute","wave","steady"]:
			PixelArt.rect(img,31,31+offset,12,14,Color.TRANSPARENT)
			var hand := Vector2i(38,31+offset)
			if mood in ["neck","salute"]: hand = Vector2i(34,20+offset)
			if mood == "wave": hand = Vector2i(42,17+offset)
			if mood == "proud": hand = Vector2i(40,34+offset)
			if mood == "steady": hand = Vector2i(46,30+offset)
			PixelArt.line(img,32,32+offset,hand.x,hand.y,shirt.lightened(0.18))
			PixelArt.line(img,33,33+offset,hand.x+1,hand.y+1,shirt)
			PixelArt.rect(img,hand.x-1,hand.y,4,3,c.tint)
			if mood == "cup":
				PixelArt.rect(img,hand.x-2,hand.y-5,6,8,Color("#81a8a1"))
				PixelArt.rect(img,hand.x-1,hand.y-7,4,2,Color("#d6bd87"))
		if mood in ["smile","proud","salute","wave","steady"]:
			PixelArt.hline(img,27,24+offset,4,c.tint)
			PixelArt.hline(img,27,25+offset,3,Color("#855744"))
		if mood == "down":
			PixelArt.hline(img,26,19+offset,4,c.tint)
			PixelArt.hline(img,26,21+offset,3,Color("#344149"))
		if left: img.flip_x()
		return img)

static func table() -> Texture2D:
	return PixelArt.cached_texture("reunion/table/v1",func() -> Image:
		var img := PixelArt.image(88,42)
		for x in [12,67]: PixelArt.rect(img,x,13,6,29,Color("#65513d"))
		PixelArt.rect(img,0,8,88,13,Color("#6f563e"))
		PixelArt.rect(img,1,2,86,13,Color("#b69362"))
		for y in [5,10]: PixelArt.hline(img,2,y,84,Color("#d1af77"))
		for x in [15,39,66]:
			PixelArt.rect(img,x,0,6,6,Color("#e2d2ab"))
			PixelArt.hline(img,x,0,6,Color("#fff1ca"))
		return img)

static func dock(night: bool) -> Texture2D:
	return PixelArt.cached_texture("reunion/dock/%s/v1" % night,func() -> Image:
		var img := PixelArt.image(480,224)
		img.fill(Color("#273c52") if night else Color("#b8d0c3"))
		PixelArt._fill_polygon(img,[Vector2i(0,74),Vector2i(51,42),Vector2i(100,58),Vector2i(147,37),Vector2i(211,81),Vector2i(480,88),Vector2i(480,111),Vector2i(0,111)],Color("#3c5d58") if night else Color("#719382"))
		PixelArt.rect(img,0,96,480,128,Color("#244754") if night else Color("#4b8588"))
		for i in 54: PixelArt.hline(img,posmod(i*71,475),101+posmod(i*19,119),4+i%9,Color("#557f86") if night else Color("#8fb4a7"))
		PixelArt.rect(img,0,180,325,44,Color("#604e3d"))
		for y in range(173,224,8):
			PixelArt.rect(img,0,y,325,6,Color("#ad8f60") if not night else Color("#8e7959"))
			for x in range(8,325,24): PixelArt.px(img,x,y+2,Color("#574c3d"))
		for x in [16,70,290]:
			PixelArt.rect(img,x,164,7,59,Color("#66533e"))
			PixelArt.rect(img,x-2,162,11,5,Color("#d6b17a"))
		PixelArt.rect(img,81,177,32,28,Color("#937147"))
		for y in [180,192]: PixelArt.hline(img,83,y,28,Color("#c6a16b"))
		PixelArt.line(img,83,179,110,203,Color("#d0ac75"))
		return img)

static func departure_backdrop(night: bool, open_sea: bool) -> Texture2D:
	return PixelArt.cached_texture("reunion/departure/%s/%s/v1" % [night,open_sea],func() -> Image:
		var img := PixelArt.image(480,224)
		var sky: Array = ["#182b43","#223c53","#345467","#54717a"] if night else ["#93b9bc","#abc9c1","#c8d8bf","#e5ddbc"]
		for i in 4: PixelArt.rect(img,0,i*25,480,25,Color(sky[i]))
		if night:
			for i in 22: PixelArt.px(img,16+posmod(i*83,450),8+posmod(i*19,60),Color("#d9e2cc"))
			PixelArt.ellipse(img,395,31,12,12,Color("#ece1b8"))
		else:
			PixelArt.ellipse(img,395,64,19,18,Color("#f6e8bc"))
			for x in [32,168,282]:
				PixelArt.ellipse(img,x,24,34,5,Color("#dbe5d5"))
				PixelArt.ellipse(img,x+21,21,23,6,Color("#dbe5d5"))
		PixelArt.rect(img,0,100,480,124,Color("#224553") if night else Color("#4c898a"))
		PixelArt.hline(img,0,100,480,Color("#8da7a1"))
		for i in 76:
			var y := 103+posmod(i*17,119)
			PixelArt.hline(img,posmod(i*67,478),y,3+i%12,Color("#386374") if night else Color("#76aaa3"))
		if open_sea: return img
		PixelArt._fill_polygon(img,[Vector2i(0,71),Vector2i(38,43),Vector2i(75,66),Vector2i(112,47),Vector2i(179,81),Vector2i(210,101),Vector2i(0,122)],Color("#35574e") if night else Color("#688c6a"))
		PixelArt._fill_polygon(img,[Vector2i(0,122),Vector2i(91,112),Vector2i(153,141),Vector2i(184,181),Vector2i(0,210)],Color("#82795e") if night else Color("#c3b38a"))
		# Small warm BESUT homes remain visible behind the farewell party.
		for x in [11,73]:
			PixelArt.rect(img,x,89,37,32,Color("#786044"))
			PixelArt._fill_polygon(img,[Vector2i(x-5,91),Vector2i(x+18,69),Vector2i(x+43,91)],Color("#3a5449"))
			PixelArt.rect(img,x+13,102,9,19,Color("#e9cd8a"))
		# Timber jetty, alternating board lengths, nails and rails.
		PixelArt.rect(img,0,181,302,43,Color("#564838"))
		for y in range(176,224,7):
			PixelArt.rect(img,0,y,302,5,Color("#8a7757") if night else Color("#b59866"))
			PixelArt.hline(img,0,y,302,Color("#c2a778") if not night else Color("#a18f6c"))
			for x in range(8,302,38): PixelArt.px(img,x+(y%3)*4,y+2,Color("#65513b"))
		for x in [10,72,283]:
			PixelArt.rect(img,x,162,6,62,Color("#66523e"))
			PixelArt.rect(img,x-2,160,10,4,Color("#cfad76"))
		PixelArt.rect(img,82,178,28,26,Color("#896641"))
		PixelArt.line(img,84,180,107,200,Color("#d1ad72"))
		for y in [181,200]: PixelArt.hline(img,83,y,26,Color("#c8a16b"))
		# A steady lantern remains readable at low effects and at night.
		PixelArt.rect(img,31,105,3,70,Color("#5a4b39"))
		PixelArt.rect(img,25,110,15,19,Color("#423e36"))
		PixelArt.rect(img,28,113,9,12,Color("#ffdc8c"))
		PixelArt.hline(img,28,119,9,Color("#a38351"))
		return img)
