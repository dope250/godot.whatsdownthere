extends MeshInstance3D

@export var line_length: float = 10.0
@export var projectile: PackedScene
@export var muzzle: Node3D
@export var shoot_force: float = 100.0
@export var catch_interval: float = 2.0

var is_casting: bool = false
var fishing_line: RayCast3D
var swimmer

func _ready() -> void:
	fishing_line = RayCast3D.new()
	fishing_line.target_position = -transform.basis.z * line_length
	add_child(fishing_line)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Shoot"):
		cast_rod()

func cast_rod() -> void:
	if not is_casting:
		is_casting = true
		print("Rod cast into the water")
		swimmer = projectile.instantiate()	
		owner.add_child(swimmer)
		swimmer.global_transform = muzzle.global_transform
		# Call Init from projectile
		#if swimmer.has_method("initialize"):
		# Give it a little push
		swimmer.apply_central_impulse(-global_transform.basis.z * shoot_force)

	else:
		is_casting = false
		pull_fish()
		swimmer.remove()

func pull_fish() -> void:

	if swimmer.caught_something():
			swimmer.catch_random_item()
		
#	if swimmer.is_colliding():
#		var fish = swimmer.get_collider()
#
#		if fish.name == "Fish":
#			fish.queue_free()  # Simulates catching a fish
#			print("You caught a fish!")
#			swimmer.remove()
