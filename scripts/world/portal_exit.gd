class_name PortalExit
extends Interactable
## The way home. Leaving through this gate banks unbanked expedition loot.

var _time := 0.0


func _ready() -> void:
	super._ready()
	prompt = "Return to shore (bank loot)"
	interact_radius = 2.0
	var tex := PixelArt.portal_texture("tidebound_grotto")
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.centered = false
	sprite.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height())
	sprite.scale = Vector2(PixelArt.PX, PixelArt.PX)
	sprite.modulate = Color(0.8, 0.95, 0.95, 0.95)
	sprite.z_index = 7
	add_child(sprite)
	var label := Label.new()
	label.text = "Shore Gate"
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color("#bfeee7"))
	label.scale = Vector2(0.032, 0.032)
	label.position = Vector2(-0.9, -3.65)
	add_child(label)


func _process(delta: float) -> void:
	super._process(delta)
	_time += delta


func interact(_player: Node) -> void:
	var dungeon := get_tree().get_first_node_in_group("dungeon")
	if dungeon != null and dungeon.has_method("exit_to_lobby"):
		dungeon.call("exit_to_lobby", true)
