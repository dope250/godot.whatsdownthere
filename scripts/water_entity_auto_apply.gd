extends Node

const WATER_MATERIAL: ShaderMaterial = preload("res://materials/water.tres")


func _enter_tree() -> void:
	get_tree().node_added.connect(_on_node_added)


func _ready() -> void:
	_scan_tree(get_tree().root)


func _on_node_added(node: Node) -> void:
	if _is_water_entity(node):
		call_deferred("_apply_to_entity", node)
	elif node is MeshInstance3D:
		var ancestor := node.get_parent()
		while ancestor != null:
			if _is_water_entity(ancestor):
				_apply_to_mesh(node)
				return
			ancestor = ancestor.get_parent()


func _scan_tree(node: Node) -> void:
	if _is_water_entity(node):
		_apply_to_entity(node)
	for child in node.get_children():
		_scan_tree(child)


func _apply_to_entity(entity: Node) -> void:
	if not is_instance_valid(entity):
		return
	_apply_to_node(entity)


func _apply_to_node(node: Node) -> void:
	if node is MeshInstance3D:
		_apply_to_mesh(node)
	for child in node.get_children():
		_apply_to_node(child)


func _apply_to_mesh(mesh_instance: MeshInstance3D) -> void:
	mesh_instance.material_override = WATER_MATERIAL


func _is_water_entity(node: Node) -> bool:
	if node.is_in_group("water"):
		return true
	var entity_name := String(node.name).to_lower()
	return entity_name == "water" or entity_name.ends_with("_water") or entity_name.begins_with("water_")
