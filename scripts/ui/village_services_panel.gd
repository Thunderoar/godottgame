class_name VillageServicesPanel
extends ModalBase

var _message := ""


func _ready() -> void:
	_panel_size = Vector2(810, 620)
	super._ready()
	GameState.data_changed.connect(func() -> void:
		if visible:
			_rebuild())


func open_services(_repairs: bool = false) -> void:
	_message = ""
	open_panel("Water Keeper Shop")
	GameState.record_mission_event("services")


func _rebuild() -> void:
	_clear_content()
	add_body_text("Gold: %d" % GameState.gold(), GameUI.GOLD, 19)
	if not _message.is_empty():
		add_body_text(_message, GameUI.TEAL, 14)
	add_body_text("Blue water keepers heal burning trees and plant new saplings. Sea urchins can kill them outside shelter.", GameUI.TEXT, 16)
	var cost := GameState.water_hire_cost()
	var hire := GameUI.button("Hire water keeper - %d Gold" % cost, Vector2(400, 48))
	hire.disabled = GameState.water_hire_slot() < 0 or GameState.gold() < cost
	hire.pressed.connect(func() -> void:
		var result := GameState.hire_water_keeper()
		_message = str(result.get("message", ""))
		_rebuild())
	content.add_child(hire)
	add_body_text("Two keepers start with the village. Hire up to five; fallen keepers can be replaced.", GameUI.MUTED, 14)
