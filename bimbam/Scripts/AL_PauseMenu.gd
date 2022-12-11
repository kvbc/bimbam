#
# TODO: Make setting arrows interact with the mouse
#

extends CanvasLayer

var focused_node = null
var setting_row_types = {} # setting row node -> ALMain.SettingType
var setting_row_nodes = {} # ALMain.SettingType -> setting row node
var node_neighbour_right = {}
var node_neighbour_left = {}
var node_neighbour_top = {}
var node_neighbour_bottom = {}

func pause ():
	ALMain.Pause()
	$Control.visible = true
	$Control/Labels/Resume.grab_focus()

func focus (node):
	if focused_node != null:
		focused_node.modulate = Color.white
	focused_node = node
	node.modulate = Color.yellow

func is_node_setting_row (node):
	return node.get_parent() == $Control/Settings/rows

func get_next_setting_value (setting_type):
	var setting_value = ALMain.GetSetting(setting_type)
	var setting_values = ALMain.GetSettingValues(setting_type)
	var idx = setting_values.find(setting_value)
	return setting_values[(idx + 1) % setting_values.size()]

func get_prev_setting_value (setting_type):
	var setting_value = ALMain.GetSetting(setting_type)
	var setting_values = ALMain.GetSettingValues(setting_type)
	var idx = setting_values.find(setting_value)
	idx -= 1
	if idx < 0:
		idx = setting_values.size() - 1
	return setting_values[idx]

func _unhandled_key_input (event):
	if not event.pressed:
		return
	if not ALMain.IsPaused():
		if event.scancode == KEY_ENTER:
			pause()
			focus($Control/Labels/Resume)
	else:
		if event.scancode == KEY_ENTER:
			if focused_node == $Control/Labels/Settings:
				if $Control/Settings.visible:
					$Control/Settings.visible = false
				else:
					$Control/Settings.visible = true
					focus($Control/Settings/rows.get_child(0))
			elif focused_node == $Control/Labels/Resume:
				ALMain.Unpause()
			elif focused_node == $Control/Labels/Exit:
				get_tree().quit()
			elif is_node_setting_row(focused_node):
				var setting_type = setting_row_types[focused_node]
				var setting_values = ALMain.GetSettingValues(setting_type)
				if setting_values.size() == 2:
					ALMain.SetSetting(setting_type, get_next_setting_value(setting_type))
		elif event.scancode in [KEY_ESCAPE, KEY_BACKSPACE]:
			if $Control/Settings.visible:
				focus($Control/Labels/Settings)
				$Control/Settings.visible = false
			else:
				ALMain.Unpause()
		elif event.scancode in [KEY_A, KEY_LEFT]:
			if is_node_setting_row(focused_node):
				var setting_type = setting_row_types[focused_node]
				ALMain.SetSetting(setting_type, get_prev_setting_value(setting_type))
			elif focused_node in node_neighbour_left:
				focus(node_neighbour_left[focused_node])
		elif event.scancode in [KEY_D, KEY_RIGHT]:
			if is_node_setting_row(focused_node):
				var setting_type = setting_row_types[focused_node]
				ALMain.SetSetting(setting_type, get_next_setting_value(setting_type))
			elif focused_node in node_neighbour_right:
				focus(node_neighbour_right[focused_node])
		elif event.scancode in [KEY_W, KEY_UP]:
			if focused_node in node_neighbour_top:
				focus(node_neighbour_top[focused_node])
		elif event.scancode in [KEY_S, KEY_DOWN]:
			if focused_node in node_neighbour_bottom:
				focus(node_neighbour_bottom[focused_node])

func on_setting_changed (setting_type, new_value):
	var setting_row = setting_row_nodes[setting_type]
	setting_row.get_node("value/label").text = new_value

func _ready ():
	pause_mode = Node.PAUSE_MODE_PROCESS
	$Control.visible = false
	$Control/Settings.visible = false
	
	node_neighbour_bottom[$Control/Labels/Settings] = $Control/Labels/Resume
	node_neighbour_bottom[$Control/Labels/Resume] = $Control/Labels/Exit
	node_neighbour_top[$Control/Labels/Resume] = $Control/Labels/Settings
	node_neighbour_top[$Control/Labels/Exit] = $Control/Labels/Resume
	
	ALMain.connect("setting_changed", self, "on_setting_changed")
	
	var prev_setting_row = null
	var setting_row_copy = $Control/Settings/rows/copy
	for setting_type in ALMain.GetSettingTypes():
		var setting_row = setting_row_copy.duplicate()
		setting_row.visible = true
		setting_row.get_node("setting").text = ALMain.GetSettingName(setting_type)
		setting_row_types[setting_row] = setting_type
		setting_row_nodes[setting_type] = setting_row
		$Control/Settings/rows.add_child(setting_row)
		if prev_setting_row != null:
			node_neighbour_top[setting_row] = prev_setting_row
			node_neighbour_bottom[prev_setting_row] = setting_row
		prev_setting_row = setting_row
	$Control/Settings/rows.remove_child(setting_row_copy)

#
#
# Public
#
#

func Unpause ():
	$Control.visible = false
