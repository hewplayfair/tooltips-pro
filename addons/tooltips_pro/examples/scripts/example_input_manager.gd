extends Node


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("lock_tooltip"):
		TooltipManager.action_lock_input.emit()
