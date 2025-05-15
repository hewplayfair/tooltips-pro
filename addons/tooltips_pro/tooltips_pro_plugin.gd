@tool
extends EditorPlugin

const MANAGER = "TooltipManager"
const PLACEHOLDER_VARIABLES = "TooltipPlaceholderVariables"


func _enable_plugin() -> void:
	add_autoload_singleton(MANAGER, "res://addons/tooltips_pro/scripts/tooltip_manager.gd")
	add_autoload_singleton(PLACEHOLDER_VARIABLES, "res://addons/tooltips_pro/scripts/tooltip_placeholder_variables.gd")
	
	var primary_key = InputEventKey.new()
	primary_key.physical_keycode = KEY_T
	var secondary_key = InputEventMouseButton.new()
	secondary_key.device = -1
	secondary_key.button_index = MOUSE_BUTTON_MIDDLE

	var input = {
		"deadzone": 0.2,
		"events": [
			primary_key,
			secondary_key
		]
	}
	ProjectSettings.set_setting("input/lock_tooltip", input)
	ProjectSettings.save()


func _disable_plugin() -> void:
	remove_autoload_singleton(MANAGER)
	remove_autoload_singleton(PLACEHOLDER_VARIABLES)
	
	ProjectSettings.set_setting("input/lock_tooltip", null)
	ProjectSettings.save()
