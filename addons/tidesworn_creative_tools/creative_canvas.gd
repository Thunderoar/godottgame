@tool
extends Control
## Shared viewport: integer tool coordinates, cursor-anchored zoom, middle pan.
signal pressed(at: Vector2i)
signal dragged(at: Vector2i)
signal released(at: Vector2i)
var image_texture: Texture2D
var zoom := 12.0
var pan := Vector2(24, 24)
var grid := true
var grid_step := 1
var selection := Rect2i()
var _drawing := false
var _panning := false

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	clip_contents = true
	custom_minimum_size = Vector2(400, 340)
	mouse_filter = Control.MOUSE_FILTER_STOP

func show_image(img: Image) -> void:
	if image_texture is ImageTexture and image_texture.get_size() == Vector2(img.get_size()):
		(image_texture as ImageTexture).update(img)
	else:
		image_texture = ImageTexture.create_from_image(img)
	queue_redraw()

func coordinate(at: Vector2) -> Vector2i:
	return Vector2i(((at - pan) / zoom).floor())

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and event.pressed:
			var anchor: Vector2 = (event.position - pan) / zoom
			zoom = clampf(zoom * (1.25 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 0.8), 0.25, 48.0)
			pan = event.position - anchor * zoom
			queue_redraw()
		if event.button_index == MOUSE_BUTTON_MIDDLE: _panning = event.pressed
		if event.button_index == MOUSE_BUTTON_LEFT:
			_drawing = event.pressed
			if event.pressed: pressed.emit(coordinate(event.position))
			else: released.emit(coordinate(event.position))
		accept_event()
	elif event is InputEventMouseMotion:
		if _panning:
			pan += event.relative
			queue_redraw()
		elif _drawing:
			dragged.emit(coordinate(event.position))
		accept_event()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("182b35"))
	if image_texture == null: return
	var dimensions := image_texture.get_size()
	var bounds := Rect2(pan, dimensions * zoom)
	# Checkerboard is clipped to the canvas by Control and bounded to image size.
	for y in range(0, int(dimensions.y), 8):
		for x in range(0, int(dimensions.x), 8):
			draw_rect(Rect2(pan + Vector2(x, y) * zoom, Vector2(minf(8, dimensions.x - x), minf(8, dimensions.y - y)) * zoom), Color("52606a") if (int(x / 8) + int(y / 8)) % 2 else Color("414e58"))
	draw_texture_rect(image_texture, bounds, false)
	if grid and zoom * grid_step >= 5.0:
		for x in range(0, int(dimensions.x) + 1, grid_step):
			draw_line(pan + Vector2(x * zoom, 0), pan + Vector2(x * zoom, dimensions.y * zoom), Color(0, 0, 0, 0.15))
		for y in range(0, int(dimensions.y) + 1, grid_step):
			draw_line(pan + Vector2(0, y * zoom), pan + Vector2(dimensions.x * zoom, y * zoom), Color(0, 0, 0, 0.15))
	if selection.has_area():
		draw_rect(Rect2(pan + Vector2(selection.position) * zoom, Vector2(selection.size) * zoom), Color("ffe4a4"), false, 2.0)
	draw_rect(bounds, Color("c5a66e"), false, 1.0)
