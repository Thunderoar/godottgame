@tool
class_name TidePixelDocument
extends RefCounted
## Image tools operate in integer pixel space. History is capped to 48 documents.
signal changed
var frames: Array[Image] = []
var durations: Array[float] = []
var index := 0
var selection := Rect2i()
var color := Color("f37b65")
var recent: Array[Color] = []
var undo_stack: Array[Dictionary] = []
var redo_stack: Array[Dictionary] = []
var dirty := false
var source_path := ""

func _init() -> void:
	new_image(Vector2i(32, 32))

func new_image(size: Vector2i) -> void:
	frames = [Image.create_empty(clampi(size.x, 1, 512), clampi(size.y, 1, 512), false, Image.FORMAT_RGBA8)]
	durations = [0.13]
	index = 0
	undo_stack.clear()
	redo_stack.clear()
	dirty = false
	source_path = ""
	changed.emit()

func image() -> Image:
	return frames[index]

func snapshot() -> Dictionary:
	var copies: Array[Image] = []
	for frame in frames:
		copies.append(frame.duplicate())
	return {"frames": copies, "durations": durations.duplicate(), "index": index}

func restore(state: Dictionary) -> void:
	frames.assign(state.frames)
	durations.assign(state.durations)
	index = state.index
	dirty = true
	changed.emit()

func checkpoint() -> void:
	undo_stack.append(snapshot())
	var state_bytes := image().get_width() * image().get_height() * 4 * frames.size()
	while undo_stack.size() > mini(48, maxi(1, int(33554432 / state_bytes))):
		undo_stack.pop_front()
	redo_stack.clear()
	dirty = true

func undo() -> void:
	if undo_stack.is_empty(): return
	redo_stack.append(snapshot())
	restore(undo_stack.pop_back())

func redo() -> void:
	if redo_stack.is_empty(): return
	undo_stack.append(snapshot())
	restore(redo_stack.pop_back())

func inside(at: Vector2i) -> bool:
	return Rect2i(Vector2i.ZERO, image().get_size()).has_point(at)

func dot(at: Vector2i, ink: Color) -> void:
	if inside(at): image().set_pixelv(at, ink)

func line(a: Vector2i, b: Vector2i, ink: Color) -> void:
	PixelArt.line(image(), a.x, a.y, b.x, b.y, ink)
	changed.emit()

func rectangle(a: Vector2i, b: Vector2i, ink: Color) -> void:
	var rect := Rect2i(a.min(b), (a - b).abs() + Vector2i.ONE)
	for x in range(rect.position.x, rect.end.x):
		dot(Vector2i(x, rect.position.y), ink)
		dot(Vector2i(x, rect.end.y - 1), ink)
	for y in range(rect.position.y, rect.end.y):
		dot(Vector2i(rect.position.x, y), ink)
		dot(Vector2i(rect.end.x - 1, y), ink)
	changed.emit()

func fill(at: Vector2i, ink: Color) -> void:
	if not inside(at): return
	var target := image().get_pixelv(at)
	if target.is_equal_approx(ink): return
	var todo: Array[Vector2i] = [at]
	dot(at, ink)
	while not todo.is_empty():
		var p: Vector2i = todo.pop_back()
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = p + d
			if inside(next) and image().get_pixelv(next).is_equal_approx(target):
				dot(next, ink)
				todo.append(next)
	changed.emit()

func move_selection(offset: Vector2i) -> void:
	var clipped := selection.intersection(Rect2i(Vector2i.ZERO, image().get_size()))
	if not clipped.has_area(): return
	var part := image().get_region(clipped)
	image().fill_rect(clipped, Color.TRANSPARENT)
	image().blit_rect(part, Rect2i(Vector2i.ZERO, part.get_size()), clipped.position + offset)
	selection.position += offset
	changed.emit()

func replace_color(old: Color, replacement: Color) -> void:
	checkpoint()
	for y in image().get_height():
		for x in image().get_width():
			if image().get_pixel(x, y).is_equal_approx(old):
				image().set_pixel(x, y, replacement)
	changed.emit()

func quantized(palette: Array[Color]) -> Image:
	var result := image().duplicate() as Image
	if palette.is_empty(): return result
	for y in result.get_height():
		for x in result.get_width():
			var original := result.get_pixel(x, y)
			if original.a == 0.0: continue
			var nearest := palette[0]
			var distance := INF
			for ink in palette:
				var d := Vector3(original.r - ink.r, original.g - ink.g, original.b - ink.b).length_squared()
				if d < distance:
					distance = d
					nearest = ink
			nearest.a = original.a
			result.set_pixel(x, y, nearest)
	return result

func add_frame(duplicate_current: bool = false) -> void:
	if frames.size() >= 64 or (frames.size() + 1) * image().get_width() * image().get_height() > 4194304: return
	checkpoint()
	frames.insert(index + 1, image().duplicate() if duplicate_current else Image.create_empty(image().get_width(), image().get_height(), false, Image.FORMAT_RGBA8))
	durations.insert(index + 1, durations[index])
	index += 1
	changed.emit()

func remove_frame() -> void:
	if frames.size() < 2: return
	checkpoint()
	frames.remove_at(index)
	durations.remove_at(index)
	index = mini(index, frames.size() - 1)
	changed.emit()

func reorder(direction: int) -> void:
	var next := clampi(index + direction, 0, frames.size() - 1)
	if next == index: return
	checkpoint()
	var frame := frames[index]
	var duration := durations[index]
	frames[index] = frames[next]
	durations[index] = durations[next]
	frames[next] = frame
	durations[next] = duration
	index = next
	changed.emit()

func load_png(path: String, frame_size := Vector2i.ZERO) -> Error:
	var source := Image.load_from_file(ProjectSettings.globalize_path(path))
	if source == null or source.is_empty(): return ERR_FILE_CORRUPT
	source.convert(Image.FORMAT_RGBA8)
	if source.get_width() > 4096 or source.get_height() > 4096: return ERR_OUT_OF_MEMORY
	if frame_size == Vector2i.ZERO: frame_size = source.get_size()
	if frame_size.x < 1 or frame_size.y < 1 or frame_size.x > 512 or frame_size.y > 512: return ERR_INVALID_PARAMETER
	if source.get_width() % frame_size.x != 0 or source.get_height() % frame_size.y != 0: return ERR_INVALID_PARAMETER
	var count := int(source.get_width() / frame_size.x) * int(source.get_height() / frame_size.y)
	if count > 64 or count * frame_size.x * frame_size.y > 4194304: return ERR_OUT_OF_MEMORY
	checkpoint()
	frames.clear()
	durations.clear()
	for y in int(source.get_height() / frame_size.y):
		for x in int(source.get_width() / frame_size.x):
			frames.append(source.get_region(Rect2i(Vector2i(x, y) * frame_size, frame_size)))
			durations.append(0.13)
	index = 0
	source_path = path
	var meta := path + ".frames.json"
	if FileAccess.file_exists(meta):
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(meta))
		if data is Dictionary and data.get("durations", []).size() == frames.size():
			for i in frames.size(): durations[i] = clampf(float(data.durations[i]), 0.02, 10.0)
	dirty = false
	changed.emit()
	return OK

func save_png(path: String) -> Error:
	if image().get_width() * frames.size() > 16384: return ERR_OUT_OF_MEMORY
	var sheet := Image.create_empty(image().get_width() * frames.size(), image().get_height(), false, Image.FORMAT_RGBA8)
	for i in frames.size():
		sheet.blit_rect(frames[i], Rect2i(Vector2i.ZERO, frames[i].get_size()), Vector2i(i * image().get_width(), 0))
	var result := sheet.save_png(path)
	if result != OK: return result
	var meta := FileAccess.open(path + ".frames.json", FileAccess.WRITE)
	if meta == null: return FileAccess.get_open_error()
	meta.store_string(JSON.stringify({"version": 1, "frame_size": [image().get_width(), image().get_height()], "durations": durations}, "	"))
	source_path = path
	dirty = false
	changed.emit()
	return OK
