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
	
	#homepage.newGame.connect(newGame.bind())
	
	GameControlsVisible(false)
	loadingScreenVisible(false)
	
	
	

func joinTheGame(gameCode):
	wantsToWatch = false
	joinGame.rpc(myID, gameCode, theUsername, wantsToWatch)	
	code = gameCode

	


func newGame(): 	
	print("NEW GAME")
	rpc_id(1, "createNewGame", myID, theUsername)



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
	
	inGame = true
	firstMoveMade = false
	#if iAmWhitePieces:
		#$Camera3D.position = krjnsfbg
	#else: 
		#$Camera3D.position = kshjbks
	
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

	
	#codeLabel.visible = true
	#oppLabel.visible = true
	#leaveButton.visible = true
	#myPiecesLabel.visible = true
	#$GameControls/PanelContainer/VBoxContainer/MyTurnLabel.visible = true
	#$GameControls/PanelContainer/VBoxContainer/HBoxContainer/MyNameLabel.visible = true
	
	#$GameControls/PanelContainer/VBoxContainer/HBoxContainer/OpponentLabel.text = " vs %s" %oppName
	#codeLabel.text = "Code: %s" %code

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
	$EndGameDisplay/PanelContainer/VBoxContainer/Label.text = "You have been Checkmated"
	
	$EndGameDisplay.visible = true
	rpc_id(1, "sendOppTheyWon", myID, code)
	
	#Send signal to server saying you won! 
	
@rpc("any_peer") #when server runs this it makes the opponents move appear on your screen
func sendOppTheyWon():	
	$EndGameDisplay/PanelContainer/VBoxContainer/Label.text = "You have Checkmated your Opponent"
	$EndGameDisplay.visible = true

func updateGameState(squareImGoingTo, pieceInfo): 
	#update every legal_move and attackable squares for every piece on the board 
	#update opponent's legal_moves first so a change doesn't break my pieces legal moves
	
	#if en passant just happened delete the pawn that got captured
	deleteIfEnPassant(squareImGoingTo, pieceInfo)	
	checkIfRookNeedsToBeCastled(squareImGoingTo, pieceInfo)
	
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
	checkIfEnPassantJustHappened(squareImGoingTo, pieceInfo)
	
	#add king's ability to castle
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
	#check for pins	
	var numPiecesBlocking = 0 
	var pieceBlocking = {}
	var kingIsAttacked = false
	var moveIsLegal = false
	
	for piece in Global.piece_list:
		if ((piece.is_white != iAmWhitePieces) and (piece.type == Global.PIECE_TYPE.queen or piece.type == Global.PIECE_TYPE.bishop or piece.type == Global.PIECE_TYPE.rook)): #opps bishop queen or rook
			#check if my king is on an attackable square
			for square in piece.attackable_squares: 
				if square.column == myKingsPos.square.column and square.row == myKingsPos.square.row:
					#check how many of my pieces are between my king and the attacking square
					kingIsAttacked = true
					
			#check how many of my pieces are between my king and the attacking square
			if kingIsAttacked:
				#get squares between king and attacking piece
				piece.get_squares_to_king(myKingsPos.square)
				for square in piece.squares_to_king: 
					for attackedPiece in Global.piece_list:
						if attackedPiece.is_white == iAmWhitePieces: 
							if square.column == attackedPiece.square.column and square.row == attackedPiece.square.row:
								numPiecesBlocking += 1
								pieceBlocking = attackedPiece
								
			if numPiecesBlocking == 1: 
				print("only one piece blocking: " , pieceBlocking)
				#remove all legal moves from the attacked piece except for ones that are between the attacking opps piece and my king
				for move in pieceBlocking.legal_moves: 
					moveIsLegal = false
					for move2 in piece.attackable_squares: 
						if move.column == move2.column and move.row == move2.row:			
							moveIsLegal	 = true
							
					if move.column == piece.square.column and move.row == piece.square.row:
						moveIsLegal = true
						 
					if !moveIsLegal:
						pieceBlocking.legal_moves.erase(move)
	

	#restrict king moves
	#check for checks	
	for oppsPiece in Global.piece_list:
			if oppsPiece.is_white != iAmWhitePieces: #opps pieces
				#check if legal_move is matches my king's position
				for move in oppsPiece.legal_moves: 
					if move.column == myKingsPos.square.column and move.row == myKingsPos.square.row: 
						inCheck = true
						print("in check")
						# make it so the only legal moves for all my pieces are the ones that can get me out of check
						#so that I don;t have to see a buncha bs potential moves show up on the board
						
						#edit all of my piece's legal_moves so they aren't 
						
						for myPiece in Global.piece_list:
							if myPiece.is_white == iAmWhitePieces and myPiece.type != Global.PIECE_TYPE.king: #my pieces
								#print("my piece: " , myPiece.pieceInfo(), " my pieces legal moves: ", myPiece.legal_moves)
								
								var tempPieceLegalMoves = myPiece.legal_moves.duplicate()
								for myPiecesLegalMove in tempPieceLegalMoves: 									
									if oppsPiece.type == Global.PIECE_TYPE.bishop or oppsPiece.type == Global.PIECE_TYPE.queen or oppsPiece.type == Global.PIECE_TYPE.rook:
										oppsPiece.get_squares_to_king(myKingsPos.square)
	
										moveIsLegal = false
										for oppsPieceLegalMove in oppsPiece.squares_to_king:
											#print("opps piece legal move ",oppsPieceLegalMove)
																						
											if myPiecesLegalMove.column == oppsPieceLegalMove.column and  myPiecesLegalMove.row == oppsPieceLegalMove.row: #can blcok
												moveIsLegal = true
												#print("this piece can block: ", myPiece.type, " on square:" ,myPiecesLegalMove)
												
										if myPiecesLegalMove.column == oppsPiece.square.column and  myPiecesLegalMove.row ==  oppsPiece.square.row: #can capture
											moveIsLegal = true
											#print("this piece can capture: ", myPiece.type, " on square:" ,myPiecesLegalMove)
												
										if !moveIsLegal: 
											myPiece.legal_moves.erase(myPiecesLegalMove)
				
									else:
											if myPiecesLegalMove.column == oppsPiece.square.column and  myPiecesLegalMove.row ==  oppsPiece.square.row:
												for myPiecesLegalMoves in myPiece.legal_moves:
													if myPiecesLegalMoves.column == myPiecesLegalMove.column and myPiecesLegalMoves.row == myPiecesLegalMove.row: 
														myPiece.legal_moves.erase(myPiecesLegalMoves)
											
								#print("POST deleting my piece: " , myPiece.pieceInfo(), " my pieces legal moves: ", myPiece.legal_moves)
						
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
				
		#fnd the piece being moved and move it
	for y in Global.piece_list: 
		if  y.square.row == pieceInfo.square.row and y.square.column == pieceInfo.square.column:
			y.set_square(square)
			Global.game_state.selected_piece = y	
			
	
	updateGameState(square, pieceInfo)

	
	myTurn = true
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
	#oppDisconnected display
	$EndGameDisplay.visible = true
	$EndGameDisplay/PanelContainer.visible = true
	$EndGameDisplay/PanelContainer/VBoxContainer.visible = true
	$EndGameDisplay/PanelContainer/VBoxContainer/DisconnectedButton.visible = true
	$EndGameDisplay/PanelContainer/VBoxContainer/Label.text = "Your Opponent Has Been Disconnected"
	$EndGameDisplay/PanelContainer/VBoxContainer/Label.visible = true

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
	rpc_id(1, "leftGame", myID, code)
	endGame()


func _on_disconnected_button_pressed() -> void:
	endGame()
	$EndGameDisplay.visible = false


	
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
		var promotion = checkPromotion(squareClicked.get_notation(), pieceInfo)
			
		if !promotion:
			Global.game_state.selected_piece.move_to(squareClicked.get_notation())
	
		
		

				
		myTurn = false
		$GameControls/PanelContainer/VBoxContainer/MyTurnLabel.text = "It is not your turn"
		
	clearPotentialMoveColors()


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
			
		
func loadingScreenVisible(isOn):
	$LoadingScreen.visible = isOn
	$LoadingScreen/PanelContainer.visible = isOn
	$LoadingScreen/PanelContainer/VBoxContainer.visible = isOn
	$LoadingScreen/PanelContainer/VBoxContainer/Label.visible = isOn
	$LoadingScreen/PanelContainer/VBoxContainer/SubLabel.visible = isOn
	$LoadingScreen/PanelContainer/VBoxContainer/SubLabel2.visible = isOn
	$LoadingScreen/PanelContainer/VBoxContainer/SubLabel3.visible = isOn
	$LoadingScreen/PanelContainer/VBoxContainer/TextureRect.visible = isOn
	$LoadingScreen.isOn(true)
	

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
	print("start of deleting piece captured en passant")
	print(square)
	print(pieceInfo)
	if pieceInfo.type == Global.PIECE_TYPE.pawn and pieceInfo.square.column != square.column: 
		for z in Global.piece_list: 
			if pieceInfo.is_white == true: 
				if z.square.row + 1 == square.row and z.square.column == square.column:
					Global.piece_list.erase(z)
					z.queue_free()
			if pieceInfo.is_white == false: 
				if z.square.row - 1 == square.row and z.square.column == square.column:
					Global.piece_list.erase(z)
					z.queue_free()
	print("end of deleting piece captured en passant")
	
func checkIfEnPassantJustHappened(square, pieceInfo):	
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
	print("checking castling")
	print(square)
	print(pieceInfo)
	
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
				
	
	
	
	
func checkPromotion(square, pieceInfo) -> bool: 
	var oppsBackRank 
	if pieceInfo.is_white:
		oppsBackRank == 8
	else: 
		oppsBackRank == 1
	
	if pieceInfo.type == Global.PIECE_TYPE.pawn and square.row == oppsBackRank:
		
		#delete pawn
		for pawn in Global.piece_list: 
			if pawn.square.column == square.column and pawn.square.row == square.row: 
				Global.piece_list.erase(pawn)
				pawn.queue_free()
				
		#add queen
		var newQueen = piece_template.instantiate()
		newQueen.type = Global.PIECE_TYPE.queen
		newQueen.is_white = pieceInfo.is_white
		newQueen.set_square(square)
		Global.piece_list.push_front(newQueen)
		add_child(newQueen)
		return true
		
	return false
