class_name RealmPresentation
extends RefCounted
## Imported, shared game sprites plus one inexpensive quad per spell.
const ORDER := ["chaos","wind","ice","earth","fire","lightning","forest","water","decay","dark"]
# Authored rectangles account for transparent export trim. Never assume that
# generated atlas cells divide the exported canvas into exact equal fractions.
const BOSS_RECTS := [Rect2(2,125,312,326),Rect2(317,125,331,332),Rect2(650,125,292,330),Rect2(950,140,330,312),Rect2(1290,120,329,335),Rect2(0,535,318,345),Rect2(327,531,306,348),Rect2(647,520,310,359),Rect2(978,528,278,351),Rect2(1260,530,359,347)]
const MINION_RECTS := [Rect2(40,55,328,340),Rect2(458,45,304,355),Rect2(840,18,300,377),Rect2(1190,95,354,298),Rect2(1620,90,330,307),Rect2(15,420,344,360),Rect2(465,412,265,372),Rect2(832,408,304,373),Rect2(1206,410,320,370),Rect2(1550,421,420,355)]
const PROP_RECTS := [Rect2(72,2,267,384),Rect2(476,2,269,381),Rect2(850,1,271,382),Rect2(1252,0,273,386),Rect2(1676,3,228,382),Rect2(70,387,261,402),Rect2(460,386,273,402),Rect2(850,384,273,401),Rect2(1251,384,266,397),Rect2(1652,388,282,399)]
const SPELL := preload("res://assets/shaders/realm_spell.gdshader")
const FLOOR := preload("res://assets/shaders/realm_floor.gdshader")
static var _regions: Dictionary = {}

static func actor_texture(element: String, boss: bool) -> Texture2D:
	if VisualStyle.is_pixel(): return null
	var index := ORDER.find(element)
	if index < 0: return null
	var key := "%s/%s" % ["boss" if boss else "minion",element]
	if _regions.has(key): return _regions[key]
	var source := "res://assets/authored/realms/demon-bosses-v3.png" if boss else "res://assets/authored/realms/demon-minions-v3.png"
	if not ResourceLoader.exists(source): return null
	var atlas := load(source) as Texture2D
	if atlas == null: return null
	var region := AtlasTexture.new()
	region.atlas = atlas
	region.region = BOSS_RECTS[index] if boss else MINION_RECTS[index]
	region.filter_clip = true
	_regions[key] = region
	return region

static func spell_material(element: String, projectile: bool = false) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SPELL
	material.set_shader_parameter("tint",Color(str(ElementDB.get_element(element).get("glow","#c299ff"))))
	material.set_shader_parameter("element",maxi(0,ORDER.find(element)))
	material.set_shader_parameter("projectile",projectile)
	return material

static func prop_texture(element: String) -> Texture2D:
	if VisualStyle.is_pixel(): return null
	var index := ORDER.find(element)
	if index < 0: return null
	var key := "prop/"+element
	if _regions.has(key): return _regions[key]
	var source := "res://assets/authored/realms/realm-props-v2.png"
	if not ResourceLoader.exists(source): return null
	var atlas := load(source) as Texture2D
	var region := AtlasTexture.new()
	region.atlas = atlas
	region.region = PROP_RECTS[index]
	region.filter_clip = true
	_regions[key] = region
	return region

static func quad() -> Texture2D:
	return PixelArt.cached_texture("realms/white_quad/v1",func() -> Image:
		var image := PixelArt.image(2,2)
		image.fill(Color.WHITE)
		return image)

static func impact_ring() -> Texture2D:
	return PixelArt.cached_texture("realms/impact_ring/v1",func() -> Image:
		var image := PixelArt.image(128,128)
		for y in 128:
			for x in 128:
				var radius := Vector2(x+0.5-64,y+0.5-64).length()/64.0
				var alpha := exp(-pow((radius-0.76)*27.0,2.0))*0.9+exp(-pow((radius-0.76)*7.0,2.0))*0.16
				image.set_pixel(x,y,Color(1,1,1,minf(1,alpha)))
		return image)

static func weapon_arc(kind: String) -> Texture2D:
	return PixelArt.cached_texture("realms/weapon_arc/%s/v1"%kind,func() -> Image:
		var image := PixelArt.image(128,128)
		for y in 128:
			for x in 128:
				var point := Vector2(x+0.5-47,y+0.5-64)
				var angle := point.angle()
				var radius := point.length()
				var taper := pow(maxf(0.0,1.0-absf(angle)/1.4),0.65)
				var distance := absf(radius-52.0)
				var core := exp(-pow(distance/2.0,2.0))*taper
				var glow := exp(-pow(distance/8.0,2.0))*taper*0.35
				if kind == "thrust":
					core = exp(-pow(point.y/2.0,2.0))*smoothstep(0,20,point.x)
					glow = exp(-pow(point.y/7.0,2.0))*0.2
				var alpha := clampf(core+glow,0.0,1.0)
				image.set_pixel(x,y,Color(1.0,0.83+core*0.17,0.48+core*0.52,alpha))
		return image)

static func floor_material(element: String) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = FLOOR
	var definition := ElementDB.get_element(element)
	material.set_shader_parameter("tint",Color(str(definition.get("floor","#473c57"))).lightened(0.35))
	material.set_shader_parameter("accent",Color(str(definition.get("glow","#c299ff"))))
	material.set_shader_parameter("element",maxi(0,ORDER.find(element)))
	return material
