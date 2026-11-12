extends Node3D

var world_lighting_enabled := true

@onready var environment: Environment = $WorldEnvironment.environment
@onready var key_light: DirectionalLight3D = $KeyLight
@onready var fill_light: OmniLight3D = $FillLight


func _on_world_lighting_toggle_requested() -> void:
	world_lighting_enabled = not world_lighting_enabled
	key_light.visible = world_lighting_enabled
	fill_light.visible = world_lighting_enabled
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR if world_lighting_enabled else Environment.AMBIENT_SOURCE_DISABLED
