extends SceneTree
## Build-time helper: resize icon.png and write a multi-size Windows .ico so
## the exported executable has a crisp icon in Explorer and the taskbar.
## Not part of the shipped game. Run with:
##   godot --headless --path . --script res://tools/make_icon.gd

const SIZES := [16, 32, 48, 64, 128, 256]


func _init() -> void:
	var source := Image.load_from_file("res://icon.png")
	if source == null or source.is_empty():
		push_error("icon.png could not be read")
		quit(1)
		return

	var pngs: Array[PackedByteArray] = []
	for size: int in SIZES:
		var image := source.duplicate() as Image
		image.convert(Image.FORMAT_RGBA8)
		if image.get_width() != size or image.get_height() != size:
			image.resize(size, size, Image.INTERPOLATE_LANCZOS)
		pngs.append(image.save_png_to_buffer())

	var count := SIZES.size()
	var offset := 6 + 16 * count
	var file := FileAccess.open("res://icon.ico", FileAccess.WRITE)
	if file == null:
		push_error("Could not open icon.ico for writing: %s" % FileAccess.get_open_error())
		quit(1)
		return
	file.store_16(0)  # reserved
	file.store_16(1)  # type: icon
	file.store_16(count)
	for i in count:
		var size: int = SIZES[i]
		var png: PackedByteArray = pngs[i]
		file.store_8(0 if size >= 256 else size)
		file.store_8(0 if size >= 256 else size)
		file.store_8(0)  # palette colours
		file.store_8(0)  # reserved
		file.store_16(1)  # colour planes
		file.store_16(32)  # bits per pixel
		file.store_32(png.size())
		file.store_32(offset)
		offset += png.size()
	for png: PackedByteArray in pngs:
		file.store_buffer(png)
	file.close()
	print("Wrote icon.ico with sizes: %s" % str(SIZES))
	quit(0)
