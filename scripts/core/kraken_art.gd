class_name KrakenArt
extends RefCounted
## Layered pixel art with the same outlines and lighting as portal creatures.
static func body_texture() -> Texture2D:
	return PixelArt.cached_texture("boss/kraken_king/v3",func() -> Image:
		var img := PixelArt.image(160,144)
		var ink := Color("#20243d")
		var purple := Color("#695082")
		for arm in 8:
			var start := Vector2(62+arm*5,84)
			var end := Vector2(10+arm*20,122+arm%2*11)
			for j in 36:
				var t := j/35.0
				var at := start.lerp(end,t)+Vector2(sin(t*5+arm)*8*t,-sin(t*PI)*9)
				var radius := roundi(lerpf(10,2,t))
				PixelArt.ellipse(img,int(at.x),int(at.y),radius+2,radius+2,ink)
				PixelArt.ellipse(img,int(at.x),int(at.y),radius,radius,purple)
				if j%5==0:
					PixelArt.ellipse(img,int(at.x),int(at.y)+3,3,2,Color("#c18da8"))
					PixelArt.px(img,int(at.x),int(at.y)+3,Color("#764867"))
		PixelArt.ellipse(img,80,56,40,43,ink)
		PixelArt.ellipse(img,79,54,37,40,purple)
		PixelArt.ellipse(img,72,43,28,28,Color("#8e6b9f"))
		PixelArt.ellipse(img,66,36,17,15,Color("#a382b1"))
		for i in 20: PixelArt.ellipse(img,48+(i*17)%61,28+(i*11)%35,1+i%2,1,Color("#ba91b5"))
		for x in [60,100]:
			PixelArt.ellipse(img,x,65,13,10,ink)
			PixelArt.ellipse(img,x,66,10,7,Color("#eac37b"))
			PixelArt.ellipse(img,x+2,66,2,7,Color("#9e4250"))
			PixelArt.px(img,x-4,63,Color("#fff1be"))
		PixelArt._fill_polygon(img,[Vector2i(46,52),Vector2i(71,60),Vector2i(69,64),Vector2i(47,57)],ink)
		PixelArt._fill_polygon(img,[Vector2i(88,60),Vector2i(114,51),Vector2i(113,57),Vector2i(89,64)],ink)
		PixelArt.ellipse(img,80,85,10,8,ink)
		PixelArt._fill_polygon(img,[Vector2i(74,81),Vector2i(87,81),Vector2i(80,94)],Color("#d0ac83"))
		PixelArt.line(img,80,83,80,91,Color("#856649"))
		PixelArt._fill_polygon(img,[Vector2i(48,23),Vector2i(43,3),Vector2i(65,12),Vector2i(80,0),Vector2i(96,12),Vector2i(117,3),Vector2i(112,23)],Color("#d6ad65"))
		PixelArt.rect(img,48,22,64,6,Color("#865c45"))
		PixelArt.rect(img,49,22,61,2,Color("#f1d58d"))
		for x in [58,80,102]:
			PixelArt.ellipse(img,x,18,4,5,Color("#a94b68"))
			PixelArt.px(img,x-1,16,Color("#eab09a"))
		return img)

static func prison_texture(opened: bool = false) -> Texture2D:
	return PixelArt.cached_texture("boss/arjun_prison/v2/%s" % opened,func() -> Image:
		var img := PixelArt.image(112,132)
		var ink := Color("#233345")
		PixelArt.ellipse(img,56,121,52,9,ink)
		PixelArt.rect(img,8,30,96,88,Color(0.09,0.15,0.22,0.18))
		PixelArt._fill_polygon(img,[Vector2i(6,31),Vector2i(25,11),Vector2i(87,11),Vector2i(106,31)],Color("#526678"))
		PixelArt.line(img,24,12,86,12,Color("#a8b6b5"))
		PixelArt.rect(img,8,30,96,7,Color("#9ba8a4"))
		PixelArt.rect(img,8,111,96,10,Color("#758a8c"))
		PixelArt.rect(img,10,111,92,3,Color("#b5beb2"))
		for x in [10,94]:
			PixelArt.rect(img,x,35,8,76,Color("#657f92"))
			PixelArt.rect(img,x,35,2,76,Color("#b7c8c2"))
			for y in [41,99]: PixelArt.rect(img,x+2,y,3,3,Color("#d7d9bd"))
		if not opened:
			for x in range(24,94,13):
				PixelArt.rect(img,x,35,4,76,Color("#8eacb4"))
				PixelArt.rect(img,x,35,1,76,Color("#d6e1d6"))
			PixelArt.rect(img,16,66,82,5,Color("#60798e"))
			PixelArt.rect(img,49,65,15,19,Color("#c9a55d"))
			PixelArt.ellipse(img,56,72,3,4,ink)
			PixelArt.rect(img,55,73,3,6,ink)
		else:
			PixelArt.rect(img,96,40,8,66,Color("#a6b8ba"))
			PixelArt.rect(img,101,43,3,60,Color("#dce1ce"))
		PixelArt.ellipse(img,56,16,7,8,Color("#b7a078"))
		PixelArt.ellipse(img,56,16,3,4,Color("#e2c48a"))
		return img)
