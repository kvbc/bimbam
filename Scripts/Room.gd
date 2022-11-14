extends Node2D
signal player_entered

var is_exit_open = {}

func is_body_player (body):
	return body is preload("res://Scripts/Player.gd")
	
func on_exit_entered (body, area, method):
	if is_exit_open.get(area, true):
		if is_body_player(body):
			ALMain.call(method)

func get_exit_area (dir):
	return {
		ALMain.Dir.LEFT  : $Left,
		ALMain.Dir.RIGHT : $Right,
		ALMain.Dir.UP    : $Top,
		ALMain.Dir.DOWN  : $Bottom,
	}[dir]

func on_player_entered_on_area_exited (body, area):
	if is_body_player(body):
		is_exit_open[area] = true
		area.disconnect("body_exited", self, "on_player_entered_on_area_exited")
func on_player_entered (from_dir):
	var area = get_exit_area(from_dir)
	is_exit_open[area] = false
	area.connect("body_exited", self, "on_player_entered_on_area_exited", [area])

func _ready ():
	connect("player_entered", self, "on_player_entered")
	if (has_node("Left"  )): $Left  .connect("body_entered", self, "on_exit_entered", [$Left,   "MoveLeft"])
	if (has_node("Right" )): $Right .connect("body_entered", self, "on_exit_entered", [$Right,  "MoveRight"])
	if (has_node("Top"   )): $Top   .connect("body_entered", self, "on_exit_entered", [$Top,    "MoveTop"])
	if (has_node("Bottom")): $Bottom.connect("body_entered", self, "on_exit_entered", [$Bottom, "MoveBottom"])

func GetExitPosition (dir):
	return get_exit_area(dir).global_position
