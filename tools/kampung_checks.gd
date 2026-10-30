class_name KampungChecks
extends RefCounted
## Authored occupation/parcel regressions; all queries use synchronized physics.
static func run(game: Game, check: Callable) -> void:
	var lobby := game.world as Lobby
	var layout := lobby._layout
	var planner := ResidentRoutes.new(lobby)
	planner.clearance = WorldLayout.ACTOR_CLEARANCE
	check.call(layout.crowded_buildings().is_empty(), "districts: full building footprints have deliberate breathing room: " + str(layout.crowded_buildings()))
	var residences := 0
	for anchor in layout.anchors:
		var kind := str(anchor.get("kind", ""))
		if kind == "residence" and anchor.get("zone", "") == "residential": residences += 1
		if kind in ["residence", "shop", "garden"]:
			check.call(layout.zone_at(anchor.position) == anchor.get("zone", ""), "districts: destination sits in its declared district: " + str(anchor.id))
		if kind == "decoration":
			var owner := str(anchor.get("relative_to", ""))
			var detail := {"parent": owner, "position": layout.position_of(str(anchor.id)) - layout.position_of(owner), "footprint": anchor.get("footprint", Rect2(-0.4, -0.3, 0.8, 0.3))}
			check.call(layout.scenery_fits(detail), "districts: movable default prop avoids public circulation: " + str(anchor.id))
	check.call(residences == 5, "districts: five ordinary households share the eastern residential area")
	var commercial_right := -INF
	var residential_left := INF
	for anchor in layout.anchors:
		var kind := str(anchor.get("kind", ""))
		var plot := layout.world_footprint(str(anchor.id))
		if kind == "shop":
			commercial_right = maxf(commercial_right, plot.end.x)
			check.call(anchor.position.x < 22, "districts: every shop stays in the western quarter: " + str(anchor.id))
		elif kind in ["house", "residence"]:
			residential_left = minf(residential_left, plot.position.x)
			check.call(anchor.position.x >= 30, "districts: every occupied home stays in the east: " + str(anchor.id))
	check.call(residential_left - commercial_right >= 10, "districts: at least ten world units separate all shop and home footprints")
	check.call(layout.zone_at(Vector2(25, 19)) == "village_green", "districts: a landscaped green, not more buildings, occupies the central separation")
	for id in ["shop_potion", "shop_equipment", "shop_pet", "shop_house", "shop_services"]:
		check.call(layout.anchor(id).get("zone", "") == "market", "districts: merchant belongs to shared commercial district: " + id)
	for detail in layout.scenery:
		check.call(layout.scenery_fits(detail), "districts: authored accessory keeps roads, doorways and neighbouring plots clear: " + str(detail.get("id", "")))
	var parcel_ids: Array[String] = []
	for entry in layout.anchors:
		if entry.get("kind", "") in ["house", "shop", "residence", "ruin"]: parcel_ids.append(str(entry.id))
	var overlaps := PackedStringArray()
	for i in parcel_ids.size():
		for j in range(i + 1, parcel_ids.size()):
			if layout.world_footprint(parcel_ids[i]).intersects(layout.world_footprint(parcel_ids[j])):
				overlaps.append(parcel_ids[i] + "/" + parcel_ids[j])
	check.call(overlaps.is_empty(), "kampung: complete building plots do not overlap: " + str(overlaps))
	for entry in layout.activity_records():
		var points := layout.activity_points(entry)
		if entry.get("kind", "") in ["boat", "water_keeper"]: continue
		var clear := not points.is_empty()
		for at in points:
			clear = clear and planner.point_clear(at)
		check.call(clear, "kampung: activity points occupy clear land: " + str(entry.id))
		if entry.get("kind", "") != "resident": continue
		var reachable := true
		for at in points:
			reachable = reachable and not planner.path(layout.position_of("arrival"), at, false).is_empty()
		check.call(reachable, "kampung: exact work destinations reachable: " + str(entry.id))
	var squeezed := layout.copy_layout()
	squeezed.anchor("shop_pet").position = squeezed.position_of("shop_equipment") + Vector2(0, 3.7)
	check.call(not squeezed.crowded_buildings().is_empty(), "districts: validator rejects non-overlapping buildings with too little space")
	var blocked_accessory := {"position": layout.position_of("arrival"), "footprint": Rect2(-0.3, -0.3, 0.6, 0.6)}
	check.call(not layout.scenery_fits(blocked_accessory), "districts: scenery validator rejects clutter in the arrival court")
	var saved_prop := layout.resolved([], {"crate_1": [40.0, 24.0]})
	check.call(saved_prop.position_of("crate_1") == Vector2(40, 24), "districts: player-owned decoration keeps its position above new defaults")
	var road_style := layout.copy_layout()
	road_style.routes[0].role = "informal"
	check.call(road_style.signature() != layout.signature(), "kampung: road hierarchy changes invalidate the terrain bake")
	var copy := layout.copy_layout()
	var original := layout.position_of("shop_house")
	var moved := layout.resolved([], {"shop_house": [original.x + 1.0, original.y + 0.5]})
	check.call(moved.activity_points(moved.activity("Rami"))[0].distance_to(layout.activity_points(layout.activity("Rami"))[0] + Vector2(1, 0.5)) < 0.001, "kampung: workshop routine follows saved owner")
	check.call(moved.position_of("barrel_3").distance_to(layout.position_of("barrel_3") + Vector2(1, 0.5)) < 0.001, "kampung: local prop default follows its workshop")
	var independent := layout.resolved([], {"shop_house": [original.x + 1, original.y], "barrel_3": [40.0, 24.0]})
	check.call(independent.position_of("barrel_3") == Vector2(40, 24), "kampung: older independent prop save wins over relative default")
	copy.activities[0].points[0].offset += Vector2.ONE
	check.call(copy.activities != layout.activities, "kampung: activity copies are independent source data")
	var map := lobby._authored_map.copy_map()
	var snapshot := map.snapshot()
	map.layout.activities.clear()
	map.restore(snapshot)
	check.call(map.snapshot() == snapshot, "kampung: authoring undo restores complete activity data")
	var old := layout.copy_layout()
	old.activities.clear()
	check.call(old.activity_points(old.activity("Rami")) == layout.activity_points(layout.activity("Rami")), "kampung: old custom layouts inherit semantic routines")
	for kind in KampungArt.KINDS:
		check.call(KampungArt.texture(kind) != null and KampungArt.texture(kind) == KampungArt.texture(kind), "kampung: bounded cached artwork: " + kind)
	for kind in KampungArt.COMPOUND_KINDS:
		var image := KampungArt.draw(kind)
		check.call(image.get_size()==Vector2i(128,112) and image.get_used_rect().end.x<128 and image.get_used_rect().end.y<112, "kampung: compound retains frame and unclipped bounds: "+kind)
		check.call(image.get_data()==KampungArt.draw(kind).get_data(), "kampung: compound artwork is deterministic without placement RNG: "+kind)
	for kind in ["wakaf","garden_shed"]:
		var image := KampungArt.draw(kind)
		check.call(image.get_pixel(64,15).a>0.9 and image.get_pixel(64,37).a>0.9 and image.get_pixel(37,34)!=image.get_pixel(91,34), "kampung: compound ridge recedes in screen Y with two lit roof planes: "+kind)
		check.call(is_zero_approx(image.get_pixel(110,80).a), "kampung: compound has no extruded right wall: "+kind)
	check.call(is_zero_approx(KampungArt.draw("wakaf").get_pixel(64,72).a) and KampungArt.draw("garden_shed").get_pixel(64,72).a>0.9, "kampung: shelter keeps open centre while garden store has a closed shutter")
	await _walk_workers(lobby, check)
	# Exercise the same completion hook used by mouse and touch drags. No actor
	# assignment: replanning starts from the resident's existing fractional position.
	var workshop: SettlementPlaceable
	for node in lobby._placeables:
		if node.placeable_id == "shop_house": workshop = node
	check.call(lobby._settlement_editor.building_area.encloses(Rect2(workshop.position - workshop.selection_size * 0.5, workshop.selection_size)), "kampung: workshop selection fits settlement edit area without pickup clamping")
	var carpenter: Resident
	for resident in lobby._residents:
		if resident.resident_name == "Rami": carpenter = resident
	for placeable in lobby._placeables:
		if placeable.category != "shop": continue
		check.call(lobby._settlement_editor.building_area.encloses(Rect2(placeable.position - placeable.selection_size * 0.5, placeable.selection_size)), "districts: relocated shop fits the settlement editor: " + placeable.placeable_id)
	var editor := lobby._settlement_editor
	editor._selected = workshop
	editor._dragging = true
	editor._grab_offset = Vector2.ZERO
	editor._drag(Vector2(10, 30))
	check.call(workshop.position == original, "districts: expanded settlement editor rejects dragging a shop base into the sea")
	editor._selected = null
	editor._dragging = false
	var before := carpenter.position
	var before_route := carpenter.waypoints.duplicate()
	workshop.position += Vector2(0.5, 0)
	GameState.set_placeable_position("shop_house", workshop.position)
	lobby.refresh_spatial_layout()
	check.call(carpenter.position == before and carpenter.waypoints[0].distance_to(before_route[0] + Vector2(0.5, 0)) < 0.001, "kampung: settlement completion moves work destinations without teleporting workers")
	# Restore through the existing transaction; subsequent gate fixtures create a new game.
	workshop.position = original
	GameState.set_placeable_position("shop_house", original)
	lobby.refresh_spatial_layout()
	for frame in 6: await game.get_tree().physics_frame
	print("KAMPUNG_SPATIAL ", JSON.stringify(metrics(layout)))
	GameState.new_game("qayyim")
	game.call("_load_lobby", false)
	for frame in 4: await game.get_tree().physics_frame

static func metrics(layout: WorldLayout) -> Dictionary:
	var length := 0.0
	var routes := {}
	for route in layout.routes:
		var points := layout.route_points(route)
		var total := 0.0
		for i in points.size() - 1: total += points[i].distance_to(points[i + 1])
		length += total
		routes[str(route.id)] = snappedf(total, 0.01)
	var plots := 0.0
	for entry in layout.anchors:
		if entry.get("kind", "") in ["house", "shop", "residence", "ruin"]: plots += layout.world_footprint(str(entry.id)).get_area()
	var shop_distances := {}
	for id in ["shop_potion", "shop_equipment", "shop_pet", "shop_house", "shop_services"]:
		shop_distances[id] = snappedf(layout.approach(id).distance_to(layout.position_of("arrival")), 0.01)
	return {"bounds": [64, 40], "anchors": layout.anchors.size(), "routes": layout.routes.size(), "activities": layout.activities.size(), "scenery": layout.scenery.size(), "route_length": length, "building_plot_area": plots, "arrival_shop_direct_distances": shop_distances, "route_lengths": routes}


static func _walk_workers(lobby: Lobby, check: Callable) -> void:
	var workers: Array[Resident] = []
	var goals: Array[Vector2] = []
	var arrived: Array[bool] = []
	var continuous: Array[bool] = []
	for resident in lobby._residents:
		resident.set_physics_process(false)
		if not resident.has_meta("activity_id") or resident.role == "water_keeper": continue
		workers.append(resident)
		goals.append(resident.waypoints[-1])
		arrived.append(false)
		continuous.append(true)
		resident._path_goal = Vector2(INF, INF)
	for frame in 600:
		await lobby.get_tree().physics_frame
		var complete := true
		for i in workers.size():
			if arrived[i]: continue
			var worker := workers[i]
			var before := worker.position
			var delta := worker.get_physics_process_delta_time()
			arrived[i] = worker._walk_to(goals[i], worker.speed, delta)
			continuous[i] = continuous[i] and before.distance_to(worker.position) <= worker.speed * delta + 0.005
			complete = complete and arrived[i]
		if complete: break
	for i in workers.size():
		check.call(arrived[i], "kampung: worker physically reaches authored destination: " + workers[i].resident_name)
		check.call(continuous[i], "kampung: worker moves continuously without jumps: " + workers[i].resident_name)
