extends NpcBase

@export var collect_balls_task: Task

func on_interact(player: Node) -> void:
	

	if collect_balls_task == null:
		return

	# Only give it if not already active/completed
	if TaskService.is_completed(collect_balls_task.id) or TaskService.has_task(collect_balls_task.id):
		for line in post_task_lines:
			await show_dialogue(line)

			hide_dialogue()
		return

	for line in pre_task_lines:
		await show_dialogue(line)

		hide_dialogue()
		
	TaskService.add_task(collect_balls_task, self)
	print("%s gave task: %s" % [npc_name, collect_balls_task.title])
