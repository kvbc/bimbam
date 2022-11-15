extends CanvasLayer

func update_rooms (focus_room):
	for room in ALMain.idx_map:
		var txt = $ColorRect.get_child(room.idx)
		txt.rect_position = $ColorRect.rect_size / 2 + Vector2(room.pos.x - focus_room.pos.x, room.pos.y - focus_room.pos.y) * txt.rect_size - txt.rect_size / 2

func _ready ():
	for room in ALMain.idx_map:
		var txt = TextureRect.new()
		txt.expand = true
		txt.texture = preload("res://icon.png")
		txt.rect_size = Vector2(64, 64)
		$ColorRect.add_child(txt)
	update_rooms(ALMain.map)
		
func MarkRoomInactive (room):
	$ColorRect.get_child(room.idx).self_modulate = Color.white
		
func MarkRoomActive (room):
	$ColorRect.get_child(room.idx).self_modulate = Color.red
	update_rooms(room)
