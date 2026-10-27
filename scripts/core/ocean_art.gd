class_name OceanArt
extends RefCounted
## Original cached pixel assets for marine life and the sea floor.
static func creature(kind: String, frame: int = 0) -> Texture2D:
	return PixelArt.cached_texture("ocean_life/%s/%d/v2" % [kind, frame % 2], func() -> Image:
		var img := PixelArt.image(128,80)
		var ink := Color("#142f45")
		var blue := Color("#6095ad")
		var pale := Color("#d5ecdc")
		var fin := 3 if frame % 2 else -3
		match kind:
			"shark", "megalodon", "whale":
				var whale := kind == "whale"
				var skin := Color("#426b8d") if whale else blue
				PixelArt._fill_polygon(img,[Vector2i(94,36),Vector2i(125,14+fin),Vector2i(117,38),Vector2i(126,63-fin),Vector2i(92,47)],ink)
				PixelArt._fill_polygon(img,[Vector2i(94,37),Vector2i(121,19+fin),Vector2i(112,39),Vector2i(121,59-fin),Vector2i(93,44)],skin)
				PixelArt.ellipse(img,57,41,51,23,ink)
				PixelArt.ellipse(img,57,39,49,20,skin)
				PixelArt.ellipse(img,49,48,39,11,pale.darkened(0.08))
				if not whale:
					PixelArt._fill_polygon(img,[Vector2i(56,22),Vector2i(75,3),Vector2i(78,27)],ink)
					PixelArt._fill_polygon(img,[Vector2i(60,22),Vector2i(73,8),Vector2i(74,25)],skin.lightened(0.08))
				PixelArt._fill_polygon(img,[Vector2i(65,48),Vector2i(85,69+fin),Vector2i(48,54)],skin.darkened(0.23))
				PixelArt.ellipse(img,29,32,3,3,ink)
				PixelArt.px(img,28,31,Color.WHITE)
				for x in [39,44,49]: PixelArt.line(img,x,34,x+2,42,skin.darkened(0.4))
				if whale:
					PixelArt.line(img,12,43,28,48,ink)
					for i in 5: PixelArt.line(img,22+i*5,49,25+i*5,55,blue)
				else:
					PixelArt.ellipse(img,18,48,16,16,ink)
					PixelArt.ellipse(img,17,48,12,12,Color("#6c283e"))
					PixelArt.ellipse(img,16,54,9,4,Color("#cd6878"))
					for i in 4:
						var x := 7+i*6
						PixelArt._fill_polygon(img,[Vector2i(x,37),Vector2i(x+5,38),Vector2i(x+2,45)],pale)
						PixelArt._fill_polygon(img,[Vector2i(x,58),Vector2i(x+5,57),Vector2i(x+2,51)],pale)
			"mermaid", "diver":
				var skin := Color("#e1ad83")
				PixelArt.ellipse(img,44,20,9,10,ink)
				PixelArt.ellipse(img,42,19,7,8,skin)
				PixelArt.rect(img,37,31,15,19,Color("#49b8a9") if kind == "mermaid" else Color("#263947"))
				PixelArt.line(img,38,33,22,43+fin,skin)
				PixelArt.line(img,50,33,65,29-fin,skin)
				if kind == "mermaid":
					PixelArt._fill_polygon(img,[Vector2i(37,47),Vector2i(51,47),Vector2i(67,64),Vector2i(91,57+fin),Vector2i(78,71),Vector2i(56,69)],Color("#47bfaa"))
					PixelArt._fill_polygon(img,[Vector2i(77,67),Vector2i(104,53+fin),Vector2i(100,72),Vector2i(80,74)],Color("#8ce7ca"))
					PixelArt.ellipse(img,45,13,10,5,Color("#923f6d"))
					PixelArt.rect(img,49,14,8,20,Color("#aa5077"))
				else:
					PixelArt.rect(img,34,15,19,8,Color("#b1eceb"))
					PixelArt.rect(img,55,31,8,18,Color("#e5bd56"))
					for x in [39,49]:
						PixelArt.line(img,x,47,x+10,64+fin,Color("#263947"))
						PixelArt.rect(img,x+7,62+fin,14,5,Color("#f3c962"))
					PixelArt.line(img,53,20,61,13,ink)
			"fish":
				PixelArt.ellipse(img,58,39,25,13,ink)
				PixelArt.ellipse(img,57,38,23,11,Color("#efbb63"))
				PixelArt._fill_polygon(img,[Vector2i(77,38),Vector2i(99,24+fin),Vector2i(97,53-fin)],Color("#e47e65"))
				PixelArt.rect(img,53,29,5,18,Color("#f5e5bd"))
				PixelArt.ellipse(img,40,36,3,3,ink)
		return img)

static func seabed(kind: String) -> Texture2D:
	return PixelArt.cached_texture("ocean_bed/%s/v1" % kind,func() -> Image:
		var img := PixelArt.image(128,96)
		match kind:
			"wreck":
				PixelArt._fill_polygon(img,[Vector2i(4,49),Vector2i(111,37),Vector2i(100,77),Vector2i(30,87)],Color("#284c56"))
				for i in 8: PixelArt.line(img,17+i*12,48-i,35+i*8,82-i,Color("#617c79"))
				PixelArt.line(img,62,52,72,4,Color("#506d6f"))
				PixelArt._fill_polygon(img,[Vector2i(72,7),Vector2i(99,33),Vector2i(69,29)],Color("#74928b"))
				for x in [38,61,84]: PixelArt.ellipse(img,x,60,5,5,Color("#153740"))
			"chest":
				PixelArt.rect(img,31,44,66,37,Color("#574235"))
				PixelArt.ellipse(img,64,44,33,17,Color("#a47d47"))
				PixelArt.rect(img,31,49,66,5,Color("#ddb966"))
				for x in [39,83]: PixelArt.rect(img,x,40,7,40,Color("#c5a159"))
				PixelArt.rect(img,60,49,10,13,Color("#f3d88f"))
				PixelArt.rect(img,64,53,3,5,Color("#5a453a"))
			"pearl":
				PixelArt.ellipse(img,64,64,28,14,Color("#b384b0"))
				PixelArt._fill_polygon(img,[Vector2i(37,57),Vector2i(41,29),Vector2i(65,39),Vector2i(87,30),Vector2i(91,57)],Color("#d9a9c8"))
				PixelArt.ellipse(img,64,55,12,12,Color("#f3f1de"))
				PixelArt.ellipse(img,60,51,4,4,Color.WHITE)
			"crab":
				PixelArt.ellipse(img,63,61,18,10,Color("#e48868"))
				for side in [-1,1]:
					for i in 3: PixelArt.line(img,63+side*15,60+i*4,63+side*30,57+i*7,Color("#ce6a59"))
					PixelArt.line(img,63+side*16,57,63+side*26,43,Color("#edaa77"))
					PixelArt.ellipse(img,63+side*27,41,7,7,Color("#e89170"))
				for x in [56,70]: PixelArt.rect(img,x,46,3,7,Color("#263a44"))
			"starfish":
				var pts: Array[Vector2i] = []
				for i in 10:
					var a := i*TAU/10-PI/2
					pts.append(Vector2i(Vector2(64,60)+Vector2.from_angle(a)*(29 if i%2==0 else 12)))
				PixelArt._fill_polygon(img,pts,Color("#ecae70"))
				PixelArt.ellipse(img,64,60,5,5,Color("#f6ce8d"))
			"coral":
				for i in 7:
					var x := 25+i*12
					var y := 20+i%3*13
					for dx in [-8,8]: PixelArt.line(img,x,78,x+dx,y,Color("#d578a1"))
					PixelArt.ellipse(img,x+8,y,4,5,Color("#ef9bb1"))
		return img)
