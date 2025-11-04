extends Node

@export var selection_object: Node3D
@export var prism_mesh_instance: MeshInstance3D
@export var cube_mesh_instance: MeshInstance3D
@export var prism_tooltip_trigger: TooltipTrigger
var is_selected: bool


func _process(delta: float) -> void:
	selection_object.rotate_y(PI/2 * get_process_delta_time() * 0.25)


func _on_static_body_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		toggle_selection(!is_selected)


func toggle_selection(toggle: bool) -> void:
	is_selected = toggle
	if toggle:
		prism_mesh_instance.mesh.surface_get_material(0).next_pass.set_shader_parameter("outline_width", 3.0)
		prism_tooltip_trigger._on_focus_entered_3d()
	else:
		prism_mesh_instance.mesh.surface_get_material(0).next_pass.set_shader_parameter("outline_width", 0.0)
		prism_tooltip_trigger._on_focus_exited()


func _on_3d_mouse_entered() -> void:
	cube_mesh_instance.mesh.surface_get_material(0).next_pass.set_shader_parameter("outline_width", 3.0)


func _on_3d_mouse_exited() -> void:
	cube_mesh_instance.mesh.surface_get_material(0).next_pass.set_shader_parameter("outline_width", 0.0)
