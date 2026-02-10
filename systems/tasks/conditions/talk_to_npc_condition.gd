extends TaskCondition

@export var npc_id: String = ""
@export var requires_condition_key: String = ""  # e.g. "collect_balls"

var _connected := false

func activate(_owner: Node) -> void:
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
	if event_name != "talked_to_npc":
		return
	if data.get("npc_id", "") != npc_id:
		return
	# GATE: don't complete until prerequisite condition is complete
	if requires_condition_key != "" and task != null:
		if not task.is_condition_complete(requires_condition_key):
			return
	print("talk to npc condition completed")
	_set_completed(true)
