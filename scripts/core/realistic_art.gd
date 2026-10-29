@tool
class_name RealisticArt
extends RefCounted
## Imported physical pixels retain old logical dimensions. Animation, feet,
## collision and atlas-independent widget sizing keep one consistent contract.
const ROOT := "res://assets/authored/realistic/"
const SHOPS := ["potion","equipment","pet","house","services"]
const PETS := ["ember","moss","luma","sparring_ember","bramble_cat","dusk_moth","storm_fox","tidecat_sovereign"]
const TREE_SIZES := [Vector2i(104,128),Vector2i(116,120),Vector2i(84,144),Vector2i(96,116),Vector2i(112,144)]
static var _regions: Dictionary = {}
static var _images: Dictionary = {}
static var _textures: Dictionary = {}
static var _loaded := false
static var _generation := -1

static func _record(key: String) -> Array:
	if key.begins_with("house_") and key.trim_prefix("house_").is_valid_int(): return ["buildings",clampi(int(key.trim_prefix("house_"))-1,0,4),Vector2i(224,176)]
	if key.begins_with("stall_"): return ["buildings",5+maxi(0,SHOPS.find(key.trim_prefix("stall_"))),Vector2i(112,96)]
	if key.begins_with("shop_interior_"): return ["interiors",maxi(0,SHOPS.find(key.trim_prefix("shop_interior_"))),Vector2i(448,84)]
	if key.begins_with("bust_"): return ["residents",maxi(0,SHOPS.find(key.get_slice("_",1))),Vector2i(72,88),"bust"]
	if key.begins_with("npc_"):
		var role := key.trim_prefix("npc_")
		var index := 8
		if role in ["water","water_keeper","water_worker"]: index=5
		elif role in ["gardener","planter","tree_planter"]: index=6
		elif role in ["builder","construction","construction_worker"]: index=7
		elif role == "carpenter": index=3
		elif role in ["swordsman","fighter"]: return ["heroes",0,Vector2i(24,36)]
		elif role in ["fisher","fisherman"]: index=9
		elif role in SHOPS: index=SHOPS.find(role)
		return ["residents",index,Vector2i(24,36)]
	if key.begins_with("character_"):
		var parts := key.split("_")
		var hero := ["adam","arjun","mei_ling"].find("mei_ling" if key.begins_with("character_mei_ling_") else str(parts[1]))
		var facing := int(parts[parts.size()-2])
		return ["heroes",maxi(0,hero)*4+[0,2,1,3][posmod(facing,4)],Vector2i(32,48)]
	if key.begins_with("portrait_"):
		var hero := 2 if key.begins_with("portrait_mei_ling_") else maxi(0,["adam","arjun"].find(key.get_slice("_",1)))
		var size := int(key.get_slice("_",key.get_slice_count("_")-1))
		return ["heroes",hero*4,Vector2i(size,size),"portrait"]
	if key.begins_with("pet_"):
		for i in PETS.size():
			if key.begins_with("pet_"+PETS[i]+"_"): return ["pets",i,Vector2i(32,32)]
	if key.begins_with("monsoon/tree/"):
		var species := posmod(int(key.get_slice("/",2)),5)
		if species in [1,2]: return ["trees-pair",species-1,TREE_SIZES[species],key.get_slice("/",3)]
		return ["vegetation",species,TREE_SIZES[species],key.get_slice("/",3)]
	if key == "authored_tree": return ["vegetation",0,TREE_SIZES[0]]
	if key.begins_with("monsoon/undergrowth/") or key.begins_with("coastal_grass_"): return ["vegetation",5+posmod(int(key.get_slice("/",2) if "/" in key else key.get_slice("_",2)),4),Vector2i(40,32)]
	if key == "grass_tuft": return ["vegetation",5,Vector2i(16,12)]
	if key.begins_with("monsoon/props/"):
		return _prop_record(key.get_slice("/",2),Vector2i(64,64))
	if key.begins_with("kampung/"):
		var kind := key.get_slice("/",1)
		if kind in ["banana","herbs","moon_flower"]: return ["vegetation",{"banana":9,"herbs":10,"moon_flower":14}[kind],Vector2i(128,112)]
		return _prop_record(kind,Vector2i(128,112))
	if key.begins_with("coastal/"): return _prop_record(key.get_slice("/",1),Vector2i(48,48))
	if key == "ship": return ["village-props",3,Vector2i(208,128)]
	if key == "dock": return ["village-props",4,Vector2i(256,96)]
	if key.begins_with("fence_tier_"): return ["village-props",0,Vector2i(48,32)]
	if key == "besut_sign_board": return ["village-props",5,Vector2i(104,54)]
	if key == "garden": return ["vegetation",10,Vector2i(64,32)]
	if key == "bed": return ["details",5,Vector2i(64,40)]
	if key == "realistic/home_table": return ["details",7,Vector2i(64,64)]
	if key == "coast/northern_cliff/v1": return ["stone-floor",0,Vector2i(64,64)]
	if key == "coastal_net": return ["household",4,Vector2i(16,16)]
	if key.begins_with("pb_archer_hut_"): return ["village-props",11,Vector2i(80,96)]
	if key.begins_with("animal_horse_"): return ["household",3,Vector2i(20,20)]
	if key.begins_with("animal_"): return ["details",{"chicken":0,"duck":1,"cat":2,"dog":3}.get(key.get_slice("_",1),0),Vector2i(20,20)]
	if key.begins_with("rubbish_"): return ["details",14,Vector2i(16,16)]
	if key.begins_with("roof_gun_"): return ["details",13,Vector2i(48,32)]
	if key.begins_with("pb_home_decor_"):
		if "wardrobe" in key: return ["details",6,Vector2i(64,64)]
		return ["household",0 if "chest" in key else (1 if "weapons" in key else 2),Vector2i(64,64)]
	if key.begins_with("enemy_urchin_"): return ["ocean",13,Vector2i(32,32)]
	if key.begins_with("enemy_fire_"): return ["fire-demon",0,Vector2i(32,32)]
	if key.begins_with("portal_frame_"): return ["gates",1 if "pet" in key else 0,Vector2i(80,112)]
	if key.begins_with("portal_") and not key.begins_with("portal_swirl_") and not key.begins_with("portal_emblem_"): return ["gates",0,Vector2i(80,112)]
	if key == "boss/kraken_king/v3": return ["kraken-set",0,Vector2i(160,144)]
	if key.begins_with("boss/arjun_prison/v2/"): return ["kraken-set",2 if key.ends_with("true") else 1,Vector2i(112,132)]
	if key.begins_with("coast/turtle/"): return ["ocean",1 if key.get_slice("/",2) == "true" else 0,Vector2i(96,48)]
	if key == "beach_turtle": return ["ocean",0,Vector2i(42,30)]
	if key == "coast/turtle_food/v1": return ["ocean",2,Vector2i(32,24)]
	if key == "campaign/sea_bomb/v1": return ["ocean",14,Vector2i(32,32)]
	if key.begins_with("ocean_life/"):
		var kind := key.get_slice("/",1)
		if kind in ["mermaid","diver"]: return ["ocean-bed",8 if kind == "mermaid" else 9,Vector2i(128,80)]
		var indexes := {"shark":4,"megalodon":3,"whale":7,"fish":2,"dolphin":5,"ray":6,"jellyfish":8,"seahorse":9,"crab":10,"octopus":11}
		return ["ocean",indexes.get(kind,12),Vector2i(128,80)]
	if key.begins_with("ocean_bed/"):
		var indexes := {"coral":0,"starfish":1,"chest":2,"pearl":3,"wreck":4,"kelp":5,"arch":6,"anemone":7}
		if key.get_slice("/",1) == "crab": return ["ocean",10,Vector2i(128,96)]
		return ["ocean-bed",indexes.get(key.get_slice("/",1),0),Vector2i(128,96)]
	return []

static func _prop_record(kind: String, logical: Vector2i) -> Array:
	if kind == "bucket": return ["details",9,logical]
	if kind == "fishing_net": return ["household",4,logical]
	if kind == "timber": return ["village-props",8,logical]
	if kind in ["planter","basket"]: return ["vegetation",8,logical]
	var indexes := {"fence":0,"bench":1,"lamp":2,"lantern":2,"sign":5,"barrel":6,"water_barrel":6,"crate":7,"driftwood":8,"well":9,"wakaf":10,"veranda":10,"garden_shed":11,"drying_rack":12,"clothesline":12,"trough":13,"parit":13,"sanctuary_arch":14,"sentinel":14,"companion_stone":14}
	if kind in ["flowers","flower","bush"]: return ["vegetation",8 if "flower" in kind else 7,logical]
	return ["village-props",indexes[kind],logical] if indexes.has(kind) else []

static func get_texture(key: String) -> Texture2D:
	if VisualStyle.is_pixel(): return null
	var record := _record(key)
	if record.is_empty(): return null
	if _generation != WorldPalette.generation:
		_textures.clear()
		_generation=WorldPalette.generation
	if not _loaded:
		_loaded=true
		if not FileAccess.file_exists(ROOT+"regions.json"): return null
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ROOT+"regions.json"))
		if parsed is Dictionary: _regions=parsed
	var sheet := str(record[0])
	var index := int(record[1])
	var logical: Vector2i = record[2]
	var part := str(record[3]) if record.size()>3 else "whole"
	var cache_key := "%s/%d/%s/%s/%d" % [sheet,index,logical,part,WorldPalette.generation]
	if _textures.has(cache_key): return _textures[cache_key]
	var entries: Array = _regions.get(sheet,[])
	if index>=entries.size() or (entries[index] as Array).size()!=4: return null
	if not _images.has(sheet):
		var source_path := ROOT+sheet+".png"
		if sheet == "fire-demon": source_path="res://assets/authored/realms/demon-minions-v3.png"
		elif sheet == "stone-floor": source_path="res://assets/authored/realms/basalt-floor-v2.png"
		if not ResourceLoader.exists(source_path): return null
		var imported := load(source_path) as Texture2D
		if imported == null: return null
		_images[sheet]=imported.get_image()
	var source: Image = _images[sheet]
	var box: Array = entries[index]
	var rectangle := Rect2i(int(box[0]),int(box[1]),int(box[2]),int(box[3]))
	if not Rect2i(Vector2i.ZERO,source.get_size()).encloses(rectangle): return null
	var pixels := source.get_region(rectangle)
	pixels.convert(Image.FORMAT_RGBA8)
	if part in ["bust","portrait"]:
		pixels=pixels.get_region(Rect2i(0,0,pixels.get_width(),maxi(1,int(pixels.get_height()*0.62))))
	var aspect := float(logical.x)/maxi(1,logical.y)
	var padding := 0 if sheet in ["interiors","stone-floor"] else 8
	var canvas_size := Vector2i(maxi(pixels.get_width()+padding*2,ceili((pixels.get_height()+padding*2)*aspect)),maxi(pixels.get_height()+padding*2,ceili((pixels.get_width()+padding*2)/aspect)))
	var canvas := Image.create_empty(canvas_size.x,canvas_size.y,false,Image.FORMAT_RGBA8)
	canvas.blit_rect(pixels,Rect2i(Vector2i.ZERO,pixels.get_size()),Vector2i((canvas_size.x-pixels.get_width())/2,canvas_size.y-pixels.get_height()-padding))
	if sheet == "stone-floor": canvas=pixels
	if part in ["upper","lower"]:
		var fraction := float(logical.y-46)/logical.y
		var split := roundi(canvas_size.y*fraction)
		canvas=canvas.get_region(Rect2i(0,0 if part=="upper" else split,canvas_size.x,split if part=="upper" else canvas_size.y-split))
		logical.y=logical.y-46 if part=="upper" else 46
	var texture := ImageTexture.create_from_image(canvas)
	texture.set_size_override(logical)
	texture.set_meta("realistic_art",true)
	texture.set_meta("realistic_sheet",sheet)
	if _textures.size()>512: _textures.clear()
	_textures[cache_key]=texture
	return texture
