@tool
extends VBoxContainer
var plugin: EditorPlugin
var tabs: TabContainer
var asset_panel: Control
var map_panel: Control
var pixel_panel: Control
var palette_panel: Control
var feedback: RichTextLabel

func _ready() -> void:
	var heading := Label.new()
	heading.text = "TIDESWORN  /  CREATIVE STUDIO"
	heading.add_theme_font_size_override("font_size", 24)
	add_child(heading)
	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(tabs)
	for spec in [["Asset Library", "asset_panel"], ["Map Studio", "map_panel"], ["Pixel & Animation", "pixel_panel"], ["World Palette", "palette_panel"]]:
		var panel := load("res://addons/tidesworn_creative_tools/%s.gd" % spec[1]).new() as Control
		panel.name = spec[0]
		panel.studio = self
		set(spec[1], panel)
		tabs.add_child(panel)
	feedback = RichTextLabel.new()
	feedback.custom_minimum_size.y = 55
	feedback.fit_content = false
	add_child(feedback)
	report("Editor-time authoring • source maps stay separate from player settlement saves. Wheel zoom / middle mouse pan in canvases.")
	restore_recovery_draft()
	if Engine.is_editor_hint():
		EditorInterface.get_resource_filesystem().resources_reimported.connect(_reimported)

func _exit_tree() -> void:
	if Engine.is_editor_hint() and EditorInterface.get_resource_filesystem().resources_reimported.is_connected(_reimported):
		EditorInterface.get_resource_filesystem().resources_reimported.disconnect(_reimported)

func _reimported(_paths: PackedStringArray) -> void:
	AssetRegistry.invalidate()
	asset_panel.refresh()

func report(message: String) -> void:
	if feedback: feedback.text = message
	print("Tidesworn Studio: ", message)

func has_unsaved() -> bool:
	return (map_panel != null and map_panel.dirty) or (pixel_panel != null and pixel_panel.document.dirty) or (palette_panel != null and palette_panel.dirty)

func confirm_discard(unsaved: bool, action: Callable) -> void:
	if not unsaved: action.call(); return
	var dialog := ConfirmationDialog.new()
	dialog.dialog_text = "This document has unsaved changes. Discard them and continue?"
	dialog.confirmed.connect(action)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered()

func open_pixels(path: String, frame_size: Vector2i) -> void:
	tabs.current_tab = 2
	pixel_panel.open_image(path, frame_size)


const DRAFT_ROOT := "user://tidesworn_studio_recovery"

func save_recovery_draft() -> void:
	if not has_unsaved():
		for file in ["state.cfg", "map.tres", "palette.tres", "pixels.png", "pixels.png.frames.json"]:
			if FileAccess.file_exists(DRAFT_ROOT.path_join(file)): DirAccess.remove_absolute(DRAFT_ROOT.path_join(file))
		return
	DirAccess.make_dir_recursive_absolute(DRAFT_ROOT)
	var config := ConfigFile.new()
	config.set_value("draft", "map", map_panel.dirty)
	config.set_value("draft", "pixels", pixel_panel.document.dirty)
	config.set_value("draft", "palette", palette_panel.dirty)
	config.set_value("paths", "map", map_panel.path)
	config.set_value("paths", "pixels", pixel_panel.document.source_path)
	config.set_value("paths", "palette", palette_panel.path)
	config.set_value("pixels", "size", pixel_panel.document.image().get_size())
	if map_panel.dirty:
		map_panel.map.editor_hidden = map_panel._hidden
		map_panel.map.editor_locked = map_panel._locked
		var result: Error = ResourceSaver.save(map_panel.map, DRAFT_ROOT.path_join("map.tres"))
		if result != OK: report("Unable to save map recovery draft: " + error_string(result))
	if palette_panel.dirty:
		palette_panel.palette.title = palette_panel.name_entry.text
		ResourceSaver.save(palette_panel.palette, DRAFT_ROOT.path_join("palette.tres"))
	if pixel_panel.document.dirty:
		var source: String = pixel_panel.document.source_path
		var result: Error = pixel_panel.document.save_png(DRAFT_ROOT.path_join("pixels.png"))
		pixel_panel.document.source_path = source
		pixel_panel.document.dirty = true
		if result != OK: report("Unable to save pixel recovery draft: " + error_string(result))
	config.save(DRAFT_ROOT.path_join("state.cfg"))
	report("Unsaved studio edits retained as recovery drafts for the next editor session.")

func restore_recovery_draft() -> void:
	var config := ConfigFile.new()
	if config.load(DRAFT_ROOT.path_join("state.cfg")) != OK: return
	if config.get_value("draft", "map", false):
		var recovered := load(DRAFT_ROOT.path_join("map.tres")) as AuthoredMap
		if recovered:
			map_panel.map = recovered
			map_panel._hidden = recovered.editor_hidden
			map_panel._locked = recovered.editor_locked
			map_panel.path = config.get_value("paths", "map", map_panel.path)
			map_panel.dirty = true
			map_panel.refresh()
	if config.get_value("draft", "palette", false):
		var recovered := load(DRAFT_ROOT.path_join("palette.tres")) as WorldPalette
		if recovered:
			palette_panel.palette = recovered
			palette_panel.name_entry.text = recovered.title
			palette_panel.path = config.get_value("paths", "palette", palette_panel.path)
			palette_panel.dirty = true
			palette_panel._rebuild()
	if config.get_value("draft", "pixels", false):
		var result: Error = pixel_panel.document.load_png(DRAFT_ROOT.path_join("pixels.png"), config.get_value("pixels", "size", Vector2i(32, 32)))
		if result == OK:
			pixel_panel.document.source_path = config.get_value("paths", "pixels", "")
			pixel_panel.document.dirty = true
			pixel_panel.refresh()
	report("Recovered unsaved studio drafts. Review them and Save or explicitly discard changes.")
