extends CanvasLayer

const SCRIPT_SOURCE_START = """
extends Resource
func select (obj):
	ALDebugConsole.selected_obj = obj
func clear_history ():
	ALDebugConsole.clear_cmd_history = true
"""

onready var output = $Control/VBoxContainer/Output/RichTextLabel
onready var editor = $Control/VBoxContainer/Editor/HBoxContainer/TextEdit
onready var run_button = $Control/VBoxContainer/Editor/HBoxContainer/Run

onready var panel_btn_help      = $Control/VBoxContainer/Panels/HBoxContainer/Help
onready var panel_btn_history   = $Control/VBoxContainer/Panels/HBoxContainer/History
onready var panel_btn_object    = $Control/VBoxContainer/Panels/HBoxContainer/Object
onready var panel_btn_autopause = $Control/VBoxContainer/Panels/HBoxContainer/AutoPause
onready var panel_btn_autofocus = $Control/VBoxContainer/Panels/HBoxContainer/AutoFocus

var selected_obj = null
var cmd_history = []
var clear_cmd_history = false

func get_header (name):
	var lines = "=".repeat(20)
	var header = "[color=yellow]"
	header += lines
	header += " %s " % name
	header += lines
	header += "[/color]"
	header += '\n\n'
	return header

func is_method_public (method_name):
	return method_name[0] == method_name[0].capitalize()

func output_history ():
	output.bbcode_text += get_header("HISTORY")
	if cmd_history.empty():
		output.bbcode_text += "[color=red]Empty[/color]"
		output.bbcode_text += '\n'
		output.bbcode_text += '\n'
	else:
		for cmd in cmd_history:
			output.bbcode_text += "[color=yellow]* [/color][color=teal]" + cmd + "[/color]"
			output.bbcode_text += '\n'
			output.bbcode_text += '\n'

func output_selected_obj ():
	output.bbcode_text += get_header("OBJECT")
	if not is_instance_valid(selected_obj):
		selected_obj = null
	if selected_obj == null:
		output.bbcode_text += "[color=red]No object has been selected,"
		output.bbcode_text += '\n'
		output.bbcode_text += "the selected object is NULL,"
		output.bbcode_text += '\n'
		output.bbcode_text += "or the object has been freed[/color]"
		output.bbcode_text += '\n'
	else:
		var name = str(selected_obj)
		if selected_obj is Node:
			name = selected_obj.name
		output.bbcode_text += "[color=yellow]* Name: [/color][color=teal]" + name + "[/color]" + '\n'
		if selected_obj is Node:
			output.bbcode_text += "[color=yellow]* Path: [/color][color=teal]" + selected_obj.get_path() + "[/color]"
			output.bbcode_text += '\n'
		output.bbcode_text += "[color=yellow]* Methods: [/color]"
		output.bbcode_text += '\n'
		output_obj_methods(selected_obj, '\t')
	output.bbcode_text += '\n'

func output_obj_methods (obj, indent_str = ""):
	var longest_method_name = ""
	for method in obj.get_method_list():
		if is_method_public(method.name):
			if method.name.length() > longest_method_name.length():
				longest_method_name = method.name
	for method in obj.get_method_list():
		if is_method_public(method.name):
			output.bbcode_text += indent_str
			output.bbcode_text += '[color=teal]- ' + method.name + '[/color] '
			output.bbcode_text += " ".repeat(longest_method_name.length() - method.name.length())
			output.bbcode_text += '[color=fuchsia]([/color]'
			for idx in method.args.size():
				var arg = method.args[idx]
				output.bbcode_text += "[color=silver]" + arg.name + "[/color]"
				if idx + 1 < method.args.size():
					output.bbcode_text += "[color=yellow], [/color]"
			output.bbcode_text += '[color=fuchsia])[/color]\n'

func output_help ():
	output.bbcode_text += get_header("HELP")
	output.bbcode_text += \
"""[color=aqua]Functions[/color]

	[color=teal]- select[/color] [color=fuchsia]([color=silver]Object[/color])[/color] select object to display metadata of
	[color=teal]- clear_history[/color] [color=fuchsia]()[/color] clear script history
	
[color=aqua]AutoLoads[/color]

"""
	for autoload in get_tree().root.get_children():
		if autoload != get_tree().get_current_scene():
			output.bbcode_text += '\t[color=yellow]* ' + autoload.name + '[/color]\n'
			output_obj_methods(autoload, '\t\t')

func on_run_button_pressed ():
	var script = GDScript.new()
	var user_code = editor.text
	var res = Resource.new()
	
	script.source_code = SCRIPT_SOURCE_START + user_code
	script.reload()
	res.set_script(script)
	res.run()
	
	if clear_cmd_history:
		cmd_history.clear()
		clear_cmd_history = false
	else:
		cmd_history.append(user_code)
	update_output()

func update_output ():
	output.bbcode_text = ""
	if panel_btn_object.pressed:
		output_selected_obj()
	if panel_btn_history.pressed:
		output_history()
	if panel_btn_help.pressed:
		output_help()

func on_panel_btn_autopause_toggled (pressed):
	if pressed:
		ALMain.Pause()
	else:
		ALMain.Unpause()

func _ready ():
	$Control.visible = false
	pause_mode = Node.PAUSE_MODE_PROCESS
	run_button.connect("pressed", self, "on_run_button_pressed")
	panel_btn_help.connect("pressed", self, "update_output")
	panel_btn_history.connect("pressed", self, "update_output")
	panel_btn_object.connect("pressed", self, "update_output")
	panel_btn_autopause.connect("toggled", self, "on_panel_btn_autopause_toggled")
	update_output()
	
func _unhandled_key_input (event):
	if event.scancode == KEY_F1:
		if event.pressed:
			if $Control.visible:
				$Control.visible = false
				if panel_btn_autopause.pressed:
					ALMain.Unpause()
			else:
				$Control.visible = true
				if panel_btn_autopause.pressed:
					ALMain.Pause()
				if panel_btn_autofocus.pressed:
					editor.grab_focus()
