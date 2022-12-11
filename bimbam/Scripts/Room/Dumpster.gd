extends RigidBody

var pathfinding_agent_id = null

func _process (_delta):
	var aabb = $MeshInstance.get_transformed_aabb()
	
	#
	# DEBUG
	#
	if ALMain.GetSetting(ALMain.SettingType.SHOW_ROOM_PROP_BOUNDS) == "yes":
		ALDebug.DrawLine3D(ALDebug.Line3D.new(
			aabb.position,
			aabb.position + aabb.size * Vector3(1,0,0)
		))
		ALDebug.DrawLine3D(ALDebug.Line3D.new(
			aabb.position + aabb.size * Vector3(1,0,0),
			aabb.position + aabb.size * Vector3(1,0,1)
		))
		ALDebug.DrawLine3D(ALDebug.Line3D.new(
			aabb.position + aabb.size * Vector3(1,0,1),
			aabb.position + aabb.size * Vector3(0,0,1)
		))
		ALDebug.DrawLine3D(ALDebug.Line3D.new(
			aabb.position + aabb.size * Vector3(0,0,1),
			aabb.position
		))
	
	if pathfinding_agent_id != null:
		var room = ALMain.GetCurrentRoomScene()
		var tile_pos2d = room.Get3DWorldTo2DTilePosition(aabb.position).round()
		var tile_end2d = room.Get3DWorldTo2DTilePosition(aabb.end).round()
		var tile_size2d = tile_end2d - tile_pos2d
		room.UpdatePathfindingAgent(pathfinding_agent_id, tile_pos2d, tile_size2d)

func Hit (_damage:float, dir:Vector2) -> bool:
	apply_central_impulse(ALMain.Get2Dto3DVector(dir) * 5)
	return true

func Init ():
	pathfinding_agent_id = ALMain.GetCurrentRoomScene().RegisterPathfindingAgent()
