extends KinematicBody2D

var type = null
var enemy_data = null
var health = null
var is_player_in_range = false
var can_attack = true
var can_shoot = false
var steering_ray_dirs = []
var pathfinding_agent_id = null
var move_dir = Vector2.ZERO
# DEBUG
var debug_last_move_dir = null

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

func on_Area2D_body_entered (body):
	if ALMain.IsBodyPlayer(body):
		ALMain.GetPlayer().Damage(enemy_data.GetContactDamage())

# DEBUG
func on_setting_changed (setting_type, new_value):
	if setting_type == ALMain.SettingType.SHOW_ENEMY_STEERING_RAYS:
		if new_value == "no":
			debug_last_move_dir = null
			update()

func _ready ():
	$FleeArea2D.connect("body_entered", self, "on_FleeArea2D_body_entered")
	$FleeArea2D.connect("body_exited", self, "on_FleeArea2D_body_exited")
	$ShootArea2D.connect("body_entered", self, "on_ShootArea2D_body_entered")
	$ShootArea2D.connect("body_exited", self, "on_ShootArea2D_body_exited")
	$AttackTimer.connect("timeout", self, "on_AttackTimer_timeout")
	$Area2D.connect("body_entered", self, "on_Area2D_body_entered")
	
	for i in ALMain.ENEMY_STEERING_RAYS:
		steering_ray_dirs.append(Vector2.RIGHT.rotated(deg2rad(360 / ALMain.ENEMY_STEERING_RAYS * i)))
	
	# DEBUG	
	ALMain.connect("setting_changed", self, "on_setting_changed")
	
	pathfinding_agent_id = ALMain.GetCurrentRoomScene().RegisterPathfindingAgent(global_position)

func _exit_tree ():
	ALMain.GetCurrentRoomScene().RemovePathfindingAgent(pathfinding_agent_id)
	
func _process (delta):
	var plr_pos = ALMain.GetPlayer().global_position
	var plr_dir = global_position.direction_to(plr_pos)
	var move = false
	
	ALMain.GetCurrentRoomScene().UpdatePathfindingAgent(pathfinding_agent_id, global_position)
	var next_pos = ALMain.GetCurrentRoomScene().GetNextPathfindingAgentPosition(pathfinding_agent_id)
	var next_dir = plr_dir
	if next_pos != null:
		next_dir = global_position.direction_to(next_pos)
	move_dir = move_dir.linear_interpolate(next_dir, 0.025)
	
	match type:
		ALMain.EnemyType.MENEL:
			move = true
		ALMain.EnemyType.CRACKHEAD:
			if is_player_in_range:
				move = true
				move_dir = -move_dir
			else:
				if can_shoot:
					if can_attack:
						can_attack = false
						$AttackTimer.start()
						ALMain.GetCurrentRoomScene().SpawnBullet(global_position, plr_dir, enemy_data.GetBulletDamage())
				else:
					move = true
	
#	var avoid_dir = Vector2.ZERO
#	for body in $Area2D.get_overlapping_bodies():
#		if body != self:
#			avoid_dir -= global_position.direction_to(body.global_position)

	if move:
#		var closest_steering_ray_idx = round(rad2deg(move_dir.angle()) / (360 / ALMain.ENEMY_STEERING_RAYS))
#		var steering_ray_indices = [closest_steering_ray_idx]
#		steering_ray_indices.append_array(range(closest_steering_ray_idx + 1, ALMain.ENEMY_STEERING_RAYS))
#		steering_ray_indices.append_array(range(closest_steering_ray_idx - 1, 0, -1))
		
#		move_dir = avoid_dir
		
#		for idx in steering_ray_indices:
#			var ray_dir = steering_ray_dirs[idx]
#			if get_world_2d().direct_space_state.intersect_ray(global_position, global_position + ray_dir * ALMain.ENEMY_STEERING_RAY_LENGTH, [self]).empty():
#				move_dir = ray_dir
#				break
		
		# DEBUG		
		if ALMain.GetSetting(ALMain.SettingType.SHOW_ENEMY_STEERING_RAYS) == "yes":
			debug_last_move_dir = move_dir
			update()
				
#		move_and_collide(move_dir * enemy_data.GetMoveSpeed() * delta)
		move_and_slide(move_dir * enemy_data.GetMoveSpeed())

# DEBUG
func _draw ():
	if debug_last_move_dir == null:
		return
	draw_line(Vector2.ZERO, debug_last_move_dir * ALMain.ENEMY_STEERING_RAY_LENGTH, Color.red, 5)

#
#
# PUBLIC
#
#

func Init (enemy_type):
	type = enemy_type
	enemy_data = ALMain.GetEnemyData(type)
	health = enemy_data.GetMaxHealth()

func Damage (dmg:float):
	health -= dmg
	material.set_shader_param("is_on", true)
	yield(get_tree().create_timer(0.1), "timeout")
	material.set_shader_param("is_on", false)
	if health <= 0:
		queue_free()
