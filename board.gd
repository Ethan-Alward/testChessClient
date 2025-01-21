extends Node3D

@export var square_template: PackedScene

func start():
	# Generate the board
	var isStartLight = false
	for col in 8:
		var column = char(col+97)
		var isLight = isStartLight
		for r in 8:
			var row = r+1
			var s = square_template.instantiate()
			s.isWhite = isLight
			var coor = Global.translate(column,row)
			s.position.x = coor[0]
			s.position.z = coor[1]
			s.set_notation(column,row)
			isLight = !isLight
			add_child(s)
		isStartLight = !isStartLight
