extends Node3D
class_name FishingLine

@export_range(6, 64, 1) var particle_count: int = 24
@export_range(1, 24, 1) var constraint_iterations: int = 10
@export_range(0.0, 0.1, 0.001) var line_radius: float = 0.008
@export_range(0.0, 1.0, 0.01) var damping: float = 0.015
@export_flags_3d_physics var collision_mask: int = 1
@export var gravity: Vector3 = Vector3(0.0, -9.8, 0.0)

var _anchor: Node3D
var _bait: RigidBody3D
var _line_length: float = 30.0
var _positions: Array[Vector3] = []
var _previous_positions: Array[Vector3] = []
var _line_mesh := ImmediateMesh.new()
var _line_instance: MeshInstance3D
var _line_material: StandardMaterial3D
var _initialized: bool = false


func configure(anchor: Node3D, bait: RigidBody3D, line_length: float) -> void:
	_anchor = anchor
	_bait = bait
	_line_length = maxf(line_length, 0.1)


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	_line_instance = MeshInstance3D.new()
	_line_material = StandardMaterial3D.new()
	_line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_line_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_line_material.albedo_color = Color(0.83, 0.8, 0.68)
	_line_instance.mesh = _line_mesh
	_line_instance.material_override = _line_material
	add_child(_line_instance)

	if not is_instance_valid(_anchor) or not is_instance_valid(_bait):
		queue_free()
		return

	_initialize_points()
	if _bait.has_method("attach_fishing_line"):
		_bait.call("attach_fishing_line", _anchor, _line_length, self)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_anchor) or not is_instance_valid(_bait):
		queue_free()
		return
	if not _initialized:
		_initialize_points()
		return

	var anchor_position := _anchor.global_position
	var bait_position := _bait.global_position
	_positions[0] = anchor_position
	_positions[particle_count - 1] = bait_position

	var dt_squared := delta * delta
	for i in range(1, particle_count - 1):
		var current := _positions[i]
		var velocity := (current - _previous_positions[i]) * (1.0 - damping)
		_previous_positions[i] = current
		_positions[i] = current + velocity + gravity * dt_squared
		_resolve_particle_collision(i)

	var segment_length := _line_length / float(particle_count - 1)
	for _iteration in range(constraint_iterations):
		_positions[0] = anchor_position
		_positions[particle_count - 1] = bait_position
		for i in range(particle_count - 1):
			var offset := _positions[i + 1] - _positions[i]
			var distance := offset.length()
			if distance <= segment_length or is_zero_approx(distance):
				continue
			var correction := offset * ((distance - segment_length) / distance)
			if i == 0:
				_positions[i + 1] -= correction
			elif i + 1 == particle_count - 1:
				_positions[i] += correction
			else:
				_positions[i] += correction * 0.5
				_positions[i + 1] -= correction * 0.5

	_positions[0] = anchor_position
	_positions[particle_count - 1] = bait_position
	_update_line_mesh()


func _initialize_points() -> void:
	if not is_instance_valid(_anchor) or not is_instance_valid(_bait):
		return
	_positions.clear()
	_previous_positions.clear()
	for i in range(particle_count):
		var point := _anchor.global_position.lerp(_bait.global_position, float(i) / float(particle_count - 1))
		_positions.append(point)
		_previous_positions.append(point)
	_initialized = true
	_update_line_mesh()


func _resolve_particle_collision(index: int) -> void:
	if collision_mask == 0:
		return
	var from := _previous_positions[index]
	var to := _positions[index]
	if from.is_equal_approx(to):
		return

	var query := PhysicsRayQueryParameters3D.create(from, to, collision_mask)
	query.exclude = _get_excluded_rids()
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return

	var normal: Vector3 = hit.normal
	var contact: Vector3 = hit.position + normal * line_radius
	var tangent_motion := (to - from).slide(normal) * (1.0 - damping)
	_positions[index] = contact
	_previous_positions[index] = contact - tangent_motion


func _get_excluded_rids() -> Array[RID]:
	var excluded: Array[RID] = []
	if is_instance_valid(_bait):
		excluded.append(_bait.get_rid())

	var ancestor: Node = _anchor
	while ancestor:
		if ancestor is CollisionObject3D:
			excluded.append((ancestor as CollisionObject3D).get_rid())
			break
		ancestor = ancestor.get_parent()
	return excluded


func _update_line_mesh() -> void:
	if _positions.size() < 2 or not _line_instance:
		return
	var camera := get_viewport().get_camera_3d()
	_line_mesh.clear_surfaces()
	_line_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, _line_material)
	for i in range(_positions.size()):
		var tangent := (_positions[mini(i + 1, _positions.size() - 1)] - _positions[maxi(i - 1, 0)]).normalized()
		var view_direction := Vector3.UP
		if camera:
			view_direction = (camera.global_position - _positions[i]).normalized()
		var side := tangent.cross(view_direction).normalized()
		if side.is_zero_approx():
			side = tangent.cross(Vector3.RIGHT).normalized()
		if side.is_zero_approx():
			side = Vector3.FORWARD
		var offset := side * line_radius
		_line_mesh.surface_add_vertex(to_local(_positions[i] - offset))
		_line_mesh.surface_add_vertex(to_local(_positions[i] + offset))
	_line_mesh.surface_end()


func _exit_tree() -> void:
	if is_instance_valid(_bait) and _bait.has_method("detach_fishing_line"):
		_bait.call("detach_fishing_line", self)
