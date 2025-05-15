class_name TooltipEnums


enum TriggerMode{
	## [TooltipTrigger] will connect to and create a tooltip on 
	## [code]mouse_entered[/code] and [code]focus_entered[/code]
	MOUSE_AND_FOCUS,
	## [code]mouse_entered[/code] only
	MOUSE_ONLY,
	## [code]focus_entered[/code] only if [TooltipTrigger] inherits from [Control].
	## [code]FOCUS_ONLY[/code] should be used on 2D or 3D nodes when you have a
	## custom script determining when these nodes are "selected." See the prism 
	## example and [code]/examples/scripts/example_collision_object_3d.gd[/code]
	FOCUS_ONLY,
}


# Used by TooltipTrigger to set position relative to the Tooltip's Origin.
enum TooltipAlignment {
	TOP_LEFT,
	TOP_CENTER,
	TOP_RIGHT,
	MIDDLE_LEFT,
	MIDDLE_CENTER,
	MIDDLE_RIGHT,
	BOTTOM_LEFT,
	BOTTOM_CENTER,
	BOTTOM_RIGHT
}


# Used with TooltipTrigger.overflow_mode to set what bounds Tooltips should be
# constrained by when considering overflow positioning.
enum OverflowBounds {
	## Bounds are set to the main [Viewport]'s visible rect (window size).
	WINDOW_SIZE,
	## Bounds are set to a rect defined by a [Control] in the scene, set on
	## [code]TooltipTrigger.overflow_element_node[/code].
	CONTROL_NODE_SIZE,
}


# Used with TooltipTrigger.overflow_bounds to determine how a Tooltip should be 
# positioned when overflowing the designated OverflowBounds.
enum OverflowMode {
	## [code]TooltipAlignment[/code] is flipped horizontally or vertically or both.
	FLIPPED_ALIGNMENT,
	## [Tooltip] position is clamped to the set bounds.
	CLAMP,
	## Allow [Tooltip] overflow and do not adjust its position.
	OVERFLOW,
}


# A global setting on TooltipManager or override setting on TooltipTrigger that
# sets how Tooltips are locked.
enum TooltipLockMode {
	## [Tooltip]s lock after a delay of [code]timer_lock_delay[/code].
	TIMER_LOCK,
	## [Tooltip]s lock with [code]Input.is_action_just_pressed("LockTooltip")[/code].
	## By default, the "LockTooltip" input action is [kbd]T[/kbd] or [kbd]Middle Mouse Button[/kbd].
	ACTION_LOCK,
	## [Tooltip]s always open in locked state.
	AUTO_LOCK,
	## [Tooltip]s cannot be locked.
	NO_LOCK,
}


# Used by TooltipTrigger.origin to set the origin, or pivot, around which the 
# Tooltip is aligned and positioned.
enum TooltipOrigin {
	## Position the [Tooltip] relative to the [TooltipTrigger] [Control].
	TRIGGER_ELEMENT,
	## Position the [Tooltip] relative to the [Control] assigned on 
	## [code]TooltipTrigger.remote_element_node[/code].
	REMOTE_ELEMENT,
	## Position the [Tooltip] relative to the [b]mouse position[b] at the time 
	## of trigger.
	MOUSE_POSITION_START,
	## Position the [Tooltip] relative to the [b]mouse position[b] and follow 
	## its position unless the [Tooltip] is locked.
	MOUSE_POSITION_FOLLOW,
}


enum TooltipState {
	INIT,
	READY,
	LOCKING,
	LOCKED,
	UNLOCKING,
	REMOVE,
}


enum TriggerState {
	READY,
	INIT_MOUSE_ENTERED,
	INIT_FOCUS_ENTERED,
	ACTIVE_MOUSE_ENTERED,
	ACTIVE_FOCUS_ENTERED
}
