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
