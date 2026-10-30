class_name AndroidRenderingChecks
extends RefCounted

static func run(check: Callable) -> void:
	var values: Dictionary = GameSettings._values.duplicate(true)
	var config_path: String = GameSettings.config_path
	var journey: Dictionary = GameState.data.duplicate(true)
	GameSettings.config_path = OS.get_environment("TIDESWORN_TEST_ROOT").path_join("android_rendering_settings.cfg")
	GameSettings.reset_to_defaults()
	check.call(GameSettings.target_fps() == 60, "Android defaults target 60 FPS")
	GameSettings.set_value("target_fps", 30)
	GameSettings.set_value("render_resolution", "balanced")
	GameSettings.load_settings()
	check.call(GameSettings.target_fps() == 30 and GameSettings.render_resolution() == "balanced", "Android frame and resolution preferences survive device-settings reload")
	for invalid in [0, -1, 90, "30", "bad", null]:
		GameSettings.set_value("target_fps", invalid, false)
		check.call(GameSettings.target_fps() == 60, "unsupported frame-rate value %s falls back to 60" % str(invalid))
	GameSettings.set_value("render_resolution", "invalid", false)
	check.call(GameSettings.render_resolution() == str(GameSettings.DEFAULTS.render_resolution), "unsupported resolution falls back to the device default")
	check.call(GameState.data == journey, "rendering preferences do not mutate journey data or control layouts")
	GameSettings._values = values
	GameSettings.config_path = config_path
	GameSettings._apply_all()
	var diagnostics := preload("res://scripts/core/runtime_diagnostics.gd").new()
	check.call(diagnostics.frame_summary().is_empty(), "frame diagnostics handle an empty sample window")
	diagnostics._frame_intervals = PackedFloat64Array([10, 16, 16, 16, 40])
	diagnostics._frame_count = 5
	diagnostics._frame_total_ms = 98.0
	diagnostics._frame_max_ms = 40.0
	var summary: Dictionary = diagnostics.frame_summary()
	check.call(is_equal_approx(summary.fps, 5000.0 / 98.0) and summary.frame_interval_ms.p50 == 16 and summary.frame_interval_ms.p95 == 40 and summary.frame_interval_ms.max == 40, "wall-clock frame diagnostics report weighted FPS and tail stalls correctly")
	diagnostics.free()
	var music: AudioStreamWAV = Sfx._build_battle_track(0)
	check.call(music.loop_begin >= 0 and music.loop_end < music.data.size() / 2 and music.loop_end > music.loop_begin, "procedural battle music loop endpoints stay inside the mono PCM buffer")
