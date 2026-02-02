extends Interactable

func interact(player: Node) -> void:
	if not can_interact():
		return
	print('im a ball')
		
