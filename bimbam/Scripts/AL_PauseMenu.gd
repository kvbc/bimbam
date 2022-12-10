#
# TODO: Make setting arrows interact with the mouse
#

extends CanvasLayer

var focused_node = null
var in_settings = false
var setting_row_types = {} # setting row node -> ALMain.SettingType
var setting_row_nodes = {} # ALMain.SettingType -> setting row node

func on_focus_entered (node):
	focused_node = node
	node.modulate = Color.yellow
		
func on_focus_exited (node):
	focused_node = null
	node.modulate = Color.white

func unpause ():
	ALMain.Unpause()
	$Control.visible = false

func pause ():
	ALMain.Pause()
	$Control.visible = true
	$Control/Labels/Resume.grab_focus()

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

func _process (_delta):
	var pause_pressed = Input.is_action_just_pressed("PAUSE")
	if ALMain.IsPaused():
		if Input.is_action_just_pressed("ui_accept"):
			if focused_node == $Control/Labels/Settings:
				if in_settings:
					$Control/Settings.visible = false
				else:
					in_settings = true
					$Control/Settings.visible = true
					$Control/Settings/rows.get_child(0).grab_focus()
			elif focused_node == $Control/Labels/Resume:
				unpause()
			elif focused_node == $Control/Labels/Exit:
				get_tree().quit()
			elif is_node_setting_row(focused_node):
				var setting_type = setting_row_types[focused_node]
				var setting_values = ALMain.GetSettingValues(setting_type)
				if setting_values.size() == 2:
					ALMain.SetSetting(setting_type, get_next_setting_value(setting_type))
		if Input.is_action_just_pressed("ui_cancel"):
			if in_settings:
				$Control/Labels/Settings.grab_focus()
				$Control/Settings.visible = false
			else:
				unpause()
		if Input.is_action_just_pressed("ui_left"):
			if is_node_setting_row(focused_node):
				var setting_type = setting_row_types[focused_node]
				ALMain.SetSetting(setting_type, get_prev_setting_value(setting_type))
		if Input.is_action_just_pressed("ui_right"):
			if is_node_setting_row(focused_node):
				var setting_type = setting_row_types[focused_node]
				ALMain.SetSetting(setting_type, get_next_setting_value(setting_type))
		if pause_pressed:
			if not in_settings:
				unpause()
		in_settings = $Control/Settings.visible
	elif pause_pressed:
		pause()

func on_setting_changed (setting_type, new_value):
	var setting_row = setting_row_nodes[setting_type]
	setting_row.get_node("value/label").text = new_value

func _ready ():
	pause_mode = Node.PAUSE_MODE_PROCESS
	$Control.visible = false
	$Control/Settings.visible = false
	
	ALMain.connect("setting_changed", self, "on_setting_changed")
	
	var prev_setting_row = null
	var setting_row_copy = $Control/Settings/rows/copy
	for setting_type in ALMain.GetSettingTypes():
		var setting_row = setting_row_copy.duplicate()
		setting_row.visible = true
		setting_row.focus_mode = Control.FOCUS_ALL
		setting_row.get_node("setting").text = ALMain.GetSettingName(setting_type)
		setting_row_types[setting_row] = setting_type
		setting_row_nodes[setting_type] = setting_row
		$Control/Settings/rows.add_child(setting_row)
		setting_row.focus_neighbour_left = setting_row.get_path() # itself
		if prev_setting_row != null:
			setting_row.focus_previous = prev_setting_row.get_path()
			setting_row.focus_neighbour_top = prev_setting_row.get_path()
			prev_setting_row.focus_next = setting_row.get_path()
			prev_setting_row.focus_neighbour_bottom = setting_row.get_path()
		prev_setting_row = setting_row
	$Control/Settings/rows.remove_child(setting_row_copy)
	
	var focusable_nodes = $Control/Labels.get_children()
	focusable_nodes.append_array($Control/Settings/rows.get_children())
	for node in focusable_nodes:
		node.connect("focus_entered", self, "on_focus_entered", [node])
		node.connect("focus_exited", self, "on_focus_exited", [node])
		
