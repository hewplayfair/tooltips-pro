class_name TooltipEnums


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


## Used by OverflowMode to determine when a tooltip needs to be repositioned
enum OverflowBounds {
	## Bounds are set to main viewport screen size
	WINDOW_SIZE,
	## Bounds are set to a custom UI node size
	CONTROL_NODE_SIZE,
}


enum OverflowMode {
	## Tooltip alignment changed to one not out of bounds
	FLIPPED_ALIGNMENT,
	## Tooltip position is clamped to the set bounds so it is always fully visible.
	CLAMP,
	## Tooltip position will not be changed if it goes out of the set bounds.
	OVERFLOW,
}


enum TooltipLockMode {
	## Tooltip locks after a delay of TooltipManager.TimerLockDelay (seconds).
	TIMER_LOCK,
	## Tooltip locks after TooltipActionButton is pressed by player.
	ACTION_LOCK,
	## Tooltip always opened in locked state.
	AUTO_LOCK,
	## Tooltip cannot be locked.
	NO_LOCK,
}


enum TooltipOrigin {
	## Position the tooltip relative to the trigger node
	TRIGGER_ELEMENT,
	## Position the tooltip relative to a remote node
	REMOTE_ELEMENT,
	## Position the tooltip relative to the mouse position at time of trigger
	MOUSE_POSITION_START,
	## Position the tooltip relative to the mouse position and follow until lock/unlock
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
	INITIALIZING,
	ACTIVE,
}
