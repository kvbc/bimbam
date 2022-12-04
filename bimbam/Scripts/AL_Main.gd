extends Node
signal setting_changed

const PLAYER_SPEED = 500
const PLAYER_IFRAMES = 0.5 # in seconds
const PLAYER_MAX_HP = 3 # in hearts
const PLAYER_HAND_RANGE = 200

const ENEMY_IFRAMES = 1 # in seconds
const ENEMY_FLEE_RADIUS = 150
const ENEMY_SHOOT_RADIUS = 300

const BULLET_SPEED = 300
const BULLET_LIFETIME = 5.0 # in seconds

const MAX_MAP_DEPTH = 15

const CAMERA_ZOOM_SENSITIVITY = 0.05
const MINIMAP_ZOOM_SENSITIVITY = 1

#
#
# Settings
#
#

enum SettingType {
	SHOW_ROOM_CHUNKS,
	SHOW_ROOM_PATHFINDING,
	SHOW_INTERIOR_ROOM_TILES,
	SHOW_COLLISION_SHAPES,
	SHOW_ENEMY_STEERING_RAYS,
	SHOW_ENEMY_FLEE_AREA,
	SHOW_ENEMY_SHOOT_AREA,
	RESOLUTION,
	VSYNC,
	SHOW_FPS
}

#
#
# Enemy
#
#

class EnemyData:
	var contact_damage : float # in hearts
	var move_speed     : float 
	var bullet_damage  : float # in hearts
	var max_health     : float # in hearts
	
	func _init (_move_speed, _contact_damage, _bullet_damage, _max_health):
		move_speed     = _move_speed
		contact_damage = _contact_damage
		bullet_damage  = _bullet_damage
		max_health = _max_health
		
	func GetContactDamage (): return contact_damage
	func GetMoveSpeed     (): return move_speed
	func GetBulletDamage  (): return bullet_damage
	func GetMaxHealth     (): return max_health

enum EnemyType {
	MENEL,
	CRACKHEAD,
	SKIN
}

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

#
#
# Room
#
#

class RoomChunk:
	var pos : Vector2 # chunk pos
	var room : MapRoom
	var neighbour_left  : RoomChunk
	var neighbour_right : RoomChunk
	var neighbour_up    : RoomChunk
	var neighbour_down  : RoomChunk

	func _init (_room:MapRoom, _pos:Vector2):
		room = _room
		pos = _pos

	func GetRoom ():
		return room

	func GetPosition ():
		return pos

	func GetNeighbour (dir):
		match dir:
			Dir.LEFT : return neighbour_left
			Dir.RIGHT: return neighbour_right
			Dir.UP   : return neighbour_up
			Dir.DOWN : return neighbour_down

	func HasNeighbour (dir):
		return GetNeighbour(dir) != null
		
	func SetNeighbour (dir, chunk : RoomChunk):
		match dir:
			Dir.LEFT : neighbour_left  = chunk
			Dir.RIGHT: neighbour_right = chunk
			Dir.UP   : neighbour_up    = chunk
			Dir.DOWN : neighbour_down  = chunk
		
class MapRoom:
	var type : String # see set_room_as_scene()
	var pos  : Vector2
	var chunks # chunk pos -> RoomChunk
	
	func _init (_type:String, _x:int, _y:int):
		type = _type
		pos = Vector2(_x, _y)
		chunks = {}
		
	func GetChunks ():
		return chunks.values()
		
	func GetChunk (chunk_pos):
		return chunks.get(chunk_pos)
		
	func HasChunk (chunk_pos):
		return GetChunk(chunk_pos) != null
		
	func AddChunk (chunk : RoomChunk):
		chunks[chunk.GetPosition()] = chunk

#
#
# PRIVATE
#
#

var xy_rooms = {} # vec2 -> MapRoom
var map = MapRoom.new("donut", 0, 0) # first MapRoom
var current_room : MapRoom = null
var current_room_scene : Node = null
var player = null
var is_paused = false
var settings = {} # SettingType -> value
var enemy_data = {
	EnemyType.MENEL    : EnemyData.new(250, 0.5, 0.0, 1),
	EnemyType.CRACKHEAD: EnemyData.new(250, 0.5, 0.5, 1),
	EnemyType.SKIN     : EnemyData.new(250, 0.5, 0.0, 1)
}
#
# Below room cache variables are auto-generated in _ready() 
#
var room_chunk_positions   = {} # room type     -> room's chunk positions[]
var room_types             = {} # room exit dir -> room types[] that have exit on that direction
var room_wall_tile_offsets = {} # room type     -> room wall tile offsets[]
var room_chunk_exit_dirs   = {} # room type     -> room's chunk position   -> exit directions[]
var room_tile_sizes        = {} # room type     -> room's size in tiles
var room_chunk_exit_tile_offsets = {}
var room_interior_tile_offsets = {}
var room_tiles_per_chunk   = null

func expand_room (room:MapRoom, depth = 0):
	if (depth >= MAX_MAP_DEPTH):
		return
		
	for chunk_pos in room_chunk_positions[room.type]:
		xy_rooms[room.pos + chunk_pos] = room
	
	for chunk_pos in room_chunk_positions[room.type]: # for every chunk
		if not room.HasChunk(chunk_pos): # if it doesnt exist
			var chunk = RoomChunk.new(room, chunk_pos) # create one
			for dir in room_chunk_exit_dirs[room.type][chunk_pos]: # for every chunk's exit direction
				# generate a new neighbour room
				var opp_dir = OppositeDir(dir)
				var new_type = ALUtil.RandomArrayElement(room_types[opp_dir])
				
				var x = room.pos.x + chunk_pos.x + DirVector(dir).x
				var y = room.pos.y + chunk_pos.y + DirVector(dir).y
				
				# brute-force first available neighbour's chunk position matching {dir} for {new_type}
				var valid = false
				var new_chunk_pos
				for idx in room_chunk_positions[new_type].size():
					new_chunk_pos = room_chunk_positions[new_type][idx]
					if opp_dir in room_chunk_exit_dirs[new_type][new_chunk_pos]:
						var new_x = x - new_chunk_pos.x
						var new_y = y - new_chunk_pos.y
						valid = true
						for _chunk_pos in room_chunk_positions[new_type]:
							if xy_rooms.has(Vector2(new_x, new_y) + _chunk_pos):
								valid = false
								break
						if valid:
							x = new_x
							y = new_y
							break
				if not valid:
					continue
				
				var new_room = MapRoom.new(new_type, x, y)
				var new_chunk = RoomChunk.new(new_room, new_chunk_pos)
				new_chunk.SetNeighbour(opp_dir, chunk)
				new_room.AddChunk(new_chunk)
				chunk.SetNeighbour(dir, new_chunk)
				expand_room(new_room, depth + 1)
			room.AddChunk(chunk)

func get_room_scene_path (room_type : String):
	return "res://Scenes/Rooms/" + room_type + ".tscn"

func set_room_as_current_scene (room:MapRoom, entered_from_dir = null):
	var new_plr_chunk
	if entered_from_dir != null:
		var plr_chunk_pos = current_room_scene.WorldToChunkPosition(player.global_position)
		var closest_plr_chunk_pos
		for chunk_pos in room_chunk_positions[current_room.type]:
			if closest_plr_chunk_pos == null or plr_chunk_pos.distance_to(chunk_pos) < plr_chunk_pos.distance_to(closest_plr_chunk_pos):
				closest_plr_chunk_pos = chunk_pos
		var plr_chunk = current_room.GetChunk(closest_plr_chunk_pos)
		new_plr_chunk = plr_chunk.GetNeighbour(OppositeDir(entered_from_dir))
	
	current_room = room
	ALHUD.GetMinimap().UpdateCurrentRoom(current_room)
	
	player = null
	
	get_tree().change_scene(get_room_scene_path(room.type))
	yield(get_tree(), "idle_frame") # change_scene() is deferred
	current_room_scene = get_tree().current_scene
	current_room_scene.Init(
		room,
		entered_from_dir
	)
	
	player = preload("res://Scenes/Player.tscn").instance()
	if entered_from_dir != null and new_plr_chunk != null:
		player.global_position = current_room_scene.GetChunkExitPosition(new_plr_chunk.GetPosition(), entered_from_dir)
	else:
		player.global_position = Vector2(500, 300)
	current_room_scene.add_child(player)
	player.call_deferred("connect", "damaged", self, "on_player_damaged")

func on_player_damaged ():
	ALHUD.GetHPDisplay().Update(player.GetHealth())

func _ready ():
	# auto-generate a list of room types
	# based on filenames of all the room scenes
	var room_scene_names = []
	var room_scenes_dir = Directory.new()
	room_scenes_dir.open("res://Scenes/Rooms/")
	room_scenes_dir.list_dir_begin()
	while true:
		var file_name = room_scenes_dir.get_next()
		if file_name.empty():
			break
		if file_name.ends_with(".tscn"):
			room_scene_names.append(file_name.trim_suffix(".tscn"))
	room_scenes_dir.list_dir_end()
	# cache all the necessary stuff from each room type
	var room_sizes = []
	var rooms = []
	for room_type in room_scene_names:
		var room = load(get_room_scene_path(room_type)).instance()
		get_tree().get_root().call_deferred("add_child", room)
		yield(room, "ready")
		room_sizes.append(room.GetTileSize().x)
		room_sizes.append(room.GetTileSize().y)
		room_tile_sizes[room_type] = room.GetTileSize()
		room_wall_tile_offsets[room_type] = room.GetWallTileOffsets()
		room_interior_tile_offsets[room_type] = room.GetInteriorTileOffsets()
		for dir in room.GetPossibleExitDirs():
			if not room_types.has(dir):
				room_types[dir] = []
			room_types[dir].append(room_type)
		rooms.append(room)
	# based on the size of each room
	# calculate the maximum size (in tiles) for one square chunk
	# which will be the greatest common divisor of all room sizes
	room_tiles_per_chunk = ALUtil.GCDArray(room_sizes)
	for idx in rooms.size():
		var room = rooms[idx]
		var room_type = room_scene_names[idx]
		room_chunk_positions[room_type] = room.GetChunkPositions()
		room_chunk_exit_dirs[room_type] = room.GetPossibleChunkExitDirs()
		room_chunk_exit_tile_offsets[room_type] = room.GetChunkExitTileOffsets()
		room.queue_free()
	
	randomize()
	expand_room(map)
	ALHUD.Init()
	set_room_as_current_scene(map)
	
	ALHUD.GetHPDisplay().Init(PLAYER_MAX_HP)
	
	for setting_type in GetSettingTypes():
		SetSetting(setting_type, GetSettingValues(setting_type)[0])

func _process (_delta):
	if GetSetting(SettingType.SHOW_FPS) == "yes":
		ALHUD.GetFPSLabel().Update(Engine.get_frames_per_second())

#
#
# PUBLIC
#
#

func GetDebugFont (size):
	var font = DynamicFont.new()
	font.font_data = preload("res://Assets/Fonts/Milky Boba.ttf")
	font.size = size
	return font

func GetSetting (setting_type, default_value = null):
	return settings.get(setting_type, default_value)

func SetSetting (setting_type, value):
	settings[setting_type] = value
	emit_signal("setting_changed", setting_type, value)
	match setting_type:
		SettingType.SHOW_COLLISION_SHAPES:
			get_tree().debug_collisions_hint = (value == "yes")
		SettingType.RESOLUTION:
			OS.window_size = {
				"1280x1024": Vector2(1280, 1024),
				"1366x768" : Vector2(1366, 768),
				"1600x900" : Vector2(1600, 900),
				"1920x1080": Vector2(1920, 1080)
			}[value]
		SettingType.VSYNC:
			OS.vsync_enabled = (value == "on")
		SettingType.SHOW_FPS:
			if value == "yes":
				ALHUD.GetFPSLabel().Show()
			else:
				ALHUD.GetFPSLabel().Hide()

func GetSettingTypes ():
	return range(SettingType.size())

func GetSettingName (setting_type):
	return {
		SettingType.SHOW_ROOM_CHUNKS         : "show room chunks",
		SettingType.SHOW_ROOM_PATHFINDING    : "show room pathfinding",
		SettingType.SHOW_INTERIOR_ROOM_TILES : "show interior room tiles",
		SettingType.SHOW_COLLISION_SHAPES    : "show collision shapes",
		SettingType.SHOW_ENEMY_STEERING_RAYS : "show enemy steering rays",
		SettingType.SHOW_ENEMY_FLEE_AREA     : "show enemy flee area",
		SettingType.SHOW_ENEMY_SHOOT_AREA    : "show enemy shoot area",
		SettingType.RESOLUTION               : "resolution",
		SettingType.VSYNC                    : "VSync",
		SettingType.SHOW_FPS				 : "show FPS"
	}[setting_type]

func GetSettingValues (setting_type):
	return {
		SettingType.SHOW_ROOM_CHUNKS         : ["no", "yes"],
		SettingType.SHOW_ROOM_PATHFINDING    : ["no", "yes"],
		SettingType.SHOW_INTERIOR_ROOM_TILES : ["no", "yes"],
		SettingType.SHOW_COLLISION_SHAPES    : ["no", "yes"],
		SettingType.SHOW_ENEMY_STEERING_RAYS : ["no", "yes"],
		SettingType.SHOW_ENEMY_FLEE_AREA     : ["no", "yes"],
		SettingType.SHOW_ENEMY_SHOOT_AREA    : ["no", "yes"],
		SettingType.RESOLUTION               : ["1920x1080", "1280x1024", "1366x768", "1600x900"],
		SettingType.VSYNC                    : ["on", "off"],
		SettingType.SHOW_FPS				 : ["no", "yes"]
	}[setting_type]

func IsPaused ():
	return is_paused

func Pause ():
	get_tree().paused = true
	is_paused = true
	
func Unpause ():
	get_tree().paused = false
	is_paused = false

func GetCurrentRoomScene         ()                         : return current_room_scene
func GetRoomTilesPerChunk        ()                         : return room_tiles_per_chunk
func GetRoomChunkPositions       (room_type)                : return room_chunk_positions[room_type]
func GetRoomChunkExitDirections  (room_type, chunk_pos)     : return room_chunk_exit_dirs[room_type][chunk_pos]
func GetRoomWallTileOffsets      (room_type)                : return room_wall_tile_offsets[room_type]
func GetRoomTileSize             (room_type)                : return room_tile_sizes[room_type]
func GetRoomChunkExitTileOffsets (room_type, chunk_pos, dir): return room_chunk_exit_tile_offsets[room_type][chunk_pos][dir]
func GetRoomInteriorTileOffsets  (room_type)                : return room_interior_tile_offsets[room_type]
	
func IsBodyPlayer (body:KinematicBody2D):
	return body == player

func GetPlayer ():
	return player

func GetAllDirs ():
	return [
		Dir.LEFT,
		Dir.RIGHT,
		Dir.UP,
		Dir.DOWN
	]

func OppositeDir (dir):
	match dir:
		Dir.LEFT : return Dir.RIGHT
		Dir.RIGHT: return Dir.LEFT
		Dir.UP   : return Dir.DOWN
		Dir.DOWN : return Dir.UP

func DirFromString (dir_str : String):
	match dir_str:
		"Left" : return ALMain.Dir.LEFT
		"Right": return ALMain.Dir.RIGHT
		"Up"   : return ALMain.Dir.UP
		"Down" : return ALMain.Dir.DOWN

func DirVector (dir):
	match dir:
		Dir.LEFT : return Vector2.LEFT
		Dir.RIGHT: return Vector2.RIGHT
		Dir.UP   : return Vector2.UP
		Dir.DOWN : return Vector2.DOWN

func GetEnemyData (enemy_type):
	return enemy_data[enemy_type]

func EnemyNameToType (enemy_name):
	match enemy_name:
		"Menel"    : return EnemyType.MENEL
		"Crackhead": return EnemyType.CRACKHEAD
		"Skin"     : return EnemyType.SKIN

func MoveLeft   (room_chunk : RoomChunk): set_room_as_current_scene(room_chunk.GetNeighbour(Dir.LEFT ).GetRoom(), Dir.RIGHT)
func MoveRight  (room_chunk : RoomChunk): set_room_as_current_scene(room_chunk.GetNeighbour(Dir.RIGHT).GetRoom(), Dir.LEFT)
func MoveTop    (room_chunk : RoomChunk): set_room_as_current_scene(room_chunk.GetNeighbour(Dir.UP   ).GetRoom(), Dir.DOWN)
func MoveBottom (room_chunk : RoomChunk): set_room_as_current_scene(room_chunk.GetNeighbour(Dir.DOWN ).GetRoom(), Dir.UP)
