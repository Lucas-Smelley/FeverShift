extends Area2D
class_name Collectable

@export var item_id: String = ""
@export var item_name: String = ""
@export var enabled: bool = true
@export var amount: int = 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func can_be_collected() -> bool:
	return enabled

func collect(player: Node) -> void:
	player.inventory.add_item(item_id)

func _on_body_entered(body: Node) -> void:
	if not enabled:
		return

	if not body.is_in_group("player"):
		return
		
	WorldEvents.emit_event("item_collected", {
		"item_id": item_id,
		"item_name": item_name,
		"amount": amount
	})

	print("collected:", item_id)
	body.inventory.add_item(item_id)
	queue_free()
