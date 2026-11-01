extends RefCounted
## Runs inside the isolated ocean fixture, which freezes gameplay while audio ticks.

static func run(game: Game, ocean: OceanJourney, check: Callable) -> void:
	game._sync_ocean_music()
	var music := game._ocean_music
	var song := music.stream as AudioStreamOggVorbis
	check.call(music.playing and not music.stream_paused and song != null and song.loop, "ocean starts its own looping instrumental")
	check.call(song != null and is_equal_approx(song.get_length(), 40.0) and music.bus == "Master", "complete forty-second ocean track follows the existing Master audio settings")
	if song != null:
		# Start at the endpoint atomically. A seek immediately after play can race
		# the audio thread, and SceneTree timers are not the device's audio clock.
		music.play(song.get_length() - 0.1)
		var deadline := Time.get_ticks_msec() + 3000
		while music.get_stream_playback().get_loop_count() == 0 and Time.get_ticks_msec() < deadline:
			await game.get_tree().process_frame
		check.call(music.playing and music.get_stream_playback().get_loop_count() > 0, "ocean instrumental loops across its actual endpoint")
	ocean._ocean_settings.open_settings()
	game._sync_ocean_music()
	check.call(music.stream_paused, "ocean Settings suspends its background music")
	# Let queued pause commands reach the mixer before measuring a frozen clock.
	await _wait_audio(game.get_tree(), 0.15)
	var position := music.get_playback_position()
	await _wait_audio(game.get_tree(), 0.15)
	check.call(absf(music.get_playback_position() - position) < 0.05, "Settings keeps the ocean song position while paused")
	ocean._ocean_settings.close_panel()
	game._sync_ocean_music()
	check.call(music.playing and not music.stream_paused, "closing ocean Settings resumes the same song")
	var volume := GameSettings.master_volume()
	var muted := GameSettings.mute_all()
	GameSettings.set_master_volume(25, false)
	var master := AudioServer.get_bus_index("Master")
	check.call(is_equal_approx(AudioServer.get_bus_volume_db(master), GameSettings.volume_percent_to_db(25)), "Master volume applies to ocean music without a second volume setting")
	GameSettings.set_mute_all(true, false)
	check.call(AudioServer.is_bus_mute(master), "Mute silences ocean music through its Master bus")
	GameSettings.set_master_volume(volume, false)
	GameSettings.set_mute_all(muted, false)
	game._developer_paused = true
	game._sync_ocean_music()
	check.call(music.stream_paused, "developer suspension also pauses ocean background music")
	game._developer_paused = false
	game._sync_ocean_music()
	check.call(not music.stream_paused, "ending developer suspension resumes ocean background music")

static func _wait_audio(tree: SceneTree, seconds: float) -> void:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		await tree.process_frame
