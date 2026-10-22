class_name ItemCard
extends PanelContainer
## One stock card in a shop grid: icon, name, stat line, price chip and a clear
## action state (Buy / Equip / Equipped / Owned xN / can't afford / pack full).
## Cards refresh in place on data changes so the shop never loses scroll.


signal action_pressed(card: ItemCard)
signal selected(card: ItemCard)

var item_id := ""
var icon_kind := "spark"

var _icon: TextureRect
var _name_label: Label
var _stat_label: Label
var _price_label: Label
var _price_icon: TextureRect
var _action_button: Button
var _state_label: Label
var _card: PanelContainer


func setup(for_item: String, kind: String) -> void:
	item_id = for_item
	icon_kind = kind
	_build()
	refresh()


func _build() -> void:
	var variant := "iron" if ItemDB.is_equipment(item_id) else "parchment"
	_card = self
	add_theme_stylebox_override("panel", GameUI.frame_style(variant, 7))
	mouse_filter = Control.MOUSE_FILTER_PASS
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	add_child(hbox)
	_icon = TextureRect.new()
	_icon.texture = PixelArt.icon(icon_kind, 32)
	_icon.custom_minimum_size = Vector2(40, 40)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(_icon)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 1)
	hbox.add_child(info)
	_name_label = GameUI.label("", 16, GameUI.TEXT)
	info.add_child(_name_label)
	_stat_label = GameUI.label("", 12, GameUI.GREEN)
	info.add_child(_stat_label)
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(128, 0)
	right.add_theme_constant_override("separation", 4)
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(right)
	var price_row := HBoxContainer.new()
	price_row.add_theme_constant_override("separation", 5)
	right.add_child(price_row)
	_price_icon = TextureRect.new()
	_price_icon.texture = PixelArt.icon("gold", 32)
	_price_icon.custom_minimum_size = Vector2(17, 17)
	_price_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_price_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_price_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_price_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	price_row.add_child(_price_icon)
	_price_label = GameUI.label("", 15, GameUI.GOLD)
	_price_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	price_row.add_child(_price_label)
	_action_button = GameUI.button("Buy", Vector2(122, 36))
	_action_button.pressed.connect(func() -> void:
		action_pressed.emit(self)
		_press_squash())
	right.add_child(_action_button)
	_state_label = GameUI.label("", 12, GameUI.MUTED)
	_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right.add_child(_state_label)
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selected.emit(self)


func _on_hover(over: bool) -> void:
	# Subtle lift on hover / focus.
	if GameSettings.reduce_motion():
		return
	var target := Vector2(1.015, 1.015) if over else Vector2.ONE
	create_tween().tween_property(self, "scale", target, 0.12).set_trans(Tween.TRANS_SINE)


func _press_squash() -> void:
	if GameSettings.reduce_motion():
		return
	var tween := create_tween()
	tween.tween_property(_action_button, "scale", Vector2(0.94, 0.9), 0.06)
	tween.tween_property(_action_button, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func refresh() -> void:
	# Updates every mutable value in place. Called on open and on data_changed.
	var item := ItemDB.get_item(item_id)
	_name_label.text = str(item.get("name", item_id))
	_stat_label.text = ItemDB.stat_line(item_id)
	var price := int(item.get("price", 0))
	if price > 0:
		_price_label.text = "%d" % price
		_price_icon.texture = PixelArt.icon("gold", 32)
		_price_icon.visible = true
	else:
		_price_label.text = "Starter"
		_price_icon.visible = false
	var afford := price <= GameState.gold()
	if ItemDB.is_equipment(item_id):
		var slot := str(item.get("slot", ""))
		var equipped := GameState.equipped_item(slot) == item_id
		if GameState.item_count(item_id) <= 0:
			_action_button.visible = true
			_action_button.text = "Buy"
			_action_button.disabled = not afford
			_state_label.text = ""
		elif equipped:
			_action_button.visible = false
			_state_label.text = "Equipped"
			_state_label.add_theme_color_override("font_color", GameUI.TEAL)
		else:
			_action_button.visible = true
			_action_button.text = "Equip"
			_action_button.disabled = false
			_state_label.text = ""
	else:
		_action_button.visible = true
		_action_button.text = "Buy"
		var pack_full := not GameState.can_add_item(item_id)
		_action_button.disabled = not afford or pack_full
		var count := GameState.item_count(item_id)
		if pack_full:
			_state_label.text = "Pack full"
			_state_label.add_theme_color_override("font_color", GameUI.RED)
		elif count > 0:
			_state_label.text = "Owned x%d" % count
			_state_label.add_theme_color_override("font_color", GameUI.MUTED)
		else:
			_state_label.text = ""
	if not afford and GameState.item_count(item_id) <= 0:
		_price_label.add_theme_color_override("font_color", GameUI.RED)
	else:
		_price_label.add_theme_color_override("font_color", GameUI.GOLD)


func mark_selected(selected_now: bool) -> void:
	# Focus highlight for the detail pane link.
	var style := GameUI.frame_style("iron" if ItemDB.is_equipment(item_id) else "parchment", 7)
	if selected_now:
		style.border_color = GameUI.GOLD
		style.border_color = style.border_color.lightened(0.2)
	add_theme_stylebox_override("panel", style)


func pop() -> void:
	# Purchase feedback: a quick card pop.
	if GameSettings.reduce_motion():
		return
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.06, 1.06), 0.08).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func flash_error() -> void:
	# Failed purchase: shake + red border flash.
	var style := GameUI.frame_style("iron" if ItemDB.is_equipment(item_id) else "parchment", 7)
	style.border_color = GameUI.RED
	add_theme_stylebox_override("panel", style)
	if not GameSettings.reduce_motion():
		var tween := create_tween()
		var base := position
		tween.tween_property(self, "position", base + Vector2(5, 0), 0.05)
		tween.tween_property(self, "position", base - Vector2(5, 0), 0.05)
		tween.tween_property(self, "position", base + Vector2(3, 0), 0.05)
		tween.tween_property(self, "position", base, 0.05)
	await get_tree().create_timer(0.7).timeout
	if is_instance_valid(self):
		refresh()
