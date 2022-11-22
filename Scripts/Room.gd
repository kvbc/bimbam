extends Node2D

var chunk_dir_exit_positions = {} # chunk pos -> dir -> exit position
#var interior_cells = []
var room : ALMain.MapRoom = null
var chunk_positions = null
var interior_tile_positions = []

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

func _draw ():
	if room == null:
		return
	if ALMain.GetSetting(ALMain.SettingType.SHOW_ROOM_CHUNKS) == "yes":
		var tiles_per_chunk = ALMain.GetRoomTilesPerChunk() * Vector2.ONE
		for chunk_pos in GetChunkPositions():
			var world_pos = ChunkToWorldPosition(chunk_pos)
			for dir in [ALMain.Dir.RIGHT, ALMain.Dir.DOWN]:
				var end_pos = world_pos + $TileMap.map_to_world(ALMain.DirVector(dir) * tiles_per_chunk)
				draw_line(world_pos, end_pos, Color.red, 5)
				
			var font = ALMain.GetDebugFont()
			var string = str(chunk_pos)
			var str_size = font.get_string_size(string)
			draw_string(font, world_pos + TileToWorldPosition(tiles_per_chunk/2) - str_size/2, string)
	if ALMain.GetSetting(ALMain.SettingType.SHOW_INTERIOR_ROOM_TILES) == "yes":
		for tile_pos in interior_tile_positions:
			draw_circle(TileToWorldPosition(tile_pos) + $TileMap.cell_size / 2, 5, Color.red)

func on_setting_changed (setting_type, new_value):
	if setting_type in [
		ALMain.SettingType.SHOW_ROOM_CHUNKS,
		ALMain.SettingType.SHOW_INTERIOR_ROOM_TILES
	]:
		update()

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
