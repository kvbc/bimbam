extends KinematicBody2D

func on_iframes_timeout ():
	$iframes.stop()

func _ready ():
	$iframes.wait_time = ALMain.PLAYER_IFRAMES
	$iframes.connect("timeout", self, "on_iframes_timeout")

func _process (delta):
	var move = Vector2.ZERO
	if Input.is_action_pressed("LEFT"):
		move.x += Vector2.LEFT.x
	if Input.is_action_pressed("RIGHT"):
		move.x += Vector2.RIGHT.x
	if Input.is_action_pressed("UP"):
		move.y += Vector2.UP.y
	if Input.is_action_pressed("DOWN"):
		move.y += Vector2.DOWN.y
		
	if move.x == Vector2.LEFT.x:
		$Sprite.flip_h = true
	elif move.x == Vector2.RIGHT.x:
		$Sprite.flip_h = false
		
	if move == Vector2.ZERO:
		$AnimationPlayer.stop()
	elif not $AnimationPlayer.is_playing():
		$AnimationPlayer.play("Walk")
		
	move_and_collide(move * ALMain.PLAYER_SPEED * delta)

func Damage (dmg):
	if $iframes.is_stopped():
		$iframes.start()
