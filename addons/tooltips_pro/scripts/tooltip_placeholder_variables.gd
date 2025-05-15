extends Node

# The variables "num" and "time" are used in an example scene 
# string_placeholders_example_scene.tscn and included for reference. They can be 
# removed from this script when no longer needed.

# This variable doesn't need to update while the tooltip is open, so doesn't
# need to send an update signal.
var num: String

# We want this variable to update continuously on the tooltip, so it emits the
# update signal when set, with the variable name sent as a parameter.
var time: String:
	set(value):
		time = value
		get_tree().call_group("tooltips", "on_tooltip_variable_updated", "time")
