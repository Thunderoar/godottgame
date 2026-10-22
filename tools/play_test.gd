extends SceneTree
## Gameplay smoke test for the ported scene.
##
##   godot --path <project> --script tools/play_test.gd -- --shots <dir>
##
## Drives the same interactions the Unity build supported - click-to-move,
## WASD steering, walking up to the chest and pressing E - and asserts that the
## world, the chest artwork and the welcome popup all respond.

const SCENE := "res://scenes/main.tscn"

var world: Node
var player: CharacterBody2D
var chest: Area2D
var popup: Control
var shots := ""


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--shots" and i + 1 < args.size():
			shots = args[i + 1]

	world = load(SCENE).instantiate()
	get_root().add_child(world)
	await process_frame
	await process_frame

	player = _find_node(world, "PF Player") as CharacterBody2D
	chest = _find_node(world, "PF Props - Chest 01") as Area2D
	popup = _find_node(world, "Panel") as Control

	if player == null or chest == null or popup == null:
		print("FAIL: missing node (player=%s chest=%s popup=%s)" % [player, chest, popup])
		quit(1)
		return

	var fails := 0
	fails += _test_start_state()
	fails += await _test_click_to_move()
	fails += await _test_keyboard()
	fails += await _test_chest()
	fails += await _test_stairs()

	print("--- play test: %s ---" % ("PASS" if fails == 0 else "%d FAILURE(S)" % fails))
	world.queue_free()
	quit(0 if fails == 0 else 1)


func _test_start_state() -> int:
	var ok := true
	print("[start] player at %s" % player.global_position)
	ok = _check(player.is_in_group("player"), "player is in the 'player' group") and ok
	ok = _check(player.velocity == Vector2.ZERO, "player starts still") and ok
	ok = _check(popup.modulate.a < 0.01, "popup starts hidden") and ok
	ok = _check(_chest_texture_open() == false, "chest starts closed") and ok
	_shot("start.png")
	return 0 if ok else 1


func _test_click_to_move() -> int:
	var start := player.global_position
	# Click to the left of the player so the walk cannot be blocked by the chest.
	var click := Vector2(start.x - 1.2, start.y)
	var cam := get_root().get_camera_2d()
	# Viewport::get_canvas_transform() is world -> screen; Camera2D.get_screen_transform()
	# is the screen-space transform, which is not the same thing.
	var screen: Vector2 = get_root().get_canvas_transform() * click
	_click(screen)
	print("[click] world=%s screen=%s start=%s" % [click, screen, start])
	var moved := await _wait_until(func() -> bool:
		return player.global_position.distance_to(start) > 0.25, 2.0)
	var ok := _check(moved, "click-to-move walks the character")
	await _wait(0.9)
	print("[click] ended at %s" % player.global_position)
	ok = _check(player.global_position.x < start.x - 0.3, "character moved towards the click") and ok
	ok = _check(_marker_visible(), "click marker was shown") and ok
	return 0 if ok else 1


func _marker_visible() -> bool:
	for c in get_root().get_children():
		if c.name == "ClickMarker":
			return true
	return false


func _test_keyboard() -> int:
	var before := player.global_position
	Input.action_press("move_right")
	await _wait(0.4)
	Input.action_release("move_right")
	await _wait(0.1)
	var ok := _check(player.global_position.x > before.x, "keyboard steers the character")
	before = player.global_position
	Input.action_press("move_up")
	await _wait(0.4)
	Input.action_release("move_up")
	await _wait(0.1)
	# Godot is Y-down, so "up" must lower the character's y.
	ok = _check(player.global_position.y < before.y, "W moves up the screen (Y-down world)") and ok
	return 0 if ok else 1


func _test_chest() -> int:
	# Stand next to the chest, then press E.
	var chest_pos := chest.global_position
	player.global_position = chest_pos + Vector2(-0.9, 0.0)
	player.velocity = Vector2.ZERO
	await _wait(0.25)
	_shot("before_chest.png")

	var in_range: bool = chest.get_node_or_null("Sprite") != null
	_input_key(KEY_E)
	var opened := await _wait_until(func() -> bool: return _chest_texture_open(), 1.0)
	var ok := _check(opened, "pressing E swaps the chest to its open artwork")
	var shown := await _wait_until(func() -> bool: return popup.modulate.a > 0.4, 1.5)
	ok = _check(shown, "welcome popup fades in")
	await _wait(0.2)
	_shot("chest_open.png")
	await _wait(3.2)
	ok = _check(popup.modulate.a < 0.2, "welcome popup fades back out") and ok
	return 0 if ok else 1


func _test_stairs() -> int:
	var triggers := []
	_collect_scripts(world, "stairs_layer_trigger.gd", triggers)
	var ok := _check(triggers.size() >= 1, "stairs triggers present (%d)" % triggers.size())
	if triggers.is_empty():
		return 0 if ok else 1

	# Stand on the "upper" side of a south-facing trigger and confirm the draw
	# order switch the original script performed still happens.
	var trigger: Area2D = null
	for t in triggers:
		if int(t.get("direction")) == 1:   # Direction.SOUTH
			trigger = t
			break
	if trigger == null:
		trigger = triggers[0]

	var sprite := player.get_node_or_null("Sprite") as Sprite2D
	var was := sprite.z_index
	player.global_position = trigger.global_position + Vector2(0, 0.3)
	player.velocity = Vector2.ZERO
	await _wait(0.4)
	print("[stairs] sprite z %d -> %d (upper=%s lower=%s)" % [was, sprite.z_index,
		trigger.get("z_upper"), trigger.get("z_lower")])
	ok = _check(sprite.z_index != was, "stairs trigger changes the player's draw order")
	ok = _check(sprite.z_index == int(trigger.get("z_upper")),
			"player moved onto the upper storey's sorting layer") and ok
	_shot("stairs.png")
	return 0 if ok else 1


# ---------------------------------------------------------------- helpers

func _chest_texture_open() -> bool:
	var sprite := chest.get_node_or_null("Sprite") as Sprite2D
	if sprite == null or sprite.texture == null:
		return false
	return str(sprite.texture.resource_path).contains("Opened")


func _click(screen_pos: Vector2) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = screen_pos
	ev.global_position = screen_pos
	get_root().push_input(ev)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = screen_pos
	up.global_position = screen_pos
	get_root().push_input(up)


func _input_key(keycode: int) -> void:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.physical_keycode = keycode
	ev.pressed = true
	get_root().push_input(ev)
	var up := InputEventKey.new()
	up.keycode = keycode
	up.physical_keycode = keycode
	up.pressed = false
	get_root().push_input(up)


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _wait_until(cond: Callable, timeout: float) -> bool:
	var elapsed := 0.0
	while elapsed < timeout:
		if cond.call():
			return true
		await process_frame
		elapsed += 1.0 / 60.0
	return cond.call()


func _shot(name: String) -> void:
	if shots == "":
		return
	for i in 4:
		await process_frame
	var img := get_root().get_texture().get_image()
	var path := shots.path_join(name)
	img.save_png(path)
	print("  shot -> %s" % path)


func _check(cond: bool, label: String) -> bool:
	print("  [%s] %s" % ["OK" if cond else "FAIL", label])
	return cond


func _find_node(root: Node, name: String) -> Node:
	if root.name == name:
		return root
	for c in root.get_children():
		var hit := _find_node(c, name)
		if hit:
			return hit
	return null


func _collect_scripts(node: Node, suffix: String, out: Array) -> void:
	var sc: Variant = node.get_script()
	if sc != null and str(sc.resource_path).ends_with(suffix):
		out.append(node)
	for c in node.get_children():
		_collect_scripts(c, suffix, out)