extends Camera2D

func _input (event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_UP:
			zoom -= ALMain.CAMERA_ZOOM_SENSITIVITY * Vector2.ONE
		elif event.button_index == BUTTON_WHEEL_DOWN:
			zoom += ALMain.CAMERA_ZOOM_SENSITIVITY * Vector2.ONE
