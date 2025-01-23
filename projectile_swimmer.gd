extends RigidBody3D

@export var speed: float = 50.0  # Exported speed variable for easy tuning
var direction: Vector3 = Vector3.ZERO  # The direction the bullet will move

func initialize(new_direction: Vector3):
	direction = new_direction.normalized()
	# Apply an impulse in the given direction
	apply_impulse(Vector3.ZERO, direction * speed)
