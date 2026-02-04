extends Resource
class_name TaskCondition

signal condition_changed

@export var key: String = ""  # optional identifier, like "collect_balls"
@export var description: String = "Condition"

var completed: bool = false
var task: Task = null  # set by Task.start()

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
