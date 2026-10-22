extends Node
## Non-destructive visual review harness (task §9).
##
## Renders fixed scenarios (title, lobby, shops, panels, dungeon, HUD at two
## window sizes) to PNGs so visual work can be judged without running the
## destructive tide_capture tool. It NEVER calls GameState.delete_save() and
## writes to an absolute path outside res:// (default /home/z/my-project/shots).
##
## Run with a virtual display:
##   xvfb-run -a -s "-screen 0 1280x720x24" env LIBGL_ALWAYS_SOFTWARE=1 \
##     godot --path . res://tools/visual_review.tscn -- [--shots DIR] [--only NAME]


const DEFAULT_SHOT_DIR := "/home/z/my-project/shots"

var shot_dir := DEFAULT_SHOT_DIR
var only := ""
var game: Node
var hud: Node


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for i in range(0, args.size() - 1, 2):
		if args[i] == "--shots":
			shot_dir = args[i + 1]
		elif args[i] == "--only":
			only = args[i + 1]
	DirAccess.make_dir_recursive_absolute(shot_dir)
	print("visual_review: writing to ", shot_dir)

	game = load("res://scenes/game.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	await _shot("01_title")

	game.call("_on_character_selected", "qayyim")
	await get_tree().create_timer(0.6).timeout
	hud = game.get("hud")
	if hud != null and hud.tutorial_guide != null:
		hud.tutorial_guide.call("_skip")
	await get_tree().create_timer(0.3).timeout
	await _shot("02_lobby_home")

	var player: Node = game.call("player")
	if player != null:
		player.global_position = Vector2(34.0, 14.5)
		await get_tree().create_timer(0.4).timeout
	await _shot("03_lobby_portals")

	if player != null:
		player.global_position = Vector2(23.8, 24.5)
		await get_tree().create_timer(0.4).timeout
	await _shot("04_lobby_market")

	await _capture_shop("05_shop_potion", "potion", "Mara")
	await _capture_shop("06_shop_equipment", "equipment", "Garrick")
	await _capture_shop("07_shop_pet", "pet", "Nia")

	game.call("open_house")
	await get_tree().create_timer(0.5).timeout
	await _shot("08_house_bram")
	hud.hide_modals()
	await get_tree().process_frame

	game.call("open_inventory")
	await get_tree().create_timer(0.5).timeout
	await _shot("09_inventory")
	hud.hide_modals()
	await get_tree().process_frame

	game.call("enter_portal", "tidebound_grotto")
	await get_tree().create_timer(1.0).timeout
	await _shot("10_dungeon_grotto")

	game.call("return_to_lobby", true)
	await get_tree().create_timer(1.2).timeout

	# Narrow window: HUD and modal fit checks at 832x480.
	get_window().size = Vector2(832, 480)
	await get_tree().create_timer(0.3).timeout
	await _shot("11_hud_832x480")
	game.call("open_shop", "potion", "Mara")
	await get_tree().create_timer(0.5).timeout
	await _shot("12_shop_832x480")
	hud.hide_modals()
	await get_tree().process_frame

	print("visual_review: done")
	get_tree().quit(0)


func _capture_shop(shot_name: String, kind: String, keeper: String) -> void:
	game.call("open_shop", kind, keeper)
	await get_tree().create_timer(0.5).timeout
	await _shot(shot_name)
	hud.hide_modals()
	await get_tree().process_frame


func _shot(shot_name: String) -> void:
	if only != "" and only != shot_name:
		return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := shot_dir.path_join(shot_name + ".png")
	var err := image.save_png(path)
	print("visual_review: ", shot_name, " -> ", path, " (", "ok" if err == OK else str(err), ")")
