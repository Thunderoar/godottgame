class_name TitleScreen
extends Control
## Boot menu -> deliberate hero selection -> one guarded journey handoff.
## Both pages ride one clipped horizontal track: the menu leaves to the left
## while the road arrives from the right. State changes are immediate; only
## the pixels travel. Browsing never writes player data.

signal character_selected(character_id: String)
signal continue_requested

enum Page { HOME, HEROES }
const PAGE_SLIDE_SECONDS := 0.36
const PAGE_SLIDE_MIN_SECONDS := 0.12
const TITLE_FONT_PATH := "res://assets/fonts/title/NotoSerif-Bold.ttf"
static var TITLE_FONT: Font
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
var _home_wordmark: Label
var _home_scroll: ScrollContainer
var _home_nav: PanelContainer
var _home_utilities: HBoxContainer
var _save_card: HBoxContainer
var _scenic_caption: VBoxContainer
var _heroes: VBoxContainer
var _cards: BoxContainer
var _card_buttons: Array[Button] = []
var _card_portraits: Array[TextureRect] = []
var _card_status: Array[Label] = []
var _card_locks: Array[TextureRect] = []
var _card_unlock_text: Array[Label] = []
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
var _body: Control
var _slide_tween: Tween
var _page_p := 0.0
var _page_input_defaults: Dictionary = {}
var _fit_pending := false
var _compact := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = GameUI.theme()
	# Load only when a menu is created, after imports; fresh editor boot must
	# not preload an as-yet-unimported font through the autoload dependency graph.
	if TITLE_FONT == null:
		TITLE_FONT = load(TITLE_FONT_PATH) as Font
	var backdrop := TitleBackdrop.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	_build()
	_build_overlay()
	resized.connect(_layout)
	GameSettings.changed.connect(_on_settings_changed)
	GameState.data_changed.connect(_refresh_hero_locks)
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
	var location := _label("BESUT  /  TERENGGANU", 11, GOLD)
	location.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	location.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.add_child(location)
	if not OS.has_feature("web") and not OS.has_feature("mobile"):
		var quit := _button("Quit", func() -> void: get_tree().quit())
		quit.custom_minimum_size = Vector2(64, 34)
		quit.add_theme_font_size_override("font_size", 13)
		header.add_child(quit)
	shell.add_child(header)
	_body = Control.new()
	_body.name = "PageStage"
	# The two pages share one horizontal track; the stage is the window they
	# travel across. Drawing clips to it; input is gated while they move.
	_body.clip_contents = true
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.resized.connect(_on_page_stage_resized)
	shell.add_child(_body)
	_build_home(_body)
	_build_heroes(_body)
	_capture_page_inputs()
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
	_home.add_theme_constant_override("separation", 56)
	parent.add_child(_home)
	_home_scroll = _scroll()
	_home_scroll.name = "HomeNavigationScroll"
	_home_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_home.add_child(_home_scroll)
	_home_column = BoxContainer.new()
	_home_column.vertical = true
	_home_column.alignment = BoxContainer.ALIGNMENT_CENTER
	_home_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_home_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_home_column.add_theme_constant_override("separation", 28)
	_home_scroll.add_child(_home_column)
	_home_intro = VBoxContainer.new()
	_home_intro.alignment = BoxContainer.ALIGNMENT_CENTER
	_home_intro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_home_intro.add_theme_constant_override("separation", -2)
	_home_column.add_child(_home_intro)
	_home_wordmark = _label("P R O T E C T", 22, GOLD)
	_home_intro.add_child(_home_wordmark)
	_home_title = _label("BESUT", 108, CREAM)
	_home_title.add_theme_font_override("font", TITLE_FONT)
	_home_title.add_theme_color_override("font_shadow_color", Color(0.015, 0.035, 0.04, 0.6))
	_home_title.add_theme_constant_override("shadow_offset_y", 5)
	_home_intro.add_child(_home_title)
	var signature := HBoxContainer.new()
	signature.add_theme_constant_override("separation", 12)
	for i in 3:
		if i == 1:
			signature.add_child(_label("◇", 16, GOLD))
		else:
			var rule := ColorRect.new()
			rule.color = Color(0.78, 0.65, 0.43, 0.45)
			rule.custom_minimum_size = Vector2(48, 1)
			rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			signature.add_child(rule)
	signature.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_home_intro.add_child(signature)
	_home_nav = PanelContainer.new()
	_home_nav.name = "HarbourNavigation"
	_home_nav.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_home_nav.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rail := _style(Color(0.025, 0.075, 0.09, 0.86), Color(0.48, 0.65, 0.61, 0.3))
	rail.set_corner_radius_all(10)
	rail.content_margin_left = 20
	rail.content_margin_right = 20
	rail.content_margin_top = 20
	rail.content_margin_bottom = 18
	_home_nav.add_theme_stylebox_override("panel", rail)
	_home_column.add_child(_home_nav)
	_home_actions = VBoxContainer.new()
	_home_actions.add_theme_constant_override("separation", 10)
	_home_nav.add_child(_home_actions)
	_start_button = _button("Start Game   →", _open_heroes, not save_available)
	_start_button.name = "StartGame"
	_style_home_action(_start_button, not save_available)
	_home_actions.add_child(_start_button)
	_continue_button = _button("Continue Journey   →", _request_continue, save_available)
	_continue_button.name = "ContinueJourney"
	_continue_button.disabled = not save_available
	_style_home_action(_continue_button, save_available)
	_home_actions.add_child(_continue_button)
	if save_available:
		_home_actions.move_child(_continue_button, 0)
	_save_card = HBoxContainer.new()
	_save_card.name = "SavedJourneyDetails"
	_save_card.visible = save_available
	_save_card.add_theme_constant_override("separation", 12)
	_home_actions.add_child(_save_card)
	var portrait := TextureRect.new()
	portrait.texture = PixelArt.portrait(str(GameState.data.get("character_id", "adam")), 96)
	portrait.custom_minimum_size = Vector2(42, 42)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_save_card.add_child(portrait)
	_save_summary = _paragraph(_saved_journey_text() if save_available else "", 13, MUTED)
	_save_summary.visible = save_available
	_save_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_save_summary.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_save_card.add_child(_save_summary)
	_error = _paragraph("", 14, Color("#ffb2a0"))
	_error.visible = false
	_home_actions.add_child(_error)
	_home_actions.add_child(GameUI.divider(Color(0.48, 0.65, 0.61, 0.22)))
	_home_utilities = HBoxContainer.new()
	_home_utilities.alignment = BoxContainer.ALIGNMENT_CENTER
	_home_utilities.add_theme_constant_override("separation", 6)
	_home_actions.add_child(_home_utilities)
	for entry in [["How to Play", _open_guide], ["Settings", _open_settings], ["Credits", _open_credits]]:
		var button := _button(str(entry[0]), entry[1])
		button.custom_minimum_size = Vector2(0, 42)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 13)
		var quiet := _style(Color.TRANSPARENT, Color.TRANSPARENT, 0)
		quiet.content_margin_left = 7
		quiet.content_margin_right = 7
		button.add_theme_stylebox_override("normal", quiet)
		var hover := quiet.duplicate() as StyleBoxFlat
		hover.bg_color = Color(0.45, 0.67, 0.61, 0.12)
		button.add_theme_stylebox_override("hover", hover)
		_home_utilities.add_child(button)
	# An empty scenic region preserves composition without bringing back copy.
	_scenic_caption = VBoxContainer.new()
	_scenic_caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_home.add_child(_scenic_caption)


func _style_home_action(button: Button, primary: bool) -> void:
	button.custom_minimum_size.y = 58 if primary else 48
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 17)
	var normal := _style(GOLD if primary else Color(0.12, 0.23, 0.25, 0.48), GOLD if primary else Color("#365351"))
	normal.set_corner_radius_all(5)
	normal.content_margin_left = 22
	button.add_theme_stylebox_override("normal", normal)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.09, 0.16, 0.18, 0.36)
	disabled.border_color = Color(0.28, 0.40, 0.40, 0.32)
	button.add_theme_stylebox_override("disabled", disabled)


func _build_heroes(parent: Control) -> void:
	_heroes = VBoxContainer.new()
	_heroes.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_heroes.add_theme_constant_override("separation", 12)
	parent.add_child(_heroes)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 20)
	# The focus ring expands past the button; leave it room inside the clip.
	var ring_room := Control.new()
	ring_room.custom_minimum_size = Vector2(4, 0)
	heading.add_child(ring_room)
	_back_button = _button("← Back", func() -> void: _show_page(Page.HOME))
	_back_button.custom_minimum_size = Vector2(110, 44)
	heading.add_child(_back_button)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_child(_label("CHOOSE YOUR ROAD", 32, CREAM))
	_hero_intro = _paragraph("Three friends, separated by a sea monster. Your campaign begins as Adam.", 15, MUTED)
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
	# Keep the campaign line readable beside the Begin action when space is tight.
	info.custom_minimum_size.x = 240
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
	var lock_picture := TextureRect.new()
	lock_picture.texture = PixelArt.icon("lock")
	lock_picture.set_anchors_preset(Control.PRESET_CENTER)
	lock_picture.offset_left = -22
	lock_picture.offset_top = -22
	lock_picture.offset_right = 22
	lock_picture.offset_bottom = 22
	lock_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lock_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	lock_picture.modulate = GOLD
	portrait.add_child(lock_picture)
	_card_locks.append(lock_picture)
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
	var unlock_text := _paragraph(_unlock_requirement(id), 14, MUTED)
	unlock_text.custom_minimum_size.y = 50
	box.add_child(unlock_text)
	_card_unlock_text.append(unlock_text)
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
	if _slide_tween:
		_slide_tween.kill()
		_slide_tween = null
	current_page = page
	# State changes this frame; only the pixels travel. Both pages stay visible
	# for the journey and the arrival frame retires the old one.
	_home.visible = true
	_heroes.visible = true
	_schedule_page_fit()
	if not _hero_available(selected_character_id): selected_character_id = "adam"
	_select_character(selected_character_id)
	_footer_hint.text = "MOUSE / TOUCH   ·   ARROWS + ENTER" if page == Page.HOME else "ARROWS + ENTER TO SELECT   ·   TAB TO BEGIN   ·   ESC TO GO BACK"
	var target := 1.0 if page == Page.HEROES else 0.0
	if not animate or GameSettings.reduce_motion():
		_settle_pages()
		return
	var span := absf(target - _page_p)
	if span < 0.001:
		_settle_pages()
		return
	_set_pages_inert()
	_apply_page_progress(_page_p)
	var slide := create_tween()
	_slide_tween = slide
	slide.tween_method(_apply_page_progress, _page_p, target, maxf(PAGE_SLIDE_MIN_SECONDS, PAGE_SLIDE_SECONDS * span)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	slide.finished.connect(_on_page_slide_finished.bind(slide, page), CONNECT_ONE_SHOT)


func _apply_page_progress(progress: float) -> void:
	_page_p = clampf(progress, 0.0, 1.0)
	var width := _body.size.x
	if width <= 0.0:
		return
	# Adjacent pages always tile the stage exactly: no seam mid-slide.
	_home.position = Vector2(-width * _page_p, 0.0)
	_heroes.position = Vector2(width * (1.0 - _page_p), 0.0)


func _settle_pages() -> void:
	_apply_page_progress(1.0 if current_page == Page.HEROES else 0.0)
	_home.visible = current_page == Page.HOME
	_heroes.visible = current_page == Page.HEROES
	_schedule_page_fit()
	_set_page_inert(_heroes if current_page == Page.HOME else _home)
	_restore_page_input(_home if current_page == Page.HOME else _heroes)
	if _departing or _overlay.visible:
		return
	_set_page_focus(true)
	_focus_page(current_page)


func _focus_page(page: Page) -> void:
	var target: Control = _continue_button if save_available else _start_button
	if page == Page.HEROES:
		var index := CharacterDB.ids().find(selected_character_id)
		if index >= 0 and index < _card_buttons.size():
			target = _card_buttons[index]
	if is_instance_valid(target) and target.is_visible_in_tree():
		target.grab_focus()


func _on_page_slide_finished(slide: Tween, page: Page) -> void:
	if slide != _slide_tween:
		return
	_slide_tween = null
	if _departing or current_page != page:
		return
	_settle_pages()


func _on_page_stage_resized() -> void:
	# Re-derive travel from the stored progress so a resize never strands a
	# page half off-screen or opens a gap between them.
	_apply_page_progress(_page_p)
	_schedule_page_fit()


func _fit_pages_to_stage() -> void:
	_fit_pending = false
	# A page hidden while its autowrap labels have no width can clamp to a
	# minimum thousands of pixels tall. Once it has been laid out at the real
	# width, re-anchor it so the stage owns the size again.
	for page in [_home, _heroes]:
		page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_apply_page_progress(_page_p)


func _schedule_page_fit() -> void:
	if _fit_pending or not is_inside_tree():
		return
	_fit_pending = true
	await get_tree().process_frame
	if not is_inside_tree():
		return
	_fit_pages_to_stage()


func is_sliding() -> bool:
	return _slide_tween != null and _slide_tween.is_running()


func _capture_page_inputs() -> void:
	_page_input_defaults.clear()
	for root in [_home, _heroes]:
		_capture_input_filters(root)


func _capture_input_filters(node: Node) -> void:
	if node is Control:
		_page_input_defaults[node] = (node as Control).mouse_filter
	for child in node.get_children():
		_capture_input_filters(child)


func _set_pages_inert() -> void:
	_set_page_inert(_home)
	_set_page_inert(_heroes)
	_set_page_focus(false)


func _set_page_inert(root: Control) -> void:
	for key in _page_input_defaults:
		var node := key as Control
		if not is_instance_valid(node):
			continue
		if node == root or root.is_ancestor_of(node):
			node.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _restore_page_input(root: Control) -> void:
	for key in _page_input_defaults:
		var node := key as Control
		if not is_instance_valid(node):
			continue
		if node == root or root.is_ancestor_of(node):
			node.mouse_filter = int(_page_input_defaults[key])


func _select_character(character_id: String) -> void:
	if _departing or not CharacterDB.ids().has(character_id): return
	if not _hero_available(character_id):
		_refresh_hero_locks()
		_show_unlock_requirement(character_id)
		return
	selected_character_id = character_id
	_refresh_hero_locks()
	_hero_summary.text = "Adam · Sword · Rescue Arjun at sea and Mei Ling in the final portal"

func _hero_available(id: String) -> bool:
	return id == "adam" or bool(GameState.campaign().get(id + "_rescued", false))

func _unlock_requirement(id: String) -> String:
	match id:
		"arjun": return "Complete all 3 sea routes. Defeat the Kraken King, then open Arjun's prison to rescue him."
		"mei_ling": return "Defeat %s in %s, the final Monster Portal, to rescue Mei Ling." % [PortalDB.get_portal("drowned_throne").get("boss_name","Abyss Monarch"),PortalDB.get_portal("drowned_throne").get("name","Abyssal Throne")]
	return "Available from the start. Begin Adam's story and find your missing friends."

func _refresh_hero_locks() -> void:
	if _card_buttons.is_empty(): return
	if not _hero_available(selected_character_id): selected_character_id = "adam"
	for i in _card_buttons.size():
		var id := str(CharacterDB.CHARACTERS[i].get("id", ""))
		var locked := not _hero_available(id)
		var selected := id == selected_character_id and not locked
		_card_buttons[i].set_pressed_no_signal(selected)
		_card_locks[i].visible = locked
		_card_portraits[i].self_modulate = Color(0.28, 0.32, 0.36) if locked else Color.WHITE
		_card_status[i].text = "LOCKED" if locked else ("ADAM · STORY HERO" if id == "adam" else "RESCUED · VILLAGE DEFENDER")
		_card_status[i].add_theme_color_override("font_color", Color("#e1a58b") if locked else GOLD)
		_card_unlock_text[i].text = _unlock_requirement(id) if locked or id == "adam" else ("Rescued! Arjun guards BESUT with his scythe." if id == "arjun" else "Rescued! Mei Ling guards BESUT with her bow.")

func _show_unlock_requirement(id: String) -> void:
	var index := CharacterDB.ids().find(id)
	_open_overlay(str(CharacterDB.get_character(id).get("name", "Friend")) + " · LOCKED", _card_buttons[index])
	var portrait := TextureRect.new()
	portrait.texture = PixelArt.portrait(id, 96)
	portrait.custom_minimum_size = Vector2(0, 130)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.modulate = Color(0.5, 0.55, 0.6)
	_overlay_body.add_child(portrait)
	_overlay_body.add_child(_paragraph(_unlock_requirement(id), 20, CREAM))
	_overlay_body.add_child(_paragraph("After the rescue, your friend returns to BESUT and helps defend the village.", 16, MUTED))
	_overlay_close.text = "Back"
	_overlay_close.grab_focus()

func _request_begin() -> void:
	if _departing or current_page != Page.HEROES or _overlay.visible:
		return
	if save_available:
		_open_overlay("Begin a new journey?", _begin_button)
		_overlay_body.add_child(_paragraph("Your saved journey", 13, GOLD))
		_overlay_body.add_child(_paragraph(_saved_journey_text(), 19, CREAM))
		_overlay_body.add_child(_paragraph("Starting Adam's story will replace this journey and its progress. You can go back and continue your saved adventure instead.", 17, MUTED))
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
	if _slide_tween:
		_slide_tween.kill()
		_slide_tween = null
		_settle_pages()
	_set_page_focus(false)
	mouse_filter = Control.MOUSE_FILTER_STOP
	character_selected.emit("adam")


func _request_continue() -> void:
	if _departing or not save_available or current_page != Page.HOME or _overlay.visible:
		return
	_departing = true
	if _slide_tween:
		_slide_tween.kill()
		_slide_tween = null
		_settle_pages()
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
	_overlay_body.add_child(VisualStyleSettings.new())
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
		["03  /  FIND YOUR FOOTING", "WASD / Arrows  ·  Move\nF  ·  Attack     Shift  ·  Sprint\nE  ·  Interact     B  ·  Build     I / Tab  ·  Pack\nTouch  ·  Joystick to move. Attack and Sprint on the right. Tap nearby people and objects to interact."],
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
	if GameSettings.reduce_motion() and is_sliding():
		_slide_tween.kill()
		_slide_tween = null
		_settle_pages()


func _set_page_focus(enabled: bool) -> void:
	for control in _page_buttons:
		control.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE


# ------------------------------------------------------------------ layout & widgets

func _layout() -> void:
	_compact = size.y < 650 or size.x < 1100
	var narrow := size.x < 800
	var margin := 24 if _compact else 64
	for side in ["left", "right"]:
		_margin.add_theme_constant_override("margin_" + side, margin)
	_margin.add_theme_constant_override("margin_top", 18 if _compact else 24)
	_margin.add_theme_constant_override("margin_bottom", 16 if _compact else 20)
	var landscape_compact := _compact and not narrow
	_home_column.vertical = not landscape_compact
	_home_column.add_theme_constant_override("separation", 32 if landscape_compact else 24)
	_home_scroll.custom_minimum_size.x = size.x - margin * 2 if _compact else 424
	_home_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL if _compact else Control.SIZE_FILL
	_home_intro.custom_minimum_size.x = 290 if landscape_compact else 0
	_home_nav.custom_minimum_size.x = 300 if landscape_compact else (minf(360, size.x - margin * 2) if narrow else 0)
	_home_title.add_theme_font_size_override("font_size", 88 if landscape_compact else (92 if size.x < 500 else 108))
	_home_wordmark.add_theme_font_size_override("font_size", 18 if landscape_compact else 22)
	_home_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if narrow else HORIZONTAL_ALIGNMENT_LEFT
	_home_wordmark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if narrow else HORIZONTAL_ALIGNMENT_LEFT
	_home_intro.get_child(2).alignment = BoxContainer.ALIGNMENT_CENTER if narrow else BoxContainer.ALIGNMENT_BEGIN
	_home_nav.size_flags_horizontal = Control.SIZE_SHRINK_CENTER if narrow else Control.SIZE_EXPAND_FILL
	_hero_intro.visible = not _compact
	_scenic_caption.visible = not _compact
	_scenic_caption.custom_minimum_size.x = 0
	_cards.vertical = narrow
	for portrait in _card_portraits:
		portrait.custom_minimum_size.y = 48 if _compact else 64
	for detail in _card_details:
		detail.visible = not _compact
	for unlock_text in _card_unlock_text:
		# The rescue route stays in the lock overlay; the compact card keeps
		# only portrait, name, weapon, vitals and lock state.
		unlock_text.visible = not _compact
	for hero_name in _card_names:
		hero_name.add_theme_font_size_override("font_size", 24 if _compact else 28)
	# The campaign line must stay one line on compact width; a second wrapped
	# line steals the height the three cards need.
	_hero_summary.add_theme_font_size_override("font_size", 15 if _compact else 18)
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
