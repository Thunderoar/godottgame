class_name ElementalArt
extends RefCounted
## Original reproducible demon pixels, adapted from the supplied elemental roster.
## Cached source art uses the same AssetRegistry override path as the village.

static func _poly(img: Image, points: Array, color: Color) -> void:
	var vertices: Array[Vector2i] = []
	for point in points: vertices.append(Vector2i(point[0],point[1]))
	PixelArt._fill_polygon(img,vertices,color)

static func _orb(img: Image, x: int, y: int, radius: int, color: Color) -> void:
	PixelArt.ellipse(img,x,y,radius+3,radius+3,color.darkened(0.65))
	PixelArt.ellipse(img,x,y,radius,radius,color)
	PixelArt.ellipse(img,x-2,y-2,maxi(1,radius/2),maxi(1,radius/2),color.lightened(0.55))

static func boss_texture(element: String, frame: int = 0) -> Texture2D:
	var override := AssetRegistry.get_texture("elemental/boss/%s/%d/v1" % [element,frame%2])
	if override != null: return override
	var authored := RealmPresentation.actor_texture(element,true)
	if authored != null: return authored
	return PixelArt.cached_texture("elemental/boss/%s/%d/v1" % [element,frame%2],func() -> Image:
		var img := PixelArt.image(128,160)
		var def := ElementDB.get_element(element)
		var body := Color(str(def.get("body","#9063bb")))
		var glow := Color(str(def.get("glow","#ebafff")))
		var ink := Color("#171624")
		var dark := body.darkened(0.62)
		var light := body.lightened(0.22)
		var wing := 2 if frame%2 else 0
		# The monarch's raised throne, with a crown of obsidian spires.
		if element == "dark":
			_poly(img,[[28,139],[24,37],[38,20],[44,37],[51,8],[64,27],[77,8],[84,37],[92,20],[104,37],[100,139]],ink)
			PixelArt.rect(img,31,46,66,88,dark)
			for x in [33,89]:
				PixelArt.rect(img,x,43,7,94,body.darkened(0.3))
				PixelArt.vline(img,x+1,48,78,light)
			for step in 3: PixelArt.rect(img,24-step*5,140+step*5,80+step*10,5,body.darkened(0.55-step*0.08))
		# Bat membranes, ragged tempest wings and the shadow fiend's red fins.
		if element in ["chaos","wind","dark"]:
			for side in [-1,1]:
				_poly(img,[[64+side*17,70],[64+side*34,38-wing],[64+side*60,23+wing],[64+side*52,61],[64+side*44,53],[64+side*35,80],[64+side*26,73]],ink)
				_poly(img,[[64+side*20,66],[64+side*34,43-wing],[64+side*55,29+wing],[64+side*47,55],[64+side*39,53],[64+side*32,73]],body.darkened(0.4))
				PixelArt.line(img,64+side*20,65,64+side*54,29+wing,light)
				PixelArt.line(img,64+side*32,45,64+side*39,66,body)
		# Heavy boots, layered greaves and a torn loincloth.
		for side in [-1,1]:
			_poly(img,[[64+side*7,104],[64+side*24,108],[64+side*25,139],[64+side*34,146],[64+side*9,150]],ink)
			_poly(img,[[64+side*10,108],[64+side*21,110],[64+side*21,137],[64+side*27,142],[64+side*12,144]],body.darkened(0.25))
			PixelArt.line(img,64+side*14,116,64+side*17,137,light)
		_poly(img,[[41,69],[50,59],[78,59],[88,69],[82,111],[64,126],[46,111]],ink)
		_poly(img,[[46,71],[53,63],[75,63],[82,71],[77,107],[64,118],[51,106]],body)
		# Breastplate facets and glowing seams.
		_poly(img,[[48,72],[62,68],[62,86],[50,82]],light)
		_poly(img,[[66,68],[80,72],[78,82],[66,86]],body.lightened(0.1))
		for y in [89,96,103]:
			PixelArt.line(img,53,y,62,y+3,dark)
			PixelArt.line(img,66,y+3,75,y,dark)
		PixelArt.rect(img,48,109,32,4,dark)
		_orb(img,64,111,3,glow)
		# Muscular forearms, clawed hands and jagged pauldrons.
		for side in [-1,1]:
			_poly(img,[[64+side*17,64],[64+side*31,63],[64+side*42,93],[64+side*37,112],[64+side*27,106],[64+side*23,82]],ink)
			_poly(img,[[64+side*21,68],[64+side*28,68],[64+side*36,93],[64+side*33,104],[64+side*27,99],[64+side*26,81]],body)
			PixelArt.line(img,64+side*26,74,64+side*33,91,light)
			for spike in 3:
				var x := 64+int(side)*(20+spike*5)
				_poly(img,[[x,69],[x+side*4,50-spike*2],[x+side*7,70]],light if spike%2 else dark)
			for claw in 3: PixelArt.line(img,64+side*(28+claw*3),103,64+side*(29+claw*3),112,glow.darkened(0.1))
		# Angular demon skull and swept horns; bright eyes remain readable at 1x.
		_poly(img,[[48,37],[55,29],[73,29],[81,37],[77,57],[64,66],[51,57]],ink)
		_poly(img,[[52,38],[57,33],[71,33],[77,38],[73,55],[64,61],[55,55]],body.darkened(0.12))
		PixelArt.line(img,55,42,61,45,glow)
		PixelArt.line(img,67,45,73,42,glow)
		PixelArt.line(img,59,54,69,54,ink)
		for x in [60,64,68]: PixelArt.vline(img,x,52,4,glow.lightened(0.4))
		for side in [-1,1]:
			_poly(img,[[64+side*10,37],[64+side*22,29],[64+side*27,8],[64+side*17,18],[64+side*16,29]],ink)
			PixelArt.line(img,64+side*13,34,64+side*21,25,light)
		# Unique materials, weapons and silhouettes for every elemental ruler.
		match element:
			"earth":
				for i in 16:
					var x := 43+(i%4)*12
					var y := 65+(i/4)*15
					_poly(img,[[x,y],[x+10,y-3],[x+13,y+6],[x+8,y+13],[x-2,y+9]],body.lightened((i%3)*0.08))
					PixelArt.line(img,x+1,y+9,x+7,y+11,glow)
			"ice":
				for x in [31,44,82,95]:
					_poly(img,[[x,76],[x-5,44],[x+4,27],[x+9,63]],glow.darkened(0.28))
					PixelArt.line(img,x+4,33,x+3,66,glow.lightened(0.5))
				PixelArt.vline(img,63,70,30,glow)
			"fire":
				_poly(img,[[90,115],[109,41],[118,24],[119,50],[100,118]],Color("#bd3829"))
				_poly(img,[[95,113],[112,46],[116,34],[114,53],[99,114]],glow)
				PixelArt.line(img,85,111,108,120,ink)
				for x in [35,50,76,88]: _flame(img,x,62,glow,frame)
			"lightning":
				for side in [-1,1]:
					var x := 64+int(side)*43
					_poly(img,[[x,21],[x-9,51],[x+1,49],[x-8,84],[x+14,42],[x+4,44],[x+10,18]],glow)
					PixelArt.line(img,x+2,29,x-3,47,Color.WHITE)
			"forest":
				for side in [-1,1]:
					PixelArt.line(img,64+side*13,33,64+side*30,9,body)
					PixelArt.line(img,64+side*22,19,64+side*35,19,light)
					PixelArt.line(img,64+side*22,19,64+side*19,4,light)
					for y in [75,91,107,123]:
						PixelArt.line(img,64+side*12,y,64+side*23,y+11,dark)
						_poly(img,[[64+side*19,y+5],[64+side*32,y-2],[64+side*24,y+12]],body.lightened(0.2))
				_staff(img,103,glow,true)
			"water":
				PixelArt.vline(img,103,40,101,glow.darkened(0.4))
				PixelArt.line(img,92,34,92,48,glow)
				PixelArt.line(img,115,34,115,48,glow)
				PixelArt.line(img,92,48,103,56,glow)
				PixelArt.line(img,115,48,103,56,glow)
				_poly(img,[[99,42],[103,25],[107,42]],glow)
				for y in [77,85,93]:
					for x in range(51,78,8): PixelArt.line(img,x,y,x+4,y+3,light)
			"decay":
				_poly(img,[[45,67],[51,32],[64,23],[78,34],[84,69],[76,62],[64,36],[52,61]],dark)
				_poly(img,[[45,83],[39,146],[57,138],[65,151],[77,137],[91,146],[82,83],[75,118],[56,119]],dark)
				_staff(img,103,glow,false)
				for y in [114,123,135]: _orb(img,31,y,2,glow)
			"wind":
				for i in 9:
					var y := 84+i*6
					PixelArt.ellipse(img,25,y,16-i,2,glow.darkened(i*0.055))
					PixelArt.ellipse(img,103,y,16-i,2,glow.darkened(i*0.055))
			"chaos":
				for x in [23,101]: _flame(img,x,108,glow,frame)
				PixelArt.line(img,64,36,64,51,Color("#ff957b"))
			"dark":
				_orb(img,26,91,10,glow)
				_orb(img,103,91,10,glow)
				for x in [55,64,73]: _flame(img,x,24,glow,frame)
		return img)

static func _flame(img: Image, x: int, y: int, glow: Color, frame: int) -> void:
	_poly(img,[[x-9,y],[x-10,y-11],[x-4,y-7],[x+frame*2,y-30],[x+5,y-14],[x+9,y-18],[x+11,y-5],[x+5,y+3]],glow.darkened(0.25))
	_poly(img,[[x-4,y],[x-3,y-12],[x,y-20],[x+3,y-8],[x+5,y]],glow.lightened(0.35))

static func _staff(img: Image, x: int, glow: Color, nature: bool) -> void:
	PixelArt.line(img,x,52,x-7,143,Color("#50412f"))
	_orb(img,x,47,8,glow)
	for side in [-1,1]: PixelArt.line(img,x+side*11,36,x+side*8,56,glow.darkened(0.4))
	if nature: PixelArt.line(img,x+8,58,x+16,47,glow)

static func minion_texture(element: String, frame: int = 0) -> Texture2D:
	var override := AssetRegistry.get_texture("elemental/minion/%s/%d/v1" % [element,frame%2])
	if override != null: return override
	var authored := RealmPresentation.actor_texture(element,false)
	if authored != null: return authored
	return PixelArt.cached_texture("elemental/minion/%s/%d/v1" % [element,frame%2],func() -> Image:
		var img := PixelArt.image(48,64)
		var def := ElementDB.get_element(element)
		var body := Color(str(def.get("body","#9864ba")))
		var glow := Color(str(def.get("glow","#dfaaff")))
		var ink := Color("#1c1a29")
		var bob := frame%2
		for side in [-1,1]:
			_poly(img,[[24+side*4,41],[24+side*11,42],[24+side*(11+bob*2),59],[24+side*3,60]],ink)
			PixelArt.line(img,24+side*7,45,24+side*(9+bob*2),56,body)
			_poly(img,[[24+side*8,26],[24+side*17,26],[24+side*20,43],[24+side*13,46]],body.darkened(0.35))
			_poly(img,[[24+side*6,17],[24+side*14,5],[24+side*12,22]],body)
		_poly(img,[[14,25],[34,25],[33,45],[24,50],[15,45]],ink)
		_poly(img,[[17,28],[31,28],[29,43],[24,46],[19,42]],body)
		PixelArt.ellipse(img,24,20+bob,10,11,ink)
		PixelArt.ellipse(img,24,20+bob,8,9,body.darkened(0.1))
		PixelArt.hline(img,18,19+bob,4,glow)
		PixelArt.hline(img,26,19+bob,4,glow)
		PixelArt.hline(img,21,26+bob,6,ink)
		match element:
			"ice":
				for x in [10,35]: _poly(img,[[x,36],[x-3,21],[x+2,14],[x+6,36]],glow)
			"earth":
				for y in [31,39]: PixelArt.rect(img,12,y,24,6,body.lightened(0.1))
			"forest":
				for x in [10,33]: _poly(img,[[x,29],[x-7,20],[x+6,25]],glow.darkened(0.2))
			"water":
				PixelArt.vline(img,40,15,39,glow)
				PixelArt.hline(img,35,22,11,glow)
			"decay":
				_poly(img,[[12,31],[16,12],[24,6],[33,13],[37,31],[29,26],[24,15],[18,27]],body.darkened(0.5))
			"wind","chaos":
				for side in [-1,1]: _poly(img,[[24+side*10,30],[24+side*23,15],[24+side*21,39]],body.darkened(0.3))
			"lightning": PixelArt.line(img,6,7,3,37,glow)
			"fire": _flame(img,37,44,glow,frame)
			"dark": _orb(img,40,37,4,glow)
		return img)

static func pillar_texture(element: String) -> Texture2D:
	var override := AssetRegistry.get_texture("elemental/pillar/%s/v1" % element)
	if override != null: return override
	var authored := RealmPresentation.prop_texture(element)
	if authored != null: return authored
	return PixelArt.cached_texture("elemental/pillar/%s/v1" % element,func() -> Image:
		var img := PixelArt.image(48,88)
		var def := ElementDB.get_element(element)
		var body := Color(str(def.get("body","#796188")))
		var glow := Color(str(def.get("glow","#ceacf0")))
		if element in ["ice","lightning"]:
			_poly(img,[[4,75],[12,30],[23,1],[35,22],[44,77],[24,86]],body.darkened(0.3))
			_poly(img,[[15,73],[23,6],[30,26],[31,78]],glow)
		elif element == "forest":
			for side in [-1,1]:
				PixelArt.line(img,24,76,24+side*17,29,body)
				PixelArt.line(img,24+side*11,48,24+side*20,37,glow.darkened(0.25))
			_poly(img,[[12,82],[18,29],[23,7],[31,35],[36,82]],body.darkened(0.3))
		else:
			_poly(img,[[5,79],[11,20],[23,5],[38,19],[43,79],[24,87]],body.darkened(0.5))
			_poly(img,[[15,73],[17,26],[23,15],[30,29],[31,74]],body)
			for y in range(30,69,11): PixelArt.hline(img,20,y,8,glow)
		return img)

static func paint_floor(img: Image, element: String, rng: RandomNumberGenerator) -> void:
	var def := ElementDB.get_element(element)
	var glow := Color(str(def.get("glow","#bc8bdd")))
	var base := Color(str(def.get("floor","#40334c")))
	for i in 28:
		var x := rng.randi_range(70,img.get_width()-70)
		var y := rng.randi_range(95,img.get_height()-80)
		match element:
			"ice":
				_poly(img,[[x-30,y],[x,y-15],[x+42,y+3],[x+20,y+18]],base.lightened(0.12))
				PixelArt.line(img,x-12,y,x+17,y+8,glow.darkened(0.2))
			"forest":
				PixelArt.ellipse(img,x,y,28,14,base.lightened(0.06))
				for stem in 6: PixelArt.line(img,x+stem*4-12,y+5,x+stem*4-14,y-7,glow.darkened(0.6))
			"water","wind":
				for band in 3: PixelArt.hline(img,x-28+band*5,y+band*4,46-band*5,base.lightened(0.1+band*0.025))
			"earth","fire","chaos":
				for crack in 5:
					PixelArt.line(img,x+crack*7,y+crack%2*5,x+(crack+1)*7,y+(crack+1)%2*5,glow.darkened(0.52))
			"decay":
				PixelArt.ellipse(img,x,y,20,8,base.lerp(glow,0.24))
				for bubble in 3: PixelArt.ellipse(img,x+bubble*9-9,y-2,2,1,glow.darkened(0.25))
			_:
				_poly(img,[[x-16,y],[x,y-9],[x+16,y],[x,y+9]],base.lightened(0.12))
				PixelArt.vline(img,x,y-5,10,glow.darkened(0.4))
