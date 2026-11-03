@tool
extends Node3D
class_name WaterEntity

const WATER_MATERIAL: ShaderMaterial = preload("res://materials/water.tres")


func _ready() -> void:
	call_deferred("_apply_water_material")


func _apply_water_material() -> void:
	_apply_to_node(self)


func _apply_to_node(node: Node) -> void:
	if node is MeshInstance3D:
		node.material_override = WATER_MATERIAL
	for child in node.get_children():
		_apply_to_node(child)
