class_name HouseDefense
extends Node2D
## Purchased rooftop machine gun; home level controls its fire rate.
const INTERVALS := [0.6, 0.5, 0.4, 0.3, 0.2]
var structure: SettlementTarget
var _cooldown := 0.0
var _aim := Vector2.RIGHT
var _flash := 0.0
var _art: Sprite2D
var _tier: Label
var _level := 0

func _ready() -> void:
	add_to_group("house_defenses")
	add_to_group("roof_guns")
	z_index = 20
	_art = Sprite2D.new()
	_art.scale = Vector2.ONE * PixelArt.PX
	add_child(_art)
	_tier = Label.new()
	_tier.scale = Vector2.ONE * PixelArt.PX
	_tier.position = Vector2(-0.65, -0.8)
	_tier.add_theme_font_size_override("font_size", 11)
	_tier.add_theme_color_override("font_outline_color", Color.BLACK)
	_tier.add_theme_constant_override("outline_size", 3)
	add_child(_tier)
	visible = false

func _process(delta: float) -> void:
	if not is_instance_valid(structure):
		return
	visible = structure.is_intact() and GameState.has_roof_gun(structure.structure_id)
	_flash = maxf(0.0, _flash - delta)
	_cooldown = maxf(0.0, _cooldown - delta)
	var level := GameState.house_level()
	if _level != level:
		_level = level
		# Align the mount to the current roof ridge in the existing 224x176 art.
		var house_scale := 1.3 if structure.structure_id == "cottage" else 0.78
		position.y = (-118.0 - (level - 1) * 10.0) * PixelArt.PX * house_scale
		_art.texture = PixelArt.roof_gun_texture(level)
		_tier.text = "Lv %d" % level
	if not visible or GameState.game_over_active:
		return
	var target: Enemy
	var nearest := 11.0 + level
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.dead or enemy.is_queued_for_deletion() or enemy.get_parent() != structure.get_parent().get_parent() or enemy.kind not in ["fire", "urchin"]:
			continue
		var distance := global_position.distance_to(enemy.global_position)
		if distance < nearest:
			nearest = distance
			target = enemy
	if is_instance_valid(target):
		_aim = (target.global_position - global_position).normalized()
		_art.rotation = _aim.angle()
		if _cooldown <= 0.0:
			_cooldown = INTERVALS[level - 1]
			var bullet := VillageBolt.new()
			bullet.target = target
			bullet.source = self
			bullet.arrow = false
			bullet.damage = 3 + level
			bullet.speed = 30.0
			structure.get_parent().get_parent().add_child(bullet)
			bullet.global_position = global_position + _aim * 0.7
			Vfx.sparks(bullet.global_position, _aim, Color("#ffe08c"), 2)
			if target.combat_sounds_enabled():
				Sfx.play("hit", -25.0)
