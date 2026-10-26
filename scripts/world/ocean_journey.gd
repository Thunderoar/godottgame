class_name OceanJourney
extends Node2D
## Automatic turtle journey. Touch and keyboard share the two InputMap actions.
enum Phase { DIVE, RESCUE, RUNNING, FINISHED }
const MAX_HEALTH := 3
const START_MULTIPLIER := 2.5
const STAGE_SECONDS := 45.0
const VERTICAL_SPEED := 7.0
const HIT_IMMUNITY := 1.4
const INITIAL_SPEED := 3.2
const SPEED_PER_SECOND := 0.035
const MAX_SPEED := 27.5
const ACTION_REACH := 2.2
const TURTLE_AT := Vector2(9.2, 12.8)
var zone_name := "Turtle Ocean Journey"
var phase := Phase.DIVE
var player: Player
var camera: Camera2D
var turtle: Sprite2D
var health := MAX_HEALTH
var elapsed := 0.0
var trash_collected := 0
var food_eaten := 0
var mistakes := 0
var items: Array[Dictionary] = []
var stage := 1
var stage_cleared := false
var _turtle_y := TURTLE_AT.y
var _heart_clock := 12.0
var _bomb_clock := 3.0
var _sink_time := 0.0
var _ocean_joystick: TouchJoystick
var _ocean_settings: SettingsPanel
var _intro := 0.0
var _clock := 0.0
var _spawn_clock := 1.2
var _mouth_time := 0.0
var _hurt_time := 0.0
var _rng := RandomNumberGenerator.new()
var _layer: CanvasLayer
var _status: Label
var _vitals: Label
var _score: Label
var _pickup: TouchActionButton
var _eat: TouchActionButton
var _retry: Button
var _return: Button

func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	Vfx.ensure_pool(self)
	stage = int(GameState.campaign().get("ocean_stage", 1))
	_rng.randomize()
	camera = Camera2D.new()
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	camera.position = Vector2(20, 11.25)
	camera.zoom = Vector2.ONE * 32
	add_child(camera)
	camera.make_current()
	player = Player.new()
	player.position = Vector2(9.2, 4.5)
	add_child(player)
	player.controls_locked = true
	player.collision_mask = 0
	player.facing = Vector2.RIGHT
	player._visual.set_facing(2, false)
	var vitals := player.get_node_or_null("VitalHud") as Node2D
	if vitals:
		vitals.visible = false
	turtle = Sprite2D.new()
	turtle.texture = CoastalArt.turtle_texture()
	turtle.scale = Vector2.ONE * PixelArt.PX * 1.6
	turtle.position = Vector2(-6, 12.8)
	turtle.z_index = 5
	add_child(turtle)
	_build_ui()
	_build_ocean_controls()
	_refresh_ui()

func get_player() -> Player:
	return player

func speed() -> float:
	return minf(MAX_SPEED, INITIAL_SPEED * START_MULTIPLIER + elapsed * SPEED_PER_SECOND + (stage - 1) * 0.8)

func mouth_position() -> Vector2:
	return turtle.position + Vector2(2.1, 0.1)

func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 20
	add_child(_layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(root)
	var header := GameUI.panel(Color("#102e40"), Color("#4b8e9b"))
	header.anchor_right = 1
	header.offset_left = 22
	header.offset_top = 18
	header.offset_right = -22
	header.offset_bottom = 118
	root.add_child(header)
	var box := VBoxContainer.new()
	header.add_child(box)
	box.add_child(GameUI.label("TURTLE OCEAN JOURNEY", 24, Color("#ffe2a0")))
	_vitals = GameUI.label("", 19, Color("#baf3df"))
	box.add_child(_vitals)
	_score = GameUI.label("", 14, Color("#afdae2"))
	box.add_child(_score)
	_status = GameUI.label("", 18, Color("#fff0c6"))
	_status.anchor_left = 0.08
	_status.anchor_right = 0.92
	_status.anchor_top = 0.7
	_status.offset_bottom = 65
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_status)
	_pickup = TouchActionButton.new()
	_pickup.action = "ocean_pickup"
	_pickup.caption = "Pick Up"
	_pickup.icon_kind = "gather"
	_pickup.accent = Color("#79d9d1")
	_pickup.diameter = 104
	_place_action(root, _pickup, -266)
	_pickup.set_key_hint("E")
	_eat = TouchActionButton.new()
	_eat.action = "ocean_eat"
	_eat.caption = "Eat"
	_eat.icon_kind = "food"
	_eat.accent = Color("#f0cc72")
	_eat.diameter = 104
	_place_action(root, _eat, -136)
	_eat.set_key_hint("F")
	_return = GameUI.button("Return to Shore", Vector2(170, 40))
	_return.anchor_left = 1
	_return.anchor_right = 1
	_return.offset_left = -210
	_return.offset_right = -40
	_return.offset_top = 140
	_return.offset_bottom = 180
	_return.pressed.connect(return_to_shore)
	root.add_child(_return)
	_retry = GameUI.button("Ride Again", Vector2(180, 48))
	_retry.anchor_left = 0.5
	_retry.anchor_right = 0.5
	_retry.anchor_top = 0.85
	_retry.anchor_bottom = 0.85
	_retry.offset_left = -90
	_retry.offset_right = 90
	_retry.offset_bottom = 48
	_retry.visible = false
	_retry.pressed.connect(restart)
	root.add_child(_retry)

func _place_action(root: Control, button: TouchActionButton, left: float) -> void:
	button.anchor_left = 1
	button.anchor_right = 1
	button.anchor_top = 1
	button.anchor_bottom = 1
	button.offset_left = left
	button.offset_right = left + 104
	button.offset_top = -132
	button.offset_bottom = -28
	root.add_child(button)

func _process(delta: float) -> void:
	_clock += delta
	if phase in [Phase.DIVE, Phase.RESCUE]:
		_advance_intro(delta)
	elif phase == Phase.RUNNING:
		_update_run(delta)
		if Input.is_action_just_pressed("ocean_pickup"):
			choose_action("pickup")
		elif Input.is_action_just_pressed("ocean_eat"):
			choose_action("eat")
	_mouth_time = maxf(0, _mouth_time - delta)
	_hurt_time = maxf(0, _hurt_time - delta)
	turtle.texture = CoastalArt.turtle_texture(_mouth_time > 0, 0 if GameSettings.reduce_motion() else int(_clock * 3) % 2)
	turtle.modulate = Color(1, 0.65, 0.65, 0.25 if int(_hurt_time * 12) % 2 else 1.0) if _hurt_time > 0 else Color.WHITE
	if phase == Phase.FINISHED and health == 0:
		_sink_time += delta
		turtle.rotation = lerpf(0.0, PI, clampf(_sink_time, 0, 1))
		turtle.position.y += delta * 1.8
		turtle.modulate.a = maxf(0, 1.0 - (_sink_time - 0.8) / 1.4)
		player.modulate.a = turtle.modulate.a
		player.position = turtle.position + Vector2(-0.55, -1.0)
		_retry.visible = _sink_time >= 2.0
	_refresh_ui()
	queue_redraw()

func _advance_intro(delta: float) -> void:
	_intro += delta
	if _intro < 1.6:
		player.position = Vector2(9.2, lerpf(4.5, 12.1, clampf(_intro / 1.6, 0, 1)))
		_status.text = "Diving below the waves..."
	elif _intro < 3.3:
		phase = Phase.RESCUE
		turtle.position = Vector2(lerpf(-6.0, TURTLE_AT.x, clampf((_intro - 1.6) / 1.7, 0, 1)), TURTLE_AT.y)
		_status.text = "A sea turtle comes to help!"
	else:
		turtle.position = TURTLE_AT
		player.position = turtle.position + Vector2(-0.55, -1.0)
		player.reset_physics_interpolation()
		turtle.reset_physics_interpolation()
		phase = Phase.RUNNING
		_status.text = "Move up/down to dodge bombs. Pick Up rubbish · Eat food · Eat pink hearts for lives."

func _update_run(delta: float) -> void:
	if is_instance_valid(_ocean_settings) and _ocean_settings.visible: return
	elapsed += delta
	_turtle_y = clampf(_turtle_y + Input.get_axis("move_up", "move_down") * VERTICAL_SPEED * delta, 6.8, 18.0)
	turtle.position = Vector2(TURTLE_AT.x, _turtle_y)
	player.position = turtle.position + Vector2(-0.55, -1.0)
	_spawn_clock -= delta
	_heart_clock -= delta
	_bomb_clock -= delta
	if _spawn_clock <= 0:
		spawn_item("trash" if _rng.randf() < 0.5 else "food")
		_spawn_clock = maxf(1.2, 2.1 - stage * 0.15)
	if _heart_clock <= 0:
		spawn_item("heart")
		_heart_clock = _rng.randf_range(15, 20)
	if _bomb_clock <= 0:
		spawn_item("bomb")
		_bomb_clock = _rng.randf_range(2.2, 3.4) - stage * 0.15
	for item in items.duplicate():
		if item.get("resolved", false): continue
		var sprite := item.node as Sprite2D
		var previous := sprite.position
		sprite.position.x -= speed() * delta
		sprite.position.y = float(item.get("lane", TURTLE_AT.y)) + sin(_clock * (1.4 if item.kind == "bomb" else 3.0) + float(item.phase)) * (1.4 if item.kind == "bomb" else 0.12)
		if item.kind == "bomb":
			# Swept hit test prevents fast bombs tunnelling through the shell.
			var closest := Geometry2D.get_closest_point_to_segment(turtle.position + Vector2(0.6, 0), previous, sprite.position)
			if closest.distance_to(turtle.position + Vector2(0.6, 0)) < 1.5 and _hurt_time <= 0:
				var blast_at := sprite.position
				_resolve_item(item, false)
				Vfx.burst(blast_at, Color("#ff9c45"), 14)
				Vfx.ring(blast_at, 2.5, Color("#ffe09a"), 0.45)
				Sfx.play("hit", -7)
				_mistake("Bomb! Move up or down to dodge. You are briefly protected.")
		if not item.get("resolved", false) and sprite.position.x < mouth_position().x - ACTION_REACH:
			_resolve_item(item, false)
		if phase == Phase.FINISHED: break
	if elapsed >= STAGE_SECONDS and phase == Phase.RUNNING:
		_complete_stage()

func spawn_item(kind: String, at_x: float = 43.0) -> Dictionary:
	var sprite := Sprite2D.new()
	match kind:
		"trash": sprite.texture = PixelArt.rubbish_texture(0)
		"heart": sprite.texture = CampaignArt.heart_texture()
		"bomb": sprite.texture = CampaignArt.bomb_texture()
		_: sprite.texture = CoastalArt.food_texture()
	sprite.scale = Vector2.ONE * PixelArt.PX * 1.8
	var lane := clampf(_turtle_y + _rng.randf_range(-4.0, 4.0), 7.0, 18.0) if at_x >= 40.0 else mouth_position().y
	sprite.position = Vector2(at_x, lane)
	sprite.z_index = 7
	add_child(sprite)
	var tag := Label.new()
	tag.text = {"trash": "PICK UP", "food": "EAT", "heart": "+1 LIFE · EAT", "bomb": "DODGE!"}.get(kind, "")
	tag.scale = Vector2.ONE / 1.8
	tag.position = Vector2(-20, -24)
	tag.add_theme_font_size_override("font_size", 12)
	tag.add_theme_color_override("font_color", Color("#ffabbe") if kind in ["heart", "bomb"] else Color("#ffe09a"))
	tag.add_theme_color_override("font_shadow_color", Color("#102838"))
	sprite.add_child(tag)
	var item := {"kind": kind, "node": sprite, "resolved": false, "lane": lane, "phase": _rng.randf_range(0, TAU)}
	items.append(item)
	return item

func actionable_item() -> Dictionary:
	var closest: Dictionary = {}
	var distance := ACTION_REACH + 0.001
	for item in items:
		if item.resolved or item.kind == "bomb": continue
		var d := (item.node as Sprite2D).position.distance_to(mouth_position())
		if d < distance:
			closest = item
			distance = d
	return closest

func choose_action(action: String) -> bool:
	if phase != Phase.RUNNING or action not in ["pickup", "eat"] or (is_instance_valid(_ocean_settings) and _ocean_settings.visible): return false
	var item := actionable_item()
	if item.is_empty():
		_status.text = "Move to the item, then act inside the glowing ring. Dodge bombs!"
		return false
	var correct: bool = (action == "pickup" and item.kind == "trash") or (action == "eat" and item.kind in ["food", "heart"])
	_resolve_item(item, correct)
	if action == "pickup": player.play_pickup(3.2)
	else: _mouth_time = 0.4
	if not correct:
		_mistake("Wrong action! Pick Up rubbish; Eat food or pink hearts.")
		return false
	if item.kind == "trash":
		trash_collected += 1
		GameState.register_rubbish_cleaned(1)
		_status.text = "Rubbish collected · +1 Gold"
		Sfx.play("coin", -10)
	elif item.kind == "heart":
		health = mini(MAX_HEALTH, health + 1)
		_status.text = "Heart collected · +1 turtle life"
		Vfx.burst(mouth_position(), Color("#ff8eae"), 12)
		Vfx.ring(turtle.position, 2.0, Color("#ffbdd4"), 0.6)
		Sfx.play("skill_recover", -12)
	else:
		food_eaten += 1
		_status.text = "Food eaten. Only pink hearts restore a life."
		Vfx.sparks(mouth_position(), Vector2.UP, Color("#ffe09a"), 5)
	return true

func _resolve_item(item: Dictionary, animate: bool) -> void:
	if item.resolved:
		return
	item.resolved = true
	items.erase(item)
	var sprite := item.node as Sprite2D
	if animate:
		var tween := sprite.create_tween().set_parallel(true)
		tween.tween_property(sprite, "position", mouth_position(), 0.22)
		tween.tween_property(sprite, "scale", Vector2.ZERO, 0.22)
		tween.chain().tween_callback(sprite.queue_free)
	else:
		sprite.queue_free()

func _mistake(message: String) -> void:
	if phase != Phase.RUNNING or _hurt_time > 0: return
	health = maxi(0, health - 1)
	mistakes += 1
	_hurt_time = HIT_IMMUNITY
	_status.text = message
	Sfx.play("deny", -11)
	if health == 0:
		phase = Phase.FINISHED
		_sink_time = 0
		_pickup.cancel()
		_eat.cancel()
		_ocean_joystick.cancel()
		_status.text = "The turtle has fallen... Ride Again to retry this sea route. Your cleared routes are safe."
		_retry.text = "Ride Again"
		_retry.visible = false

func restart() -> void:
	if phase != Phase.FINISHED:
		return
	for item in items:
		(item.node as Node).queue_free()
	items.clear()
	health = MAX_HEALTH
	stage = int(GameState.campaign().get("ocean_stage", 1))
	stage_cleared = false
	_turtle_y = TURTLE_AT.y
	_heart_clock = 12.0
	_bomb_clock = 3.0
	_sink_time = 0.0
	turtle.rotation = 0.0
	turtle.modulate = Color.WHITE
	player.modulate = Color.WHITE
	_hurt_time = 0.0
	elapsed = 0
	trash_collected = 0
	food_eaten = 0
	mistakes = 0
	_intro = 0
	_spawn_clock = 1.2
	phase = Phase.DIVE
	_retry.visible = false
	turtle.position = Vector2(-6, 12.8)

func return_to_shore() -> void:
	_pickup.cancel()
	_eat.cancel()
	var game := get_tree().get_first_node_in_group("game") as Game
	if is_instance_valid(game) and game.world == self:
		game.return_from_ocean()

func _refresh_ui() -> void:
	_vitals.text = "TURTLE HEALTH  %s  %d/%d" % ["♥".repeat(health) + "♡".repeat(MAX_HEALTH - health), health, MAX_HEALTH]
	_score.text = "Sea route %d/3 · %ds / %ds · Speed %.1fx · Gold %d" % [stage, mini(int(elapsed), int(STAGE_SECONDS)), int(STAGE_SECONDS), speed() / INITIAL_SPEED, GameState.gold()]
	_pickup.set_touch_enabled(phase == Phase.RUNNING)
	_eat.set_touch_enabled(phase == Phase.RUNNING)

func _exit_tree() -> void:
	Input.action_release("ocean_pickup")
	Input.action_release("ocean_eat")
	if is_instance_valid(_pickup): _pickup.cancel()
	if is_instance_valid(_eat): _eat.cancel()

func _draw() -> void:
	draw_rect(Rect2(-60, -40, 160, 100), Color("#103b59"))
	for band in 12:
		var y := float(band) * 2.2 - 2.0
		draw_rect(Rect2(-40, y, 120, 2.25), Color("#103b59").lerp(Color("#071d35"), clampf(float(band) / 12, 0, 1)))
	for i in 8:
		var x := i * 7.0 - 4
		draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 1, 0), Vector2(x + 8, 19), Vector2(x + 4, 19)]), Color(0.35, 0.79, 0.86, 0.035))
	for i in 32:
		var drift := 0.0 if GameSettings.reduce_motion() else _clock * 0.25
		var x := fposmod(i * 7.17 - drift, 48.0) - 4
		var y := fposmod(i * 2.61 - drift * 1.4, 22.0)
		draw_arc(Vector2(x, y), 0.05 + (i % 3) * 0.025, 0, TAU, 8, Color(0.55, 0.91, 0.95, 0.24), PixelArt.PX)
	for i in 16:
		var x := fposmod(i * 4.31 - elapsed * 0.3, 48) - 4
		draw_line(Vector2(x, 24), Vector2(x + sin(i) * 0.4, 20.7 - (i % 3) * 0.25), Color("#286d73"), 0.16)
	if phase == Phase.RUNNING:
		var point := mouth_position()
		draw_arc(point, ACTION_REACH, 0, TAU, 40, Color(0.6, 0.95, 0.85, 0.35), 0.05)
		draw_line(point + Vector2(0, -2.5), point + Vector2(0, -2.1), Color("#ffe4a0"), 0.07)

func _complete_stage() -> void:
	if stage_cleared: return
	stage_cleared = true
	phase = Phase.FINISHED
	_pickup.cancel()
	_eat.cancel()
	_ocean_joystick.cancel()
	for item in items.duplicate(): _resolve_item(item, false)
	if stage < GameState.OCEAN_STAGES:
		GameState.advance_ocean_stage(stage)
		_status.text = "Route cleared! Next: sea route %d/3. Progress saved." % (stage + 1)
		_retry.text = "Next Sea Route"
		_retry.visible = true
	else:
		_status.text = "Kraken Island! The turtle carries Adam ashore..."
		var ride := create_tween()
		ride.tween_property(turtle, "position:x", 38.0, 2.0)
		await ride.finished
		var game := get_tree().get_first_node_in_group("game") as Game
		if is_instance_valid(game) and game.world == self: game.enter_kraken_island()

func _build_ocean_controls() -> void:
	var root := _pickup.get_parent() as Control
	_ocean_joystick = TouchJoystick.new()
	root.add_child(_ocean_joystick)
	_ocean_settings = SettingsPanel.new()
	root.add_child(_ocean_settings)
	_ocean_settings.closed.connect(_apply_ocean_layout)
	var settings := GameUI.button("Controls", Vector2(110, 40))
	settings.position = Vector2(24, 140)
	settings.pressed.connect(func() -> void:
		_ocean_joystick.cancel()
		_pickup.cancel()
		_eat.cancel()
		_ocean_settings.open_settings())
	root.add_child(settings)
	root.resized.connect(_apply_ocean_layout)
	_apply_ocean_layout()

func _apply_ocean_layout() -> void:
	var view := get_viewport_rect().size
	var defaults := {"ocean_joystick": {"x": 24.0, "y": view.y - 210.0, "size": 180.0}, "ocean_pickup": {"x": view.x - 266.0, "y": view.y - 132.0, "size": 104.0}, "ocean_eat": {"x": view.x - 136.0, "y": view.y - 132.0, "size": 104.0}}
	var controls := {"ocean_joystick": _ocean_joystick, "ocean_pickup": _pickup, "ocean_eat": _eat}
	for id in controls:
		var values: Dictionary = GameState.control_layout().get(id, defaults[id])
		var node := controls[id] as Control
		var extent := clampf(float(values.get("size", 104)), 42, 260)
		node.set_anchors_preset(Control.PRESET_TOP_LEFT)
		node.custom_minimum_size = Vector2.ONE * extent
		node.size = Vector2.ONE * extent
		node.position = Vector2(float(values.get("x", 24)), float(values.get("y", 400))).clamp(Vector2.ZERO, (view - node.size).max(Vector2.ZERO))
		if node is TouchActionButton: node.diameter = extent
		if node is TouchJoystick:
			node.radius = extent * 0.38
			node.knob_radius = extent * 0.16
