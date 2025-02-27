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

	outline_material = ShaderMaterial.new()
	
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
	#print("in change square colour")
	
	$MeshInstance3D.material_override = load("res://peice_meshs/selected_piece_material.tres")
	#$WorldEnvironment.environment.glow_enabled = true
	#$WorldEnvironment.environment.glow_intensity = 1.5
	#$WorldEnvironment.environment.glow_threshold = 0.25
	#outline_material = StandardMaterial3D.new()
	#outline_material.albedo_color = Color(0.5, 0.5, 0.5)
	#outline_material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	#outline_material.emission =  Color(1, 0.5, 0.5)
	#outline_material.emission_energy = 2
	#outline_material.shader = load("res://outline/square_border.gdshader")
	#
	#for child in get_children():
		#child.material_overlay = outline_material

func backToOriginalColor():
	#print("in back to original")
	$WorldEnvironment.environment.glow.enabled = false
	if isWhite:
		$MeshInstance3D.material_override = preload("res://white_square_material.tres")
		#for child in get_children():
			#child.material_overlay = null

	else:
		$MeshInstance3D.material_override = preload("res://black_square_material.tres")
		#for child in get_children():
			#child.material_overlay = null
		#
		
