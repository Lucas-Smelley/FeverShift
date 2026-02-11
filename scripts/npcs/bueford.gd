extends NpcBase

@export var collect_balls_task: Task
@onready var choice_menu: ChoiceMenu = $ChoiceMenu


func on_interact(player: Node) -> void:

	if collect_balls_task == null:
		return

	# Only give it if not already active/completed
	if TaskService.is_completed(collect_balls_task.id) or TaskService.has_task(collect_balls_task.id):
		for line in post_task_lines:
			await show_dialogue(line)

			hide_dialogue()
		return

	for i in pre_task_lines.size():
		
		var is_last_line = i == pre_task_lines.size() - 1
		if not is_last_line:
			await show_dialogue(pre_task_lines[i])
			hide_dialogue()
		show_dialogue(pre_task_lines[i])
		
	choice_menu.open_menu(["Yes", "No", "More..."])
	player.set_active_choice_menu(choice_menu)
	TaskService.add_task(collect_balls_task, self)
	print("%s gave task: %s" % [npc_name, collect_balls_task.title])
