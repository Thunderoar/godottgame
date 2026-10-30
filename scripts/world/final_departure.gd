class_name FinalDeparture
extends Interactable
## The ending invitation has its own nearby-only route, independent of sea travel.
var _hint: Button
var _reason := ""
var _time := 0.0

func _ready() -> void:
	show_marker = false
	interact_radius = 2.2
	super._ready()
	z_index = 700
	_hint = Button.new()
	_hint.position = Vector2(-2.6,-3.8)
	_hint.size = Vector2(260,36)
	_hint.scale = Vector2.ONE * 0.02
	_hint.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.focus_mode = Control.FOCUS_NONE
	_hint.flat = true
	_hint.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal","hover","pressed","disabled","focus"]:
		_hint.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	_hint.pressed.connect(func() -> void: interact(null))
	_hint.add_theme_font_size_override("font_size",19)
	_hint.add_theme_color_override("font_color",GameUI.GOLD)
	_hint.add_theme_color_override("font_shadow_color",Color("#102733"))
	_hint.add_theme_constant_override("shadow_offset_x",2)
	_hint.add_theme_constant_override("shadow_offset_y",2)
	add_child(_hint)

func _process(delta: float) -> void:
	_time += delta
	var game := get_tree().get_first_node_in_group("game") as Game
	_reason = game.final_departure_reason(self) if is_instance_valid(game) else ""
	available = _reason == "Embark together"
	_hint.visible = not _reason.is_empty()
	_hint.disabled = not available
	_hint.text = "EMBARK TOGETHER" if available else _reason
	queue_redraw()

func get_prompt() -> String:
	return "Tap to embark together" if GameSettings.touch_controls() == "always" or (GameSettings.touch_controls() == "auto" and DisplayServer.is_touchscreen_available()) else "E · Embark together"

func is_interactable_available() -> bool:
	var game := get_tree().get_first_node_in_group("game") as Game
	return is_instance_valid(game) and game.final_departure_reason(self) == "Embark together"

func interact(_player: Node) -> void:
	var game := get_tree().get_first_node_in_group("game") as Game
	if is_instance_valid(game): game.begin_final_departure(self)

func _draw() -> void:
	if GameState.final_departure_available():
		var home := get_parent() as Lobby
		if home._departure_posts.has("mei_ling"):
			var bag: Vector2 = home._departure_posts.mei_ling-position+Vector2(0.45,0.12)
			draw_rect(Rect2(bag-Vector2(0.17,0.29),Vector2(0.34,0.28)),Color("#bfa372"))
			draw_line(bag+Vector2(-0.1,-0.31),bag+Vector2(0.1,-0.31),Color("#ead7a7"),0.04)
			draw_line(bag+Vector2(0,-0.27),bag,Color("#755b40"),0.04)
	if not available: return
	draw_rect(Rect2(-2.7,-3.86,5.4,0.62),Color(0.035,0.10,0.13,0.94))
	draw_line(Vector2(-2.7,-3.86),Vector2(2.7,-3.86),GameUI.GOLD,0.025)
	var glow := 0.22 if GameSettings.reduce_motion() else 0.17+sin(_time*2)*0.05
	draw_arc(Vector2.ZERO,0.55,0,TAU,32,Color(0.95,0.79,0.43,glow),0.06)
	draw_line(Vector2(-0.15,-0.03),Vector2.ZERO,GameUI.GOLD,0.04)
	draw_line(Vector2.ZERO,Vector2(-0.15,0.12),GameUI.GOLD,0.04)

func _unhandled_input(event: InputEvent) -> void:
	var screen := Vector2.ZERO
	if event is InputEventScreenTouch and event.pressed: screen = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed: screen = event.position
	else: return
	if not is_interactable_available(): return
	var world_point := get_canvas_transform().affine_inverse()*screen
	var home := get_parent() as Lobby
	var on_ship := is_instance_valid(home.ship_boarding.ship) and home.ship_boarding.ship.get_rect().has_point(home.ship_boarding.ship.to_local(world_point))
	if on_ship or world_point.distance_to(global_position+Vector2(0,-0.65)) < 1.2:
		interact(null)
		get_viewport().set_input_as_handled()
