#
# TODO: Optimize static collision body generation for the floor, walls and exit
#

extends Node

class StaticData:
	var chunk_positions = [] # Vector2
	var possible_exit_dirs = [] # ALMain.Dir
	var chunk_exit_tile_positions = {} # chunk pos -> tile pos[]
	var possible_chunk_exit_dirs = {} # chunk pos -> ALMain.Dir[]
	var interior_tile_positions = []
	var wall_tile_positions = []
	var size_in_tiles = null
	
	func _init (
		_chunk_positions,
		_possible_exit_dirs,
		_chunk_exit_tile_positions,
		_possible_chunk_exit_dirs,
		_interior_tile_positions,
		_wall_tile_positions,
		_size_in_tiles
	):
		chunk_positions = _chunk_positions
		possible_exit_dirs = _possible_exit_dirs
		chunk_exit_tile_positions = _chunk_exit_tile_positions
		possible_chunk_exit_dirs = _possible_chunk_exit_dirs
		interior_tile_positions = _interior_tile_positions
		wall_tile_positions = _wall_tile_positions
		size_in_tiles = _size_in_tiles

	func GetChunkPositions         (): return chunk_positions
	func GetPossibleExitDirs       (): return possible_exit_dirs
	func GetChunkExitTilePositions (): return chunk_exit_tile_positions
	func GetPossibleChunkExitDirs  (): return possible_chunk_exit_dirs
	func GetInteriorTilePositions  (): return interior_tile_positions
	func GetWallTilePositions      (): return wall_tile_positions
	func GetSizeInTiles            (): return size_in_tiles
	
var room : ALMain.MapRoom = null
var pathfinding : FlowFieldPathfinding = null

#
# DEBUG
#
func _process (_delta):
	if room == null: # uninitialized
		return
		
	var data = ALMain.GetRoomStaticData(room.GetType())
	if ALMain.GetSetting(ALMain.SettingType.SHOW_ROOM_CHUNKS) == "yes":
		var tiles_per_chunk = ALMain.GetRoomTilesPerChunk() * Vector2.ONE
		for chunk_pos in data.GetChunkPositions():
			var tile_pos = chunk_pos * tiles_per_chunk
			var p1 = Get2DTileTo3DWorldPosition(tile_pos)
			var p2 = Get2DTileTo3DWorldPosition(tile_pos + tiles_per_chunk * Vector2(1,0))
			var p3 = Get2DTileTo3DWorldPosition(tile_pos + tiles_per_chunk * Vector2(1,1))
			var p4 = Get2DTileTo3DWorldPosition(tile_pos + tiles_per_chunk * Vector2(0,1))
			ALDebug.DrawLine3D(ALDebug.Line3D.new(p1, p2))
			ALDebug.DrawLine3D(ALDebug.Line3D.new(p2, p3))
			ALDebug.DrawLine3D(ALDebug.Line3D.new(p3, p4))
			ALDebug.DrawLine3D(ALDebug.Line3D.new(p4, p1))
		
			ALDebug.DrawString3D(ALDebug.String3D.new(
				Get2DTileTo3DWorldPosition(tile_pos + tiles_per_chunk / 2.0),
				str(chunk_pos)
			))
	if ALMain.GetSetting(ALMain.SettingType.SHOW_ROOM_PATHFINDING) == "yes":
		for x in pathfinding.GetWidth():
			for y in pathfinding.GetHeight():
				var tile_pos = Vector2(x, y)
				var tile_size = ALMain.Get3Dto2DVector(Get2DTileTo3DWorldPosition(Vector2.ONE) - Get2DTileTo3DWorldPosition(Vector2.ZERO))
				var pos = Get2DTileTo3DWorldPosition(tile_pos)

				if pathfinding.IsTileWall(tile_pos):
					ALDebug.DrawLine3D(ALDebug.Line3D.new(
						pos + ALMain.Get2Dto3DVector(tile_size * Vector2(0.25, 0.25)),
						pos + ALMain.Get2Dto3DVector(tile_size * Vector2(0.75, 0.75))
					))
					ALDebug.DrawLine3D(ALDebug.Line3D.new(
						pos + ALMain.Get2Dto3DVector(tile_size * Vector2(0.25, 0.75)),
						pos + ALMain.Get2Dto3DVector(tile_size * Vector2(0.75, 0.25))
					))
				else:
					var dir = pathfinding.GetTileDirection(tile_pos)
					if dir == FlowFieldPathfinding.NONE:
						continue
					var angle_degrees
					match dir:
						FlowFieldPathfinding.UP      : angle_degrees = 45 * 0
						FlowFieldPathfinding.TOPRIGHT: angle_degrees = 45 * 1
						FlowFieldPathfinding.RIGHT   : angle_degrees = 45 * 2
						FlowFieldPathfinding.BOTRIGHT: angle_degrees = 45 * 3
						FlowFieldPathfinding.DOWN    : angle_degrees = 45 * 4
						FlowFieldPathfinding.BOTLEFT : angle_degrees = 45 * 5
						FlowFieldPathfinding.LEFT    : angle_degrees = 45 * 6
						FlowFieldPathfinding.TOPLEFT : angle_degrees = 45 * 7
					var offsets = [
						Vector2(tile_size.x * 0.50, tile_size.y * 0.75),
						Vector2(tile_size.x * 0.50, tile_size.y * 0.25),
						Vector2(tile_size.x * 0.25, tile_size.y * 0.50),
						Vector2(tile_size.x * 0.50, tile_size.y * 0.25),
						Vector2(tile_size.x * 0.75, tile_size.y * 0.50),
						Vector2(tile_size.x * 0.50, tile_size.y * 0.25)
					]
					for idx in offsets.size():
						var offset = offsets[idx]
						offsets[idx] = (offset - tile_size / 2).rotated(deg2rad(angle_degrees)) + tile_size / 2
					var color = Color.red if pathfinding.IsTileOccupied(tile_pos) else Color.yellow
					ALDebug.DrawLine3D(ALDebug.Line3D.new(
						pos + ALMain.Get2Dto3DVector(offsets[0]),
						pos + ALMain.Get2Dto3DVector(offsets[1]),
						color
					))
					ALDebug.DrawLine3D(ALDebug.Line3D.new(
						pos + ALMain.Get2Dto3DVector(offsets[2]),
						pos + ALMain.Get2Dto3DVector(offsets[3]),
						color
					))
					ALDebug.DrawLine3D(ALDebug.Line3D.new(
						pos + ALMain.Get2Dto3DVector(offsets[4]),
						pos + ALMain.Get2Dto3DVector(offsets[5]),
						color
					))

func get_exit_tilemap_dir (tilemap):
	return {
		$Viewport/Exit_Tilemaps/Left  : ALMain.Dir.LEFT,
		$Viewport/Exit_Tilemaps/Right : ALMain.Dir.RIGHT,
		$Viewport/Exit_Tilemaps/Up    : ALMain.Dir.UP,
		$Viewport/Exit_Tilemaps/Down  : ALMain.Dir.DOWN,
	}[tilemap]

func start_pathfinding_loop ():
	while true:
		if ALMain.GetPlayer() != null:
			pathfinding.Update(Get3DWorldTo2DTilePosition(ALMain.GetPlayer().Get3DPosition()))
		yield(get_tree().create_timer(0.1), "timeout")

func on_exit_entered (body, dir, chunk : ALMain.RoomChunk):
	if ALMain.IsBodyPlayer(body):
		ALMain.Move(chunk, dir)

func get_tile_polygon (tile_pos : Vector2) -> PoolVector2Array:
	return PoolVector2Array([
		Vector2.ZERO + ALMain.Get3Dto2DVector(Get2DTileTo3DWorldPosition(tile_pos + Vector2(0,0))),
		Vector2.ZERO + ALMain.Get3Dto2DVector(Get2DTileTo3DWorldPosition(tile_pos + Vector2(1,0))),
		Vector2.ZERO + ALMain.Get3Dto2DVector(Get2DTileTo3DWorldPosition(tile_pos + Vector2(1,1))),
		Vector2.ZERO + ALMain.Get3Dto2DVector(Get2DTileTo3DWorldPosition(tile_pos + Vector2(0,1)))
	])
	
#
#
# PUBLIC
#
#

func Init (
	_room : ALMain.MapRoom,
	entered_from_dir = null
):
	room = _room
	var data = ALMain.GetRoomStaticData(room.GetType())

	pathfinding = FlowFieldPathfinding.new()
	pathfinding.Init(data.GetInteriorTilePositions())
	start_pathfinding_loop()
	
	var bullets = Node2D.new()
	bullets.name = "Bullets"
	add_child(bullets)
	
	var enemies = Spatial.new()
	enemies.name = "Enemies"
	add_child(enemies)
	
	if entered_from_dir != null:
		if has_node("Viewport/EnemySpawns"):
			for dir_group in $Viewport/EnemySpawns.get_children():
				var dir = ALMain.DirFromString(dir_group.name)
				if dir == entered_from_dir:
					for enemy_group in dir_group.get_children():
						for pos2d in enemy_group.get_children():
							var enemy = preload("res://Scenes/Enemy.tscn").instance()
							enemy.Set3DPosition(Get2DTileTo3DWorldPosition(Get2DWorldToTilePosition(pos2d.global_position)))
							enemy.Init(ALMain.EnemyNameToType(enemy_group.name))
							enemies.add_child(enemy)
	
	for prop in $Props.get_children():
		prop.Init()
	
	for tile_pos in data.GetInteriorTilePositions():
		var body = StaticBody.new()
		body.collision_layer = 0
		body.collision_mask = 0
		var prop_layer_idx = ALMain.GetPhysicsLayerIdx("Prop")
		body.set_collision_layer_bit(prop_layer_idx, true)
		body.set_collision_mask_bit(prop_layer_idx, true)
		var cp = CollisionPolygon.new()
		cp.rotation_degrees.x = 90
		cp.scale.z = 0
		cp.polygon = get_tile_polygon(tile_pos)
		body.add_child(cp)
		$Collision/Floor.add_child(body)
	
	var exit_tile_positions = []
	
	for tilemap in $Viewport/Exit_Tilemaps.get_children():
		var dir = get_exit_tilemap_dir(tilemap)
		for tile_pos in tilemap.get_used_cells():
			var chunk_pos = Get2DTileToChunkPosition(tile_pos)
			if not room.HasChunk(chunk_pos):
				continue
			var chunk = room.GetChunk(chunk_pos)
			if chunk.HasNeighbour(dir):
				var area = Area.new()
				var cp = CollisionPolygon.new()
				cp.rotation_degrees.x = 90
				cp.polygon = get_tile_polygon(tile_pos)
				area.add_child(cp)
				area.connect("body_entered", self, "on_exit_entered", [dir, chunk])
				$Collision/Exits.add_child(area)
				exit_tile_positions.append(tile_pos)
	
	for tile_pos in data.GetWallTilePositions():
		if not tile_pos in exit_tile_positions:
			var body = StaticBody.new()
			var cp = CollisionPolygon.new()
			cp.rotation_degrees.x = 90
			cp.polygon = get_tile_polygon(tile_pos)
			body.add_child(cp)
			$Collision/Walls.add_child(body)

func GetSizeInTiles ():
	return $Viewport/TileMap.get_used_rect().size

func SpawnBullet (pos3d:Vector3, velocity:Vector3, damage:float):
	var bullet = preload("res://Scenes/Bullet.tscn").instance()
	bullet.Init(velocity, damage)
	$Bullets.add_child(bullet)
	bullet.global_transform.origin = pos3d

#
#
# PUBLIC :: COORDINATE SYSTEMS
#
#

# All 2D<>2D coordinate system transformations
func Get2DTileToChunkPosition  (tile_pos :Vector2): return (tile_pos / ALMain.GetRoomTilesPerChunk() * Vector2.ONE).floor()
func Get2DTileToWorldPosition  (tile_pos :Vector2): return $Viewport/TileMap.map_to_world(tile_pos)
func Get2DChunkToTilePosition  (chunk_pos:Vector2): return chunk_pos * ALMain.GetRoomTilesPerChunk()
func Get2DChunkToWorldPosition (chunk_pos:Vector2): return Get2DTileToWorldPosition(Get2DChunkToTilePosition(chunk_pos))
func Get2DWorldToTilePosition  (world_pos:Vector2): return $Viewport/TileMap.world_to_map(world_pos)
func Get2DWorldToChunkPosition (world_pos:Vector2): return Get2DTileToChunkPosition(Get2DWorldToTilePosition(world_pos))

# basic 2D<>3DWorld transformation
func Get2DTileTo3DWorldPosition (tile_pos2d):
	tile_pos2d *= $Viewport.size / $Viewport/TileMap.get_used_rect().size
	tile_pos2d -= $Viewport.size / 2
	return ALMain.Get2Dto3DVector(tile_pos2d * $Floor.pixel_size)
func Get3DWorldTo2DTilePosition (world_pos3d):
	world_pos3d = ALMain.Get3Dto2DVector(world_pos3d)
	world_pos3d /= $Floor.pixel_size
	world_pos3d += $Viewport.size / 2
	world_pos3d /= $Viewport.size / $Viewport/TileMap.get_used_rect().size
	return world_pos3d

#
#
# PUBLIC :: PATHFINDING
#
#

func RegisterPathfindingAgent ():
	return pathfinding.RegisterAgent()

func UpdatePathfindingAgent (id, tile_pos2d : Vector2, tile_size2d : Vector2):
	pathfinding.UpdateAgent(id, int(tile_pos2d.x), int(tile_pos2d.y), int(tile_size2d.x), int(tile_size2d.y))
	
func GetNextPathfindingAgentPosition (id):
	var tile_pos = pathfinding.GetNextAgentPosition(id)
	if tile_pos == null:
		return null
	return Get2DTileTo3DWorldPosition(tile_pos + 0.5 * Vector2.ONE)
	
func RemovePathfindingAgent (agent_id):
	pathfinding.RemoveAgent(agent_id)

#
#
# PUBLIC :: STATIC DATA
#
#

func GetStaticData ():
	var wall_tile_positions = $Viewport/TileMap.get_used_cells()

	#
	# interior tile positions
	#

	var interior_tile_positions = []
	var rect = $Viewport/TileMap.get_used_rect()
	for x in range(rect.position.x, rect.size.x):
		var interior = false
		var prev_wall = false
		var interior_column = []
		for y in range(rect.position.y, rect.size.y):
			var pos = Vector2(x, y)
			var wall = false
			for tilemap in [
				$Viewport/Exit_Tilemaps/Left,
				$Viewport/Exit_Tilemaps/Right,
				$Viewport/Exit_Tilemaps/Up,
				$Viewport/Exit_Tilemaps/Down,
				$Viewport/TileMap
			]:
				if tilemap.get_used_cells().has(pos):
					if prev_wall:
						interior = true
					else:
						interior = not interior
					wall = true
					break
			prev_wall = wall
			if not wall and interior:
				interior_column.append(pos)
		if not interior or prev_wall:
			interior_tile_positions.append_array(interior_column)
	
	#
	# possible exit dirs
	#
	
	var possible_exit_dirs = []
	for dir in ALMain.Dir.values():
		var has_exit
		match dir:
			ALMain.Dir.LEFT : has_exit = not $Viewport/Exit_Tilemaps/Left .get_used_cells().empty()
			ALMain.Dir.RIGHT: has_exit = not $Viewport/Exit_Tilemaps/Right.get_used_cells().empty()
			ALMain.Dir.UP   : has_exit = not $Viewport/Exit_Tilemaps/Up   .get_used_cells().empty()
			ALMain.Dir.DOWN : has_exit = not $Viewport/Exit_Tilemaps/Down .get_used_cells().empty()
		if has_exit:
			possible_exit_dirs.append(dir)
	
	#
	# chunk positions
	#
	
	var chunk_positions = []
	for pos in $Viewport/TileMap.get_used_cells():
		var chunk_pos = Get2DTileToChunkPosition(pos)
		if not chunk_pos in chunk_positions:
			chunk_positions.append(chunk_pos)

	#
	# chunk dir exit tile positions
	#

	var chunk_dir_exit_tile_positions = {}
	for chunk_pos in chunk_positions:
		chunk_dir_exit_tile_positions[chunk_pos] = {}
		for dir in ALMain.Dir.values():
			chunk_dir_exit_tile_positions[chunk_pos][dir] = []
		
	for tilemap in $Viewport/Exit_Tilemaps.get_children():
		var dir = get_exit_tilemap_dir(tilemap)
		for tile_pos in tilemap.get_used_cells():
			var chunk_pos = Get2DTileToChunkPosition(tile_pos)
			if not tile_pos in chunk_dir_exit_tile_positions[chunk_pos][dir]:
				chunk_dir_exit_tile_positions[chunk_pos][dir].append(tile_pos)
				
	#
	# possible chunk exit dirs
	#
	
	var possible_chunk_exit_dirs = {}
	for chunk_pos in chunk_positions:
		possible_chunk_exit_dirs[chunk_pos] = []
	for tilemap in $Viewport/Exit_Tilemaps.get_children():
		var dir = get_exit_tilemap_dir(tilemap)
		for tile_pos in tilemap.get_used_cells():
			var chunk_pos = Get2DTileToChunkPosition(tile_pos)
			if not dir in possible_chunk_exit_dirs[chunk_pos]:
				possible_chunk_exit_dirs[chunk_pos].append(dir)
	
	#
	#
	#
	
	return StaticData.new(				\
		chunk_positions,				\
		possible_exit_dirs,				\
		chunk_dir_exit_tile_positions,	\
		possible_chunk_exit_dirs,		\
		interior_tile_positions,		\
		wall_tile_positions,			\
		GetSizeInTiles()				\
	)
