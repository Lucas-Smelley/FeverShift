extends Camera2D

var player: Node2D
var focus_target: Node2D = null

@export var talk_zoom := Vector2(2, 2)
@export var normal_zoom := Vector2(1, 1)
@export var focus_time := 0.25

var cam_tween: Tween
var is_tweening := false

func set_player(p: Node2D) -> void:
	player = p
	focus_target = player
	
func focus_on(target: Node2D) -> void:
	focus_target = target
	_start_focus_tween(target.global_position, talk_zoom)
	
func clear_focus() -> void:
	focus_target = player
	_start_focus_tween(player.global_position, normal_zoom)
	
func _start_focus_tween(target_pos: Vector2, target_zoom: Vector2) -> void:
	is_tweening = true

	if cam_tween and cam_tween.is_running():
		cam_tween.kill()

	cam_tween = create_tween()
	cam_tween.set_trans(Tween.TRANS_SINE)
	cam_tween.set_ease(Tween.EASE_OUT)

	cam_tween.tween_property(self, "global_position", target_pos, focus_time)
	cam_tween.parallel().tween_property(self, "zoom", target_zoom, focus_time)

	cam_tween.finished.connect(func():
		is_tweening = false
	)
	
func _process(delta: float) -> void:
	if focus_target == null:
		return
	if is_tweening:
		return
	global_position = focus_target.global_position
