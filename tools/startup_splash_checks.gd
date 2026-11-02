extends RefCounted
## Fast gate truth-table checks; actual decoding and delayed-load review is separate.
static func run(check: Callable) -> void:
	check.call(str(ProjectSettings.get_setting("application/run/main_scene")) == "res://scenes/startup.tscn", "normal app launch starts in the lightweight animated splash")
	check.call(not bool(ProjectSettings.get_setting("application/boot_splash/show_image")), "engine boot cannot flash the static logo before the black video entrance")
	check.call(ProjectSettings.get_setting("application/boot_splash/bg_color") == Color.BLACK, "engine initialization uses the same pure black as movie frame zero")
	check.call(load(StartupSplash.VIDEO_PATH) is VideoStreamTheora, "splash ships a native Theora stream, not unsupported MP4 playback")
	var poster := load(StartupSplash.POSTER_PATH) as Texture2D
	check.call(poster != null and poster.get_size() == StartupSplash.VIDEO_SIZE, "slow-loading hold uses the final 1280x720 logo frame")
	var splash := StartupSplash.new()
	splash._packed_scene = PackedScene.new()
	splash._elapsed = 99
	check.call(not splash.can_handoff(), "early resource readiness can never cut off a playing movie")
	splash._movie_finished = true
	splash._elapsed = 2.9
	check.call(not splash.can_handoff(), "a premature finished notification cannot bypass the full three-second floor")
	splash._elapsed = 3
	check.call(splash.can_handoff(), "completed movie and ready resource permit handoff after three seconds")
	splash._packed_scene = null
	check.call(not splash.can_handoff(), "completed movie keeps its final logo while loading is pending")
	splash._packed_scene = PackedScene.new()
	splash._focus_out = true
	check.call(not splash.can_handoff(), "startup does not reveal the title while the window is unfocused")
	splash._focus_out = false
	splash._handoff = true
	check.call(not splash.can_handoff(), "duplicate process ticks cannot construct another title scene")
	splash.free()
