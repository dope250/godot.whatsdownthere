extends Resource
class_name LootTable

@export var description: String
#@export var loot: Array[PackedScene]
@export var loot: Array[String]


func GetMeAnItem() -> String : 
	var random_item = loot[randi() % loot.size()]
	return random_item
	
