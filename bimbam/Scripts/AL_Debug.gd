#
# Custom 3D debug drawing library
#

extends Control

class Line3D:
	var start_pos : Vector3
	var end_pos : Vector3
	var color : Color
	var width : float
	
	func _init (_start_pos:Vector3, _end_pos:Vector3, _color:Color=Color.red, _width:float=1):
		start_pos = _start_pos
		end_pos = _end_pos
		color = _color
		width = _width
		
	func GetStartPosition (): return start_pos
	func GetEndPosition   (): return end_pos
	func GetColor         (): return color
	func GetWidth         (): return width

class String3D:
	var pos : Vector3
	var size
	var text : String
	var modulate : Color

	func _init (_pos:Vector3, _text:String, _size=64, _modulate:Color=Color.red):
		pos = _pos
		text = _text
		size = _size
		modulate = _modulate
		
	func GetPosition (): return pos
	func GetSize     (): return size
	func GetText     (): return text
	func GetModulate (): return modulate

var to_draw = []

func start_update_loop ():
	while true:
		yield(get_tree(), "idle_frame")
		to_draw.clear()
	
func _ready ():
	start_update_loop()

func _process (_delta):
	update()

func _draw ():
	for obj in to_draw:
		if obj is Line3D:
			var screen_start_pos = get_viewport().get_camera().unproject_position(obj.GetStartPosition())
			var screen_end_pos = get_viewport().get_camera().unproject_position(obj.GetEndPosition())
			draw_line(screen_start_pos, screen_end_pos, obj.GetColor(), obj.GetWidth())
		elif obj is String3D:
			var screen_pos = get_viewport().get_camera().unproject_position(obj.GetPosition())
			var font = ALMain.GetDebugFont(obj.GetSize())
			var str_size = font.get_string_size(obj.GetText())
			draw_string(
				font,
				screen_pos + Vector2(-str_size.x, str_size.y) / 2.0,
				obj.GetText(), obj.GetModulate()
			)

#
#
# PUBLIC
#
#

func DrawLine3D (line : Line3D):
	to_draw.append(line)

func DrawString3D (string : String3D):
	to_draw.append(string)
