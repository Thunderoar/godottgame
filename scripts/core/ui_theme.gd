class_name GameUI
extends RefCounted
## Shared palette and tiny theme factory for the HUD and menus.

const INK := Color("#0b1519")
const PANEL := Color("#12242a")
const PANEL_RAISED := Color("#1a3037")
const BORDER := Color("#38545a")
const BORDER_LIGHT := Color("#5b7c80")
const TEXT := Color("#f0e6cd")
const MUTED := Color("#9cafab")
const GOLD := Color("#f2c45a")
const DIAMOND := Color("#8fe8f7")
const TEAL := Color("#62c7ba")
const RED := Color("#df525d")
const MANA := Color("#6a9fe8")
const PURPLE := Color("#a47be0")
const GREEN := Color("#8ac36b")

static var _theme: Theme


static func theme() -> Theme:
	if _theme != null:
		return _theme
	_theme = Theme.new()
	_theme.default_font_size = 18
	_theme.set_color("font_color", "Label", TEXT)
	_theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.5))
	_theme.set_constant("shadow_offset_x", "Label", 1)
	_theme.set_constant("shadow_offset_y", "Label", 2)

	_theme.set_stylebox("panel", "Panel", style(PANEL, BORDER, 2, 0))
	_theme.set_stylebox("panel", "PanelContainer", style(PANEL, BORDER, 2, 0))
	_theme.set_color("font_color", "Button", TEXT)
	_theme.set_color("font_hover_color", "Button", Color.WHITE)
	_theme.set_color("font_pressed_color", "Button", INK)
	_theme.set_color("font_disabled_color", "Button", MUTED.darkened(0.35))
	_theme.set_stylebox("normal", "Button", style(PANEL_RAISED, BORDER, 2, 0))
	_theme.set_stylebox("hover", "Button", style(Color("#24454c"), TEAL, 2, 0))
	_theme.set_stylebox("pressed", "Button", style(TEAL, Color("#d5fff7"), 2, 0))
	_theme.set_stylebox("disabled", "Button", style(Color("#152126"), Color("#263239"), 2, 0))
	_theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	_theme.set_constant("h_separation", "Button", 8)
	_theme.set_color("font_color", "RichTextLabel", TEXT)
	_theme.set_stylebox("background", "RichTextLabel", StyleBoxEmpty.new())
	_theme.set_stylebox("normal", "LineEdit", style(INK, BORDER, 2, 0))
	_theme.set_stylebox("scroll", "VScrollBar", style(Color("#0e1b20"), Color(0, 0, 0, 0), 0, 0))
	_theme.set_stylebox("grabber", "VScrollBar", style(BORDER, BORDER_LIGHT, 1, 0))
	_theme.set_stylebox("grabber_highlight", "VScrollBar", style(BORDER_LIGHT, TEXT, 1, 0))
	_theme.set_stylebox("grabber_pressed", "VScrollBar", style(TEAL, TEXT, 1, 0))
	return _theme


static func style(fill: Color, border: Color = BORDER, width: int = 2, radius: int = 0, alpha: float = 1.0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(fill.r, fill.g, fill.b, fill.a * alpha)
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box


static func label(text: String, size: int = 18, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func title(text: String, size: int = 32, color: Color = TEXT) -> Label:
	var l := label(text, size, color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 3)
	return l


static func panel(fill: Color = PANEL, border: Color = BORDER) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style(fill, border, 2, 0))
	return p


static func button(text: String, min_size: Vector2 = Vector2.ZERO, color: Color = TEXT) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 17)
	b.add_theme_color_override("font_color", color)
	if min_size != Vector2.ZERO:
		b.custom_minimum_size = min_size
	return b


static func spacer(height: int = 8) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	return c


static func divider(color: Color = BORDER) -> ColorRect:
	var c := ColorRect.new()
	c.color = color
	c.custom_minimum_size = Vector2(0, 2)
	return c


static func icon_rect(kind: String, pixel_size: int = 22) -> TextureRect:
	var t := TextureRect.new()
	t.texture = PixelArt.icon(kind)
	t.custom_minimum_size = Vector2(pixel_size, pixel_size)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return t


static func chip(text: String, color: Color = GOLD) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style(Color(0.03, 0.07, 0.08, 0.85), color.darkened(0.3), 1, 0))
	var l := label(text, 13, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p
