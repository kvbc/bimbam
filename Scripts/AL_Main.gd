extends Node

const PLAYER_SPEED = 500
const MAX_MAP_DEPTH = 10

#
#
# Direction
#
#

enum Dir {
	LEFT,
	RIGHT,
	UP,
	DOWN
}

func dir_vector (dir):
	return {
		Dir.LEFT  : Vector2.LEFT,
		Dir.RIGHT : Vector2.RIGHT,
		Dir.UP    : Vector2.UP,
		Dir.DOWN  : Vector2.DOWN
	}[dir]

func opposite_dir (dir):
	return {
		Dir.LEFT  : Dir.RIGHT,
		Dir.RIGHT : Dir.LEFT,
		Dir.UP    : Dir.DOWN,
		Dir.DOWN  : Dir.UP
	}[dir]

#
#
# Room
#
#

class MapRoom:
	var scene : String # see set_room_as_scene()
	var pos : Vector2
	var idx : int # used for the minimap
	var left : MapRoom
	var right : MapRoom
	var up : MapRoom
	var down : MapRoom
	
	func _init (_scene:String, _x:int, _y:int):
		scene = _scene
		pos = Vector2(_x, _y)
	
	func GetNeighbour (dir):
		if (dir == Dir.LEFT ): return left
		if (dir == Dir.RIGHT): return right
		if (dir == Dir.UP   ): return up
		if (dir == Dir.DOWN ): return down
	
	func HasNeighbour (dir):
		return GetNeighbour(dir) != null
	
	func SetNeighbour (dir, room : MapRoom):
		if   (dir == Dir.LEFT ): left  = room
		elif (dir == Dir.RIGHT): right = room
		elif (dir == Dir.UP   ): up    = room
		elif (dir == Dir.DOWN ): down  = room

#
#
# Scenes
#
#

var scenes = { # dir -> scenes
	Dir.LEFT: [
		"BL",
		"TL"
	],
	Dir.RIGHT: [
		"BR",
		"TR"	
	],
	Dir.UP: [
		"TL",
		"TR"	
	],
	Dir.DOWN: [
		"BL",
		"BR"	
	]
}
var scene_dirs = {} # scene -> dir[] (auto-generated in _ready())

#
#
# Private
#
#

var xy_map = {}  # vec2 -> MapRoom
var idx_map = [] # idx -> MapRoom
var map = MapRoom.new("TL", 0, 0) # first MapRoom
var current_room : MapRoom
var player = preload("res://Scenes/Player.tscn").instance()

func expand_room (room:MapRoom, depth = 0):
	if (depth >= MAX_MAP_DEPTH):
		return
		
	xy_map[room.pos] = room
	room.idx = idx_map.size()
	idx_map.append(room)
	
	for dir in scene_dirs[room.scene]:
		if not room.HasNeighbour(dir):
			var opp_dir = opposite_dir(dir)
			var scene = scenes[opp_dir][randi() % scenes[opp_dir].size()]
			var x = room.pos.x + dir_vector(dir).x
			var y = room.pos.y + dir_vector(dir).y
			if not xy_map.has(Vector2(x, y)):
				var new_room = MapRoom.new(scene, x, y)
				new_room.SetNeighbour(opp_dir, room)
				room.SetNeighbour(dir, new_room)
				expand_room(new_room, depth + 1)

func set_room_as_current_scene (room:MapRoom, entered_from_dir = null):
	if current_room != null:
		ALMinimap.MarkRoomInactive(current_room)
	ALMinimap.MarkRoomActive(room)
	
	current_room = room
	if (player.get_parent()):
		player.get_parent().remove_child(player)
	get_tree().change_scene("res://Scenes/Rooms/" + room.scene + ".tscn")
	yield(get_tree(), "idle_frame") # change_scene() is deferred
	
	if entered_from_dir != null:
		get_tree().current_scene.emit_signal("player_entered", entered_from_dir)
		player.global_position = get_tree().current_scene.GetExitPosition(entered_from_dir)
	else:
		player.global_position = Vector2(500, 300)
		
	get_tree().current_scene.add_child(player)

func _ready ():
	randomize()
	
	# generate scene_dirs[] based on scenes[]
	for dir in scenes:
		for scene in scenes[dir]:
			if not scene_dirs.has(scene):
				scene_dirs[scene] = []
			scene_dirs[scene].append(dir)
	
	expand_room(map)
	yield(ALMinimap, "ready")
	set_room_as_current_scene(map)

#
#
# Public
#
#

func MoveLeft   (): if (current_room.HasNeighbour(Dir.LEFT )): set_room_as_current_scene(current_room.GetNeighbour(Dir.LEFT ), Dir.RIGHT)
func MoveRight  (): if (current_room.HasNeighbour(Dir.RIGHT)): set_room_as_current_scene(current_room.GetNeighbour(Dir.RIGHT), Dir.LEFT)
func MoveTop    (): if (current_room.HasNeighbour(Dir.UP   )): set_room_as_current_scene(current_room.GetNeighbour(Dir.UP   ), Dir.DOWN)
func MoveBottom (): if (current_room.HasNeighbour(Dir.DOWN )): set_room_as_current_scene(current_room.GetNeighbour(Dir.DOWN ), Dir.UP)
