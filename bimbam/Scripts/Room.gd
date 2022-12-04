extends Node2D

var chunk_dir_exit_positions = {} # chunk pos -> dir -> exit position
var room : ALMain.MapRoom = null
var chunk_positions = null
var interior_tile_positions = []
var pathfinding = FlowFieldPathfinding.new()

func get_grouped_tilemap_rects (tilemap):
	var rects = []
	var groups = ALUtil.GroupTilemapTiles(tilemap)
	for group in groups:
		var min_pos = null
		var max_pos = null
		for pos in group:
			if min_pos == null: min_pos = pos
			min_pos.x = min(min_pos.x, pos.x)
			min_pos.y = min(min_pos.y, pos.y)
			if max_pos == null: max_pos = pos
			max_pos.x = max(max_pos.x, pos.x)
			max_pos.y = max(max_pos.y, pos.y)
		var rect = Rect2(min_pos, max_pos - min_pos + Vector2(1, 1))
		rects.append(rect)
	return rects

func on_exit_entered (body, method, chunk : ALMain.RoomChunk):
	if ALMain.IsBodyPlayer(body):
		ALMain.call(method, chunk)

func create_exit (dir, tilemap, move_method):
	for exit_rect in get_grouped_tilemap_rects(tilemap):
		var tile_pos = exit_rect.position - ALMain.DirVector(dir) * 2
		var chunk_pos = TileToChunkPosition(tile_pos)
		if not chunk_pos in chunk_dir_exit_positions:
			chunk_dir_exit_positions[chunk_pos] = {}
		chunk_dir_exit_positions[chunk_pos][dir] = TileToWorldPosition(tile_pos)
		
		if not room.HasChunk(chunk_pos):
			continue
		var chunk = room.GetChunk(chunk_pos)
		var can_create_exit = chunk.HasNeighbour(dir)
		
		for x in range(exit_rect.position.x, exit_rect.position.x + exit_rect.size.x):
			for y in range(exit_rect.position.y, exit_rect.position.y + exit_rect.size.y):
				($TileMap if can_create_exit else tilemap).set_cell(x, y, -1)
		
		if can_create_exit:
			exit_rect.size     = tilemap.map_to_world(exit_rect.size)
			exit_rect.position = tilemap.map_to_world(exit_rect.position)
			var exit = Area2D.new()
			exit.position = exit_rect.position + exit_rect.size / 2
			var cs = CollisionShape2D.new()
			cs.shape = RectangleShape2D.new()
			cs.shape.extents = exit_rect.size / 2
			exit.add_child(cs)
			$Exits.add_child(exit)
			exit.connect("body_entered", self, "on_exit_entered", [move_method, chunk])
	
func _ready ():
	var rect = $TileMap.get_used_rect()
	for x in range(rect.position.x, rect.size.x):
		var interior = false
		var prev_wall = false
		var interior_column = []
		for y in range(rect.position.y, rect.size.y):
			var pos = Vector2(x, y)
			var wall = false
			for tilemap in [
				$Exit_Tilemaps/Left,
				$Exit_Tilemaps/Right,
				$Exit_Tilemaps/Up,
				$Exit_Tilemaps/Down,
				$TileMap
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
			
	pathfinding.Init(interior_tile_positions)

func _draw ():
	if room == null: # uninitialized
		return
	var tile_size = $TileMap.cell_size
	if ALMain.GetSetting(ALMain.SettingType.SHOW_ROOM_CHUNKS) == "yes":
		var tiles_per_chunk = ALMain.GetRoomTilesPerChunk() * Vector2.ONE
		for chunk_pos in GetChunkPositions():
			var world_pos = ChunkToWorldPosition(chunk_pos)
			var rect = Rect2(world_pos, ChunkToWorldPosition(Vector2.ONE))
			draw_rect(rect, Color.red, false, 5)
			
			var font = ALMain.GetDebugFont(128)
			var string = str(chunk_pos)
			var str_size = font.get_string_size(string)
			draw_string(font, world_pos + TileToWorldPosition(tiles_per_chunk/2) + tile_size/2 + Vector2(-str_size.x, str_size.y)/2, string, Color.red)
	if ALMain.GetSetting(ALMain.SettingType.SHOW_INTERIOR_ROOM_TILES) == "yes":
		for tile_pos in interior_tile_positions:
			var rect = Rect2(
				TileToWorldPosition(tile_pos),
				TileToWorldPosition(Vector2.ONE)
			)
			draw_rect(rect, Color.red, false)
	if ALMain.GetSetting(ALMain.SettingType.SHOW_ROOM_PATHFINDING) == "yes":
		for x in pathfinding.GetWidth():
			for y in pathfinding.GetHeight():
				var tile_pos = Vector2(x, y)
				var world_pos = TileToWorldPosition(tile_pos)
				
				if pathfinding.IsTileWall(tile_pos):
					draw_multiline(
						[
							world_pos + Vector2(tile_size.x * 0.25, tile_size.y * 0.25),
							world_pos + Vector2(tile_size.x * 0.75, tile_size.y * 0.75), 
							world_pos + Vector2(tile_size.x * 0.25, tile_size.y * 0.75),
							world_pos + Vector2(tile_size.x * 0.75, tile_size.y * 0.25)
						],
						Color.red
					)
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
					draw_multiline(
						[
							world_pos + offsets[0],
							world_pos + offsets[1],
							world_pos + offsets[2],
							world_pos + offsets[3],
							world_pos + offsets[4],
							world_pos + offsets[5],
						],
						Color.red if pathfinding.IsTileOccupied(tile_pos) else Color.yellow
					)

func on_setting_changed (setting_type, new_value):
	if setting_type in [
		ALMain.SettingType.SHOW_ROOM_CHUNKS,
		ALMain.SettingType.SHOW_ROOM_PATHFINDING,
		ALMain.SettingType.SHOW_INTERIOR_ROOM_TILES
	]:
		update()

func update_pathfinding_loop ():
	while true:
		if ALMain.GetPlayer() != null:
			pathfinding.Update(WorldToTilePosition(ALMain.GetPlayer().global_position))
			update()
		yield(get_tree().create_timer(0.1), "timeout")
		
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
	update()
	
	ALMain.connect("setting_changed", self, "on_setting_changed")
	
	var bullets = Node2D.new()
	bullets.name = "Bullets"
	add_child(bullets)
	
	var exits = Node2D.new()
	exits.name = "Exits"
	add_child(exits)
	
	var enemies = Node2D.new()
	enemies.name = "Enemies"
	add_child(enemies)
	
	create_exit(ALMain.Dir.LEFT,  $Exit_Tilemaps/Left,  "MoveLeft")
	create_exit(ALMain.Dir.RIGHT, $Exit_Tilemaps/Right, "MoveRight")
	create_exit(ALMain.Dir.UP,    $Exit_Tilemaps/Up,    "MoveTop")
	create_exit(ALMain.Dir.DOWN,  $Exit_Tilemaps/Down,  "MoveBottom")
	
	if entered_from_dir != null:
		if has_node("EnemySpawns"):
			for dir_group in $EnemySpawns.get_children():
				var dir = ALMain.DirFromString(dir_group.name)
				if dir == entered_from_dir:
					for enemy_group in dir_group.get_children():
						for pos2d in enemy_group.get_children():
							var enemy = preload("res://Scenes/Enemy.tscn").instance()
							enemy.global_position = pos2d.global_position
							enemy.Init(ALMain.EnemyNameToType(enemy_group.name))
							enemies.add_child(enemy)
							
	update_pathfinding_loop()

func SpawnBullet (world_pos:Vector2, velocity:Vector2, damage:float):
	var bullet = preload("res://Scenes/Bullet.tscn").instance()
	bullet.global_position = world_pos
	bullet.Init(velocity, damage)
	$Bullets.add_child(bullet)

func GetChunkExitPosition   (chunk_pos, dir): return chunk_dir_exit_positions[chunk_pos][dir]
func GetWallTileOffsets     ()              : return $TileMap.get_used_cells()
func GetTileSize            ()              : return $TileMap.get_used_rect().size
func GetInteriorTileOffsets ()              : return interior_tile_positions

func TileToChunkPosition  (tile_pos :Vector2): return (tile_pos / ALMain.GetRoomTilesPerChunk() * Vector2.ONE).floor()
func TileToWorldPosition  (tile_pos :Vector2): return $TileMap.map_to_world(tile_pos)
func ChunkToTilePosition  (chunk_pos:Vector2): return chunk_pos * ALMain.GetRoomTilesPerChunk()
func ChunkToWorldPosition (chunk_pos:Vector2): return TileToWorldPosition(ChunkToTilePosition(chunk_pos))
func WorldToTilePosition  (world_pos:Vector2): return $TileMap.world_to_map(world_pos)
func WorldToChunkPosition (world_pos:Vector2): return TileToChunkPosition(WorldToTilePosition(world_pos))

func RegisterPathfindingAgent (world_pos):
	var tile_pos = WorldToTilePosition(world_pos)
	return pathfinding.RegisterAgent(tile_pos.x, tile_pos.y)
func UpdatePathfindingAgent (id, world_pos):
	var tile_pos = WorldToTilePosition(world_pos)
	pathfinding.UpdateAgent(id, tile_pos.x, tile_pos.y)
func GetNextPathfindingAgentPosition (id):
	var tile_pos = pathfinding.GetNextAgentPosition(id)
	if tile_pos == Vector2(-1, -1):
		return null
	return TileToWorldPosition(tile_pos) + $TileMap.cell_size / 2
func RemovePathfindingAgent (agent_id):
	pathfinding.RemoveAgent(agent_id)

func GetChunkExitTileOffsets ():
	var chunk_dir_exit_tile_offsets = {}
	for chunk_pos in GetChunkPositions():
		chunk_dir_exit_tile_offsets[chunk_pos] = {}
		for dir in ALMain.GetAllDirs():
			chunk_dir_exit_tile_offsets[chunk_pos][dir] = []
		
	var tilemap_dir = {
		$Exit_Tilemaps/Left : ALMain.Dir.LEFT,
		$Exit_Tilemaps/Right: ALMain.Dir.RIGHT,
		$Exit_Tilemaps/Up   : ALMain.Dir.UP,
		$Exit_Tilemaps/Down : ALMain.Dir.DOWN
	}
	for tilemap in tilemap_dir.keys():
		var dir = tilemap_dir[tilemap]
		for tile_pos in tilemap.get_used_cells():
			var chunk_pos = TileToChunkPosition(tile_pos)
			chunk_dir_exit_tile_offsets[chunk_pos][dir].append(tile_pos)
			
	return chunk_dir_exit_tile_offsets

func GetPossibleExitDirs ():
	var dirs = []
	for dir in ALMain.GetAllDirs():
		var has_exit
		match dir:
			ALMain.Dir.LEFT : has_exit = not $Exit_Tilemaps/Left .get_used_cells().empty()
			ALMain.Dir.RIGHT: has_exit = not $Exit_Tilemaps/Right.get_used_cells().empty()
			ALMain.Dir.UP   : has_exit = not $Exit_Tilemaps/Up   .get_used_cells().empty()
			ALMain.Dir.DOWN : has_exit = not $Exit_Tilemaps/Down .get_used_cells().empty()
		if has_exit:
			dirs.append(dir)
	return dirs

func GetPossibleChunkExitDirs ():
	var chunk_exit_dirs = {}
	for chunk_pos in GetChunkPositions():
		chunk_exit_dirs[chunk_pos] = []
	for dir in ALMain.GetAllDirs():
		if GetPossibleExitDirs().has(dir):
			var tilemap = {
				ALMain.Dir.LEFT : $Exit_Tilemaps/Left,
				ALMain.Dir.RIGHT: $Exit_Tilemaps/Right,
				ALMain.Dir.UP   : $Exit_Tilemaps/Up,
				ALMain.Dir.DOWN : $Exit_Tilemaps/Down
			}[dir]
			for exit_rect in get_grouped_tilemap_rects(tilemap):
				var tile_pos = exit_rect.position - ALMain.DirVector(dir)
				var chunk_pos = TileToChunkPosition(tile_pos)
				chunk_exit_dirs[chunk_pos].append(dir)
	return chunk_exit_dirs

func GetChunkPositions ():
	if chunk_positions != null:
		return chunk_positions
	chunk_positions = []
	for pos in $TileMap.get_used_cells():
		var chunk_pos = TileToChunkPosition(pos)
		if not chunk_positions.has(chunk_pos):
			chunk_positions.append(chunk_pos)
	return chunk_positions
