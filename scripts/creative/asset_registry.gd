@tool
class_name AssetRegistry
extends RefCounted
## Runtime uses imported Texture2D resources (export safe), not source Image paths.
const PATH := "res://data/asset_registry/library.tres"
const LIMIT := 384
static var catalog: AssetCatalog
static var _cache: Dictionary = {}
static var _reported: Dictionary = {}

static func library() -> AssetCatalog:
	if catalog == null:
		catalog = load(PATH) as AssetCatalog
	return catalog

static func invalidate() -> void:
	_cache.clear()
	_reported.clear()
	PixelArt.CACHE.clear()

static func get_texture(id: String, frame: int = 0) -> Texture2D:
	var entry: Dictionary = library().entries.get(id, {})
	if entry.is_empty() and id.begins_with("character_"):
		var parts := id.split("_")
		if parts.size() == 4:
			entry = library().entries.get("character/" + parts[1], {})
			var walk_frame := int(parts[3])
			var direction := int(parts[2])
			frame = direction * int(entry.get("frames_per_direction", 7)) + walk_frame
	if entry.is_empty():
		return null
	var key := id + ":" + str(frame)
	if _cache.has(key):
		return _cache[key]
	var path := str(entry.get("path", ""))
	var texture: Texture2D
	if ResourceLoader.exists(path):
		texture = load(path) as Texture2D
	if texture == null:
		if not _reported.has(id):
			if entry.get("required", false):
				push_error("Tidesworn REQUIRED asset '%s' missing: %s. Fix the Asset Library path." % [id, path])
			else:
				push_warning("Tidesworn asset '%s' missing: %s; procedural fallback" % [id, path])
			_reported[id] = true
		if entry.get("required", false):
			var missing := Image.create_empty(32, 32, false, Image.FORMAT_RGBA8)
			missing.fill(Color.MAGENTA)
			missing.fill_rect(Rect2i(0, 0, 16, 16), Color.BLACK)
			missing.fill_rect(Rect2i(16, 16, 16, 16), Color.BLACK)
			var diagnostic := ImageTexture.create_from_image(missing)
			_cache[key] = diagnostic
			return diagnostic
		return null
	var size: Vector2i = entry.get("frame_size", Vector2i.ZERO)
	if size.x > 0 and size.y > 0:
		var cols := maxi(1, int(entry.get("columns", int(texture.get_width() / size.x))))
		var count := maxi(1, int(entry.get("frames", cols)))
		var index := posmod(frame, count)
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		var margin := int(entry.get("margin", 0))
		var spacing := int(entry.get("spacing", 0))
		atlas.region = Rect2(Vector2(margin + (index % cols) * (size.x + spacing), margin + int(index / cols) * (size.y + spacing)), Vector2(size))
		texture = atlas
	if _cache.size() >= LIMIT:
		_cache.clear()
	_cache[key] = texture
	return texture

static func diagnostics() -> PackedStringArray:
	var problems := PackedStringArray()
	for id in library().entries:
		var entry: Dictionary = library().entries[id]
		if not ResourceLoader.exists(str(entry.get("path", ""))):
			problems.append("%s: missing %s" % [id, entry.get("path", "")])
	return problems
