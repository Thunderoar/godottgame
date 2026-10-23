class_name ResourcePile
extends Interactable
## A replenishing pile of driftwood on the beach. Gives the player a safe,
## repeatable gold source outside portals (sell the wood at Garrick's).

@export var item_id := "wood"
@export var amount := 2
@export var cooldown := 14.0

var _cooldown_left := 0.0
var _label: Label


func _ready() -> void:
	super._ready()
	prompt = "Gather driftwood"
	interact_radius = 1.7
	var icon := Sprite2D.new()
	icon.texture = PixelArt.icon("wood", 16)
	icon.scale = Vector2(0.08, 0.08)
	icon.position = Vector2(0, -0.32)
	icon.z_index = 5
	add_child(icon)
	_label = Label.new()
	_label.text = "Driftwood"
	_label.add_theme_font_size_override("font_size", 11)
	_label.add_theme_color_override("font_color", Color("#e1c48a"))
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_label.scale = Vector2(0.026, 0.026)
	_label.position = Vector2(-0.52, -0.82)
	add_child(_label)


func _process(delta: float) -> void:
	super._process(delta)
	if _cooldown_left > 0.0:
		_cooldown_left = maxf(0.0, _cooldown_left - delta)
		if _cooldown_left <= 0.0:
			prompt = "Gather driftwood"
			if _label:
				_label.modulate = Color.WHITE


func get_prompt() -> String:
	if _cooldown_left > 0.0:
		return "Driftwood washes ashore in %ds" % int(ceil(_cooldown_left))
	return prompt


func interact(_player: Node) -> void:
	if _cooldown_left > 0.0:
		GameState.toast_requested.emit("The tide has not brought more yet.", "info")
		return
	if not GameState.add_item(item_id, amount):
		GameState.toast_requested.emit("Your pack is too full for driftwood.", "bad")
		return
	_cooldown_left = cooldown
	GameState.record_mission_event("gather")
	prompt = "Gather driftwood"
	if _label:
		_label.modulate = Color(0.55, 0.6, 0.58, 0.7)
	GameState.toast_requested.emit("Gathered %d driftwood. Garrick buys it for 4 gold each." % amount, "good")
