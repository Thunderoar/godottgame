class_name ShopScene
extends VBoxContainer
## The illustrated "storefront band" at the top of every shop panel: a
## procedural interior, an animated shopkeeper bust (blinks, breathes, works a
## prop), a speech line that reacts to what the player does, and one or two
## browsing background silhouettes so the shop feels staffed and visited.
##
## Budget: <= 6 animated nodes per shop (breathe tween, blink timer, prop tween,
## lantern sway, steam loop, browser drift). Low effects quality drops the
## browsers and steam.


signal keeper_spoke(text: String)

var shop_type := "potion"
var keeper_name := "Mara"

var _bust: TextureRect
var _speech: Label
var _speech_panel: PanelContainer
var _emote: TextureRect
var _steam: Array[TextureRect] = []
var _browsers: Array[TextureRect] = []
var _prop: TextureRect
var _blink_timer := 0.0
var _blink := false
var _speak_tween: Tween


func setup(kind: String, keeper: String) -> void:
	shop_type = kind
	keeper_name = keeper
	_build()


func _build() -> void:
	custom_minimum_size = Vector2(0, 178)
	add_theme_constant_override("separation", 4)

	var band := GameUI.framed_panel("wood", 10)
	band.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	band.custom_minimum_size = Vector2(0, 150)
	add_child(band)

	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_child(holder)

	var interior := TextureRect.new()
	interior.texture = PixelArt.shop_interior_texture(shop_type)
	interior.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	interior.stretch_mode = TextureRect.STRETCH_SCALE
	interior.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	interior.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	interior.modulate = Color(0.92, 0.95, 0.92)
	holder.add_child(interior)

	# Keeper bust with breathing.
	var bust_box := VBoxContainer.new()
	bust_box.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	bust_box.offset_left = 26
	bust_box.offset_top = -66
	bust_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(bust_box)
	_bust = TextureRect.new()
	_bust.texture = PixelArt.shopkeeper_bust(shop_type)
	_bust.custom_minimum_size = Vector2(72, 88)
	_bust.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bust.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_bust.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_bust.pivot_offset = Vector2(36, 84)
	bust_box.add_child(_bust)
	var name_label := GameUI.label(keeper_name, 13, GameUI.GOLD)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bust_box.add_child(name_label)
	if not GameSettings.reduce_motion():
		var breathe := create_tween().set_loops()
		breathe.tween_property(_bust, "scale", Vector2(1.0, 1.025), 1.6).set_trans(Tween.TRANS_SINE)
		breathe.tween_property(_bust, "scale", Vector2(1.0, 1.0), 1.6).set_trans(Tween.TRANS_SINE)

	# Keeper prop: a small animated item near the bust.
	_prop = TextureRect.new()
	_prop.texture = PixelArt.icon(_prop_icon(), 16)
	_prop.custom_minimum_size = Vector2(20, 20)
	_prop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_prop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_prop.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_prop.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	_prop.offset_left = 108
	_prop.offset_top = -14
	_prop.pivot_offset = Vector2(10, 10)
	holder.add_child(_prop)
	if not GameSettings.reduce_motion():
		var work := create_tween().set_loops()
		work.tween_property(_prop, "rotation", 0.5, 0.5).set_trans(Tween.TRANS_SINE)
		work.tween_property(_prop, "rotation", -0.35, 0.5).set_trans(Tween.TRANS_SINE)

	# Browsing background silhouettes ("ad org bagai" - it should feel staffed).
	if GameSettings.effects_at_least("med") and not GameSettings.reduce_motion():
		var roles := ["resident", "fisher", "gardener", "trader"]
		for i in (2 if shop_type != "house" else 1):
			var browser := TextureRect.new()
			browser.texture = PixelArt.npc_texture(roles[(shop_type.hash() + i) % roles.size()])
			browser.custom_minimum_size = Vector2(48, 72)
			browser.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			browser.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			browser.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			browser.modulate = Color(0.42, 0.46, 0.5, 0.8)
			browser.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
			browser.offset_left = -160 - i * 70
			browser.offset_top = -40 + i * 12
			holder.add_child(browser)
			_browsers.append(browser)
			var drift := create_tween().set_loops()
			drift.tween_property(browser, "position:x", 10.0, 2.4 + float(i))
			drift.tween_property(browser, "position:x", -10.0, 2.4 + float(i))

	# Steam / forge sparks over the prop area (kept as two soft puffs).
	if GameSettings.effects_at_least("med") and not GameSettings.reduce_motion():
		for i in 2:
			var puff := TextureRect.new()
			puff.texture = PixelArt.light_texture()
			puff.custom_minimum_size = Vector2(18, 18)
			puff.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			puff.stretch_mode = TextureRect.STRETCH_SCALE
			puff.modulate = Color(0.85, 0.9, 0.9, 0.28)
			puff.set_anchors_preset(Control.PRESET_CENTER_LEFT)
			puff.offset_left = 104 + i * 8
			puff.offset_top = -34
			holder.add_child(puff)
			_steam.append(puff)
			var rise := create_tween().set_loops()
			rise.tween_property(puff, "position:y", -12.0, 1.4 + float(i) * 0.4)
			rise.parallel().tween_property(puff, "modulate:a", 0.02, 1.4 + float(i) * 0.4)
			rise.tween_callback(func() -> void:
				puff.position = Vector2(puff.position.x, 0.0)
				puff.modulate.a = 0.3)

	# Speech panel with the current line + emote icon.
	var speech_row := HBoxContainer.new()
	speech_row.add_theme_constant_override("separation", 8)
	add_child(speech_row)
	_speech_panel = GameUI.framed_panel("parchment", 8)
	_speech_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	speech_row.add_child(_speech_panel)
	_speech = GameUI.label("", 15, GameUI.TEXT)
	_speech.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_speech.custom_minimum_size = Vector2(0, 20)
	_speech_panel.add_child(_speech)
	_emote = TextureRect.new()
	_emote.texture = PixelArt.icon("heart", 32)
	_emote.custom_minimum_size = Vector2(30, 30)
	_emote.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_emote.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_emote.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_emote.visible = false
	speech_row.add_child(_emote)
	set_process(true)


func _process(delta: float) -> void:
	_blink_timer -= delta
	if _blink_timer <= 0.0:
		_blink = not _blink
		_blink_timer = 2.6 if not _blink else 0.14
		_bust.texture = PixelArt.shopkeeper_bust(shop_type, _blink)


func _prop_icon() -> String:
	match shop_type:
		"equipment":
			return "hammer"
		"pet":
			return "pet"
		"house":
			return "build"
	return "health_potion"


func keeper_say(text: String, emote := "") -> void:
	# Keeper reaction: new speech line + a small emote pop (heart / ? / !).
	if _speech != null:
		_speech.text = "%s: \u201c%s\u201d" % [keeper_name, text]
	if _speak_tween != null and _speak_tween.is_valid():
		_speak_tween.kill()
	_speech_panel.modulate = Color(1.12, 1.08, 0.95)
	_speak_tween = create_tween()
	_speak_tween.tween_property(_speech_panel, "modulate", Color.WHITE, 0.45)
	if emote != "" and _emote != null:
		_emote.texture = PixelArt.icon(emote, 32)
		_emote.visible = true
		_emote.scale = Vector2(1.6, 1.6)
		if not GameSettings.reduce_motion():
			var pop := create_tween().set_parallel(true)
			pop.tween_property(_emote, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			pop.tween_property(_emote, "modulate:a", 0.0, 1.1)
			pop.chain().tween_callback(func() -> void:
				_emote.visible = false
				_emote.modulate.a = 1.0)
		else:
			var fade := create_tween()
			fade.tween_interval(0.8)
			fade.tween_callback(func() -> void:
				_emote.visible = false)
	keeper_spoke.emit(text)
