extends RigidBody3D

@export var catchtime: float = 5.0
var gotSomething: bool = false

func _ready():
	await get_tree().create_timer(catchtime).timeout
	gotSomething = true
	#queue_free()

func caught_something() -> bool:
	if gotSomething:
		return true
	else:
		return false

func catch_random_item():
	var items = ["Fish", "Boot", "Treasure", "Junk"]
	var random_item = items[randi() % items.size()]
	print("Caught: ", random_item)

func remove():
	queue_free()
