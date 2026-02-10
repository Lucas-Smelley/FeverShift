extends CharacterBody2D
class_name NpcBase

@export var npc_id: String = ""
@export var npc_name: String = ""
@export var interactable: bool = true
@export_multiline var pre_task_lines: Array[String] = []
@export_multiline var post_task_lines: Array[String] = []

@onready var interact_area: Area2D = $InteractArea
@onready var interact_icon: AnimatedSprite2D = get_node_or_null("InteractIcon")

@onready var speech_bubble: Node2D = $SpeechBubble
@onready var bubble_sprite: AnimatedSprite2D = $SpeechBubble/bubble
@onready var bubble_label: RichTextLabel = $SpeechBubble/RichTextLabel


@export var char_delay := 0.02
var is_typing := false
var full_text := ""

signal dialogue_advance


func _ready() -> void:
	interact_area.body_entered.connect(_on_interact_area_body_entered)
	interact_area.body_exited.connect(_on_interact_area_body_exited)

	if interact_icon:
		interact_icon.visible = false
		
	bubble_label.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
		
	hide_dialogue()

func set_icon_visible(value: bool) -> void:
	if interact_icon:
		interact_icon.visible = value

func can_interact(_player: Node) -> bool:
	return interactable

func interact(player: Node) -> void:
	if not can_interact(player):
		return

	# Always emit: "player talked to this npc"
	WorldEvents.emit_event("talked_to_npc", {"npc_id": npc_id})

	player.start_npc_interaction(self)
	set_icon_visible(false)

	# Hook for child classes (Bueford, etc.)
	on_interact(player)

# Child NPCs override this
func on_interact(_player: Node) -> void:
	pass

func _on_interact_area_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if body.has_method("register_npc"):
		body.register_npc(self)
		body.target_dirty = true

func _on_interact_area_body_exited(body: Node) -> void:

	if not body.is_in_group("player"):
		return
		
	hide_dialogue()

	if body.has_method("unregister_npc"):
		body.unregister_npc(self)
	body.target_dirty = true
	
	if body.is_interacting_with == self:
		if body.has_method("end_npc_interaction"):
			body.end_npc_interaction(self)
		body.is_interacting_with = null


func show_dialogue(text: String) -> void:
	is_typing = true
	speech_bubble.visible = true
	bubble_sprite.play("idle")

	bubble_label.text = text
	bubble_label.visible_characters = 0

	for i in text.length():
		if not is_typing:
			break
		bubble_label.visible_characters = i + 1
		await get_tree().create_timer(char_delay).timeout

	bubble_label.visible_characters = -1
	is_typing = false
	
	if not speech_bubble.visible:
		return
	
	await dialogue_advance

func skip_typing() -> void:
	is_typing = false

func hide_dialogue() -> void:
	speech_bubble.visible = false
