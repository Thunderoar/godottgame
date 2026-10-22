class_name ControlModePrefs
extends RefCounted
## Port of Unisza' ControlMode.cs / ControlModePrefs.
##
## PlayerPrefs survives across builds, so the stored int is range-checked before
## it is cast: an enum value that was later removed or reordered would otherwise
## be trusted blindly.

enum ControlMode { KEYBOARD, JOYSTICK, CLICK_TO_MOVE, FOLLOW_MOUSE }

const PATH := "user://unisza.cfg"
const SECTION := "control"
const KEY := "mode"


static func get_default() -> int:
	return ControlMode.JOYSTICK if OS.has_feature("mobile") else ControlMode.KEYBOARD


static func load_mode() -> int:
	var cfg := ConfigFile.new()
	var fallback := get_default()
	if cfg.load(PATH) != OK:
		return fallback
	var raw: int = cfg.get_value(SECTION, KEY, fallback)
	if raw < 0 or raw > ControlMode.FOLLOW_MOUSE:
		return fallback
	return raw


static func save_mode(mode: int) -> void:
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value(SECTION, KEY, mode)
	cfg.save(PATH)