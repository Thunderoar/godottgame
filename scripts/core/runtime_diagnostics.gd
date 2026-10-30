extends Node
## Small independent session record. Never reads or writes journey saves.
## Flush samples so an abrupt process exit still leaves the last known state.

const SAMPLE_SECONDS := 30.0
const MAX_BYTES := 256 * 1024
const MAX_FRAME_SAMPLES := 4096
var game: Game
var path := ""
var _file: FileAccess
var _elapsed := 0.0
var _previous_frame_us := 0
var _frame_intervals := PackedFloat64Array()
var _frame_count := 0
var _frame_total_ms := 0.0
var _frame_max_ms := 0.0

func _ready() -> void:
	game = get_parent() as Game
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir().path_join("logs"))
	path = "user://logs/runtime_%d.jsonl" % OS.get_process_id()
	_file = FileAccess.open(path, FileAccess.WRITE)
	_previous_frame_us = Time.get_ticks_usec()
	var graphics := {"renderer":"headless", "driver":"headless", "gpu":""}
	if DisplayServer.get_name() != "headless":
		graphics = {"renderer":RenderingServer.get_current_rendering_method(), "driver":RenderingServer.get_current_rendering_driver_name(), "gpu":RenderingServer.get_video_adapter_name()}
	graphics.merge({"event":"session_start", "engine":Engine.get_version_info().get("string", ""), "os":OS.get_name(), "display":DisplayServer.get_name(), "pid":OS.get_process_id(), "configured_renderer":ProjectSettings.get_setting("rendering/renderer/rendering_method", ""), "frame_pacing":ProjectSettings.get_setting("display/window/frame_pacing/android/enable_frame_pacing", true), "swappy_mode":ProjectSettings.get_setting("display/window/frame_pacing/android/swappy_mode", 2)})
	_record(graphics)

func _process(delta: float) -> void:
	var now := Time.get_ticks_usec()
	var frame_ms := float(now - _previous_frame_us) / 1000.0
	_previous_frame_us = now
	if _frame_intervals.size() < MAX_FRAME_SAMPLES:
		_frame_intervals.append(frame_ms)
	else:
		_frame_intervals[_frame_count % MAX_FRAME_SAMPLES] = frame_ms
	_frame_count += 1
	_frame_total_ms += frame_ms
	_frame_max_ms = maxf(_frame_max_ms, frame_ms)
	_elapsed += delta
	if _elapsed < SAMPLE_SECONDS: return
	_elapsed = 0.0
	var world := game.world if is_instance_valid(game) else null
	var record := {"event": "sample", "static_bytes": OS.get_static_memory_usage(), "nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), "objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)), "video_bytes": int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED))}
	record.merge(frame_summary())
	_frame_intervals.clear()
	_frame_count = 0
	_frame_total_ms = 0
	_frame_max_ms = 0
	record.max_fps = Engine.max_fps
	record.effects_quality = GameSettings.effects_quality()
	record.visual_style = GameSettings.active_visual_style()
	record.render_resolution = GameSettings.render_resolution()
	record.draw_calls = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	record.texture_bytes = int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED))
	record.engine_process_ms = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	record.physics_ms = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	record.logical_size = [get_viewport().get_visible_rect().size.x, get_viewport().get_visible_rect().size.y]
	record.window_size = [get_window().size.x, get_window().size.y]
	if DisplayServer.get_name() != "headless":
		var render_size := get_viewport().get_texture().get_size()
		record.render_size = [render_size.x, render_size.y]
	if is_instance_valid(world):
		record.world = world.get_script().resource_path
		var player := game.player()
		if is_instance_valid(player): record.player = [player.position.x, player.position.y]
		if world is Dungeon:
			record.portal = world.portal_id
			record.boss_arrived = world._boss_arrived
			if is_instance_valid(world.boss): record.boss_hp = world.boss.hp
	_record(record)

func frame_summary() -> Dictionary:
	if _frame_count == 0: return {}
	var sorted := _frame_intervals.duplicate()
	sorted.sort()
	# Wall-clock cadence includes frame limiting/stalls, not GPU execution time.
	return {"frames":_frame_count, "frame_samples":sorted.size(), "fps":_frame_count * 1000.0 / maxf(0.001, _frame_total_ms), "frame_interval_ms":{"mean":_frame_total_ms / _frame_count,"p50":sorted[ceili(sorted.size()*0.5)-1],"p95":sorted[ceili(sorted.size()*0.95)-1],"p99":sorted[ceili(sorted.size()*0.99)-1],"max":_frame_max_ms}}

func _record(record: Dictionary) -> void:
	if _file == null: return # Diagnostics must never prevent gameplay.
	if _file.get_position() >= MAX_BYTES:
		_file = null
		var previous := path.trim_suffix(".jsonl") + "_previous.jsonl"
		DirAccess.remove_absolute(ProjectSettings.globalize_path(previous))
		DirAccess.rename_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(previous))
		_file = FileAccess.open(path, FileAccess.WRITE)
		if _file == null: return
	record.utc = Time.get_datetime_string_from_system(true)
	record.uptime_ms = Time.get_ticks_msec()
	_file.store_line(JSON.stringify(record))
	_file.flush()

func _exit_tree() -> void:
	_record({"event": "session_end"})
	_file = null
