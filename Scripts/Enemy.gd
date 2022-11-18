extends KinematicBody2D

var type
var is_player_in_range = false
var can_attack = true
var can_shoot = false
var steering_ray_dirs = []

func on_AttackTimer_timeout ():
	can_attack = true

func on_ShootArea2D_body_entered (body):
	if ALMain.IsBodyPlayer(body):
		can_shoot = true
func on_ShootArea2D_body_exited (body):
	if ALMain.IsBodyPlayer(body):
		can_shoot = false

func on_FleeArea2D_body_entered (body):
	if ALMain.IsBodyPlayer(body):
		is_player_in_range = true
func on_FleeArea2D_body_exited (body):
	if ALMain.IsBodyPlayer(body):
		is_player_in_range = false

func _ready ():
	$FleeArea2D.connect("body_entered", self, "on_FleeArea2D_body_entered")
	$FleeArea2D.connect("body_exited", self, "on_FleeArea2D_body_exited")
	$ShootArea2D.connect("body_entered", self, "on_ShootArea2D_body_entered")
	$ShootArea2D.connect("body_exited", self, "on_ShootArea2D_body_exited")
	$AttackTimer.connect("timeout", self, "on_AttackTimer_timeout")
	
	for i in ALMain.ENEMY_STEERING_RAYS:
		steering_ray_dirs.append(Vector2.RIGHT.rotated(deg2rad(360 / ALMain.ENEMY_STEERING_RAYS * i)))

func _process (delta):
	var plr_dir = global_position.direction_to(ALMain.GetPlayer().global_position)
	var move = false
	var move_dir = plr_dir
	
	match type:
		ALMain.EnemyType.MENEL:
			move = true
		ALMain.EnemyType.CRACKHEAD:
			if is_player_in_range:
				move = true
				move_dir = -plr_dir
			else:
				if can_shoot:
					if can_attack:
						can_attack = false
						$AttackTimer.start()
						ALMain.GetCurrentRoomScene().SpawnBullet(global_position, plr_dir, ALMain.GetEnemyData(type).bullet_damage)
				else:
					move = true
	
	var avoid_dir = Vector2.ZERO
	for body in $Area2D.get_overlapping_bodies():
		if ALMain.IsBodyPlayer(body):
			ALMain.GetPlayer().Damage(ALMain.GetEnemyData(type).contact_damage)
		elif body != self:
			avoid_dir -= global_position.direction_to(body.global_position)

	if move:
		var new_pos = global_position + move_dir * ALMain.GetEnemyData(type).move_speed * delta
		
		var closest_steering_ray_idx = round(rad2deg(move_dir.angle()) / (360 / ALMain.ENEMY_STEERING_RAYS))
		var steering_ray_indices = [closest_steering_ray_idx]
		steering_ray_indices.append_array(range(closest_steering_ray_idx + 1, ALMain.ENEMY_STEERING_RAYS))
		steering_ray_indices.append_array(range(closest_steering_ray_idx - 1, 0, -1))
		
		move_dir = avoid_dir
		
		for idx in steering_ray_indices:
			var ray_dir = steering_ray_dirs[idx]
			if get_world_2d().direct_space_state.intersect_ray(global_position, global_position + ray_dir * ALMain.ENEMY_STEERING_RAY_LENGTH, [self]).empty():
				move_dir = ray_dir
				break
				
		move_and_collide(move_dir * ALMain.GetEnemyData(type).move_speed * delta)

func Init (enemy_type):
	type = enemy_type
