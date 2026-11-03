extends Resource
class_name LootTable

@export var description: String
@export var loot: Array[LootEntry] = []


func get_random_item() -> String:
	var total_weight := 0.0
	for entry in loot:
		if entry and not entry.item_name.strip_edges().is_empty() and entry.weight > 0.0:
			total_weight += entry.weight

	if total_weight <= 0.0:
		return ""

	var roll := randf() * total_weight
	for entry in loot:
		if not entry or entry.item_name.strip_edges().is_empty() or entry.weight <= 0.0:
			continue
		roll -= entry.weight
		if roll < 0.0:
			return entry.item_name

	return ""
