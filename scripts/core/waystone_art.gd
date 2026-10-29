class_name WaystoneArt
extends RefCounted
## Small original pixel pieces; no shared-image mutation or gameplay RNG.

static func ground() -> Texture2D:
	return PixelArt.cached_texture("waystone/ground/v1", func() -> Image:
		var img := PixelArt.image(112, 64)
		PixelArt.ellipse(img, 56, 38, 49, 18, Color("#263e4140"))
		for tile in [Vector3(19,35,0),Vector3(43,43,1),Vector3(65,37,0),Vector3(85,30,1)]:
			PixelArt.rect(img,int(tile.x)-10,int(tile.y)-4,21,9,Color("#596c67"))
			PixelArt.rect(img,int(tile.x)-9,int(tile.y)-4,18,2,Color("#a0a48a"))
			PixelArt.rect(img,int(tile.x)-7,int(tile.y),10,2,Color("#788c79"))
		for p in [Vector2i(13,31),Vector2i(38,49),Vector2i(76,39),Vector2i(95,29)]:
			PixelArt.rect(img,p.x,p.y,7,3,Color("#627c50"))
			PixelArt.rect(img,p.x+2,p.y-2,3,3,Color("#8c9d60"))
		PixelArt.ellipse(img,86,39,9,5,Color("#384f52"))
		PixelArt.ellipse(img,86,37,8,4,Color("#b4b49a"))
		PixelArt.ellipse(img,86,37,5,2,Color("#526467"))
		return img)

static func marker() -> Texture2D:
	return PixelArt.cached_texture("waystone/marker/v1", func() -> Image:
		var img := PixelArt.image(30,52)
		PixelArt.rect(img,5,8,21,41,Color("#40565c"))
		PixelArt.rect(img,7,5,17,43,Color("#8d9990"))
		PixelArt.rect(img,9,4,12,3,Color("#bcc2a4"))
		PixelArt.rect(img,8,9,3,34,Color("#b2b89d"))
		PixelArt.rect(img,21,11,3,36,Color("#617c7c"))
		PixelArt.rect(img,14,13,3,27,Color("#435f64"))
		PixelArt.rect(img,11,20,10,3,Color("#435f64"))
		PixelArt.rect(img,11,31,10,3,Color("#435f64"))
		PixelArt.rect(img,7,40,7,4,Color("#6b8558"))
		PixelArt.rect(img,9,39,3,3,Color("#a2ad72"))
		return img)

static func lantern() -> Texture2D:
	return PixelArt.cached_texture("waystone/lantern/v1", func() -> Image:
		var img := PixelArt.image(20,32)
		PixelArt.rect(img,7,2,6,2,Color("#45595a"))
		PixelArt.rect(img,5,4,2,5,Color("#45595a"))
		PixelArt.rect(img,13,4,2,5,Color("#45595a"))
		PixelArt.rect(img,3,10,14,3,Color("#806f58"))
		PixelArt.rect(img,5,13,10,12,Color("#ffe8a0"))
		PixelArt.rect(img,8,15,4,9,Color("#fff8d8"))
		PixelArt.rect(img,3,13,2,14,Color("#626b60"))
		PixelArt.rect(img,15,13,2,14,Color("#626b60"))
		PixelArt.rect(img,2,26,16,3,Color("#806f58"))
		PixelArt.rect(img,5,29,10,2,Color("#45595a"))
		return img)

static func road() -> Texture2D:
	return PixelArt.cached_texture("waystone/answering_road/v1", func() -> Image:
		var img := PixelArt.image(48,92)
		for y in 92:
			for x in 48:
				var dx := (float(x)-23.5)/23.0
				var dy := (float(y)-46.0)/45.0
				if dx*dx+dy*dy > 1.0: continue
				var col := Color("#353f61") if y < 40 else Color("#4c6764")
				if absi(x-24) < 3+(y/12) and y > 29: col = Color("#9caa9b") if y%12 < 8 else Color("#6c827f")
				if x < 10 or x > 38: col = Color("#494b65") if (x+y/8)%7 < 4 else Color("#69727e")
				img.set_pixel(x,y,col)
		return img)
