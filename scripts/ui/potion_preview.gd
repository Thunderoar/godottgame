class_name PotionPreview
extends Control
## Illustration only: no item use, actors, rewards or changes to progression.

var item_id := "health_potion"
var _clock := 0.0
var _hero: Texture2D
var _bottle: Texture2D

static func supports(id: String) -> bool:
	return str(ItemDB.get_item(id).get("shop", "")) == "potion"

static func usage_hint(id: String) -> String:
	var effect: Dictionary = ItemDB.get_item(id).get("effect", {})
	if effect.has("heal"):
		return "Auto after a hit at ≤%d%% HP" % roundi(GameState.AUTO_HEAL_RATIO * 100)
	if effect.has("boss_revive"): return "Auto · Boss fights only"
	return "Use from your Pack"

func setup(id: String) -> void:
	item_id = id
	_hero = PixelArt.character_texture("adam", 0)
	var icon := str(ItemDB.get_item(id).get("icon", id))
	_bottle = PixelArt.icon(icon, 32)
	custom_minimum_size = Vector2(80, 102)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = VisualStyle.texture_filter()

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	if not GameSettings.reduce_motion(): _clock = fmod(_clock + delta, 3.0)
	queue_redraw()

func _draw() -> void:
	if _hero == null: return
	var t := 1.5 if GameSettings.reduce_motion() else _clock
	var progress := clampf(t / 1.6, 0.0, 1.0)
	var effect: Dictionary = ItemDB.get_item(item_id).get("effect", {})
	var pos := Vector2(24, 22)
	var tint := Color.WHITE
	var hp := 0.3
	if effect.has("sprint_seconds"):
		pos.x += sin(t * 4) * 10
		for i in range(3):
			draw_line(pos + Vector2(-10 - i * 3, 20 + i * 7), pos + Vector2(-2, 20 + i * 7), Color("#a6dfab"), 2)
	if effect.has("heal"): hp = lerpf(0.3, 0.9, progress)
	if effect.has("boss_revive"):
		hp = float(effect.boss_revive) * progress
		tint.a = lerpf(0.15, 1.0, progress)
		pos.y += 10 * (1.0 - progress)
	draw_texture_rect(_hero, Rect2(pos, Vector2(32, 48)), false, tint)
	if effect.has("heal") or effect.has("boss_revive"):
		var green := Color("#8bdd8a") if effect.has("heal") else Color("#edcf83")
		draw_rect(Rect2(18, 10, 48, 7), Color("#29383a"))
		draw_rect(Rect2(19, 11, 46 * hp, 5), green)
		var cross := Vector2(64, 45 - 12 * progress)
		draw_line(cross - Vector2(5, 0), cross + Vector2(5, 0), green, 3)
		draw_line(cross - Vector2(0, 5), cross + Vector2(0, 5), green, 3)
	if effect.has("haste_seconds"):
		var hand := pos + Vector2(26, 24)
		var tip := hand + Vector2(18, -18).rotated(sin(t * 9) * 0.8)
		draw_line(hand, tip, Color("#e5dfb1"), 3)
		draw_arc(hand, 24, -1.4, 0.5, 12, Color("#f5d88a"), 2)
	if effect.has("shield"):
		draw_arc(pos + Vector2(16, 24), 27 + sin(t * 4), 0, TAU, 24, Color("#74c8ef"), 2)
		draw_texture_rect(PixelArt.icon("shield", 32), Rect2(52, 45, 22, 22), false)
	draw_texture_rect(_bottle, Rect2(4, 72, 24, 24), false)
	draw_line(Vector2(34, 84), Vector2(67, 84), Color("#a8bdaf"), 2)
	draw_line(Vector2(60, 79), Vector2(67, 84), Color("#a8bdaf"), 2)
	draw_line(Vector2(60, 89), Vector2(67, 84), Color("#a8bdaf"), 2)
