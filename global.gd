extends Node
var initial_piece_state = []

var piece_list = []

func translate(column, row):
	var x = -('a'.unicode_at(0)-column.unicode_at(0)+4) + 0.5
	var z = -(row-4) + 0.5
	return [x,z]

enum PIECE_TYPE {
	pawn,
	knight,
	bishop,
	rook,
	queen,
	king
}


var game_state = {
	'is_white_turn': true,
	'selected_piece': null,
	'player_color': null,
}

func check_square(notation):
	for i in range(Global.piece_list.size()):
		if Global.piece_list[i].is_on(notation):
			return Global.piece_list[i]
	return null

func compare_square_notations(notation_1, notation_2):
	if notation_1.column==notation_2.column and notation_1.row==notation_2.row:
		return true
	return false

func check_capture(notation):
	for i in range(Global.piece_list.size()):
		if Global.piece_list[i].is_on(notation):
			Global.piece_list[i].queue_free()
			Global.piece_list.remove_at(i)
			break

func deletePieces(): 
	for piece in piece_list: 
		#remove_child(piece)
		piece.queue_free()
	

# this is supposed to be retrieved in the handshake
func server_hand_shake():
	
	# initial state of the pieces
	initial_piece_state = []
	piece_list = []
	# pawns
	for i in range(8):
		initial_piece_state.append_array(
			[
				{
					'type': Global.PIECE_TYPE.pawn,
					'square': { 'column':char('a'.unicode_at(0)+i), 'row':2 },
					'is_white': true
				},
				{
					'type': Global.PIECE_TYPE.pawn,
					'square': { 'column':char('a'.unicode_at(0)+i), 'row':7 },
					'is_white': false
				}
			]
		)
	# white pieces
	initial_piece_state.append_array(
		[
			# Knights
			{
				'type': Global.PIECE_TYPE.knight,
				'square': { 'column':'b', 'row':1 },
				'is_white': true
			},
			{
				'type': Global.PIECE_TYPE.knight,
				'square': { 'column':'g', 'row':1 },
				'is_white': true
			},
			# Bishops
			{
				'type': Global.PIECE_TYPE.bishop,
				'square': { 'column':'c', 'row':1 },
				'is_white': true
			},
			{
				'type': Global.PIECE_TYPE.bishop,
				'square': { 'column':'f', 'row':1 },
				'is_white': true
			},
			# Rooks
			{
				'type': Global.PIECE_TYPE.rook,
				'square': { 'column':'a', 'row':1 },
				'is_white': true
			},
			{
				'type': Global.PIECE_TYPE.rook,
				'square': { 'column':'h', 'row':1 },
				'is_white': true
			},
			# Queen
			{
				'type': Global.PIECE_TYPE.queen,
				'square': { 'column':'d', 'row':1 },
				'is_white': true
			},
			# King
			{
				'type': Global.PIECE_TYPE.king,
				'square': { 'column':'e', 'row':1 },
				'is_white': true
			},
		]
	)
	# black pieces
	initial_piece_state.append_array(
		[
			# Knights
			{
				'type': Global.PIECE_TYPE.knight,
				'square': { 'column':'b', 'row':8 },
				'is_white': false
			},
			{
				'type': Global.PIECE_TYPE.knight,
				'square': { 'column':'g', 'row':8 },
				'is_white': false
			},
			# Bishops
			{
				'type': Global.PIECE_TYPE.bishop,
				'square': { 'column':'c', 'row':8 },
				'is_white': false
			},
			{
				'type': Global.PIECE_TYPE.bishop,
				'square': { 'column':'f', 'row':8 },
				'is_white': false
			},
			# Rooks
			{
				'type': Global.PIECE_TYPE.rook,
				'square': { 'column':'a', 'row':8 },
				'is_white': false
			},
			{
				'type': Global.PIECE_TYPE.rook,
				'square': { 'column':'h', 'row':8 },
				'is_white': false
			},
			# Queen
			{
				'type': Global.PIECE_TYPE.queen,
				'square': { 'column':'d', 'row':8 },
				'is_white': false
			},
			# King
			{
				'type': Global.PIECE_TYPE.king,
				'square': { 'column':'e', 'row':8 },
				'is_white': false
			},
		]
	)
	print(initial_piece_state)
