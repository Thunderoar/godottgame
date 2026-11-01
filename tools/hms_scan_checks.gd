class_name HmsScanChecks
extends RefCounted


class RecordingBridge extends RefCounted:
	var received_content := ""
	var received_size := 0
	var response: Variant = PackedByteArray()


	func generate_qr(content: String, size: int) -> Variant:
		received_content = content
		received_size = size
		return response


static func run(check: Callable) -> void:
	var before := GameState.data.duplicate(true)
	var bridge := RecordingBridge.new()
	check.call(not bool(HmsScanService._generate_with_bridge(null).ok), "HMS: missing bridge reports unavailable")
	check.call(not bool(HmsScanService._generate_with_bridge(RefCounted.new()).ok), "HMS: incompatible bridge reports unavailable")
	check.call(not bool(HmsScanService._generate_with_bridge(bridge).ok), "HMS: native generation failure reports failure")
	bridge.response = "not a PNG buffer"
	check.call(not bool(HmsScanService._generate_with_bridge(bridge).ok), "HMS: wrong native return type reports failure")
	var image := Image.create(512, 512, false, Image.FORMAT_RGB8)
	image.fill(Color.WHITE)
	bridge.response = image.save_png_to_buffer()
	var generated := HmsScanService._generate_with_bridge(bridge)
	check.call(bool(generated.ok) and generated.texture is ImageTexture and generated.texture.get_size() == Vector2(512, 512), "HMS: native PNG bytes become a display texture")
	check.call(bridge.received_content == "PB (Protect BESUT)\nAlam ini perlukan pelindung." and bridge.received_size == 512, "HMS: QR payload contains only the public BESUT message")
	if OS.has_feature("android"):
		check.call(HmsScanService.available(), "HMS: Android export loads the real Scan Kit singleton")
		var actual := HmsScanService.generate_message_qr()
		check.call(bool(actual.ok) and actual.get("texture") is ImageTexture, "HMS: real Android SDK generates QR without an app ID or account")
	else:
		check.call(not HmsScanService.available() and not bool(HmsScanService.generate_message_qr().ok), "HMS: desktop reports unavailable without pretending to generate a QR")
	check.call(GameState.data == before, "HMS: generating a message never changes journey data")
