extends Node2D

var items: Dictionary = {}

func add_item(id: String, amount := 1):
	items[id] = items.get(id, 0) + amount
	
func has_item(id: String):
	return items.has(id)
	
func remove_item(id: String, amount := 1):
	if not items.has(id):
		return
	
	items[id] -= amount
	if items[id] <= 0:
		items.erase(id)
