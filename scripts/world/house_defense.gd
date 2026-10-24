class_name HouseDefense
extends Node2D
## A sheltered archer. Its tier is owned by the central home.

const INTERVALS := [2.1, 1.7, 1.3, 1.0, 0.7]
var structure: SettlementTarget
var _cooldown := 0.0
var _aim := Vector2.RIGHT
var _flash := 0.0
var _art: Sprite2D
var _tier: Label
var _level := 0

func _ready() -> void:
	add_to_group("house_defenses")
	add_to_group("archer_huts")
	z_index = 20
	_art = Sprite2D.new()
	_art.scale = Vector2.ONE * PixelArt.PX
	_art.position.y = -1.2
	add_child(_art)
	_tier = Label.new()
	_tier.scale = Vector2.ONE * PixelArt.PX
	_tier.position = Vector2(-0.65, -2.8)
	_tier.add_theme_font_size_override("font_size", 11)
	_tier.add_theme_color_override("font_outline_color", Color.BLACK)
	_tier.add_theme_constant_override("outline_size", 3)
	add_child(_tier)

func _process(delta: float) -> void:
	if not is_instance_valid(structure):
		return
	visible = structure.is_intact()
	_flash = maxf(0, _flash - delta)
	_cooldown = maxf(0, _cooldown - delta)
	var level := GameState.house_level()
	if _level != level:
		_level = level
		_art.texture = PixelArt.archer_hut_texture(level)
		_tier.text = "Lv %d" % level
	if not visible or GameState.game_over_active:
		return
	var target: Enemy
	var nearest := 7.0 + level
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.dead or enemy.is_queued_for_deletion() or enemy.get_parent() != structure.get_parent().get_parent() or enemy.kind not in ["fire", "urchin"]:
			continue
		var distance := global_position.distance_to(enemy.global_position)
		if distance < nearest:
			nearest = distance
			target = enemy
	if is_instance_valid(target):
		_aim = (target.global_position - global_position).normalized()
		_art.flip_h = _aim.x < 0
		if _cooldown <= 0:
			_cooldown = INTERVALS[level - 1]
			_flash = 0.15
			var arrow := VillageBolt.new()
			arrow.target = target
			arrow.source = self
			arrow.arrow = true
			arrow.damage = 4 + level * 2
			arrow.speed = 18.0
			structure.get_parent().get_parent().add_child(arrow)
			arrow.global_position = global_position + Vector2(0, -1.2)
