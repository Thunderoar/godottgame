extends Area2D
## Port of Unisza's ChestInteract.cs
##
## Sits on the chest's interaction trigger. Swaps the closed artwork for the
## opened one (and likewise for the drop shadow) and pops the welcome message.

@export var closed_sprite: Texture2D
@export var open_sprite: Texture2D
@export var closed_shadow_sprite: Texture2D
@export var open_shadow_sprite: Texture2D

@export var sprite_path: NodePath
@export var shadow_path: NodePath
@export var popup_path: NodePath

## Godot's Key enum, stored as an int so it round-trips through the scene file.
## Key.E == 69, which is also Unity's KeyCode.E == 101's ASCII counterpart.
@export var interact_key: int = KEY_E
@export var require_key_press := true
@export var only_once := true

var _sprite: Sprite2D
var _shadow: Sprite2D
# Typed as Node, not WelcomePopup: the popup script has no class_name, so the
# two scripts stay independent of each other's import order.
var _popup: Node
var _player_in_range := false
var _is_open := false


func _ready() -> void:
	_sprite = get_node_or_null(sprite_path) as Sprite2D
	_shadow = get_node_or_null(shadow_path) as Sprite2D
	_popup = get_node_or_null(popup_path)
	body_entered.connect(func(b: Node2D) -> void: if _is_player(b): _player_in_range = true)
	body_exited.connect(func(b: Node2D) -> void: if _is_player(b): _player_in_range = false)
	_apply_state(false)


func _is_player(other: Node) -> bool:
	return other.is_in_group("player")


## Unity used Input.GetKeyDown, i.e. the press edge, not "is held".
func _unhandled_input(event: InputEvent) -> void:
	if not require_key_press:
		return
	if not _player_in_range or (only_once and _is_open):
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == interact_key:
		open()
		get_viewport().set_input_as_handled()


func open() -> void:
	if _is_open:
		return
	_is_open = true
	_apply_state(true)
	if _popup:
		_popup.show_popup()


func _apply_state(open_state: bool) -> void:
	if _sprite:
		var s := open_sprite if open_state else closed_sprite
		if s:
			_sprite.texture = s
	if _shadow:
		var s := open_shadow_sprite if open_state else closed_shadow_sprite
		if s:
			_shadow.texture = s