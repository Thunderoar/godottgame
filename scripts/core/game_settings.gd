extends Node
## Device-level settings, deliberately independent of any save file (decision D2).
##
## Backed by a ConfigFile at `user://settings.cfg`, so the title screen can read
## and write them before a save exists, and so they survive New Game and
## `GameState.delete_save()`. `config_path` is a plain var on purpose: the test
## suite points it at a scratch file and calls `load_settings()` /
## `reset_to_defaults()`, so the real `settings.cfg` is never touched.
##
## Keys and defaults (all clamped/validated on read and on write):
##   master_volume            int    0..100            default 100  (Master bus)
##   effects_volume           int    0..100            default 100  (SFX bus, driven by Sfx)
##   mute_all                 bool                     default false
##   fullscreen               bool                     default false
##   ui_scale                 int    75..130           default 100  (percent)
##   touch_controls           String auto|always|hidden default "always"
##   screen_shake             bool                     default true
##   auto_pause_on_focus_loss bool                     default true
##   reduce_motion            bool                     default false
##   visual_style             String modern|pixel     default "pixel" (restart)
##   effects_quality          String low|med|high     default "high"
##
## This node applies what it owns: the Master bus (volume + mute) and the window
## mode. The SFX bus belongs to `Sfx`, which reads `effects_volume()`/`mute_all()`
## and re-applies on `changed`. `ui_scale`, `touch_controls`, `screen_shake` and
## `auto_pause_on_focus_loss` are plain stored values that their owners read when
## they need them. Every accepted change emits `changed(key)`.
##
## Setters take `persist := true`. A settings panel should pass `false` while a
## slider is dragged and `true` once on release, so the file is not rewritten on
## every tick.

signal changed(key: String)

const CONFIG_PATH := "user://settings.cfg"
const SECTION := "settings"
## 0 % must never reach `linear_to_db()`: it returns -inf, which the audio server
## refuses. -60 dB is inaudible and keeps the bus arithmetic finite.
const SILENCE_DB := -60.0
const UI_SCALE_MIN := 75
const UI_SCALE_MAX := 130
const CAMERA_ZOOM_MIN := 28
const CAMERA_ZOOM_MAX := 64
const CAMERA_ZOOM_DEFAULT := 38
const TOUCH_MODES := ["auto", "always", "hidden"]
const EFFECT_QUALITIES := ["low", "med", "high"]
const VISUAL_STYLES := ["modern", "pixel"]
const VISUAL_STYLE_LABELS := ["Modern Illustrated", "Classic Pixel"]

const DEFAULTS := {
        "master_volume": 100,
        "effects_volume": 100,
        "mute_all": false,
        "fullscreen": false,
        "ui_scale": 100,
        "camera_zoom": CAMERA_ZOOM_DEFAULT,
        "touch_controls": "always",
        "screen_shake": true,
        "auto_pause_on_focus_loss": true,
        "reduce_motion": false,
        "effects_quality": "high",
        "visual_style": "pixel",
}

## Override before `load_settings()` to redirect persistence (tests do this).
var config_path := CONFIG_PATH

var _values: Dictionary = DEFAULTS.duplicate(true)
# Latch once at startup: never mix art families or rebuild a running world.
var _active_visual_style := "pixel"


func _ready() -> void:
        load_settings()
        _active_visual_style = visual_style()


# --------------------------------------------------------------- load / persist

func load_settings() -> void:
        _values = DEFAULTS.duplicate(true)
        var config := ConfigFile.new()
        var load_error := config.load(config_path)
        if load_error == OK:
                for key in DEFAULTS.keys():
                        if config.has_section_key(SECTION, key):
                                _values[key] = _sanitize_value(key, config.get_value(SECTION, key))
        # Persist migration before a new/deleted journey loses the legacy value.
        var migrate := not config.has_section_key(SECTION, "ui_scale") and load_error in [OK, ERR_FILE_NOT_FOUND]
        if migrate:
                var legacy: Dictionary = GameState.data.get("settings", {})
                _values["ui_scale"] = _sanitize_value("ui_scale", roundi(float(legacy.get("gui_scale", 1.0)) * 100.0))
        _apply_all()
        if migrate:
                save_settings()


func save_settings() -> void:
        var config := ConfigFile.new()
        for key in DEFAULTS.keys():
                config.set_value(SECTION, key, _values.get(key, DEFAULTS[key]))
        var error := config.save(config_path)
        if error != OK:
                push_warning("Could not save settings: %s" % error_string(error))


func reset_to_defaults() -> void:
        var touched: Array[String] = []
        for key in DEFAULTS.keys():
                var previous: Variant = _values.get(key, DEFAULTS[key])
                _values[key] = DEFAULTS[key]
                if previous != _values[key]:
                        touched.append(str(key))
        _apply_all()
        save_settings()
        for key in touched:
                changed.emit(key)


# --------------------------------------------------------------- generic access

func get_value(key: String) -> Variant:
        return _values.get(key, DEFAULTS.get(key))


func set_value(key: String, value: Variant, persist: bool = true) -> void:
        if not DEFAULTS.has(key):
                return
        var clean: Variant = _sanitize_value(key, value)
        var previous: Variant = _values.get(key, DEFAULTS[key])
        _values[key] = clean
        _apply_key(key)
        if persist:
                save_settings()
        if previous != clean:
                changed.emit(key)


func _sanitize_value(key: String, value: Variant) -> Variant:
        match key:
                "master_volume", "effects_volume":
                        return clampi(int(value), 0, 100)
                "camera_zoom":
                        return clampi(int(value), CAMERA_ZOOM_MIN, CAMERA_ZOOM_MAX)
                "ui_scale":
                        return clampi(int(value), UI_SCALE_MIN, UI_SCALE_MAX)
                "touch_controls":
                        var mode := str(value).to_lower()
                        return mode if TOUCH_MODES.has(mode) else str(DEFAULTS["touch_controls"])
                "visual_style":
                        var style := str(value).to_lower()
                        return style if VISUAL_STYLES.has(style) else str(DEFAULTS["visual_style"])
                "effects_quality":
                        var quality := str(value).to_lower()
                        return quality if EFFECT_QUALITIES.has(quality) else str(DEFAULTS["effects_quality"])
                "mute_all", "fullscreen", "screen_shake", "auto_pause_on_focus_loss", "reduce_motion":
                        return _as_bool(value, bool(DEFAULTS[key]))
        return DEFAULTS.get(key, value)


func _as_bool(value: Variant, fallback: bool) -> bool:
        if value is bool:
                return value
        if value is int or value is float:
                return int(value) != 0
        if value is String:
                return str(value).to_lower() in ["true", "1", "yes", "on"]
        return fallback


# --------------------------------------------------------------- apply

func _apply_all() -> void:
        apply_audio()
        apply_display()


func _apply_key(key: String) -> void:
        match key:
                "master_volume", "mute_all":
                        apply_audio()
                "fullscreen":
                        apply_display()


func apply_audio() -> void:
        var index := AudioServer.get_bus_index("Master")
        if index < 0:
                return
        AudioServer.set_bus_volume_db(index, volume_percent_to_db(master_volume()))
        AudioServer.set_bus_mute(index, mute_all() or master_volume() <= 0)


func apply_display() -> void:
        # The gate runs headless: a dummy DisplayServer would only log errors.
        if DisplayServer.get_name() == "headless":
                return
        var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen() else DisplayServer.WINDOW_MODE_WINDOWED
        if DisplayServer.window_get_mode() != mode:
                DisplayServer.window_set_mode(mode)


static func volume_percent_to_db(percent: int) -> float:
        if percent <= 0:
                return SILENCE_DB
        return clampf(linear_to_db(float(percent) / 100.0), SILENCE_DB, 0.0)


# --------------------------------------------------------------- typed accessors

func master_volume() -> int:
        return int(_values.get("master_volume", 100))


func set_master_volume(value: int, persist: bool = true) -> void:
        set_value("master_volume", value, persist)


func effects_volume() -> int:
        return int(_values.get("effects_volume", 100))


func set_effects_volume(value: int, persist: bool = true) -> void:
        set_value("effects_volume", value, persist)


func mute_all() -> bool:
        return bool(_values.get("mute_all", false))


func set_mute_all(value: bool, persist: bool = true) -> void:
        set_value("mute_all", value, persist)


func fullscreen() -> bool:
        return bool(_values.get("fullscreen", false))


func set_fullscreen(value: bool, persist: bool = true) -> void:
        set_value("fullscreen", value, persist)


func ui_scale() -> int:
        return int(_values.get("ui_scale", 100))


func set_ui_scale(value: int, persist: bool = true) -> void:
        set_value("ui_scale", value, persist)


func touch_controls() -> String:
        return str(_values.get("touch_controls", "always"))


func set_touch_controls(value: String, persist: bool = true) -> void:
        set_value("touch_controls", value, persist)


func screen_shake() -> bool:
        return bool(_values.get("screen_shake", true))


func set_screen_shake(value: bool, persist: bool = true) -> void:
        set_value("screen_shake", value, persist)


func auto_pause_on_focus_loss() -> bool:
        return bool(_values.get("auto_pause_on_focus_loss", true))


func set_auto_pause_on_focus_loss(value: bool, persist: bool = true) -> void:
        set_value("auto_pause_on_focus_loss", value, persist)


func reduce_motion() -> bool:
        return bool(_values.get("reduce_motion", false))


func set_reduce_motion(value: bool, persist: bool = true) -> void:
        set_value("reduce_motion", value, persist)


func effects_quality() -> String:
        return str(_values.get("effects_quality", "high"))


func set_effects_quality(value: String, persist: bool = true) -> void:
        set_value("effects_quality", value, persist)


func effects_at_least(level: String) -> bool:
        # True when the current quality tier is at or above `level` (low < med < high).
        var order := {"low": 0, "med": 1, "high": 2}
        return int(order.get(effects_quality(), 2)) >= int(order.get(level, 2))


func camera_zoom() -> float:
        return float(_values.get("camera_zoom", CAMERA_ZOOM_DEFAULT))


func set_camera_zoom(value: float, persist: bool = true) -> void:
        set_value("camera_zoom", roundi(value), persist)


func visual_style() -> String:
        return str(_values.get("visual_style", DEFAULTS["visual_style"]))


func set_visual_style(value: String, persist: bool = true) -> void:
        set_value("visual_style", value, persist)


func active_visual_style() -> String:
        return _active_visual_style
