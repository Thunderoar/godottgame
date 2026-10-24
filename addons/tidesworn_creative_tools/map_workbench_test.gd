@tool
extends RefCounted
## Native editor gestures and history, run only by the disposable-source harness.
static func run(panel: Control, check: Callable, output: String) -> void:
	var original: AuthoredMap = panel.map
	var old_path: String = panel.path
	var old_dirty: bool = panel.dirty
	var saved: Dictionary = panel._saved_snapshot
	var ui: Control = panel.workbench
	panel.map = (load("res://data/maps/village.tres") as AuthoredMap).copy_map()
	panel.path = "res://data/maps/editor_workbench.tres"
	panel._hidden = panel.map.editor_hidden
	panel._locked = panel.map.editor_locked
	panel._saved_snapshot = panel.map.snapshot()
	panel.dirty = false
	panel.tool.select(11)
	ui.clear_selection()
	panel.refresh()
	await panel.get_tree().process_frame
	panel._fit_map()
	var document: AuthoredMap = panel.map
	var initial := document.snapshot()
	var canonical := WorldLayout.village().anchors.duplicate(true)
	ui.select_feature("anchors", "shop_house")
	var start := document.resolved_layout().position_of("shop_house")
	_mouse(panel, start, true)
	_motion(panel, start + Vector2(0.75, 0.25))
	check.call(document.snapshot() == initial and not panel.canvas.edit_overlay.is_empty(), "workbench: drag previews an outline without mutating source or regenerating terrain")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	panel.canvas._gui_input(escape)
	_mouse(panel, start + Vector2(0.75, 0.25), false)
	check.call(document.snapshot() == initial and not panel.dirty, "workbench: Escape cancels a drag with no dirty state or history mutation")
	_gesture(panel, start, start + Vector2(0.75, 0.25))
	check.call(document.resolved_layout().position_of("shop_house") == start + Vector2(0.75, 0.25), "workbench: canvas gesture moves a protected shop through its canonical anchor")
	check.call(WorldLayout.village().anchors == canonical, "workbench: editing retains the shared source resource unchanged")
	panel._history_step(false)
	check.call(document.snapshot() == initial and not panel.dirty, "workbench: native undo returns to the saved state and clears dirty")
	panel._history_step(true)
	check.call(document.resolved_layout().position_of("shop_house") == start + Vector2(0.75, 0.25), "workbench: native redo restores direct canvas movement")
	ui.fields.position_x.value += 0.25
	ui.apply_properties()
	check.call(document.resolved_layout().position_of("shop_house") == start + Vector2(1, 0.25), "workbench: numeric inspector edits use the same resolved building placement")
	var nudge := InputEventKey.new()
	nudge.keycode = KEY_RIGHT
	nudge.pressed = true
	panel.canvas._gui_input(nudge)
	check.call(document.resolved_layout().position_of("shop_house") == start + Vector2(1.25, 0.25), "workbench: focused canvas arrows nudge precisely by a quarter unit")
	panel._history_step(false)
	ui.frame_selection()
	check.call(panel.canvas.zoom > 1, "workbench: frame selection zooms into the actual selected building")
	panel._fit_map()
	check.call(panel.canvas.pan.x >= 0 and panel.canvas.pan.y >= 0, "workbench: Fit map centres the complete canvas")
	panel.canvas_only.button_pressed = true
	await panel.get_tree().process_frame
	check.call(not ui.visible and not panel.inspector_scroll.visible, "workbench: canvas-only mode hides both sidebars")
	panel.canvas_only.button_pressed = false
	await panel.get_tree().process_frame
	ui.asset_search.text = "bench"
	ui.asset_search.text_changed.emit("bench")
	check.call(ui.assets.item_count >= 1 and ui.assets.get_item_icon(0) != null, "workbench: searchable asset palette provides real thumbnails")
	ui.assets.item_selected.emit(0)
	check.call(panel.tool.selected == 7 and panel.asset.text == "bench", "workbench: choosing a thumbnail arms the object placement tool (%s / %d)" % [panel.asset.text, panel.tool.selected])
	_mouse(panel, Vector2(28, 34), true)
	_mouse(panel, Vector2(28, 34), false)
	var id: String = document.objects[-1].id
	ui.select_feature("objects", id)
	var before_count := document.objects.size()
	var duplicate := InputEventKey.new()
	duplicate.keycode = KEY_D
	duplicate.ctrl_pressed = true
	duplicate.pressed = true
	panel.canvas._gui_input(duplicate)
	check.call(document.objects.size() == before_count + 1 and document.objects[-1].id != id and document.objects[-1].position == Vector2(29.5, 35.5), "workbench: Ctrl+D gives a placed prop a distinct identity and offset")
	ui.delete_selection()
	check.call(document.objects.size() == before_count, "workbench: deleting a selected prop removes the correct identity")
	panel._history_step(false)
	check.call(document.objects.size() == before_count + 1, "workbench: native undo restores a deleted prop")
	panel._history_step(true)
	ui.search.text = "shop_house"
	ui.search.text_changed.emit("shop_house")
	var root: TreeItem = ui.scene.get_root()
	var matches := 0
	for branch in root.get_children(): matches += branch.get_child_count()
	var found_house := false
	var only_matches := true
	for branch in root.get_children():
		for child in branch.get_children():
			found_house = found_house or child.get_metadata(0).id == "shop_house"
			only_matches = only_matches and str(child.get_metadata(0).id).contains("shop_house")
	check.call(matches >= 1 and found_house and only_matches, "workbench: scene search shows matching buildings and their accessories")
	ui.search.text = ""
	ui.search.text_changed.emit("")
	var tree_id := ""
	for entry in panel.base.objects:
		if str(entry.get("base_id", "")).begins_with("forest_"): tree_id = str(entry.id); break
	ui.select_feature("base", tree_id)
	var base_count := document.objects.size()
	var tree_at: Vector2 = ui.selected().position
	_gesture(panel, tree_at, tree_at + Vector2(0.25, 0))
	check.call(document.objects.size() == base_count + 1 and document.objects[-1].id == tree_id and document.objects[-1].has("base_id"), "workbench: an original tree move creates an independent stable-ID override")
	panel._history_step(false)
	check.call(document.objects.size() == base_count and WorldLayout.village().anchors == canonical, "workbench: undo removes a tree override without changing canonical forest data")
	var road: Dictionary = document.resolved_layout().routes[0]
	ui.select_feature("routes", str(road.id))
	var via_count: int = road.get("via", PackedVector2Array()).size()
	ui.insert_point(Vector2(30, 25))
	check.call(ui.selected().via.size() == via_count + 1, "workbench: inserting a road bend preserves endpoint bindings")
	ui.remove_point()
	check.call(ui.selected().via.size() == via_count, "workbench: removing a bend keeps the road itself")
	panel._history_step(false)
	check.call(ui.selected().via.size() == via_count + 1, "workbench: road point deletion participates in native undo")
	ui.fields.width.value = 2.6
	ui.apply_properties()
	check.call(is_equal_approx(float(ui.selected().width), 2.6), "workbench: road inspector changes the shared ground width")
	ui.frame_selection()
	await _screenshot(panel, output.path_join("workbench-road.png"))
	ui.select_feature("zones", "residential")
	var polygon: PackedVector2Array = ui.selected().polygon.duplicate()
	ui.point = 0
	_gesture(panel, polygon[0], polygon[0] + Vector2(0.25, 0.25))
	check.call(ui.selected().polygon[0] == polygon[0] + Vector2(0.25, 0.25), "workbench: a district handle reshapes the real polygon (%s → %s)" % [str(polygon[0]), str(ui.selected().polygon[0])])
	ui.select_feature("zones", "residential")
	ui.carry_district = true
	var before_district := document.snapshot()
	var home := document.resolved_layout().position_of("ResidentHouseWest")
	ui.category.select(3)
	_gesture(panel, Vector2(17, 15), Vector2(17.5, 15))
	check.call(document.resolved_layout().position_of("ResidentHouseWest") == home + Vector2(0.5, 0), "workbench: moving a district carries its households")
	check.call(WorldLayout.village().anchors == canonical, "workbench: district movement never rewrites the canonical forest fixture")
	panel._history_step(false)
	check.call(document.snapshot() == before_district, "workbench: district buildings, scenery and road bends undo as one transaction")
	ui.carry_district = false
	ui.category.select(0)
	ui.select_feature("activities", str(document.resolved_layout().activities[0].id))
	ui.point = 0
	panel.refresh()
	var old_point: Vector2 = document.resolved_layout().activity_points(ui.selected())[0]
	_gesture(panel, old_point, old_point + Vector2(0.25, 0))
	check.call(document.resolved_layout().activity_points(ui.selected())[0] == old_point + Vector2(0.25, 0), "workbench: dragging a workpoint preserves its owner-relative coordinate")
	var work_count: int = ui.selected().points.size()
	ui.insert_point(old_point + Vector2(0.5, 0))
	check.call(ui.selected().points.size() == work_count + 1, "workbench: work routines accept additional points")
	ui.remove_point()
	check.call(ui.selected().points.size() == work_count, "workbench: deleting a selected workpoint preserves the routine")
	panel.layer.select(0)
	panel._set_layer_flag("Terrain", "locked", true)
	panel.tool.select(0)
	panel._press(Vector2i(5, 5) * 8)
	panel._release(Vector2i(5, 5) * 8)
	check.call(document.cell("Terrain", Vector2i(5, 5)).is_empty(), "workbench: layer locks prevent paint through the canvas handler")
	panel._history_step(false)
	check.call(not panel._locked.get("Terrain", false), "workbench: layer lock undo restores actual paint permissions")
	panel._set_layer_flag("Decoration", "hidden", true)
	check.call(document.editor_hidden.get("Decoration", false), "workbench: layer visibility is stored in the undoable document")
	panel._history_step(false)
	check.call(not document.editor_hidden.get("Decoration", false), "workbench: visibility undo restores document and canvas settings")
	panel.tool.select(0)
	var before_cancel := document.snapshot()
	_mouse(panel, Vector2(4, 4), true)
	panel.canvas._gui_input(escape)
	_mouse(panel, Vector2(4, 4), false)
	check.call(document.snapshot() == before_cancel, "workbench: Escape also cancels an in-progress paint stroke")
	var space := InputEventKey.new()
	space.keycode = KEY_SPACE
	space.pressed = true
	panel.canvas._gui_input(space)
	_mouse(panel, Vector2(4, 4), true)
	space.pressed = false
	panel.canvas._gui_input(space)
	_mouse(panel, Vector2(4, 4), false)
	check.call(not panel.canvas._panning and document.snapshot() == before_cancel, "workbench: releasing Space before the mouse cannot leave pan stuck or paint a cell")
	ui._new_type.select(0)
	ui.create_feature(Vector2(29, 24.5))
	var commons_id: String = ui.identity
	check.call(ui.selected().kind == "landmark" and ui.selected().position == Vector2(29, 24.5), "workbench: new commons landmarks are authored anchors")
	ui._new_type.select(1)
	ui.create_feature(Vector2(30, 25))
	_select_choice(ui.fields.to, commons_id)
	ui.fields.width.value = 2.4
	ui.fields.feather.value = 0.3
	ui.apply_properties()
	check.call(ui.selected().to == commons_id and is_equal_approx(float(ui.selected().width), 2.4) and is_equal_approx(float(ui.selected().feather), 0.3), "workbench: new road connects directly to the newly authored commons")
	ui._new_type.select(2)
	ui.create_feature(Vector2(29, 24.5))
	check.call(ui.selected().polygon.size() == 4, "workbench: new district starts as an editable four-vertex region")
	ui.insert_point(Vector2(29, 21.5))
	check.call(ui.selected().polygon.size() == 5, "workbench: new districts accept extra boundary vertices")
	ui.fields.feather.value = 4
	ui.fields.strength.value = 0.35
	ui.apply_properties()
	check.call(is_equal_approx(float(ui.selected().feather), 4) and is_equal_approx(float(ui.selected().strength), 0.35), "workbench: district inspector controls edge blending and ground tint")
	ui.frame_selection()
	await _screenshot(panel, output.path_join("workbench-district.png"))
	ui.select_feature("anchors", "house")
	var anchors_before: int = document.resolved_layout().anchors.size()
	ui.delete_selection()
	check.call(document.resolved_layout().anchors.size() == anchors_before, "workbench: delete cannot remove an existing gameplay identity")
	var bad := document.snapshot()
	document.layout.routes[0].to = document.layout.routes[0].from
	panel._commit(bad, document.snapshot(), "Invalid test endpoint")
	panel._validate()
	var found := -1
	for i in ui.problems.item_count:
		if ui.problems.get_item_text(i).contains("two different"): found = i
	check.call(found >= 0, "workbench: issues panel explains invalid road endpoints")
	if found >= 0: ui._problem_selected(found)
	check.call(ui.kind == "routes" and ui.identity == str(document.layout.routes[0].id), "workbench: selecting an issue locates the affected road")
	panel._history_step(false)
	ui.inspector_tabs.current_tab = 0
	ui.select_feature("anchors", "house")
	panel._save(panel.path)
	check.call(not panel.dirty, "workbench: Save records the current history state")
	var written := ResourceLoader.load(panel.path, "", ResourceLoader.CACHE_MODE_IGNORE) as AuthoredMap
	var same := written != null
	if same:
		var wanted := document.snapshot()
		var actual := written.snapshot()
		for key in wanted:
			if wanted[key] != actual.get(key): print("WORKBENCH ROUNDTRIP DIFF ", key, " ", str(wanted[key]).left(120), " / ", str(actual.get(key)).left(120))
		same = actual == wanted
	check.call(same, "workbench: save/reload retains polygons, roads, workpoints, props and editor state")
	var old_document_id := document.get_instance_id()
	panel.map = AuthoredMap.new()
	var replacement := (panel.map as AuthoredMap).snapshot()
	panel._restore_document(initial, old_document_id)
	check.call((panel.map as AuthoredMap).snapshot() == replacement, "workbench: stale native undo actions cannot modify a newly opened document")
	panel.map = document
	ui.select_feature("anchors", "house")
	panel.spatial_shown.button_pressed = false
	ui.frame_selection()
	await _screenshot(panel, output.path_join("workbench-building.png"))
	panel._fit_map()
	await _screenshot(panel, output.path_join("workbench-overview.png"))
	panel.canvas_only.button_pressed = true
	await panel.get_tree().process_frame
	panel._fit_map()
	await _screenshot(panel, output.path_join("workbench-canvas-only.png"))
	panel.canvas_only.button_pressed = false
	panel.map = original
	panel.path = old_path
	panel._saved_snapshot = saved
	panel._hidden = original.editor_hidden
	panel._locked = original.editor_locked
	panel.dirty = old_dirty
	ui.clear_selection()
	panel.refresh()

static func _select_choice(box: OptionButton, value: String) -> void:
	for i in box.item_count:
		if box.get_item_text(i) == value: box.select(i); return

static func _mouse(panel: Control, at: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = panel.canvas.pan + at * 8 * panel.canvas.zoom
	panel.canvas._gui_input(event)

static func _motion(panel: Control, at: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = panel.canvas.pan + at * 8 * panel.canvas.zoom
	panel.canvas._gui_input(event)

static func _gesture(panel: Control, from: Vector2, to: Vector2) -> void:
	_mouse(panel, from, true)
	_motion(panel, to)
	_mouse(panel, to, false)

static func _screenshot(panel: Control, path: String) -> void:
	await panel.get_tree().process_frame
	RenderingServer.force_draw()
	panel.get_viewport().get_texture().get_image().save_png(path)
