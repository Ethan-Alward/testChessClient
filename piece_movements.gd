extends Node

func pawn(is_white, curr_notation, num_moves):
	var direction = 1
	if !is_white:
		direction = -1
	var col = curr_notation.column.unicode_at(0)
	var r = curr_notation.row
	var squares = []
	# the square in front of the pawn
	var notation = { 'column':String.chr(col), 'row':r+direction*1 }
	var piece = Global.check_square(notation)
	if !piece:
		squares.push_front(notation)
	
		#the first move can go up to another row
		if num_moves==0:
			notation = { 'column':String.chr(col), 'row':r+direction*2 }
			piece = Global.check_square(notation)
			if !piece:
				squares.push_front(notation)
	
	# the two squares where the pawn goes to capture things
	var a = 1
	for i in range(2):
		notation = { 'column':String.chr(col+a), 'row':r+direction*1 }
		piece = Global.check_square(notation)
		if piece and piece.is_white != is_white:
			squares.push_front(notation)
		a = -1
		
	return squares

func collect_straight_moves(is_white, start_notation, directions):
	var result = []
	var start_col = start_notation.column.unicode_at(0)
	var start_row = start_notation.row
	for dir in directions:
		var col = start_col
		var row = start_row
		while true:
			col += dir.x
			row += dir.y
			if col < 'a'.unicode_at(0) or col > 'h'.unicode_at(0) or row < 1 or row > 8:
				break
			var next_notation = { 'column': String.chr(col), 'row': row }
			var piece = Global.check_square(next_notation)
			if piece:
				if piece.is_white != is_white:
					result.push_back(next_notation)
				break
			else:
				result.push_back(next_notation)
				
	#print("result: ", result)
	return result

func knight(is_white, curr_notation):
	var moves = []
	var offsets = [
		Vector2(2, 1), Vector2(2, -1), Vector2(-2, 1), Vector2(-2, -1),
		Vector2(1, 2), Vector2(1, -2), Vector2(-1, 2), Vector2(-1, -2)
	]
	var col_start = curr_notation.column.unicode_at(0)
	var row_start = curr_notation.row
	for offset in offsets:
		var col = col_start + int(offset.x)
		var row = row_start + int(offset.y)
		if col >= 'a'.unicode_at(0) and col <= 'h'.unicode_at(0) and row >= 1 and row <= 8:
			var check_notation = { 'column': String.chr(col), 'row': row }
			var piece = Global.check_square(check_notation)
			if !piece or (piece.is_white != is_white):
				moves.push_back(check_notation)
	return moves

func bishop(is_white, curr_notation):
	var directions = [
		Vector2(1, 1), Vector2(1, -1),
		Vector2(-1, 1), Vector2(-1, -1)
	]
	return collect_straight_moves(is_white, curr_notation, directions)

func rook(is_white, curr_notation):
	var directions = [
		Vector2(1, 0), Vector2(-1, 0),
		Vector2(0, 1), Vector2(0, -1)
	]
	return collect_straight_moves(is_white, curr_notation, directions)

func queen(is_white, curr_notation):
	var directions = [
		Vector2(1, 0), Vector2(-1, 0),
		Vector2(0, 1), Vector2(0, -1),
		Vector2(1, 1), Vector2(1, -1),
		Vector2(-1, 1), Vector2(-1, -1)
	]
	return collect_straight_moves(is_white, curr_notation, directions)

func king(is_white, curr_notation):
	var moves = []
	var directions = [
		Vector2(1, 0), Vector2(-1, 0),
		Vector2(0, 1), Vector2(0, -1),
		Vector2(1, 1), Vector2(1, -1),
		Vector2(-1, 1), Vector2(-1, -1)
	]
	var col_start = curr_notation.column.unicode_at(0)
	var row_start = curr_notation.row
	for dir in directions:
		var col = col_start + dir.x
		var row = row_start + dir.y
		if col < 'a'.unicode_at(0) or col > 'h'.unicode_at(0) or row < 1 or row > 8:
			continue
		var check_notation = { 'column': String.chr(col), 'row': row }
		var piece = Global.check_square(check_notation)
		if !piece or (piece.is_white != is_white):
			moves.push_back(check_notation)
	
	#print("king moves: ", moves)
	#update kings moves to remove any squares opponent pieces are attacking
	for piece in Global.piece_list:
		if piece.is_white != is_white: #opps pieces
			for move in piece.legal_moves: 
				for myKingsMoves in moves: 
					if move.column == myKingsMoves.column and move.row == myKingsMoves.row: 
						moves.erase(myKingsMoves) #if my kings legal move is attacked by one of their pieces delete it as a legal move
		
	var isPieceNearKing = false
	var thePieceNearKing

	#remove the ability to capture a defended opponent's piece
	for oppsPiece in Global.piece_list:
		if oppsPiece.is_white != is_white: #opps pieces
			for myKingsMoves in moves: 
				if oppsPiece.square.column == myKingsMoves.column and oppsPiece.square.row == myKingsMoves.row: 
				 	#if opps piece is on a square my king can capture check if the piece is defended
					#check if any opps pieces have an attackable square that matches this opps square
						#this changes based on piece type
						#check if pawns, knights, or king's legal move is that square 
						#if they do remove the move from my king's moves
					isPieceNearKing = true
					thePieceNearKing = oppsPiece
					print(thePieceNearKing.pieceInfo())
	
					
	if isPieceNearKing: #verify that this piece is being defended if it is delete that oppsPece.square from kings legal moves. 
		for oppsPiece in Global.piece_list:
			if oppsPiece.is_white != is_white: #opps pieces
				for oppsPieceMove in oppsPiece.attackable_squares:
					#check all opps pieces has an attackable_square that matches thePieceNearKing.sqaure
					if oppsPieceMove.row == thePieceNearKing.square.row and oppsPieceMove.column == thePieceNearKing.square.column:
						#if they do check that there are no pieces between them 
							#only needed for bishops queens and rooks because nothing can block a kinght,pawn, or king's defense 
						if oppsPiece.type == Global.PIECE_TYPE.queen or oppsPiece.type == Global.PIECE_TYPE.bishop or oppsPiece.type == Global.PIECE_TYPE.rook:
							oppsPiece.get_squares_to_king(curr_notation)
							
							print("opps piece info: ", oppsPiece.pieceInfo())
							print(oppsPiece.squares_to_king)
							
							var piecesBetweenKing = 0
							for square in oppsPiece.squares_to_king:
								for piece in Global.piece_list:
										if piece.square.row == square.row and piece.square.column == square.column:
											piecesBetweenKing += 1
							if piecesBetweenKing == 0: 
								print("apparently theres a piece between")
								for move in moves:
									if move.column == thePieceNearKing.square.column and move.row == thePieceNearKing.square.row:
										moves.erase(move) #piece is defended
								
						#piece is defended by a pawn, knight, or king					
						else:
							for move in moves:
									if move.column == thePieceNearKing.square.column and move.row == thePieceNearKing.square.row:
										moves.erase(move) #piece is defended
							#moves.erase(thePieceNearKing.square)  #piece is defended
								
										
						
	#print("king moves without opps attack mvoes: ", moves)
	return moves


#will return attackable squares, used for pin logic
#example the rook's initial attackable squares should be every square in it's row and column 
#primarily used for bishops, queens, and rooks



func bishopA(is_white, curr_notation):
	var directions = [
		Vector2(1, 1), Vector2(1, -1),
		Vector2(-1, 1), Vector2(-1, -1)
	]
	return collect_attackable_squares(is_white, curr_notation, directions)

func rookA(is_white, curr_notation):
	var directions = [
		Vector2(1, 0), Vector2(-1, 0),
		Vector2(0, 1), Vector2(0, -1)
	]
	return collect_attackable_squares(is_white, curr_notation, directions)

func queenA(is_white, curr_notation):
	var directions = [
		Vector2(1, 0), Vector2(-1, 0),
		Vector2(0, 1), Vector2(0, -1),
		Vector2(1, 1), Vector2(1, -1),
		Vector2(-1, 1), Vector2(-1, -1)
	]
	return collect_attackable_squares(is_white, curr_notation, directions)
	

func pawnA(is_white, curr_notation):
	var direction = 1
	if !is_white:
		direction = -1
	var col = curr_notation.column.unicode_at(0)
	var r = curr_notation.row
	var squares = []
	## the square in front of the pawn
	var notation = { 'column':String.chr(col), 'row':r+direction*1 }
	var piece = Global.check_square(notation)

	var a = 1
	for i in range(2):
		notation = { 'column':String.chr(col+a), 'row':r+direction*1 }
		piece = Global.check_square(notation)
		if piece and piece.is_white != is_white:
			squares.push_front(notation)
		a = -1
		
	return squares

func kingA(curr_notation):
	var moves = []
	var directions = [
		Vector2(1, 0), Vector2(-1, 0),
		Vector2(0, 1), Vector2(0, -1),
		Vector2(1, 1), Vector2(1, -1),
		Vector2(-1, 1), Vector2(-1, -1)
	]
	var col_start = curr_notation.column.unicode_at(0)
	var row_start = curr_notation.row
	for dir in directions:
		var col = col_start + dir.x
		var row = row_start + dir.y
		if col < 'a'.unicode_at(0) or col > 'h'.unicode_at(0) or row < 1 or row > 8:
			continue
		var check_notation = { 'column': String.chr(col), 'row': row }
		moves.push_back(check_notation)
			
	return moves

func collect_attackable_squares(_is_white, start_notation, directions):
	var result = []
	var start_col = start_notation.column.unicode_at(0)
	var start_row = start_notation.row
	for dir in directions:
		var col = start_col
		var row = start_row
		while true:
			col += dir.x
			row += dir.y
			if col < 'a'.unicode_at(0) or col > 'h'.unicode_at(0) or row < 1 or row > 8:
				break
			var next_notation = { 'column': String.chr(col), 'row': row }
			result.push_back(next_notation)
				
	#print("result: ", result)
	return result
	
	
	
	
func bishopK(is_white, curr_notation, squareKingIsOn):
	var directions = [
		Vector2(1, 1), Vector2(1, -1),
		Vector2(-1, 1), Vector2(-1, -1)
	]
	return collect_squares_to_king(is_white, curr_notation, directions, squareKingIsOn)

func rookK(is_white, curr_notation,squareKingIsOn):
	var directions = [
		Vector2(1, 0), Vector2(-1, 0),
		Vector2(0, 1), Vector2(0, -1)
	]
	return collect_squares_to_king(is_white, curr_notation, directions, squareKingIsOn)

func queenK(is_white, curr_notation, squareKingIsOn):
	var directions = [
		Vector2(1, 0), Vector2(-1, 0),
		Vector2(0, 1), Vector2(0, -1),
		Vector2(1, 1), Vector2(1, -1),
		Vector2(-1, 1), Vector2(-1, -1)
	]
	return collect_squares_to_king(is_white, curr_notation, directions, squareKingIsOn)

func collect_squares_to_king(_is_white, start_notation, directions, squareKingIsOn):
	var tempResult = []
	var result = []
	var start_col = start_notation.column.unicode_at(0)
	var start_row = start_notation.row
	for dir in directions:
		var col = start_col
		var row = start_row
		while true:
			col += dir.x
			row += dir.y
			if col < 'a'.unicode_at(0) or col > 'h'.unicode_at(0) or row < 1 or row > 8:
				break				
			var next_notation = { 'column': String.chr(col), 'row': row }
			tempResult.push_back(next_notation)
		
		#return only the squares between the king and the piece
		#print("square king is on: " , squareKingIsOn)
		#print("squares to king: ", tempResult)
		#print(result.has(squareKingIsOn))
		
		for square in tempResult: 
			if square.column == squareKingIsOn.column and square.row == squareKingIsOn.row:
				tempResult.erase(square)
				#print("correct result: ", tempResult)
				result = tempResult
				break
				
		
		#if code reaches here reset the result 
		tempResult = []

	return result
