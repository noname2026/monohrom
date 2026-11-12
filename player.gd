extends CharacterBody3D

signal world_lighting_toggle_requested

@onready var camera: Camera3D = $Camera3D
@onready var spawn_transform: Transform3D = transform
@onready var spawn_pitch: float = camera.rotation.x
@onready var screen_material: ShaderMaterial = $Monochrome/Screen.material
@onready var toggle: CheckButton = $HUD/Top/Layout/Controls/Toggle
@onready var strength_slider: HSlider = $HUD/Top/Layout/Controls/Strength
@onready var strength_label: Label = $HUD/Top/Layout/Controls/Value
@onready var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	toggle.toggled.connect(_on_toggle_toggled)
	strength_slider.value_changed.connect(_on_strength_changed)
	_on_strength_changed(strength_slider.value)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.is_physical_key_pressed(KEY_SHIFT) else Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	var movement := Vector2.ZERO
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		movement = Vector2(
			float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
			float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
		).normalized()
	var direction := basis * Vector3(movement.x, 0.0, movement.y)
	velocity.x = direction.x * 4.0
	velocity.z = direction.z * 4.0
	if not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.physical_keycode == KEY_SHIFT and not event.echo:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if event.pressed else Input.MOUSE_MODE_CAPTURED
		if not event.pressed:
			get_viewport().gui_release_focus()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.screen_relative.x * 0.0025)
		camera.rotation.x = clampf(camera.rotation.x - event.screen_relative.y * 0.0025, -1.35, 1.35)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not Input.is_physical_key_pressed(KEY_SHIFT):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_M:
			strength_slider.value = 0.0 if toggle.button_pressed else 1.0
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_G:
			world_lighting_toggle_requested.emit()
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_R:
			transform = spawn_transform
			velocity = Vector3.ZERO
			camera.rotation.x = spawn_pitch
			get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_toggle_toggled(enabled: bool) -> void:
	strength_slider.value = 1.0 if enabled else 0.0


func _on_strength_changed(value: float) -> void:
	screen_material.set_shader_parameter("strength", value)
	strength_label.text = "%d %%" % roundi(value * 100.0)
	toggle.set_pressed_no_signal(value > 0.0)
	toggle.text = "Монохром включён" if value > 0.0 else "Исходные цвета"
