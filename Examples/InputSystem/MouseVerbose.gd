extends Spatial

var mouse_current : Vector2
var mouse_buttons = 0

var last_buttons

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var pos : Vector2 = get_viewport().get_mouse_position()
	var buttons = Input.get_mouse_button_mask()
	if (buttons!=last_buttons || Input.is_physical_key_pressed(KEY_SPACE)):
		print(" poll xy ",pos,"    buttons ",buttons)
		last_buttons=buttons
	pass

func _input(event):
	if event is InputEventMouse:
		mouse_current = event.position
		mouse_buttons = event.button_mask
		if (mouse_buttons!=0):
			print("event xy ",mouse_current,"    buttons ",mouse_buttons)
	if event is InputEventKey:
		if (event.pressed):
			print(" keydown ",event.unicode,"  code ",event.scancode)
		else:
			print(" keyup ",event.unicode,"  code ",event.scancode)
	pass
