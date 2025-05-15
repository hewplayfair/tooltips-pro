extends Node

@export var spin_box: SpinBox
var last_time: String

func _ready() -> void:
	TooltipPlaceholderVariables.num = str(spin_box.value).pad_decimals(0)


func _process(delta: float) -> void:
	var current_time = Time.get_time_string_from_system()
	if current_time != last_time:
		last_time = current_time
		TooltipPlaceholderVariables.time = current_time


func _on_spin_box_value_changed(value: float) -> void:
	TooltipPlaceholderVariables.num = str(value).pad_decimals(0)
