extends Node
var checks := 0
var failures := 0
const FIXTURE := "res://tools/startup_ready_fixture.tscn"
class HeldLoadSplash extends StartupSplash:
	var allow_ready := false
	func _request_game() -> void: pass
	func _poll_loading() -> void:
		if allow_ready and _packed_scene == null: _packed_scene = load("res://tools/startup_ready_fixture.tscn") as PackedScene

func _ready() -> void:
	if not TestEnvironment.require_isolation(): get_tree().quit(1); return
	GameState.autosave_enabled = false
	preload("res://tools/startup_splash_checks.gd").run(_check)
	await _fast()
	await _slow()
	await _focus()
	await _fallback()
	await _failure_retry()
	await _cancel()
	await _real_game()
	print("--- startup splash review: %d checks, %s ---" % [checks,"PASS" if failures == 0 else "FAIL"])
	get_tree().quit(0 if failures == 0 else 1)

func _fast() -> void:
	var splash := StartupSplash.new()
	splash.next_scene_path = FIXTURE
	var observed := _observe(splash)
	add_child(splash)
	await _shot("01-first-frame-black")
	await get_tree().create_timer(0.35).timeout
	_check(splash._packed_scene != null and not splash._movie_finished and not splash._handoff, "real threaded fixture load finishes early without shortening the video")
	_check(_fixtures().is_empty() and splash._video.is_playing() and not splash._video.loop, "no title node is created while the nonlooping film is playing")
	await _shot("02-fade-in")
	for pressed in [true,false]:
		var event := InputEventKey.new()
		event.keycode = KEY_ENTER
		event.pressed = pressed
		Input.parse_input_event(event)
		await get_tree().process_frame
	_check(not splash._movie_finished and not splash._handoff, "keyboard acceptance cannot skip the startup film")
	await _gone(splash,9)
	_check(observed.movie == 1 and observed.handoff == 1 and observed.done == 1 and observed.time >= 3.0, "real decoder completion hands off once after at least three active seconds")
	_check(_fixtures().size() == 1, "fast startup constructs exactly one loaded scene")
	await _clear_fixtures()

func _slow() -> void:
	var splash := HeldLoadSplash.new()
	var observed := _observe(splash)
	add_child(splash)
	await get_tree().create_timer(4.1).timeout
	_check(splash._movie_finished and not splash._handoff and _fixtures().is_empty(), "delayed resource readiness never cuts or bypasses playback")
	_check(splash._poster.visible and splash._status.visible and not splash._video.visible and not splash._video.loop, "slow startup holds the final logo with Loading, without replaying the video")
	await _shot("03-slow-startup-final-frame-hold")
	for extent in [Vector2i(1280,720),Vector2i(832,480),Vector2i(360,780)]:
		get_window().content_scale_size = extent
		get_window().size = extent
		await get_tree().process_frame
		await get_tree().process_frame
		var rect := splash._poster.get_global_rect()
		_check(get_viewport().get_visible_rect().encloses(rect) and absf(rect.size.x/rect.size.y-16.0/9.0)<0.001, "splash holds correct aspect and stays inside %s" % extent)
		await _shot("hold-%dx%d" % [extent.x,extent.y])
	get_window().content_scale_size = Vector2i(1280,720)
	get_window().size = Vector2i(1280,720)
	splash.allow_ready = true
	await _gone(splash,3)
	_check(observed.movie == 1 and observed.handoff == 1 and _fixtures().size() == 1, "late readiness releases the held logo once without replaying the film")
	await _clear_fixtures()

func _focus() -> void:
	var splash := StartupSplash.new()
	splash.next_scene_path = FIXTURE
	var observed := _observe(splash)
	var start := Time.get_ticks_msec()
	add_child(splash)
	await get_tree().create_timer(0.8).timeout
	splash._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	var time := splash._elapsed
	var position := splash._video.stream_position
	await get_tree().create_timer(0.7).timeout
	_check(splash._elapsed == time and splash._video.paused and absf(splash._video.stream_position-position)<0.05, "focus loss freezes both startup accounting and actual decoder playback")
	splash._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_IN)
	await _gone(splash,8)
	_check(observed.time >= 3 and Time.get_ticks_msec()-start >= 3600, "focus return resumes the remaining movie instead of consuming its unseen time")
	await _clear_fixtures()

func _fallback() -> void:
	var splash := StartupSplash.new()
	splash.video_path = "res://assets/video/missing-for-fallback-test.ogv"
	splash.next_scene_path = FIXTURE
	var observed := _observe(splash)
	add_child(splash)
	await get_tree().create_timer(0.3).timeout
	_check(splash._fallback and splash._poster.visible and splash._poster.modulate.a < 1 and not splash._handoff, "missing movie falls back to a real black-to-logo fade, not an early title")
	await _gone(splash,8)
	_check(observed.movie == 1 and observed.handoff == 1 and observed.time >= 3, "fallback retains the full duration and eventually loads the title once")
	await _clear_fixtures()

func _failure_retry() -> void:
	var splash := StartupSplash.new()
	splash.next_scene_path = "res://scenes/missing-startup-fixture.tscn"
	var observed := _observe(splash)
	add_child(splash)
	await get_tree().create_timer(0.4).timeout
	_check(splash._load_failed and not splash._retry.visible and not splash._movie_finished, "a failed game load does not interrupt or obscure the film")
	await get_tree().create_timer(3.0).timeout
	_check(splash._movie_finished and splash._retry.visible and not splash._handoff, "failed loading presents an actionable retry over the final frame")
	await _shot("04-failed-load-retry")
	splash.next_scene_path = FIXTURE
	splash._retry.pressed.emit()
	await _gone(splash,5)
	_check(observed.movie == 1 and observed.handoff == 1, "retry loads the title without replaying or skipping an unfinished movie")
	await _clear_fixtures()

func _cancel() -> void:
	var splash := StartupSplash.new()
	splash.next_scene_path = FIXTURE
	var observed := _observe(splash)
	add_child(splash)
	await get_tree().create_timer(0.3).timeout
	splash.queue_free()
	await get_tree().create_timer(0.4).timeout
	_check(observed.handoff == 0 and _fixtures().is_empty(), "closing startup cancels playback without a late scene handoff")

func _real_game() -> void:
	var splash := load("res://scenes/startup.tscn").instantiate() as StartupSplash
	var observed := _observe(splash)
	get_tree().root.add_child(splash)
	get_tree().current_scene = splash
	await get_tree().create_timer(1.0).timeout
	_check(get_tree().get_nodes_in_group("game").is_empty() and not splash._movie_finished, "actual game scene is not instantiated before its startup movie completes")
	await _gone(splash,12)
	var game := get_tree().get_first_node_in_group("game") as Game
	_check(is_instance_valid(game) and game.title_screen != null and observed.handoff == 1 and observed.done == 1, "normal configured startup reaches the real existing title once")
	_check(get_tree().current_scene == game and not game.hud.visible and game.world == null, "startup installs Game as current_scene without starting or changing a journey")
	await _shot("05-real-title-after-complete-playback")
	get_tree().current_scene = self
	if is_instance_valid(game): game.queue_free()
	await get_tree().process_frame

func _observe(splash: StartupSplash) -> Dictionary:
	var result := {"movie":0,"handoff":0,"done":0,"time":0.0}
	splash.movie_completed.connect(func() -> void: result.movie += 1)
	splash.handoff_started.connect(func() -> void: result.handoff += 1; result.time = splash._elapsed)
	splash.handoff_completed.connect(func() -> void: result.done += 1)
	return result
func _gone(splash: StartupSplash,timeout: float) -> void:
	var deadline := Time.get_ticks_msec()+int(timeout*1000)
	while is_instance_valid(splash) and Time.get_ticks_msec()<deadline: await get_tree().create_timer(0.05).timeout
	_check(not is_instance_valid(splash), "startup completes within its bounded review window")
func _fixtures() -> Array[Node]: return get_tree().get_nodes_in_group("startup_ready_fixture")
func _clear_fixtures() -> void:
	for fixture in _fixtures(): fixture.queue_free()
	await get_tree().process_frame
func _shot(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	var dir := OS.get_environment("TIDESWORN_TEST_ROOT").path_join("shots")
	DirAccess.make_dir_recursive_absolute(dir)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir.path_join(name+".png"))
func _check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("[OK] " if ok else "[FAIL] ",message)
