extends SceneTree
## Headless smoke test + screenshot harness.
##
##   godot --headless --path <project> --script tools/smoke_test.gd
##
## Loads the converted scene, walks it looking for the nodes the port is
## supposed to produce, and (with --shot <path>) saves a viewport capture.

const SCENE := "res://scenes/main.tscn"


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var shot := ""
	for i in args.size():
		if args[i] == "--shot" and i + 1 < args.size():
			shot = args[i + 1]

	var packed: PackedScene = load(SCENE)
	if packed == null:
		print("FAIL: could not load " + SCENE)
		quit(1)
		return

	var world := packed.instantiate()
	get_root().add_child(world)
	await process_frame
	await process_frame

	print("--- scene summary ---")
	_summary(world, 0)
	var cam := _first(world, "Camera2D") as Camera2D
	if cam:
		var vp := get_root()
		print("camera pos=%s zoom=%s current=%s" % [cam.global_position, cam.zoom, cam.is_current()])
		print("viewport visible=%s size=%s" % [cam.get_viewport_rect().size, vp.size])
		print("screen center=%s" % [cam.get_screen_center_position()])
		var xf := cam.get_screen_transform()
		var a: Vector2 = xf * Vector2(0, 0)
		var b: Vector2 = xf * Vector2(0, 1)
		print("pixels per world unit = %s ; origin at %s" % [(b - a).length(), a])
	_expect(world)

	if shot != "":
		await process_frame
		await process_frame
		await process_frame
		var img := get_root().get_texture().get_image()
		var err := img.save_png(shot)
		print("screenshot -> %s (%d)" % [shot, err])

	world.queue_free()
	quit(0)


func _summary(node: Node, depth: int) -> void:
	if node is Node2D and node is TileMapLayer:
		var t: TileMapLayer = node
		print("%s%-28s cells=%d" % ["  ".repeat(depth), node.name, t.get_used_cells().size()])
	for c in node.get_children():
		_summary(c, depth + 1)


func _expect(world: Node) -> void:
	var checks := {
		"player (CharacterBody2D)": _find(world, "PF Player", "CharacterBody2D"),
		"camera (Camera2D)": _find(world, "Main Camera", "Camera2D"),
		"chest (Area2D)": _find(world, "PF Props - Chest 01", "Area2D"),
		"popup (ColorRect)": _find(world, "Panel", "ColorRect"),
		"stairs triggers (Area2D)": _count(world, "stairs_layer_trigger.gd"),
	}
	print("--- checks ---")
	var failed := 0
	for label in checks:
		var value: Variant = checks[label]
		var ok: bool = int(value) > 0
		if not ok:
			failed += 1
		print("  [%s] %s -> %s" % ["OK" if ok else "MISSING", label, value])
	print("--- result: %s ---" % ("PASS" if failed == 0 else "%d MISSING" % failed))


func _first(node: Node, type: String) -> Node:
	if node.is_class(type):
		return node
	for c in node.get_children():
		var hit := _first(c, type)
		if hit:
			return hit
	return null


func _find(node: Node, name: String, type: String) -> int:
	if node.name == name and node.is_class(type):
		return 1
	for c in node.get_children():
		if _find(c, name, type) > 0:
			return 1
	return 0


func _count(node: Node, script_suffix: String) -> int:
	var total := 0
	var sc: Variant = node.get_script()
	if sc != null and str(sc.resource_path).ends_with(script_suffix):
		total += 1
	for c in node.get_children():
		total += _count(c, script_suffix)
	return total