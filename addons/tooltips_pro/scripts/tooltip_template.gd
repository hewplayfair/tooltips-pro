class_name Tooltip
extends Control

@export var content_labels: Array[Label]
@export var lock_elements: Array[Control]
@export var timer_lock_progress_bar: TextureProgressBar
var trigger: TooltipTrigger

var state :=  TooltipEnums.TooltipState.INIT

func _init(trigger_p: TooltipTrigger = null) -> void:
	trigger = trigger_p
		
	for element in lock_elements:
		element.hide()
	
	if timer_lock_progress_bar:
		timer_lock_progress_bar.value = 0.0
		
	state =  TooltipEnums.TooltipState.READY


func init_lock_mode() -> void:
	var lock_mode = TooltipManager.singleton.tooltip_settings.lock_mode
	if trigger.tooltip_settings_override:
		lock_mode = trigger.tooltip_settings_override.lock_mode
	match lock_mode:
		TooltipEnums.TooltipLockMode.AUTO_LOCK:
			lock()
		TooltipEnums.TooltipLockMode.TIMER_LOCK:
			begin_lock_delay()


func toggle_lock() -> void:
	match state:
		TooltipEnums.TooltipState.READY:
			lock()
		TooltipEnums.TooltipState.LOCKED:
			unlock()


func begin_lock_delay() -> void:
	var lock_delay = TooltipManager.singleton.tooltip_settings.timer_lock_delay
	if trigger.tooltip_settings_override:
		lock_delay = trigger.tooltip_settings_override.timer_lock_delay
	
	var t = 0.0
	while t < lock_delay:
		t += get_process_delta_time()
		timer_lock_progress_bar.value = 1.0 - (lock_delay - t) / lock_delay
		await get_tree().process_frame
	
	lock()

func lock() -> void:
	for element in lock_elements:
		element.show()
		
	state =  TooltipEnums.TooltipState.LOCKED
	

func unlock() -> void:
	for element in lock_elements:
		element.hide()
		
	state =  TooltipEnums.TooltipState.READY


func set_pivot(_alignment: TooltipEnums.TooltipAlignment) -> void:
	match _alignment:
		TooltipEnums.TooltipAlignment.TOP_LEFT:
			self.pivot_offset = Vector2(self.size.x, self.size.y)
		TooltipEnums.TooltipAlignment.TOP_CENTER:
			self.pivot_offset = Vector2(self.size.x/2, self.size.y)
		TooltipEnums.TooltipAlignment.TOP_RIGHT:
			self.pivot_offset = Vector2(0.0, self.size.y)
		TooltipEnums.TooltipAlignment.MIDDLE_LEFT:
			self.pivot_offset = Vector2(self.size.x, self.size.y/2)
		TooltipEnums.TooltipAlignment.MIDDLE_CENTER:
			self.pivot_offset = Vector2(self.size.x/2, self.size.y/2)
		TooltipEnums.TooltipAlignment.MIDDLE_RIGHT:
			self.pivot_offset = Vector2(0.0, self.size.y/2)
		TooltipEnums.TooltipAlignment.BOTTOM_LEFT:
			self.pivot_offset = Vector2(self.size.x, 0.0)
		TooltipEnums.TooltipAlignment.BOTTOM_CENTER:
			self.pivot_offset = Vector2(self.size.x/2, 0.0)
		TooltipEnums.TooltipAlignment.BOTTOM_RIGHT:
			self.pivot_offset = Vector2(0.0, 0.0)
		_:
			self.pivot_offset = Vector2.ZERO


func _on_mouse_entered() -> void:
	print("_on_mouse_entered tooltip: ", self.name)
	print("tooltip state: ", TooltipEnums.TooltipState.keys()[state])
	if state == TooltipEnums.TooltipState.UNLOCKING:
		trigger.cancel_unlock_delay()


func _on_mouse_exited() -> void:
	print("_on_mouse_exited tooltip: ", self.name)
	print("tooltip state: ", TooltipEnums.TooltipState.keys()[state])
	if state == TooltipEnums.TooltipState.LOCKED:
		trigger.try_await_unlock_delay()
