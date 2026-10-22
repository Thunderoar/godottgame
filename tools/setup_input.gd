extends SceneTree
## Adds the movement input actions to project.godot.
##
##   godot --headless --path <project> --script tools/setup_input.gd
##
## Written as a script rather than hand-edited into project.godot because the
## serialised InputEventKey form is long and easy to get subtly wrong.

const ACTIONS := {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"interact": [KEY_E],
}


func _init() -> void:
	for action in ACTIONS:
		var events := []
		for keycode in ACTIONS[action]:
			var ev := InputEventKey.new()
			ev.device = -1            # -1 = accept the key from any device
			ev.physical_keycode = keycode
			events.append(ev)
		ProjectSettings.set_setting("input/" + action, {"deadzone": 0.2, "events": events})
	var err := ProjectSettings.save()
	print("input actions written: %s" % ("ok" if err == OK else error_string(err)))
	quit()
