class_name Tooltip
extends Control

## The Labels that have their text set by the tooltip_strings on a Tooltip Trigger.
@export var content_labels: Array[Label]
## UI elements that will hide() when the tooltip is unlocked and show() when locked.
@export var lock_elements: Array[Control]
## The TextureProgressBar to be filled by a normalized time remaining of Timer Lock Delay.
@export var timer_lock_progress_bar: TextureProgressBar
var trigger: TooltipTrigger
var child_trigger_nodes: Array[Node]

var state: TooltipEnums.TooltipState

var stack_coroutine_manager = TooltipStackCoroutineManager.new()

func _init(trigger_p: TooltipTrigger = null) -> void:
	trigger = trigger_p
		
	for element in lock_elements:
		element.hide()
	
	if timer_lock_progress_bar:
		timer_lock_progress_bar.value = 0.0
		
	child_trigger_nodes = self.find_children("*", "TooltipTrigger", true, false)
		
	state =  TooltipEnums.TooltipState.READY


func init_lock_mode() -> void:
	var lock_mode = TooltipManager.singleton.tooltip_settings.lock_mode
	if trigger.tooltip_settings_override:
		lock_mode = trigger.tooltip_settings_override.lock_mode
	match lock_mode:
		TooltipEnums.TooltipLockMode.AUTO_LOCK:
			if trigger.can_lock:
				lock()
		TooltipEnums.TooltipLockMode.TIMER_LOCK:
			if trigger.can_lock:
				begin_lock_delay()


func toggle_lock() -> void:
	if trigger.can_lock:
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
	
	self.mouse_filter = Control.MOUSE_FILTER_STOP
	for trigger in child_trigger_nodes:
		trigger.mouse_filter = Control.MOUSE_FILTER_PASS
	
	state =  TooltipEnums.TooltipState.LOCKED
	

func unlock() -> void:
	for element in lock_elements:
		element.hide()
	
	self.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for trigger in child_trigger_nodes:
		trigger.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
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

func set_stack_position_modulate(index: int) -> void:
	if index == 0:
		self.modulate = Color.WHITE
	elif index >= TooltipManager.singleton.tooltip_settings.darken_step_count:
		self.modulate = TooltipManager.singleton.tooltip_settings.step_limit_color
	else:
		var color_value = 1.0 - (TooltipManager.singleton.tooltip_settings.darken_step_value * (index + 1))
		self.modulate = Color(color_value, color_value, color_value, 1.0)

func _on_mouse_entered() -> void:
	stack_coroutine_manager.free_coroutines()
	match state:
		TooltipEnums.TooltipState.LOCKED:
			TooltipManager.singleton.collapse_tooltip_stack(TooltipManager.singleton.mouse_tooltip_stack.find(self))
		TooltipEnums.TooltipState.UNLOCKING:
			trigger.cancel_unlock_delay()


func _on_mouse_exited() -> void:
	stack_coroutine_manager.force_close_stack_run(self)
