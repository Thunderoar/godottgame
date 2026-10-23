@tool
extends EditorPlugin
var studio: Control

func _enter_tree() -> void:
	studio = preload("res://addons/tidesworn_creative_tools/studio.gd").new()
	studio.size_flags_vertical = Control.SIZE_EXPAND_FILL
	studio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	studio.name = "TideswornCreativeStudio"
	studio.plugin = self
	EditorInterface.get_editor_main_screen().add_child(studio)
	studio.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	studio.hide()
	if "--creative-tool-tests" in OS.get_cmdline_user_args() and not Engine.has_meta("creative_test_started"):
		Engine.set_meta("creative_test_started", true)
		call_deferred("_run_checks")

func _exit_tree() -> void:
	if is_instance_valid(studio):
		studio.save_recovery_draft()
		studio.queue_free()

func _has_main_screen() -> bool:
	return true

func _make_visible(value: bool) -> void:
	if is_instance_valid(studio): studio.visible = value

func _get_plugin_name() -> String:
	return "Tidesworn"

func _get_unsaved_status(_for_scene: String) -> String:
	if is_instance_valid(studio) and studio.has_unsaved():
		return "Tidesworn has unsaved artwork or map edits. Save them in the studio."
	return ""

func _build() -> bool:
	if is_instance_valid(studio) and studio.has_unsaved():
		studio.report("Save or discard studio edits before launching the game.")
		return false
	return true

func _run_checks() -> void:
	await preload("res://addons/tidesworn_creative_tools/studio_test.gd").run(studio)
