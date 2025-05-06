extends Resource

@export_group("Lock")
## The mode used to set tooltips into a Locked state. While locked, Tooltips  
## will not automatically close when the cursor moves off of the TooltipTrigger
@export var lock_mode: TooltipEnums.TooltipLockMode
@export_group("Delay")
## The default delay (in seconds) until a Tooltip is opened,
## upon the TooltipTrigger being activated.
@export_range(0.0, 5.0) var open_delay: float
## The default delay (in seconds) until a Tooltip is Locked, when 
## TooltipManager.lock_mode is set to TIMER_LOCK
@export_range(0.0, 5.0) var timer_lock_delay: float
## The default delay (in seconds) until a locked Tooltip is unlocked and closes,
## upon the Tooltip losing focus.
@export_range(0.0, 5.0) var unlock_delay: float

@export_group("Stack Appearance")
@export var darken_step_count: int
@export_range(0.0, 1.0) var darken_step_value: float
@export var step_limit_color: Color
