class_name DockHost
extends Interactable
## An original small pixel character; never samples the illustrated NPC atlas.
func _ready() -> void:
	prompt = "Talk to Pak Rahim"
	interact_radius = 2.4
	show_marker = false
	super._ready()
	var sprite := Sprite2D.new()
	sprite.texture = texture()
	sprite.scale = Vector2.ONE * PixelArt.PX
	sprite.position = Vector2(0, -0.65)
	add_child(sprite)
	z_index = 6

func interact(_player: Node) -> void:
	var game := get_tree().get_first_node_in_group("game") as Game
	if is_instance_valid(game): game.play_dock_conversation()

static func texture() -> Texture2D:
	return PixelArt.cached_texture("characters/pak_rahim/v1", func() -> Image:
		var img := PixelArt.image(32, 44)
		var ink := Color("#41616a")
		var skin := Color("#dba880")
		var hair := Color("#454751")
		PixelArt.ellipse(img, 16, 41, 11, 2, Color(0.18, 0.29, 0.30, 0.2))
		# Rounded chibi silhouette, soft mint work shirt and sky-blue headband.
		PixelArt.rect(img, 10, 33, 5, 8, ink)
		PixelArt.rect(img, 18, 33, 5, 8, ink)
		PixelArt.rect(img, 8, 40, 7, 2, Color("#816c60"))
		PixelArt.rect(img, 18, 40, 7, 2, Color("#816c60"))
		PixelArt.ellipse(img, 16, 28, 11, 11, ink)
		PixelArt.ellipse(img, 16, 27, 10, 10, Color("#8dc5b6"))
		PixelArt.rect(img, 7, 23, 18, 9, Color("#a8dacc"))
		PixelArt.rect(img, 10, 32, 13, 3, Color("#f1e9cf"))
		PixelArt.rect(img, 19, 24, 4, 12, Color("#fff0d7"))
		PixelArt.ellipse(img, 16, 13, 11, 12, hair)
		PixelArt.ellipse(img, 16, 15, 9, 9, skin)
		PixelArt.ellipse(img, 16, 7, 10, 6, hair)
		PixelArt.rect(img, 6, 9, 20, 4, Color("#98d1e1"))
		PixelArt.rect(img, 5, 11, 4, 7, Color("#b4e2e9"))
		PixelArt.rect(img, 9, 5, 3, 2, Color("#afbfbd"))
		PixelArt.rect(img, 11, 14, 2, 3, ink)
		PixelArt.rect(img, 20, 14, 2, 3, ink)
		PixelArt.px(img, 11, 14, Color("#fff8e9"))
		PixelArt.px(img, 20, 14, Color("#fff8e9"))
		PixelArt.hline(img, 14, 20, 4, hair)
		PixelArt.hline(img, 15, 22, 3, hair)
		PixelArt.rect(img, 9, 18, 3, 1, Color("#e6b1a0"))
		PixelArt.rect(img, 22, 18, 2, 1, Color("#e6b1a0"))
		PixelArt.ellipse(img, 6, 30, 3, 4, skin)
		PixelArt.ellipse(img, 26, 29, 3, 3, skin)
		PixelArt.rect(img, 23, 26, 7, 5, Color("#b8966e"))
		PixelArt.hline(img, 23, 26, 7, Color("#f2dbb0"))
		return img)
