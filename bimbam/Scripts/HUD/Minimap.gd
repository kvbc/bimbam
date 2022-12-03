extends Control

var current_room = null
var room_tile_positions = {} # MapRoom -> tile position

func _input (event):
	if event is InputEventMouseButton:
		if event.pressed:
			if $ViewportContainer/Viewport.get_visible_rect().has_point($ViewportContainer/Viewport.get_mouse_position()):
				if event.button_index == BUTTON_WHEEL_UP:
					$ViewportContainer/Viewport/Camera2D.zoom -= ALMain.MINIMAP_ZOOM_SENSITIVITY * Vector2.ONE
				elif event.button_index == BUTTON_WHEEL_DOWN:
					$ViewportContainer/Viewport/Camera2D.zoom += ALMain.MINIMAP_ZOOM_SENSITIVITY * Vector2.ONE

func get_rooms_tile_positions (room, pos):
	if room_tile_positions.has(room):
		return
	room_tile_positions[room] = pos
	for chunk_pos in ALMain.GetRoomChunkPositions(room.type):
		if room.HasChunk(chunk_pos):
			var chunk = room.GetChunk(chunk_pos)
			for dir in ALMain.GetRoomChunkExitDirections(room.type, chunk_pos):
				if chunk.HasNeighbour(dir):
					var neighbour_chunk = chunk.GetNeighbour(dir)
					var new_chunk_pos = chunk_pos + ALMain.DirVector(dir) - neighbour_chunk.pos
					var new_pos = pos + new_chunk_pos * ALMain.GetRoomTilesPerChunk()
					get_rooms_tile_positions(neighbour_chunk.GetRoom(), new_pos)

func update_room (room):
	var red_tile_idx = $ViewportContainer/Viewport/TileMap.tile_set.find_tile_by_name("red")
	var black_tile_idx = $ViewportContainer/Viewport/TileMap.tile_set.find_tile_by_name("black")
	var white_tile_idx = $ViewportContainer/Viewport/TileMap.tile_set.find_tile_by_name("white")
	
	for wall_tile_offset in ALMain.GetRoomWallTileOffsets(room.type):
		var tile_idx = white_tile_idx
		var is_exit = false
		for chunk in room.GetChunks():
			for dir in ALMain.GetAllDirs():
				if chunk.HasNeighbour(dir):
					if wall_tile_offset in ALMain.GetRoomChunkExitTileOffsets(room.type, chunk.GetPosition(), dir):
						is_exit = true
						break
			if is_exit:
				break
		if is_exit:
			tile_idx = black_tile_idx
		elif room == current_room:
			tile_idx = red_tile_idx
		var pos = room_tile_positions[room] + wall_tile_offset
		$ViewportContainer/Viewport/TileMap.set_cell(pos.x, pos.y, tile_idx)
	for interior_tile_offset in ALMain.GetRoomInteriorTileOffsets(room.type):
		var pos = room_tile_positions[room] + interior_tile_offset
		$ViewportContainer/Viewport/TileMap.set_cell(pos.x, pos.y, black_tile_idx)

func Init ():
	get_rooms_tile_positions(ALMain.map, Vector2.ZERO)
	for room in room_tile_positions.keys():
		update_room(room)

func UpdateCurrentRoom (new_room : ALMain.MapRoom):
	if current_room != null:
		var old_room = current_room
		current_room = null
		update_room(old_room)
	current_room = new_room
	update_room(new_room)
	
	var current_room_center_tilepos = room_tile_positions[current_room] + ALMain.GetRoomTileSize(current_room.type) / 2
	$ViewportContainer/Viewport/Camera2D.position = $ViewportContainer/Viewport/TileMap.map_to_world(current_room_center_tilepos)
