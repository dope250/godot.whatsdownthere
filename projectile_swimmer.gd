extends RigidBody3D

@export var catchtimeMin: int = 5
@export var catchtimeMax: int = 30


var gotSomething: bool = false
var catchEffect
var destroyEffect

func _ready():
	catchEffect = get_node("CatchEffect")
	#TODO: destroyEffect = get_node(".")
	await get_tree().create_timer(randi() % catchtimeMin + catchtimeMax).timeout
	catchEffect.set_emitting(true)
	gotSomething = true
	

func caught_something() -> bool:
	return gotSomething

func catch_random_item():
	var items = ["Fish", "Boot", "Treasure", "Junk"]
	var random_item = items[randi() % items.size()]
	print("Caught: ", random_item)

func remove():
	queue_free()
