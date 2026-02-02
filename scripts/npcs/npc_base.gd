extends CharacterBody2D
class_name NpcBase

@export var npc_name: String = "NPC"
@export var interactable: bool = true
@export_multiline var dialogue_lines: Array[String] = []

@onready var interact_area: Area2D = $InteractArea
@onready var interact_icon: AnimatedSprite2D = get_node_or_null("InteractIcon")

func _ready() -> void:
	interact_area.body_entered.connect(_on_interact_area_body_entered)
	interact_area.body_exited.connect(_on_interact_area_body_exited)

	if interact_icon:
		interact_icon.visible = false

func set_icon_visible(value: bool) -> void:
	if interact_icon:
		interact_icon.visible = value

func can_interact(_player: Node) -> bool:
	return interactable

func interact(player: Node) -> void:
	if not can_interact(player):
		return
	# replace later with your dialogue UI manager
	for line in dialogue_lines:
		print("%s: %s" % [npc_name, line])

func _on_interact_area_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if body.has_method("register_npc"):
		body.register_npc(self)
	set_icon_visible(true)

func _on_interact_area_body_exited(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if body.has_method("unregister_npc"):
		body.unregister_npc(self)
	set_icon_visible(false)
