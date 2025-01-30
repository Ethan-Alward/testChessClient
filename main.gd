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
var gameID
var iAmWhitePieces
var myTurn

var theUsername


var squareImOn
var squareClicked

var homepage 
var inGame

var gameControls
var codeLabel
var oppLabel
var myPiecesLabel
var leaveButton

var wantsToWatch



# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	
	code = 0
	myID = 0
	oppId = 0
	gameID = 0
	
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
	
	gameControls = $GameControls
	leaveButton = $GameControls/LeaveButton
	codeLabel = $GameControls/CodeLabel
	myPiecesLabel = $GameControls/MyPiecesLabel
	oppLabel = $GameControls/OpponentLabel
	
	
	codeLabel.visible = false
	oppLabel.visible = false
	leaveButton.visible = false
	myPiecesLabel.visible = false
	$GameControls/MyTurnLabel.visible = false
	$GameControls/MyNameLabel.visible = false
	
	

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
	codeLabel.text = "Code: %s" %code 

	

@rpc
func startGame(): 	
	print("game started from server call")
	inGame = true
	
	#if iAmWhitePieces:
		#$Camera3D.position = krjnsfbg
	#else: 
		#$Camera3D.position = kshjbks
	
	$GameControls/MyNameLabel.text = theUsername
	#set up board
	Global.server_hand_shake()
	get_node("board").start()
	
	for p in Global.initial_piece_state:
		var piece = piece_template.instantiate()
		piece.type =  p.type
		piece.is_white = p.is_white
		piece.set_square(p.square)
		Global.piece_list.push_front(piece)
		add_child(piece)
	

	$GameControls.visible = true
	codeLabel.visible = true
	oppLabel.visible = true
	leaveButton.visible = true
	myPiecesLabel.visible = true
	$GameControls/MyTurnLabel.visible = true
	$GameControls/MyNameLabel.visible = true
	
	oppLabel.text = "oppenent's name: %s" %oppName
	codeLabel.text = "Code: %s" %code

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
					var pieceOnSquare = Global.check_square(squareClicked.get_notation())					
					#if there is a piece on it
					if pieceOnSquare:						
						#if it is my coloured piece, set it to the selected piece
						if pieceOnSquare.is_white == iAmWhitePieces:
							Global.game_state.selected_piece = pieceOnSquare
							pieceOnSquare.get_legal_moves()
							
						else: #not my coloured piece
							#if it is a legal move capture the piece
							squareImOn = Global.game_state.selected_piece.square
							var legal_moves = Global.game_state.selected_piece.legal_moves
							# If the selected piece can go to that square
							if is_legal(squareClicked.get_notation(), legal_moves):
								var pieceInfo = Global.game_state.selected_piece.pieceInfo() 	
								print(Global.game_state.selected_piece)							
								#send move to server who sends it to opponent 
								serverIsLegal.rpc(oppId,squareClicked.get_notation(), pieceInfo)
								#make move on my screen
								Global.game_state.selected_piece.move_to(squareClicked.get_notation())					
								myTurn = false
								$GameControls/MyTurnLabel.text = "It is not your turn"
							
					else: #there is no piece on the square			
						if Global.game_state.selected_piece:
							squareImOn = Global.game_state.selected_piece.square
							var legal_moves = Global.game_state.selected_piece.legal_moves
							# If the selected piece can go to that square
							if is_legal(squareClicked.get_notation(), legal_moves):
								var pieceInfo = Global.game_state.selected_piece.pieceInfo() 								
								#send move to server who sends it to opponent 
								serverIsLegal.rpc(oppId,squareClicked.get_notation(), pieceInfo)								
								#make move on my screen
								Global.game_state.selected_piece.move_to(squareClicked.get_notation())
								myTurn = false
								$GameControls/MyTurnLabel.text = "It is not your turn"


		


func is_legal(square, legal_moves):
	for m in legal_moves:
		if Global.compare_square_notations(m, square):
			return true
	return false

	

@rpc("any_peer") #when server runs this it makes the opponents move appear on your screen
func sendOppMove(square, pieceInfo):
	#if square has piece on it, delete the piece
	for x in Global.piece_list: 
		#if the square I wanna go to has a piece on it remove it
		if x["square"] == square:	
			#delete piece 
			x.queue_free()
			Global.piece_list.erase(x)
	
		#fnd the piece being moved and move it
		if x["square"] == pieceInfo["square"]:	
			x.set_square(square)
			Global.game_state.selected_piece = x	
	
	myTurn = true
	$GameControls/MyTurnLabel.text = "It is your turn!"


@rpc("any_peer") #when connected to an opponent tell them the opps id
func connectToOpp(opponentId, oppsName):
	oppId = opponentId
	oppName = oppsName
	oppLabel.text = "you are playing against: %s" %oppName
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
		myPiecesLabel.text = "You are the white pieces" 
		$GameControls/MyTurnLabel.text = "It is your turn!"
	else:
		iAmWhitePieces = false
		myPiecesLabel.text = "You are the black pieces" 
		$GameControls/MyTurnLabel.text = "not your turn yet.."
		
		
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
	gameID = 0
	code = 0
	
	homepage._ready()	
	
@rpc("any_peer")
func oppDisconnected():
	#trigger end of game and error message
	print("opp disconnected")
	#oppDisconnected display
	$DiconnectedDisplay/ColorRect.visible = true

@rpc("any_peer")
func invalidJoinGame():
	$Homepage/Subtitle.visible = false
	$Homepage/InvalidJoinGame.visible = true
	$Homepage/InvalidJoinGame.text = "Game is full, please verify you have the right code or start new game"

	$Homepage/CodeTextBox.visible = true
	$Homepage/EnterCode.visible = true
	$Homepage/Play.visible = true	
	$Homepage/Back.visible = true
	$Homepage/Title.visible = true
	


func theUsernamePasser(theName):
	print("passing username into func")
	theUsername = theName
	print(theUsername)
	

func _on_leave_button_pressed() -> void:
	endGame()
	rpc_id(1, "leftGame", myID, gameID)

func _on_disconnected_button_pressed() -> void:
	endGame()
	$DiconnectedDisplay/ColorRect.visible = false


	
@rpc("any_peer")
func serverIsLegal(_oppID, _square, _piece):
	pass
	
@rpc("any_peer")
func leftGame(_myID, _gameID):
	pass
	
@rpc("any_peer")
func createNewGame(_userID):
	pass	

@rpc("any_peer")
func joinGame(_id, _code, _name, _wannaWatch):
	pass
	


func _on_no_watch_pressed() -> void:
	wantsToWatch = false
	$Homepage/NoWatch.visible = false
	$Homepage/YesWatch.visible = false


func _on_yes_watch_pressed() -> void:
	wantsToWatch = true
	$Homepage/NoWatch.visible = false
	$Homepage/YesWatch.visible = false
	joinGame.rpc(myID, code, theUsername, wantsToWatch)
	
	
