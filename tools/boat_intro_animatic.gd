extends Node
## Deterministic silent preview of the actual runtime renderer and caption UI.
func _ready() -> void:
	if not TestEnvironment.require_isolation(): get_tree().quit(1); return
	GameState.autosave_enabled = false
	get_window().content_scale_size = Vector2i(832,480)
	get_window().size = Vector2i(832,480)
	GameSettings.set_reduce_motion(false,false)
	var story := StorySequence.new()
	add_child(story)
	story.set_process(false)
	var directory := OS.get_environment("TIDESWORN_TEST_ROOT").path_join("frames")
	DirAccess.make_dir_recursive_absolute(directory)
	for frame in 288:
		story.page = frame / 72
		story._page_time = float(frame % 72) / 12.0
		story._render()
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var result := get_viewport().get_texture().get_image().save_png(directory.path_join("%04d.png" % frame))
		if result != OK: push_error("Preview frame failed: " + str(result)); get_tree().quit(1); return
	story.finish()
	print("ANIMATIC_FRAMES=288 FPS=12 SECONDS=24 SILENT=true")
	get_tree().quit(0)
