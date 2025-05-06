extends Node

@export var initial_focus_control: Control

@export var lock_mode_option_button: OptionButton
@export var open_delay_slider: Slider
@export var open_delay_value: Label
@export var timer_lock_delay_slider: Slider
@export var timer_lock_delay_value: Label
@export var unlock_delay_slider: Slider
@export var unlock_delay_value: Label

func _ready() -> void:
	initial_focus_control.grab_focus()
	
	lock_mode_option_button.select(TooltipManager.singleton.tooltip_settings.lock_mode)
	open_delay_slider.value = TooltipManager.singleton.tooltip_settings.open_delay
	timer_lock_delay_slider.value = TooltipManager.singleton.tooltip_settings.timer_lock_delay
	unlock_delay_slider.value = TooltipManager.singleton.tooltip_settings.unlock_delay


func _on_lock_mode_option_button_item_selected(index: int) -> void:
	TooltipManager.singleton.tooltip_settings.lock_mode = index


func _on_open_delay_slider_value_changed(value: float) -> void:
	TooltipManager.singleton.tooltip_settings.open_delay = value
	open_delay_value.text = str(value, "s")


func _on_timer_lock_delay_slider_value_changed(value: float) -> void:
	TooltipManager.singleton.tooltip_settings.timer_lock_delay = value
	timer_lock_delay_value.text = str(value, "s")


func _on_unlock_delay_slider_value_changed(value: float) -> void:
	TooltipManager.singleton.tooltip_settings.unlock_delay = value
	unlock_delay_value.text = str(value, "s")


func _on_reset_to_default_button_pressed() -> void:
	lock_mode_option_button.select(TooltipManager.singleton.default_tooltip_settings.lock_mode)
	open_delay_slider.value = TooltipManager.singleton.default_tooltip_settings.open_delay
	timer_lock_delay_slider.value = TooltipManager.singleton.default_tooltip_settings.timer_lock_delay
	unlock_delay_slider.value = TooltipManager.singleton.default_tooltip_settings.unlock_delay
