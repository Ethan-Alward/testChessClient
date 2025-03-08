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
				var index = tempResult.find(square)
				tempResult = tempResult.slice(0, index)
				#print("correct result: ", tempResult)
				result = tempResult
				return result
				
		
		#if code reaches here reset the result 
		tempResult = []

	#code shouldn't reach here
	return result
	
	
	
	
