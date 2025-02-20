extends NinePatchRect

@onready var GuestButton = $Guest
@onready var RegularButton = $Regular
@onready var BackButton = $Back
@onready var JoinButton = $Join
@onready var NewButton = $New
@onready var EnterCodeLabel = $'EnterCode'
@onready var PlayButton = $Play
@onready var CodeTextBox = $CodeTextBox
@onready var TimeDropDown = $Time
@onready var TimeLabel = $TimeControlText
@onready var Title = $Title
@onready var Subtitle = $Subtitle
@onready var NameBox = $NameBox
@onready var NameLabel = $NameLabel
@onready var NameConfirm = $NameConfirm
@onready var NoNameEntered = $NoNameEntered
@onready var GameTypeButton = $GameTypeButton

 
var code: String
var theName : String
var newOrJoin : String
signal joinGame(code)
signal newGame
signal theUsername(theName)


#4. give user the ability to resign / leave game	
	#-disconnect from server
	#-drop the board and be thrust back to beginning of ui
#5. figure out camera so white and black players start facing their size so your pieces are clear
#6. Add Regular login ability

func _ready() -> void:
	NewButton.visible = false
	JoinButton.visible = false	
	EnterCodeLabel.visible = false
	PlayButton.visible = false
	CodeTextBox.visible = false
	TimeDropDown.visible = false
	TimeLabel.visible = false
	NameLabel.visible = false
	NameBox.visible = false
	NameConfirm.visible = false
	NoNameEntered.visible = false
	GameTypeButton.visible = false
	$InvalidJoinGame.visible = false
	$YesWatch.visible = false
	$NoWatch.visible = false
	
	GuestButton.visible = true
	RegularButton.visible = true
	BackButton.visible = true
	Title.visible = true
	Subtitle.visible = true
	
	$/root/main/GameControls.visible = false
	

func _on_guest_pressed() -> void:
	RegularButton.visible = false
	GuestButton.visible = false
	
	NameBox.visible = true
	NameLabel.visible = true
	NameConfirm.visible = true
	
	
	
func _on_regular_pressed() -> void:
	#back to start for now, eventually will have login
	RegularButton.visible = true
	GuestButton.visible = true
	JoinButton.visible = false
	NewButton.visible = false
	
func _on_back_pressed() -> void:

	#brings back to start for now
	#eventually have if elses to go to previous step
	RegularButton.visible = true
	GuestButton.visible = true
	JoinButton.visible = false
	NewButton.visible = false
	EnterCodeLabel.visible = false
	PlayButton.visible = false
	CodeTextBox.visible = false
	TimeDropDown.visible = false
	TimeLabel.visible = false
	NameBox.visible = false
	NameLabel.visible = false
	NameConfirm.visible = false
	GameTypeButton.visible = false
	$NoNameEntered.visible = false
	
	
func _on_join_pressed() -> void:
	JoinButton.visible = false
	NewButton.visible = false
	GameTypeButton.visible = false
	CodeTextBox.visible = true
	EnterCodeLabel.visible = true
	PlayButton.visible = true
	
	newOrJoin = "join"
	
	
func _on_new_pressed() -> void:
	#connect to the board and then put the code in the top right or wherever the menu stuff is 
	NewButton.visible = false
	JoinButton.visible = false
	CodeTextBox.visible = false
	GameTypeButton.visible = false
	EnterCodeLabel.visible = false
	PlayButton.visible = true
	TimeDropDown.visible = true
	TimeLabel.visible = true
	
	newOrJoin = "new"
	

func _on_play_pressed() -> void:
	#try joining the game
	theUsername.emit(theName)
	
	if newOrJoin == "join": 
		if code.length() == 4: 
			joinGame.emit(code)
		else:
			$InvalidJoinGame.text = "game code must be 4 numbers" 
			$InvalidJoinGame.visible = true
	else: 
		newGame.emit()
		

	
	NewButton.visible = false
	JoinButton.visible = false
	CodeTextBox.visible = false
	EnterCodeLabel.visible = false
	PlayButton.visible = false
	TimeDropDown.visible = false
	TimeLabel.visible = false
	BackButton.visible = false
	Title.visible = false
	Subtitle.visible = false
	GameTypeButton.visible = false



func _on_code_text_box_text_changed(new_text: String) -> void:
	if new_text.length() > 4:
		CodeTextBox.text = ""
	else:
		code = new_text


func _on_disconnected_button_pressed() -> void:
	pass # Replace with function body.


func _on_name_box_text_changed(new_text: String) -> void:
	if new_text.length() > 15:
		NameBox.text = ""
	else:
		theName = new_text


func _on_name_confirm_pressed() -> void:
	
	if theName.length() < 1: 
		NoNameEntered.visible = true
	else:
			
		NameBox.visible = false
		NameLabel.visible = false
		NameConfirm.visible = false 
		
		JoinButton.visible = true
		NewButton.visible = true
		GameTypeButton.visible = true
		
