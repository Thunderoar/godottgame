class_name VillageServicesPanel
extends ModalBase

var _message := ""
var _band: ShopScene

func _ready() -> void:
	_panel_size = Vector2(810, 620)
	super._ready()
	GameState.data_changed.connect(func() -> void:
		if visible:
			_rebuild())

func open_services(_repairs: bool = false) -> void:
	_message = ""
	open_panel("Village Worker Shop")
	GameState.record_mission_event("services")

func _rebuild() -> void:
	_clear_content()
	_band=ShopScene.new()
	_band.setup("services","Village Workers")
	content.add_child(_band)
	add_body_text("Gold: %d" % GameState.gold(), GameUI.GOLD, 19)
	if not _message.is_empty():
		add_body_text(_message, GameUI.TEAL, 14)
	var descriptions := {"builder": "ORANGE - repair damaged buildings by day. Each repair takes 10 seconds after arrival.", "water": "BLUE - attack fire monsters with water and extinguish burning trees.", "planter": "GREEN - plant fallen trees. Saplings grow safely over 30 seconds.", "fighter": "BLACK - fight sea urchins with a sword."}
	for worker_role in ["builder", "water", "planter", "fighter"]:
		var card := GameUI.framed_panel("stone", 8)
		content.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		card.add_child(row)
		var portrait := WorkerPreview.new()
		portrait.setup(worker_role)
		row.add_child(portrait)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var status := GameState.worker_status(worker_role)
		var title := GameUI.label("%s · %d/%d alive" % [str(GameState.WORKER_LABELS[worker_role]), int(status.alive), int(status.total)], 17, GameUI.GOLD)
		title.name = "WorkerStatus_" + worker_role
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(title)
		if int(status.fallen) > 0:
			var warning := GameUI.label("%d fallen · Hire a replacement here" % int(status.fallen), 14, GameUI.RED)
			warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			info.add_child(warning)
		var description := GameUI.label(str(descriptions[worker_role]), 14, GameUI.TEXT)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(description)
		info.add_child(GameUI.label("Job preview", 12, GameUI.MUTED))
		var cost := GameState.worker_hire_cost(worker_role)
		var hire := GameUI.button("%s %s - %d Gold" % ["Replace" if int(status.fallen) > 0 else "Hire", str(GameState.WORKER_LABELS[worker_role]), cost], Vector2(0, 44))
		hire.disabled = GameState.worker_hire_slot(worker_role) < 0 or GameState.gold() < cost
		hire.pressed.connect(_hire.bind(worker_role))
		info.add_child(hire)
	add_body_text("One of each specialist starts with the village. Hire more or replace fallen workers here.", GameUI.MUTED, 14)

func _hire(worker_role: String) -> void:
	var result := GameState.hire_worker(worker_role)
	_message = str(result.get("message", ""))
	_rebuild()
