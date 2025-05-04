@tool
class_name TooltipManager
extends Node

static var _singleton: TooltipManager = null
static var singleton: TooltipManager:
	get:
		return _singleton

@export var default_tooltip_settings: Resource
@export var tooltip_settings: Resource
@export var tooltip_template_paths: Array[String]

var mouse_tooltip_stack: Array[Tooltip]
var focus_tooltip_stack: Array[Tooltip]

var follow_mouse := false


func _init() -> void:
	if singleton == null:
		_singleton = self


func _input(event):
	if not mouse_tooltip_stack:
		return
	if (
		mouse_tooltip_stack.back().state == TooltipEnums.TooltipState.LOCKED
		or mouse_tooltip_stack.back().state == TooltipEnums.TooltipState.UNLOCKING
	):
		return
		
	# Mouse in viewport coordinates.
	if follow_mouse and event is InputEventMouseMotion:
		position_tooltip(mouse_tooltip_stack.back(), false)


func _process(delta: float) -> void:
	if (
		tooltip_settings.lock_mode == TooltipEnums.TooltipLockMode.ACTION_LOCK 
		and mouse_tooltip_stack.size() > 0
	):
		if Input.is_action_just_pressed("LockTooltip"):
			mouse_tooltip_stack[-1].toggle_lock()


func init_tooltip(tooltip_trigger: TooltipTrigger, is_collision: bool, screen_pos: Vector2) -> Tooltip:
	# Instantiate tooltip and add to Tooltip Stack
	var tooltip_path = tooltip_template_paths[tooltip_trigger.tooltip_template]
	var new_tooltip := load(tooltip_path).instantiate() as Tooltip
	
	# HACK: Using Hide()/Show() prevents the tooltip from resizing correctly 
	# to fit the content, so it's moved out of view until positioned correctly
	# instead.
	new_tooltip.set_position(Vector2(100000, 100000))
	
	new_tooltip._init(tooltip_trigger)
	if tooltip_trigger.trigger_on_focus:
		focus_tooltip_stack.append(new_tooltip)
	else:
		mouse_tooltip_stack.append(new_tooltip)
		
	if tooltip_trigger.origin == TooltipEnums.TooltipOrigin.TRIGGER_ELEMENT:
		if is_collision:
			add_child(new_tooltip)
		else:
			tooltip_trigger.add_child(new_tooltip)
	elif tooltip_trigger.origin == TooltipEnums.TooltipOrigin.REMOTE_ELEMENT:
		if tooltip_trigger.remote_element_node:
			tooltip_trigger.remote_element_node.add_child(new_tooltip)
	elif (
			tooltip_trigger.origin == TooltipEnums.TooltipOrigin.MOUSE_POSITION_START 
			or tooltip_trigger.origin == TooltipEnums.TooltipOrigin.MOUSE_POSITION_FOLLOW
	):
		add_child(new_tooltip)
	
	# HACK: Most tooltips need to await process_frame and be positioned after
	# content is set, but tooltips triggered on focus shouldn't to prevent a 
	# flicker for a frame when tabbing between tooltip triggers.
	if tooltip_trigger.trigger_on_focus:
		position_tooltip(new_tooltip, is_collision, screen_pos)
	
	for i in tooltip_trigger.tooltip_strings.size():
		if new_tooltip.content_labels.size() > i:
			new_tooltip.content_labels[i].text = tooltip_trigger.tooltip_strings[i]
		else:
			print_debug(new_tooltip.name, " has fewer content labels than there are content strings on trigger ", tooltip_trigger.name)

	# HACK: Must await one frame due to issues related to the tooltip resizing 
	# to correctly fit the content. Don't ask...
	if not tooltip_trigger.trigger_on_focus:
		await get_tree().process_frame
		position_tooltip(new_tooltip, is_collision, screen_pos)
	
	new_tooltip.init_lock_mode()
	
	return new_tooltip


func position_tooltip(tooltip: Tooltip, world_to_screen: bool = false, screen_pos = Vector2.ZERO) -> void:	
	var offset := tooltip.trigger.offset
	
	# Position tooltip relative to origin element set on TooltipTrigger
	var origin := tooltip.trigger.origin
		
	var mouse_position := Vector2.ZERO
	var new_alignment := TooltipEnums.TooltipAlignment.TOP_LEFT
				
	if (
		origin == TooltipEnums.TooltipOrigin.MOUSE_POSITION_START 
		or origin == TooltipEnums.TooltipOrigin.MOUSE_POSITION_FOLLOW
	):
		mouse_position = get_viewport().get_mouse_position()
		if origin == TooltipEnums.TooltipOrigin.MOUSE_POSITION_FOLLOW:
			follow_mouse = true
	
	if world_to_screen and screen_pos != Vector2.ZERO:
		tooltip.set_position(
				get_alignment_position(tooltip, tooltip.trigger.tooltip_alignment, offset) 
				+ screen_pos + mouse_position
		)
	else:
		tooltip.set_position(
				get_alignment_position(tooltip, tooltip.trigger.tooltip_alignment, offset) 
				+ mouse_position
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


func collapse_tooltip_stack(collapse_focus_stack: bool = false) -> void:
	print("collapse_tooltip_stack")
	# TODO: Collapse range of specific tooltips
	var stack_to_collapse := mouse_tooltip_stack
	if collapse_focus_stack:
		stack_to_collapse = focus_tooltip_stack
		
	for i in range(stack_to_collapse.size()-1, -1, -1):
		remove_tooltip(stack_to_collapse[i])

func remove_tooltip(tooltip: Tooltip) -> void:
	tooltip.trigger.on_tooltip_removed()
	if tooltip.trigger.trigger_on_focus:
		focus_tooltip_stack.erase(tooltip)
	else:
		mouse_tooltip_stack.erase(tooltip)
	
	tooltip.queue_free()
	
	follow_mouse = false
