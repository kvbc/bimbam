extends HBoxContainer

func Update (hearts):
	for c in get_children():
		c.queue_free()
	for i in hearts:
		var txt = TextureRect.new()
		txt.expand = true
		txt.texture = preload("res://serce.png")
		txt.rect_min_size = Vector2(64, 64)
		add_child(txt)
