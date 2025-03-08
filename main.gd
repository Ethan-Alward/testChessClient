extends Node3D

@export var piece_template : PackedScene
var rayOrigin = Vector3()
var rayEnd = Vector3()

var multiplayer_peer 
var ip
const PORT = 9010

#Game Data
var code 
var myID 
var oppId 
var oppName
var iAmWhitePieces
var myTurn

var theUsername


var squareImOn
var squareClicked
var pieceOnSquare

var homepage 
var inGame

var gameControls
var codeLabel
var oppLabel
var myPiecesLabel
var leaveButton


var wantsToWatch

var currentlySelectedPiece
var selectedPieceOrigColour

var inCheck
var myKingsPos
var kingRookPieceInfo
var queenRookPieceInfo
var checkmate
var firstMoveMade
var backRank

var gameTime

# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	checkmate = false
	inCheck = false
	code = 0
	myID = 0
	oppId = 0
	

	
	
	print("Connecting To Server ...")	
	multiplayer_peer = ENetMultiplayerPeer.new()
	ip = "127.0.0.1"
	#ip = "ec2-18-224-56-186.us-east-2.compute.amazonaws.com"	
	multiplayer_peer.create_client(ip, PORT)	
	multiplayer.multiplayer_peer = multiplayer_peer
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	
	myID = multiplayer_peer.get_unique_id()
	print("My userId is ", myID)
	
	inGame = false
	wantsToWatch = false
	
	homepage = $Homepage
	homepage.connect("joinGame", joinTheGame.bind())
	homepage.connect("newGame", newGame.bind())
	homepage.connect("theUsername", theUsernamePasser.bind())
	homepage.connect("time", setGameTime.bind())

	
	#homepage.newGame.connect(newGame.bind())
	
	GameControlsVisible(false)
	loadingScreenVisible(false)
	
	
	

func joinTheGame(gameCode):
	wantsToWatch = false
	joinGame.rpc(myID, gameCode, theUsername, wantsToWatch)	
	code = int(gameCode)
	


func newGame(): 	
	print("NEW GAME")
	rpc_id(1, "createNewGame", myID, theUsername, gameTime)



@rpc("any_peer")
func getCode(gameCode):
	code = gameCode
	print(code)
	$GameControls/PanelContainer/VBoxContainer/CodeLabel.text = "Code: %s" %code 
	$LoadingScreen/PanelContainer/VBoxContainer/Label.text = "Code: %s" %code
	
@rpc("any_peer")
func loadingScreen():
	loadingScreenVisible(true)
	


@rpc
func startGame(): 	
	print("game started from server call")
	
	loadingScreenVisible(false)
	$Start.play()
	
	inGame = true
	firstMoveMade = false

	
	$GameControls/PanelContainer/VBoxContainer/HBoxContainer/MyNameLabel.text = theUsername
	#set up board
	#print("start of server handshake")
	Global.server_hand_shake()
	#print("end of server handshake")
	#print("start of board start")
	get_node("board").start()
	#print("end of board start")
	
	for p in Global.initial_piece_state:
		#print("adding piece to piece_list")
		var piece = piece_template.instantiate()
		#print("setting piece type")
		piece.type =  p.type
		piece.is_white = p.is_white
		piece.set_square(p.square)
		Global.piece_list.push_front(piece)
		add_child(piece)
		#print("piece add as child")
	
	GameControlsVisible(true)
	
	if !iAmWhitePieces:
		$Camera3D.position.z = -7.564
		$Camera3D.rotate_y(deg_to_rad(180))

	
	flipTimers()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	if inGame && myTurn:	
		
		# ray casting
		if Input.is_action_just_pressed("click"):
			var space_state = get_world_3d().direct_space_state
			var mouse_position = get_viewport().get_mouse_position()
			rayOrigin = $Camera3D.project_ray_origin(mouse_position)
			rayEnd = rayOrigin + $Camera3D.project_ray_normal(mouse_position) * 1000
			var ray_query = PhysicsRayQueryParameters3D.create(rayOrigin, rayEnd)
			var intersection = space_state.intersect_ray(ray_query)
			
			#when a square has been cliked on
			if intersection:
				squareClicked = intersection["collider"].get_parent().get_parent()				
				if squareClicked.is_in_group("square"): # if is a square					
					#check if square clicked has a piece on it 
					pieceOnSquare = Global.check_square(squareClicked.get_notation())		
				
					#if there is a piece on it
					if pieceOnSquare:		
						#print(pieceOnSquare.pieceInfo())
						
								
						#if it is my coloured piece, set it to the selected piece
						if pieceOnSquare.is_white == iAmWhitePieces:						
							
							if Global.game_state.selected_piece != null:
								clearPotentialMoveColors()

							#pieceOnSquare.get_legal_moves()
							Global.game_state.selected_piece = pieceOnSquare	
							if firstMoveMade == false: 
								Global.game_state.selected_piece.get_legal_moves()
							
							setPotentialMoveColors()

							
						else: #not my coloured piece
							#if it is a legal move capture the piece
							if Global.game_state.selected_piece != null: 
								makeMove()
							
					else: #there is no piece on the square			
						if Global.game_state.selected_piece != null: 
							makeMove()


		


func is_legal(square, legal_moves):
	for m in legal_moves:
		if Global.compare_square_notations(m, square):
			return true
	return false

func checkMate():
	print("checkmate")
	inGame = false
	$myTimer.stop()
	$oppsTimer.stop()	
	$EndGameDisplay/PanelContainer/VBoxContainer/Label.text = "You have been Checkmated"	
	endGameDisplayVisible(true)
	rpc_id(1, "sendOppTheyWon", myID, code)
	
	#Send signal to server saying you won! 
	
@rpc("any_peer") #when server runs this it makes the opponents move appear on your screen
func sendOppTheyWon():	
	$EndGameDisplay/PanelContainer/VBoxContainer/Label.text = "You have Checkmated your Opponent"
	endGameDisplayVisible(true)

func updateGameState(squareImGoingTo, pieceInfo): 
	#update every legal_move and attackable squares for every piece on the board 
	#update opponent's legal_moves first so a change doesn't break my pieces legal moves
	
	#if en passant just happened delete the pawn that got captured
	deleteIfEnPassant(squareImGoingTo, pieceInfo)	
	checkIfRookNeedsToBeCastled(squareImGoingTo, pieceInfo)
	checkPromotion(squareImGoingTo, pieceInfo)
	
	for piece in Global.piece_list:
		if piece.is_white != iAmWhitePieces:
			piece.get_legal_moves()
			piece.get_attackable_squares()
			
	for piece in Global.piece_list:
		if piece.is_white == iAmWhitePieces:
			piece.get_legal_moves()
			piece.get_attackable_squares()
		#save my king's position 
		if piece.type == Global.PIECE_TYPE.king and piece.is_white == iAmWhitePieces: 
			myKingsPos = piece
			
		if piece.type == Global.PIECE_TYPE.rook and piece.is_white == iAmWhitePieces and piece.square.column == 'a':
			queenRookPieceInfo = piece.pieceInfo()
			
		if piece.type == Global.PIECE_TYPE.rook and piece.is_white == iAmWhitePieces and piece.square.column == 'h':
			kingRookPieceInfo = piece.pieceInfo()
	
	
	
	#check if en passant can happen
	#add a legal move to the pawns that can en passant 
	checkIfEnPassantCanHappen(squareImGoingTo, pieceInfo)
	
	
	
	#add king's ability to castle, assume they can, prove they can't
	var kingSideCastle = true
	var queenSideCastle = true
	var myKingsPieceInfo = myKingsPos.pieceInfo()	

	
	if myKingsPieceInfo.num_moves == 0: #king hasn't moved
		#king side castle
		if kingRookPieceInfo.num_moves == 0: 
			#check no pieces between them 			
			if  Global.check_square({'column' : 'f', 'row': backRank}) == null and  Global.check_square({'column' : 'g', 'row': backRank}) == null: 
				#check if any opponent pieces have legal moves in these squares
				for x in Global.piece_list: 
					if x.is_white != iAmWhitePieces:
						for xMove in x.legal_moves:
							if xMove.row == backRank and (xMove.column == 'f' or xMove.column == 'g'): 
								kingSideCastle = false
		
			else:
				kingSideCastle = false
		else:	
			kingSideCastle = false
		
		#queen side castle
		if queenRookPieceInfo.num_moves == 0: 
			if  Global.check_square({'column' : 'd', 'row': backRank}) == null and  Global.check_square({'column' : 'c', 'row': backRank}) == null and Global.check_square({'column' : 'b', 'row': backRank}) == null: 
				#check if any opponent pieces have legal moves in these squares
				for x in Global.piece_list: 
					if x.is_white != iAmWhitePieces:
						for xMove in x.legal_moves:
							if xMove.row == backRank and (xMove.column == 'd' or xMove.column == 'c'): 
								queenSideCastle = false								
			else:
				queenSideCastle = false
		else:
				queenSideCastle = false
	else: 
		kingSideCastle = false
		queenSideCastle = false

	if kingSideCastle: 
		myKingsPos.legal_moves.push_front({'column': 'g', 'row': backRank})
	
	if queenSideCastle: 
		myKingsPos.legal_moves.push_front({'column': 'c', 'row': backRank})




	#restrict non king pieces and their legal moves
	var numPiecesBlocking
	var pieceBlocking
	var kingIsAttacked = false
	var moveIsLegal = false
	#check for pins	
	for piece in Global.piece_list:
		numPiecesBlocking = 0 
		pieceBlocking = {}
		
		if ((piece.is_white != iAmWhitePieces) and (piece.type == Global.PIECE_TYPE.queen or piece.type == Global.PIECE_TYPE.bishop or piece.type == Global.PIECE_TYPE.rook)): #opps bishop queen or rook
			
			#check if my king is on an attackable square
			for square in piece.attackable_squares: 
				if square.column == myKingsPos.square.column and square.row == myKingsPos.square.row:
					#check how many of my pieces are between my king and the attacking square
					kingIsAttacked = true
					print("King is currently attaccked by %s" %piece.pieceInfo())
					
			#check how many of my pieces are between my king and the attacking square
			if kingIsAttacked:
				kingIsAttacked = false #reset variable
				#get squares between king and attacking piece
				piece.get_squares_to_king(myKingsPos.square)
				for square in piece.squares_to_king: 
					for attackedPiece in Global.piece_list:
						if attackedPiece.is_white == iAmWhitePieces: 
							if square.column == attackedPiece.square.column and square.row == attackedPiece.square.row:
								numPiecesBlocking += 1
								pieceBlocking = attackedPiece
								print("King is currently blocked by %s", pieceBlocking.pieceInfo())
								
			if numPiecesBlocking == 1: 
				print("only one piece blocking: %s" , pieceBlocking.pieceInfo())
				#remove all legal moves from the attacked piece except for ones that are between the attacking opps piece and my king
				var tempBlockingLegalMoves = pieceBlocking.legal_moves.duplicate()
				for move in tempBlockingLegalMoves: 
					moveIsLegal = false
					for pieceAttackingKingMove in piece.squares_to_king: 
						if move.column == pieceAttackingKingMove.column and move.row == pieceAttackingKingMove.row:			
							moveIsLegal	 = true
							
					if move.column == piece.square.column and move.row == piece.square.row:
						moveIsLegal = true
						 
					if !moveIsLegal:
						pieceBlocking.legal_moves.erase(move)


	#restrict king moves
	#print("king moves: ", moves)
	#update kings moves to remove any squares opponent pieces are attacking
	for piece in Global.piece_list:
		if piece.is_white != iAmWhitePieces: #opps pieces
			for move in piece.legal_moves: 
				for myKingsMoves in myKingsPos.legal_moves.duplicate(): 
					if move.column == myKingsMoves.column and move.row == myKingsMoves.row: 
						myKingsPos.legal_moves.erase(myKingsMoves) #if my kings legal move is attacked by one of their pieces delete it as a legal move
		
	var isPieceNearKing = false
	var thePieceNearKing

	#remove the ability to capture a defended opponent's piece
	for oppsPiece in Global.piece_list:
		if oppsPiece.is_white != iAmWhitePieces: #opps pieces
			for myKingsMoves in  myKingsPos.legal_moves.duplicate(): 
				isPieceNearKing = false
				if oppsPiece.square.column == myKingsMoves.column and oppsPiece.square.row == myKingsMoves.row: 
				 	#if opps piece is on a square my king can capture check if the piece is defended

					isPieceNearKing = true
					thePieceNearKing = oppsPiece
					print("there is a piece near the king")
					print(thePieceNearKing.pieceInfo())
	
					
					if isPieceNearKing: #verify that this piece is being defended if it is delete that oppsPece.square from kings legal moves. 
						for oppsPiece2 in Global.piece_list:
							if oppsPiece2.is_white != iAmWhitePieces: #opps pieces
								for oppsPieceMove in oppsPiece2.attackable_squares:
									#check all opps pieces has an attackable_square that matches thePieceNearKing.sqaure
									if oppsPieceMove.row == thePieceNearKing.square.row and oppsPieceMove.column == thePieceNearKing.square.column:
										#if they do check that there are no pieces between them 
											#only needed for bishops queens and rooks because nothing can block a kinght,pawn, or king's defense 
										if oppsPiece2.type == Global.PIECE_TYPE.queen or oppsPiece2.type == Global.PIECE_TYPE.bishop or oppsPiece2.type == Global.PIECE_TYPE.rook:
											#oppsPiece2.get_squares_to_king(curr_notation)
											
											#
											#print("opps piece info: ", oppsPiece2.pieceInfo())
											print(oppsPiece2.squares_to_king)
											#
											
											
											#needs to be called from main
											var squaresBetweenOppPieces = oppsPiece2.get_squares_to_king(isPieceNearKing.square)
											var isPieceBetweenOppPieces = false
											for square in squaresBetweenOppPieces: 
												if square.check_square():
													isPieceBetweenOppPieces = true
											
											if !isPieceBetweenOppPieces: 
												for move in myKingsPos.legal_moves.duplicate():
													if move.column == thePieceNearKing.square.column and move.row == thePieceNearKing.square.row:
														myKingsPos.legal_moves.erase(move)
											
											
												
										#piece is defended by a pawn, knight, or king					
										else:
											for move in myKingsPos.legal_moves.duplicate():
												if move.column == thePieceNearKing.square.column and move.row == thePieceNearKing.square.row:
													myKingsPos.legal_moves.erase(move) #piece is defended


	
	#check for checks	
	for oppsPiece in Global.piece_list:
			if oppsPiece.is_white != iAmWhitePieces: #opps pieces
				#check if legal_move is matches my king's position
				for move in oppsPiece.legal_moves: 
					if move.column == myKingsPos.square.column and move.row == myKingsPos.square.row: 
						inCheck = true
						print("in check")
						$GameControls/GameCommunication.text = "In Check"
						$GameControls/GameCommunication.visible = true
						# make it so the only legal moves for all my pieces are the ones that can get me out of check
						#so that I don't have to see a buncha bs potential moves show up on the board	
						for myPiece in Global.piece_list:
							if myPiece.is_white == iAmWhitePieces and myPiece.type != Global.PIECE_TYPE.king: #my pieces								
								var tempPieceLegalMoves = myPiece.legal_moves.duplicate()
								for myPiecesLegalMove in tempPieceLegalMoves:
									#if opps piece is a range piece, I can block or capture
									if oppsPiece.type == Global.PIECE_TYPE.bishop or oppsPiece.type == Global.PIECE_TYPE.queen or oppsPiece.type == Global.PIECE_TYPE.rook:
										oppsPiece.get_squares_to_king(myKingsPos.square)
	
										moveIsLegal = false
										for oppsPieceSquaresItCanSee in oppsPiece.squares_to_king:
											#print("opps piece legal move ",oppsPieceLegalMove)
											if myPiecesLegalMove.column == oppsPieceSquaresItCanSee.column and  myPiecesLegalMove.row == oppsPieceSquaresItCanSee.row: #can block
												moveIsLegal = true
												#print("this piece can block: ", myPiece.type, " on square:" ,myPiecesLegalMove)
												
										if myPiecesLegalMove.column == oppsPiece.square.column and  myPiecesLegalMove.row ==  oppsPiece.square.row: #can capture
											moveIsLegal = true
											#print("this piece can capture: ", myPiece.type, " on square:" ,myPiecesLegalMove)
												
										if !moveIsLegal: 
											myPiece.legal_moves.erase(myPiecesLegalMove)
											
									#if not a range piece, only non king moves allowed are to capture
									else:
										for myPiecesLegalMoves in tempPieceLegalMoves:
											if myPiecesLegalMoves.column != oppsPiece.square.column or myPiecesLegalMoves.row != oppsPiece.square.row: 
												myPiece.legal_moves.erase(myPiecesLegalMoves)
											
						#in check, check for checkmate
						#check for checkmate
						#king can't move
						#print("myKing's legal moves: ", myKingsPos.legal_moves)
						if myKingsPos.legal_moves.is_empty():
							#check if a piece can capture or block		
							var canCapture = false
							var canBlock = false
							for myPiece in Global.piece_list:
								if myPiece.is_white == iAmWhitePieces: #my piece
									for myLegalMove in myPiece.legal_moves:
										if myLegalMove.column == oppsPiece.square.column and myLegalMove.row == oppsPiece.square.row:
												print("can capture, ", oppsPiece.pieceInfo(), " with ", myPiece.pieceInfo())
												canCapture = true
												
												
												
							if !canCapture: #check if I can block
								oppsPiece.get_squares_to_king(myKingsPos.square)
								print(oppsPiece.squares_to_king)
								if !oppsPiece.squares_to_king.is_empty():
									#can block this king of piece
									for myPiece in Global.piece_list:
										if myPiece.is_white == iAmWhitePieces: #my piece
											for myLegalMove in myPiece.legal_moves:
												for squaresBetweenKing in oppsPiece.squares_to_king:
													if myLegalMove.column == squaresBetweenKing.column and myLegalMove.row == squaresBetweenKing.row:
														print("can block, ", oppsPiece.pieceInfo(), " with ", myPiece.pieceInfo())
														canBlock = true
									
							if !canBlock:
								#can't block this king of piece
								#it's mate
								checkmate = true
								checkMate()
									



@rpc("any_peer") #when server runs this it makes the opponents move appear on your screen
func sendOppMove(square, pieceInfo):
	#if square has piece on it, delete the piece
	firstMoveMade = true 
		
	for x in Global.piece_list: 
		#if the square I wanna go to has a piece on it remove it
		if x.square.row == square.row and x.square.column == square.column:	
			#delete piece 
			Global.piece_list.erase(x)
			x.queue_free()
			$Capture.play()
			
				
		#fnd the piece being moved and move it
	for y in Global.piece_list: 
		if  y.square.row == pieceInfo.square.row and y.square.column == pieceInfo.square.column:
			y.set_square(square)
			Global.game_state.selected_piece = y	
			$Move.play()
	
	updateGameState(square, pieceInfo)

	
	myTurn = true
	flipTimers()
	$GameControls/PanelContainer/VBoxContainer/MyTurnLabel.text = "It is your turn!"


@rpc("any_peer") #when connected to an opponent tell them the opps id
func connectToOpp(opponentId, oppsName):
	oppId = opponentId
	oppName = oppsName
	$GameControls/PanelContainer/VBoxContainer/HBoxContainer/OpponentLabel.text = "%s" %oppName
	print("Currently playing against: " + str(oppId))


@rpc
func sync_player_list(updated_connected_peer_ids):
	print("Currently connected Players: " + str(updated_connected_peer_ids))
	
	
@rpc
func isMyTurn(x):
	myTurn = x
	Global.game_state.player_color = x
	if x:
		iAmWhitePieces = true
		backRank = 1
		$GameControls/PanelContainer/VBoxContainer/MyPiecesLabel.text = "You are the white pieces" 
		$GameControls/PanelContainer/VBoxContainer/MyTurnLabel.text = "It is your turn!"
	else:
		iAmWhitePieces = false
		backRank = 8
		$GameControls/PanelContainer/VBoxContainer/MyPiecesLabel.text = "You are the black pieces" 
		$GameControls/PanelContainer/VBoxContainer/MyTurnLabel.text = "not your turn yet.."
		
		
func _on_server_disconnected():
	multiplayer_peer.close()
	inGame = false
	print("Connection to server lost.")
	
	

func endGame(): 
	inGame = false
	print("about to end game")
	
	#delete board
	var board = $board
	for child in board.get_children():
		child.queue_free()
		
	Global.deletePieces()
	oppId = 0
	code = 0
	
	homepage._ready()	
	
@rpc("any_peer")
func oppDisconnected():
	#trigger end of game and error message
	print("opp disconnected")
	$EndGameDisplay/PanelContainer/VBoxContainer/Label.text = "Your Opponent Has Been Disconnected"	
	endGameDisplayVisible(true)

@rpc("any_peer")
func invalidJoinGame(isAGame):
	if isAGame: 
		$Homepage/InvalidJoinGame.text = "Game is full"
	else:
		$Homepage/InvalidJoinGame.text = "There is no game with that code, please verify you have the right code or start new game"
	
	$Homepage/Subtitle.visible = false
	$Homepage/InvalidJoinGame.visible = true
	$Homepage/CodeTextBox.visible = true
	$Homepage/EnterCode.visible = true
	$Homepage/Play.visible = true	
	$Homepage/Back.visible = true
	$Homepage/Title.visible = true
	


func theUsernamePasser(theName):
	#print("passing username into func")
	theUsername = theName
	$GameControls/PanelContainer/VBoxContainer/HBoxContainer/MyNameLabel.text = theUsername
	$LoadingScreen/PanelContainer/VBoxContainer/SubLabel.text = "Welcome %s" %theUsername
	
	

func _on_leave_button_pressed() -> void:
	loadingScreenVisible(false)
	rpc_id(1, "leftGame", myID, code)
	endGame()


func _on_disconnected_button_pressed() -> void:
	endGame()
	endGameDisplayVisible(false)


	
@rpc("any_peer")
func serverIsLegal(_oppID, _square, _piece):
	pass
	
@rpc("any_peer")
func leftGame(_myID, _code):
	pass
	
@rpc("any_peer")
func createNewGame(_userID):
	pass	

@rpc("any_peer")
func joinGame(_id, _code, _name, _wannaWatch):
	pass
	


#func _on_no_watch_pressed() -> void:
	#wantsToWatch = false
	#$Homepage/NoWatch.visible = false
	#$Homepage/YesWatch.visible = false
#
#
#func _on_yes_watch_pressed() -> void:
	#wantsToWatch = true
	#$Homepage/NoWatch.visible = false
	#$Homepage/YesWatch.visible = false
	#joinGame.rpc(myID, code, theUsername, wantsToWatch)
	
	
func clearPotentialMoveColors():
	#reset previously selected piece's colour
	for child in Global.game_state.selected_piece.mesh.get_children(): 
		if Global.game_state.selected_piece.mesh.is_light: 
			child.material_override = load("res://peice_meshs/white_piece_material.tres")
		else:
			child.material_override = load("res://peice_meshs/black_piece_material.tres")
			
	#reset previously selected square's colour
	for square in Global.game_state.selected_piece.legal_moves: 
		for legalSquare in $board.get_children():
			if legalSquare.notation.column == square.column and legalSquare.notation.row == square.row:
				legalSquare.setSelectSquareVis(false)
				legalSquare.setSquareColour(false)



func setPotentialMoveColors():
	for child in Global.game_state.selected_piece.mesh.get_children(): 								
		child.material_override = load("res://peice_meshs/selected_piece_material.tres")

	#get new selected legal squares and change it's colour	
	for square in Global.game_state.selected_piece.legal_moves: 
		for legalSquare in $board.get_children():				
			if legalSquare.notation.column == square.column and legalSquare.notation.row == square.row:
				
				var isPieceOnSquare = Global.check_square(legalSquare.notation)
				
				if isPieceOnSquare: 
					legalSquare.setSquareColour(true)
				else:
					legalSquare.setSelectSquareVis(true)

func makeMove():	
	squareImOn = Global.game_state.selected_piece.square
	var legal_moves = Global.game_state.selected_piece.legal_moves
	#print("legal Moves: ",Global.game_state.selected_piece.legal_moves )
	# If the selected piece can go to that square
	if is_legal(squareClicked.get_notation(), legal_moves):
		var pieceInfo = Global.game_state.selected_piece.pieceInfo() 								
		#send move to server who sends it to opponent 
		serverIsLegal.rpc(oppId,squareClicked.get_notation(), pieceInfo)	
		
		
		deleteIfEnPassant(squareClicked.get_notation(), pieceInfo)					
		checkIfRookNeedsToBeCastled(squareClicked.get_notation(), pieceInfo)
		
		Global.game_state.selected_piece.move_to(squareClicked.get_notation())
		checkPromotion(squareClicked.get_notation(), pieceInfo)				
		
		myTurn = false
		flipTimers()
		$GameControls/PanelContainer/VBoxContainer/MyTurnLabel.text = "It is not your turn"
		
	clearPotentialMoveColors()
	$GameControls/GameCommunication.text = ""
	$GameControls/GameCommunication.visible = false


func GameControlsVisible(isOn): 
	$GameControls.visible = isOn
	$GameControls/PanelContainer.visible = isOn
	$GameControls/PanelContainer/VBoxContainer.visible = isOn
	$GameControls/PanelContainer/VBoxContainer/CodeLabel.visible = isOn
	$GameControls/PanelContainer/VBoxContainer/HBoxContainer.visible = isOn
	$GameControls/PanelContainer/VBoxContainer/HBoxContainer/MyNameLabel.visible = isOn
	$GameControls/PanelContainer/VBoxContainer/HBoxContainer/OpponentLabel.visible = isOn
	$GameControls/PanelContainer/VBoxContainer/LeaveButton.visible = isOn
	$GameControls/PanelContainer/VBoxContainer/MyPiecesLabel.visible = isOn
	$GameControls/PanelContainer/VBoxContainer/MyTurnLabel.visible = isOn
	#$GameControls/GameCommunication.visible = isOn
			
		
func loadingScreenVisible(isOn):
	$LoadingScreen.visible = isOn
	$LoadingScreen/PanelContainer.visible = isOn
	$LoadingScreen/PanelContainer/VBoxContainer.visible = isOn
	$LoadingScreen/PanelContainer/VBoxContainer/Label.visible = isOn
	$LoadingScreen/PanelContainer/VBoxContainer/SubLabel.visible = isOn
	$LoadingScreen/PanelContainer/VBoxContainer/SubLabel2.visible = isOn
	$LoadingScreen/PanelContainer/VBoxContainer/SubLabel3.visible = isOn
	$LoadingScreen/PanelContainer/VBoxContainer/TextureRect.visible = isOn
	$LoadingScreen.isOn(isOn)
	

func endGameDisplayVisible(isOn):
	$EndGameDisplay.visible = isOn
	$EndGameDisplay/PanelContainer.visible = isOn
	$EndGameDisplay/PanelContainer/VBoxContainer.visible = isOn
	$EndGameDisplay/PanelContainer/VBoxContainer/DisconnectedButton.visible = isOn
	$EndGameDisplay/PanelContainer/VBoxContainer/Label.visible = isOn

	


func _on_send_button_pressed() -> void:
	var curText = $GameControls/PanelContainer/VBoxContainer/HBoxContainer2/LineEdit.text
	
	if curText.length() > 1:
						
		var sendingText = str("[left] ",theUsername,": ", curText, "\n[/left]")
		$GameControls/PanelContainer/VBoxContainer/HBoxContainer2/LineEdit.text = ""	
		$GameControls/PanelContainer/VBoxContainer/RichTextLabel.text += sendingText
		rpc_id(1, "sendText", sendingText, myID, code)
		$GameControls/PanelContainer/ChatLabel.visible = false



@rpc("any_peer")
func sendText(_text, _myID, _code):
	pass
	
@rpc("any_peer")
func receiveText(text):
	$GameControls/PanelContainer/VBoxContainer/RichTextLabel.text += text
	$GameControls/PanelContainer/ChatLabel.visible = false
	
	
	
	
	
	
func deleteIfEnPassant(square, pieceInfo):

	
	#if there's a piece on the en passant square it is not en passant since the pawn couldn't've moved 2 squares
	var isACapture = Global.check_square(square)
	
	if !isACapture:	
		if pieceInfo.type == Global.PIECE_TYPE.pawn and pieceInfo.square.column != square.column: 
			for z in Global.piece_list: 
				if pieceInfo.is_white == true: 
					if z.square.row == 5 and square.row == 6 and z.square.column == square.column:
						Global.piece_list.erase(z)
						z.queue_free()
				if pieceInfo.is_white == false: 
					if z.square.row == 4 and square.row == 3 and z.square.column == square.column:
						Global.piece_list.erase(z)
						z.queue_free()
						

	
func checkIfEnPassantCanHappen(square, pieceInfo):	
	if pieceInfo.type == Global.PIECE_TYPE.pawn: 
		if pieceInfo.is_white == false: 
			#if pawn just moved two squares
			if pieceInfo.square.row == 7 and square.row == 5: 
			#check if there is a pawn that can en passant it
				for x in Global.piece_list: 
					if x.type == Global.PIECE_TYPE.pawn and x.is_white == true and x.square.row == 5:
						#print("initial column: %s" %square.column)
						#print("column 1 up: %s" %char(square.column.unicode_at(0) - 1))
						if x.square.column == char(square.column.unicode_at(0) + 1)  or x.square.column == char(square.column.unicode_at(0) - 1):
							#set x's legal moves to include enpassant
							x.legal_moves.push_front({'column': square.column, 'row': 6})
								
		if pieceInfo.is_white == true: 
			#if pawn just moved two squares
			if pieceInfo.square.row == 2 and square.row == 4: 
			 #check if there is a pawn that can en passant it
				for x in Global.piece_list: 
					if x.type == Global.PIECE_TYPE.pawn and x.is_white == false and x.square.row == 4:
						#print("initial column: %s" %square.column)
						#print("column 1 up: %s" %char(square.column.unicode_at(0) - 1))
						if x.square.column == char(square.column.unicode_at(0) + 1)  or x.square.column == char(square.column.unicode_at(0) - 1):
							#set x's legal moves to include enpassant
							x.legal_moves.push_front({'column': square.column, 'row': 3})
							
							
							
							
func checkIfRookNeedsToBeCastled(square, pieceInfo):

	
	var tempBackRank	
	if pieceInfo.is_white: 
		tempBackRank = 1
	else: 
		tempBackRank = 8
	
	if pieceInfo.type == Global.PIECE_TYPE.king: 
		#king moves 2 spots
		if abs(square.column.unicode_at(0) - pieceInfo.square.column.unicode_at(0)) > 1: 
			if square.column == 'g': 
				for x in Global.piece_list:
					if x.type == Global.PIECE_TYPE.rook and x.square.column == 'h' and x.square.row == tempBackRank and x.is_white == pieceInfo.is_white: 
						x.set_square({'column': 'f', 'row': tempBackRank})
				
			if square.column == 'c': 
				for x in Global.piece_list:
					if x.type == Global.PIECE_TYPE.rook and x.square.column == 'a' and x.square.row == tempBackRank and x.is_white == pieceInfo.is_white: 
						x.set_square({'column': 'd', 'row': tempBackRank})
				
	
	
	
	
func checkPromotion(square, pieceInfo): 	
	var oppsBackRank
	if pieceInfo.is_white:
		oppsBackRank = 8
	else: 
		oppsBackRank = 1
	
	if pieceInfo.type == Global.PIECE_TYPE.pawn and square.row == oppsBackRank:
		
		#add queen
		var newQueen = piece_template.instantiate()
		newQueen.type = Global.PIECE_TYPE.queen
		newQueen.is_white = pieceInfo.is_white
		newQueen.set_square(square)
		newQueen.get_legal_moves()
		newQueen.get_attackable_squares()
		Global.piece_list.push_front(newQueen)
		print(Global.piece_list)
		add_child(newQueen)
		#Global.game_state.selected_piece = newQueen
		
		#delete pawn
		for pawn in Global.piece_list: 
			if pawn.type == Global.PIECE_TYPE.pawn and pawn.square.column == square.column and pawn.square.row == oppsBackRank:  
					print(pawn.pieceInfo())
					Global.piece_list.erase(pawn)
					pawn.queue_free()
					

func setGameTime(selectedTime): 
	match selectedTime:
		0: 	
			gameTime = 10
		1: 	
			gameTime = 5
		2: 	
			gameTime = 3			
		3: 	
			gameTime = INF
			
			

func _on_my_timer_timeout() -> void:
	$EndGameDisplay/PanelContainer/VBoxContainer/Label.text = "You have ran out of time"	
	endGameDisplayVisible(true)


func _on_opps_timer_timeout() -> void:
	$EndGameDisplay/PanelContainer/VBoxContainer/Label.text = "Your opponent has run out of time"	
	endGameDisplayVisible(true)
	
	
@rpc("any_peer")
func recieveTime(time):
	gameTime = time
	$myTimer.setGameTime(gameTime)
	$oppsTimer.setGameTime(gameTime)
	
func flipTimers(): 
	if myTurn:
		$myTimer.setMyTurn(true)
		$myTimer.start()
		
		$oppsTimer.setMyTurn(false)
		$oppsTimer.is_paused()
	else:
		$myTimer.is_paused()
		$myTimer.setMyTurn(false)
		
		$oppsTimer.start()
		$oppsTimer.setMyTurn(true)
	
	
