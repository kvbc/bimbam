extends KinematicBody2D

const RAYS = 10
const RAY_LENGTH = 150

var type
var is_player_in_range = false
var can_attack = true
var can_shoot = false
var rays = []

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
	
	for i in RAYS:
		rays.append(Vector2.UP.rotated(deg2rad(360 / RAYS * i)))

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

	
	if move:
		var new_pos = global_position + move_dir * ALMain.GetEnemyData(type).move_speed * delta
		
		var closest_ray_idx = -1
		for idx in rays.size():
			if closest_ray_idx < 0 or (global_position + rays[idx]).distance_to(new_pos) < (global_position + rays[closest_ray_idx]).distance_to(new_pos):
				closest_ray_idx = idx
				
#		var indices = [closest_ray_idx]
#		var is_next_ray = closest_ray_idx + 1 < rays.size()
#		var is_prev_ray = closest_ray_idx - 1 > 0
#		var next_ray = rays[closest_ray_idx + 1] if is_next_ray else Vector2.ZERO
#		var prev_ray = rays[closest_ray_idx - 1] if is_prev_ray else Vector2.ZERO
#		var next_ray_distance = (global_position + next_ray).distance_to(new_pos)
#		var prev_ray_distance = (global_position + prev_ray).distance_to(new_pos)
#		if next_ray_distance < prev_ray_distance:
#			indices.append_array(range(closest_ray_idx + 1, rays.size()))
#			indices.append_array(range(closest_ray_idx - 1, 0, -1))
#		else:
#			indices.append_array(range(closest_ray_idx - 1, 0, -1))
#			indices.append_array(range(closest_ray_idx + 1, rays.size()))
		var indices = [closest_ray_idx]
		indices.append_array(range(closest_ray_idx + 1, rays.size()))
		indices.append_array(range(closest_ray_idx - 1, 0, -1))
		
		for idx in indices:
			var ray = rays[idx]
			if get_world_2d().direct_space_state.intersect_ray(global_position, global_position + ray * RAY_LENGTH, [self]).empty():
				var collision = move_and_collide(ray * ALMain.GetEnemyData(type).move_speed * delta)
				if collision:
					if ALMain.IsBodyPlayer(collision.collider):
						ALMain.GetPlayer().Damage(ALMain.GetEnemyData(type).contact_damage)
				break
			

func Init (enemy_type):
	type = enemy_type
