extends KinematicBody2D

func _process (delta):
	var move = Vector2.ZERO
	if Input.is_action_pressed("LEFT"):
		move.x = Vector2.LEFT.x
	if Input.is_action_pressed("RIGHT"):
		move.x = Vector2.RIGHT.x
	if Input.is_action_pressed("UP"):
		move.y = Vector2.UP.y
	if Input.is_action_pressed("DOWN"):
		move.y = Vector2.DOWN.y
	move_and_collide(move * ALMain.PLAYER_SPEED * delta)
