class_name TooltipTrigger
extends Node

## The TooltipTrigger is used to set the positioning and content of tooltips.
##
## [TooltipTrigger]s work with the [TooltipManager] to instantiate a new
## tooltip and position it according to the settings on the [TooltipTrigger].
## The content defined in [b]Tooltip Strings[/b] is then sent to the [Tooltip] 
## Template to be set on its [RichTextLabel](s).
## [br][br]
## Global Tooltip Settings, such as [b]Lock Mode[/b] or [b]Open Delay[/b], can 
## also be optionally overidden on the [TooltipTrigger].

## The [Tooltip] Template path to use for the instantiated [Tooltip]. If empty, 
## the default [Tooltip] Template (first one in the directory) will be used.
@export var tooltip_template_path: String
## Whether the tooltip is triggered on the signal [code]mouse_entered[/code], 
## [code]focus_entered[/code], or both.
@export var trigger_mode: TooltipEnums.TriggerMode = TooltipEnums.TriggerMode.MOUSE_AND_FOCUS

@export_group("Layout")
## The alignment of the [Tooltip] position relative to its [b]origin[/b].
@export var tooltip_alignment: TooltipEnums.TooltipAlignment
## The [b]origin[/b] of the [Tooltip] around which it is aligned and positioned.
@export var origin: TooltipEnums.TooltipOrigin
## The UI element used to define the [Tooltip]'s [b]origin[/b], if [code]origin[/code] 
## is set to [code]TooltipEnums.TooltipOrigin.REMOTE_ELEMENT[/code].
@export var remote_element_node: Control
## The amount to offset the [Tooltip] from its [b]origin[/b].
@export var offset: Vector2

@export_group("Overflow")
## The mode for handling a [Tooltip] overlapping its defined bounds.
@export var overflow_mode: TooltipEnums.OverflowMode
## The bounds to use for restricting [Tooltip] positioning.
@export var overflow_bounds: TooltipEnums.OverflowBounds
## The UI element to use to define the [Tooltip] bounds if [code]overflow_bounds[/code]
## is set to [code]TooltipEnums.OverflowBounds.CONTROL_NODE_SIZE[/code].
@export var overflow_element_node: Control

@export_group("Tooltip Settings")
## Override the global settings as defined by the resource set on the [TooltipManager].
@export var tooltip_settings_override: Resource

@export_group("Content")
## The text to apply to the [Label]s or [RichTextLabel]s defined on the [Tooltip] Template.
@export_multiline var tooltip_strings: Array[String]

var control_node: Control
var collision_object_2d_node: CollisionObject2D
var collision_object_3d_node: CollisionObject3D

var state: TooltipEnums.TriggerState
var active_tooltip: Tooltip

var delay_timer: Timer = Timer.new()


func _init() -> void:
	add_child(delay_timer)


func _ready() -> void:
	init_signals()


func _on_mouse_entered() -> void:
	if state != TooltipEnums.TriggerState.READY:
		return
	
	state = TooltipEnums.TriggerState.INIT_MOUSE_ENTERED
	try_await_open_delay()


func _on_mouse_exited() -> void:
	cancel_open_delay()
	
	if active_tooltip and active_tooltip.state == TooltipEnums.TooltipState.READY:
		TooltipManager.remove_tooltip(active_tooltip)
	else:
		if TooltipManager.mouse_tooltip_stack.size() > 1:
			TooltipManager.collapse_tooltip_stack(1)
		else:
			TooltipManager.collapse_tooltip_stack()


func _on_focus_entered() -> void:
	if state != TooltipEnums.TriggerState.READY:
		return
		
	if TooltipManager.is_collapsing_stack:
		return
	
	state = TooltipEnums.TriggerState.INIT_FOCUS_ENTERED
	try_await_open_delay(Vector2.ZERO, TooltipEnums.TriggerState.ACTIVE_FOCUS_ENTERED)


func _on_focus_exited() -> void:
	cancel_open_delay(TooltipEnums.TriggerState.ACTIVE_FOCUS_ENTERED)
	
	if active_tooltip and active_tooltip.state == TooltipEnums.TooltipState.READY:
		TooltipManager.remove_tooltip(active_tooltip)
	else:
		TooltipManager.collapse_tooltip_stack(-1, true)

## Used when needing to set a tooltip's position relative to a 2D object
func _on_mouse_entered_2d() -> void:
	if state != TooltipEnums.TriggerState.READY:
		return
		
	var selection_node := self as Node
	var screen_pos = selection_node.get_global_transform_with_canvas().origin
	
	state = TooltipEnums.TriggerState.INIT_MOUSE_ENTERED
	try_await_open_delay(screen_pos)

## Used when needing to set a tooltip's position relative to a 3D object
func _on_mouse_entered_3d() -> void:
	if state != TooltipEnums.TriggerState.READY:
		return
		
	var selection_node := self as Node
	var camera = get_viewport().get_camera_3d()
	if camera:
		var screen_pos: Vector2i = camera.unproject_position(selection_node.global_position)
		# This sets correct position when SubViewport is smaller than the main 
		# viewport/screen size.
		screen_pos += get_window().size - get_viewport().size
		
		state = TooltipEnums.TriggerState.INIT_MOUSE_ENTERED
		try_await_open_delay(screen_pos)
	else:
		print_debug("Camera3D not found in scene. Cannot get tooltip screen position from Node3D.")


func init_signals() -> void:
	control_node = get_node(".") as Control
	if control_node:
		if(
			trigger_mode == TooltipEnums.TriggerMode.MOUSE_AND_FOCUS or 
			trigger_mode == TooltipEnums.TriggerMode.MOUSE_ONLY
		):
			control_node.mouse_entered.connect(_on_mouse_entered)
			control_node.mouse_exited.connect(_on_mouse_exited)
		if(
			trigger_mode == TooltipEnums.TriggerMode.MOUSE_AND_FOCUS or 
			trigger_mode == TooltipEnums.TriggerMode.FOCUS_ONLY
		):
			control_node.focus_entered.connect(_on_focus_entered)
			control_node.focus_exited.connect(_on_focus_exited)
			
		return

	collision_object_2d_node = get_node(".") as CollisionObject2D
	if collision_object_2d_node:
		if(
			trigger_mode == TooltipEnums.TriggerMode.MOUSE_AND_FOCUS or 
			trigger_mode == TooltipEnums.TriggerMode.MOUSE_ONLY
		):
			if (
				origin == TooltipEnums.TooltipOrigin.MOUSE_POSITION_START or
				origin == TooltipEnums.TooltipOrigin.MOUSE_POSITION_FOLLOW
			):
				collision_object_2d_node.mouse_entered.connect(_on_mouse_entered)
			else:
				collision_object_2d_node.mouse_entered.connect(_on_mouse_entered_2d)
			
			collision_object_2d_node.mouse_exited.connect(_on_mouse_exited)
			
		return

	var collision_object_3d_node = get_node(".") as CollisionObject3D
	if collision_object_3d_node:
		if(
			trigger_mode == TooltipEnums.TriggerMode.MOUSE_AND_FOCUS or 
			trigger_mode == TooltipEnums.TriggerMode.MOUSE_ONLY
		):
			if (
				origin == TooltipEnums.TooltipOrigin.MOUSE_POSITION_START or
				origin == TooltipEnums.TooltipOrigin.MOUSE_POSITION_FOLLOW
			):
				collision_object_3d_node.mouse_entered.connect(_on_mouse_entered)
			else:
				collision_object_3d_node.mouse_entered.connect(_on_mouse_entered_3d)
			collision_object_3d_node.mouse_exited.connect(_on_mouse_exited)
		
		return


func disconnect_signals() -> void:
	if control_node:
		if control_node.mouse_entered.is_connected(_on_mouse_entered):
			control_node.mouse_entered.disconnect(_on_mouse_entered)
		if control_node.mouse_exited.is_connected(_on_mouse_exited):
			control_node.mouse_exited.disconnect(_on_mouse_exited)
	if collision_object_2d_node:
		if collision_object_2d_node.mouse_entered.is_connected(_on_mouse_entered):
			collision_object_2d_node.mouse_entered.disconnect(_on_mouse_entered)
		if collision_object_2d_node.mouse_entered.is_connected(_on_mouse_entered_2d):
			collision_object_2d_node.mouse_entered.disconnect(_on_mouse_entered_2d)
		if collision_object_2d_node.mouse_exited.is_connected(_on_mouse_exited):
			collision_object_2d_node.mouse_exited.disconnect(_on_mouse_exited)
	if collision_object_3d_node:
		if collision_object_3d_node.mouse_entered.is_connected(_on_mouse_entered):
			collision_object_3d_node.mouse_entered.disconnect(_on_mouse_entered)
		if collision_object_3d_node.mouse_exited.is_connected(_on_mouse_exited):
			collision_object_3d_node.mouse_exited.disconnect(_on_mouse_exited)


func try_await_open_delay(screen_pos := Vector2.ZERO, active_state := TooltipEnums.TriggerState.ACTIVE_MOUSE_ENTERED):
	var delay = TooltipManager.tooltip_settings.open_delay
	if tooltip_settings_override:
		delay = tooltip_settings_override.open_delay
	
	if delay <= 0.0:
		active_tooltip = await TooltipManager.init_tooltip(self, screen_pos)
		active_tooltip.set_content(tooltip_strings)
		state = active_state
		return
	
	delay_timer.wait_time = delay
	delay_timer.start()
	await delay_timer.timeout
	
	# Because this is a coroutine the state may have changed while awaiting the
	# Timer, so need to check it again to prevent multiple initializations.
	if(
		state != TooltipEnums.TriggerState.INIT_MOUSE_ENTERED and 
		state != TooltipEnums.TriggerState.INIT_FOCUS_ENTERED
	):
		return
	
	active_tooltip = await TooltipManager.init_tooltip(self, screen_pos)
	active_tooltip.set_content(tooltip_strings)
	state = active_state


func cancel_open_delay(active_state := TooltipEnums.TriggerState.ACTIVE_MOUSE_ENTERED):
	delay_timer.stop()
	TooltipManager.is_collapsing_stack = false
	if active_tooltip:
		state = active_state
	else:
		state = TooltipEnums.TriggerState.READY


func cancel_unlock_delay():
	delay_timer.stop()
	TooltipManager.is_collapsing_stack = false
	if active_tooltip and active_tooltip.state == TooltipEnums.TooltipState.UNLOCKING:
		active_tooltip.state = TooltipEnums.TooltipState.LOCKED


func on_tooltip_removed() -> void:
	state = TooltipEnums.TriggerState.READY
	active_tooltip = null
