extends Node

func _ready() -> void:
	for level in range(1, 6):
		print("building house ", level)
		var tex := PixelArt.house_texture(level)
		print("  -> ", tex.get_width(), "x", tex.get_height())
	print("done")
	get_tree().quit()
