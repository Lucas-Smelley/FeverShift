extends Resource
class_name TaskCondition

signal condition_changed

@export var description: String = "Condition"
var completed: bool = false

func is_complete() -> bool:
	
	return completed

func activate(_owner: Node) -> void:
	pass

func deactivate(_owner: Node) -> void:
	pass

func on_event(_event_name: String, _data: Dictionary) -> void:
	pass

func _set_completed(value: bool) -> void:
	if completed == value:
		return
	completed = value
	condition_changed.emit()
