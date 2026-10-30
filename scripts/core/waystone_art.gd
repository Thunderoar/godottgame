class_name WaystoneArt
extends RefCounted
## Small original pixel pieces; no shared-image mutation or gameplay RNG.

static func ground() -> Texture2D:
	return PixelArt.cached_texture("waystone/ground/v2", func() -> Image:
		var img := PixelArt.image(176,144)
		var centre := Vector2(88,60)
		PixelArt.ellipse(img,88,65,72,29,Color("#263e412b"))
		PixelArt.ellipse(img,88,61,58,21,Color("#7b927b"))
		# A broken oval has a southern opening, leading the eye into the site.
		for i in 16:
			if i in [3,4,11]: continue
			var a := float(i)*TAU/16+0.035
			var b := float(i+1)*TAU/16-0.035
			var points := [centre+Vector2(cos(a)*54,sin(a)*20),centre+Vector2(cos(a)*70,sin(a)*29),centre+Vector2(cos(b)*70,sin(b)*29),centre+Vector2(cos(b)*54,sin(b)*20)]
			PixelArt._fill_polygon(img,points,Color("#afbaa1") if i%3 else Color("#93a58f"))
			PixelArt.line(img,int(points[0].x),int(points[0].y),int(points[1].x),int(points[1].y),Color("#d0ccb0"))
		for tile in [Vector2i(57,56),Vector2i(81,69),Vector2i(106,59),Vector2i(88,88),Vector2i(109,105),Vector2i(127,124)]:
			PixelArt.rect(img,tile.x-12,tile.y-4,25,10,Color("#566f67"))
			PixelArt.rect(img,tile.x-11,tile.y-5,23,8,Color("#abb69d"))
			PixelArt.rect(img,tile.x-9,tile.y-5,18,2,Color("#d1c9aa"))
			PixelArt.line(img,tile.x,tile.y-3,tile.x,tile.y+1,Color("#6a8f83"))
			PixelArt.hline(img,tile.x-3,tile.y-1,7,Color("#6a8f83"))
		# Moss, grass and fragments soften the edge; the walking lane stays open.
		for p in [Vector2i(29,52),Vector2i(47,80),Vector2i(127,79),Vector2i(143,46),Vector2i(61,35)]:
			PixelArt.rect(img,p.x,p.y,10,3,Color("#6f8c57"))
			PixelArt.rect(img,p.x+3,p.y-2,5,3,Color("#a3ad73"))
		PixelArt.ellipse(img,118,63,10,6,Color("#3c5556"))
		PixelArt.ellipse(img,118,61,9,5,Color("#d4c8a4"))
		PixelArt.ellipse(img,118,61,5,3,Color("#4f6b66"))
		PixelArt.px(img,117,60,Color("#e5d6ad"))
		return img)

static func flowers() -> Texture2D:
	return PixelArt.cached_texture("waystone/moonblooms/v1", func() -> Image:
		var img := PixelArt.image(176,112)
		for p in [Vector2i(17,56),Vector2i(26,48),Vector2i(34,63),Vector2i(30,77),Vector2i(143,62),Vector2i(154,51),Vector2i(160,71),Vector2i(141,82)]:
			PixelArt.ellipse(img,p.x,p.y+7,7,2,Color("#50765d70"))
			PixelArt.vline(img,p.x,p.y,8,Color("#476d5e"))
			PixelArt.line(img,p.x,p.y+5,p.x-4,p.y+2,Color("#81a585"))
			PixelArt.rect(img,p.x-4,p.y-1,9,3,Color("#c6ddcf"))
			PixelArt.rect(img,p.x-1,p.y-4,3,9,Color("#dbe9cf"))
			PixelArt.rect(img,p.x-1,p.y-1,3,3,Color("#f5d58d"))
		return img)

static func ribbon() -> Texture2D:
	return PixelArt.cached_texture("waystone/wayfarer_ribbon/v1", func() -> Image:
		var img := PixelArt.image(24,46)
		PixelArt.ellipse(img,12,42,9,2,Color("#243f4140"))
		PixelArt.rect(img,10,7,4,35,Color("#5e6956"))
		PixelArt.vline(img,11,6,34,Color("#b2a078"))
		PixelArt.rect(img,5,8,15,3,Color("#776b54"))
		PixelArt.rect(img,6,11,13,17,Color("#c1b186"))
		PixelArt.rect(img,7,11,10,2,Color("#e1ce9c"))
		PixelArt.rect(img,7,28,4,3,Color("#c1b186"))
		PixelArt.rect(img,14,28,4,5,Color("#c1b186"))
		PixelArt.vline(img,12,15,9,Color("#617f76"))
		PixelArt.hline(img,9,18,7,Color("#617f76"))
		PixelArt.rect(img,16,23,3,3,Color("#889575"))
		return img)

static func glimmer() -> Texture2D:
	return PixelArt.cached_texture("waystone/socket_glimmer/v1", func() -> Image:
		var img := PixelArt.image(12,12)
		for pair in [[6,1,10,6],[10,6,6,10],[6,10,2,6],[2,6,6,1]]:
			PixelArt.line(img,pair[0],pair[1],pair[2],pair[3],Color("#f2e4ac"))
		PixelArt.rect(img,5,5,3,3,Color("#ffffdf"))
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
