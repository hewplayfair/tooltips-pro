extends EditorInspectorPlugin

var TooltipTemplateEditor = preload("res://addons/tooltips_pro/scripts/inspector_scripts/tooltip_template_editor.gd")


func _can_handle(object):
	return true


func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
	if name == "tooltip_template":
		add_property_editor(name, TooltipTemplateEditor.new())
		return true
	else:
		return false
