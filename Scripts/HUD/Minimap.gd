extends Control

var is_inited = false

const SIZE = Vector2(8, 8)

func get_room_draw_positions (room, pos, visited = {}):
	if visited.has(room):
		return visited
	visited[room] = pos
	
	for chunk_pos in ALMain.room_chunks[room.type]:
		if room.HasChunk(chunk_pos):
			var chunk = room.GetChunk(chunk_pos)
			for dir in ALMain.room_chunk_exit_dirs[room.type][chunk_pos]:
				if chunk.HasNeighbour(dir):
					var neighbour_chunk = chunk.GetNeighbour(dir)
					var neighbour_room = neighbour_chunk.GetRoom()
					var new_pos = pos + chunk_pos * ALMain.GetRoomTilesPerChunk() * SIZE
					new_pos += ALMain.DirVector(dir) * ALMain.GetRoomTilesPerChunk() * SIZE
					new_pos -= neighbour_chunk.pos * ALMain.GetRoomTilesPerChunk() * SIZE
					visited = get_room_draw_positions(neighbour_room, new_pos, visited)
	return visited

func _draw ():
	if not is_inited:
		return
	var visited = get_room_draw_positions(ALMain.map, Vector2.ZERO)
	for room in visited.keys():
		var pos = visited[room]
		pos += $ColorRect.rect_size / 2 # center the container
		pos -= ALMain.room_rects[ALMain.current_room.type].size / 2 * SIZE # center the room
		pos -= visited[ALMain.current_room] # center all rooms
		for wall_pos in ALMain.room_wall_positions[room.type]:
			var rect = Rect2(pos + wall_pos * SIZE, SIZE)
			if room == ALMain.current_room:
				draw_rect(rect, Color.red)
			else:
				draw_rect(rect, Color.white)

func Init ():
	is_inited = true
	update()
	pass
	
func Update ():
	update()
