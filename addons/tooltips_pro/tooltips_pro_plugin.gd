@tool
extends EditorPlugin

var editor_inspector_plugin
var element_scripts := [
	["TooltipTrigger", preload("res://addons/tooltips_pro/scripts/tooltip_trigger.gd"), null],
	["TooltipTemplate", preload("res://addons/tooltips_pro/scripts/tooltip_template.gd"), null],
	["TooltipManager", preload("res://addons/tooltips_pro/scripts/tooltip_manager.gd"), null],
]

func _enter_tree():
	editor_inspector_plugin = preload("res://addons/tooltips_pro/scripts/inspector_scripts/tooltip_inspector_plugin.gd").new()
	add_inspector_plugin(editor_inspector_plugin)
	
	var editor_base_node := get_editor_interface().get_base_control()
	for x in element_scripts:
		var x_icon = x[2]
		if x_icon == null:
			x_icon = x[1].get_instance_base_type()

		if x_icon is StringName || x_icon is String:
			x_icon = editor_base_node.get_theme_icon(x_icon, "EditorIcons")

		add_custom_type(x[0], x[1].get_instance_base_type(), x[1], x_icon)


func _exit_tree():
	remove_inspector_plugin(editor_inspector_plugin)
	
	for x in element_scripts:
		remove_custom_type(x[0])
