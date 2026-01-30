extends CharacterBody2D

func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()
	
func can_interact(player) -> bool:
	return true
	
func interact(player) -> void:
	player.start_npc_focus(self)
		
