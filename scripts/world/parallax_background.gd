extends ParallaxBackground

@onready var parallax_move_speed = 40


func _process(delta: float) -> void:
	
	scroll_base_offset.x -= parallax_move_speed * delta
	
	
