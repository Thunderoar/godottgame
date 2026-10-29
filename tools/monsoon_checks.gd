class_name MonsoonChecks
extends RefCounted
## Protect visual ownership, original forest associations, palettes and clock edges.
static func run(game: Game, check: Callable) -> void:
	var lobby := game.world as Lobby
	var expected: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tools/fixtures/monsoon_forest.json"))
	var unchanged := lobby._forest_trees.size() == expected.size()
	for i in mini(expected.size(), lobby._forest_trees.size()):
		var tree := lobby._forest_trees[i]
		var record: Dictionary = expected[i]
		unchanged = unchanged and tree.tree_id == str(record.id) and tree.max_health == int(record.hp) and tree.position.distance_to(Vector2(float(record.position[0]), float(record.position[1]))) < 0.0001
	check.call(unchanged, "Monsoon preserves every original forest ID, creation order, position and maximum HP")
	var palette := WorldPalette.current()
	check.call(palette.title == "Monsoon Afterglow", "shipped village selects Monsoon Afterglow in runtime and authored map")
	check.call(WorldPalette.color("leaf_mint").get_luminance() > WorldPalette.color("leaf").get_luminance() and WorldPalette.color("leaf").get_luminance() > WorldPalette.color("leaf_deep").get_luminance(), "foliage ramp separates upper leaves, leaf body and deep interior")
	var work_props := ["fishing_net", "timber", "bucket", "lantern", "baskets", "planter", "rope", "tools", "feed", "driftwood", "bench"]
	var prop_hashes := {}
	for kind in work_props:
		var texture := WorldComposition.texture(kind)
		var image := texture.get_image()
		var height := 48 if kind in ["rope", "tools", "feed", "driftwood", "bench"] else 64
		check.call(image.get_size() == Vector2i(64, height), "workspace %s retains native frame and placement pivot" % kind)
		check.call(texture == WorldComposition.texture(kind), "workspace %s reuses its existing cache route" % kind)
		var bounds := image.get_used_rect()
		check.call(bounds.position.x > 0 and bounds.position.y > 0 and bounds.end.x < 64 and bounds.end.y < height, "workspace %s has unclipped transparent clearance" % kind)
		prop_hashes[image.get_data().hex_encode().sha256_text()] = true
	check.call(prop_hashes.size() == work_props.size(), "eleven work props remain visually distinct")
	var silhouettes := {}
	for species in MonsoonArt.TREE_SIZES.size():
		var full := MonsoonArt.tree_texture(species).get_image()
		var upper := MonsoonArt.tree_texture(species, "upper").get_image()
		var lower := MonsoonArt.tree_texture(species, "lower").get_image()
		var assembled := PixelArt.image(full.get_width(), full.get_height())
		assembled.blit_rect(upper, Rect2i(Vector2i.ZERO, upper.get_size()), Vector2i.ZERO)
		assembled.blit_rect(lower, Rect2i(Vector2i.ZERO, lower.get_size()), Vector2i(0, upper.get_height()))
		check.call(assembled.get_data() == full.get_data(), "tree family %d split preserves pixels and trunk/crown pivot" % species)
		var bounds := full.get_used_rect()
		check.call(bounds.position.x > 0 and bounds.position.y > 0 and bounds.end.x < full.get_width() and bounds.end.y < full.get_height(), "tree family %d has transparent clearance without clipped silhouettes" % species)
		silhouettes[str(bounds) + str(full.get_size())] = true
	check.call(silhouettes.size() == MonsoonArt.TREE_SIZES.size(), "all five tree families have distinct silhouette bounds and proportions")
	for level in range(1, 6):
		check.call(PixelArt.house_texture(level).get_size() == Vector2(224, 176) and MonsoonArt.house(level, true).get_used_rect().has_area(), "cottage tier %d retains frame footprint and dedicated night windows" % level)
	var house_variants := {}
	for level in range(1, 6):
		var painted := MonsoonArt.house(level)
		var mask := MonsoonArt.house(level, true)
		check.call(painted.get_pixel(110, 30).a > 0.9 and painted.get_pixel(110, 80).a > 0.9 and painted.get_pixel(70, 90) != painted.get_pixel(154, 90), "approved cottage tier %d retains receding ridge and two roof planes" % level)
		check.call(is_zero_approx(painted.get_pixel(191, 135).a) and is_zero_approx(mask.get_pixel(112, 129).a) and mask.get_pixel(65, 129).a > 0.9 and mask.get_pixel(149, 129).a > 0.9, "cottage tier %d has no extra side wall and dedicated front window emission" % level)
		house_variants[painted.get_data().hex_encode().hash()] = true
	check.call(house_variants.size() == 5, "five cottage material grades are visually distinct within the same approved projection")
	var ground := lobby.house_sprite.get_parent().get_node_or_null("CottageGround") as Sprite2D
	check.call(is_instance_valid(ground) and ground.visible and ground.texture.get_size() == Vector2(384, 256), "Classic Pixel cottage owns one static native ground-detail layer")
	var ground_image := MonsoonArt.cottage_ground()
	check.call(ground_image.get_data() == MonsoonArt.cottage_ground().get_data(), "yard clusters use their own reproducible decorative stream")
	var cottage := lobby.house_sprite.get_parent() as Node2D
	var before_position := cottage.position
	cottage.position = Vector2(5, 39)
	lobby._refresh_cottage_ground(cottage)
	check.call(not ground.texture.get_image().get_used_rect().has_area(), "yard painting clips entirely off sea without changing coastline or collision")
	cottage.position = before_position
	lobby._refresh_cottage_ground(cottage)
	for variant in 6:
		var understory := MonsoonArt.undergrowth(variant)
		check.call(understory.get_size()==Vector2i(40,32) and understory.get_data()==MonsoonArt.undergrowth(variant).get_data(),"understory family %d keeps native bounds and deterministic material clusters" % variant)
	var market_signatures := {}
	for kind in ["potion","equipment","pet","house","services"]:
		var stall := MonsoonArt.stall(kind)
		var front := MonsoonArt.stall_front(kind)
		check.call(stall.get_size()==Vector2i(112,96) and PixelArt.stall_texture(kind).get_size()==Vector2(112,96), "%s market art retains the existing native frame and cache route" % kind)
		check.call(stall.get_used_rect().position.x>0 and stall.get_used_rect().position.y>0 and stall.get_used_rect().end.x<112 and stall.get_used_rect().end.y<96, "%s canopy and goods have transparent silhouette clearance" % kind)
		check.call(stall.get_pixel(30,24)!=stall.get_pixel(82,24) and stall.get_pixel(56,12).a>0.9, "%s canopy reads as two projected roof planes with a receding ridge" % kind)
		var subset := true
		for y in 96:
			for x in 112:
				if front.get_pixel(x,y).a>0.0:subset=subset and front.get_pixel(x,y)==stall.get_pixel(x,y)
		check.call(subset and is_zero_approx(front.get_pixel(56,48).a) and front.get_pixel(56,70).a>0.9, "%s unchanged merchant occupies the opening behind the counter foreground" % kind)
		market_signatures[stall.get_data().hex_encode().hash()]=true
	check.call(market_signatures.size()==5,"all five market occupations retain distinct cloth and purposeful goods")
	var potion_shop := lobby.get_node("PotionShop") as Node2D
	var yard := potion_shop.get_node("StallGround") as Sprite2D
	check.call(yard.visible and yard.texture.get_size()==Vector2(192,160),"native stall owns a bounded noncolliding ground layer")
	var shop_position := potion_shop.position
	potion_shop.position=Vector2(5,39)
	lobby._refresh_shop_ground(potion_shop,"potion")
	check.call(not yard.texture.get_image().get_used_rect().has_area(),"shop frontage clips off sea using a copied image")
	potion_shop.position=shop_position
	lobby._refresh_shop_ground(potion_shop,"potion")
	check.call(MonsoonArt.shop_ground("potion").get_data()==MonsoonArt.shop_ground("potion").get_data(),"market ground details are reproducible without gameplay RNG")
	var time_before := float(GameState.data.get("world_time", 0.0))
	for boundary in [0.0, 133.0, 180.0, 193.0, 340.0, 360.0]:
		var before := MonsoonLighting.grade(boundary - 0.001)
		var after := MonsoonLighting.grade(boundary + 0.001)
		check.call(Vector3(before.r, before.g, before.b).distance_to(Vector3(after.r, after.g, after.b)) < 0.001, "lighting remains continuous at world-clock boundary %d" % boundary)
	check.call(is_zero_approx(MonsoonLighting.lantern_strength(50.0)) and MonsoonLighting.lantern_strength(210.0) > 0.99 and time_before == float(GameState.data.get("world_time", 0.0)), "lanterns follow the existing clock without advancing or mutating gameplay time")
	var imported := AssetRegistry.get_texture("coastal/planter")
	var imported_pixels := imported.get_image().get_data()
	var original := load("res://data/palettes/coast.tres") as WorldPalette
	var tree_before := MonsoonArt.tree_texture(0)
	WorldPalette.use_palette(original)
	var tree_after := MonsoonArt.tree_texture(0)
	check.call(tree_before != tree_after and WorldPalette.color("leaf_mint") != Color.MAGENTA, "previous palettes derive new semantic roles and invalidate generated artwork")
	check.call(imported_pixels == AssetRegistry.get_texture("coastal/planter").get_image().get_data(), "palette preview leaves imported source artwork untouched")
	WorldPalette.use_palette(palette)
	var catalog := AssetRegistry.library()
	var replacement := catalog.duplicate(true) as AssetCatalog
	replacement.entries["house_1"] = catalog.entries["coastal/planter"].duplicate(true)
	replacement.entries["stall_potion"] = catalog.entries["coastal/planter"].duplicate(true)
	replacement.entries["authored_tree"] = catalog.entries["coastal/planter"].duplicate(true)
	var legacy_upper := "res://assets/sprites/TX Plant__TX Tree T1 Upper.tres"
	replacement.entries["foliage/" + legacy_upper] = catalog.entries["coastal/planter"].duplicate(true)
	for kind in work_props: replacement.entries["village/" + kind] = catalog.entries["coastal/planter"].duplicate(true)
	AssetRegistry.catalog = replacement
	AssetRegistry.invalidate()
	for kind in work_props: check.call(WorldComposition.texture(kind) == AssetRegistry.get_texture("village/" + kind), "workspace %s explicit imported override remains authoritative" % kind)
	lobby._add_window_lights(lobby.house_sprite, 1)
	lobby._refresh_shop_ground(potion_shop,"potion")
	check.call(PixelArt.stall_texture("potion")==AssetRegistry.get_texture("stall_potion") and not yard.visible and not potion_shop.get_node("StallFront").visible,"explicit stall replacement owns its art, foreground and yard")
	check.call(PixelArt.authored_tree_texture() == AssetRegistry.get_texture("authored_tree"), "existing authored_tree semantic overrides retain priority")
	# Unparented construction checks a legacy override without running a world or
	# assigning any additional persistent tree state in the active game.
	var fixture := Lobby.new()
	fixture._add_tree(Vector2(54, 8), legacy_upper, "unused_lower", 1.0)
	var canopy := fixture._forest_trees[0]._visuals[1] as Sprite2D
	check.call(canopy.texture == AssetRegistry.get_texture("foliage/" + legacy_upper), "legacy foliage overrides remain authoritative on existing forest trees")
	fixture.free()
	check.call(not lobby.house_sprite.get_node("WarmWindows").visible, "imported house overrides never receive a procedural window mask")
	check.call(not ground.visible, "explicit house replacement also owns its ground presentation")
	AssetRegistry.catalog = catalog
	AssetRegistry.invalidate()
	lobby._add_window_lights(lobby.house_sprite, GameState.house_level())
	lobby._refresh_shop_ground(potion_shop,"potion")
	var cached := WorldTerrain._make_terrain_texture()
	check.call(cached == WorldTerrain._make_terrain_texture(), "unchanged palettes reuse the whole terrain texture")
	var quality := GameSettings.effects_quality()
	var motion := GameSettings.reduce_motion()
	for tier in ["low", "med", "high"]:
		GameSettings.set_effects_quality(tier, false)
		GameSettings.set_reduce_motion(true, false)
		check.call(cached == WorldTerrain._make_terrain_texture() and not lobby.get_node("WaterLayer").visible, "%s reduced motion retains the same complete static terrain and water" % tier)
	var ship := lobby.get_node("MooredShip") as Sprite2D
	var boat_motion: Tween = ship.get_meta("ambient_tween")
	check.call(not boat_motion.is_running(), "Reduce Motion pauses the existing boat tween immediately")
	GameSettings.set_reduce_motion(false, false)
	GameSettings.set_effects_quality("low", false)
	check.call(not boat_motion.is_running(), "Low quality pauses optional boat motion after a live settings change")
	GameSettings.set_effects_quality("high", false)
	check.call(boat_motion.is_running(), "High quality restores the same owned boat tween")
	GameSettings.set_effects_quality(quality, false)
	GameSettings.set_reduce_motion(motion, false)
