extends NinePatchRect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$PanelContainer.visible = false
	$PanelContainer/VBoxContainer.add_theme_constant_override("separation", 20) 

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.8)
	style.border_color = Color(0, 0.992, 0.494)
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_width_left = 3
	style.border_width_right = 3
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	add_theme_stylebox_override("panel", style)
	$PanelContainer.add_theme_stylebox_override("panel", style)
	
