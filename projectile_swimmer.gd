extends RigidBody3D

@export var catchtimeMinInSec: int = 5
@export var catchtimeMaxInSec: int = 30
@export var lootTable: LootTable

var collider: RigidBody3D
var isInWater: bool = false


var gotSomething: bool = false
var catchEffect
var destroyEffect

func _ready():
	catchEffect = get_node("CatchEffect")
	#collider = get_node("Collider")
	#TODO: destroyEffect = get_node(".")

func caught_something() -> bool:
	return gotSomething

func catch_random_item():
	print("Caught: ", lootTable.GetMeAnItem())

func remove():
	#TODO: Make swimmer fly to player. Play destroy effect on the way
	queue_free()

func _on_body_entered(body: Node) -> void:
	print("Swimmer entered: " + body.name)
	if body.name.contains("Water"):
		isInWater = true;
		await get_tree().create_timer(randi() % catchtimeMinInSec + catchtimeMaxInSec).timeout
		gotSomething = true
		catchEffect.set_emitting(true)
	else:
		isInWater = false;
		catchEffect.set_emitting(false)

func _on_body_exited(body: Node) -> void:
	print("Swimmer exited: " + body.name)
	if body.name.contains("Water"):
		isInWater = false;
