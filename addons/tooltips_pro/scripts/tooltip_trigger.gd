@tool
class_name TooltipTrigger
extends Node

@export var tooltip_template: int
@export var trigger_on_focus := false

@export_group("Origin")
@export var origin := TooltipEnums.TooltipOrigin.TRIGGER_ELEMENT
@export var remote_element_node: Control

@export_group("Offset")
@export var offset := Vector2.ZERO

@export_group("Layout")
## The alignment of the Tooltip position relative to its TooltipAnchor
@export var tooltip_alignment := TooltipEnums.TooltipAlignment.TOP_RIGHT

@export_group("Overflow")
@export var overflow_mode := TooltipEnums.OverflowMode.CLAMP
@export var overflow_bounds := TooltipEnums.OverflowBounds.WINDOW_SIZE
@export var overflow_element_node: Control

@export_group("Tooltip Settings")
@export var tooltip_settings_override: Resource

@export_group("Content")
@export_multiline var tooltip_strings: Array[String]

var control_node: Control
var collision_object_2d_node: CollisionObject2D
var collision_object_3d_node: CollisionObject3D

var state := TooltipEnums.TriggerState.READY
var active_tooltip: Tooltip

var delay_timer := Timer.new()


func _init() -> void:
	add_child(delay_timer)


func _ready() -> void:	
	init_signals()


func _on_mouse_entered() -> void:
	print("_on_mouse_entered trigger: ", self.name)
	print("trigger state: ", TooltipEnums.TriggerState.keys()[state])
	if state != TooltipEnums.TriggerState.READY:
		return
		
	try_await_open_delay()


func _on_mouse_exited() -> void:
	print("_on_mouse_exited trigger: ", self.name)
	print("trigger state: ", TooltipEnums.TriggerState.keys()[state])
	cancel_open_delay()
	state = TooltipEnums.TriggerState.READY
	
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
	state = TooltipEnums.TriggerState.READY
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
	if active_tooltip:
		return
		
	state = TooltipEnums.TriggerState.INITIALIZING
	
	var delay = TooltipManager.singleton.tooltip_settings.open_delay
	if tooltip_settings_override:
		delay = tooltip_settings_override.open_delay
	
	if delay <= 0.0:
		active_tooltip = await TooltipManager.singleton.init_tooltip(self, is_collision, screen_pos)
		state = TooltipEnums.TriggerState.ACTIVE
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


func try_await_unlock_delay():
	print("try_await_unlock_delay")
	if active_tooltip.state != TooltipEnums.TooltipState.LOCKED:
		TooltipManager.singleton.collapse_tooltip_stack(trigger_on_focus)
		return
	
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
	delay_timer.stop()
	state = TooltipEnums.TriggerState.READY


func cancel_unlock_delay():
	print("cancel_unlock_delay")
	delay_timer.stop()
	if active_tooltip and active_tooltip.state == TooltipEnums.TooltipState.UNLOCKING:
		active_tooltip.state = TooltipEnums.TooltipState.LOCKED


func on_tooltip_removed() -> void:
	state = TooltipEnums.TriggerState.READY
	active_tooltip = null
