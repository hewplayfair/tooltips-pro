extends Resource

@export_group("Templates")
## Directory path for loading all the [Tooltip] Templates
@export var tooltip_template_dir_path: String = "res://addons/tooltips_pro/examples/tooltip_templates/"
@export_group("Lock")
## The mode used to set tooltips into a Locked state. While locked, Tooltips  
## will not automatically close when the cursor moves off of the [TooltipTrigger]
@export var lock_mode: TooltipEnums.TooltipLockMode = TooltipEnums.TooltipLockMode.TIMER_AND_ACTION_LOCK
@export_group("Delay")
## The default delay (in seconds) until a [Tooltip] is opened,
## upon the [TooltipTrigger] being activated.
@export_range(0.0, 5.0) var open_delay: float = 0.1
## The default delay (in seconds) until a [Tooltip] is Locked, when 
## [code]TooltipManager.lock_mode[/code] is set to [code]TIMER_LOCK[/code]
@export_range(0.0, 5.0) var timer_lock_delay: float = 1.5
## The default delay (in seconds) until a locked [Tooltip] is unlocked and closes,
## upon the [Tooltip] losing focus.
@export_range(0.0, 5.0) var unlock_delay: float = 0.25

@export_group("Stack Appearance")
## The number of tooltips in the stack behind the most recent that will be 
## progressively darkened by [code]darken_step_value[/code].
@export var darken_step_count: int = 3
## Tooltips in the stack behind the most recent tooltip have their color 
## modulated to darken by this amount.
@export_range(0.0, 1.0) var darken_step_value: float = 0.25
## The color used to modulate tooltips if they are in a stack position 
## greater than [code]darken_step_count[/code].
@export var step_limit_color: Color = Color(00000040)
