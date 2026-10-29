class_name UrchinArrival
extends Node2D
## Cosmetic shore preview. Game/Lobby own delivery; previews are never enemies.
signal completed

const DURATION := 8.0
var home: Lobby
var points := PackedVector2Array()
var fires := 0
var night := -1
var serial := -1
var full_intro := false
var cancelled := false
var elapsed := 0.0
var warning_started := -1.0
var _done := false
var _started_at := 0.0
var _sprites: Array[Sprite2D] = []
var _feet := PackedVector2Array()
var _camera: Camera2D
var _previous_camera: Camera2D
var _camera_start := Vector2.ZERO
var _zoom_start := Vector2.ONE
var _focus := Vector2.ZERO
var _ui: CanvasLayer
var _root: Control
var _skip: Button
var _caption: Label
var _voice: AudioStreamPlayer
var _sound_beat := -1

func _ready() -> void:
	z_index = 45
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_started_at = warning_started if warning_started >= 0 else float(GameState.data.world_time)
	for at in points:
		var actor := Sprite2D.new()
		actor.scale = Vector2.ONE * PixelArt.PX
		actor.position = home.to_global(at) + Vector2(0, -0.5)
		actor.light_mask = 0
		add_child(actor)
		_sprites.append(actor)
		_feet.append(home.to_global(at))
		_focus += home.to_global(at)
	_focus /= maxf(1, points.size())
	_focus += Vector2(0, -0.4)
	if full_intro:
		_previous_camera = get_viewport().get_camera_2d()
		_camera_start = _previous_camera.global_position if is_instance_valid(_previous_camera) else _focus
		_zoom_start = _previous_camera.zoom if is_instance_valid(_previous_camera) else Vector2.ONE * 38
		_camera = Camera2D.new()
		_camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
		_camera.position = _camera_start
		_camera.zoom = _zoom_start
		add_child(_camera)
		_camera.make_current()
	_ui = CanvasLayer.new()
	_ui.layer = 260
	add_child(_ui)
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_root)
	_caption = GameUI.label("", 22, Color("#f7e7bc"))
	_caption.add_theme_color_override("font_outline_color", Color("#273b50"))
	_caption.add_theme_constant_override("outline_size", 5)
	_caption.position = Vector2(28, 28)
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_caption)
	if full_intro:
		_skip = GameUI.button("Skip introduction", Vector2(190, 64))
		_skip.pressed.connect(finish)
		_root.add_child(_skip)
		_root.resized.connect(_fit)
		_fit()
	_voice = AudioStreamPlayer.new()
	_voice.bus = "Master"
	add_child(_voice)
	GameSettings.changed.connect(_on_setting_changed)
	_apply_volume()
	sample(0)

func _fit() -> void:
	var display_scale := float(get_window().size.y) / maxf(1, get_viewport_rect().size.y) if DisplayServer.get_name() != "headless" else 1.0
	_skip.size = Vector2(190, maxf(48, 44 / maxf(0.1, display_scale)))
	_skip.position = Vector2(_root.size.x - _skip.size.x - 24, 24)

func _process(delta: float) -> void:
	if _done: return
	var game := get_tree().get_first_node_in_group("game") as Game
	if not is_instance_valid(home) or not is_instance_valid(game) or game.world != home or serial != GameState.journey_serial or not GameState.is_night() or GameState.night_number() != night:
		cancel()
		return
	if full_intro: elapsed += maxf(0, delta)
	else: elapsed = maxf(0, float(GameState.data.world_time) - _started_at)
	sample(elapsed)
	if elapsed >= DURATION: finish()

func sample(time: float) -> void:
	elapsed = clampf(time, 0, DURATION)
	var reduced := GameSettings.reduce_motion()
	var visible_time := elapsed if full_intro else minf(1.99, elapsed * 0.25)
	for i in _sprites.size():
		var actor := _sprites[i]
		var delay := 0.0 if i == 0 else 3.7 + float(i - 1) * 0.18
		var t := visible_time - delay
		var show_spines := t >= 0.8 and t < 2.0
		actor.visible = t >= 0.8
		var land := home.to_global(points[i])
		var water := land + Vector2(0, 1.8)
		var progress := smoothstep(2.0, 3.2, t)
		var foot := water.lerp(land, progress)
		if reduced: foot = water if show_spines else land
		_feet[i] = foot
		actor.position = foot + Vector2(0, -0.5)
		var pose := "spines" if show_spines else ("notice" if t >= 4.6 else "wobble")
		actor.texture = UrchinArt.texture(pose, int(t * 5.0))
		actor.rotation = sin((t - 3.2) * TAU) * 0.10 * (1.0 - smoothstep(3.2, 4.6, t)) if not reduced and t >= 3.2 else 0.0
		actor.modulate.a = 1.0 if reduced else smoothstep(0.8, 1.2, t)
	if full_intro and is_instance_valid(_camera):
		var close_zoom := Vector2.ONE * minf(64, get_viewport_rect().size.y / 6.0)
		var focus_progress := smoothstep(0.0, 0.8, elapsed)
		var return_progress := smoothstep(7.0, DURATION, elapsed)
		if reduced:
			focus_progress = 1
			return_progress = 1 if elapsed >= 7 else 0
		_camera.global_position = _camera_start.lerp(_focus, focus_progress).lerp(_camera_start, return_progress)
		_camera.zoom = _zoom_start.lerp(close_zoom, focus_progress).lerp(_zoom_start, return_progress)
		_camera.force_update_scroll()
	var direction := _focus - home.player.global_position
	var bearing := ("east" if direction.x > 0 else "west") if absf(direction.x) > absf(direction.y) else ("south" if direction.y > 0 else "north")
	_caption.text = ("Spines in the foam..." if elapsed < 4.6 else "Sea Urchins · A stubborn visitor from the tide") if full_intro else "Spines at the shoreline · " + bearing
	var game := get_tree().get_first_node_in_group("game") as Game
	_ui.visible = full_intro or (is_instance_valid(game) and not game.hud.any_modal_open() and not game._story_active and not is_instance_valid(game.home_interior))
	var beat := 0 if elapsed < 2 else (1 if elapsed < 3.4 else 2)
	if beat != _sound_beat:
		_sound_beat = beat
		if _voice != null and not GameSettings.mute_all() and GameSettings.effects_volume() > 0 and GameSettings.master_volume() > 0:
			_voice.stream = Sfx.urchin_arrival_sound(["surf", "sand", "rattle"][beat])
			_voice.play()
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(home): return
	var reduced := GameSettings.reduce_motion()
	for i in _feet.size():
		if full_intro and _sprites[i].visible:
			var at := _feet[i]
			draw_ellipse_shadow(at)
		var water := home.to_global(points[i]) + Vector2(0, 1.35)
		var movement := 0.0 if reduced else sin(elapsed * 2 + i) * 0.06
		var foam := PackedVector2Array([water + Vector2(-0.65, movement), water + Vector2(-0.32, -0.06), water, water + Vector2(0.31, -0.07), water + Vector2(0.65, movement)])
		draw_polyline(foam, Color("#c1e6dd"), PixelArt.PX * 2)
		if GameSettings.effects_at_least("med") and not reduced and elapsed > 2 and elapsed < 3.4:
			for n in 3:
				draw_rect(Rect2(water + Vector2(float(n - 1) * 0.22, -sin((elapsed - 2) * PI) * 0.35), Vector2.ONE * PixelArt.PX * 2), Color("#a2d6d5"))

func draw_ellipse_shadow(at: Vector2) -> void:
	var polygon := PackedVector2Array()
	for i in 12: polygon.append(at + Vector2(cos(float(i) * TAU / 12) * 0.38, sin(float(i) * TAU / 12) * 0.11))
	draw_colored_polygon(polygon, Color(0.04, 0.06, 0.1, 0.24))

func _apply_volume() -> void:
	_voice.volume_db = -18 + GameSettings.volume_percent_to_db(GameSettings.effects_volume())
	if GameSettings.mute_all() or GameSettings.effects_volume() <= 0 or GameSettings.master_volume() <= 0: _voice.stop()

func _on_setting_changed(key: String) -> void:
	if key in ["effects_volume", "master_volume", "mute_all"]: _apply_volume()
	if key in ["reduce_motion", "effects_quality"]: sample(elapsed)

func _input(event: InputEvent) -> void:
	if full_intro and not _done and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ESCAPE, KEY_SPACE, KEY_ENTER]:
		get_viewport().set_input_as_handled()
		finish()

func finish() -> void:
	if _done: return
	_done = true
	_voice.stop()
	hide()
	_ui.hide()
	if is_instance_valid(_previous_camera): _previous_camera.make_current()
	completed.emit()
	queue_free()

func cancel() -> void:
	cancelled = true
	finish()
