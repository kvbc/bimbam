extends KinematicBody

var type = null
var enemy_data = null
var health = null
var can_attack = true
var pathfinding_agent_id = null
var move_dir = Vector3.ZERO
var hit_from_dir = null

func on_iframes_timeout ():
	$iframes.stop()

func on_AttackTimer_timeout ():
	can_attack = true

func on_Area_body_entered (body):
	if ALMain.IsBodyPlayer(body):
		if ALMain.GetPlayer() != null:
			ALMain.GetPlayer().Damage(enemy_data.GetContactDamage())

func _ready ():
	$AttackTimer.connect("timeout", self, "on_AttackTimer_timeout")
	$Area.connect("body_entered", self, "on_Area_body_entered")
	
	$iframes.wait_time = ALMain.ENEMY_IFRAMES
	$iframes.connect("timeout", self, "on_iframes_timeout")
	
	pathfinding_agent_id = ALMain.GetCurrentRoomScene().RegisterPathfindingAgent(global_transform.origin)

func _exit_tree ():
	ALMain.GetCurrentRoomScene().RemovePathfindingAgent(pathfinding_agent_id)
	
func _process (delta):
	var pos = global_transform.origin
	var plr_pos = ALMain.GetPlayer().Get3DPosition()
	var plr_dir = pos.direction_to(plr_pos)
	var move = false
	var fleeing = false
	
	match type:
		ALMain.EnemyType.MENEL:
			move = true
		ALMain.EnemyType.CRACKHEAD:
			if pos.distance_to(plr_pos) <= ALMain.ENEMY_FLEE_RADIUS:
				move = true
				fleeing = true
			else:
				if pos.distance_to(plr_pos) <= ALMain.ENEMY_SHOOT_RADIUS:
					if can_attack:
						can_attack = false
						$AttackTimer.start()
						ALMain.GetCurrentRoomScene().SpawnBullet(pos, plr_dir, enemy_data.GetBulletDamage())
				else:
					move = true
	
	if hit_from_dir != null:
		move = true
	
	if move:	
		ALMain.GetCurrentRoomScene().UpdatePathfindingAgent(pathfinding_agent_id, pos)
		var next_dir = plr_dir
		if hit_from_dir != null:
			next_dir = hit_from_dir * 50
			hit_from_dir *= delta
			if next_dir.distance_to(Vector3.ZERO) < 5:
				hit_from_dir = null
		else:
			var next_pos = ALMain.GetCurrentRoomScene().GetNextPathfindingAgentPosition(pathfinding_agent_id)
			if next_pos != null:
				next_dir = pos.direction_to(next_pos)
			if fleeing:
				next_dir = -next_dir
		move_dir = move_dir.linear_interpolate(next_dir, delta * 5)
		move_and_slide(move_dir * enemy_data.GetMoveSpeed())

	#
	# DEBUG
	#
	if ALMain.GetSetting(ALMain.SettingType.SHOW_ENEMY_STEERING_RAYS) == "yes":
		ALDebug.DrawLine3D(ALDebug.Line3D.new(
			global_transform.origin,
			global_transform.origin + move_dir,
			Color.white
		))
	if ALMain.GetSetting(ALMain.SettingType.SHOW_ENEMY_FLEE_AREA) == "yes":
		ALDebug.DrawLine3D(ALDebug.Line3D.new(
			global_transform.origin,
			global_transform.origin + (-plr_dir) * ALMain.ENEMY_FLEE_RADIUS,
			Color.green
		))
	if ALMain.GetSetting(ALMain.SettingType.SHOW_ENEMY_SHOOT_AREA) == "yes":
		ALDebug.DrawLine3D(ALDebug.Line3D.new(
			global_transform.origin,
			global_transform.origin + (plr_dir) * ALMain.ENEMY_SHOOT_RADIUS,
			Color.red
		))
#
#
# PUBLIC
#
#

func Init (enemy_type):
	type = enemy_type
	enemy_data = ALMain.GetEnemyData(type)
	health = enemy_data.GetMaxHealth()

func Hit (damage:float, from_dir:Vector2):
	if $iframes.is_stopped():
		$iframes.start()
		hit_from_dir = ALMain.Get2Dto3DVector(from_dir)
		health -= damage
		# $Flash.material.set_shader_param("is_on", true)
		# yield(get_tree().create_timer(0.1), "timeout")
		# $Flash.material.set_shader_param("is_on", false)
		if health <= 0:
			queue_free()
		return true
	return false

func Set3DPosition (pos : Vector3):
	global_transform.origin = pos

func Get3DPosition ():
	return global_transform.origin
