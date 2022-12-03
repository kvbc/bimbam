extends Node

func gcd (a:int, b:int):
	return b if a == 0 else gcd(b % a, a)

#
#
# Public
#
#

func GCDArray (arr):
	if arr.empty():
		return 0
	var r = arr[0]
	for i in range(1, arr.size()):
		r = gcd(arr[i], r)
	return r

func RandomArrayElement (arr):
	return arr[randi() % arr.size()]

func GroupTilemapTiles (tilemap, groups = [], visited_tiles = [], group = [], cell = null):
	if cell in visited_tiles:
		return
		
	if cell != null:
		if not tilemap.get_used_cells().has(cell):
			return
		
	var cell_was_null = cell == null
	if cell == null:
		for pos in tilemap.get_used_cells():
			if not pos in visited_tiles:
				cell = pos
	if cell == null:
		return groups
				
	visited_tiles.append(cell)
	group.append(cell)
	GroupTilemapTiles(tilemap, groups, group, visited_tiles, Vector2(cell.x - 1, cell.y))
	GroupTilemapTiles(tilemap, groups, group, visited_tiles, Vector2(cell.x + 1, cell.y))
	GroupTilemapTiles(tilemap, groups, group, visited_tiles, Vector2(cell.x, cell.y - 1))
	GroupTilemapTiles(tilemap, groups, group, visited_tiles, Vector2(cell.x, cell.y + 1))
	
	if cell_was_null:
		groups.append(group)
		return GroupTilemapTiles(tilemap, groups, visited_tiles)

func AngleDistance (a, b):
	return abs(fposmod(a - b + 180, 360) - 180)
