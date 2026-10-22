class_name ShopNPC
extends Interactable
## A merchant or service NPC. The world places a stall behind it; this node is
## just the person and interaction point. Names are intentionally not floating
## over NPCs; their identity appears only when the interaction panel opens.

@export var shop_type := "potion"
@export var npc_kind := "potion"
@export var npc_name := "Mara"

var sprite: Sprite2D


func _ready() -> void:
	super._ready()
	prompt = "Talk to %s" % npc_name
	_build()


func _build() -> void:
	var tex := PixelArt.npc_texture(npc_kind)
	sprite = Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = tex
	sprite.centered = false
	sprite.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height())
	sprite.scale = Vector2(PixelArt.PX, PixelArt.PX)
	sprite.z_index = 8
	add_child(sprite)


func interact(_player: Node) -> void:
	var game := get_tree().get_first_node_in_group("game")
	if game == null:
		return
	if shop_type == "house":
		if game.has_method("open_house"):
			game.call("open_house")
		return
	if game.has_method("open_shop"):
		game.call("open_shop", shop_type, npc_name)
