extends RigidBody3D

@export_range(1, 120, 1) var catchtimeMinInSec: int = 5
@export_range(1, 120, 1) var catchtimeMaxInSec: int = 30
@export var lootTable: LootTable

var isInWater: bool = false
var gotSomething: bool = false
var catchEffect: CPUParticles3D
var _water_bodies: Array[Node] = []
var _catch_token: int = 0
var _fishing_line_anchor: Node3D
var _fishing_line_owner: Node
var _fishing_line_length: float = 0.0
var _last_anchor_position: Vector3


func _ready() -> void:
	catchEffect = get_node_or_null("CatchEffect") as CPUParticles3D


func attach_fishing_line(anchor: Node3D, line_length: float, line_owner: Node = null) -> void:
	_fishing_line_anchor = anchor
	_fishing_line_owner = line_owner
	_fishing_line_length = maxf(line_length, 0.1)
	if is_instance_valid(anchor):
		_last_anchor_position = anchor.global_position


func detach_fishing_line(line_owner: Node = null) -> void:
	if line_owner != null and line_owner != _fishing_line_owner:
		return
	_fishing_line_anchor = null
	_fishing_line_owner = null
	_fishing_line_length = 0.0


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if not is_instance_valid(_fishing_line_anchor) or _fishing_line_length <= 0.0:
		return

	var anchor_position := _fishing_line_anchor.global_position
	var anchor_velocity := (anchor_position - _last_anchor_position) / maxf(state.step, 0.0001)
	_last_anchor_position = anchor_position
	var offset := state.transform.origin - anchor_position
	var distance := offset.length()
	if distance <= _fishing_line_length or is_zero_approx(distance):
		return

	var rope_direction := offset / distance
	state.transform.origin = anchor_position + rope_direction * _fishing_line_length
	var outward_speed := (state.linear_velocity - anchor_velocity).dot(rope_direction)
	if outward_speed > 0.0:
		state.linear_velocity -= rope_direction * outward_speed


func caught_something() -> bool:
	return gotSomething


func catch_random_item() -> String:
	if not gotSomething or lootTable == null:
		return ""
	return lootTable.get_random_item()


func reel_in(target_position: Vector3, duration: float = 0.35) -> void:
	detach_fishing_line()
	_water_bodies.clear()
	isInWater = false
	gotSomething = false
	_catch_token += 1
	if catchEffect:
		catchEffect.emitting = false
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "global_position", target_position, duration)
	tween.finished.connect(queue_free)


func remove() -> void:
	queue_free()


func _on_body_entered(body: Node) -> void:
	if not _is_water(body) or _water_bodies.has(body):
		return
	_water_bodies.append(body)
	if _water_bodies.size() == 1:
		isInWater = true
		_start_catch_timer()


func _on_body_exited(body: Node) -> void:
	if not _is_water(body) or not _water_bodies.has(body):
		return
	_water_bodies.erase(body)
	if _water_bodies.is_empty():
		isInWater = false
		gotSomething = false
		_catch_token += 1
		if catchEffect:
			catchEffect.emitting = false


func _is_water(body: Node) -> bool:
	return body.is_in_group("Water") or body.name.to_lower().contains("water")


func _start_catch_timer() -> void:
	_catch_token += 1
	var token := _catch_token
	var min_time := mini(catchtimeMinInSec, catchtimeMaxInSec)
	var max_time := maxi(catchtimeMinInSec, catchtimeMaxInSec)
	var wait_time := randf_range(float(min_time), float(max_time))
	await get_tree().create_timer(wait_time).timeout
	if not is_inside_tree() or token != _catch_token or not isInWater:
		return
	gotSomething = true
	if catchEffect:
		catchEffect.emitting = true
