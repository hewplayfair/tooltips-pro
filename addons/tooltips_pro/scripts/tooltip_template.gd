class_name Tooltip
extends Control

## The TooltipTemplate defines the layout and appearance of tooltips.
##
## [b]TooltipTemplates[/b] must be located in the directory path assigned to [b]Tooltip
## Template Dir Path[/b] on the [b]Tooltip Settings[/b] resource. There should not be any
## Objects or Resources in the directory other than [b]TooltipTemplates[/b].
##[br][br]
## The first [code].tscn[/code] in the directory will be used as the default template, used 
## when [b]Tooltip Template Path[/b] on a [TooltipTrigger] is empty.

@export var can_lock: bool = true

## The [RichTextLabel]s have their text set by the [code]tooltip_strings[/code] 
## on a [TooltipTrigger].
@export var content_labels: Array[RichTextLabel]
## UI elements that will [code]hide()[/code] when the tooltip is locking or unlocked and 
## [code]show()[/code] when locked.
@export var locked_elements: Array[Control]
## UI elements that will [code]hide()[/code] when the tooltip is locked or unlocked and 
## [code]show()[/code] when locking.
@export var locking_elements: Array[Control]
## UI elements that will [code]hide()[/code] when the tooltip is locked or locking and 
## [code]show()[/code] when unlocked.
@export var unlocked_elements: Array[Control]

## UI elements that will [code]hide()[/code] when the tooltip is pinned in place and 
## [code]show()[/code] when not pinned.
@export var unpinned_elements: Array[Control]
## UI elements that will [code]hide()[/code] when the tooltip is not pinned in place and 
## [code]show()[/code] when pinned.
@export var pinned_elements: Array[Control]

## The [TextureProgressBar] to be filled by a normalized time remaining of 
## [code]timer_lock_delay[/code].
@export var timer_lock_progress_bar: TextureProgressBar

var trigger: TooltipTrigger
var child_trigger_nodes: Array[Node]

var tween: Tween
@export_group("Tweening")
## Use a tween scale animation from [code]Vector2.ZERO[/code] to [code]Vector2.ONE[/code] 
## when the tooltip is created.
@export var use_tween_in: bool
## Tween's duration in seconds.
@export var tween_in_duration: float = 0.1
## Tween's EaseType.
@export var tween_in_ease_type: Tween.EaseType = Tween.EaseType.EASE_IN_OUT
## Create a "pop" effect by briefly increasing the scale past Vector2.ONE
@export var pop_scale: Vector2 = Vector2.ONE
## Use a tween scale animation from [code]Vector2.ONE[/code] to [code]Vector2.ZERO[/code] 
## when the tooltip is removed. 
@export var use_tween_out: bool
## Tween's duration in seconds.
@export var tween_out_duration: float = 0.1
## Tween's EaseType.
@export var tween_out_ease_type: Tween.EaseType = Tween.EaseType.EASE_IN_OUT

var state: TooltipEnums.TooltipState

var stack_coroutine_manager = TooltipStackCoroutineManager.new()

var placeholder_dictionaries: Array[Dictionary]

func _init(trigger_p: TooltipTrigger = null) -> void:
	trigger = trigger_p
			
	for element in locked_elements:
		element.hide()
	for element in locking_elements:
		element.hide()
	for element in unlocked_elements:
		element.show()
		
	for element in pinned_elements:
		element.hide()
	for element in unpinned_elements:
		element.hide()
	
	if timer_lock_progress_bar:
		timer_lock_progress_bar.value = 0.0
		
	child_trigger_nodes = self.find_children("*", "TooltipTrigger", true, false)
		
	state =  TooltipEnums.TooltipState.READY


func init_lock_mode() -> void:
	var lock_mode = TooltipManager.tooltip_settings.lock_mode
	match lock_mode:
		TooltipEnums.TooltipLockMode.AUTO_LOCK:
			lock()
		TooltipEnums.TooltipLockMode.TIMER_LOCK:
			begin_lock_delay()
		TooltipEnums.TooltipLockMode.TIMER_AND_ACTION_LOCK:
			begin_lock_delay()


func toggle_lock() -> void:
	match state:
		TooltipEnums.TooltipState.READY:
			lock()
		TooltipEnums.TooltipState.LOCKED:
			unlock()


func begin_lock_delay() -> void:
	if not can_lock:
		return
	
	var lock_delay = TooltipManager.tooltip_settings.timer_lock_delay
		
	for element in locked_elements:
		element.hide()
	for element in locking_elements:
		element.show()
	for element in unlocked_elements:
		element.hide()
	
	var t = 0.0
	while t < lock_delay:
		t += get_process_delta_time()
		if timer_lock_progress_bar:
			timer_lock_progress_bar.value = 1.0 - (lock_delay - t) / lock_delay
		await get_tree().process_frame
	
	lock()

func lock() -> void:
	if not can_lock:
		return
		
	for element in locked_elements:
		element.show()
	for element in locking_elements:
		element.hide()
	for element in unlocked_elements:
		element.hide()
	
	self.mouse_filter = Control.MOUSE_FILTER_STOP
	for trigger in child_trigger_nodes:
		trigger.mouse_filter = Control.MOUSE_FILTER_PASS
	
	state =  TooltipEnums.TooltipState.LOCKED
	

func unlock() -> void:
	for element in locked_elements:
		element.hide()
	for element in locking_elements:
		element.hide()
	for element in unlocked_elements:
		element.show()
	
	self.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for trigger in child_trigger_nodes:
		trigger.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	state =  TooltipEnums.TooltipState.READY


func pin() -> void:
	for element in pinned_elements:
		element.show()
	for element in unpinned_elements:
		element.hide()
		
	lock()


func unpin() -> void:
	for element in pinned_elements:
		element.hide()
	for element in unpinned_elements:
		element.show()
	

func set_content(tooltip_strings: Array[String]):
	placeholder_dictionaries.clear()
	
	for i in tooltip_strings.size():
		if content_labels.size() > i:
			var placeholder_dict: Dictionary[String, String]
			placeholder_dictionaries.append(placeholder_dict)
			var translated_string = tr(tooltip_strings[i])
			
			var regex = RegEx.new()
			regex.compile("(?<={).+?(?=})")
			var results = regex.search_all(translated_string)
			if results:
				for result in results:
					for string in result.strings:
						placeholder_dictionaries[i].set(string, tr(TooltipPlaceholderVariables.get(string)))
						pass
			
			content_labels[i].text = tr(tooltip_strings[i]).format(placeholder_dictionaries[i])
		else:
			printerr(name, " has fewer RichTextLabels than there are content strings on trigger ", trigger.name)


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
	elif index >= TooltipManager.tooltip_settings.darken_step_count:
		self.modulate = TooltipManager.tooltip_settings.step_limit_color
	else:
		var color_value = 1.0 - (TooltipManager.tooltip_settings.darken_step_value * (index + 1))
		self.modulate = Color(color_value, color_value, color_value, 1.0)


func tween_in():
	if not use_tween_in:
		return
		
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0)
	tween.set_ease(tween_in_ease_type)
	tween.tween_property(self, "scale", pop_scale, tween_in_duration)
	if pop_scale != Vector2.ONE:
		tween.set_ease(Tween.EaseType.EASE_IN)
		tween.tween_property(self, "scale", Vector2.ONE, tween_in_duration)


func tween_out():
	if not use_tween_out:
		return
	
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_ease(tween_out_ease_type)
	tween.tween_property(self, "scale", Vector2.ZERO, tween_out_duration)
	await get_tree().create_timer(tween_out_duration).timeout


func _on_mouse_entered() -> void:
	TooltipManager.last_mouse_entered_tooltip = self
	
	if TooltipManager.has_pinned_tooltip:
		return
		
	if state == TooltipEnums.TooltipState.REMOVE:
		return
	
	stack_coroutine_manager.free_coroutines()
	match state:
		TooltipEnums.TooltipState.LOCKED:
			TooltipManager.collapse_tooltip_stack(TooltipManager.mouse_tooltip_stack.find(self), false, 0.0)
		TooltipEnums.TooltipState.UNLOCKING:
			if trigger:
				trigger.cancel_unlock_delay()


func _on_mouse_exited() -> void:
	if state == TooltipEnums.TooltipState.REMOVE:
		return
	
	TooltipManager.last_mouse_entered_tooltip = null
	
	if TooltipManager.has_pinned_tooltip:
		return
	
	stack_coroutine_manager.force_close_stack_run(self)
	
	
func on_tooltip_variable_updated(property_name: String):
	for i in content_labels.size():
		if placeholder_dictionaries[i].has(property_name):
			set_content(trigger.tooltip_strings)
