extends Node3D

@export var is_light: bool
@export var outline_material: Material

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#var direction = Vector3(1, 0, 0)
	#print("printing get children", get_children())
	for child in get_children():
		if is_light:
			outline_material = preload(("res://outline/white_outline.tres"))
			child.material_override = preload("res://peice_meshs/white_piece_material.tres")
			child.rotation_degrees.y -= 90
			#outline_material.set_shader_parameter("outline_color", Color(255 / 255.0, 81 / 255.0, 0 / 255.0))
			outline_material.set_shader_parameter("outline_color", Color(0,0,0))
		else:
			outline_material = preload(("res://outline/black_outline.tres"))
			child.material_override = preload("res://peice_meshs/black_piece_material.tres")
			child.rotation_degrees.y += 90
			outline_material.set_shader_parameter("outline_color", Color(255, 255, 255))
		child.material_overlay = outline_material
	outline_material.set_shader_parameter("outline_width", 1)
		
		
	#print("end of mesh.gd for loop")
