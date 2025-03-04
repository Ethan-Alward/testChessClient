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

	$Selected.visible = false
	
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
	
func setSelectSquareVis(isVisible):	
	if isVisible: 	
		$Selected.visible = true
	else:
		$Selected.visible = false

func setSquareColour(theBool):
	if theBool:
		$MeshInstance3D.material_override = preload("res://peice_meshs/selected_piece_material.tres")
	else:
		if isWhite:
			$MeshInstance3D.material_override = preload("res://white_square_material.tres")
		else:
			$MeshInstance3D.material_override = preload("res://black_square_material.tres")
