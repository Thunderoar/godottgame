class_name CoastalGuard
extends Interactable
## Watches the beach and catches drifting rubbish before it reaches the sand.
## Also serves as the in-world source of settlement emergency warnings.

var catch_radius := 2.4


func _ready() -> void:
	super._ready()
	z_index = 6
	prompt = "Talk to the Coastal Guard"
	interact_radius = 2.2
	var tex := PixelArt.npc_texture("guard")
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = tex
	sprite.centered = false
	sprite.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height())
	sprite.scale = Vector2(PixelArt.PX, PixelArt.PX)
	sprite.z_index = 0
	add_child(sprite)
	# A net marker so the catch mechanic is readable. No floating name label.
	var net := Sprite2D.new()
	net.texture = PixelArt.net_texture()
	net.modulate = Color("#8fe8f7")
	net.scale = Vector2(0.04, 0.04)
	net.position = Vector2(0.45, -0.95)
	net.z_index = 0
	add_child(net)


func interact(_player: Node) -> void:
	var game := get_tree().get_first_node_in_group("game")
	if game != null and game.has_method("open_sea_cleaning"):
		game.call("open_sea_cleaning")
