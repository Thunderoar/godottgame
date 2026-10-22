class_name HouseBed
extends Interactable
## Sleep interaction. The duration is always read from the current house level.

func _ready() -> void:
	super._ready()
	prompt = "Sleep"
	var tex := PixelArt.bed_texture()
	var sprite := Sprite2D.new()
	sprite.name = "Bed"
	sprite.texture = tex
	sprite.centered = false
	sprite.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height())
	sprite.scale = Vector2(PixelArt.PX, PixelArt.PX)
	sprite.z_index = 6
	add_child(sprite)
	var label := Label.new()
	label.text = "Sleep"
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color("#e8d8ae"))
	label.scale = Vector2(0.032, 0.032)
	label.position = Vector2(-0.45, -1.25)
	add_child(label)
	GameState.house_changed.connect(func(_level: int) -> void:
		prompt = "Sleep (%ds)" % int(round(GameState.sleep_recovery_seconds())))
	prompt = "Sleep (%ds)" % int(round(GameState.sleep_recovery_seconds()))


func interact(player: Node) -> void:
	if GameState.recovery_active():
		GameState.toast_requested.emit("The recovery ward is already mending you.", "info")
		return
	if player != null and player.has_method("start_sleep"):
		player.call("start_sleep", GameState.sleep_recovery_seconds())
