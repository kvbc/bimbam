extends KinematicBody2D

var type = null
var enemy_data = null
var health = null
var can_attack = true
var pathfinding_agent_id = null
var move_dir = Vector2.ZERO
var hit_from_dir = null
# DEBUG
var debug_last_move_dir = null

func on_iframes_timeout ():
	$iframes.stop()

func on_AttackTimer_timeout ():
	can_attack = true

func on_Area2D_body_entered (body):
	if ALMain.IsBodyPlayer(body):
		ALMain.GetPlayer().Damage(enemy_data.GetContactDamage())

# DEBUG
func on_setting_changed (setting_type, new_value):
	if setting_type in [
		ALMain.SettingType.SHOW_ENEMY_STEERING_RAYS,
		ALMain.SettingType.SHOW_ENEMY_FLEE_AREA,
		ALMain.SettingType.SHOW_ENEMY_SHOOT_AREA,
	]:
		update()

func _ready ():
	$AttackTimer.connect("timeout", self, "on_AttackTimer_timeout")
	$Area2D.connect("body_entered", self, "on_Area2D_body_entered")
	
	# DEBUG	
	ALMain.connect("setting_changed", self, "on_setting_changed")
	
	pathfinding_agent_id = ALMain.GetCurrentRoomScene().RegisterPathfindingAgent(global_position)
	
	$iframes.wait_time = ALMain.ENEMY_IFRAMES
	$iframes.connect("timeout", self, "on_iframes_timeout")

func _exit_tree ():
	ALMain.GetCurrentRoomScene().RemovePathfindingAgent(pathfinding_agent_id)
	
func _process (delta):
	var plr_pos = ALMain.GetPlayer().GetPosition()
	var plr_dir = global_position.direction_to(plr_pos)
	var move = false
	var fleeing = false
	
	match type:
		ALMain.EnemyType.MENEL:
			move = true
		ALMain.EnemyType.CRACKHEAD:
			if global_position.distance_to(plr_pos) <= ALMain.ENEMY_FLEE_RADIUS:
				move = true
				fleeing = true
			else:
				if global_position.distance_to(plr_pos) <= ALMain.ENEMY_SHOOT_RADIUS:
					if can_attack:
						can_attack = false
						$AttackTimer.start()
						ALMain.GetCurrentRoomScene().SpawnBullet(global_position, plr_dir, enemy_data.GetBulletDamage())
				else:
					move = true
				
	if move:	
		ALMain.GetCurrentRoomScene().UpdatePathfindingAgent(pathfinding_agent_id, global_position)
		var next_dir = plr_dir
		if hit_from_dir != null:
			next_dir = hit_from_dir * 50
			hit_from_dir *= 0.99
			if hit_from_dir.distance_to(Vector2.ZERO) < 10:
				hit_from_dir = null
		else:
			var next_pos = ALMain.GetCurrentRoomScene().GetNextPathfindingAgentPosition(pathfinding_agent_id)
			if next_pos != null:
				next_dir = global_position.direction_to(next_pos)
			if fleeing:
				next_dir = -next_dir
		move_dir = move_dir.linear_interpolate(next_dir, delta * 5)
					
		if ALMain.GetSetting(ALMain.SettingType.SHOW_ENEMY_STEERING_RAYS) == "yes":
			debug_last_move_dir = move_dir
			update()
		move_and_slide(move_dir * enemy_data.GetMoveSpeed())

# DEBUG
func _draw ():
	if ALMain.GetSetting(ALMain.SettingType.SHOW_ENEMY_STEERING_RAYS) == "yes":
		if debug_last_move_dir != null:
			draw_line(Vector2.ZERO, debug_last_move_dir * 150, Color.white, 5)
	if ALMain.GetSetting(ALMain.SettingType.SHOW_ENEMY_FLEE_AREA) == "yes":
		draw_circle(Vector2.ZERO, ALMain.ENEMY_FLEE_RADIUS, Color(0,1,0,0.05))
	if ALMain.GetSetting(ALMain.SettingType.SHOW_ENEMY_SHOOT_AREA) == "yes":
		draw_circle(Vector2.ZERO, ALMain.ENEMY_SHOOT_RADIUS, Color(1,0,0,0.05))

#
#
# PUBLIC
#
#

func Init (enemy_type):
	type = enemy_type
	enemy_data = ALMain.GetEnemyData(type)
	health = enemy_data.GetMaxHealth()

func Hit (dmg, from_dir):
	if $iframes.is_stopped():
		$iframes.start()
		hit_from_dir = from_dir
		health -= dmg
		$Flash.material.set_shader_param("is_on", true)
		yield(get_tree().create_timer(0.1), "timeout")
		$Flash.material.set_shader_param("is_on", false)
		if health <= 0:
			queue_free()
		return true
	return false

func GetPosition ():
	return global_position
