extends Node3D

@export var type: Global.PIECE_TYPE
@export var is_white: bool

var piece_mesh
var legal_moves = []
var attackable_squares = []
var squares_to_king = []
var mesh
var num_moves

var square = {
	'column': '',
	'row': -1
}



func pieceInfo(): 	
	return {'type': type, 'square': square, 'is_white': is_white, 'num_moves': num_moves}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#print("in piece.gd ready")
	num_moves = 0
	
	match type:
		Global.PIECE_TYPE.pawn:
			piece_mesh = load("res://peice_meshs/pawn_mesh.tscn")
		Global.PIECE_TYPE.knight:
			piece_mesh = load("res://peice_meshs/knight_mesh.tscn")
		Global.PIECE_TYPE.bishop:
			piece_mesh = load("res://peice_meshs/bishop_mesh.tscn")
		Global.PIECE_TYPE.rook:
			piece_mesh = load("res://peice_meshs/rook_mesh.tscn")
		Global.PIECE_TYPE.queen:
			piece_mesh = load("res://peice_meshs/queen_mesh.tscn")
		Global.PIECE_TYPE.king:
			piece_mesh = load("res://peice_meshs/king_mesh.tscn")
	mesh = piece_mesh.instantiate()
	mesh.is_light = is_white
	add_child(mesh)
	#print("finished piece.gd ready")

func move_to(notation):
	num_moves = 1 #piece has moved
	Global.check_capture(notation)
	set_square(notation)
	#Global.game_state.is_white_turn = !Global.game_state.is_white_turn

func set_square(notation):
	square.column = notation.column
	square.row = notation.row
	update_position()

func update_position():
	var pos = Global.translate(square.column, square.row)
	position.x = pos[0]
	position.z = pos[1]

func is_on(notation):
	return Global.compare_square_notations(square, notation)
	
#legal piece moves, based on how pieces move. NOT RESTRICTED by pieces around them except the king function
func get_legal_moves():
	#print(square)
	match type:
		Global.PIECE_TYPE.pawn:
			legal_moves = PieceMovements.pawn(is_white, square, num_moves)
		Global.PIECE_TYPE.knight:
			legal_moves = PieceMovements.knight(is_white, square)
		Global.PIECE_TYPE.bishop:
			legal_moves = PieceMovements.bishop(is_white, square)
		Global.PIECE_TYPE.rook:
			legal_moves = PieceMovements.rook(is_white, square)
		Global.PIECE_TYPE.queen:
			legal_moves = PieceMovements.queen(is_white, square)
		Global.PIECE_TYPE.king:
			legal_moves = PieceMovements.king(is_white, square)


#more like defendable squares
func get_attackable_squares(): 
	match type:		
		#pawns can only attack/defend diagnol
		Global.PIECE_TYPE.pawn:
			attackable_squares = PieceMovements.pawnA(is_white, square)			
			
		#can see the whole board
		Global.PIECE_TYPE.bishop:
			attackable_squares = PieceMovements.bishopA(is_white, square)
		Global.PIECE_TYPE.rook:
			attackable_squares = PieceMovements.rookA(is_white, square)
		Global.PIECE_TYPE.queen:
			attackable_squares = PieceMovements.queenA(is_white, square)
			
		#king and knight's attackable/defendable squares are simply they're legal move squares
		Global.PIECE_TYPE.knight:
			attackable_squares = PieceMovements.knight(is_white, square)	
		
		Global.PIECE_TYPE.king:
			attackable_squares = PieceMovements.kingA(square) #little different because we restrict king's legal moves in king function

#returns the squares the long range pieces "sees" 
func get_squares_to_king(squareKingIsOn): 
	match type:		
		Global.PIECE_TYPE.bishop:
			squares_to_king = PieceMovements.bishopK(is_white, square, squareKingIsOn)
		Global.PIECE_TYPE.rook:
			squares_to_king = PieceMovements.rookK(is_white, square, squareKingIsOn)
		Global.PIECE_TYPE.queen:
			squares_to_king = PieceMovements.queenK(is_white, square, squareKingIsOn)
			
		#other pieces can't be blocked so return [] 
		Global.PIECE_TYPE.pawn:
				squares_to_king = []
		Global.PIECE_TYPE.knight:
				squares_to_king = []
		Global.PIECE_TYPE.king:
				squares_to_king = []
