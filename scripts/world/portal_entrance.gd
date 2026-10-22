class_name PortalEntrance
extends Interactable
## Lobby portal gate. Opens the requirements panel; entry itself is always
## validated again by GameState.

@export var portal_id := "tidebound_grotto"
@export var gate_kind := "monster"  # monster / pet
@export var gate_title := ""

var _glow: PointLight2D
var _sprite: Sprite2D
var _time := 0.0


func _ready() -> void:
	super._ready()
	add_to_group("battle_portal")
	var is_pet := gate_kind == "pet"
	var shown_title := gate_title
	if shown_title == "":
		shown_title = "Pet Battle Portal" if is_pet else "Monster Battle Portal"
	prompt = "Enter the %s" % shown_title
	interact_radius = 2.1
	var visual_id := "sunken_crypt" if is_pet else portal_id
	var tex := PixelArt.portal_texture(visual_id)
	_sprite = Sprite2D.new()
	_sprite.name = "Portal"
	_sprite.texture = tex
	_sprite.centered = false
	_sprite.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height())
	_sprite.scale = Vector2(PixelArt.PX, PixelArt.PX)
	_sprite.z_index = 7
	add_child(_sprite)
	_glow = PointLight2D.new()
	_glow.texture = PixelArt.light_texture()
	_glow.texture_scale = 0.75
	_glow.energy = 0.8
	_glow.color = Color("#56d5d0") if is_pet else Color("#a57ce8")
	_glow.position = Vector2(0, -1.45)
	add_child(_glow)
	var label := Label.new()
	label.text = shown_title
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color("#a8f5ea") if is_pet else Color("#d9c6ff"))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	label.scale = Vector2(0.031, 0.031)
	label.position = Vector2(-1.55, -3.85)
	add_child(label)
	if not is_pet:
		GameState.data_changed.connect(_refresh)
	_refresh()


func _process(delta: float) -> void:
	super._process(delta)
	_time += delta
	if _glow:
		_glow.energy = (0.72 + sin(_time * 1.7) * 0.12) * (1.0 if available else 0.3)
	if _sprite:
		_sprite.modulate = Color(1, 1, 1, 1) if available else Color(0.55, 0.58, 0.62, 0.9)


func _refresh() -> void:
	if gate_kind == "pet":
		available = true
		prompt = "Enter the Pet Battle Portal"
		return
	var state := GameState.portal_state(portal_id)
	var unlocked := bool(state.get("unlocked", false))
	available = unlocked
	prompt = "Enter the Monster Battle Portal" if unlocked else "Open the Monster Battle Portal"
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
