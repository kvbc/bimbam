extends KinematicBody2D
signal damaged

const ATTACK_ANGLE = 90

var is_attacking = false
var is_attack_retracting = false
var target_hand_deg = 0
onready var health = ALMain.PLAYER_MAX_HP # in hearts

func on_iframes_timeout ():
	$iframes.stop()

func attempt_to_attack_body (body):
	if body is preload("res://Scripts/Enemy.gd"):
		if is_attacking:
			var hit = body.Hit(0.5, global_position.direction_to(get_global_mouse_position()))
			if hit and not $HitSound.is_playing():
				$HitSound.play()

func _ready ():
	$iframes.wait_time = ALMain.PLAYER_IFRAMES
	$iframes.connect("timeout", self, "on_iframes_timeout")
	$BodyAnimationPlayer.play("Walk")
	$HandsLook/HandsAttack/Right/Weapon.connect("body_entered", self, "attempt_to_attack_body")
	
func _process (delta):
	var wpn_deg = 0
	var mouse_pos = get_global_mouse_position()
	var attack_angle = ATTACK_ANGLE
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
			$AttackSound.play()
			for body in $HandsLook/HandsAttack/Right/Weapon.get_overlapping_bodies():
				attempt_to_attack_body(body)
	
	if is_attacking and not is_attack_retracting:
		wpn_deg += attack_angle
	
	$HandsLook.rotation = lerp_angle(
		$HandsLook.rotation,
		$HandsLook.global_position.direction_to(mouse_pos).angle(),
		delta * 25
	)
	$HandsLook/HandsAttack.rotation = lerp_angle(
		$HandsLook/HandsAttack.rotation,
		deg2rad(target_hand_deg),
		delta * 15
	)
	$HandsLook/HandsAttack/Right/Weapon.rotation = lerp_angle(
		$HandsLook/HandsAttack/Right/Weapon.rotation + (1.0 / (1 << 31)), # so rotation > 0 and it goes to the right
		deg2rad(wpn_deg),
		delta * 15
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

#
#
# PUBLIC
#
#

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

func GetPosition ():
	return global_position
