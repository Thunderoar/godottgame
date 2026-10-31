class_name ShipDeparture
extends Interactable
const SAIL_SPEED := 3.6
const DISEMBARK_SPEED := 2.5
const PASSENGER_OFFSET := Vector2(1.05, -0.65)
const ARJUN_OFFSET := Vector2(-1.55, -0.65)
const HULL_FACE := Rect2(0, 82, 208, 30)
var ship: Sprite2D
var passenger: Player
var departing := false
var arrived := false
var returning := false
var disembarking := false
var landed := false
var _moored_position := Vector2.ZERO
var _passenger_mask := 0
var _front_hull: Sprite2D

func _ready() -> void:
	prompt = ""
	touch_verb = "Enter"
	show_marker = false
	interact_radius = 2.2
	_moored_position = ship.position
	_build_front_hull()
	super._ready()
	add_to_group("ship_boarding")
	GameState.data_changed.connect(_refresh_availability)
	_refresh_availability()

func _refresh_availability() -> void:
	available = GameState.sea_journey_available() and not (departing or returning or disembarking)

func _build_front_hull() -> void:
	# Redraw only the near hull in front of the rider, keeping the mast behind.
	_front_hull = Sprite2D.new()
	_front_hull.name = "PassengerHull"
	_front_hull.texture = ship.texture
	_front_hull.region_enabled = true
	_front_hull.region_rect = HULL_FACE
	_front_hull.centered = false
	_front_hull.offset = ship.offset + HULL_FACE.position
	_front_hull.z_as_relative = false
	_front_hull.visible = false
	# This layer is visible only while occupied and must not fade over its rider.
	_front_hull.set_meta("passenger_onboard", true)
	ship.add_child(_front_hull)

func interact(player: Node) -> void:
	if not available or not is_instance_valid(player) or player.global_position.distance_to(global_position) > interact_radius:
		return
	var game := get_tree().get_first_node_in_group("game") as Game
	if is_instance_valid(game):
		game.board_ship(self)

func _take_passenger(player: Player) -> void:
	available = false
	passenger = player
	ship.set_meta("passenger_onboard", true)
	_front_hull.z_index = passenger.z_index + 1
	_front_hull.visible = true
	_passenger_mask = passenger.collision_mask
	var bob: Tween = ship.get_meta("ambient_tween", null)
	if bob:
		bob.pause()
	ship.remove_from_group("ambient_boat")
	ship.rotation = 0
	ship.position = _moored_position
	passenger.collision_mask = 0
	passenger.velocity = Vector2.ZERO
	passenger.controls_locked = true

func _carry_passenger() -> void:
	passenger.global_position = ship.global_position + PASSENGER_OFFSET

func begin(player: Player) -> bool:
	if not GameState.sea_journey_available() or departing or returning or disembarking or not is_instance_valid(ship) or not is_instance_valid(player):
		return false
	departing = true
	landed = false
	_take_passenger(player)
	_carry_passenger()
	passenger.reset_physics_interpolation()
	return true

func begin_return(player: Player) -> void:
	returning = true
	landed = false
	_take_passenger(player)
	# Start with the complete hull beyond the same boundary used for departure.
	ship.position.x = Lobby.MAP_RECT.position.x - ship.get_rect().end.x * ship.scale.x - 0.25
	_carry_passenger()
	var game := get_tree().get_first_node_in_group("game") as Game
	if is_instance_valid(game) and game._arjun_returning:
		var friend := PlayerSprite.new()
		friend.name = "ArjunPassenger"
		friend.character_id = "arjun"
		friend.base_scale = Vector2.ONE
		friend.scale = Vector2.ONE
		friend.offset = Vector2(0, -24)
		friend.position = ARJUN_OFFSET / ship.scale
		friend.z_as_relative = false
		friend.z_index = player.z_index
		friend.set_meta("passenger_onboard", true)
		ship.add_child(friend)
		friend.set_facing(2, false)
	ship.reset_physics_interpolation()
	passenger.reset_physics_interpolation()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(passenger):
		return
	if returning:
		ship.position = ship.position.move_toward(_moored_position, SAIL_SPEED * delta)
		_carry_passenger()
		if ship.position.is_equal_approx(_moored_position):
			returning = false
			disembarking = true
		return
	if disembarking:
		passenger.global_position = passenger.global_position.move_toward(global_position, DISEMBARK_SPEED * delta)
		if passenger.global_position.is_equal_approx(global_position):
			disembarking = false
			landed = true
			ship.set_meta("passenger_onboard", false)
			_front_hull.visible = false
			_refresh_availability()
			passenger.collision_mask = _passenger_mask
			passenger.velocity = Vector2.ZERO
			passenger.reset_physics_interpolation()
			ship.add_to_group("ambient_boat")
			var game := get_tree().get_first_node_in_group("game") as Game
			if is_instance_valid(game) and game.world == get_parent():
				game.finish_ship_return(self)
		return
	if not departing or arrived:
		return
	ship.position.x -= SAIL_SPEED * delta
	_carry_passenger()
	var bounds: Rect2 = ship.global_transform * ship.get_rect()
	if bounds.position.x <= Lobby.MAP_RECT.position.x:
		arrived = true
		var game := get_tree().get_first_node_in_group("game") as Game
		if is_instance_valid(game) and game.world == get_parent():
			game.enter_ocean(self)

func _unhandled_input(event: InputEvent) -> void:
	var point := Vector2.ZERO
	if event is InputEventScreenTouch and event.pressed: point = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed: point = event.position
	else: return
	var game := get_tree().get_first_node_in_group("game") as Game
	if not is_instance_valid(game) or game.world != get_parent() or game._input_locked or not available: return
	if game.world._settlement_editor.active: return
	var world_point := get_canvas_transform().affine_inverse() * point
	if is_instance_valid(ship) and ship.get_rect().has_point(ship.to_local(world_point)):
		game.board_ship(self, true)
		get_viewport().set_input_as_handled()
