class_name TooltipStackCoroutineManager

static var _force_close_stack_coroutine: Coroutine

class Coroutine extends Node:
	func run():
		if self.is_inside_tree():
			await get_tree().create_timer(TooltipManager.tooltip_settings.open_delay).timeout
			TooltipManager.force_close_stack()
		pass
	
static func force_close_stack_run(node: Node):
	_force_close_stack_coroutine = Coroutine.new()
	node.add_child.call(_force_close_stack_coroutine)
	_force_close_stack_coroutine.run()
	
static func free_coroutines():
	if _force_close_stack_coroutine:
		_force_close_stack_coroutine.free()
