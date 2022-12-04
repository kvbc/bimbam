#
# Old pathfinding algorithms, both of which suffer greatly from performance issues
# The current pathfinding implementation resides in the /modules directory and is written in C++
#

#####################################################################################
#
# CUSTOM A*
#
#####################################################################################

#extends AStar2D
#class_name Pathfinding
#
##
## TODO: add support for various agent sizes
##
#
#class Tile:
#	var id
#	var width  : int # in tiles
#	var height : int # in tiles
#	var agent = null
#
#	func _init (_id, _width, _height):
#		id = _id
#		width = _width
#		height = _height
#
#	func GetWidth  (): return width
#	func GetHeight (): return height
#	func GetId     (): return id
#
#	func GetAgent    ()      : return agent
#	func SetAgent    (_agent): agent = _agent
#
##
##
## PRIVATE
##
##
#
#var tiles = {} # tile pos -> Tile
#var agent_tile_positions = {} # agent id -> agent tile positions
#var current_agent = null
## DEBUG
#var latest_agent_path = {} # agent id -> tile path
#
#func _init (tile_positions : Array):
#	for tile_pos in tile_positions:
#		var width = 0
#		var height = 0
#		var next_tile_pos = tile_pos
#		while tile_positions.has(next_tile_pos):
#			width += 1
#			next_tile_pos = Vector2(next_tile_pos.x + 1, next_tile_pos.y)
#		next_tile_pos = tile_pos
#		while tile_positions.has(next_tile_pos):
#			height += 1
#			next_tile_pos = Vector2(next_tile_pos.x, next_tile_pos.y + 1)
#
#		var id = get_available_point_id()
#		tiles[tile_pos] = Tile.new(id, width, height)
#		add_point(id, tile_pos)
#
#	for tile_pos in tile_positions:
#		var tile_pos_left     = tile_pos + Vector2.LEFT
#		var tile_pos_right    = tile_pos + Vector2.RIGHT
#		var tile_pos_up       = tile_pos + Vector2.UP
#		var tile_pos_down     = tile_pos + Vector2.DOWN
#		var tile_pos_topleft  = tile_pos + Vector2.UP   + Vector2.LEFT
#		var tile_pos_topright = tile_pos + Vector2.UP   + Vector2.RIGHT
#		var tile_pos_botleft  = tile_pos + Vector2.DOWN + Vector2.LEFT
#		var tile_pos_botright = tile_pos + Vector2.DOWN + Vector2.RIGHT
#
#		var left  = tiles.has(tile_pos_left)
#		var right = tiles.has(tile_pos_right)
#		var up    = tiles.has(tile_pos_up)
#		var down  = tiles.has(tile_pos_down)
##		var topleft  = up and left and tiles.has(tile_pos_topleft)
##		var topright = up and right and tiles.has(tile_pos_topright)
##		var botleft  = down and left and tiles.has(tile_pos_botleft)
##		var botright = down and right and tiles.has(tile_pos_botright)
#
#		if left     : connect_points(tiles[tile_pos].GetId(), tiles[tile_pos_left].GetId())
#		if right    : connect_points(tiles[tile_pos].GetId(), tiles[tile_pos_right].GetId())
#		if up       : connect_points(tiles[tile_pos].GetId(), tiles[tile_pos_up].GetId())
#		if down     : connect_points(tiles[tile_pos].GetId(), tiles[tile_pos_down].GetId())
##		if topleft  : connect_points(tiles[tile_pos].GetId(), tiles[tile_pos_topleft].GetId())
##		if topright : connect_points(tiles[tile_pos].GetId(), tiles[tile_pos_topright].GetId())
##		if botleft  : connect_points(tiles[tile_pos].GetId(), tiles[tile_pos_botleft].GetId())
##		if botright : connect_points(tiles[tile_pos].GetId(), tiles[tile_pos_botright].GetId())
#
#func _compute_cost (from_id, to_id):
#	var to_tile_pos = get_point_position(to_id)
#	var tile = tiles[to_tile_pos]
#	if tile.GetAgent() != current_agent and tile.GetAgent() != null:
#		return 2137
#	return 1
#
#func _estimate_cost (from_id, to_id):
#	var to_tile_pos = get_point_position(to_id)
#	var tile = tiles[to_tile_pos]
#	if tile.GetAgent() != current_agent and tile.GetAgent() != null:
#		return 2137
#	return get_point_position(from_id).distance_to(to_tile_pos)
#
##
##
## PUBLIC
##
##
#
#func GetPath (agent_id, from_tile_pos, to_tile_pos):
#	if not tiles.has(from_tile_pos) : return []
#	if not tiles.has(to_tile_pos)   : return []
#
#	if agent_tile_positions.has(agent_id):
#		for tile_pos in agent_tile_positions[agent_id]:
#			tiles[tile_pos].SetAgent(null)
#			agent_tile_positions[agent_id].erase(tile_pos)
#	else:
#		agent_tile_positions[agent_id] = []
#	current_agent = agent_id
#	agent_tile_positions[agent_id].append(from_tile_pos)
#	tiles[from_tile_pos].SetAgent(agent_id)
#
#	var path = get_point_path(tiles[from_tile_pos].GetId(), tiles[to_tile_pos].GetId())
#	latest_agent_path[agent_id] = path
#
#	return path
#
##
##
## DEBUG
##
##
#
#func DBGGetTilePositions ():
#	return tiles.keys()
#
#func DBGGetTile (tile_pos) -> Tile:
#	return tiles[tile_pos]
#
#func DBGGetTileNeighbourPositions (tile):
#	var neighbours = []
#	for id in get_point_connections(tile.GetId()):
#		neighbours.append(get_point_position(id))
#	return neighbours
#
#func DBGGetAgentPositions ():
#	var all_positions = []
#	for agent_positions in agent_tile_positions.values():
#		all_positions.append_array(agent_positions)
#	return all_positions
#
#func DBGGetLatestPathPositions ():
#	var points = []
#	for path in latest_agent_path.values():
#		points.append_array(path)
#	return points

#####################################################################################
#
# CUSTOM FLOW FIELD
#
#####################################################################################

#class_name Pathfinding
#
#enum Dir {
#	LEFT,
#	RIGHT,
#	UP,
#	DOWN,
#	TOPLEFT,
#	TOPRIGHT,
#	BOTLEFT,
#	BOTRIGHT
#}
#
#var tile_positions
#var flow_field = {} # tile pos -> dir
#var distance_to_target = {} # tile pos -> distance
#var agents_tile_position = {} # agent id -> tile position
#var dir_vectors = {
#	Dir.LEFT     : Vector2.LEFT,
#	Dir.RIGHT    : Vector2.RIGHT,
#	Dir.UP       : Vector2.UP,
#	Dir.DOWN     : Vector2.DOWN,
#	Dir.TOPLEFT  : Vector2.UP + Vector2.LEFT,
#	Dir.TOPRIGHT : Vector2.UP + Vector2.RIGHT,
#	Dir.BOTLEFT  : Vector2.DOWN + Vector2.LEFT,
#	Dir.BOTRIGHT : Vector2.DOWN + Vector2.RIGHT
#}
#
#func _init (_tile_positions):
#	tile_positions = _tile_positions
#
#func dir_vector (dir):
##	return {
##		Dir.LEFT     : Vector2.LEFT,
##		Dir.RIGHT    : Vector2.RIGHT,
##		Dir.UP       : Vector2.UP,
##		Dir.DOWN     : Vector2.DOWN,
##		Dir.TOPLEFT  : Vector2.UP + Vector2.LEFT,
##		Dir.TOPRIGHT : Vector2.UP + Vector2.RIGHT,
##		Dir.BOTLEFT  : Vector2.DOWN + Vector2.LEFT,
##		Dir.BOTRIGHT : Vector2.DOWN + Vector2.RIGHT
##	}[dir]
#	match dir:
#		Dir.LEFT     : return Vector2.LEFT
#		Dir.RIGHT    : return Vector2.RIGHT
#		Dir.UP       : return Vector2.UP
#		Dir.DOWN     : return Vector2.DOWN
#		Dir.TOPLEFT  : return Vector2.UP + Vector2.LEFT
#		Dir.TOPRIGHT : return Vector2.UP + Vector2.RIGHT
#		Dir.BOTLEFT  : return Vector2.DOWN + Vector2.LEFT
#		Dir.BOTRIGHT : return Vector2.DOWN + Vector2.RIGHT
#
#func is_tile_occupied (tile_pos):
#	return agents_tile_position.values().has(tile_pos)
#
##
##
## PUBLIC
##
##
#
#func UpdateAgent (agent_id, tile_pos):
#	agents_tile_position[agent_id] = tile_pos
#
#func Update (target_tile_pos):
#	distance_to_target.clear()
#	flow_field.clear()
#
#	var open = [target_tile_pos]
#	distance_to_target[target_tile_pos] = 0
#	while not open.empty():
#		var tile_pos = open[0]
#		for dir in Dir.values():
#			var neighbour_tile_pos = tile_pos + dir_vectors[dir]
#			if tile_positions.has(neighbour_tile_pos) and not is_tile_occupied(neighbour_tile_pos):
#				var distance = distance_to_target[tile_pos] + neighbour_tile_pos.distance_to(tile_pos)
#				if distance_to_target.has(neighbour_tile_pos):
#					distance_to_target[neighbour_tile_pos] = min(distance_to_target[neighbour_tile_pos], distance)
#				else:
#					distance_to_target[neighbour_tile_pos] = distance
#					open.append(neighbour_tile_pos)
#		open.erase(tile_pos)
#
#	for tile_pos in tile_positions:
#		var closest_neighbour_tile_pos = null
#		var closest_dir = null
#		for dir in Dir.values():
#			var neighbour_tile_pos = tile_pos + dir_vectors[dir]
#			if distance_to_target.has(neighbour_tile_pos): # and not is_tile_occupied(neighbour_tile_pos):
#				if closest_neighbour_tile_pos == null or distance_to_target[neighbour_tile_pos] < distance_to_target[closest_neighbour_tile_pos]:
#					closest_neighbour_tile_pos = neighbour_tile_pos
#					closest_dir = dir
#		flow_field[tile_pos] = closest_dir
#	flow_field[target_tile_pos] = null
#
#func GetNextAgentPosition (agent_id):
#	var tile_pos = agents_tile_position[agent_id]
#	if flow_field.get(tile_pos) != null:
#		return tile_pos + dir_vectors[flow_field[tile_pos]]
#	return null
#
##
##
## DEBUG
##
##
#
#func DBGGetTilePositions ():
#	return tile_positions
#
#func DBGGetFlowField ():
#	return flow_field
#
#func DBGGetDistanceField ():
#	return distance_to_target
#
#func DBGGetAgentTilePositions ():
#	return agents_tile_position.values()
