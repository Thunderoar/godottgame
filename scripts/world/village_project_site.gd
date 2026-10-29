class_name VillageProjectSite
extends Interactable
## Runtime labor lease and presentation. Saved progress is owned only by GameState.

var project_id := VillageProjectDB.WORKSHOP
var target: SettlementTarget
var _worker: WeakRef
var _worker_hp := 0
var _worker_origin := Vector2.ZERO
var _last_position := Vector2.ZERO
var _stalled := 0.0
var _retry_after: Dictionary = {}
var _label: Label
var _refresh_clock := 0.0
var _last_interaction_msec := -1000

func _ready() -> void:
	show_marker = false
	interact_radius = 2.0
	super._ready()
	add_to_group("village_project_sites")
	_label = Label.new()
	_label.position = Vector2(4, 2)
	_label.custom_minimum_size = Vector2(224, 50)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 12)
	_label.add_theme_color_override("font_outline_color", Color("#172b2b"))
	_label.add_theme_constant_override("outline_size", 3)
	_label.z_index = 1
	var plaque := Panel.new()
	plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plaque.scale = Vector2.ONE * PixelArt.PX
	plaque.position = Vector2(-3.625, -5.16) - position
	plaque.custom_minimum_size = Vector2(232, 54)
	plaque.add_theme_stylebox_override("panel", GameUI.style(Color("#132a2a"), Color("#987d4e"), 1, 3))
	plaque.z_as_relative = false
	plaque.z_index = 699
	add_child(plaque)
	plaque.add_child(_label)
	GameState.village_project_changed.connect(_refresh_label)
	_refresh_label()

func lobby() -> Lobby:
	return get_parent().get_parent() as Lobby

func active_context() -> bool:
	var home := lobby()
	if not is_instance_valid(home) or home.is_queued_for_deletion() or home.journey_serial != GameState.journey_serial or GameState.game_over_active: return false
	var game := get_tree().get_first_node_in_group("game") as Game
	return is_instance_valid(game) and game.world == home and not game._transitioning and not game._sailing and not game._story_active and not game._game_over and not is_instance_valid(game.home_interior) and not home._settlement_editor.active

func workpoint() -> Vector2:
	return global_position

func ground_area() -> Rect2:
	return Rect2(get_parent().global_position + Vector2(-2.4, -1.1), Vector2(4.8, 1.1))

func reservation() -> Rect2:
	return Rect2(get_parent().global_position + Vector2(-2.8, -4.3), Vector2(5.6, 6.6))

func commission_blocker() -> String:
	var home := lobby()
	for placeable in home._placeables:
		if is_instance_valid(placeable) and home._layout.world_footprint(placeable.placeable_id).intersects(reservation()):
			return "A moved building blocks the workshop. Move it clear of the western cottage first."
	if home.resident_path(home._layout.approach("shop_house"), workpoint(), false).is_empty():
		return "The workshop approach is blocked. Clear a route for the builders first."
	return ""

func daytime_safe() -> bool:
	if not active_context() or GameState.is_night() or GameState.emergency_active(): return false
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and enemy.get_parent() == lobby() and not enemy.dead and enemy.global_position.distance_to(workpoint()) < 9.0: return false
	return true

func current_worker() -> Node2D:
	return _worker.get_ref() as Node2D if _worker != null else null

func release_worker(checkpoint: bool = true) -> void:
	if _worker == null: return
	_worker = null
	_stalled = 0
	if checkpoint and is_instance_valid(GameState) and str(GameState.project_status(project_id).state) == "working": GameState.checkpoint_village_project()

func _claim(actor: Node2D) -> bool:
	if is_instance_valid(current_worker()) and current_worker() != actor: return false
	if current_worker() != actor:
		_worker = weakref(actor)
		_worker_origin = actor.global_position
		_last_position = actor.global_position
		_worker_hp = GameState.health() if actor is Player else GameState.resident_health(actor.resident_name)
		_stalled = 0
	return true

func accepts_work(actor: Node) -> bool:
	if not is_instance_valid(actor) or actor.is_queued_for_deletion() or current_worker() != actor or not daytime_safe(): return false
	if actor.get_parent() != lobby() or actor.global_position.distance_to(workpoint()) > 0.65 and not actor is Player: return false
	if actor is Player:
		var game := get_tree().get_first_node_in_group("game") as Game
		return game.player() == actor and not game._input_locked and not actor.controls_locked and not actor.dead and not actor.sleeping and not actor.attacking and GameState.health() >= _worker_hp and actor.global_position.distance_to(_worker_origin) < 0.2 and actor.global_position.distance_to(workpoint()) <= interact_radius and Input.get_vector("move_left", "move_right", "move_up", "move_down").length() < 0.1 and not Input.is_action_pressed("attack")
	return actor is Resident and actor.worker_role == "builder" and not actor.dead and not actor.sheltered and GameState.resident_health(actor.resident_name) >= _worker_hp

func work_builder(actor: Resident, delta: float) -> bool:
	if str(GameState.project_status(project_id).state) != "working" or not daytime_safe() or actor.dead or actor.sheltered: return false
	if is_instance_valid(actor._build_target) and current_worker() != actor: return false
	if int(_retry_after.get(actor.get_instance_id(), 0)) > Time.get_ticks_msec(): return false
	if not is_instance_valid(current_worker()):
		if lobby().resident_path(actor.global_position, workpoint(), false).is_empty():
			_retry_after[actor.get_instance_id()] = Time.get_ticks_msec() + 3000
			return false
	if not _claim(actor): return false
	actor._release_build_task()
	if actor.global_position.distance_to(workpoint()) > 0.4:
		actor._walk_to(workpoint(), 2.8, delta)
		_stalled = _stalled + delta if actor.global_position.distance_to(_last_position) < 0.002 else 0.0
		_last_position = actor.global_position
		if actor._path.is_empty() or _stalled > 2.0:
			_retry_after[actor.get_instance_id()] = Time.get_ticks_msec() + 3000
			release_worker()
			return false
	else:
		actor.velocity = Vector2.ZERO
		actor.expression.request("work")
		GameState.work_village_project(project_id, delta, actor)
	return true

func activation_clear() -> bool:
	if not daytime_safe() or not commission_blocker().is_empty(): return false
	# An old, already intact cottage is a fit-out: no collision is being enabled.
	if int(GameState.structure_state(VillageProjectDB.WORKSHOP_STRUCTURE).get("health", 0)) > 0 and GameState.village_legacy_access(): return true
	var area := ground_area().grow(0.42)
	for actor in lobby().get_children():
		if actor is CharacterBody2D and not actor.is_queued_for_deletion() and area.has_point(actor.global_position): return false
	return true

func begin_player_work(actor: Player) -> bool:
	if not is_instance_valid(actor) or not daytime_safe() or str(GameState.project_status(project_id).state) != "working" or actor.global_position.distance_to(workpoint()) > interact_radius: return false
	release_worker()
	actor.velocity = Vector2.ZERO
	return _claim(actor)

func get_prompt() -> String:
	var state := str(GameState.project_status(project_id).state)
	if state == "complete": return "West Workshop"
	if current_worker() is Player: return "Stop working"
	return "Help build the workshop" if state == "working" else "West Workshop project"

func interact(actor: Node) -> void:
	if not active_context() or not actor is Player: return
	if actor.global_position.distance_to(workpoint()) > interact_radius: return
	# A touch can also emit an emulated mouse press. It must not instantly toggle
	# off the labor that the same physical gesture just started.
	var now := Time.get_ticks_msec()
	if now - _last_interaction_msec < 300: return
	_last_interaction_msec = now
	var game := get_tree().get_first_node_in_group("game") as Game
	var status := GameState.project_status(project_id)
	if current_worker() == actor:
		release_worker()
		return
	if str(status.state) == "not_started" and bool(status.ok):
		var result := GameState.start_village_project(project_id)
		if not bool(result.ok): game.open_dialogue("West Workshop", [result.message]); return
		status = GameState.project_status(project_id)
	if str(status.state) == "working" and begin_player_work(actor): return
	game.open_dialogue("West Workshop", [status.message, status.benefit, status.work])

func _physics_process(delta: float) -> void:
	var worker := current_worker()
	if _worker != null and (not is_instance_valid(worker) or not daytime_safe()): release_worker()
	elif worker is Player:
		if accepts_work(worker): GameState.work_village_project(project_id, delta, worker)
		else: release_worker()
	elif worker is Resident and (worker.dead or worker.sheltered or worker.get_parent() != lobby() or GameState.resident_health(worker.resident_name) < _worker_hp): release_worker()
	if active_context() and str(GameState.project_status(project_id).state) == "working" and float(GameState.project_status(project_id).remaining) <= 0:
		if GameState.complete_village_project(project_id):
			release_worker()
			Vfx.ring(workpoint(), 1.5, Color("#9ee0b1"), 0.6)
	_refresh_clock -= delta
	if _refresh_clock <= 0:
		_refresh_clock = 0.2
		_refresh_label()

func _refresh_label() -> void:
	if not is_instance_valid(_label): return
	var status := GameState.project_status(project_id)
	var caption := "Clear Chaos Citadel to restore"
	if bool(status.eligible): caption = "Free restoration · tap to commission"
	if str(status.state) == "working":
		caption = "%.0f%% · %s" % [(1.0 - float(status.remaining) / VillageProjectDB.WORK_SECONDS) * 100, "resumes by day" if GameState.is_night() else ("step clear of the cottage" if float(status.remaining) <= 0 else ("working" if is_instance_valid(current_worker()) else "tap here to help"))]
	if str(status.state) == "complete": caption = "Advanced swords licensed at Garrick's"
	_label.text = "WEST WORKSHOP\n" + caption
	_label.modulate = Color("#a3ebc5") if str(status.state) == "complete" else Color("#ffe2a5")
	queue_redraw()

func _draw() -> void:
	var state := str(GameState.project_status(project_id).state)
	# A timber workbench and hammer remain readable at every quality setting.
	draw_rect(Rect2(-0.95, -0.6, 1.9, 0.34), Color("#77513a"))
	draw_rect(Rect2(-0.9, -0.67, 1.8, 0.1), Color("#dab47b"))
	for x in [-0.72, 0.62]: draw_rect(Rect2(x, -0.3, 0.13, 0.5), Color("#5b4034"))
	draw_line(Vector2(-0.3, -0.67), Vector2(0, -0.95), Color("#d7ad72"), 0.08)
	draw_line(Vector2(-0.14, -1.08), Vector2(0.14, -0.82), Color("#9cacaf"), 0.12)
	if state != "complete":
		var base := -position
		for x in [-2.5, 2.5]: draw_line(base + Vector2(x, 0.2), base + Vector2(x, -4.4), Color("#ac8153"), 0.12)
		draw_line(base + Vector2(-2.5, -4.0), base + Vector2(2.5, -4.0), Color("#dab47b"), 0.13)
		if state == "working":
			var fraction := 1.0 - float(GameState.project_status(project_id).remaining) / VillageProjectDB.WORK_SECONDS
			draw_rect(Rect2(-1.5, -1.45, 3, 0.15), Color("#213c38"))
			draw_rect(Rect2(-1.5, -1.45, 3 * fraction, 0.15), Color("#9ee0b1"))

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and current_worker() is Player: release_worker()

func _exit_tree() -> void:
	release_worker()
