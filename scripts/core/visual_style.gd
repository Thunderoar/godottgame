@tool
class_name VisualStyle
extends RefCounted
## Art selection only. Editor authoring always retains its modern source preview.
## Runtime choice is latched by GameSettings before any game art is constructed.
static func is_pixel() -> bool:
	if Engine.is_editor_hint():
		return false
	var tree := Engine.get_main_loop() as SceneTree
	var settings := tree.root.get_node_or_null("GameSettings") if tree else null
	return settings != null and settings.call("active_visual_style") == "pixel"

static func texture_filter() -> CanvasItem.TextureFilter:
	return CanvasItem.TEXTURE_FILTER_NEAREST if is_pixel() else CanvasItem.TEXTURE_FILTER_LINEAR
