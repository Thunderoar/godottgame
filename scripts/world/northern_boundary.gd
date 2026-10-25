class_name NorthernBoundary
extends RefCounted
## Full-width northern stone boundary, independent of the two portals.

static func build_north_wall(world: Node2D) -> void:
	var wall := Node2D.new()
	wall.name = "NorthernStoneWall"
	wall.add_to_group("northern_boundary")
	wall.z_index = 2
	world.add_child(wall)
	var art := Sprite2D.new()
	art.texture = CoastalArt.cliff_texture()
	art.centered = false
	art.region_enabled = true
	art.region_rect = Rect2(0, 0, Lobby.MAP_RECT.size.x / PixelArt.PX, 64)
	art.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	art.scale = Vector2.ONE * PixelArt.PX
	wall.add_child(art)
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	wall.add_child(body)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(Lobby.MAP_RECT.size.x, 1.3)
	shape.shape = rectangle
	shape.position = Vector2(Lobby.MAP_RECT.size.x * 0.5, 0.65)
	body.add_child(shape)
