class_name UniszaStudent
extends Interactable
## Yellow-clad student NPC near the cottage. Interaction opens a persistent
## dialogue panel with the Unisza welcome message.

func _ready() -> void:
	super._ready()
	prompt = "Talk to the yellow student"
	interact_radius = 2.1
	add_to_group("special_npc")
	var tex := PixelArt.npc_texture("student")
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = tex
	sprite.centered = false
	sprite.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height())
	sprite.scale = Vector2(PixelArt.PX, PixelArt.PX)
	sprite.modulate = Color("#f2cf4d")
	sprite.z_index = 8
	add_child(sprite)
	var glow := PointLight2D.new()
	glow.texture = PixelArt.light_texture()
	glow.texture_scale = 0.35
	glow.energy = 0.32
	glow.color = Color("#ffe36e")
	glow.position = Vector2(0, -0.9)
	add_child(glow)


func interact(_player: Node) -> void:
	var game := get_tree().get_first_node_in_group("game")
	if game != null and game.has_method("open_dialogue"):
		game.call("open_dialogue", "Unisza Student", [
			"“Welcome to Unisza”",
			"“We are students from Unisza.”",
		])
