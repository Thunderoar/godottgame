class_name WorkerPreview
extends Control
## Cosmetic shop demonstration. Never creates actors or performs village work.

var worker_role := "builder"
var _clock := 0.0
var _texture: Texture2D
const NPCS := {"builder": "construction_worker", "water": "water_keeper", "planter": "tree_planter", "fighter": "swordsman"}

func setup(role: String) -> void:
	worker_role = role
	_texture = PixelArt.npc_texture(str(NPCS[role]))
	custom_minimum_size = Vector2(120, 108)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = VisualStyle.texture_filter()

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	if not GameSettings.reduce_motion():
		_clock = fmod(_clock + delta, 3.0)
	queue_redraw()

func _draw() -> void:
	if _texture == null: return
	var t := 0.6 if GameSettings.reduce_motion() else _clock
	var swing := sin(t * TAU)
	var ground := Vector2(88, 90)
	draw_line(Vector2(5, 96), Vector2(115, 96), Color("#435c51"), 2)
	draw_texture_rect(_texture, Rect2(4, 9 + swing * 1.5, 48, 80), false)
	var hand := Vector2(41, 53)
	match worker_role:
		"builder":
			draw_rect(Rect2(72, 62, 35, 30), Color("#866749"))
			for y in [68, 78, 88]: draw_line(Vector2(74, y), Vector2(105, y), Color("#c6a16c"), 2)
			var tip := Vector2(63 + swing * 8, 50 + swing * 14)
			draw_line(hand, tip, Color("#c49b64"), 5)
			draw_line(tip - Vector2(7, 0), tip + Vector2(7, 0), Color("#c8d2d5"), 7)
			if swing > 0.7: draw_line(Vector2(68, 65), Vector2(75, 59), Color("#ffe2a0"), 2)
		"water":
			draw_rect(Rect2(42, 53, 14, 14), Color("#57c9e4"))
			draw_line(Vector2(53, 57), Vector2(65, 51), Color("#9be7eb"), 4)
			draw_line(ground, ground - Vector2(0, 33), Color("#805539"), 7)
			draw_circle(ground - Vector2(0, 38), 16, Color("#4d8854"))
			draw_circle(ground - Vector2(0, 12), 6 + 3 * swing, Color("#f7a24f"))
			for i in range(5):
				var flow := fmod(t * 1.5 + i * 0.2, 1.0)
				draw_circle(Vector2(63, 52).lerp(Vector2(85, 82), flow) - Vector2(0, sin(flow * PI) * 12), 2, Color("#80ddeb"))
		"planter":
			draw_ellipse_soil(ground)
			var growth := 10 + 12 * (t / 3.0)
			draw_line(ground, ground - Vector2(0, growth), Color("#70ba68"), 3)
			draw_line(ground - Vector2(0, growth * 0.6), ground - Vector2(10, growth), Color("#92d476"), 5)
			draw_line(ground - Vector2(0, growth * 0.8), ground + Vector2(10, -growth - 3), Color("#92d476"), 5)
			draw_line(hand, Vector2(62, 73 + swing * 9), Color("#b89a68"), 4)
			draw_circle(Vector2(62, 77 + swing * 9), 6, Color("#b9c8c8"))
		"fighter":
			draw_circle(ground - Vector2(0, 10), 11, Color("#59486c"))
			for i in range(8):
				var direction := Vector2.from_angle(i * TAU / 8)
				draw_line(ground - Vector2(0, 10) + direction * 8, ground - Vector2(0, 10) + direction * 18, Color("#9f87b8"), 2)
			var tip := hand + Vector2(35, -25).rotated(swing * 0.7)
			draw_line(hand, tip, Color("#d8e7eb"), 5)
			draw_line(hand + Vector2(-3, -5), hand + Vector2(6, 7), Color("#d9b66d"), 4)

func draw_ellipse_soil(at: Vector2) -> void:
	draw_style_box(GameUI.style(Color("#6d5039"), Color("#96714d"), 1, 8), Rect2(at - Vector2(20, 5), Vector2(40, 10)))
