extends Node
class_name TaskManager

signal task_added(task: Task)
signal task_completed(task: Task)

# Active tasks by id
var active: Dictionary = {}        # String -> Task
var completed_ids: Dictionary = {} # String -> bool (cheap set)

func has_task(task_id: String) -> bool:
	return active.has(task_id)

func is_completed(task_id: String) -> bool:
	return completed_ids.has(task_id)

func get_task(task_id: String) -> Task:
	return active.get(task_id, null)

func add_task(task_template: Task, owner: Node) -> Task:
	if task_template == null:
		return null
	if task_template.id == "":
		push_warning("Tried to add a task with empty id.")
		return null

	# Don't re-add if active or already completed
	if active.has(task_template.id) or completed_ids.has(task_template.id):
		return active.get(task_template.id, null)

	# IMPORTANT:
	# Tasks are Resources. If you reuse the same .tres for multiple NPCs/plays,
	# you must duplicate it so state isn't shared.
	var task := task_template.duplicate(true) as Task

	active[task.id] = task
	task.task_completed.connect(func(): _on_task_completed(task))

	task.start(owner)
	task_added.emit(task)
	return task

func _on_task_completed(task: Task) -> void:
	# Mark completed + remove from active
	completed_ids[task.id] = true
	active.erase(task.id)

	# Optional cleanup: disconnect conditions by stopping
	task.stop()

	task_completed.emit(task)
