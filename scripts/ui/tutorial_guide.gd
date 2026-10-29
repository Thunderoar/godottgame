class_name TutorialGuide
extends PanelContainer
## Action-based New Journey tutorial. It is intentionally non-blocking: the player
## can still move and fight while reading, and can skip at any time.

var _step := 0
var _tips_enabled := false
var _title: Label
var _body: Label
var _counter: Label
var _next: Button

const STEPS := MissionDB.STEPS


func _ready() -> void:
	z_index = 101
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = -338
	offset_right = -22
	offset_top = 226
	offset_bottom = 468
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", GameUI.style(Color(0.03, 0.075, 0.085, 0.94), Color("#5c8c85"), 2, 0))
	visible = false
	_build()
	GameState.data_changed.connect(_on_mission_changed)
	GameState.day_phase_changed.connect(func(_night: bool) -> void: _on_mission_changed())


func _build() -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	add_child(box)
	var top := HBoxContainer.new()
	box.add_child(top)
	var tag := GameUI.label("NEW JOURNEY", 11, GameUI.TEAL)
	tag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(tag)
	_counter = GameUI.label("1/8", 11, GameUI.MUTED)
	top.add_child(_counter)
	_title = GameUI.title("Move", 21, GameUI.TEXT)
	box.add_child(_title)
	_body = GameUI.label("", 13, Color("#d9e5d9"))
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_body)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	box.add_child(buttons)
	var skip := GameUI.button("Hide tips", Vector2(92, 34))
	skip.pressed.connect(_skip)
	buttons.add_child(skip)
	_next = GameUI.button("Next", Vector2(150, 34))
	_next.disabled = true
	_next.pressed.connect(func() -> void:
		var game := get_tree().get_first_node_in_group("game") as Game
		if is_instance_valid(game):
			game.hud.field_guide_panel._category = 3
			game.open_field_guide())
	buttons.add_child(_next)


func start() -> void:
	_tips_enabled = true
	_step = GameState.mission_step()
	visible = not GameState.tutorial_complete()
	_render()


func _on_mission_changed() -> void:
	_step = GameState.mission_step()
	visible = _tips_enabled and not GameState.tutorial_complete()
	_render()

func _advance() -> void:
	# Lessons complete only when the player performs the requested action.
	_render()

func _skip() -> void:
	_tips_enabled = false
	visible = false
	GameState.toast_requested.emit("Tutorial skipped. Open Backpack or speak to residents for help.", "info")


func _render() -> void:
	if _step >= STEPS.size():
		_title.text = "Night lessons complete" if GameState.is_night() else "Day lessons complete"
		_body.text = ("Daytime lessons resume at dawn. Surviving monsters still attack: protect the village and keep Health Potions ready." if GameState.is_night() else "The remaining battle lessons start at night. Prepare weapons, carry Health Potions and help the village until dusk.")
		_counter.text = "WAIT FOR DAWN" if GameState.is_night() else "WAIT FOR NIGHT"
		_next.text = "Story & Sea Guide"
		_next.disabled = false
		return
	_next.disabled = true
	var entry: Dictionary = MissionDB.step(_step)
	var title := str(entry.get("title", "Mission"))
	_title.text = title.substr(title.find(". ") + 2) if title.contains(". ") else title
	_body.text = str(entry.text)
	var steps := MissionDB.phase_steps(GameState.is_night())
	_counter.text = "%s %d/%d" % ["NIGHT" if GameState.is_night() else "DAY", steps.find(_step) + 1, steps.size()]
	_next.text = "Do this task"
