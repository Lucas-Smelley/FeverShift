extends TaskCondition
class_name CollectItemCondition

@export var item_id: String = "apple"
@export var required_amount: int = 3

var current_amount: int = 0
var _connected := false

func activate(_owner: Node) -> void:
	current_amount = 0

	if not _connected:
		WorldEvents.event_emitted.connect(_on_world_event)
		_connected = true

func deactivate(_owner: Node) -> void:
	if _connected:
		WorldEvents.event_emitted.disconnect(_on_world_event)
		_connected = false

func _on_world_event(event_name: String, data: Dictionary) -> void:
	if completed:
		return

	if event_name != "item_collected":
		return

	if data.get("item_id", "") != item_id:
		return

	current_amount += int(data.get("amount", 1))
	print("Progress:", current_amount, "/", required_amount)

	if current_amount >= required_amount:
		_set_completed(true)
