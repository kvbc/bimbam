extends Node2D

var chunk_dir_exit_positions = {} # chunk pos -> dir -> exit position
var empty_cells = []
var min_empty_cell
var room : ALMain.MapRoom

func on_exit_entered (body, method, chunk : ALMain.RoomChunk):
	if ALMain.IsBodyPlayer(body):
		ALMain.call(method, chunk)

func tile_to_chunk_pos (tile_pos):
	var chunk_tiles = ALMain.GetRoomTilesPerChunk()
	return ((tile_pos - min_empty_cell) / Vector2(chunk_tiles, chunk_tiles)).floor()

func get_grouped_tilemap_rects (tilemap):
	var rects = []
	var groups = ALUtil.GroupTilemapTiles(tilemap)
	for group in groups:
		var min_pos = null
		var max_pos = null
		for pos in group:
			if min_pos == null:
				min_pos = pos
			else:
				min_pos.x = min(min_pos.x, pos.x)
				min_pos.y = min(min_pos.y, pos.y)
			if max_pos == null:
				max_pos = pos
			else:
				max_pos.x = max(max_pos.x, pos.x)
				max_pos.y = max(max_pos.y, pos.y)
		var rect = Rect2(min_pos, max_pos - min_pos + Vector2(1, 1))
		rects.append(rect)
	return rects

func create_exit (dir, tilemap, move_method):
	for rect in get_grouped_tilemap_rects(tilemap):
		var tile_pos_in_front = rect.position - ALMain.DirVector(dir) * 2
		var chunk_pos_in_front = tile_to_chunk_pos(tile_pos_in_front)
		if not chunk_pos_in_front in chunk_dir_exit_positions:
			chunk_dir_exit_positions[chunk_pos_in_front] = {}
		chunk_dir_exit_positions[chunk_pos_in_front][dir] = tile_pos_in_front * tilemap.cell_size
		
		var chunk = room.GetChunk(chunk_pos_in_front)
		if chunk.HasNeighbour(dir):
			rect.size *= tilemap.cell_size
			rect.position *= tilemap.cell_size
			var exit = Area2D.new()
			exit.position = rect.position + rect.size / 2
			var cs = CollisionShape2D.new()
			cs.shape = RectangleShape2D.new()
			cs.shape.extents = rect.size / 2
			exit.add_child(cs)
			$Exits.add_child(exit)
			exit.connect("body_entered", self, "on_exit_entered", [move_method, chunk])
	
func has_exit (dir):
	if (dir == ALMain.Dir.LEFT ): return not $Exit_Tilemaps/Left .get_used_cells().empty()
	if (dir == ALMain.Dir.RIGHT): return not $Exit_Tilemaps/Right.get_used_cells().empty()
	if (dir == ALMain.Dir.UP   ): return not $Exit_Tilemaps/Up   .get_used_cells().empty()
	if (dir == ALMain.Dir.DOWN ): return not $Exit_Tilemaps/Down .get_used_cells().empty()

func _ready ():
	var rect = $TileMap.get_used_rect()
	for x in range(rect.position.x, rect.size.x):
		var empty = false
		for y in range(rect.position.y, rect.size.y):
			var pos = Vector2(x, y)
			if $Exit_Tilemaps/Left .get_used_cells().has(pos): continue
			if $Exit_Tilemaps/Right.get_used_cells().has(pos): continue
			if $Exit_Tilemaps/Up   .get_used_cells().has(pos): continue
			if $Exit_Tilemaps/Down .get_used_cells().has(pos): continue
			if $TileMap.get_used_cells().has(pos):
				empty = not empty
			elif empty:
				empty_cells.append(pos)
				if min_empty_cell == null:
					min_empty_cell = pos
				else:
					min_empty_cell.x = min(min_empty_cell.x, x)
					min_empty_cell.y = min(min_empty_cell.y, y)

func SpawnBullet (pos:Vector2, velocity:Vector2, damage:int):
	var bullet = preload("res://Scenes/Bullet.tscn").instance()
	bullet.global_position = pos
	bullet.Init(velocity, damage)
	$Bullets.add_child(bullet)

func ToChunkPosition (pos):
	return tile_to_chunk_pos(pos / $TileMap.cell_size)

func GetPossibleExitDirs ():
	var dirs = []
	for dir in ALMain.GetAllDirs():
		if has_exit(dir):
			dirs.append(dir)
	return dirs

func GetPossibleChunkExitDirs ():
	var chunk_exit_dirs = {}
	for chunk_pos in GetChunks():
		chunk_exit_dirs[chunk_pos] = []
	for dir in ALMain.GetAllDirs():
		if has_exit(dir):
			var tilemap = {
				ALMain.Dir.LEFT : $Exit_Tilemaps/Left,
				ALMain.Dir.RIGHT: $Exit_Tilemaps/Right,
				ALMain.Dir.UP   : $Exit_Tilemaps/Up,
				ALMain.Dir.DOWN : $Exit_Tilemaps/Down
			}[dir]
			for exit_rect in get_grouped_tilemap_rects(tilemap):
				var tile_pos = exit_rect.position - ALMain.DirVector(dir)
				var chunk_pos = tile_to_chunk_pos(tile_pos)
				chunk_exit_dirs[chunk_pos].append(dir)
	return chunk_exit_dirs

func GetExitPosition (chunk_pos, dir):
	return chunk_dir_exit_positions[chunk_pos][dir]

func GetWallPositions ():
	return $TileMap.get_used_cells()

func GetRect ():
	return $TileMap.get_used_rect()

func GetInsideSize ():
	return $TileMap.get_used_rect().size - Vector2(2, 2)

func GetChunks ():
	var chunks = []
	for pos in empty_cells:
		var chunk_pos = tile_to_chunk_pos(pos)
		if not chunks.has(chunk_pos):
			chunks.append(chunk_pos)
	return chunks

func Init (
	_room : ALMain.MapRoom,
	entered_from_dir
):
	room = _room
	
	var bullets = Node2D.new()
	bullets.name = "Bullets"
	add_child(bullets)
	
	var exits = Node2D.new()
	exits.name = "Exits"
	add_child(exits)
	
	var enemies = Node2D.new()
	enemies.name = "Enemies"
	add_child(enemies)
	
#	if has_exit(ALMain.Dir.LEFT ): create_exit(ALMain.Dir.LEFT,  $Exit_Tilemaps/Left,  "MoveLeft")
#	if has_exit(ALMain.Dir.RIGHT): create_exit(ALMain.Dir.RIGHT, $Exit_Tilemaps/Right, "MoveRight")
#	if has_exit(ALMain.Dir.UP   ): create_exit(ALMain.Dir.UP,    $Exit_Tilemaps/Up,    "MoveTop")
#	if has_exit(ALMain.Dir.DOWN ): create_exit(ALMain.Dir.DOWN,  $Exit_Tilemaps/Down,  "MoveBottom")
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
