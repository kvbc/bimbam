extends KinematicBody
signal damaged

const ATTACK_ANGLE = 90

var is_attacking = false
var is_attack_retracting = false
var target_hand_deg = 0
onready var health = ALMain.PLAYER_MAX_HP # in hearts
var attack_angle = ATTACK_ANGLE
var moving_left = false
var moving_right = false
var moving_up = false
var moving_down = false

func on_iframes_timeout ():
	$iframes.stop()

func attempt_to_attack_body (body):
	var is_enemy = body is preload("res://Scripts/Enemy.gd")
	var is_rb = body is RigidBody #prop
	if is_rb or is_enemy:
		if is_attacking:
			var screen_pos = ALMain.Get3DtoScreenPosition(global_transform.origin)
			var mouse_pos = ALMain.GetMousePosition()
			var hit = body.Hit(0.5, screen_pos.direction_to(mouse_pos))
			if hit and not $HitSound.is_playing():
				$HitSound.play()

func _ready ():
	$iframes.wait_time = ALMain.PLAYER_IFRAMES
	$iframes.connect("timeout", self, "on_iframes_timeout")
	$HandsLook/HandsAttack/Right/Weapon.connect("body_entered", self, "attempt_to_attack_body")
	
func _unhandled_input (event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				if not is_attacking:
					is_attacking = true
					target_hand_deg = attack_angle
					$AttackSound.play()
					for body in $HandsLook/HandsAttack/Right/Weapon.get_overlapping_bodies():
						attempt_to_attack_body(body)
	elif event is InputEventKey:
		match event.scancode:
			KEY_A: moving_left  = event.pressed
			KEY_D: moving_right = event.pressed
			KEY_W: moving_up    = event.pressed
			KEY_S: moving_down  = event.pressed
	
func _physics_process (delta):
	var move = Vector2.ZERO
	if moving_left:
		move += Vector2.LEFT
	if moving_right:
		move += Vector2.RIGHT
	if moving_up:
		move += Vector2.UP
	if moving_down:
		move += Vector2.DOWN
	if move != Vector2.ZERO:
		move_and_collide(ALMain.Get2Dto3DVector(move) * ALMain.PLAYER_SPEED * delta)
	
func _process (delta):
	var wpn_deg = 0
	var mouse_pos = ALMain.GetMousePosition()
	attack_angle = ATTACK_ANGLE
	var screen_pos = ALMain.Get3DtoScreenPosition(global_transform.origin)
	if mouse_pos.x < screen_pos.x: # left
		$HandsLook/HandsAttack/Left.flip_h = true
		$HandsLook/HandsAttack/Right/Sprite.flip_h = true
		wpn_deg = 180
	else:
		$HandsLook/HandsAttack/Left.flip_h = false
		$HandsLook/HandsAttack/Right/Sprite.flip_h = false
		attack_angle *= -1

	if is_attacking and not is_attack_retracting:
		wpn_deg += attack_angle

	$HandsLook.rotation_degrees.z = rad2deg(lerp_angle(
		deg2rad($HandsLook.rotation_degrees.z),
		(screen_pos.direction_to(mouse_pos) * Vector2(1,-1)).angle(),
		delta * 25
	))
	
	$HandsLook/HandsAttack.rotation_degrees.z = rad2deg(lerp_angle(
		deg2rad($HandsLook/HandsAttack.rotation_degrees.z),
		deg2rad(target_hand_deg),
		delta * 15
	))
	
	$HandsLook/HandsAttack/Right/Weapon.rotation_degrees.z = rad2deg(lerp_angle(
		deg2rad($HandsLook/HandsAttack/Right/Weapon.rotation_degrees.z + 0.1), # +0.1 so it goes to the right
		deg2rad(wpn_deg),
		delta * 15
	))
	
	if ALUtil.AngleDistance(target_hand_deg, $HandsLook/HandsAttack.rotation_degrees.z) < 5:
		if is_attack_retracting:
			is_attack_retracting = false
			is_attacking = false
		elif is_attacking:
			is_attack_retracting = true
			target_hand_deg = 0
	
	if Input.is_action_just_pressed("LEFT"):
		$Flip.scale.x = -1
	if Input.is_action_just_pressed("RIGHT"):
		$Flip.scale.x = 1

#
#
# PUBLIC
#
#

func Damage (dmg):
	if $iframes.is_stopped():
		$iframes.start()
		$HurtSound.play()
		health -= dmg
		emit_signal("damaged")
#		material.set_shader_param("is_on", true)
#		yield(get_tree().create_timer(0.2), "timeout")
#		material.set_shader_param("is_on", false)

func GetHealth ():
	return health

func Get3DPosition ():
	return global_transform.origin

func Set3DPosition (pos : Vector3):
	translation = pos
