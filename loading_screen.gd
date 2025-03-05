extends NinePatchRect
var isOnQ

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$PanelContainer/VBoxContainer.add_theme_constant_override("separation", 10) 
	isOnQ = false
	$PanelContainer/VBoxContainer/TextureRect.pivot_offset = Vector2(70,117/2)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if isOnQ:
		$PanelContainer/VBoxContainer/TextureRect.rotation_degrees += 90 * delta

func isOn(on): 
	isOnQ = on
		
