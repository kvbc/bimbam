extends HBoxContainer

func Init (max_health):
	for i in ceil(max_health):
		var txt = TextureRect.new()
		txt.expand = true
		txt.texture = preload("res://Assets/Images/heart_full.png")
		txt.rect_min_size = Vector2(64, 64)
		add_child(txt)

func Update (health):
	if health < 0:
		return
	for i in floor(health):
		get_child(i).texture = preload("res://Assets/Images/heart_full.png")
	if health - floor(health) > 0:
		get_child(floor(health)).texture = preload("res://Assets/Images/heart_half.png")
	for i in range(ceil(health), get_child_count()):
		get_child(i).texture = preload("res://Assets/Images/heart_empty.png")
