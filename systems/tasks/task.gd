extends Resource
class_name Task

signal task_updated
signal task_completed

@export var id: String = ""
@export var title: String = "Task"
@export_multiline var description: String = ""
@export var conditions: Array[TaskCondition] = []
@export var reward_money: int = 0

enum State { INACTIVE, ACTIVE, COMPLETE }
var state: int = State.INACTIVE

var owner: Node = null

func start(task_owner: Node) -> void:
	if state != State.INACTIVE:
		return

	owner = task_owner
	state = State.ACTIVE

	for c in conditions:
		if c == null:
			continue
		# listen for condition changes
		c.condition_changed.connect(_on_condition_changed)
		c.activate(owner)

	_check_complete()
	task_updated.emit()

func stop() -> void:
	if state != State.ACTIVE:
		return

	for c in conditions:
		if c == null:
			continue
		if c.condition_changed.is_connected(_on_condition_changed):
			c.condition_changed.disconnect(_on_condition_changed)
		c.deactivate(owner)

	state = State.INACTIVE
	owner = null
	task_updated.emit()

func _on_condition_changed() -> void:
	_check_complete()
	task_updated.emit()

func _check_complete() -> void:
	if state != State.ACTIVE:
		return

	for c in conditions:
		if c == null:
			continue
		if not c.is_complete():
			return

	state = State.COMPLETE
	task_completed.emit()
