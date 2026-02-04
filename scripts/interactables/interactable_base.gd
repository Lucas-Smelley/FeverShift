extends Node2D
class_name Interactable

@export var item_id: String = ""      # logic id (e.g. "ball")
@export var item_name: String = ""    # display name (e.g. "Rubber Ball")

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
	# Base behavior only handles "used" state
	if one_shot:
		_used = true
