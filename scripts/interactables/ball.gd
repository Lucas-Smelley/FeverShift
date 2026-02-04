extends Interactable

@export var amount: int = 1

func interact(player: Node) -> void:
	if not can_interact():
		return

	super.interact(player)

	WorldEvents.emit_event("item_collected", {
		"item_id": item_id,
		"item_name": item_name,
		"amount": amount
	})

	print("Collected:", item_name)

	if one_shot:
		enabled = false
		visible = false

		var area := get_node_or_null("InteractArea") as Area2D
		if area:
			area.monitoring = false
			area.monitorable = false
