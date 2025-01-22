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
var gameID
var iAmWhitePieces
var myTurn

var squareIWannaGoTO
var squareImOn

var homepage 
var inGame

var gameControls
var codeLabel
var oppLabel
var leaveButton



# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	
	code = 0
	myID = 0
	oppId = 0
	gameID = 0
	
	print("Connecting To Server ...")
	
	multiplayer_peer = ENetMultiplayerPeer.new()
	#ip = "127.0.0.1"
	ip = "ec2-18-224-56-186.us-east-2.compute.amazonaws.com"
	
	multiplayer_peer.create_client(ip, PORT)
	
	
	multiplayer.multiplayer_peer = multiplayer_peer
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	print("connection status: %s" %multiplayer_peer.get_connection_status())
	print(MultiplayerPeer.CONNECTION_CONNECTED)
	
	#get_tree().set_multiplayer(multiplayer_peer, "/root/main")
	myID = multiplayer_peer.get_unique_id()
	print("My userId is ", myID)
	
	inGame = false
	
	homepage = $Homepage
	homepage.connect("joinGame", joinTheGame.bind())
	homepage.connect("newGame", newGame.bind())
	#homepage.newGame.connect(newGame.bind())
	
	gameControls = $GameControls
	leaveButton = $GameControls/LeaveButton
	codeLabel = $GameControls/CodeLabel
	oppLabel = $GameControls/OpponentLabel
	codeLabel.visible = false
	oppLabel.visible = false
	leaveButton.visible = false
	
	
	
	

func joinTheGame(gameCode):
	print("Joinnnning")	
	joinGame.rpc(myID, gameCode)	
	code = gameCode
	

@rpc("any_peer")
func joinGame(_id, _code):
	pass

func newGame(): 	
	print("NEW GAME")
	#print(myID)
	rpc_id(1, "createNewGame", myID)
	#createNewGame.rpc(myID)

	


@rpc("any_peer")
func getCode(gameCode):
	code = gameCode
	print(code)
	#startGame()
	codeLabel.text = "Code: %s" %code 

	
@rpc("any_peer")
func createNewGame(_userID):
	pass
	
@rpc
func startGame(): 	
	print("game started from server call")
	inGame = true
	
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
		
	codeLabel.visible = true
	oppLabel.visible = true
	leaveButton.visible = true
	oppLabel.text = "oppenent's ID: %s" %oppId
	codeLabel.text = "Code: %s" %code

func endGame(): 
	inGame = false
	#remove board	
	var board = $board
	for child in board.get_children():
		child.queue_free()
	
	#remove pieces/reset piece arrays to initial state
	var global = $"/root/Global"
	for child in global.get_children():
		child.queue_free()
	
	homepage._ready()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
		
	if inGame:	
		# ray casting
		if Input.is_action_just_pressed("click"):
			var space_state = get_world_3d().direct_space_state
			var mouse_position = get_viewport().get_mouse_position()
			rayOrigin = $Camera3D.project_ray_origin(mouse_position)
			rayEnd = rayOrigin + $Camera3D.project_ray_normal(mouse_position) * 1000
			var ray_query = PhysicsRayQueryParameters3D.create(rayOrigin, rayEnd)
			var intersection = space_state.intersect_ray(ray_query)
			
			if intersection:
				squareIWannaGoTO = intersection["collider"].get_parent().get_parent()
				if squareIWannaGoTO.is_in_group("square"):
					if Global.game_state.selected_piece && myTurn:
						squareImOn = Global.game_state.selected_piece.square
						var legal_moves = Global.game_state.selected_piece.legal_moves
						# If the selected piece can go to that square
						if is_legal(squareIWannaGoTO.get_notation(), legal_moves):
							var pieceInfo = Global.game_state.selected_piece.pieceInfo() 
							
							#send move to server who sends it to opponent 
							serverIsLegal.rpc(oppId,squareIWannaGoTO.get_notation(), pieceInfo)
							
							#make move on my screen
							Global.game_state.selected_piece.move_to(squareIWannaGoTO.get_notation())
							
							#maybe delete
							await get_tree().create_timer(1).timeout
							myTurn = false
							
					var piece = Global.check_square(squareIWannaGoTO.get_notation())
					if piece and myTurn:
						Global.game_state.selected_piece = piece
						piece.get_legal_moves()
					else:
						Global.game_state.selected_piece = null

		


func is_legal(square, legal_moves):
	for m in legal_moves:
		if Global.compare_square_notations(m, square):
			return true
	return false

	

@rpc("any_peer") #when server runs this it makes the opponents move appear on your screen
func sendOppMove(square, pieceInfo):
	myTurn = true
	var piece2 = Global.check_square(pieceInfo["square"])
	Global.game_state.selected_piece = piece2
	piece2.get_legal_moves() #maybe not needed
	Global.game_state.selected_piece.move_to(square)



@rpc("any_peer") #when connected to an opponent tell them the opps id
func connectToOpp(opponentId):
	oppId = opponentId
	oppLabel.text = "oppenent's ID: %s" %oppId
	print("Currently playing against: " + str(oppId))




@rpc
func sync_player_list(updated_connected_peer_ids):
	print("Currently connected Players: " + str(updated_connected_peer_ids))
	
	
@rpc
func isMyTurn(x):
	myTurn = x
	if x:
		iAmWhitePieces = true
		print("I am the white pieces wooooo")
	else:
		iAmWhitePieces = false
		print("I am the black pieces boooo")
		
		
func _on_server_disconnected():
	multiplayer_peer.close()
	inGame = false
	print("Connection to server lost.")


func _on_leave_button_pressed() -> void:
	endGame()
	
@rpc("any_peer")
func serverIsLegal(_oppID, _square, _piece):
	pass
	
