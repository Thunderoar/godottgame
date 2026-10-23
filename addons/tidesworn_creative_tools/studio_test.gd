@tool
extends RefCounted
## Runs only in a disposable SOURCE COPY, as well as isolated user data.
static var checks := 0
static var failures := 0

static func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1
	print("[TOOL %s] %s" % ["OK" if value else "FAIL", message])

static func run(studio: Control) -> void:
	var tree := studio.get_tree()
	var root := OS.get_environment("TIDESWORN_TEST_ROOT")
	if root.is_empty() or not ProjectSettings.globalize_path("res://").begins_with(root + "/") or not OS.get_user_data_dir().begins_with(root + "/"):
		push_error("Creative tool tests require a disposable project copy and isolated userdata.")
		tree.quit(1)
		return
	await tree.create_timer(1.0).timeout
	EditorInterface.set_main_screen_editor("Tidesworn")
	studio.show()
	await tree.process_frame
	check(studio.tabs.get_tab_count() == 4, "all four native editor workspaces loaded")
	DirAccess.make_dir_recursive_absolute("res://data/maps")
	var output := root.path_join("evidence")
	DirAccess.make_dir_recursive_absolute(output)
	var pixel: Control = studio.pixel_panel
	studio.tabs.current_tab = 2
	pixel.document.new_image(Vector2i(32, 32))
	pixel.picker.color = WorldPalette.color("sea_shallow")
	pixel.tool.select(5)
	pixel._press(Vector2i(4, 4))
	pixel._release(Vector2i(24, 25))
	pixel.tool.select(3)
	pixel._press(Vector2i(5, 5))
	pixel._release(Vector2i(5, 5))
	check(pixel.document.image().get_pixel(6, 6).a > 0, "rectangle and bucket work through the editor controls")
	pixel.picker.color = WorldPalette.color("flower")
	pixel.tool.select(0)
	pixel._press(Vector2i(9, 9))
	pixel._drag(Vector2i(19, 19))
	pixel._release(Vector2i(19, 19))
	check(pixel.document.image().get_pixel(15, 15).is_equal_approx(pixel.picker.color), "pencil draws continuous stroke through canvas handlers")
	pixel.tool.select(1)
	pixel._press(Vector2i(10, 10))
	pixel._release(Vector2i(10, 10))
	check(pixel.document.image().get_pixel(10, 10).a == 0, "eraser preserves PNG transparency")
	pixel.document.undo()
	check(pixel.document.image().get_pixel(10, 10).a > 0, "pixel undo restores erased pixel")
	pixel.document.redo()
	check(pixel.document.image().get_pixel(10, 10).a == 0, "pixel redo reapplies eraser")
	pixel._preview_palette()
	check(pixel._preview != null, "palette substitution has non-destructive preview")
	pixel._apply_preview()
	pixel.document.add_frame(true)
	pixel.document.durations[1] = 0.2
	pixel.document.reorder(-1)
	pixel.document.remove_frame()
	pixel.document.add_frame(true)
	check(pixel.document.frames.size() == 2, "frame add/duplicate/reorder/remove produce valid timeline")
	pixel._save_to("res://assets/authored/props/editor_workflow.png")
	check(not pixel.document.dirty and FileAccess.file_exists(pixel.document.source_path), "PNG Save As clears dirty state only after successful save")
	pixel._register()
	await tree.create_timer(1.5).timeout
	check(AssetRegistry.library().entries.has("authored/editor_workflow"), "saved artwork registers in persistent asset catalog")
	check(AssetRegistry.get_texture("authored/editor_workflow") != null, "newly imported PNG is available as runtime texture")
	await screenshot(studio, output.path_join("pixel-editor.png"))
	var original := Image.create_empty(96, 32, false, Image.FORMAT_RGBA8)
	original.fill(Color.TRANSPARENT)
	for i in 3:
		var frame := PixelArt.coastal_prop("flowers").get_image()
		frame.resize(32, 32, Image.INTERPOLATE_NEAREST)
		original.blit_rect(frame, Rect2i(0, 0, 32, 32), Vector2i(i * 32, 0))
	var external := root.path_join("new_character_sheet.png")
	original.save_png(external)
	studio.tabs.current_tab = 0
	var assets: Control = studio.asset_panel
	assets.category.select(2)
	assets._import_file(external)
	await tree.create_timer(1.5).timeout
	assets.width.value = 32
	assets.height.value = 32
	assets.columns.value = 3
	assets.count.value = 3
	assets.fps.value = 6
	assets.semantic.text = "demo/character"
	assets.provenance.text = "Original procedural Tidesworn artwork"
	assets.save_entry()
	check(AssetRegistry.library().entries.has("demo/character") and AssetRegistry.get_texture("demo/character", 2).get_width() == 32, "image import, frame configuration and semantic override persist")
	var saved_source := str(AssetRegistry.library().entries["demo/character"].path)
	pixel.open_image(saved_source, Vector2i(32, 32))
	check(pixel.document.frames.size() == 3, "asset opens as editable animation frames")
	pixel.document.checkpoint()
	pixel.document.dot(Vector2i(16, 16), Color.CYAN)
	pixel._save()
	await tree.create_timer(1.5).timeout
	AssetRegistry.invalidate()
	check(AssetRegistry.get_texture("demo/character", 0).get_image().get_pixel(16, 16).is_equal_approx(Color.CYAN), "PNG edits update imported texture after editor reimport")
	await screenshot(studio, output.path_join("asset-library.png"))
	var map_panel: Control = studio.map_panel
	studio.tabs.current_tab = 1
	map_panel.map = AuthoredMap.new()
	map_panel.path = "res://data/maps/editor_workflow.tres"
	map_panel.dirty = false
	map_panel.layer.select(0)
	map_panel.terrain_choice.select(1)
	map_panel.tool.select(0)
	map_panel._press(Vector2i(28, 31) * 8)
	map_panel._drag(Vector2i(31, 31) * 8)
	map_panel._release(Vector2i(31, 31) * 8)
	check(map_panel.map.cell("Terrain", Vector2i(30, 31)) == "grass_light", "map pencil interpolates cell strokes")
	map_panel.layer.select(1)
	map_panel.terrain_choice.select(3)
	for at in [Vector2i(28, 32), Vector2i(29, 32), Vector2i(30, 33)]:
		map_panel._press(at * 8)
		map_panel._release(at * 8)
	map_panel.layer.select(2)
	map_panel.terrain_choice.select(5)
	map_panel.tool.select(2)
	map_panel._press(Vector2i(25, 33) * 8)
	map_panel._release(Vector2i(27, 35) * 8)
	check(map_panel.map.cell("Water", Vector2i(26, 34)) == "sea_shallow", "rectangle paints authored water")
	map_panel._history_step(false)
	check(map_panel.map.cell("Water", Vector2i(26, 34)).is_empty(), "native EditorUndoRedoManager undoes map stroke")
	map_panel._history_step(true)
	check(map_panel.map.cell("Water", Vector2i(26, 34)) == "sea_shallow", "native EditorUndoRedoManager redoes map stroke")
	map_panel.tool.select(7)
	map_panel.asset.text = "tree"
	map_panel.blocking.button_pressed = true
	map_panel._press(Vector2i(32, 34) * 8)
	map_panel._release(Vector2i(32, 34) * 8)
	map_panel.asset.text = "demo/character"
	map_panel.blocking.button_pressed = false
	map_panel._press(Vector2i(30, 31) * 8)
	map_panel._release(Vector2i(30, 31) * 8)
	check(map_panel.map.objects.size() == 2 and map_panel.map.objects[0].blocking, "object placement preserves stable identity and collision properties")
	var identity: String = map_panel.map.objects[0].id
	map_panel._save(map_panel.path)
	var loaded := ResourceLoader.load(map_panel.path, "", ResourceLoader.CACHE_MODE_IGNORE) as AuthoredMap
	check(loaded.objects[0].id == identity and not map_panel.dirty, "map save/reload preserves object IDs and dirty state")
	map_panel.refresh()
	await screenshot(studio, output.path_join("map-editor.png"))
	studio.tabs.current_tab = 3
	await screenshot(studio, output.path_join("palette-editor.png"))
	var flag := {"called": false}
	studio.confirm_discard(true, func() -> void: flag.called = true)
	var confirmation: ConfirmationDialog
	for child in studio.get_children():
		if child is ConfirmationDialog: confirmation = child
	check(not flag.called and confirmation != null, "unsaved documents require an explicit discard choice")
	if confirmation: confirmation.canceled.emit()
	await tree.process_frame
	pixel.document.checkpoint()
	pixel.document.dot(Vector2i(2, 2), Color.MAGENTA)
	EditorInterface.set_plugin_enabled("tidesworn_creative_tools", false)
	await tree.process_frame
	await tree.process_frame
	check(not EditorInterface.is_plugin_enabled("tidesworn_creative_tools"), "plugin disables and removes its workspace")
	EditorInterface.set_plugin_enabled("tidesworn_creative_tools", true)
	await tree.process_frame
	check(EditorInterface.is_plugin_enabled("tidesworn_creative_tools"), "plugin enables again in the same editor session")
	var recovered: Control = EditorInterface.get_editor_main_screen().get_node("TideswornCreativeStudio")
	check(recovered.pixel_panel.document.dirty and recovered.pixel_panel.document.image().get_pixel(2, 2).is_equal_approx(Color.MAGENTA), "plugin reload recovers unsaved pixel work without overwriting source art")
	recovered.pixel_panel.document.dirty = false
	# Tool UI resources hold temporary palette copies; release process-static refs on exit.
	AssetRegistry.catalog = null
	WorldPalette.active = null
	PersonalityProfile._default = null
	print("--- creative tools: %d checks, %d failures ---" % [checks, failures])
	tree.quit(0 if failures == 0 else 1)

static func screenshot(studio: Control, path: String) -> void:
	await studio.get_tree().process_frame
	RenderingServer.force_draw()
	studio.get_viewport().get_texture().get_image().save_png(path)
