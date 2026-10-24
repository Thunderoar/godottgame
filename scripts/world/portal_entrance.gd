class_name PortalEntrance
extends Interactable
## Lobby portal gate, rebuilt as an animated composite: a theme-tinted stone
## frame (PortalDB theme, never a portal-id special case), an 8-frame swirling
## interior, orbiting motes, a pulsing rune glow, a ground light pool and a
## wake-up burst when the player approaches. Locked gates are sealed with a
## slab and chains; cleared gates wear a golden aura and banner.
##
## Kept contracts: Interactable with portal_id / gate_kind / gate_title, group
## battle_portal, interact() routing to Game.open_portals / open_pet_battles.

@export var portal_id := "tidebound_grotto"
@export var gate_kind := "monster"  # monster / pet
@export var gate_title := ""

const SWIRL_FPS := 9.0

var _glow: PointLight2D
var _frame: Sprite2D
var _swirl: Sprite2D
var _pool: Sprite2D
var _motes: CPUParticles2D
var _aura: Sprite2D
var _banner: Label
var _time := 0.0
var _swirl_timer := 0.0
var _swirl_frame := 0
var _awake := false
var _theme := "grotto"
var _cleared := false


func _ready() -> void:
	super._ready()
	add_to_group("battle_portal")
	var is_pet := gate_kind == "pet"
	var shown_title := gate_title
	if shown_title == "":
		shown_title = "Pet Battle Portal" if is_pet else "Monster Battle Portal"
	prompt = "Enter the %s" % shown_title
	interact_radius = 2.1
	# Theme comes from PortalDB (pet gates get their own aqua arena look).
	if is_pet:
		_theme = "pet"
	else:
		_theme = str(PortalDB.get_portal(portal_id).get("theme", "grotto"))
	var palette := PixelArt.portal_theme_palette(_theme)
	_build_visuals(palette, shown_title, is_pet)
	if not is_pet:
		GameState.data_changed.connect(_refresh)
	_refresh()


func _build_visuals(palette: Dictionary, shown_title: String, is_pet: bool) -> void:
	# Ground light pool.
	_pool = Sprite2D.new()
	_pool.texture = PixelArt.light_texture()
	_pool.modulate = Color((palette["glow"] as Color).r, (palette["glow"] as Color).g, (palette["glow"] as Color).b, 0.16)
	_pool.scale = Vector2(0.025, 0.013)
	_pool.position = Vector2(0, -0.1)
	_pool.z_index = 1
	add_child(_pool)

	# Swirl interior (animated in _process).
	_swirl = Sprite2D.new()
	_swirl.name = "Swirl"
	_swirl.texture = PixelArt.portal_swirl_texture(_theme, 0)
	_swirl.centered = false
	_swirl.offset = Vector2(-24, -92)
	_swirl.scale = Vector2(PixelArt.PX, PixelArt.PX)
	_swirl.position = Vector2(0, 0.02)
	_swirl.z_index = 6
	add_child(_swirl)

	# Stone frame on top.
	_frame = Sprite2D.new()
	_frame.name = "Portal"
	_frame.texture = PixelArt.portal_frame_texture(_theme, false)
	_frame.centered = false
	_frame.offset = Vector2(-40, -112)
	_frame.scale = Vector2(PixelArt.PX, PixelArt.PX)
	_frame.z_index = 7
	add_child(_frame)

	_glow = PointLight2D.new()
	_glow.texture = PixelArt.light_texture()
	_glow.texture_scale = 0.032
	_glow.energy = 0.22
	_glow.color = palette["glow"] if gate_kind == "pet" else (palette["glow_light"] as Color).lerp(Color.WHITE, 0.25)
	_glow.position = Vector2(0, -1.45)
	add_child(_glow)

	# Orbiting motes (CPUParticles2D, Compatibility-safe, capped).
	_motes = CPUParticles2D.new()
	_motes.amount = 4
	_motes.lifetime = 1.6
	_motes.preprocess = 1.2
	_motes.texture = PixelArt.mote_texture()
	_motes.scale_amount_min = 0.03
	_motes.scale_amount_max = 0.05
	_motes.color = palette["mote"]
	_motes.direction = Vector2(0, -1)
	_motes.spread = 30.0
	_motes.gravity = Vector2(0, -0.05)
	_motes.initial_velocity_min = 0.12
	_motes.initial_velocity_max = 0.3
	_motes.position = Vector2(0, -2.2)
	_motes.z_as_relative = false
	_motes.z_index = 660
	add_child(_motes)

	# Cleared aura ring (hidden until the portal is cleared).
	_aura = Sprite2D.new()
	_aura.texture = PixelArt.light_texture()
	_aura.modulate = Color(1.0, 0.85, 0.45, 0.0)
	_aura.scale = Vector2(0.035, 0.028)
	_aura.position = Vector2(0, -1.6)
	_aura.z_as_relative = false
	_aura.z_index = 665
	add_child(_aura)

	var label := Label.new()
	label.z_as_relative = false
	label.z_index = 710
	label.text = shown_title
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color("#a8f5ea") if gate_kind == "pet" else (PixelArt.portal_theme_palette(_theme)["glow_light"] as Color))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label.scale = Vector2(0.031, 0.031)
	label.position = Vector2(-1.55, -3.85)
	add_child(label)

	_banner = Label.new()
	_banner.z_as_relative = false
	_banner.z_index = 711
	_banner.text = "CLEARED"
	_banner.add_theme_font_size_override("font_size", 11)
	_banner.add_theme_color_override("font_color", Color("#ffd88a"))
	_banner.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_banner.scale = Vector2(0.030, 0.030)
	_banner.position = Vector2(-0.75, -4.35)
	_banner.visible = false
	add_child(_banner)


func _process(delta: float) -> void:
	super._process(delta)
	_time += delta
	var unlocked := available or gate_kind == "pet"
	# Swirl animation only when the gate is live.
	if unlocked and not GameSettings.reduce_motion():
		_swirl_timer += delta
		if _swirl_timer >= 1.0 / SWIRL_FPS:
			_swirl_timer = 0.0
			_swirl_frame = (_swirl_frame + 1) % 8
			_swirl.texture = PixelArt.portal_swirl_texture(_theme, _swirl_frame)
	if _glow:
		_glow.energy = (0.18 + (sin(_time * 1.7) * 0.025 if not GameSettings.reduce_motion() else 0.0)) * (1.0 if unlocked and GameSettings.effects_at_least("med") else 0.0)
	if _frame:
		_frame.modulate = Color(1, 1, 1, 1) if unlocked else Color(0.55, 0.58, 0.62, 0.9)
	if _motes:
		_motes.emitting = unlocked and GameSettings.effects_at_least("high") and not GameSettings.reduce_motion()
	if _pool:
		_pool.modulate.a = (0.06) if unlocked else 0.04
	if _aura:
		_aura.modulate.a = 0.07 if _cleared else 0.0
	# Approach wake: the portal ignites once as the player comes near.
	if not _awake and unlocked:
		var p := get_tree().get_first_node_in_group("player")
		if p != null and is_instance_valid(p) and global_position.distance_to((p as Node2D).global_position) < 3.6:
			_awake = true
			Vfx.ring(global_position + Vector2(0, -1.6), 1.4, PixelArt.portal_theme_palette(_theme)["glow_light"], 0.5)
			Sfx.play("portal_in", -16.0)


func _refresh() -> void:
	if gate_kind == "pet":
		available = true
		prompt = "Enter the Pet Battle Portal"
		return
	var state := GameState.portal_state(portal_id)
	var unlocked := bool(state.get("unlocked", false))
	_cleared = bool(state.get("cleared", false))
	available = unlocked
	prompt = "Enter the Monster Battle Portal" if unlocked else "Open the Monster Battle Portal"
	# Locked gates show the sealed frame; cleared gates gain the aura + banner.
	if _frame:
		_frame.texture = PixelArt.portal_frame_texture(_theme, not unlocked and not _cleared)
	if _swirl:
		_swirl.visible = unlocked
	if _banner:
		_banner.visible = _cleared
	queue_redraw()


func is_interactable_available() -> bool:
	return true


func interact(_player: Node) -> void:
	var game := get_tree().get_first_node_in_group("game")
	if game == null:
		return
	if gate_kind == "pet":
		if game.has_method("open_pet_battles"):
			game.call("open_pet_battles")
		return
	if game.has_method("open_portals"):
		game.call("open_portals", portal_id)


func _unhandled_input(event: InputEvent) -> void:
	var point := Vector2.ZERO
	var pressed := false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		point = event.position
		pressed = true
	elif event is InputEventScreenTouch and event.pressed:
		point = event.position
		pressed = true
	var game := get_tree().get_first_node_in_group("game") as Game
	if not pressed or not is_instance_valid(game) or game._input_locked or game.world != get_parent() or is_instance_valid(game.home_interior):
		return
	if game.world is Lobby and game.world._settlement_editor.active:
		return
	var local := to_local(get_canvas_transform().affine_inverse() * point)
	if Rect2(-1.5, -3.8, 3, 4.3).has_point(local):
		interact(game.player())
		get_viewport().set_input_as_handled()
