class_name HmsScanService
extends RefCounted
## Local QR generation through the Android HUAWEI Scan Kit bridge.

const SINGLETON := "ProtectBesutHms"
const PAGE_URL := "https://yizzan1.github.io/protect-besut/"
const MESSAGE := PAGE_URL
const QR_SIZE := 512


static func available() -> bool:
	return OS.has_feature("android") and Engine.has_singleton(SINGLETON)


static func generate_message_qr() -> Dictionary:
	if not available():
		return {"ok": false, "message": "QR sharing is available in the Android HMS build."}
	return _generate_with_bridge(Engine.get_singleton(SINGLETON))


static func _generate_with_bridge(bridge: Object) -> Dictionary:
	if not _supports_generation(bridge):
		return {"ok": false, "message": "QR sharing is unavailable in this build."}
	var result: Variant = bridge.call("generate_qr", MESSAGE, QR_SIZE)
	if not result is PackedByteArray or result.is_empty():
		return {"ok": false, "message": "Could not create the QR code. Please try again."}
	var image := Image.new()
	if image.load_png_from_buffer(result) != OK:
		return {"ok": false, "message": "Could not display the QR code. Please try again."}
	return {"ok": true, "texture": ImageTexture.create_from_image(image)}


static func _supports_generation(bridge: Object) -> bool:
	if bridge == null: return false
	# Android JNISingleton methods live in the Java method table, outside
	# Object.has_method(). Keep the ordinary check for desktop test adapters.
	if bridge.has_method("has_java_method"):
		return bool(bridge.call("has_java_method", &"generate_qr"))
	return bridge.has_method("generate_qr")
