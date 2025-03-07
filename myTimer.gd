extends Timer


var time
var myTurn
# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	var homepage = $/root/main/Homepage
	homepage.connect("time", setGameTime.bind())
	time = -1


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if time > 0 and myTurn:
		time -= delta
		$/root/main/GameControls/PanelContainer/VBoxContainer/HBoxContainer3/MyTime.text = format_time(time)
	
	
	
	
	
	
	
	#change this so server passes times back and forth
	
	
	
	
	
	

func setGameTime(timeSelected):	
	match timeSelected:
		0: 	
			wait_time = 10 * 60
		1: 	
			wait_time = 5 * 60
		2: 	
			wait_time = 3 * 60
		3: 	
			wait_time = INF
			#consider changing timelabel
	time = wait_time
			
func format_time(daTime) -> String:
	var mins = daTime / 60
	var seconds = fmod(daTime, 60)
	
	return "%02d:%02d" %[mins,seconds]

	
func setMyTurn(isMyTurn):
	myTurn = isMyTurn
