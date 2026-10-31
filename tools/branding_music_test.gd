extends Node
## Save-isolated checks and native captures for supplied branding and village music.
var game: Game
var checks := 0
var failures := 0

func _ready() -> void:
	if not TestEnvironment.require_isolation():
		get_tree().quit(1)
		return
	GameState.delete_save()
	game = load("res://scenes/game.tscn").instantiate()
	add_child(game)
	game._side_quest_auto_enabled = false
	await get_tree().create_timer(0.3).timeout
	_check(not game._village_music.playing, "title remains outside village music")
	_check(game.title_screen._home_title.text == "BESUT" and game.title_screen._home_wordmark.text == "P R O T E C T", "main menu restores its original text wordmark")
	_check(ProjectSettings.get_setting("application/boot_splash/image") == "res://assets/authored/branding/protect_besut.png" and int(ProjectSettings.get_setting("application/boot_splash/stretch_mode")) == 1, "opening splash uses the supplied logo with aspect ratio preserved")
	_check(ProjectSettings.get_setting("application/config/icon") == "res://icon.png", "game icon uses supplied branding")
	if "--capture" in OS.get_cmdline_user_args():
		for resolution in [Vector2i(1280, 720), Vector2i(832, 480), Vector2i(360, 780)]:
			get_window().content_scale_size = resolution
			get_window().size = resolution
			await get_tree().create_timer(0.3).timeout
			var title := game.title_screen
			var viewport := get_viewport().get_visible_rect()
			_check(viewport.encloses(title._home_title.get_global_rect()) and viewport.encloses(title._home_nav.get_global_rect()), "original menu wordmark and navigation fit %s" % resolution)
			await _shot("title-%dx%d" % [resolution.x, resolution.y])
		get_window().content_scale_size = Vector2i(1280, 720)
		get_window().size = Vector2i(1280, 720)
	GameState.new_game("adam")
	game._remove_title()
	await get_tree().process_frame
	await game._load_lobby(false)
	await get_tree().create_timer(0.3).timeout
	game.hud.tutorial_guide._skip()
	var music := game._village_music
	var song := music.stream as AudioStreamOggVorbis
	_check(music.playing and not music.stream_paused and song != null and song.loop, "village plays supplied looping song")
	music.seek(song.get_length() - 0.1)
	await get_tree().create_timer(0.5).timeout
	_check(music.playing and music.get_playback_position() < 2.0, "song repeats across its actual endpoint")
	if "--capture" in OS.get_cmdline_user_args(): await _shot("village")
	game.play_dock_conversation(true)
	await get_tree().create_timer(0.2).timeout
	_check(game._dock_conversation != null and music.stream_paused, "dock introduction pauses village music")
	var position := music.get_playback_position()
	await get_tree().create_timer(0.2).timeout
	_check(absf(music.get_playback_position() - position) < 0.05, "story suspension preserves the song position")
	game._dock_conversation.finish()
	await get_tree().create_timer(0.2).timeout
	_check(music.playing and not music.stream_paused, "song resumes after dock introduction")
	game.open_settings()
	await get_tree().create_timer(0.1).timeout
	_check(music.playing and not music.stream_paused, "ordinary village Settings keeps music playing")
	GameSettings.set_mute_all(true, false)
	_check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")), "existing mute control covers village audio")
	GameSettings.set_mute_all(false, false)
	game.hud.settings_panel.close_panel()
	# The normal ship departure gate owns the transition; avoid waiting for its film.
	var ship := (game.world as Lobby).ship_boarding
	_check(game.board_ship(ship, true), "ship accepts village departure")
	ship.arrived = true
	await game.enter_ocean(ship)
	_check(game.world is OceanJourney and not music.playing, "ocean transition stops village song")
	await game._load_lobby(false)
	await get_tree().create_timer(0.1).timeout
	_check(music.playing and not music.stream_paused, "return to village restarts its song")
	await game.return_to_title()
	_check(not music.playing, "title handoff stops village song")
	GameState.delete_save()
	print("--- branding music: %d checks, %s ---" % [checks, "PASS" if failures == 0 else "FAIL"])
	get_tree().quit(0 if failures == 0 else 1)

func _shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var path := OS.get_environment("TIDESWORN_TEST_ROOT").path_join(label + ".png")
	_check(get_viewport().get_texture().get_image().save_png(path) == OK, "capture " + label)

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("[%s] %s" % ["OK" if ok else "FAIL", message])
