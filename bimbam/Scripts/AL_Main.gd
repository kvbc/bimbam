#
# TODO: Improve room generation
#

extends Node
signal setting_changed

const PLAYER_SPEED = 10
const PLAYER_IFRAMES = 0.5 # in seconds
const PLAYER_MAX_HP = 3 # in hearts

const ENEMY_IFRAMES = 1 # in seconds
const ENEMY_FLEE_RADIUS = 2.5
const ENEMY_SHOOT_RADIUS = 5

const BULLET_SPEED = 10
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
	SHOW_ROOM_PROP_BOUNDS,
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

enum EnemyType {
	MENEL,
	CRACKHEAD,
	SKIN
}

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
		
	func GetType ():
		return type
		
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
var map = MapRoom.new("2x2", 0, 0) # first MapRoom
var current_room : MapRoom = null
var current_room_scene : Node = null
var player = null
var is_paused = false
var settings = {} # SettingType -> value
var physics_layers = []
var enemy_data = {
	EnemyType.MENEL    : EnemyData.new(5, 0.5, 0.0, 1),
	EnemyType.CRACKHEAD: EnemyData.new(5, 0.5, 0.5, 1),
	EnemyType.SKIN     : EnemyData.new(5, 0.5, 0.0, 1)
}
#
# Below room variables are auto-generated in _ready() 
#
var room_static_data = {} # room type -> Room.StaticData
var room_possible_dir_types = {} # dir -> room types[]
var room_tiles_per_chunk   = null

func expand_room (room:MapRoom, depth = 0):
	if (depth >= MAX_MAP_DEPTH):
		return
		
	var data = GetRoomStaticData(room.GetType())
	for chunk_pos in data.GetChunkPositions():
		xy_rooms[room.pos + chunk_pos] = room
	
	for chunk_pos in data.GetChunkPositions(): # for every chunk
		if not room.HasChunk(chunk_pos): # if it doesnt exist
			var chunk = RoomChunk.new(room, chunk_pos) # create one
			for dir in data.GetPossibleChunkExitDirs()[chunk_pos]: # for every chunk's exit direction
				# generate a new neighbour room
				var opp_dir = OppositeDir(dir)
				var new_type = ALUtil.RandomArrayElement(room_possible_dir_types[opp_dir])
				var new_data = GetRoomStaticData(new_type)
				
				var x = room.pos.x + chunk_pos.x + DirVector(dir).x
				var y = room.pos.y + chunk_pos.y + DirVector(dir).y
				
				# brute-force first available neighbour's chunk position matching {dir} for {new_type}
				var valid = false
				var new_chunk_pos
				for idx in new_data.GetChunkPositions().size():
					new_chunk_pos = new_data.GetChunkPositions()[idx]
					if opp_dir in new_data.GetPossibleChunkExitDirs()[new_chunk_pos]:
						var new_x = x - new_chunk_pos.x
						var new_y = y - new_chunk_pos.y
						valid = true
						for _chunk_pos in new_data.GetChunkPositions():
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
	var new_plr_chunk = null
	if entered_from_dir != null:
		var plr_chunk_pos = current_room_scene.Get2DWorldToChunkPosition(ALMain.Get3Dto2DVector(player.Get3DPosition()))
		var closest_plr_chunk_pos
		for chunk_pos in GetRoomStaticData(current_room.GetType()).GetChunkPositions():
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
#	if entered_from_dir != null and new_plr_chunk != null:
#		player.Set2DPosition(GetRoomStaticData(current_room.GetType()).GetChunkExitPosition(new_plr_chunk.GetPosition(), entered_from_dir))
#	else:
	if true:
		player.Set3DPosition(Vector3.ZERO)
	current_room_scene.add_child(player)
	player.call_deferred("connect", "damaged", self, "on_player_damaged")
		
	var camera = Camera.new()
	camera.current = true
	camera.set_script(preload("res://Scripts/Camera.gd"))
	current_room_scene.add_child(camera)

func on_player_damaged ():
	ALHUD.GetHPDisplay().Update(player.GetHealth())

func _ready ():
	for i in range(1, 32):
		var layer_name = ProjectSettings.get_setting("layer_names/3d_physics/layer_" + str(i))
		physics_layers.append(layer_name)

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
		room_sizes.append(room.GetSizeInTiles().x)
		room_sizes.append(room.GetSizeInTiles().y)
		rooms.append(room)
	# based on the size of each room
	# calculate the maximum size (in tiles) for one square chunk
	# which will be the greatest common divisor of all room sizes
	room_tiles_per_chunk = ALUtil.GCDArray(room_sizes)
	for idx in rooms.size():
		var room = rooms[idx]
		var room_type = room_scene_names[idx]
		var static_data = room.GetStaticData()
		room_static_data[room_type] = static_data
		
		for dir in static_data.GetPossibleExitDirs():
			if not dir in room_possible_dir_types:
				room_possible_dir_types[dir] = []
			room_possible_dir_types[dir].append(room_type)
		
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

func GetMousePosition ():
	return get_viewport().get_mouse_position()

func GetPhysicsLayerIdx (layer_name:String) -> int:
	return physics_layers.find(layer_name)

func Get3DtoScreenPosition (pos3d: Vector3) -> Vector2:
	if pos3d == Vector3.ZERO:
		# there's a division by 0 somewhere in godot's source code of Camera's unproject_position() function
		# which is causing an error with pos3d being exactly Vector3.ZERO
		# this will work for now
		pos3d = 1e-10 * Vector3.ONE
	return get_viewport().get_camera().unproject_position(pos3d)

func Get2Dto3DVector (pos2d: Vector2) -> Vector3:
	return Vector3(pos2d.x, 0, pos2d.y)

func Get3Dto2DVector (pos3d: Vector3) -> Vector2:
	return Vector2(pos3d.x, pos3d.z)

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
		SettingType.SHOW_ROOM_PROP_BOUNDS    : "show room prop bounds",
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
		SettingType.SHOW_ROOM_PROP_BOUNDS    : ["no", "yes"],
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

func GetCurrentRoomScene  ()         : return current_room_scene
func GetRoomTilesPerChunk ()         : return room_tiles_per_chunk
func GetRoomStaticData    (room_type): return room_static_data[room_type]
	
func IsBodyPlayer (body:KinematicBody):
	return body == player

func GetPlayer ():
	return player

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

func Move (room_chunk : RoomChunk, dir):
	set_room_as_current_scene(room_chunk.GetNeighbour(dir).GetRoom(), OppositeDir(dir))
