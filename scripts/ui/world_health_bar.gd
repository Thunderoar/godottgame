class_name WorldHealthBar
extends Node2D

var subject: Node
var pet_bar := false
var boss_bar := false
var _hp := 1
var _maximum := 1
var _label: Label
var _xp_ratio := 0.0
var _boss_title: Label

func _ready() -> void:
	z_as_relative = false
	z_index = 725
	light_mask = 0
	_label = Label.new()
	_label.scale = Vector2.ONE * PixelArt.PX
	_label.position = Vector2(-1.4 if boss_bar else -0.55, -0.85 if boss_bar else -0.52)
	_label.add_theme_font_size_override("font_size", 14 if boss_bar else 11)
	_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 2)
	add_child(_label)
	if boss_bar:
		_boss_title = Label.new()
		_boss_title.scale = Vector2.ONE * PixelArt.PX
		_boss_title.position = Vector2(-3.5, -1.85)
		_boss_title.size = Vector2(224, 20)
		_boss_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_boss_title.add_theme_font_size_override("font_size", 13)
		_boss_title.add_theme_color_override("font_color", Color("#ffdf91"))
		_boss_title.add_theme_color_override("font_outline_color", Color.BLACK)
		_boss_title.add_theme_constant_override("outline_size", 3)
		add_child(_boss_title)

func _process(_delta: float) -> void:
	if not is_instance_valid(subject):
		visible = false
		return
	if pet_bar:
		var pet := GameState.get_active_pet()
		_hp = int(pet.get("hp", 0))
		_maximum = maxi(1, int(pet.get("hp_max", 1)))
		var progress := GameState.pet_xp_progress()
		_xp_ratio = 1.0 if bool(progress.get("max", false)) else clampf(float(progress.get("xp", 0)) / maxi(1, int(progress.get("next", 1))), 0, 1)
	else:
		_hp = int(subject.hp)
		_maximum = maxi(1, int(subject.max_hp))
	if boss_bar and _boss_title:
		_boss_title.text = subject._boss_name()
	visible = not (subject is Enemy and subject.dead)
	_label.text = ("BOSS " if boss_bar else "") + "%d/%d" % [_hp, _maximum]
	queue_redraw()

func _draw() -> void:
	var width := 2.8 if boss_bar else 1.65
	draw_rect(Rect2(-width / 2 - 0.04, -0.04, width + 0.08, 0.20), Color("#172128"))
	draw_rect(Rect2(-width / 2, 0, width * clampf(float(_hp) / _maximum, 0, 1), 0.12), Color("#ef646b") if boss_bar else Color("#82e4b3"))
	if pet_bar:
		draw_rect(Rect2(-width / 2 - 0.04, 0.16, width + 0.08, 0.15), Color("#172128"))
		draw_rect(Rect2(-width / 2, 0.19, width * _xp_ratio, 0.09), Color("#bb91ed"))
