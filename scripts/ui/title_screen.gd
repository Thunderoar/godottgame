class_name TitleScreen
extends Control
## Boot menu -> deliberate hero selection -> one guarded journey handoff.
## Browsing never writes player data. Device settings belong to GameSettings.

signal character_selected(character_id: String)
signal continue_requested

enum Page { HOME, HEROES }
const INK := Color("#0d2029")
const CREAM := Color("#f4ebd8")
const GOLD := Color("#e4bc78")
const MUTED := Color("#a5b8b6")
const BORDER := Color("#49616a")
const HERO_ROLES := {"adam": "BALANCED", "arjun": "HEAVY HITTER", "mei_ling": "RANGED"}
const HERO_TACTICS := {
	"adam": "Quick sword strikes. Stay close and keep moving.",
	"arjun": "Wide scythe sweeps. Strike nearby enemies with heavy, sweeping attacks.",
	"mei_ling": "Long-range arrows. Keep your distance and pick your shot.",
}

var save_available := false
var current_page: Page = Page.HOME
var selected_character_id := "adam"
var _departing := false
var _margin: MarginContainer
var _home: HBoxContainer
var _home_column: BoxContainer
var _home_intro: VBoxContainer
var _home_actions: VBoxContainer
var _home_title: Label
var _scenic_caption: VBoxContainer
var _heroes: VBoxContainer
var _cards: BoxContainer
var _card_buttons: Array[Button] = []
var _card_portraits: Array[TextureRect] = []
var _card_status: Array[Label] = []
var _card_details: Array[Control] = []
var _card_names: Array[Label] = []
var _hero_intro: Label
var _page_buttons: Array[Control] = []
var _start_button: Button
var _continue_button: Button
var _begin_button: Button
var _back_button: Button
var _hero_summary: Label
var _save_summary: Label
var _error: Label
var _overlay: Control
var _overlay_panel: PanelContainer
var _overlay_column: VBoxContainer
var _overlay_title: Label
var _overlay_body: VBoxContainer
var _overlay_actions: HBoxContainer
var _overlay_close: Button
var _overlay_focus: Control
var _footer_hint: Label
var _transition_tween: Tween
var _compact := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = GameUI.theme()
	var backdrop := TitleBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	_build()
	_build_overlay()
	resized.connect(_layout)
	GameSettings.changed.connect(_on_settings_changed)
	_show_page(Page.HOME, false)
	call_deferred("_layout")


func _build() -> void:
	_margin = MarginContainer.new()
	_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_margin)
	var shell := VBoxContainer.new()
	shell.add_theme_constant_override("separation", 18)
	_margin.add_child(shell)
	var header := HBoxContainer.new()
	header.add_child(_label("PB (Protect BESUT)", 17, CREAM))
	var location := _label("BESUT, TERENGGANU  /  MALAYSIA", 12, MUTED)
	location.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	location.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(location)
	if not OS.has_feature("web") and not OS.has_feature("mobile"):
		var quit := _button("Quit", func() -> void: get_tree().quit())
		quit.custom_minimum_size = Vector2(64, 34)
		quit.add_theme_font_size_override("font_size", 13)
		header.add_child(quit)
	shell.add_child(header)
	shell.add_child(GameUI.divider(Color(0.65, 0.74, 0.70, 0.22)))
	var body := Control.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell.add_child(body)
	_build_home(body)
	_build_heroes(body)
	var footer := HBoxContainer.new()
	footer.add_child(_label("Created by Qayyim, Farhan & Ayiz", 12, MUTED))
	_footer_hint = _label("MOUSE / TOUCH   ·   ARROWS + ENTER", 11, MUTED)
	_footer_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_footer_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_footer_hint)
	shell.add_child(footer)


func _build_home(parent: Control) -> void:
	_home = HBoxContainer.new()
	_home.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_home.add_theme_constant_override("separation", 40)
	parent.add_child(_home)
	var scroll := _scroll()
	scroll.custom_minimum_size.x = 460
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_home.add_child(scroll)
	_home_column = BoxContainer.new()
	_home_column.vertical = true
	_home_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_home_column.add_theme_constant_override("separation", 16)
	scroll.add_child(_home_column)
	_home_intro = VBoxContainer.new()
	_home_intro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_home_intro.add_theme_constant_override("separation", 10)
	_home_column.add_child(_home_intro)
	_home_intro.add_child(_label("A HOME WORTH FIGHTING FOR", 13, GOLD))
	_home_title = _label("PROTECT\nBESUT", 76, CREAM)
	_home_title.add_theme_constant_override("line_spacing", -12)
	_home_intro.add_child(_home_title)
	_home_intro.add_child(_paragraph("Between the forest and the sea, a village is counting on you.", 16, CREAM))
	_home_intro.add_child(_paragraph("Build a home. Find a companion. Defend your shore.", 14, MUTED))
	_home_actions = VBoxContainer.new()
	_home_actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_home_actions.add_theme_constant_override("separation", 10)
	_home_column.add_child(_home_actions)
	_start_button = _button("Start Game   →", _open_heroes, true)
	_start_button.name = "StartGame"
	_home_actions.add_child(_start_button)
	_continue_button = _button("Continue Journey", _request_continue)
	_continue_button.name = "ContinueJourney"
	_continue_button.disabled = not save_available
	_home_actions.add_child(_continue_button)
	_save_summary = _paragraph(_saved_journey_text() if save_available else "Your first chapter is waiting. Start a new journey.", 13, MUTED)
	_home_actions.add_child(_save_summary)
	_error = _paragraph("", 14, Color("#ffb2a0"))
	_error.visible = false
	_home_actions.add_child(_error)
	var utilities := HFlowContainer.new()
	utilities.add_theme_constant_override("h_separation", 10)
	utilities.add_theme_constant_override("v_separation", 8)
	_home_actions.add_child(utilities)
	for entry in [["How to Play", _open_guide], ["Settings", _open_settings], ["Credits", _open_credits]]:
		var button := _button(str(entry[0]), entry[1])
		button.custom_minimum_size = Vector2(124, 42)
		button.add_theme_font_size_override("font_size", 14)
		utilities.add_child(button)
	_scenic_caption = VBoxContainer.new()
	_scenic_caption.custom_minimum_size.x = 560
	_scenic_caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scenic_caption.alignment = BoxContainer.ALIGNMENT_BEGIN
	_scenic_caption.add_theme_constant_override("separation", 8)
	_home.add_child(_scenic_caption)
	_scenic_caption.add_child(GameUI.spacer(20))
	_scenic_caption.add_child(_label("01  /  THE SHORE WE CALL HOME", 12, GOLD))
	_scenic_caption.add_child(_label("Every great journey\nbegins with a little hope.", 26, CREAM))
	_scenic_caption.add_child(GameUI.spacer(22))


func _build_heroes(parent: Control) -> void:
	_heroes = VBoxContainer.new()
	_heroes.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_heroes.add_theme_constant_override("separation", 12)
	parent.add_child(_heroes)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 20)
	_back_button = _button("← Back", func() -> void: _show_page(Page.HOME))
	_back_button.custom_minimum_size = Vector2(110, 44)
	heading.add_child(_back_button)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_child(_label("CHOOSE YOUR ROAD", 32, CREAM))
	_hero_intro = _paragraph("Three heroes. One home to protect. Choose how you fight.", 15, MUTED)
	words.add_child(_hero_intro)
	heading.add_child(words)
	_heroes.add_child(heading)
	var scroll := _scroll()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_heroes.add_child(scroll)
	_cards = BoxContainer.new()
	_cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cards.add_theme_constant_override("separation", 16)
	scroll.add_child(_cards)
	for index in CharacterDB.CHARACTERS.size():
		_cards.add_child(_character_card(CharacterDB.CHARACTERS[index], index))
	var confirmation := _panel(Color("#102731"), BORDER)
	_heroes.add_child(confirmation)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	confirmation.add_child(row)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hero_summary = _paragraph("", 18, CREAM)
	info.add_child(_hero_summary)
	info.add_child(_paragraph("A new beginning in Besut Village, with Ember by your side.", 13, MUTED))
	row.add_child(info)
	_begin_button = _button("Begin Journey   →", _request_begin, true)
	_begin_button.name = "BeginJourney"
	_begin_button.custom_minimum_size.x = 238
	row.add_child(_begin_button)


func _character_card(character: Dictionary, index: int) -> Button:
	var id := str(character.get("id", ""))
	var card := _button("", func() -> void: _select_character(id))
	card.name = "Hero_%s" % id
	card.toggle_mode = true
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var padding := MarginContainer.new()
	padding.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		padding.add_theme_constant_override("margin_" + side, 12 if side in ["top", "bottom"] else 16)
	card.add_child(padding)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	padding.add_child(box)
	var role := _label("0%d  /  %s" % [index + 1, str(HERO_ROLES.get(id, "HERO"))], 11, GOLD)
	box.add_child(role)
	_card_details.append(role)
	var portrait := TextureRect.new()
	portrait.texture = PixelArt.portrait(id, 96)
	portrait.custom_minimum_size = Vector2(0, 72)
	portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	box.add_child(portrait)
	_card_portraits.append(portrait)
	var hero_name := _label(str(character.get("name", "Hero")), 28, CREAM)
	box.add_child(hero_name)
	_card_names.append(hero_name)
	box.add_child(_label("%s  ·  %s" % [str(character.get("heritage", "")), str(character.get("weapon", ""))], 14, GOLD))
	var desc := _paragraph(str(HERO_TACTICS.get(id, "")), 15, MUTED)
	desc.custom_minimum_size.y = 48
	box.add_child(desc)
	_card_details.append(desc)
	var divider := GameUI.divider(Color(0.65, 0.74, 0.70, 0.20))
	box.add_child(divider)
	_card_details.append(divider)
	box.add_child(_label("%d HP    %.1f SPD" % [int(character.get("hp", 0)), float(character.get("speed", 0))], 13, CREAM))
	var status := _label("SELECT HERO", 12, MUTED)
	status.custom_minimum_size.y = 16
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(status)
	_card_status.append(status)
	_card_buttons.append(card)
	# The entire card is a single mouse/touch/keyboard target.
	_ignore_mouse(padding)
	card.custom_minimum_size.y = 385
	return card


func _open_heroes() -> void:
	if not _departing:
		_show_page(Page.HEROES)


func _show_page(page: Page, animate: bool = true) -> void:
	if _departing:
		return
	current_page = page
	_home.visible = page == Page.HOME
	_heroes.visible = page == Page.HEROES
	_select_character(selected_character_id)
	var target: Control = _start_button if page == Page.HOME else _card_buttons[CharacterDB.ids().find(selected_character_id)]
	target.grab_focus()
	_footer_hint.text = "MOUSE / TOUCH   ·   ARROWS + ENTER" if page == Page.HOME else "ARROWS + ENTER TO SELECT   ·   TAB TO BEGIN   ·   ESC TO GO BACK"
	if _transition_tween:
		_transition_tween.kill()
	_home.modulate.a = 1.0
	_heroes.modulate.a = 1.0
	if animate and not GameSettings.reduce_motion():
		var content: Control = _home if page == Page.HOME else _heroes
		content.modulate.a = 0.35
		_transition_tween = create_tween()
		_transition_tween.tween_property(content, "modulate:a", 1.0, 0.18)


func _select_character(character_id: String) -> void:
	if _departing or not CharacterDB.ids().has(character_id):
		return
	selected_character_id = character_id
	for i in _card_buttons.size():
		var selected := str(CharacterDB.CHARACTERS[i].get("id", "")) == character_id
		_card_buttons[i].set_pressed_no_signal(selected)
		_card_status[i].text = "●  SELECTED" if selected else "SELECT HERO"
		_card_status[i].add_theme_color_override("font_color", GOLD if selected else MUTED)
	var character := CharacterDB.get_character(character_id)
	_hero_summary.text = "%s  /  %s" % [str(character.get("name", "")), str(character.get("weapon", ""))]


func _request_begin() -> void:
	if _departing or current_page != Page.HEROES or _overlay.visible:
		return
	if save_available:
		_open_overlay("Begin a new journey?", _begin_button)
		_overlay_body.add_child(_paragraph("Your saved journey", 13, GOLD))
		_overlay_body.add_child(_paragraph(_saved_journey_text(), 19, CREAM))
		_overlay_body.add_child(_paragraph("Starting as %s will replace this journey and its progress. You can go back and continue your saved adventure instead." % str(CharacterDB.get_character(selected_character_id).get("name", "Hero")), 17, MUTED))
		var replace := _button("Replace Save & Begin", _begin_journey, true, false)
		_overlay_actions.add_child(replace)
		_overlay_close.text = "Keep Saved Journey"
		_overlay_close.grab_focus()
	else:
		_begin_journey()


func _begin_journey() -> void:
	if _departing or current_page != Page.HEROES:
		return
	_departing = true
	_set_page_focus(false)
	mouse_filter = Control.MOUSE_FILTER_STOP
	character_selected.emit(selected_character_id)


func _request_continue() -> void:
	if _departing or not save_available or current_page != Page.HOME or _overlay.visible:
		return
	_departing = true
	_set_page_focus(false)
	continue_requested.emit()


func show_continue_error() -> void:
	_departing = false
	_set_page_focus(true)
	_error.text = "This journey could not be loaded. Try again or start a new journey."
	_error.show()
	_continue_button.grab_focus()


func _saved_journey_text() -> String:
	if GameState.data.is_empty():
		return "Saved journey  ·  Details unavailable"
	var character := CharacterDB.get_character(str(GameState.data.get("character_id", "adam")))
	var place := "Besut Village"
	if GameState.expedition_active():
		place = str(PortalDB.get_portal(GameState.expedition_portal()).get("name", "Expedition"))
	return "%s  ·  Level %d  ·  %s" % [str(character.get("name", "Hero")), int(GameState.data.get("level", 1)), place]


# ------------------------------------------------------------------ title overlays

func _build_overlay() -> void:
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.05, 0.07, 0.88)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(dim)
	_overlay_panel = _panel(Color("#132a34"), GOLD)
	_overlay_panel.set_anchors_preset(Control.PRESET_CENTER)
	_overlay.add_child(_overlay_panel)
	_overlay_column = VBoxContainer.new()
	_overlay_column.add_theme_constant_override("separation", 18)
	_overlay_panel.add_child(_overlay_column)
	_overlay_title = _label("", 30, CREAM)
	_overlay_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_overlay_column.add_child(_overlay_title)
	_overlay_column.add_child(GameUI.divider(BORDER))
	var scroll := _scroll()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_overlay_column.add_child(scroll)
	_overlay_body = VBoxContainer.new()
	_overlay_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_overlay_body.add_theme_constant_override("separation", 16)
	scroll.add_child(_overlay_body)
	_overlay_actions = HBoxContainer.new()
	_overlay_actions.add_theme_constant_override("separation", 12)
	_overlay_column.add_child(_overlay_actions)
	_overlay_close = _button("Back", _close_overlay, false, false)
	_overlay_actions.add_child(_overlay_close)
	_overlay.hide()


func _open_overlay(title: String, return_focus: Control = null) -> void:
	_overlay_focus = return_focus if return_focus != null else get_viewport().gui_get_focus_owner()
	_set_page_focus(false)
	for child in _overlay_body.get_children():
		_overlay_body.remove_child(child)
		child.queue_free()
	for child in _overlay_actions.get_children():
		if child != _overlay_close:
			_overlay_actions.remove_child(child)
			child.queue_free()
	_overlay_title.text = title
	_overlay_close.text = "← Back"
	_overlay.show()
	_overlay_close.grab_focus()


func _close_overlay() -> void:
	if _departing:
		return
	_overlay.hide()
	_set_page_focus(true)
	if is_instance_valid(_overlay_focus) and _overlay_focus.is_visible_in_tree():
		_overlay_focus.grab_focus()


func _open_settings() -> void:
	_open_overlay("Make yourself at home")
	_overlay_body.add_child(_paragraph("SETTINGS", 12, GOLD))
	var volume_row := VBoxContainer.new()
	var volume_text := _label("Master volume  ·  %d%%" % GameSettings.master_volume(), 17, CREAM)
	volume_row.add_child(volume_text)
	var volume := HSlider.new()
	volume.min_value = 0
	volume.max_value = 100
	volume.step = 5
	volume.value = GameSettings.master_volume()
	volume.custom_minimum_size.y = 36
	volume.value_changed.connect(func(value: float) -> void:
		volume_text.text = "Master volume  ·  %d%%" % int(value)
		GameSettings.set_master_volume(int(value), false))
	volume.drag_ended.connect(func(_changed: bool) -> void: GameSettings.save_settings())
	volume.focus_exited.connect(GameSettings.save_settings)
	volume_row.add_child(volume)
	_overlay_body.add_child(volume_row)
	var mute := CheckBox.new()
	mute.text = "Mute all audio"
	mute.button_pressed = GameSettings.mute_all()
	mute.toggled.connect(GameSettings.set_mute_all)
	_overlay_body.add_child(mute)
	var motion := CheckBox.new()
	motion.text = "Reduce motion"
	motion.button_pressed = GameSettings.reduce_motion()
	motion.toggled.connect(GameSettings.set_reduce_motion)
	_overlay_body.add_child(motion)
	var quality_row := HBoxContainer.new()
	var quality_label := _label("Effects quality", 17, CREAM)
	quality_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quality_row.add_child(quality_label)
	var quality := OptionButton.new()
	for option in ["Low", "Medium", "High"]:
		quality.add_item(option)
	quality.selected = GameSettings.EFFECT_QUALITIES.find(GameSettings.effects_quality())
	quality.custom_minimum_size = Vector2(160, 44)
	quality.item_selected.connect(func(index: int) -> void: GameSettings.set_effects_quality(str(GameSettings.EFFECT_QUALITIES[index])))
	quality_row.add_child(quality)
	_overlay_body.add_child(quality_row)
	_overlay_body.add_child(_paragraph("Saved on this device. More interface and camera options are available from the in-game menu.", 14, MUTED))


func _open_guide() -> void:
	_open_overlay("Life on the shore")
	for entry in [
		["01  /  MAKE YOURSELF AT HOME", "Follow the purple question mark for your first village tasks. Meet the residents, gather supplies and build your home."],
		["02  /  PREPARE FOR THE NIGHT", "Protect the forest and the people who live here. Visit the shops, train your companion and venture through the portals when you're ready."],
		["03  /  FIND YOUR FOOTING", "WASD / Arrows  ·  Move\nF  ·  Attack     1 / 2 / 3  ·  Skills (3s / 6s / 9s)\nE  ·  Interact     Menu  ·  Build\nTouch  ·  Left joystick to move; right-side actions to fight and interact."],
	]:
		_overlay_body.add_child(_paragraph(str(entry[0]), 13, GOLD))
		_overlay_body.add_child(_paragraph(str(entry[1]), 17, CREAM))
	_overlay_body.add_child(_paragraph("Your progress saves automatically. Use Continue Journey when you return.", 14, MUTED))


func _open_credits() -> void:
	_open_overlay("Made for a place called home")
	_overlay_body.add_child(_paragraph("PB (Protect BESUT)", 25, GOLD))
	_overlay_body.add_child(_paragraph("Created by Qayyim, Farhan & Ayiz", 22, CREAM))
	_overlay_body.add_child(_paragraph("A seaside survival action RPG set between a living forest and the waters of Besut, Terengganu.", 18, MUTED))
	_overlay_body.add_child(_paragraph("Build, explore and stand together for the village.", 18, CREAM))


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not _departing:
		if _overlay.visible:
			_close_overlay()
		elif current_page == Page.HEROES:
			_show_page(Page.HOME)
		get_viewport().set_input_as_handled()


func _on_settings_changed(_key: String) -> void:
	if GameSettings.reduce_motion() and _transition_tween:
		_transition_tween.kill()
		_home.modulate.a = 1.0
		_heroes.modulate.a = 1.0


func _set_page_focus(enabled: bool) -> void:
	for control in _page_buttons:
		control.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE


# ------------------------------------------------------------------ layout & widgets

func _layout() -> void:
	_compact = size.y < 650 or size.x < 1100
	var narrow := size.x < 800
	var margin := 24 if _compact else 44
	for side in ["left", "right"]:
		_margin.add_theme_constant_override("margin_" + side, margin)
	_margin.add_theme_constant_override("margin_top", 18 if _compact else 24)
	_margin.add_theme_constant_override("margin_bottom", 16 if _compact else 20)
	_home_title.add_theme_font_size_override("font_size", 56 if _compact else 76)
	_home_column.vertical = not (_compact and size.x >= 800)
	_home_column.add_theme_constant_override("separation", 24 if not _home_column.vertical else 16)
	_hero_intro.visible = not _compact
	_scenic_caption.visible = size.x >= 1150
	_scenic_caption.custom_minimum_size.x = maxf(0, size.x - 610)
	_home.get_child(0).custom_minimum_size.x = minf(460, size.x - margin * 2)
	_cards.vertical = narrow
	for portrait in _card_portraits:
		portrait.custom_minimum_size.y = 48 if _compact else 64
	for detail in _card_details:
		detail.visible = not _compact
	for hero_name in _card_names:
		hero_name.add_theme_font_size_override("font_size", 24 if _compact else 28)
	for card in _card_buttons:
		card.custom_minimum_size.y = 176 if _compact else 385
	_footer_hint.visible = size.x >= 1000
	_begin_button.custom_minimum_size.x = 180 if _compact else 238
	_begin_button.add_theme_font_size_override("font_size", 15 if _compact else 18)
	var fitted := Vector2(620, 530).min(size - Vector2(40, 40))
	_overlay_panel.offset_left = -fitted.x * 0.5
	_overlay_panel.offset_right = fitted.x * 0.5
	_overlay_panel.offset_top = -fitted.y * 0.5
	_overlay_panel.offset_bottom = fitted.y * 0.5


func _button(text: String, action: Callable, primary: bool = false, page_control: bool = true) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 54)
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", INK if primary else CREAM)
	button.add_theme_color_override("font_hover_color", INK if primary else Color.WHITE)
	button.add_theme_color_override("font_focus_color", INK if primary else CREAM)
	button.add_theme_color_override("font_pressed_color", INK if primary else CREAM)
	button.add_theme_color_override("font_disabled_color", Color("#6e8386"))
	button.add_theme_stylebox_override("normal", _style(GOLD if primary else Color(0.06, 0.13, 0.17, 0.94), GOLD if primary else BORDER))
	button.add_theme_stylebox_override("hover", _style(GOLD.lightened(0.16) if primary else Color("#233e48"), CREAM if primary else GOLD))
	button.add_theme_stylebox_override("pressed", _style(GOLD.darkened(0.1) if primary else Color("#28444c"), GOLD, 2))
	button.add_theme_stylebox_override("disabled", _style(Color(0.06, 0.13, 0.17, 0.65), Color("#30444a")))
	var focus := _style(Color.TRANSPARENT, CREAM, 2)
	focus.set_expand_margin_all(3)
	button.add_theme_stylebox_override("focus", focus)
	button.pressed.connect(action)
	button.pressed.connect(func() -> void: Sfx.play("select", -15))
	if page_control:
		_page_buttons.append(button)
	return button


func _style(fill: Color, border: Color, width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(3)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


func _panel(fill: Color, border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(fill, border))
	return panel


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := GameUI.label(text, font_size, color)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)
	return label


func _paragraph(text: String, font_size: int, color: Color) -> Label:
	var label := _label(text, font_size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _scroll() -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	# The shared in-game theme gives scrollbars panel-sized content margins.
	# A title rail stays unobtrusive and must not affect content wrapping.
	var bar := scroll.get_v_scroll_bar()
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.04, 0.09, 0.12, 0.4)
	track.content_margin_left = 3
	track.content_margin_right = 3
	bar.add_theme_stylebox_override("scroll", track)
	for state in ["grabber", "grabber_highlight", "grabber_pressed"]:
		var grabber := StyleBoxFlat.new()
		grabber.bg_color = BORDER if state == "grabber" else GOLD
		grabber.content_margin_left = 3
		grabber.content_margin_right = 3
		bar.add_theme_stylebox_override(state, grabber)
	return scroll


func _ignore_mouse(control: Control) -> void:
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in control.get_children():
		if child is Control:
			_ignore_mouse(child)
