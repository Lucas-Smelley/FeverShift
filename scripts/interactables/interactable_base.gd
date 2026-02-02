extends Node2D
class_name Interactable

@export var interact_priority: int = 0
@export var one_shot: bool = false
@export var enabled: bool = true

@onready var interact_icon: AnimatedSprite2D = get_node_or_null("InteractIcon")

var _used := false

func set_icon_visible(value: bool) -> void:
	if interact_icon:
		interact_icon.visible = value

func can_interact() -> bool:
	if not enabled:
		return false
	if one_shot and _used:
		return false
	return true

func interact(player: Node) -> void:
	# override in child scenes
	if one_shot:
		_used = true
