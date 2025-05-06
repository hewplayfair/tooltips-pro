@tool
class_name TooltipTrigger
extends Node

## The [Tooltip] Template to use for the instantiated tooltip. These are defined 
## on the [TooltipManager].
@export var tooltip_template: int
## If [code]true[/code] and a [Control] node, the tooltip will trigger on [signal 
## Control.focus_entered].[br][br]If [code]true[/code] and a [CollisionObject2D]/
## [CollisionObject3D] node, the tooltip will need to be triggered manually with a 
## custom script.
@export var trigger_on_focus: bool

@export_group("Origin")
## The Origin, or anchor, of the tooltip.
@export var origin: TooltipEnums.TooltipOrigin
## The UI element to use to define the tooltip Origin, if origin is set to REMOTE_ELEMENT.
@export var remote_element_node: Control

@export_group("Offset")
## The amount to offset the tooltip from its Origin.
@export var offset: Vector2

@export_group("Layout")
## The alignment of the Tooltip position relative to its Origin.
@export var tooltip_alignment: TooltipEnums.TooltipAlignment

@export_group("Overflow")
## The mode for handling a tooltip overlapping its defined bounds.
@export var overflow_mode: TooltipEnums.OverflowMode
## The bounds to use for restricting tooltip positioning.
@export var overflow_bounds: TooltipEnums.OverflowBounds
## The UI element to use to define the tooltip bounds if overflow_bounds is set 
## to CONTROL_NODE_SIZE.
@export var overflow_element_node: Control

@export_group("Tooltip Settings")
## Override the global settings as defined by the resource set on the Tooltip Manager.
@export var tooltip_settings_override: Resource

@export_group("Content")
## The text to apply to the Labels defined on the Tooltip Template.
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
		
	printerr("_on_mouse_entered ", self)
	try_await_open_delay()
	
	# TODO: 
	# if owner is at top of tooltip stack, cancel unlock delay. If owner is at any 
	# other point in stack, collapse it to that point 
	var owner_tooltip_template = self.owner as Tooltip
	if owner_tooltip_template:
		owner_tooltip_template.trigger.cancel_unlock_delay()


func _on_mouse_exited() -> void:
	printerr("_on_mouse_exited ", self)
	cancel_open_delay()
	
	if active_tooltip:
		try_await_unlock_delay()


func _on_focus_entered() -> void:
	if state != TooltipEnums.TriggerState.READY:
		return
		
	# Need to wait for process frame because if grab_focus is set in another
	# script's _ready(), there's a tooltip positioning error.
	await get_tree().process_frame
	try_await_open_delay()


func _on_focus_exited() -> void:
	cancel_open_delay()
	# try_await_unlock_delay()
	TooltipManager.singleton.collapse_tooltip_stack(true)

## Used when needing to set a tooltip's position relative to a 2D object
func _on_mouse_entered_2d() -> void:
	if state != TooltipEnums.TriggerState.READY:
		return
		
	var selection_node := self as Node
	var screen_pos = selection_node.get_global_transform_with_canvas().origin
	try_await_open_delay(true, screen_pos)

## Used when needing to set a tooltip's position relative to a 3D object
func _on_mouse_entered_3d() -> void:
	if state != TooltipEnums.TriggerState.READY:
		return
		
	var selection_node := self as Node
	var camera = get_viewport().get_camera_3d()
	if camera:
		var screen_pos = camera.unproject_position(selection_node.global_position)
		try_await_open_delay(true, screen_pos)
	else:
		print_debug("Camera3D not found in scene. Cannot get tooltip screen position from Node3D.")


func init_signals() -> void:
	control_node = get_node(".") as Control
	if control_node:
		if trigger_on_focus:
			control_node.focus_entered.connect(_on_focus_entered)
			control_node.focus_exited.connect(_on_focus_exited)
		else:
			control_node.mouse_entered.connect(_on_mouse_entered)
			control_node.mouse_exited.connect(_on_mouse_exited)
			
		return

	collision_object_2d_node = get_node(".") as CollisionObject2D
	if collision_object_2d_node:
		# If trigger_on_focus, handle tooltip triggering in another game script
		# along with object selection.
		if not trigger_on_focus:
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
		# If trigger_on_focus, handle tooltip triggering in another game script
		# along with object selection.
		if not trigger_on_focus:
			if (
				origin == TooltipEnums.TooltipOrigin.MOUSE_POSITION_START or
				origin == TooltipEnums.TooltipOrigin.MOUSE_POSITION_FOLLOW
			):
				collision_object_3d_node.mouse_entered.connect(_on_mouse_entered)
			else:
				collision_object_3d_node.mouse_entered.connect(_on_mouse_entered_3d)
			collision_object_3d_node.mouse_exited.connect(_on_mouse_exited)
		return


func try_await_open_delay(is_collision := false, screen_pos := Vector2.ZERO):
	state = TooltipEnums.TriggerState.INITIALIZING
	
	var delay = TooltipManager.singleton.tooltip_settings.open_delay
	if tooltip_settings_override:
		delay = tooltip_settings_override.open_delay
	
	if delay <= 0.0:
		active_tooltip = await TooltipManager.singleton.init_tooltip(self, is_collision, screen_pos)
		state = TooltipEnums.TriggerState.ACTIVE
		set_tooltip_content()
		return
	
	delay_timer.wait_time = delay
	delay_timer.start()
	await delay_timer.timeout
	
	# Because this is a coroutine the state may have changed while awaiting the
	# Timer, so need to check it again to prevent multiple initializations.
	if state != TooltipEnums.TriggerState.INITIALIZING:
		return
	
	active_tooltip = await TooltipManager.singleton.init_tooltip(self, is_collision, screen_pos)
	state = TooltipEnums.TriggerState.ACTIVE
	set_tooltip_content()

func try_await_unlock_delay():
	if active_tooltip and active_tooltip.state != TooltipEnums.TooltipState.LOCKED:
		TooltipManager.singleton.collapse_tooltip_stack(trigger_on_focus)
		return
	
	if active_tooltip:
		active_tooltip.state = TooltipEnums.TooltipState.UNLOCKING
	var wait_time = TooltipManager.singleton.tooltip_settings.unlock_delay
	if tooltip_settings_override:
		wait_time = tooltip_settings_override.unlock_delay
	delay_timer.start(wait_time)
	await delay_timer.timeout
	
	if not active_tooltip:
		return
	
	if active_tooltip.state != TooltipEnums.TooltipState.UNLOCKING:
		return
		
	TooltipManager.singleton.collapse_tooltip_stack(trigger_on_focus)


func cancel_open_delay():
	printerr("cancel_open_delay ", self)
	delay_timer.stop()
	if active_tooltip:
		state = TooltipEnums.TriggerState.ACTIVE
	else:
		state = TooltipEnums.TriggerState.READY


func cancel_unlock_delay():
	printerr("cancel_unlock_delay ", self)
	delay_timer.stop()
	if active_tooltip and active_tooltip.state == TooltipEnums.TooltipState.UNLOCKING:
		active_tooltip.state = TooltipEnums.TooltipState.LOCKED


func set_tooltip_content():
	for i in active_tooltip.trigger.tooltip_strings.size():
		if active_tooltip.content_labels.size() > i:
			active_tooltip.content_labels[i].text = active_tooltip.trigger.tooltip_strings[i]
		else:
			print_debug(active_tooltip.name, " has fewer content labels than there are content strings on trigger ", active_tooltip.trigger.name)

func on_tooltip_removed() -> void:
	state = TooltipEnums.TriggerState.READY
	active_tooltip = null
