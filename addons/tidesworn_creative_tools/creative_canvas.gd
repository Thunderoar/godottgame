@tool
extends Control
## Shared viewport: integer tool coordinates, cursor-anchored zoom, middle pan.
signal pressed(at: Vector2i)
signal dragged(at: Vector2i)
signal released(at: Vector2i)
signal hovered(at: Vector2i)
signal key_pressed(event: InputEventKey)
signal cancelled()
var image_texture: Texture2D
var zoom := 12.0
var pan := Vector2(24, 24)
var grid := true
var grid_step := 1
var selection := Rect2i()
var spatial_overlay: Array[Dictionary] = []
var edit_overlay: Array[Dictionary] = []
var _drawing := false
var _space_pan := false
var _left_panning := false
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
	return Vector2i(((at - pan) / zoom + Vector2.ONE * 0.00001).floor())

func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_SPACE: _space_pan = event.pressed
		if event.pressed and event.keycode == KEY_ESCAPE:
			_drawing = false
			_panning = false
			_left_panning = false
			cancelled.emit()
		if event.pressed: key_pressed.emit(event)
		accept_event()
	elif event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and event.pressed:
			var anchor: Vector2 = (event.position - pan) / zoom
			zoom = clampf(zoom * (1.25 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 0.8), 0.25, 48.0)
			pan = event.position - anchor * zoom
			queue_redraw()
		if event.button_index == MOUSE_BUTTON_MIDDLE: _panning = event.pressed
		if event.pressed: grab_focus()
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_drawing = false
			_panning = false
			_left_panning = false
			cancelled.emit()
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and _left_panning:
			_panning = false
			_left_panning = false
		elif event.button_index == MOUSE_BUTTON_LEFT and _space_pan:
			_panning = event.pressed
			_left_panning = event.pressed
		elif event.button_index == MOUSE_BUTTON_LEFT:
			_drawing = event.pressed
			if event.pressed: pressed.emit(coordinate(event.position))
			else: released.emit(coordinate(event.position))
		accept_event()
	elif event is InputEventMouseMotion:
		hovered.emit(coordinate(event.position))
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
	draw_spatial_overlay()


func draw_spatial_overlay() -> void:
	var font := ThemeDB.fallback_font
	for entry in spatial_overlay + edit_overlay:
		var color: Color = entry.get("color", Color.CORAL)
		var points: PackedVector2Array = entry.get("points", PackedVector2Array())
		var screen := PackedVector2Array()
		for point in points: screen.append(pan + point * zoom)
		if screen.size() > 2 and entry.has("fill"):
			draw_colored_polygon(screen, entry.fill)
		if screen.size() > 1:
			draw_polyline(screen, color, float(entry.get("screen_width", maxf(1.0, float(entry.get("width", 1.0)) * zoom))))
		if entry.get("handles", true):
			for point in screen:
				draw_circle(point, float(entry.get("radius", 2.5)), Color("182b35"))
				draw_arc(point, float(entry.get("radius", 2.5)), 0, TAU, 16, color.lightened(0.3), 1.5)
		if screen.size() > 0 and entry.has("label"):
			draw_string(font, screen[0] + Vector2(3, -4), str(entry.label), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, color.lightened(0.4))


func fit_image() -> void:
	if image_texture == null: return
	zoom = clampf(minf((size.x - 40) / image_texture.get_width(), (size.y - 40) / image_texture.get_height()), 0.25, 48)
	pan = (size - image_texture.get_size() * zoom) * 0.5
	queue_redraw()

func frame_area(area: Rect2) -> void:
	var extent := area.size.max(Vector2(80, 60))
	zoom = clampf(minf((size.x - 64) / extent.x, (size.y - 64) / extent.y), 0.25, 6)
	pan = size * 0.5 - area.get_center() * zoom
	queue_redraw()
