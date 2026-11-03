extends MeshInstance3D

@export var projectile: PackedScene
@export var muzzle: Node3D
@export var shoot_force: float = 100.0
@export_range(1.0, 100.0, 0.5) var fishing_line_length: float = 30.0

var is_casting: bool = false
var swimmer: RigidBody3D
var fishing_line: FishingLine
var _rest_rotation: Vector3
var _animation_tween: Tween


func _ready() -> void:
	_rest_rotation = rotation


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Shoot"):
		cast_rod()


func cast_rod() -> void:
	if is_casting:
		pull_fish()
		return
	if projectile == null or muzzle == null:
		push_warning("Fishing rod needs a projectile and muzzle to cast.")
		return

	var cast_parent := get_tree().current_scene
	if cast_parent == null:
		cast_parent = get_parent()
	swimmer = projectile.instantiate() as RigidBody3D
	if swimmer == null:
		push_warning("Fishing projectile must have a RigidBody3D root.")
		return
	cast_parent.add_child(swimmer)
	swimmer.global_transform = muzzle.global_transform
	swimmer.apply_central_impulse(-global_transform.basis.z * shoot_force)
	fishing_line = FishingLine.new()
	fishing_line.configure(muzzle, swimmer, fishing_line_length)
	cast_parent.add_child(fishing_line)
	is_casting = true
	_animate_rod(Vector3(-0.3, 0.0, 0.0))


func pull_fish() -> void:
	if not is_instance_valid(swimmer):
		is_casting = false
		return

	if swimmer.has_method("caught_something") and swimmer.call("caught_something"):
		var item := str(swimmer.call("catch_random_item"))
		if not item.is_empty():
			print("Caught: ", item)
	else:
		print("Nothing caught.")

	if swimmer.has_method("reel_in"):
		swimmer.call("reel_in", muzzle.global_position)
	else:
		swimmer.queue_free()
	swimmer = null
	fishing_line = null
	is_casting = false
	_animate_rod(Vector3(0.22, 0.0, 0.0))


func _animate_rod(rotation_offset: Vector3) -> void:
	if _animation_tween and _animation_tween.is_running():
		_animation_tween.kill()
	_animation_tween = create_tween()
	_animation_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_animation_tween.tween_property(self, "rotation", _rest_rotation + rotation_offset, 0.14)
	_animation_tween.tween_property(self, "rotation", _rest_rotation, 0.24)
