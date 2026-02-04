extends CharacterBody2D
class_name NpcBase

@export var npc_name: String = "NPC"
@export var interactable: bool = true
@export_multiline var dialogue_lines: Array[String] = []

@onready var interact_area: Area2D = $InteractArea
@onready var interact_icon: AnimatedSprite2D = get_node_or_null("InteractIcon")

@export var offered_tasks: Array[Task] = []

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
	player.start_npc_interaction(self)
	# replace later with dialogue UI manager
	for line in dialogue_lines:
		print("%s: %s" % [npc_name, line])
		
	for t in offered_tasks:
		if t == null:
			continue
		if TaskService.is_completed(t.id) or TaskService.has_task(t.id):
			continue

		TaskService.add_task(t, self)
		print("%s gave task: %s" % [npc_name, t.title])
		break

func _on_interact_area_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if body.has_method("register_npc"):
		body.register_npc(self)
		body.target_dirty = true

func _on_interact_area_body_exited(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	body.unregister_npc(self)
	body.target_dirty = true
	if body.is_interacting_with == self and body.has_method("unregister_npc"):
		body.end_npc_interaction()
		body.is_interacting_with = null
