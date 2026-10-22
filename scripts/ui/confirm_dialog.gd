class_name ConfirmDialog
extends ModalBase
## Reusable yes/no dialog for destructive actions (spec 4.6).
##
## It extends `ModalBase` for the established look (full-screen dim + framed
## panel + header), with four deliberate differences:
##   * no `await` before showing, so it works from the title screen and while the
##     tree is paused (`PROCESS_MODE_ALWAYS`),
##   * Esc, the Cancel button and the header Close all cancel,
##   * Cancel holds the default focus, so a destructive ask needs an extra step,
##   * `close_panel()` cancels instead of clearing the body, so one instance can
##     be reused for several asks.
##
## Parent it to the layer that owns the opener (title layer, pause layer, HUD)
## and call `ask()` after `add_child()`. `confirmed` / `cancelled` are the action
## signals; `closed` fires right after either one for opener cleanup.

signal confirmed
signal cancelled

const PANEL_SIZE := Vector2(540, 250)
const BUTTON_SIZE := Vector2(150, 46)
const BODY_MIN_HEIGHT := 70
const DANGER_FILL := Color("#2a1518")
const DANGER_HOVER := Color("#3d1d22")

var _body_label: Label
var _confirm_button: Button
var _cancel_button: Button
var _danger := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Same layer as the opener: the higher z_index keeps this above it.
	z_index = 10
	_panel_size = PANEL_SIZE
	super._ready()
	_close_button.visible = false
	_build_body()


func _build_body() -> void:
	_body_label = GameUI.label("", 16, GameUI.MUTED)
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_label.custom_minimum_size = Vector2(0, BODY_MIN_HEIGHT)
	content.add_child(_body_label)
	content.add_child(GameUI.spacer(8))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 12)
	content.add_child(row)
	_cancel_button = _make_button("Cancel", GameUI.TEXT)
	_cancel_button.pressed.connect(_cancel)
	row.add_child(_cancel_button)
	_confirm_button = _make_button("OK", GameUI.GOLD)
	_confirm_button.pressed.connect(_confirm)
	row.add_child(_confirm_button)


func _make_button(text: String, color: Color) -> Button:
	var button := GameUI.button(text, BUTTON_SIZE, color)
	# Menu buttons are keyboard reachable and show where the focus is.
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_stylebox_override("focus", GameUI.style(Color(0, 0, 0, 0), GameUI.GOLD, 2, 0))
	return button


## Shows the dialog. Add it to the tree before calling this.
func ask(title: String, body: String, confirm_text: String, danger: bool = false) -> void:
	_title = title
	_danger = danger
	if header_label != null:
		header_label.text = title
	_body_label.text = body
	_confirm_button.text = confirm_text
	_apply_confirm_style()
	_fit_panel()
	visible = true
	move_to_front()
	_cancel_button.grab_focus()


func _apply_confirm_style() -> void:
	if _danger:
		_confirm_button.add_theme_color_override("font_color", GameUI.TEXT)
		_confirm_button.add_theme_stylebox_override("normal", GameUI.style(DANGER_FILL, GameUI.RED, 2, 0))
		_confirm_button.add_theme_stylebox_override("hover", GameUI.style(DANGER_HOVER, GameUI.RED, 2, 0))
		_confirm_button.add_theme_stylebox_override("pressed", GameUI.style(GameUI.RED, Color("#ffe4e6"), 2, 0))
		return
	_confirm_button.add_theme_color_override("font_color", GameUI.GOLD)
	for state in ["normal", "hover", "pressed"]:
		_confirm_button.remove_theme_stylebox_override(state)


func _confirm() -> void:
	_dismiss()
	confirmed.emit()
	closed.emit()


func _cancel() -> void:
	_dismiss()
	cancelled.emit()
	closed.emit()


func close_panel() -> void:
	_cancel()


func _dismiss() -> void:
	visible = false
	if _cancel_button != null:
		_cancel_button.release_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_cancel()
		get_viewport().set_input_as_handled()
