extends Node


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("lock_tooltip"):
		TooltipManager.action_lock_input.emit()
		
	if Input.is_action_just_pressed("pin_tooltip"):
		TooltipManager.pin_tooltip_input.emit(true)
		
	if Input.is_action_just_released("pin_tooltip"):
		TooltipManager.pin_tooltip_input.emit(false)
