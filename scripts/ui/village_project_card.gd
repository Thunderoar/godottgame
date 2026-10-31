class_name VillageProjectCard
extends PanelContainer
## Shared, live civic commission card. Updates in place while village life continues.

var allow_commission := true
var compact := false
var _status: Label
var _progress: ProgressBar
var _commission: Button
var _path: Button
var _clock := 0.0
var _message := ""

func _ready() -> void:
	add_theme_stylebox_override("panel", GameUI.style(Color("#162e30"), Color("#9b8251"), 2, 12))
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 12)
	box.add_child(heading)
	var picture := TextureRect.new()
	picture.texture = PixelArt.house_texture(GameState.house_level())
	picture.custom_minimum_size = Vector2(48, 44) if compact else Vector2(82, 66)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	heading.add_child(picture)
	var title := GameUI.label("WEST WORKSHOP · ADVANCED SWORDS" if compact else "A ROOF FOR THE WORKSHOP\nBram & Rami · Western cottage", 16 if compact else 18, GameUI.GOLD)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	var definition := VillageProjectDB.get_project(VillageProjectDB.WORKSHOP)
	for paragraph in [definition.description, definition.benefit]:
		if compact: continue
		var label := GameUI.label(str(paragraph), 14, GameUI.TEXT)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(label)
	_status = GameUI.label("", 14, GameUI.TEAL)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_status)
	_progress = ProgressBar.new()
	_progress.custom_minimum_size.y = 16
	_progress.show_percentage = false
	_progress.max_value = VillageProjectDB.WORK_SECONDS
	box.add_child(_progress)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	box.add_child(actions)
	_commission = GameUI.button("Commission · FREE", Vector2(200, 40))
	_commission.pressed.connect(_start)
	actions.add_child(_commission)
	_path = GameUI.button("Show path", Vector2(140, 40))
	_path.pressed.connect(_show_path)
	actions.add_child(_path)
	_sync()

func _process(delta: float) -> void:
	if not is_visible_in_tree() or is_queued_for_deletion(): return
	_clock -= delta
	if _clock <= 0:
		_clock = 0.2
		_sync()

func _sync() -> void:
	var status := GameState.project_status()
	var state := str(status.state)
	_status.text = str(status.message)
	if state == "working":
		_status.text = "%.0f%% complete · %s\n%s" % [(1.0 - float(status.remaining) / VillageProjectDB.WORK_SECONDS) * 100, "resumes by day" if GameState.is_night() else "builders work on site", status.work]
	if bool(status.legacy) and state != "complete": _status.text += "\nYour existing shop access and restored buildings are retained. This fit-out is optional."
	if not _message.is_empty(): _status.text += "\n" + _message
	_progress.visible = state == "working"
	_progress.value = VillageProjectDB.WORK_SECONDS - float(status.remaining)
	_commission.visible = allow_commission and state == "not_started"
	_commission.disabled = not bool(status.ok)
	_commission.tooltip_text = str(status.message)
	_path.visible = state != "complete"
	_path.text = "Hide path" if GameState.tracked_village_project() == VillageProjectDB.WORKSHOP else "Show path"

func _start() -> void:
	var result := GameState.start_village_project(VillageProjectDB.WORKSHOP)
	_message = str(result.message)
	Sfx.play("equip" if bool(result.ok) else "deny", -10)
	_sync()

func _show_path() -> void:
	var was_tracked := GameState.tracked_village_project() == VillageProjectDB.WORKSHOP
	GameState.track_village_project("" if GameState.tracked_village_project() == VillageProjectDB.WORKSHOP else VillageProjectDB.WORKSHOP)
	var owner_panel := get_parent()
	while owner_panel != null:
		if owner_panel is ModalBase:
			owner_panel.close_panel()
			break
		owner_panel = owner_panel.get_parent()
	var hud := get_tree().get_first_node_in_group("hud") as GameHUD
	if not is_instance_valid(hud): return
	if was_tracked and hud._tracked_objective_id == "workshop":
		hud.clear_objective_tracking()
	elif GameState.tracked_village_project() == VillageProjectDB.WORKSHOP and hud._tracked_objective_id != "workshop":
		hud.track_objective("workshop")
