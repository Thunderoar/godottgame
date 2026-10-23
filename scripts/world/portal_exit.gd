class_name PortalExit
extends Interactable
## The way home. Leaving through this gate banks unbanked expedition loot.

var _time := 0.0


func _ready() -> void:
	super._ready()
	prompt = "Return to shore (bank loot)"
	interact_radius = 2.0
	# Themed shore gate: pale aqua frame with a slow swirl, mirroring the entry
	# portal composite so leaving feels like the same magic.
	var palette := PixelArt.portal_theme_palette("pet")
	var frame := Sprite2D.new()
	frame.texture = PixelArt.portal_frame_texture("pet", false)
	frame.centered = false
	frame.offset = Vector2(-40, -112)
	frame.scale = Vector2(PixelArt.PX, PixelArt.PX)
	frame.modulate = Color(0.85, 1.0, 0.98, 0.95)
	frame.z_index = 7
	add_child(frame)
	var swirl := Sprite2D.new()
	swirl.texture = PixelArt.portal_swirl_texture("pet", 0)
	swirl.centered = false
	swirl.offset = Vector2(-24, -92)
	swirl.scale = Vector2(PixelArt.PX, PixelArt.PX)
	swirl.position = Vector2(0, 0.02)
	swirl.z_index = 6
	swirl.modulate = Color(0.8, 1.0, 0.98, 0.9)
	add_child(swirl)
	set_meta("swirl", swirl)
	var label := Label.new()
	label.text = "Shore Gate"
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color("#bfeee7"))
	label.scale = Vector2(0.032, 0.032)
	label.position = Vector2(-0.9, -3.65)
	add_child(label)


var _swirl_frame := 0
var _swirl_timer := 0.0


func _process(delta: float) -> void:
	super._process(delta)
	_time += delta
	_swirl_timer += delta
	if _swirl_timer >= 0.13 and not GameSettings.reduce_motion():
		_swirl_timer = 0.0
		_swirl_frame = (_swirl_frame + 1) % 8
		var swirl: Sprite2D = get_meta("swirl") if has_meta("swirl") else null
		if swirl != null:
			swirl.texture = PixelArt.portal_swirl_texture("pet", _swirl_frame)


func interact(_player: Node) -> void:
	var dungeon := get_tree().get_first_node_in_group("dungeon")
	if dungeon != null and dungeon.has_method("exit_to_lobby"):
		dungeon.call("exit_to_lobby", true)
