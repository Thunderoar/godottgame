extends RefCounted
## The physical pixels must stay detailed without changing gameplay footprints.
static func run(_game: Game, check: Callable) -> void:
	var keys := {"house_1":Vector2i(224,176),"house_5":Vector2i(224,176),"stall_potion":Vector2i(112,96),"shop_interior_equipment":Vector2i(448,84),"character_adam_0_0":Vector2i(32,48),"character_arjun_2_1":Vector2i(32,48),"character_mei_ling_1_0":Vector2i(32,48),"pet_ember_0":Vector2i(32,32),"ship":Vector2i(208,128),"coast/turtle/false":Vector2i(96,48),"coast/turtle_food/v1":Vector2i(32,24),"campaign/sea_bomb/v1":Vector2i(32,32),"boss/kraken_king/v3":Vector2i(160,144)}
	for key in keys:
		var texture := RealisticArt.get_texture(key)
		if VisualStyle.is_pixel():
			check.call(texture == null, "%s permits original procedural pixels in Classic style" % key)
		else:
			check.call(texture!=null and texture.get_size()==Vector2(keys[key]) and texture.get_image().get_height()>keys[key].y,"%s retains its gameplay size with detailed imported pixels" % key)
	var animation := RealisticArt.get_texture("character_adam_2_0")
	check.call(animation==RealisticArt.get_texture("character_adam_2_3"),"moving hero reuses one bounded physical view instead of creating frame textures")
	var homes := {}
	for level in range(1,6):
		var texture := PixelArt.house_texture(level)
		homes[texture.get_image().get_data().hex_encode().sha256_text()]=true
	check.call(homes.size()==5,"five house tiers keep distinct silhouettes in the active style")
	var pets := {}
	for id in RealisticArt.PETS:
		var texture := PixelArt.pet_texture(id)
		pets[texture.get_image().get_data().hex_encode().sha256_text()]=true
	check.call(pets.size()==8,"all eight companion and opponent appearances remain distinct")
	for kind in RealisticArt.SHOPS:
		var modern := not VisualStyle.is_pixel()
		check.call(PixelArt.stall_texture(kind).get_meta("realistic_art",false) == modern and PixelArt.shop_interior_texture(kind).get_meta("realistic_art",false) == modern,"%s shop has matching active-style exterior and interior" % kind)
	var kraken := KrakenKing.new()
	_game.world.add_child(kraken)
	kraken.set_physics_process(false)
	var rest := kraken._sprite_rest_scale()
	kraken._enter(Enemy.State.WINDUP)
	kraken._pose_tween.custom_step(0.1)
	kraken._update_body()
	var ratio := kraken.sprite.scale/rest
	var bounded := ratio.x>0.85 and ratio.x<1.13 and ratio.y>0.85 and ratio.y<1.13
	kraken._enter(Enemy.State.RECOVER)
	check.call(bounded and kraken.sprite.scale.is_equal_approx(rest),"Kraken texture refresh preserves bounded wind-up size and exact recovery")
	kraken.queue_free()
	await _game.get_tree().process_frame
