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
		add_section("%s - %d hired" % [str(GameState.WORKER_LABELS[worker_role]), GameState.worker_count(worker_role)], GameUI.GOLD)
		add_body_text(str(descriptions[worker_role]), GameUI.TEXT, 15)
		var cost := GameState.worker_hire_cost(worker_role)
		var hire := GameUI.button("Hire %s - %d Gold" % [str(GameState.WORKER_LABELS[worker_role]), cost], Vector2(440, 44))
		hire.disabled = GameState.worker_hire_slot(worker_role) < 0 or GameState.gold() < cost
		hire.pressed.connect(_hire.bind(worker_role))
		content.add_child(hire)
	add_body_text("One of each specialist starts with the village. Hire more or replace fallen workers here.", GameUI.MUTED, 14)

func _hire(worker_role: String) -> void:
	var result := GameState.hire_worker(worker_role)
	_message = str(result.get("message", ""))
	_rebuild()
