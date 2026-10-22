class_name TutorialGuide
extends PanelContainer
## Eight-step New Journey tutorial. It is intentionally non-blocking: the player
## can still move and fight while reading, and can skip at any time.

var _step := 0
var _title: Label
var _body: Label
var _counter: Label
var _next: Button

const STEPS := [
	{
		"title": "Move",
		"text": "Use the bottom-left joystick or WASD to move around the cottage yard. The joystick works while you attack with the other hand.",
	},
	{
		"title": "Combat",
		"text": "Tap Strike or press F. Qayyim swings a sword, Farhan slams a hammer and Ayiz fires arrows at the nearest target in front of him.",
	},
	{
		"title": "Automatic collection",
		"text": "Walk over gold, diamonds and item drops. There is no collect button — contact picks loot up automatically.",
	},
	{
		"title": "Shops",
		"text": "Approach a merchant and tap Use or press E. Gold buys potions, armour, shields and your hero's weapon upgrades.",
	},
	{
		"title": "House upgrades",
		"text": "Talk to Bram beside the cottage. House levels cost diamonds only and improve sleep/recovery speed and the exterior.",
	},
	{
		"title": "Companions",
		"text": "Your companion fights with healing, attacks and shields. Feed it Pet Food and upgrade it at Nia's pet shop. It never dies permanently.",
	},
	{
		"title": "Portals",
		"text": "Open the Monster Battle Portal for ten boss levels, or the Pet Battle Portal for five 1v1 companion duels.",
	},
	{
		"title": "Village defence",
		"text": "While you are inside a portal, raiders can strike from the sea or forest. Return through the Shore Gate to help the guard, defenders and residents.",
	},
]


func _ready() -> void:
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
	var skip := GameUI.button("Skip", Vector2(92, 34))
	skip.pressed.connect(_skip)
	buttons.add_child(skip)
	_next = GameUI.button("Next", Vector2(150, 34))
	_next.pressed.connect(_advance)
	buttons.add_child(_next)


func start() -> void:
	_step = 0
	visible = true
	_render()


func _advance() -> void:
	_step += 1
	if _step >= STEPS.size():
		visible = false
		GameState.toast_requested.emit("Tutorial complete. The settlement is yours to shape.", "good")
		return
	_render()


func _skip() -> void:
	visible = false
	GameState.toast_requested.emit("Tutorial skipped. Open Backpack or speak to residents for help.", "info")


func _render() -> void:
	var entry: Dictionary = STEPS[_step]
	_title.text = str(entry.title)
	_body.text = str(entry.text)
	_counter.text = "%d/%d" % [_step + 1, STEPS.size()]
	_next.text = "Finish" if _step == STEPS.size() - 1 else "Next"
