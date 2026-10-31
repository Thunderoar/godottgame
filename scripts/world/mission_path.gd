class_name MissionPath
extends Node2D
## Ground-level dashed arrows follow the same obstacle-aware roads as villagers.

var _points := PackedVector2Array()
var _clock := 0.0
var _dungeon_routes: ResidentRoutes


func _ready() -> void:
	z_as_relative = false
	z_index = 4

func refresh_guidance() -> void:
	_clock = 0.0
	_points.clear()
	queue_redraw()


func _process(delta: float) -> void:
	var game := get_tree().get_first_node_in_group("game") as Game
	# Hide the tutorial trail with its tips, including cached arrows between refreshes.
	# Completed training keeps the separate campaign/project navigation unchanged.
	if is_instance_valid(game) and is_instance_valid(game.hud) and not game.hud.has_tracked_objective() and not GameState.tutorial_complete() and is_instance_valid(game.hud.tutorial_guide) and not game.hud.tutorial_guide.visible:
		if not _points.is_empty():
			_points.clear()
			queue_redraw()
		_clock = 0.0
		return
	_clock -= delta
	if _clock > 0.0:
		return
	_clock = 0.5
	_points.clear()
	var world := get_parent()
	if game == null or game.world != world or GameState.game_over_active:
		queue_redraw()
		return
	var player := game.player()
	if not is_instance_valid(player) or is_instance_valid(game.home_interior) or game._transitioning or game._story_active or game.hud.any_modal_open():
		queue_redraw()
		return
	var targets: Array = game.hud.tracked_guidance_targets(world) if game.hud.has_tracked_objective() else (world.call("get_guidance_targets") if world.has_method("get_guidance_targets") else [])
	if targets.is_empty():
		queue_redraw()
		return
	var destination: Vector2 = (targets[0] as Dictionary).get("position", player.global_position)
	if world is Lobby:
		_points = (world as Lobby).resident_path(player.global_position, destination)
	else:
		if _dungeon_routes == null:
			_dungeon_routes = ResidentRoutes.new(world, world.get_map_rect())
		_points = _dungeon_routes.path(player.global_position, destination)
	_points.insert(0, player.global_position)
	queue_redraw()


func _draw() -> void:
	if _points.size() < 2:
		return
	var carry := 0.3
	for i in range(1, _points.size()):
		var start := _points[i - 1]
		var offset := _points[i] - start
		var length := offset.length()
		if length < 0.01:
			continue
		var direction := offset / length
		var side := direction.orthogonal()
		while carry < length:
			var at := start + direction * carry
			draw_line(at, at + direction * 0.32, Color("#273b37"), 0.14)
			draw_line(at, at + direction * 0.32, Color("#ffe9a1"), 0.07)
			draw_colored_polygon(PackedVector2Array([at + direction * 0.48, at + direction * 0.24 + side * 0.15, at + direction * 0.24 - side * 0.15]), Color("#ffe9a1"))
			carry += 0.9
		carry -= length
