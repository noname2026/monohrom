extends Control

@onready var screen_material: ShaderMaterial = $Monochrome/Screen.material
@onready var toggle: CheckButton = $Margin/Layout/Controls/Toggle
@onready var strength_slider: HSlider = $Margin/Layout/Controls/Strength
@onready var strength_label: Label = $Margin/Layout/Controls/Value


func _ready() -> void:
	toggle.toggled.connect(_on_toggle_toggled)
	strength_slider.value_changed.connect(_on_strength_changed)
	_on_strength_changed(strength_slider.value)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_M:
			strength_slider.value = 0.0 if toggle.button_pressed else 1.0
			get_viewport().set_input_as_handled()


func _on_toggle_toggled(enabled: bool) -> void:
	strength_slider.value = 1.0 if enabled else 0.0


func _on_strength_changed(value: float) -> void:
	screen_material.set_shader_parameter("strength", value)
	strength_label.text = "%d %%" % roundi(value * 100.0)
	toggle.set_pressed_no_signal(value > 0.0)
	toggle.text = "Монохром включён" if value > 0.0 else "Исходные цвета"
