extends Node3D

@export var isWhite: bool
var outline_material

var notation = {
	"column": "",
	"row": -1
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("square")
	#outline_material = preload(("res://outline/black_outline.tres"))
	
	if isWhite:
		$MeshInstance3D.material_override = preload("res://white_square_material.tres")
	else:
		$MeshInstance3D.material_override = preload("res://black_square_material.tres")


func set_notation(col, r):
	notation.column = col
	notation.row = r

func print_notation():
	print(notation.column, notation.row)

func get_notation():
	return notation
	
func changeSquareColor(): 
	print("in change square colour")
	
	$MeshInstance3D.material_override = load("res://peice_meshs/selected_piece_material.tres")
	#outline_material.set_shader_parameter("outline_color", Color(0 / 255.0, 89 / 255.0, 255 / 255.0))
	#outline_material.set_shader_parameter("outline_width", 2)
	#$MeshInstance3D.material_overlay = outline_material

func backToOriginalColor():
	#print("in back to original")
	if isWhite:
		$MeshInstance3D.material_override = preload("res://white_square_material.tres")
		#outline_material.set_shader_parameter("outline_color", Color(255.0, 255.0, 255.0))
		#$MeshInstance3D.material_overlay = outline_material
		
	else:
		$MeshInstance3D.material_override = preload("res://black_square_material.tres")
		#outline_material.set_shader_parameter("outline_color", Color(0,0,0))
		#$MeshInstance3D.material_overlay = outline_material
		
		
