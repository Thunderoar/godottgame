class_name UrchinArrival
extends Node2D
## Shared shore/forest arrival owner. Chapters are cosmetic; Lobby delivers once.
signal completed

const DURATION := 8.0
const FIRE_DURATION := 10.5
const COMBINED_DURATION := 14.5
var home: Lobby
var points := PackedVector2Array()
var fires := 0
var night := -1
var serial := -1
var full_intro := false
var cancelled := false
var elapsed := 0.0
var warning_started := -1.0
var fire_points := PackedVector2Array()
var batch_id := ""
var reinforcement := false
var introduce_shore := true
var introduce_fire := false
var _fire: FireArrival
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
var _curtain: ColorRect
var fire_times: Array = []
var shore_times: Array = []
var resolved_fire: Array = []
var resolved_shore: Array = []

func configure(pending: Dictionary) -> void:
	night = int(pending.night)
	serial = GameState.journey_serial
	batch_id = str(pending.get("id", ""))
	fires = int(pending.fires)
	warning_started = float(pending.started)
	for at in pending.points: points.append(Vector2(float(at[0]), float(at[1])))
	for at in pending.get("fire_points", []): fire_points.append(Vector2(float(at[0]), float(at[1])))
	fire_times = pending.get("fire_times", [])
	shore_times = pending.get("shore_times", [])
	resolved_fire = pending.get("resolved_fire", []).duplicate()
	resolved_shore = pending.get("resolved_shore", []).duplicate()

func duration() -> float:
	if not full_intro:
		var end := DURATION
		for time in fire_times + shore_times: end = maxf(end, float(time))
		return end + ArrivalDB.LATE_GRACE + 0.1
	if not introduce_fire: return DURATION
	return COMBINED_DURATION if introduce_shore else FIRE_DURATION

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
	if not fire_points.is_empty():
		_fire = FireArrival.new()
		_fire.home = home
		_fire.points = fire_points
		_fire.full_intro = full_intro and introduce_fire
		for time in fire_times: _fire.offsets.append(float(time) - ArrivalDB.WARNING)
		_fire.resolved = resolved_fire
		add_child(_fire)
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
	_curtain = ColorRect.new()
	_curtain.color = Color("#152b34")
	_curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_curtain.visible = false
	_root.add_child(_curtain)
	_caption = GameUI.label("", 22, Color("#f7e7bc"))
	_caption.add_theme_color_override("font_outline_color", Color("#273b50"))
	_caption.add_theme_constant_override("outline_size", 5)
	_caption.position = Vector2(28, 28)
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
	if is_instance_valid(_skip):
		_skip.size = Vector2(190, maxf(48, 44 / maxf(0.1, display_scale)))
		_skip.position = Vector2(_root.size.x - _skip.size.x - 24, 24)
	_caption.size = Vector2(maxf(1, _root.size.x - 56), 64)
	_caption.position = Vector2(28, maxf(100, _root.size.y - 94)) if full_intro else Vector2(28, 100)
	if not full_intro:
		var game := get_tree().get_first_node_in_group("game") as Game
		if is_instance_valid(game) and is_instance_valid(game.hud.objective_tracker):
			var objective := game.hud.objective_tracker.get_global_rect()
			# Reserve the objective column even before its next visibility/layout tick.
			var left := maxf(objective.end.x + 16, _root.size.x * 0.38 + 28)
			var right := game.hud._menu_button.get_global_rect().position.x - 16
			var top := 90.0
			if game.hud._progression_notice.visible: top = maxf(top, game.hud._progression_notice.get_global_rect().end.y + 12)
			if right - left < 280:
				left = 28
				right = _root.size.x - 28
				top = maxf(top, objective.end.y + 12)
			_caption.position = Vector2(left, top)
			_caption.size.x = maxf(1, right - left)

func _process(delta: float) -> void:
	if _done: return
	var game := get_tree().get_first_node_in_group("game") as Game
	if not is_instance_valid(home) or home.is_queued_for_deletion() or not is_instance_valid(game) or game.world != home or serial != GameState.journey_serial or GameState.game_over_active or not GameState.is_night() or GameState.night_number() != night:
		cancel()
		return
	if full_intro: elapsed += maxf(0, delta)
	else: elapsed = maxf(0, float(GameState.data.world_time) - _started_at)
	sample(elapsed)
	if not full_intro:
		GameState.expire_home_arrival_members(reinforcement, home.capture_monsters())
		var pending := GameState.pending_home_arrival(reinforcement)
		if pending.is_empty(): finish(); return
		resolved_fire = pending.resolved_fire.duplicate()
		resolved_shore = pending.resolved_shore.duplicate()
		# At most one actual creature per tick, with saved spacing between ticks.
		var member := next_member(pending)
		if not member.is_empty() and elapsed >= float(member.time):
			home.deliver_arrival_member(self, str(member.species), int(member.index))
			pending = GameState.pending_home_arrival(reinforcement)
			if pending.is_empty(): finish(); return
			resolved_fire = pending.resolved_fire.duplicate()
			resolved_shore = pending.resolved_shore.duplicate()
		sample(elapsed)
	if elapsed >= duration(): finish()

func next_member(pending: Dictionary) -> Dictionary:
	var result := {}
	var earliest := INF
	for species in ["fire", "shore"]:
		var times: Array = pending[species + "_times"]
		for i in times.size():
			if i not in pending["resolved_" + species] and float(times[i]) < earliest:
				earliest = float(times[i])
				result = {"species": species, "index": i, "time": earliest}
	return result

func sample(time: float) -> void:
	elapsed = clampf(time, 0, duration())
	var reduced := GameSettings.reduce_motion()
	var visible_time := elapsed if full_intro else minf(1.99, elapsed * 0.25)
	# Fit all six shore landings into the combined seven-second chapter, then
	# hold their final poses while the forest is introduced. Shore-only stays 8 s.
	if full_intro and introduce_fire and introduce_shore: visible_time = minf(8.0, elapsed * 8.0 / 7.0)
	for i in _sprites.size():
		var actor := _sprites[i]
		var local_time := elapsed - (float(shore_times[i]) - ArrivalDB.WARNING if not full_intro and i < shore_times.size() else 0.0)
		var t := visible_time if full_intro else (minf(1.99, local_time * 0.25) if local_time < 6.6 else lerpf(2.0, 3.2, clampf((local_time - 6.6) / 1.4, 0, 1)))
		var show_spines := t >= 0.8 and t < 2.0
		actor.visible = t >= 0.8 and i not in resolved_shore and (not full_intro or i == 0)
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
	var fire_time := elapsed
	if full_intro and introduce_fire and introduce_shore: fire_time = (elapsed - 7.0) * 9.2 / 6.5
	if is_instance_valid(_fire):
		_fire.resolved = resolved_fire
		_fire.sample(fire_time)
	if full_intro and is_instance_valid(_camera):
		var close_zoom := Vector2.ONE * minf(64, get_viewport_rect().size.y / 6.0)
		var focus_progress := smoothstep(0.0, 0.8, elapsed)
		var return_start := duration() - (1.3 if introduce_fire and not introduce_shore else 1.0)
		var return_progress := smoothstep(return_start, duration(), elapsed)
		if reduced:
			focus_progress = 1
			return_progress = 1 if elapsed >= return_start else 0
		var shot := _focus
		if introduce_fire and is_instance_valid(_fire) and (not introduce_shore or elapsed >= 7.15):
			shot = _fire.focus()
			close_zoom = Vector2.ONE * minf(76, get_viewport_rect().size.y / 7.0) * lerpf(1.0, 0.90, smoothstep(6.6, 8.4, fire_time))
		# Bridge distant shore and forest with a brief covered cut, one camera owner.
		var cover := smoothstep(6.85, 7.15, elapsed) * (1.0 - smoothstep(7.15, 7.5, elapsed)) if introduce_fire and introduce_shore else 0.0
		_curtain.visible = cover > 0
		_curtain.modulate.a = cover
		_camera.global_position = _camera_start.lerp(shot, focus_progress).lerp(_camera_start, return_progress)
		_camera.zoom = _zoom_start.lerp(close_zoom, focus_progress).lerp(_zoom_start, return_progress)
		_camera.force_update_scroll()
	if full_intro:
		if introduce_fire and (not introduce_shore or elapsed >= 7.15):
			_caption.text = "An ember hangs between the trees..." if fire_time < 3 else ("Something is crossing into BESUT..." if fire_time < 5.4 else "Fire Monsters · Protect the forest")
		else: _caption.text = "Spines in the foam..." if elapsed < 4.6 else "Sea Urchins · A stubborn visitor from the tide"
	else:
		_fit()
		var fire_cue := false
		var shore_cue := false
		var fire_focus := Vector2.ZERO
		var shore_focus := _focus
		for i in fire_times.size():
			if i not in resolved_fire and elapsed >= float(fire_times[i]) - ArrivalDB.WARNING and elapsed <= float(fire_times[i]) + ArrivalDB.LATE_GRACE:
				if not fire_cue: fire_focus = home.to_global(fire_points[i])
				fire_cue = true
		for i in shore_times.size():
			if i not in resolved_shore and elapsed >= float(shore_times[i]) - ArrivalDB.WARNING and elapsed <= float(shore_times[i]) + ArrivalDB.LATE_GRACE:
				if not shore_cue: shore_focus = home.to_global(points[i])
				shore_cue = true
		_caption.visible = fire_cue or shore_cue
		if fire_cue and shore_cue: _caption.text = "Spines · %s   /   Embers · %s" % [_bearing(shore_focus), _bearing(fire_focus)]
		elif fire_cue: _caption.text = "Embers in the forest · " + _bearing(fire_focus)
		elif shore_cue: _caption.text = "Spines at the shoreline · " + _bearing(shore_focus)
	var game := get_tree().get_first_node_in_group("game") as Game
	_ui.visible = full_intro or (is_instance_valid(game) and not game.hud.any_modal_open() and not game._story_active and not is_instance_valid(game.home_interior))
	var beat := -1
	if full_intro and introduce_shore: beat = 0 if visible_time < 2 else (1 if visible_time < 3.4 else 2)
	elif not full_intro:
		for i in shore_times.size():
			var local_time := elapsed - float(shore_times[i]) + ArrivalDB.WARNING
			if i not in resolved_shore and local_time >= 0 and local_time <= ArrivalDB.WARNING:
				beat = i * 3 + (0 if local_time < 6.6 else (1 if local_time < 7.3 else 2))
				break
	if beat != _sound_beat and beat >= 0:
		_sound_beat = beat
		if _voice != null and not GameSettings.mute_all() and GameSettings.effects_volume() > 0 and GameSettings.master_volume() > 0:
			_voice.stream = Sfx.urchin_arrival_sound(["surf", "sand", "rattle"][beat % 3])
			_voice.play()
	if full_intro and introduce_fire and introduce_shore and elapsed >= 7.0: _voice.stop()
	queue_redraw()

func _bearing(at: Vector2) -> String:
	var direction := at - home.player.global_position
	return ("east" if direction.x > 0 else "west") if absf(direction.x) > absf(direction.y) else ("south" if direction.y > 0 else "north")

func _draw() -> void:
	if not is_instance_valid(home): return
	var reduced := GameSettings.reduce_motion()
	for i in _feet.size():
		if i in resolved_shore or (full_intro and i > 0): continue
		if not full_intro and (elapsed < float(shore_times[i]) - ArrivalDB.WARNING or elapsed > float(shore_times[i])): continue
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
	var game := get_tree().get_first_node_in_group("game") as Game
	if is_instance_valid(_previous_camera) and is_instance_valid(_camera) and get_viewport().get_camera_2d() == _camera and is_instance_valid(game) and game.world == home and serial == GameState.journey_serial: _previous_camera.make_current()
	completed.emit()
	queue_free()

func cancel() -> void:
	cancelled = true
	finish()
