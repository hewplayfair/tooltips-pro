extends Node

@export var lock_mode_option_button: OptionButton
@export var open_delay_slider: Slider
@export var open_delay_value: Label
@export var timer_lock_delay_slider: Slider
@export var timer_lock_delay_value: Label
@export var unlock_delay_slider: Slider
@export var unlock_delay_value: Label

@onready var default_lock_mode = TooltipManager.tooltip_settings.lock_mode
@onready var default_open_delay = TooltipManager.tooltip_settings.open_delay
@onready var default_lock_delay = TooltipManager.tooltip_settings.timer_lock_delay
@onready var default_unlock_delay = TooltipManager.tooltip_settings.unlock_delay

func _ready() -> void:
	lock_mode_option_button.select(TooltipManager.tooltip_settings.lock_mode)
	open_delay_slider.value = TooltipManager.tooltip_settings.open_delay
	timer_lock_delay_slider.value = TooltipManager.tooltip_settings.timer_lock_delay
	unlock_delay_slider.value = TooltipManager.tooltip_settings.unlock_delay
	
	# Be sure to only grab focus on a control with a tooltip after the tooltips 
	# have initialized
	lock_mode_option_button.call_deferred("grab_focus")


func _on_lock_mode_option_button_item_selected(index: int) -> void:
	TooltipManager.tooltip_settings.lock_mode = index


func _on_open_delay_slider_value_changed(value: float) -> void:
	TooltipManager.tooltip_settings.open_delay = value
	open_delay_value.text = str(value, "s")


func _on_timer_lock_delay_slider_value_changed(value: float) -> void:
	TooltipManager.tooltip_settings.timer_lock_delay = value
	timer_lock_delay_value.text = str(value, "s")


func _on_unlock_delay_slider_value_changed(value: float) -> void:
	TooltipManager.tooltip_settings.unlock_delay = value
	unlock_delay_value.text = str(value, "s")


func _on_reset_to_default_button_pressed() -> void:
	lock_mode_option_button.select(default_lock_mode)
	open_delay_slider.value = default_open_delay
	timer_lock_delay_slider.value = default_lock_delay
	unlock_delay_slider.value = default_unlock_delay
