extends Node2D
class_name Interactable

@export var interact_priority: int = 0
@export var one_shot: bool = false
@export var enabled: bool = true

@onready var indicator: CanvasItem = get_node_or_null("InteractIndicator")

var _used := false

func show_icon() -> void:
	if indicator:
		indicator.visible = true

func hide_icon() -> void:
	if indicator:
		indicator.visible = false

func can_interact(_player: Node) -> bool:
	if not enabled:
		return false
	if one_shot and _used:
		return false
	return true

func interact(_player: Node) -> void:
	# override in child scenes
	if one_shot:
		_used = true
