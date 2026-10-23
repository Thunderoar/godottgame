class_name AuthoredSprite
extends Sprite2D
## Preload a bounded clip once; no filesystem access or image creation during playback.
var frames: Array[Texture2D] = []
var durations: Array[float] = []
var index := 0
var clock := 0.0

func configure(id: String) -> void:
	var entry: Dictionary = AssetRegistry.library().entries.get(id, {})
	var count := clampi(int(entry.get("frames", 1)), 1, 256)
	for i in count:
		var frame := AssetRegistry.get_texture(id, i)
		if frame: frames.append(frame)
	if frames.is_empty():
		texture = AuthoredMapRenderer.object_texture(id)
		set_process(false)
	else:
		texture = frames[0]
		for i in frames.size():
			var duration_values: Array = entry.get("durations", [])
			durations.append(maxf(0.02, float(duration_values[i]) if i < duration_values.size() else 1.0 / maxf(1, float(entry.get("fps", 8)))))
		set_process(frames.size() > 1)
	if texture:
		var pivot: Vector2 = entry.get("pivot", Vector2(texture.get_width() * 0.5, texture.get_height()))
		offset = texture.get_size() * 0.5 - pivot

func _ready() -> void:
	set_process(frames.size() > 1 and durations.size() == frames.size())

func _process(delta: float) -> void:
	if frames.size() < 2 or durations.size() != frames.size() or GameSettings.reduce_motion(): return
	clock += delta
	if clock >= durations[index]:
		clock = fmod(clock, durations[index])
		index = (index + 1) % frames.size()
		texture = frames[index]
