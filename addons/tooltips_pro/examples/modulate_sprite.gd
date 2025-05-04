extends CanvasItem

@export var color: Color

func _ready() -> void:
	self_modulate = color
