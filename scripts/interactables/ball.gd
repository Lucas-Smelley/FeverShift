extends RigidBody2D

var kick_force = 900.0
var upward_force = 200.0

func can_interact(player) -> bool:
	return true
	
func get_prompt() -> String:
	return "Kick the ball"
	
func interact(player) -> void:
	var dir := 1
	if player.animated_sprite.flip_h:
		dir = -1
		
	apply_impulse(Vector2(dir * kick_force, -upward_force))
