@tool
class_name KampungArt
extends RefCounted
## Original small-scale timber, garden and sanctuary art. No reference pixels.
const COMPOUND_KINDS := ["wakaf", "garden_shed", "veranda", "clothesline", "drying_rack", "trough", "herbs"]
const KINDS := ["banana", "veranda", "clothesline", "wakaf", "drying_rack", "herbs", "parit", "trough", "garden_shed", "sanctuary_arch", "sentinel", "companion_stone", "moon_flower"]

static func texture(kind: String) -> Texture2D:
	var override := AssetRegistry.get_texture("village/" + kind)
	if override: return override
	return PixelArt.cached_texture("kampung/" + kind, func() -> Image: return draw(kind))

static func draw(kind: String) -> Image:
	if kind in COMPOUND_KINDS: return _compound(kind)
	var img := PixelArt.image(128, 112)
	var wood := WorldPalette.color("wood")
	var dark := WorldPalette.color("wood_shadow")
	var light := WorldPalette.color("cream")
	var mint := WorldPalette.color("leaf_mint")
	var jade := WorldPalette.color("grass_shadow")
	var stone := WorldPalette.color("stone")
	var ink := WorldPalette.color("outline")
	PixelArt.ellipse(img, 64, 105, 42, 5, Color(0.16, 0.25, 0.27, 0.15))
	match kind:
		"banana":
			for stem in [57, 66, 73]:
				PixelArt.line(img, stem, 103, 63, 47, dark)
				PixelArt.line(img, stem + 2, 103, 65, 47, wood)
			for i in 7:
				var end := Vector2(13 + i * 17, 51 + (i % 3) * 12)
				var origin := Vector2(64, 42 + i % 2 * 7)
				for t in range(1, 81):
					var f := t / 80.0
					var at := origin.lerp(end, f) + Vector2(0, -sin(f * PI) * 17)
					var span := int(sin(f * PI) * 10)
					PixelArt.rect(img, int(at.x), int(at.y) - span, 2, span * 2 + 1, jade if i % 2 else mint.darkened(0.18))
				PixelArt.line(img, int(origin.x), int(origin.y), int(end.x), int(end.y), mint)
			for i in 5: PixelArt.rect(img, 67 + i % 2 * 3, 62 + i * 3, 5, 4, WorldPalette.color("sunlight"))
		"parit":
			PixelArt.rect(img, 11, 94, 106, 10, stone.darkened(0.3))
			PixelArt.rect(img, 13, 96, 102, 5, WorldPalette.color("sea_deep"))
			for x in range(12, 114, 13): PixelArt.rect(img, x, 92, 9, 12, stone)
		"sanctuary_arch":
			# Framing at the sides leaves the entire central approach open.
			for x in [8, 109]:
				PixelArt.rect(img, x, 57, 11, 48, ink)
				PixelArt.rect(img, x + 2, 59, 7, 43, stone)
				PixelArt.rect(img, x - 3, 54, 17, 5, dark)
				PixelArt.rect(img, x + 4, 64, 2, 12, mint)
			PixelArt.rect(img, 7, 48, 114, 6, dark)
			PixelArt.rect(img, 12, 46, 104, 3, wood)
			for x in range(19, 113, 12): PixelArt.rect(img, x, 51, 5, 5, mint.darkened(0.3))
		"sentinel", "companion_stone":
			var pet := kind == "companion_stone"
			PixelArt.rect(img, 41, 97, 46, 8, ink)
			PixelArt.rect(img, 46, 66, 36, 31, stone.darkened(0.15))
			PixelArt.rect(img, 49, 68, 30, 25, stone)
			if pet:
				PixelArt.ellipse(img, 64, 65, 16, 14, stone)
				PixelArt.line(img, 49, 58, 48, 41, stone)
				PixelArt.line(img, 78, 58, 80, 41, stone)
				for x in [57, 70]: PixelArt.rect(img, x, 62, 3, 3, mint)
				PixelArt.ellipse(img, 64, 85, 8, 5, mint)
			else:
				PixelArt.rect(img, 52, 37, 24, 32, stone.darkened(0.1))
				PixelArt.rect(img, 56, 42, 16, 22, dark)
				PixelArt.line(img, 59, 86, 68, 72, mint)
				PixelArt.line(img, 59, 72, 68, 86, mint)
		"moon_flower":
			for i in 5:
				var x := 39 + i * 12
				PixelArt.line(img, 64, 103, x, 81 + i % 3 * 5, jade)
				PixelArt.ellipse(img, x, 80 + i % 3 * 5, 5, 3, WorldPalette.color("sea_shallow"))
				PixelArt.rect(img, x - 1, 77 + i % 3 * 5, 2, 3, light)
	return img


# Structural family: same elevated view as the approved cottage, no side extrusion.
static func _compound(kind: String) -> Image:
	var img := PixelArt.image(128, 112)
	var wood := WorldPalette.color("wood").lerp(Color("b59666"), 0.42)
	var dark := WorldPalette.color("wood_shadow").lerp(Color("304b45"), 0.30)
	var light := wood.lerp(WorldPalette.color("cream"), 0.40)
	var roof := WorldPalette.color("roof").lerp(WorldPalette.color("sunlight"), 0.12)
	var fibre := WorldPalette.color("cream").lerp(wood, 0.30)
	var metal := WorldPalette.color("stone").lerp(Color("48746d"), 0.50)
	PixelArt.ellipse(img, 64, 105, 42, 5, Color(0.16, 0.25, 0.27, 0.15))
	match kind:
		"wakaf", "garden_shed":
			for x in [27, 96]:
				PixelArt.rect(img, x, 53, 5, 50, dark)
				PixelArt.vline(img, x+1, 55, 46, wood)
				PixelArt.vline(img, x+2, 56, 43, light.darkened(0.16))
			_beam(img, 22, 93, 85, 6, 5, wood, dark, light)
			if kind == "garden_shed":
				PixelArt.rect(img, 31, 57, 65, 35, dark)
				for y in range(62,91,5):
					PixelArt.rect(img, 33, y, 61, 4, wood)
					PixelArt.hline(img, 34, y, 58, light.darkened(0.20))
				# Closed store shutter, not a new enterable house or open doorway.
				PixelArt.rect(img, 53, 68, 22, 24, dark)
				PixelArt.rect(img, 55, 70, 18, 21, wood.darkened(0.14))
				for x in [59,64,69]: PixelArt.vline(img, x, 71, 19, dark)
				PixelArt.hline(img, 56, 76, 16, light.darkened(0.22))
				PixelArt.hline(img, 56, 86, 16, dark)
				PixelArt.rect(img, 68, 80, 2, 3, fibre)
				for x in [37,82]:
					PixelArt.rect(img, x, 69, 8, 11, dark)
					PixelArt.rect(img, x+1, 70, 6, 7, metal.darkened(0.20))
					PixelArt.vline(img, x+4, 70, 7, wood)
			else:
				# Keep the central opening genuinely transparent above the seat.
				_beam(img, 31, 83, 64, 6, 5, wood, dark, light)
				for x in [38,87]:
					PixelArt.rect(img, x, 88, 4, 7, dark)
					PixelArt.vline(img, x+1, 88, 6, wood)
			_compound_roof(img, roof, wood, dark, light)
		"veranda":
			_beam(img, 12, 78, 104, 17, 7, wood, dark, light)
			for y in range(80,94,4):
				PixelArt.hline(img, 14, y, 100, dark.lightened(0.08))
				PixelArt.hline(img, 16, y+1, 96, light.darkened(0.19))
			for x in [17,36,89,108]:
				PixelArt.rect(img, x, 65, 3, 30, dark)
				PixelArt.vline(img, x+1, 66, 27, wood)
				_beam(img, x-1, 65, 5, 2, 2, wood, dark, light)
			for x in [15,87]:
				_beam(img, x, 68, 26, 3, 3, wood, dark, light)
				PixelArt.hline(img, x+1, 74, 24, dark)
			for step in 3:
				_beam(img, 49-step*2, 98+step*3, 30+step*4, 2, 2, wood, dark, light)
		"clothesline":
			for x in [17,109]:
				PixelArt.rect(img, x, 47, 3, 56, dark)
				PixelArt.vline(img, x+1, 48, 53, wood)
				_beam(img, x-1, 48, 5, 2, 2, wood, dark, light)
			var previous := Vector2i(18,53)
			for step in range(1,25):
				var t := step/24.0
				var point := Vector2i(18+roundi(t*92),53+roundi(sin(t*PI)*5))
				PixelArt.line(img,previous.x,previous.y,point.x,point.y,fibre.darkened(0.13))
				previous=point
			for i in 4:
				var x := 27+i*20
				var bottom := 80+i%2*5
				var dye: Color=[WorldPalette.color("leaf_mint").lerp(fibre,0.32),roof.lerp(fibre,0.30),fibre,WorldPalette.color("sea_deep").lerp(wood,0.27)][i]
				_poly(img,[[x,57],[x+14,58],[x+13,bottom],[x+1,bottom+1]],dye.darkened(0.12))
				PixelArt.rect(img,x+2,59,5,bottom-59,dye.lightened(0.05))
				PixelArt.vline(img,x+9,60,bottom-61,dye.darkened(0.24))
				PixelArt.hline(img,x+2,bottom-1,10,dye.lightened(0.13))
				for peg in [x+1,x+11]:PixelArt.rect(img,peg,55,2,5,wood)
		"drying_rack":
			for x in [24,98]:
				PixelArt.rect(img,x,61,4,43,dark)
				PixelArt.vline(img,x+1,62,40,wood)
			_beam(img,19,68,88,22,6,wood,dark,light)
			for x in range(23,103,6):
				PixelArt.vline(img,x,69,19,dark)
				PixelArt.vline(img,x+1,69,18,light.darkened(0.16))
			PixelArt.hline(img,21,88,84,dark)
			for i in 6:
				var x := 31+i*12
				var y := 76+i%2*5
				PixelArt.ellipse(img,x,y+1,5,2,dark)
				PixelArt.ellipse(img,x,y,5,2,WorldPalette.color("sea_deep").lerp(metal,0.40))
				PixelArt.hline(img,x-2,y-1,4,metal)
		"herbs":
			_beam(img,22,94,84,8,4,wood,dark,light)
			for i in 4:
				var x := 35+i*22
				_poly(img,[[x-7,79],[x-5,92],[x+5,92],[x+7,79]],dark)
				_poly(img,[[x-5,80],[x-3,91],[x+4,91],[x+5,80]],roof.darkened(0.14))
				PixelArt.vline(img,x-3,82,7,roof.lightened(0.18))
				PixelArt.ellipse(img,x,79,7,3,wood)
				PixelArt.ellipse(img,x,79,5,2,dark)
				PixelArt.line(img,x,79,x,56,WorldPalette.color("leaf_deep"))
				for j in 4:
					var y := 58+j*5
					var side := -1 if j%2 else 1
					PixelArt.line(img,x,y+3,x+side*5,y,WorldPalette.color("leaf_deep"))
					PixelArt.ellipse(img,x+side*5,y,4,2,WorldPalette.color("leaf").lerp(WorldPalette.color("fern"),0.40))
					PixelArt.hline(img,x+side*5-1,y-1,3,WorldPalette.color("leaf_sun").darkened(0.12))
		"trough":
			_poly(img,[[23,84],[31,79],[97,79],[105,84],[101,102],[27,102]],dark)
			PixelArt.rect(img,27,89,74,12,wood)
			for x in range(31,99,9):PixelArt.vline(img,x,91,9,dark)
			_poly(img,[[27,84],[33,81],[95,81],[101,84],[97,91],[31,91]],light)
			_poly(img,[[31,84],[35,83],[93,83],[97,84],[94,88],[34,88]],dark)
			_poly(img,[[33,85],[36,84],[92,84],[95,85],[93,88],[35,88]],WorldPalette.color("sea_shallow").lerp(metal,0.55))
			PixelArt.hline(img,38,85,34,WorldPalette.color("cream").lerp(metal,0.55))
			PixelArt.hline(img,28,97,72,metal.darkened(0.18))
	return img


static func _beam(img: Image,x: int,y: int,width: int,height: int,depth: int,wood: Color,dark: Color,light: Color) -> void:
	PixelArt.rect(img,x,y,width,height,dark)
	PixelArt.rect(img,x+1,y+1,width-2,maxi(1,height-2),wood)
	_poly(img,[[x,y],[x+3,y-depth],[x+width-3,y-depth],[x+width,y]],light)
	PixelArt.hline(img,x,y+height-1,width,dark)


static func _poly(img: Image,points: Array,ink: Color) -> void:
	var vertices: Array[Vector2i]=[]
	for point in points:vertices.append(Vector2i(point[0],point[1]))
	PixelArt._fill_polygon(img,vertices,ink)


static func _compound_roof(img: Image,roof: Color,wood: Color,dark: Color,light: Color) -> void:
	# Back ridge(64,10) -> front ridge(64,43): depth is in screen Y.
	_poly(img,[[10,28],[64,10],[118,28],[118,61],[64,44],[10,61]],dark)
	for x in range(12,117):
		var distance := absf(float(x-64))
		var back := 11.0+distance*0.32
		for y in range(11,60):
			var v := float(y)-back
			if v<0.0 or v>=30.0:continue
			var course := int(v)/7
			var ink := roof if x<64 else roof.darkened(0.15)
			if int(v)%7==6:ink=ink.darkened(0.19)
			elif int(v)%7==0:ink=ink.lightened(0.12)
			elif (x+course%2*6)%12==0:ink=ink.darkened(0.16)
			PixelArt.px(img,x,y,ink)
	_poly(img,[[13,61],[64,44],[115,61]],wood.darkened(0.22))
	for y in range(48,61,4):PixelArt.hline(img,56-(y-48)*3,y,16+(y-48)*6,wood)
	# Thick front eaves, never an extruded right-side wall.
	_poly(img,[[10,59],[62,42],[65,44],[12,63]],dark)
	_poly(img,[[64,44],[66,42],[118,59],[116,63]],dark)
	PixelArt.line(img,12,59,63,43,light)
	PixelArt.line(img,65,43,116,59,wood)
	PixelArt.rect(img,62,12,4,31,dark)
	PixelArt.vline(img,63,12,30,roof.lightened(0.26))
