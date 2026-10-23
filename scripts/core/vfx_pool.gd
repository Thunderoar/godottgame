class_name VfxPool
extends Node2D
## Pre-allocated pool of spark / ring / dust / number / icon sprites. One pool
## is added to every world root; effects borrow a free node, run a short tween
## and hand it back. Nothing is created per hit in normal play.


const SPARK_COUNT := 48
const RING_COUNT := 14
const DUST_COUNT := 24
const NUMBER_COUNT := 18
const POP_COUNT := 16

var _sparks: Array[Sprite2D] = []
var _rings: Array[Sprite2D] = []
var _dusts: Array[Sprite2D] = []
var _numbers: Array[Label] = []
var _pops: Array[Sprite2D] = []
var _spark_cursor := 0
var _ring_cursor := 0
var _dust_cursor := 0
var _number_cursor := 0
var _pop_cursor := 0


func _ready() -> void:
	add_to_group("vfx_pool")
	z_as_relative = false
	z_index = 690
	for i in SPARK_COUNT:
		var s := Sprite2D.new()
		s.texture = PixelArt.icon("spark", 16)
		s.visible = false
		s.z_as_relative = false
		s.z_index = 695
		add_child(s)
		_sparks.append(s)
	for i in RING_COUNT:
		var r := Sprite2D.new()
		r.texture = PixelArt.light_texture()
		r.visible = false
		r.z_as_relative = false
		r.z_index = 688
		add_child(r)
		_rings.append(r)
	for i in DUST_COUNT:
		var d := Sprite2D.new()
		d.texture = PixelArt.light_texture()
		d.visible = false
		d.z_as_relative = false
		d.z_index = 2
		add_child(d)
		_dusts.append(d)
	for i in NUMBER_COUNT:
		var l := Label.new()
		l.add_theme_font_size_override("font_size", 19)
		l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
		l.add_theme_constant_override("shadow_offset_x", 1)
		l.add_theme_constant_override("shadow_offset_y", 2)
		l.visible = false
		l.scale = Vector2(0.032, 0.032)
		l.z_as_relative = false
		l.z_index = 1000
		add_child(l)
		_numbers.append(l)
	for i in POP_COUNT:
		var p := Sprite2D.new()
		p.visible = false
		p.z_as_relative = false
		p.z_index = 720
		add_child(p)
		_pops.append(p)


# ------------------------------------------------------------------ spawners

func sparks(at: Vector2, dir: Vector2, color: Color, count: int) -> void:
	if GameSettings.reduce_motion():
		count = mini(count, 2)
	var n := mini(count, 10)
	for i in n:
		var s := _acquire(_sparks, _spark_cursor) as Sprite2D
		_spark_cursor = (_spark_cursor + 1) % _sparks.size()
		if s == null:
			return
		s.visible = true
		s.texture = PixelArt.icon("spark", 16)
		s.scale = Vector2(0.030, 0.030)
		s.modulate = Color(color.r, color.g, color.b, 0.95)
		s.global_position = at
		var spread := dir
		if spread == Vector2.ZERO:
			spread = Vector2.from_angle(randf() * TAU)
		var angle := spread.angle() + randf_range(-0.9, 0.9)
		var dist := randf_range(0.25, 0.85)
		var tween := s.create_tween().set_parallel(true)
		_own(s, tween)
		tween.tween_property(s, "global_position", at + Vector2.from_angle(angle) * dist, 0.28)
		tween.tween_property(s, "modulate:a", 0.0, 0.28)
		tween.tween_property(s, "rotation", angle, 0.28)
		tween.chain().tween_callback(func() -> void:
			if is_instance_valid(s):
				s.visible = false)


func ring(at: Vector2, radius: float, color: Color, duration: float) -> void:
	var r := _acquire(_rings, _ring_cursor) as Sprite2D
	_ring_cursor = (_ring_cursor + 1) % _rings.size()
	if r == null:
		return
	r.visible = true
	r.modulate = Color(color.r, color.g, color.b, 0.6)
	# The pool texture is the 128px radial light; dividing by its real size
	# keeps `radius` an honest world-unit radius (128 * s / 2 = radius).
	r.scale = Vector2(radius * 1.4 / 128.0, radius * 1.4 / 128.0)
	r.global_position = at
	var tween := r.create_tween().set_parallel(true)
	_own(r, tween)
	tween.tween_property(r, "scale", Vector2(radius * 2.6 / 128.0, radius * 2.6 / 128.0), duration)
	tween.tween_property(r, "modulate:a", 0.0, duration)
	tween.chain().tween_callback(func() -> void:
		if is_instance_valid(r):
			r.visible = false)


func dust(at: Vector2, count: int, color: Color) -> void:
	var n := mini(count, 5)
	for i in n:
		var d := _acquire(_dusts, _dust_cursor) as Sprite2D
		_dust_cursor = (_dust_cursor + 1) % _dusts.size()
		if d == null:
			return
		d.visible = true
		d.modulate = color
		# Small ground puffs (~0.7-1.3 units across) around a 1-unit character.
		var start := 0.006 + randf() * 0.004
		d.scale = Vector2(start, start * 0.8)
		d.global_position = at + Vector2(randf_range(-0.22, 0.22), randf_range(-0.05, 0.12))
		var tween := d.create_tween().set_parallel(true)
		_own(d, tween)
		tween.tween_property(d, "global_position", d.global_position + Vector2(randf_range(-0.35, 0.35), -randf_range(0.15, 0.45)), 0.45)
		tween.tween_property(d, "scale", Vector2(start * 2.2, start * 1.7), 0.45)
		tween.tween_property(d, "modulate:a", 0.0, 0.45)
		tween.chain().tween_callback(func() -> void:
			if is_instance_valid(d):
				d.visible = false)


func number(at: Vector2, amount: int, crit: bool, color: Color) -> void:
	# Labels are Controls, not Node2D, so this pool is acquired directly from
	# its typed array instead of going through the Node2D acquire helper.
	var l: Label = _numbers[_number_cursor]
	_number_cursor = (_number_cursor + 1) % _numbers.size()
	if l == null:
		return
	if l.has_meta("fx_tween"):
		var running := l.get_meta("fx_tween") as Tween
		if running != null and running.is_valid():
			running.kill()
		l.remove_meta("fx_tween")
	l.modulate.a = 1.0
	l.visible = true
	l.text = str(amount) + ("!" if crit else "")
	l.add_theme_color_override("font_color", color)
	l.scale = Vector2(0.032, 0.032) * (1.3 if crit else 1.0)
	l.rotation = 0.0
	l.global_position = at - Vector2(0.34, 0.3)
	var tween := l.create_tween().set_parallel(true)
	_own(l, tween)
	if not GameSettings.reduce_motion():
		tween.tween_property(l, "global_position", l.global_position + Vector2(randf_range(-0.1, 0.1), -1.0), 0.6)
		tween.tween_property(l, "rotation", randf_range(-0.12, 0.12), 0.6)
	tween.tween_property(l, "modulate:a", 0.0, 0.6)
	tween.chain().tween_callback(func() -> void:
		if is_instance_valid(l):
			l.visible = false
			l.modulate.a = 1.0)


func pop(at: Vector2, kind: String, color: Color) -> void:
	var p := _acquire(_pops, _pop_cursor) as Sprite2D
	_pop_cursor = (_pop_cursor + 1) % _pops.size()
	if p == null:
		return
	p.visible = true
	p.texture = PixelArt.icon(kind, 16)
	p.scale = Vector2(0.020, 0.020)
	p.modulate = Color(color.r, color.g, color.b, 1.0)
	p.global_position = at
	var tween := p.create_tween().set_parallel(true)
	_own(p, tween)
	tween.tween_property(p, "scale", Vector2(0.048, 0.048), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(p, "global_position", at + Vector2(0, -0.6), 0.55)
	tween.tween_property(p, "modulate:a", 0.0, 0.55)
	tween.chain().tween_callback(func() -> void:
		if is_instance_valid(p):
			p.visible = false)


func leaves(at: Vector2, count: int, color: Color) -> void:
	if not GameSettings.effects_at_least("med"):
		return
	var n := mini(count, 4)
	for i in n:
		var d := _acquire(_dusts, _dust_cursor) as Sprite2D
		_dust_cursor = (_dust_cursor + 1) % _dusts.size()
		if d == null:
			return
		d.visible = true
		d.texture = PixelArt.leaf_texture()
		d.modulate = color
		d.scale = Vector2(0.022, 0.022)
		d.global_position = at + Vector2(randf_range(-0.4, 0.4), -randf_range(0.5, 1.4))
		var drift := Vector2(randf_range(-0.5, 0.5), -randf_range(0.2, 0.6))
		var tween := d.create_tween().set_parallel(true)
		_own(d, tween)
		tween.tween_property(d, "global_position", d.global_position + drift, 0.6)
		tween.tween_property(d, "rotation", randf_range(-1.2, 1.2), 0.6)
		tween.tween_property(d, "modulate:a", 0.0, 0.6)
		tween.chain().tween_callback(func() -> void:
			if is_instance_valid(d):
				d.visible = false
				d.texture = PixelArt.light_texture())


func _acquire(pool_nodes: Array, cursor: int) -> Node2D:
	# Pools are always fully allocated. A busy node is stolen: its stored tween
	# is killed and every spawn resets all tweened properties anyway.
	var node := pool_nodes[cursor] as Node2D
	if node == null:
		return null
	if node.has_meta("fx_tween"):
		var running := node.get_meta("fx_tween") as Tween
		if running != null and running.is_valid():
			running.kill()
		node.remove_meta("fx_tween")
	node.modulate.a = 1.0
	return node


func _own(node: Node, tween: Tween) -> void:
	# Remember which tween drives a pooled node so the next steal can kill it.
	node.set_meta("fx_tween", tween)
