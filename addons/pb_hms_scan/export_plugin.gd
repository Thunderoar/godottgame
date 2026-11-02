@tool
extends EditorPlugin

var _export_plugin: AndroidExport


func _enter_tree() -> void:
	_export_plugin = AndroidExport.new()
	add_export_plugin(_export_plugin)


func _exit_tree() -> void:
	remove_export_plugin(_export_plugin)
	_export_plugin = null


class AndroidExport extends EditorExportPlugin:
	func _get_name() -> String:
		return "ProtectBesutHms"


	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid


	func _get_android_libraries(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray(["res://addons/pb_hms_scan/bin/ProtectBesutHms.aar"])


	func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray(["com.huawei.hms:scan:2.15.0.301"])


	func _get_android_dependencies_maven_repos(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray(["https://developer.huawei.com/repo/"])


	func _get_android_manifest_element_contents(_platform: EditorExportPlatform, _debug: bool) -> String:
		# Local QR generation needs none of the optional SDK network/camera permissions.
		var entries := ""
		for permission in ["INTERNET", "ACCESS_NETWORK_STATE", "ACCESS_WIFI_STATE", "CAMERA", "READ_EXTERNAL_STORAGE", "WRITE_EXTERNAL_STORAGE", "READ_MEDIA_IMAGES"]:
			entries += '<uses-permission xmlns:tools="http://schemas.android.com/tools" android:name="android.permission.%s" tools:node="remove" />\n' % permission
		return entries
