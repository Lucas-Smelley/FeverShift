extends Node
class_name WorldEventsBus

signal event_emitted(event_name: String, data: Dictionary)

func emit_event(event_name: String, data: Dictionary = {}) -> void:
	event_emitted.emit(event_name, data)
