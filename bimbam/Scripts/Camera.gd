extends Camera

func _ready ():
	fov = 90

func _process (delta):
	var plr_pos = ALMain.GetPlayer().Get3DPosition()
	global_transform.origin = plr_pos + Vector3(0, 10, 5)
	look_at(plr_pos, Vector3.UP)
