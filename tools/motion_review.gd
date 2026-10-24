extends Node
## Deterministic graphical motion review. Use isolated XDG_DATA_HOME and Godot's
## --write-movie OUTPUT.avi --fixed-fps 60 to retain every rendered frame.
var game: Node
var samples: Array = []

func _ready() -> void:
	if not TestEnvironment.require_isolation():
		get_tree().quit(1)
		return
	game = load("res://scenes/game.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await game.call("_on_character_selected", "qayyim")
	await get_tree().process_frame
	var hud: GameHUD = game.hud
	hud.tutorial_guide.call("_skip")
	var lobby: Lobby = game.world
	lobby._rubbish_system.spawn_interval = 99999.0
	for monster in lobby._forest_monsters:
		monster.set_physics_process(false)
	var p: Player = game.call("player")
	p.global_position = Vector2(31, 28)
	p.reset_physics_interpolation()
	lobby.pet.global_position = p.global_position + Vector2(-8, 0)
	lobby.pet.reset_physics_interpolation()
	lobby.camera.global_position = p.global_position + Vector2(0, -1)
	lobby.camera.reset_physics_interpolation()
	var enemy := Enemy.new()
	enemy.position = Vector2(37, 27)
	enemy.speed = 1.2
	enemy.damage = 0
	lobby.add_child(enemy)
	for direction in [["move_right"], ["move_down"], ["move_left"], ["move_up"], ["move_right", "move_down"], ["move_left", "move_down"], ["move_left", "move_up"], ["move_right", "move_up"]]:
		for action in direction:
			Input.action_press(action)
		for frame in 24:
			await _sample_frame(p, lobby)
		for action in direction:
			Input.action_release(action)
		for frame in 8:
			await _sample_frame(p, lobby)
	Input.action_press("move_right")
	for frame in 90:
		await _sample_frame(p, lobby)
	Input.action_release("move_right")
	Input.action_press("move_left")
	for frame in 60:
		await _sample_frame(p, lobby)
	Input.action_release("move_left")
	for frame in 25:
		await _sample_frame(p, lobby)
	for zoom_value in [28, 64, 38]:
		GameSettings.set_camera_zoom(zoom_value, false)
		for frame in 45:
			await _sample_frame(p, lobby)
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2 and args[0] == "--samples":
		var file := FileAccess.open(args[1], FileAccess.WRITE)
		file.store_string(JSON.stringify(samples))
		file.close()
	print("MOTION_REVIEW frames=", samples.size(), " user_data=", OS.get_user_data_dir())
	game.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit()


func _sample_frame(p: Player, lobby: Lobby) -> void:
	await get_tree().physics_frame
	samples.append({"frame": Engine.get_physics_frames(), "player": [p.position.x, p.position.y], "pet": [lobby.pet.position.x, lobby.pet.position.y], "camera": [lobby.camera.position.x, lobby.camera.position.y]})
