extends Node
## Small independent session record. Never reads or writes journey saves.
## Flush samples so an abrupt process exit still leaves the last known state.

const SAMPLE_SECONDS := 30.0
const MAX_BYTES := 256 * 1024
var game: Game
var path := ""
var _file: FileAccess
var _elapsed := 0.0

func _ready() -> void:
	game = get_parent() as Game
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir().path_join("logs"))
	path = "user://logs/runtime_%d.jsonl" % OS.get_process_id()
	_file = FileAccess.open(path, FileAccess.WRITE)
	_record({"event": "session_start", "engine": Engine.get_version_info().get("string", ""), "os": OS.get_name(), "display": DisplayServer.get_name(), "renderer": ProjectSettings.get_setting("rendering/renderer/rendering_method", ""), "pid": OS.get_process_id()})

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < SAMPLE_SECONDS: return
	_elapsed = 0.0
	var world := game.world if is_instance_valid(game) else null
	var record := {"event": "sample", "static_bytes": OS.get_static_memory_usage(), "nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), "objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)), "video_bytes": int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED))}
	if is_instance_valid(world):
		record.world = world.get_script().resource_path
		var player := game.player()
		if is_instance_valid(player): record.player = [player.position.x, player.position.y]
		if world is Dungeon:
			record.portal = world.portal_id
			record.boss_arrived = world._boss_arrived
			if is_instance_valid(world.boss): record.boss_hp = world.boss.hp
	_record(record)

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
