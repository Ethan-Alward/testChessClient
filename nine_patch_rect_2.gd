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


var code: String
var newOrJoin : String
signal joinGame
signal newGame


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
	
	GuestButton.visible = true
	RegularButton.visible = true
	BackButton.visible = true
	
	

func _on_guest_pressed() -> void:
	RegularButton.visible = false
	GuestButton.visible = false
	JoinButton.visible = true
	NewButton.visible = true
	
	
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
	
	
func _on_join_pressed() -> void:
	JoinButton.visible = false
	NewButton.visible = false
	CodeTextBox.visible = true
	EnterCodeLabel.visible = true
	PlayButton.visible = true
	
	newOrJoin = "join"
	
	
func _on_new_pressed() -> void:
	#connect to the board and then put the code in the top right or wherever the menu stuff is 
	NewButton.visible = false
	JoinButton.visible = false
	CodeTextBox.visible = false
	EnterCodeLabel.visible = false
	PlayButton.visible = true
	TimeDropDown.visible = true
	TimeLabel.visible = true
	
	newOrJoin = "new"
	

func _on_play_pressed() -> void:
	#try joining the game
	
	if newOrJoin == "join": 
		emit_signal("joinGame", code)
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



func _on_code_text_box_text_changed(new_text: String) -> void:
	if new_text.length() > 4:
		CodeTextBox.text = ""
	else:
		code = new_text
