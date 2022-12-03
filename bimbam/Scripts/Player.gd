extends KinematicBody2D
signal damaged

var is_hand_retracting = false
var is_attacking = false
var is_attack_retracting = false
var target_hand_deg = 0
onready var health = ALMain.PLAYER_MAX_HP # in hearts

func on_iframes_timeout ():
	$iframes.stop()

func on_weapon_body_entered (body):
	if body is preload("res://Scripts/Enemy.gd"):
		if is_attacking:
			body.Damage(0.5)

func _ready ():
	$iframes.wait_time = ALMain.PLAYER_IFRAMES
	$iframes.connect("timeout", self, "on_iframes_timeout")
	$BodyAnimationPlayer.play("Walk")
	$HandsLook/HandsAttack/Right/Weapon.connect("body_entered", self, "on_weapon_body_entered")
	
func _process (delta):
	var wpn_deg = 0
	var mouse_pos = get_global_mouse_position()
	var attack_angle = 45
	if mouse_pos.x < global_position.x:
		$HandsLook/HandsAttack/Left/Sprite.flip_h = true
		$HandsLook/HandsAttack/Right/Sprite.flip_h = true
		wpn_deg = 180
		attack_angle *= -1
	else:
		$HandsLook/HandsAttack/Left/Sprite.flip_h = false
		$HandsLook/HandsAttack/Right/Sprite.flip_h = false
		
	if Input.is_action_pressed("ATTACK"):
		if not is_attacking:
			is_attacking = true
			target_hand_deg = attack_angle
	
	if is_attacking and not is_attack_retracting:
		wpn_deg += 180
	
	$HandsLook.rotation = lerp_angle($HandsLook.rotation, $HandsLook.global_position.direction_to(mouse_pos).angle(), 0.5)
	$HandsLook/HandsAttack.rotation = lerp_angle($HandsLook/HandsAttack.rotation, deg2rad(target_hand_deg), 0.2)
	$HandsLook/HandsAttack/Right/Weapon.rotation = lerp_angle(
		$HandsLook/HandsAttack/Right/Weapon.rotation + (1.0 / (1 << 31)), # so rotation > 0 and it goes to the right
		deg2rad(wpn_deg),
		0.2
	)
		
	if ALUtil.AngleDistance(target_hand_deg, $HandsLook/HandsAttack.rotation_degrees) < 5:
		if is_attack_retracting:
			is_attack_retracting = false
			is_attacking = false
		elif is_attacking:
			is_attack_retracting = true
			target_hand_deg = 0
	
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
	elif not $LegsAnimationPlayer.is_playing():
		$LegsAnimationPlayer.play("Walk")
		
	move_and_collide(move * ALMain.PLAYER_SPEED * delta)

func Damage (dmg):
	if $iframes.is_stopped():
		$iframes.start()
		health -= dmg
		emit_signal("damaged")
		material.set_shader_param("is_on", true)
		yield(get_tree().create_timer(0.2), "timeout")
		material.set_shader_param("is_on", false)

func GetHealth ():
	return health
