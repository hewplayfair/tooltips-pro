extends EditorProperty


# The main control for editing the property.
var property_control = OptionButton.new()
# An internal value of the property.
var current_value = 0
# A guard against internal changes when the property is updated.
var updating = false


func _init():
	# Add the control as a direct child of EditorProperty node.
	add_child(property_control)
	# Make sure the control is able to retain the focus.
	add_focusable(property_control)
	init_options_array()
	# Connect to the signal to track changes.
	property_control.item_selected.connect(_on_item_selected)


func _on_item_selected(index: int):
	# Ignore the signal if the property is currently being updated.
	if (updating):
		return

	current_value = index
	emit_changed(get_edited_property(), current_value)


func _update_property():
	# Read the current value from the property.
	var new_value = get_edited_object()[get_edited_property()]
	if (new_value == current_value):
		return

	# Update the control with the new value.
	updating = true
	current_value = new_value
	updating = false
	property_control.select(new_value)


func init_options_array():
	var resources = ResourceLoader.list_directory(TooltipManager.singleton.tooltip_template_dir_path)
	for resource in resources:
		property_control.add_item(resource as String)
