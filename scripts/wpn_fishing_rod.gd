extends MeshInstance3D

@export var line_length: float = 10.0
@export var projectile: PackedScene
@export var muzzle: Node3D

var is_casting: bool = false
var fishing_line: RayCast3D

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
		var swimmer = projectile.instantiate()
		swimmer.transform = muzzle.transform
		owner.add_child(swimmer)		
		# Call Init from projectile
		if swimmer.has_method("initialize"):
			swimmer.initialize(muzzle.basis.z * -1)  # Example direction
	else:
		is_casting = false
		pull_fish()

func pull_fish() -> void:
	if fishing_line.is_colliding():
		var fish = fishing_line.get_collider()
		if fish.name == "Fish":
			fish.queue_free()  # Simulates catching a fish
			print("You caught a fish!")
