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
## The number of tooltips in the stack behind the most recent that will be 
## progressively darkened by darken_step_value.
@export var darken_step_count: int
## Tooltips in the stack behind the most recent tooltip have their color 
## modulated to darken by this amount.
@export_range(0.0, 1.0) var darken_step_value: float
## The color used to modulate tooltips if they are in a stack position 
## greater than darken_step_count.
@export var step_limit_color: Color
