class_name StartupSplash
extends CanvasLayer
## Lightweight entry scene. Resource loading may finish early; the film never does.
signal movie_completed
signal handoff_started
signal handoff_completed
const MOVIE_SECONDS := 3.0
const VIDEO_PATH := "res://assets/video/protect_besut_splash.ogv"
const POSTER_PATH := "res://assets/video/protect_besut_splash_hold.png"
const GAME_PATH := "res://scenes/game.tscn"
const VIDEO_SIZE := Vector2(1280,720)
@export_file("*.tscn") var next_scene_path := GAME_PATH
@export_file("*.ogv") var video_path := VIDEO_PATH
var _screen: Control
var _video: VideoStreamPlayer
var _poster: TextureRect
var _status: Label
var _retry: Button
var _packed_scene: PackedScene
var _load_active := false
var _load_failed := false
var _movie_finished := false
var _fallback := false
var _fallback_elapsed := 0.0
var _elapsed := 0.0
var _focus_out := false
var _handoff := false
var _reveal: Tween

func _ready() -> void:
	layer = 1000
	_screen = Control.new()
	_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_screen)
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen.add_child(black)
	_video = VideoStreamPlayer.new()
	_video.name = "SplashVideo"
	_video.expand = true
	_video.loop = false
	_video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_video.finished.connect(_on_movie_finished)
	_screen.add_child(_video)
	_poster = TextureRect.new()
	_poster.name = "FinalLogoHold"
	_poster.texture = load(POSTER_PATH) as Texture2D
	_poster.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_poster.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_poster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_poster.hide()
	_screen.add_child(_poster)
	_status = Label.new()
	_status.text = "Loading…"
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size",18)
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status.hide()
	_screen.add_child(_status)
	_retry = Button.new()
	_retry.text = "Retry loading"
	_retry.pressed.connect(_request_game)
	_retry.hide()
	_screen.add_child(_retry)
	_screen.resized.connect(_layout)
	GameSettings.changed.connect(_on_setting_changed)
	_on_setting_changed("")
	_layout()
	if ResourceLoader.exists(video_path):
		_video.stream = load(video_path) as VideoStream
	if _video.stream != null:
		_video.play()
	else:
		_begin_fallback()
	_request_game()

func _layout() -> void:
	if not is_instance_valid(_screen): return
	var extent := _screen.size
	var scale := minf(extent.x/VIDEO_SIZE.x,extent.y/VIDEO_SIZE.y)
	var rect := Rect2((extent-VIDEO_SIZE*scale)*0.5,VIDEO_SIZE*scale)
	_video.position = rect.position
	_video.size = rect.size
	_poster.position = rect.position
	_poster.size = rect.size
	_status.position = Vector2(20,maxf(0,extent.y-100))
	_status.size = Vector2(maxf(0,extent.x-40),48)
	_retry.position = Vector2(maxf(0,extent.x*0.5-90),maxf(0,extent.y-40))
	_retry.size = Vector2(180,34)

func _request_game() -> void:
	_load_failed = false
	_load_active = false
	_retry.hide()
	_status.text = "Loading…"
	if not ResourceLoader.exists(next_scene_path):
		_fail_loading()
		return
	var error := ResourceLoader.load_threaded_request(next_scene_path,"PackedScene")
	if error != OK:
		_fail_loading()
		return
	_load_active = true

func _poll_loading() -> void:
	if not _load_active or _packed_scene != null: return
	var state := ResourceLoader.load_threaded_get_status(next_scene_path)
	if state == ResourceLoader.THREAD_LOAD_LOADED:
		# Never call get() before LOADED: it would block the video thread's owner.
		_packed_scene = ResourceLoader.load_threaded_get(next_scene_path) as PackedScene
		_load_active = false
		if _packed_scene == null: _fail_loading()
	elif state in [ResourceLoader.THREAD_LOAD_FAILED,ResourceLoader.THREAD_LOAD_INVALID_RESOURCE]:
		_fail_loading()

func _fail_loading() -> void:
	_load_active = false
	_load_failed = true
	_status.text = "The title screen could not load. Please try again."
	if _movie_finished:
		_status.show()
		_retry.show()

func _process(delta: float) -> void:
	_poll_loading()
	if _focus_out: return
	_elapsed += maxf(0,delta)
	if _fallback and not _movie_finished:
		_fallback_elapsed += maxf(0,delta)
		_poster.modulate.a = smoothstep(0.125,0.75,_fallback_elapsed)
		if _fallback_elapsed >= MOVIE_SECONDS: _on_movie_finished()
	elif not _movie_finished and _elapsed > 0.3 and not _video.is_playing():
		# A failed decoder must not strand startup. Never replace a playing film.
		_begin_fallback()
	if _movie_finished:
		_status.visible = _packed_scene == null
		_retry.visible = _load_failed
	if can_handoff():
		_handoff = true
		call_deferred("_enter_game")

func _begin_fallback() -> void:
	_fallback = true
	_fallback_elapsed = 0
	_video.stop()
	_video.hide()
	_poster.modulate.a = 0
	_poster.show()

func _on_movie_finished() -> void:
	if _movie_finished: return
	_movie_finished = true
	_video.hide()
	_poster.modulate.a = 1
	_poster.show()
	movie_completed.emit()

func can_handoff() -> bool:
	return _movie_finished and _elapsed >= MOVIE_SECONDS and _packed_scene != null and not _focus_out and not _handoff

func _enter_game() -> void:
	if not is_inside_tree() or _packed_scene == null: return
	var game := _packed_scene.instantiate()
	if game == null:
		_handoff = false
		_packed_scene = null
		_fail_loading()
		return
	handoff_started.emit()
	get_tree().root.add_child(game)
	if get_tree().current_scene == self: get_tree().current_scene = game
	# Keep the last logo frame over the main-thread scene setup and first drawn frame.
	await get_tree().process_frame
	if not is_inside_tree(): return
	if DisplayServer.get_name() != "headless": await RenderingServer.frame_post_draw
	if not is_inside_tree(): return
	_status.hide()
	_retry.hide()
	_reveal = create_tween()
	_reveal.tween_property(_screen,"modulate:a",0.0,0.22)
	if _focus_out: _reveal.pause()
	await _reveal.finished
	if not is_inside_tree(): return
	handoff_completed.emit()
	queue_free()

func _input(_event: InputEvent) -> void:
	# No skip/early title input. Retry remains a real GUI button on failure.
	if not (_load_failed and _movie_finished): get_viewport().set_input_as_handled()

func _on_setting_changed(_key: String) -> void:
	_video.volume_db = -8.0+GameSettings.volume_percent_to_db(GameSettings.effects_volume())

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_focus_out = true
		if is_instance_valid(_video): _video.paused = true
		if _reveal != null and _reveal.is_valid(): _reveal.pause()
	elif what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		_focus_out = false
		if is_instance_valid(_video): _video.paused = false
		if _reveal != null and _reveal.is_valid(): _reveal.play()

func _exit_tree() -> void:
	if is_instance_valid(_video): _video.stop()
	if _reveal != null and _reveal.is_valid(): _reveal.kill()
