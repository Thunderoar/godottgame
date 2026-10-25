class_name OceanJourney
extends Node2D
## Automatic turtle journey. Touch and keyboard share the two InputMap actions.
enum Phase { DIVE, RESCUE, RUNNING, FINISHED }
const MAX_HEALTH := 5
const INITIAL_SPEED := 3.2
const SPEED_PER_SECOND := 0.035
const MAX_SPEED := 11.0
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
	_rng.seed = 80531
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
	_refresh_ui()

func get_player() -> Player:
	return player

func speed() -> float:
	return minf(MAX_SPEED, INITIAL_SPEED + elapsed * SPEED_PER_SECOND)

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
	turtle.modulate = Color("#ff8f8f") if _hurt_time > 0 else Color.WHITE
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
		phase = Phase.RUNNING
		_status.text = "Wait for an item in the glowing ring. Pick Up rubbish • Eat food."

func _update_run(delta: float) -> void:
	elapsed += delta
	turtle.position = TURTLE_AT + Vector2(0, 0 if GameSettings.reduce_motion() else sin(_clock * 2) * 0.08)
	player.position = turtle.position + Vector2(-0.55, -1.0)
	_spawn_clock -= delta
	if _spawn_clock <= 0:
		spawn_item("trash" if _rng.randf() < 0.5 else "food")
		_spawn_clock = maxf(1.1, 2.4 - elapsed * 0.006)
	for item in items.duplicate():
		if item.get("resolved", false):
			continue
		var sprite := item.node as Sprite2D
		sprite.position.x -= speed() * delta
		sprite.position.y = TURTLE_AT.y + 0.1 + (0.0 if GameSettings.reduce_motion() else sin(_clock * 3 + float(item.phase)) * 0.12)
		if sprite.position.x < mouth_position().x - ACTION_REACH:
			_resolve_item(item, false)
			if item.kind == "trash":
				_mistake("Rubbish passed the turtle. Use Pick Up in the ring.")
		if phase == Phase.FINISHED:
			break

func spawn_item(kind: String, at_x: float = 43.0) -> Dictionary:
	var sprite := Sprite2D.new()
	sprite.texture = PixelArt.rubbish_texture(0) if kind == "trash" else CoastalArt.food_texture()
	sprite.scale = Vector2.ONE * PixelArt.PX * 1.8
	sprite.position = Vector2(at_x, TURTLE_AT.y + 0.1)
	sprite.z_index = 7
	add_child(sprite)
	var tag := Label.new()
	tag.text = "RUBBISH" if kind == "trash" else "FOOD"
	tag.scale = Vector2.ONE / 1.8
	tag.position = Vector2(-20, -24)
	tag.add_theme_font_size_override("font_size", 12)
	tag.add_theme_color_override("font_color", Color("#e4b6c6") if kind == "trash" else Color("#ffe09a"))
	tag.add_theme_color_override("font_shadow_color", Color("#102838"))
	sprite.add_child(tag)
	var item := {"kind": kind, "node": sprite, "resolved": false, "phase": _rng.randf_range(0, TAU)}
	items.append(item)
	return item

func actionable_item() -> Dictionary:
	var closest: Dictionary = {}
	var distance := ACTION_REACH + 0.001
	for item in items:
		if item.resolved:
			continue
		var d := absf((item.node as Sprite2D).position.x - mouth_position().x)
		if d < distance:
			closest = item
			distance = d
	return closest

func choose_action(action: String) -> bool:
	if phase != Phase.RUNNING or action not in ["pickup", "eat"]:
		return false
	var item := actionable_item()
	if item.is_empty():
		_status.text = "Wait until the item reaches the glowing ring."
		return false
	var correct: bool = (action == "pickup" and item.kind == "trash") or (action == "eat" and item.kind == "food")
	_resolve_item(item, correct)
	if action == "pickup":
		player.play_pickup(3.2)
	else:
		_mouth_time = 0.4
	if not correct:
		_mistake("Wrong action! Pick Up rubbish and Eat food.")
		return false
	if action == "pickup":
		trash_collected += 1
		GameState.register_rubbish_cleaned(1)
		_status.text = "Rubbish collected • +1 Gold"
		Sfx.play("coin", -10)
	else:
		food_eaten += 1
		health = mini(MAX_HEALTH, health + 1)
		_status.text = "The turtle eats • +1 Health"
		Sfx.play("skill_recover", -15)
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
	if phase != Phase.RUNNING:
		return
	health = maxi(0, health - 1)
	mistakes += 1
	_hurt_time = 0.45
	_status.text = message
	Sfx.play("deny", -11)
	if health == 0:
		phase = Phase.FINISHED
		_pickup.cancel()
		_eat.cancel()
		_status.text = "Journey complete • %d rubbish collected • %d food eaten. Ride again or return to shore." % [trash_collected, food_eaten]
		_retry.visible = true

func restart() -> void:
	if phase != Phase.FINISHED:
		return
	for item in items:
		(item.node as Node).queue_free()
	items.clear()
	health = MAX_HEALTH
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
	_score.text = "Rubbish %d    Food %d    Speed %.1fx    Journey %ds    Gold %d" % [trash_collected, food_eaten, speed() / INITIAL_SPEED, int(elapsed), GameState.gold()]
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
