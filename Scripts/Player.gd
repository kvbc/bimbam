extends KinematicBody2D
signal damaged

onready var health = ALMain.PLAYER_MAX_HP # in hearts

func on_iframes_timeout ():
	$iframes.stop()

func _ready ():
	$iframes.wait_time = ALMain.PLAYER_IFRAMES
	$iframes.connect("timeout", self, "on_iframes_timeout")
	$BodyAnimationPlayer.play("Walk")

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
		
	if Input.is_action_just_pressed("LEFT"):
		$Flip.scale.x = -1
	if Input.is_action_just_pressed("RIGHT"):
		$Flip.scale.x = 1
		
	if move == Vector2.ZERO:
		$LegsAnimationPlayer.stop()
		# $LegsAnimationPlayer.seek(0, true)
	elif not $LegsAnimationPlayer.is_playing():
		$LegsAnimationPlayer.play("Walk")
		
	move_and_collide(move * ALMain.PLAYER_SPEED * delta)

func Damage (dmg):
	if $iframes.is_stopped():
		$iframes.start()
		health -= dmg
		emit_signal("damaged")

func GetHealth ():
	return health
