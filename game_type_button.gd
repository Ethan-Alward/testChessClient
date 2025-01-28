extends CheckButton


signal gametype(toggled)

func _on_game_type_button_toggled(toggled_on: bool) -> void:

	if toggled_on: 
		text = "Standard" #standard
	else: 
		text = "Fun" #startre
	gametype.emit(toggled_on)
				
