class_name KrakenKing
extends Enemy

func _ready() -> void:
	kind = "kraken_king"
	is_boss = true
	max_hp = 720
	damage = 16
	special_damage = 22
	speed = 1.1
	body_radius = 2.1
	boss_ability = "area"
	boss_ability_name = "Royal Tentacle Slam"
	special_cooldown = 3.2
	dungeon_alerted = true
	super._ready()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_instance_valid(sprite):
		sprite.texture = CampaignArt.kraken_texture()
		sprite.scale = Vector2.ONE * PixelArt.PX * 1.8

func _boss_name() -> String:
	return "VORATH, THE KRAKEN KING"
