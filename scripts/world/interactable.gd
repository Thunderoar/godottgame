class_name Interactable
extends Area2D
## Base class for things the player can talk to, sleep in, loot or enter.
## Players find these through the "interactable" group and ask for a prompt.

@export var prompt := "Interact"
@export var interact_radius := 1.9
@export var show_marker := true

var available := true
var marker: Sprite2D
var _bob := 0.0


func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 0
	collision_mask = 0
	monitoring = false
	monitorable = false
	if show_marker:
		_make_marker()


func _process(delta: float) -> void:
	if marker == null:
		return
	_bob += delta
	marker.position.y = -1.65 + sin(_bob * 2.4) * 0.07
	marker.visible = available
	marker.modulate.a = 0.55 + sin(_bob * 2.4) * 0.14


func _make_marker() -> void:
	marker = Sprite2D.new()
	marker.name = "InteractionMarker"
	marker.texture = PixelArt.icon("spark", 16)
	marker.scale = Vector2(0.040, 0.040)
	marker.position = Vector2(0, -1.65)
	marker.z_as_relative = false
	marker.z_index = 700
	add_child(marker)


func get_prompt() -> String:
	return prompt


func is_interactable_available() -> bool:
	return available


func interact(_player: Node) -> void:
	pass
