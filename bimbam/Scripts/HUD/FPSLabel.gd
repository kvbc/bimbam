extends Label

func _ready ():
	Hide()

#
#
# PUBLIC
#
#

func Update (fps:int):
	text = str("FPS ", fps)

func Show ():
	visible = true
	
func Hide ():
	visible = false
