extends CanvasLayer

func _ready ():
	for room in ALMain.idx_map:
		var txt = TextureRect.new()
		txt.expand = true
		txt.texture = preload("res://icon.png")
		txt.rect_size = Vector2(32, 32)
		txt.rect_position = $ColorRect.rect_size / 2 + Vector2(room.pos.x, room.pos.y) * txt.rect_size
		$ColorRect.add_child(txt)
		
func MarkRoomInactive (room):
	$ColorRect.get_child(room.idx).self_modulate = Color.white
		
func MarkRoomActive (room):
	$ColorRect.get_child(room.idx).self_modulate = Color.red
