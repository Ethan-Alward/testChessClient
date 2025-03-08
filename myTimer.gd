extends Timer


var time
var myTurn
var infTime
# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	var homepage = $/root/main/Homepage
	homepage.connect("time", setGameTime.bind())
	time = -1
	set_one_shot(true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if time > 0 and myTurn and !infTime:
		time -= delta
		$/root/main/GameControls/PanelContainer/VBoxContainer/HBoxContainer3/MyTime.text = format_time(time)
		print("my time: %s" %time)
		print("my wait time: %s" %get_time_left())

	

func setGameTime(timeSelected):	
	infTime = false
	match timeSelected:
		0: 	
			wait_time = 10 * 60
			print("in 10")
			time = wait_time
			$/root/main/GameControls/PanelContainer/VBoxContainer/HBoxContainer3/MyTime.text = format_time(time)
		1: 	
			wait_time = 5 * 60
			print("in 5")
			time = wait_time
			$/root/main/GameControls/PanelContainer/VBoxContainer/HBoxContainer3/MyTime.text = format_time(time)
		2: 	
			wait_time = 3 * 60
			print("in 3")		
			time = wait_time
			$/root/main/GameControls/PanelContainer/VBoxContainer/HBoxContainer3/MyTime.text = format_time(time)
		3: 	
			wait_time = INF
			infTime = true
			$/root/main/GameControls/PanelContainer/VBoxContainer/HBoxContainer3/MyTime.text = "Infinite"
			print("in inf")


func format_time(daTime) -> String:
	var mins = daTime / 60
	var seconds = fmod(daTime, 60)
	
	if daTime == 0: 
		return "%02d:%02d" %[mins,seconds]
	else: 
		return "%1d:%02d" %[mins,seconds]

	
func setMyTurn(isMyTurn):
	myTurn = isMyTurn
