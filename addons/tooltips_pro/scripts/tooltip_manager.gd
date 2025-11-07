extends Node

## The TooltipManager controls the instantiation and positioning of tooltips.
##
## The [Tooltip] stack is managed by this autoloaded singleton. It also listens 
## for the [code]action_lock_input[/code] signal which toggles locking a tooltip.
## (See [code]/examples/scripts/example_input_manager.gd[/code])
## [br][br]
## Tooltips with an [b]Origin[/b] set to the mouse will be instantiated as 
## children of the [TooltipManager]. The necessary [CanvasLayer] and [Control] 
## parents are created automatically.

var tooltip_settings = preload("res://addons/tooltips_pro/resources/tooltip_settings.tres")

var tooltip_templates: Dictionary[String, PackedScene]

var mouse_tooltip_stack: Array[Tooltip]
var focus_tooltip_stack: Array[Tooltip]

var has_pinned_tooltip: bool
var last_mouse_entered_tooltip: Tooltip
var last_mouse_entered_trigger: TooltipTrigger

var size_to_stop: int

var follow_mouse: bool
var is_collapsing_stack: bool

var mouse_tooltips_parent: Node

signal action_lock_input
signal pin_tooltip_input
signal dismiss_tooltip_input

var stack_coroutine_manager = TooltipStackCoroutineManager.new()

func _ready() -> void:
	action_lock_input.connect(on_action_lock_input)
	pin_tooltip_input.connect(on_pin_tooltip_input)
	dismiss_tooltip_input.connect(on_dismiss_tooltip_input)
	load_tooltip_templates()
	
	var canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)
	canvas_layer.layer = 128
	mouse_tooltips_parent = Control.new()
	canvas_layer.add_child(mouse_tooltips_parent)


func load_tooltip_templates() -> void:
	var resources := ResourceLoader.list_directory(tooltip_settings.tooltip_template_dir_path)
	for resource in resources:
		tooltip_templates.set(tooltip_settings.tooltip_template_dir_path + resource, load(tooltip_settings.tooltip_template_dir_path + resource))


func _input(event):
	if not mouse_tooltip_stack:
		return
	if (
		mouse_tooltip_stack[0].state == TooltipEnums.TooltipState.LOCKED
		or mouse_tooltip_stack[0].state == TooltipEnums.TooltipState.UNLOCKING
	):
		return
		
	# Mouse in viewport coordinates.
	if follow_mouse and event is InputEventMouseMotion:
		position_tooltip(mouse_tooltip_stack[0])


func on_action_lock_input() -> void:
	if (
		tooltip_settings.lock_mode == TooltipEnums.TooltipLockMode.ACTION_LOCK 
		and mouse_tooltip_stack.size() > 0
	):
		mouse_tooltip_stack[0].toggle_lock()
		
	if (
		tooltip_settings.lock_mode == TooltipEnums.TooltipLockMode.TIMER_AND_ACTION_LOCK 
		and mouse_tooltip_stack.size() > 0
	):
		mouse_tooltip_stack[0].lock()


func on_pin_tooltip_input(toggle: bool) -> void:
	has_pinned_tooltip = false
	if mouse_tooltip_stack.size() > 0:
		if toggle and mouse_tooltip_stack[0].can_lock:
			has_pinned_tooltip = true
			mouse_tooltip_stack[0].pin()
		else:
			mouse_tooltip_stack[0].unpin()
			if not last_mouse_entered_tooltip:
				if not last_mouse_entered_trigger:
					collapse_tooltip_stack()
			else:
				if last_mouse_entered_trigger and last_mouse_entered_trigger.active_tooltip:
					return
				collapse_tooltip_stack(TooltipManager.mouse_tooltip_stack.find(last_mouse_entered_tooltip))


func on_dismiss_tooltip_input() -> void:
	if mouse_tooltip_stack.size() > 0:
		remove_tooltip(mouse_tooltip_stack[0])
		has_pinned_tooltip = false


func init_tooltip(tooltip_trigger: TooltipTrigger, screen_pos: Vector2) -> Tooltip:
	# If the tooltip stack is in process of collapsing with a delay it can cause
	# this new tooltip to also be removed, so first force close all the tooltips.
	if is_collapsing_stack:
		is_collapsing_stack = false
		force_close_stack()
	
	# If there's a pinned tooltip when opening a new one, unpin it so that
	# there's never more than one potentially pinned tooltip
	if has_pinned_tooltip and mouse_tooltip_stack.size() > 0:
		has_pinned_tooltip = false
		mouse_tooltip_stack[0].unpin()
	
	# Instantiate tooltip and add to Tooltip Stack
	var template := tooltip_templates.values()[0] as PackedScene
	if tooltip_trigger.tooltip_template_path:
		if tooltip_templates.has(tooltip_trigger.tooltip_template_path):
			template = tooltip_templates[tooltip_trigger.tooltip_template_path]
		else:
			printerr("No Tooltip Template at path \"", tooltip_trigger.tooltip_template_path, 
			"\" found. Using default template for Trigger ", tooltip_trigger.name, ".")
	var new_tooltip := template.instantiate() as Tooltip
	
	new_tooltip._init(tooltip_trigger)
	if tooltip_trigger.trigger_mode == TooltipEnums.TriggerMode.FOCUS_ONLY:
		focus_tooltip_stack.push_front(new_tooltip)
	else:
		mouse_tooltip_stack.push_front(new_tooltip)
	
	var parent: Node = mouse_tooltips_parent
	if tooltip_trigger.origin == TooltipEnums.TooltipOrigin.TRIGGER_ELEMENT:
		if screen_pos == Vector2.ZERO:
			parent = tooltip_trigger
	elif tooltip_trigger.origin == TooltipEnums.TooltipOrigin.REMOTE_ELEMENT:
		if tooltip_trigger.remote_element_node:
			parent = tooltip_trigger.remote_element_node
	elif (
			tooltip_trigger.origin == TooltipEnums.TooltipOrigin.MOUSE_POSITION_START 
			or tooltip_trigger.origin == TooltipEnums.TooltipOrigin.MOUSE_POSITION_FOLLOW
	):
		if tooltip_trigger.state == TooltipEnums.TriggerState.INIT_FOCUS_ENTERED:
			parent = tooltip_trigger
			
	parent.add_child(new_tooltip)
	# Positioning needs to be deferred due to tooltip sizing and positioning 
	# order of operations that I don't understand. Without it, tooltip Controls 
	# may be sized incorrectly, with, for example, a greater height than the 
	# minimum expected.
	call_deferred("position_tooltip", new_tooltip, screen_pos)
	
	new_tooltip.tween_in()
	
	new_tooltip.init_lock_mode()
	var stack: Array[Tooltip]
	stack.assign(mouse_tooltip_stack)
	for i in stack.size():
		stack[i].set_stack_position_modulate(i)
		
	return new_tooltip


func position_tooltip(tooltip: Tooltip, screen_pos = Vector2.ZERO) -> void:
	var offset := tooltip.trigger.offset
	
	# Position tooltip relative to origin element set on TooltipTrigger
	var origin := tooltip.trigger.origin
		
	var mouse_position := Vector2.ZERO
	var new_alignment := TooltipEnums.TooltipAlignment.TOP_LEFT
				
	if (
		origin == TooltipEnums.TooltipOrigin.MOUSE_POSITION_START or 
		origin == TooltipEnums.TooltipOrigin.MOUSE_POSITION_FOLLOW
	):
		if (
			tooltip.trigger.state == TooltipEnums.TriggerState.INIT_MOUSE_ENTERED or
			tooltip.trigger.state == TooltipEnums.TriggerState.ACTIVE_MOUSE_ENTERED
		):
			mouse_position = get_viewport().get_mouse_position()
			if origin == TooltipEnums.TooltipOrigin.MOUSE_POSITION_FOLLOW:
				follow_mouse = true
	
	tooltip.set_position(
		get_alignment_position(tooltip, tooltip.trigger.tooltip_alignment, offset) 
		+ screen_pos + mouse_position
	)
	new_alignment = tooltip.trigger.tooltip_alignment

	# Reposition tooltip if necessary based on selected OverflowMode
	if tooltip.trigger.overflow_mode != TooltipEnums.OverflowMode.OVERFLOW:
		var bounds_rect := get_viewport().get_visible_rect()
		var tooltip_global_rect := tooltip.get_global_rect()
		var tooltip_global_rect_points := PackedVector2Array([
				Vector2(
						tooltip_global_rect.position.x, 
						tooltip_global_rect.position.y
				), 
				Vector2(
						tooltip_global_rect.position.x + tooltip_global_rect.size.x, 
						tooltip_global_rect.position.y
				), 
				Vector2(
						tooltip_global_rect.position.x + tooltip_global_rect.size.x, 
						tooltip_global_rect.position.y + tooltip_global_rect.size.y
				), 
				Vector2(
						tooltip_global_rect.position.x, 
						tooltip_global_rect.position.y + tooltip_global_rect.size.y
				)
		])
		var clamped_position := tooltip_global_rect.position
		var left_overflow := false
		var top_overflow := false
		var right_overflow := false
		var bottom_overflow := false
		
		if tooltip.trigger.overflow_bounds == TooltipEnums.OverflowBounds.CONTROL_NODE_SIZE:
			if tooltip.trigger.overflow_element_node:
				bounds_rect = tooltip.trigger.overflow_element_node.get_global_rect()
			else:
				print_debug("Missing Overflow Control Node. Overflow Bounds will instead use Screen Size.")

		if not bounds_rect.encloses(tooltip_global_rect):
			if (
					tooltip.trigger.tooltip_alignment == TooltipEnums.TooltipAlignment.TOP_LEFT 
					or tooltip.trigger.tooltip_alignment == TooltipEnums.TooltipAlignment.MIDDLE_LEFT 
					or tooltip.trigger.tooltip_alignment == TooltipEnums.TooltipAlignment.BOTTOM_LEFT
					or tooltip.trigger.tooltip_alignment == TooltipEnums.TooltipAlignment.BOTTOM_CENTER
					or tooltip.trigger.tooltip_alignment == TooltipEnums.TooltipAlignment.TOP_CENTER
			):
				if tooltip_global_rect_points[0].x < bounds_rect.position.x:
					# Left side out of bounds.
					clamped_position.x = bounds_rect.position.x
					left_overflow = true
			if (
					tooltip.trigger.tooltip_alignment == TooltipEnums.TooltipAlignment.TOP_LEFT 
					or tooltip.trigger.tooltip_alignment == TooltipEnums.TooltipAlignment.TOP_CENTER 
					or tooltip.trigger.tooltip_alignment == TooltipEnums.TooltipAlignment.TOP_RIGHT 
					or tooltip.trigger.tooltip_alignment == TooltipEnums.TooltipAlignment.MIDDLE_LEFT 
					or tooltip.trigger.tooltip_alignment == TooltipEnums.TooltipAlignment.MIDDLE_RIGHT
			):
				if tooltip_global_rect_points[0].y < bounds_rect.position.y:
					# Top side out of bounds.
					clamped_position.y = bounds_rect.position.y
					top_overflow = true
			if (
					tooltip.trigger.tooltip_alignment == TooltipEnums.TooltipAlignment.TOP_RIGHT 
					or tooltip.trigger.tooltip_alignment == TooltipEnums.TooltipAlignment.MIDDLE_RIGHT 
					or tooltip.trigger.tooltip_alignment == TooltipEnums.TooltipAlignment.BOTTOM_RIGHT
					or tooltip.trigger.tooltip_alignment == TooltipEnums.TooltipAlignment.BOTTOM_CENTER
					or tooltip.trigger.tooltip_alignment == TooltipEnums.TooltipAlignment.TOP_CENTER
			):
				if tooltip_global_rect_points[2].x > bounds_rect.size.x + bounds_rect.position.x:
					# Right side out of bounds.
					clamped_position.x -= tooltip_global_rect_points[2].x - bounds_rect.size.x - bounds_rect.position.x
					right_overflow = true
			if (
					tooltip.trigger.tooltip_alignment == TooltipEnums.TooltipAlignment.BOTTOM_LEFT 
					or tooltip.trigger.tooltip_alignment == TooltipEnums.TooltipAlignment.BOTTOM_CENTER 
					or tooltip.trigger.tooltip_alignment == TooltipEnums.TooltipAlignment.BOTTOM_RIGHT 
					or tooltip.trigger.tooltip_alignment == TooltipEnums.TooltipAlignment.MIDDLE_LEFT 
					or tooltip.trigger.tooltip_alignment == TooltipEnums.TooltipAlignment.MIDDLE_RIGHT
			):
				if tooltip_global_rect_points[2].y > bounds_rect.size.y + bounds_rect.position.y:
					# Bottom side out of bounds.
					clamped_position.y -= tooltip_global_rect_points[2].y - bounds_rect.size.y - bounds_rect.position.y
					bottom_overflow = true

			# CLAMP repositioning
			if tooltip.trigger.overflow_mode == TooltipEnums.OverflowMode.CLAMP:
				tooltip.set_global_position(clamped_position, false)
			# FLIPPED_ALIGNMENT repositioning
			elif tooltip.trigger.overflow_mode == TooltipEnums.OverflowMode.FLIPPED_ALIGNMENT:
				var flipped_h_alignment = get_flipped_h_alignment(tooltip.trigger.tooltip_alignment)
				var flipped_v_alignment = get_flipped_v_alignment(tooltip.trigger.tooltip_alignment)
				
				if left_overflow or right_overflow:
					var pos := get_alignment_position(tooltip, flipped_h_alignment, offset)
					tooltip.set_position(pos + mouse_position)
					new_alignment = flipped_h_alignment
						
					if not bounds_rect.encloses(tooltip.get_global_rect()):
						flipped_v_alignment = get_flipped_v_alignment(flipped_h_alignment)
						pos = get_alignment_position(tooltip, flipped_v_alignment, offset)
						tooltip.set_position(pos + mouse_position)
						new_alignment = flipped_v_alignment

				if top_overflow or bottom_overflow:
					var pos := get_alignment_position(tooltip, flipped_v_alignment, offset)
					tooltip.set_position(pos + mouse_position)
					new_alignment = flipped_v_alignment

					if not bounds_rect.encloses(tooltip.get_global_rect()):
						flipped_h_alignment = get_flipped_h_alignment(flipped_v_alignment)
						pos = get_alignment_position(tooltip, flipped_h_alignment, offset)
						tooltip.set_position(pos + mouse_position)
						new_alignment = flipped_h_alignment
	
	tooltip.set_pivot(new_alignment)

func get_alignment_position(tooltip: Tooltip, alignment: TooltipEnums.TooltipAlignment, offset: Vector2) -> Vector2:
	# Set tooltip's position relative to the TooltipTrigger node based on TooltipAlignment
	match alignment:
		TooltipEnums.TooltipAlignment.TOP_LEFT:
			tooltip.set_anchors_and_offsets_preset(
					Control.LayoutPreset.PRESET_TOP_LEFT, 
					Control.LayoutPresetMode.PRESET_MODE_KEEP_SIZE
			)
			tooltip.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			tooltip.grow_vertical = Control.GROW_DIRECTION_BEGIN
			return tooltip.position + Vector2(
					-tooltip.size.x - offset.x, 
					-tooltip.size.y - offset.y
			)
		TooltipEnums.TooltipAlignment.TOP_CENTER:
			tooltip.set_anchors_and_offsets_preset(
					Control.LayoutPreset.PRESET_CENTER_TOP, 
					Control.LayoutPresetMode.PRESET_MODE_KEEP_SIZE
			)
			tooltip.grow_horizontal = Control.GROW_DIRECTION_BOTH
			tooltip.grow_vertical = Control.GROW_DIRECTION_BEGIN
			return tooltip.position + Vector2(
					0.0 - offset.x, 
					-tooltip.size.y - offset.y
			)
		TooltipEnums.TooltipAlignment.TOP_RIGHT:
			tooltip.set_anchors_and_offsets_preset(
					Control.LayoutPreset.PRESET_TOP_RIGHT, 
					Control.LayoutPresetMode.PRESET_MODE_KEEP_SIZE
			)
			tooltip.grow_horizontal = Control.GROW_DIRECTION_END
			tooltip.grow_vertical = Control.GROW_DIRECTION_BEGIN
			return tooltip.position + Vector2(
					tooltip.size.x + offset.x, 
					-tooltip.size.y - offset.y
			)
		TooltipEnums.TooltipAlignment.MIDDLE_LEFT:
			tooltip.set_anchors_and_offsets_preset(
					Control.LayoutPreset.PRESET_CENTER_LEFT, 
					Control.LayoutPresetMode.PRESET_MODE_KEEP_SIZE
			)
			tooltip.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			tooltip.grow_vertical = Control.GROW_DIRECTION_BOTH
			return tooltip.position + Vector2(
					-tooltip.size.x - offset.x, 
					0.0 - offset.y
			)
		TooltipEnums.TooltipAlignment.MIDDLE_CENTER:
			tooltip.set_anchors_and_offsets_preset(
					Control.LayoutPreset.PRESET_FULL_RECT, 
					Control.LayoutPresetMode.PRESET_MODE_KEEP_SIZE
			)
			tooltip.grow_horizontal = Control.GROW_DIRECTION_BOTH
			tooltip.grow_vertical = Control.GROW_DIRECTION_BOTH
			return tooltip.position + Vector2(
					0.0 + offset.x, 
					0.0 - offset.y
			)
		TooltipEnums.TooltipAlignment.MIDDLE_RIGHT:
			tooltip.set_anchors_and_offsets_preset(
					Control.LayoutPreset.PRESET_CENTER_RIGHT, 
					Control.LayoutPresetMode.PRESET_MODE_KEEP_SIZE
			)
			tooltip.grow_horizontal = Control.GROW_DIRECTION_END
			tooltip.grow_vertical = Control.GROW_DIRECTION_BOTH
			return tooltip.position + Vector2(
					tooltip.size.x + offset.x, 
					0.0 - offset.y
			)
		TooltipEnums.TooltipAlignment.BOTTOM_LEFT:
			tooltip.set_anchors_and_offsets_preset(
					Control.LayoutPreset.PRESET_BOTTOM_LEFT, 
					Control.LayoutPresetMode.PRESET_MODE_KEEP_SIZE
			)
			tooltip.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			tooltip.grow_vertical = Control.GROW_DIRECTION_END
			return tooltip.position + Vector2(
					-tooltip.size.x - offset.x, 
					tooltip.size.y + offset.y
			)
		TooltipEnums.TooltipAlignment.BOTTOM_CENTER:
			tooltip.set_anchors_and_offsets_preset(
					Control.LayoutPreset.PRESET_CENTER_BOTTOM, 
					Control.LayoutPresetMode.PRESET_MODE_KEEP_SIZE
			)
			tooltip.grow_horizontal = Control.GROW_DIRECTION_BOTH
			tooltip.grow_vertical = Control.GROW_DIRECTION_END
			return tooltip.position + Vector2(
					0.0 - offset.x, 
					tooltip.size.y + offset.y
			)
		TooltipEnums.TooltipAlignment.BOTTOM_RIGHT:
			tooltip.set_anchors_and_offsets_preset(
					Control.LayoutPreset.PRESET_BOTTOM_RIGHT, 
					Control.LayoutPresetMode.PRESET_MODE_KEEP_SIZE
			)
			tooltip.grow_horizontal = Control.GROW_DIRECTION_END
			tooltip.grow_vertical = Control.GROW_DIRECTION_END
			return tooltip.position + Vector2(
					tooltip.size.x + offset.x, 
					tooltip.size.y + offset.y
			)
		_:
			tooltip.set_anchors_and_offsets_preset(
					Control.LayoutPreset.PRESET_TOP_LEFT, 
					Control.LayoutPresetMode.PRESET_MODE_KEEP_SIZE
			)
			tooltip.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			tooltip.grow_vertical = Control.GROW_DIRECTION_BEGIN
			return tooltip.position + Vector2(
					-tooltip.size.x - offset.x, 
					-tooltip.size.y - offset.y
			)


func get_flipped_h_alignment(_old_alignment: TooltipEnums.TooltipAlignment) -> TooltipEnums.TooltipAlignment:
	match _old_alignment:
		TooltipEnums.TooltipAlignment.TOP_LEFT:
			return TooltipEnums.TooltipAlignment.TOP_RIGHT
		TooltipEnums.TooltipAlignment.TOP_RIGHT:
			return TooltipEnums.TooltipAlignment.TOP_LEFT
		TooltipEnums.TooltipAlignment.MIDDLE_LEFT:
			return TooltipEnums.TooltipAlignment.MIDDLE_RIGHT
		TooltipEnums.TooltipAlignment.MIDDLE_RIGHT:
			return TooltipEnums.TooltipAlignment.MIDDLE_LEFT
		TooltipEnums.TooltipAlignment.BOTTOM_LEFT:
			return TooltipEnums.TooltipAlignment.BOTTOM_RIGHT
		TooltipEnums.TooltipAlignment.BOTTOM_RIGHT:
			return TooltipEnums.TooltipAlignment.BOTTOM_LEFT
		_:
			return _old_alignment


func get_flipped_v_alignment(_old_alignment: TooltipEnums.TooltipAlignment) -> TooltipEnums.TooltipAlignment:
	match _old_alignment:
		TooltipEnums.TooltipAlignment.TOP_LEFT:
			return TooltipEnums.TooltipAlignment.BOTTOM_LEFT
		TooltipEnums.TooltipAlignment.TOP_CENTER:
			return TooltipEnums.TooltipAlignment.BOTTOM_CENTER
		TooltipEnums.TooltipAlignment.TOP_RIGHT:
			return TooltipEnums.TooltipAlignment.BOTTOM_RIGHT
		TooltipEnums.TooltipAlignment.BOTTOM_LEFT:
			return TooltipEnums.TooltipAlignment.TOP_LEFT
		TooltipEnums.TooltipAlignment.BOTTOM_CENTER:
			return TooltipEnums.TooltipAlignment.TOP_CENTER
		TooltipEnums.TooltipAlignment.BOTTOM_RIGHT:
			return TooltipEnums.TooltipAlignment.TOP_RIGHT
		_:
			return _old_alignment

func collapse_tooltip_stack(index: int = -1, collapse_focus_stack: bool = false, override_wait_time = -1.0) -> void:
	if is_collapsing_stack:
		is_collapsing_stack = false
		await get_tree().process_frame
	is_collapsing_stack = true
	
	var stack: Array[Tooltip]
	stack.assign(mouse_tooltip_stack) 
	if collapse_focus_stack:
		stack.assign(focus_tooltip_stack)
		
	if stack.size() == 0:
		is_collapsing_stack = false
		return
		
	set_collapse_stop_size(index, stack)
	while stack.size() > size_to_stop and is_collapsing_stack:
		if stack[0] == null:
			break
			
		if stack[0].state == TooltipEnums.TooltipState.LOCKED:
			stack[0].state = TooltipEnums.TooltipState.UNLOCKING
			
			var wait_time = tooltip_settings.unlock_delay
			
			# When collapsing stack to another tooltip in the stack, in order to
			# do so accurately, we need to set wait_time to 0.0 from
			# tooltip_template._on_mouse_entered
			if override_wait_time != -1.0:
				wait_time = override_wait_time
			
			await get_tree().create_timer(wait_time).timeout
		
		if stack[0] == null:
			break
		
		if stack.size() > size_to_stop and is_collapsing_stack:
			remove_tooltip(stack[0])
			stack.remove_at(0)
			
		await get_tree().process_frame
			
	is_collapsing_stack = false


func set_collapse_stop_size(index: int, stack: Array[Tooltip]) -> void:
	size_to_stop = stack.size() - clampi(index, 0, stack.size())
	if index == -1:
		size_to_stop = 0
	size_to_stop = clamp(size_to_stop, 0, stack.size())


func force_close_stack():
	is_collapsing_stack = false
	var stack_to_close: Array[Tooltip]
	stack_to_close.assign(mouse_tooltip_stack)
	for tooltip in stack_to_close:
		remove_tooltip(tooltip, false)

func remove_tooltip(tooltip: Tooltip, modulate: bool = true) -> void:
	if tooltip.state == TooltipEnums.TooltipState.REMOVE:
		return
	else:
		tooltip.state = TooltipEnums.TooltipState.REMOVE
	
	follow_mouse = false
	if tooltip.trigger:
		tooltip.trigger.on_tooltip_removed()
	
	if tooltip.trigger && tooltip.trigger.trigger_mode == TooltipEnums.TriggerMode.FOCUS_ONLY:
		focus_tooltip_stack.erase(tooltip)
		if focus_tooltip_stack.size() == 0:
			is_collapsing_stack = false
		if modulate:
			for i in focus_tooltip_stack.size():
				focus_tooltip_stack[i].set_stack_position_modulate(i)
	else:
		mouse_tooltip_stack.erase(tooltip)
		if mouse_tooltip_stack.size() == 0:
			is_collapsing_stack = false
		if modulate:
			for i in mouse_tooltip_stack.size():
				mouse_tooltip_stack[i].set_stack_position_modulate(i)
	
	for child_trigger in tooltip.child_trigger_nodes:
		child_trigger.disconnect_signals()
	
	if not is_collapsing_stack:
		await tooltip.tween_out()
	
	tooltip.queue_free()
