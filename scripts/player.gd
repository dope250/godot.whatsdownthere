extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 3.5

@export var main_camera:Camera3D



var camera_rotation: Vector2 = Vector2(0.0,0.0)
var mouse_sensitivity = 0.001

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

	# Moves RigidBodies when touched for now (thanks cmdrRiker!) TODO: Needs better solution
	for col_idx in get_slide_collision_count():
		var col := get_slide_collision(col_idx)
		if col.get_collider() is RigidBody3D:
			col.get_collider().apply_central_impulse(-col.get_normal() * 0.1)
			col.get_collider().apply_impulse(-col.get_normal() * 0.01, col.get_position())

	if Input.is_action_just_pressed("exit"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var MouseEvent = event.relative * mouse_sensitivity
		camera_look(MouseEvent)

func camera_look(Movement: Vector2) -> void:
	camera_rotation += Movement
	
	transform.basis = Basis()
	main_camera.transform.basis = Basis()

	rotate_object_local(Vector3(0,1,0),-camera_rotation.x) # first rotate in Y
	main_camera.rotate_object_local(Vector3(1,0,0), -camera_rotation.y) # then rotate in X
	camera_rotation.y = clamp(camera_rotation.y,-1.5,1.2)
