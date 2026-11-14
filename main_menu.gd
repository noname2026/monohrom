extends Control
## Главное меню «МОНОХРОМ»: терминал смены четвёртого энергоблока.

const CFG = preload("res://game_settings.gd")

const BOOT_TEXT := """[color=#7f8c80]ОБЪЕКТ 07  //  ТЕРМИНАЛ СМЕНЫ 04[/color]
КАНАЛ СВЯЗИ 1... [color=#7f8c80]ОК[/color]
КАНАЛ СВЯЗИ 2... [color=#7f8c80]ОК[/color]
КАНАЛ СВЯЗИ 3... [color=#b3453b]СИГНАЛ ИЗВНЕ[/color]
ТЕПЛОНОСИТЕЛЬ: 297.4 C
ДАВЛЕНИЕ: 15.9 МПа
ПЕРСОНАЛ НА ОБЪЕКТЕ: [color=#b3453b]1[/color]

[color=#d9d6cc]СМЕНА НАЧАТА. НЕ ОТКРЫВАЙТЕ ШЛЮЗ 4.[/color]"""

@onready var title: RichTextLabel = $Interface/Left/Title
@onready var clock_label: Label = $Interface/Left/Clock
@onready var status_dot: ColorRect = $Interface/Left/StatusRow/StatusDot
@onready var rec_dot: ColorRect = $Interface/TopRight/RecDot
@onready var temperature_value: Label = $Interface/RightPanel/Content/Readouts/TemperatureValue
@onready var radiation_value: Label = $Interface/RightPanel/Content/Readouts/RadiationValue

@onready var start_button: Button = $Interface/Left/Menu/StartButton
@onready var settings_button: Button = $Interface/Left/Menu/SettingsButton
@onready var archive_button: Button = $Interface/Left/Menu/ArchiveButton
@onready var quit_button: Button = $Interface/Left/Menu/QuitButton

@onready var settings_panel: Control = $SettingsPanel
@onready var mono_slider: HSlider = $SettingsPanel/Center/Panel/Content/Grid/MonoSlider
@onready var mono_value: Label = $SettingsPanel/Center/Panel/Content/Grid/MonoValue
@onready var volume_slider: HSlider = $SettingsPanel/Center/Panel/Content/Grid/VolumeSlider
@onready var volume_value: Label = $SettingsPanel/Center/Panel/Content/Grid/VolumeValue
@onready var sensitivity_slider: HSlider = $SettingsPanel/Center/Panel/Content/Grid/SensitivitySlider
@onready var sensitivity_value: Label = $SettingsPanel/Center/Panel/Content/Grid/SensitivityValue
@onready var fullscreen_check: CheckButton = $SettingsPanel/Center/Panel/Content/FullscreenCheck
@onready var crt_check: CheckButton = $SettingsPanel/Center/Panel/Content/CrtCheck
@onready var defaults_button: Button = $SettingsPanel/Center/Panel/Content/Buttons/DefaultsButton
@onready var close_settings_button: Button = $SettingsPanel/Center/Panel/Content/Buttons/CloseSettingsButton

@onready var archive_panel: Control = $ArchivePanel
@onready var close_archive_button: Button = $ArchivePanel/Center/Panel/Content/CloseArchiveButton

@onready var boot_overlay: Control = $BootOverlay
@onready var boot_log: RichTextLabel = $BootOverlay/Margin/Content/Log
@onready var boot_hint: Label = $BootOverlay/Margin/Content/Hint
@onready var fade_overlay: Control = $FadeOverlay
@onready var fade_label: Label = $FadeOverlay/FadeLabel

@onready var ambient_player: AudioStreamPlayer = $AmbientPlayer
@onready var click_player: AudioStreamPlayer = $ClickPlayer
@onready var crt_overlay: ColorRect = $CRT/Overlay

var _crt_material: ShaderMaterial
var _save_timer: Timer
var _rng := RandomNumberGenerator.new()

var _time := 0.0
var _clock_seconds := 3 * 3600 + 47 * 60 + 12
var _clock_accum := 0.0
var _temperature := 297.4
var _radiation := 3.58

var _boot_active := false
var _boot_closing := false
var _boot_progress := 0.0
var _boot_total := 1
var _boot_hold := 0.0

var _transitioning := false
var _last_focus: Control


func _ready() -> void:
	_rng.randomize()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.wait_time = 0.35
	_save_timer.timeout.connect(_save_settings)
	add_child(_save_timer)

	_crt_material = crt_overlay.material as ShaderMaterial
	_load_settings()
	_bind_buttons()
	_build_audio()
	_start_boot()
	_update_clock()


func _process(delta: float) -> void:
	_time += delta

	rec_dot.modulate.a = 0.30 + 0.70 * (0.5 + 0.5 * sin(_time * 4.2))
	title.modulate.a = 0.94 + 0.06 * sin(_time * 1.7)
	status_dot.modulate.a = 0.65 + 0.35 * (0.5 + 0.5 * sin(_time * 1.9))

	if _boot_active:
		if _boot_total <= 1:
			_boot_total = maxi(boot_log.get_total_character_count(), 1)
		_boot_progress += delta * 115.0
		boot_log.visible_characters = int(_boot_progress)
		if _boot_progress >= float(_boot_total):
			boot_hint.modulate.a = minf(boot_hint.modulate.a + delta * 2.0, 0.65)
			_boot_hold += delta
			if _boot_hold >= 2.2:
				_finish_boot()

	_clock_accum += delta
	if _clock_accum >= 1.0:
		_clock_accum -= 1.0
		_tick_telemetry()


func _input(event: InputEvent) -> void:
	if not _boot_active or _boot_closing:
		return

	var skipping := false
	if event is InputEventKey and event.pressed and not event.echo:
		skipping = true
	elif event is InputEventMouseButton and event.pressed:
		skipping = true

	if skipping:
		_boot_progress = float(_boot_total)
		_finish_boot()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if settings_panel.visible or archive_panel.visible:
			_close_panels()
			get_viewport().set_input_as_handled()


func _start_boot() -> void:
	boot_overlay.visible = true
	boot_overlay.modulate.a = 1.0
	boot_log.text = BOOT_TEXT
	boot_log.visible_characters = 0
	_boot_total = maxi(boot_log.get_total_character_count(), 1)
	_boot_progress = 0.0
	_boot_hold = 0.0
	boot_hint.modulate.a = 0.0
	boot_hint.text = "НАЖМИТЕ ЛЮБУЮ КЛАВИШУ"
	_boot_active = true
	_boot_closing = false


func _finish_boot() -> void:
	if not _boot_active or _boot_closing:
		return

	_boot_active = false
	_boot_closing = true
	var tween := create_tween()
	tween.tween_property(boot_overlay, "modulate:a", 0.0, 0.45)
	await tween.finished
	boot_overlay.visible = false
	_boot_closing = false
	start_button.grab_focus()


func _bind_buttons() -> void:
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_open_settings)
	archive_button.pressed.connect(_open_archive)
	quit_button.pressed.connect(_on_quit_pressed)
	close_settings_button.pressed.connect(_close_panels)
	close_archive_button.pressed.connect(_close_panels)
	defaults_button.pressed.connect(_reset_settings)

	mono_slider.value_changed.connect(_on_mono_changed)
	volume_slider.value_changed.connect(_on_volume_changed)
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	crt_check.toggled.connect(_on_crt_toggled)

	for button in [
		start_button,
		settings_button,
		archive_button,
		quit_button,
		close_settings_button,
		close_archive_button,
		defaults_button,
	]:
		button.mouse_entered.connect(_on_button_hover)
		button.focus_entered.connect(_on_button_hover)
		button.pressed.connect(_play_click.bind(0.82, -5.0))


func _on_button_hover() -> void:
	if _boot_active:
		return
	_play_click(1.55, -15.0)
	_glitch(0.16)


func _on_start_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	_glitch(0.85)
	fade_label.text = "СМЕНА НАЧИНАЕТСЯ"
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 1.0, 0.9)
	await tween.finished
	get_tree().change_scene_to_file("res://monochrome_room_3d.tscn")


func _on_quit_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	_glitch(1.0)
	fade_label.text = "ЗАПИСЬ ЗАВЕРШЕНА"
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 1.0, 0.7)
	await tween.finished
	get_tree().quit()


func _open_settings() -> void:
	_last_focus = get_viewport().gui_get_focus_owner()
	archive_panel.visible = false
	_show_panel(settings_panel, close_settings_button)


func _open_archive() -> void:
	_last_focus = get_viewport().gui_get_focus_owner()
	settings_panel.visible = false
	_show_panel(archive_panel, close_archive_button)


func _show_panel(panel: Control, focus_target: Control) -> void:
	panel.visible = true
	panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.18)
	focus_target.grab_focus()


func _close_panels() -> void:
	if settings_panel.visible:
		_save_settings()
	settings_panel.visible = false
	archive_panel.visible = false
	if is_instance_valid(_last_focus):
		_last_focus.grab_focus()
	else:
		start_button.grab_focus()


func _load_settings() -> void:
	var config := CFG.load_file()

	mono_slider.set_value_no_signal(clampf(
		float(config.get_value("video", "monochrome_strength", 1.0)), 0.0, 1.0
	))
	volume_slider.set_value_no_signal(clampf(
		float(config.get_value("audio", "master_volume", 0.65)), 0.0, 1.0
	))
	sensitivity_slider.set_value_no_signal(clampf(
		float(config.get_value("controls", "mouse_sensitivity", 1.0)), 0.3, 3.0
	))

	var mode := DisplayServer.window_get_mode()
	var is_fullscreen := (
		mode == DisplayServer.WINDOW_MODE_FULLSCREEN
		or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	)
	fullscreen_check.set_pressed_no_signal(is_fullscreen)

	crt_check.set_pressed_no_signal(bool(config.get_value("video", "crt_enabled", true)))

	mono_value.text = "%d %%" % roundi(mono_slider.value * 100.0)
	volume_value.text = "%d %%" % roundi(volume_slider.value * 100.0)
	sensitivity_value.text = "%.1fx" % sensitivity_slider.value
	_apply_master_volume(volume_slider.value)
	crt_overlay.visible = crt_check.button_pressed


func _save_settings() -> void:
	CFG.set_values("video", {
		"monochrome_strength": mono_slider.value,
		"crt_enabled": crt_check.button_pressed,
		"fullscreen": fullscreen_check.button_pressed,
	})
	CFG.set_values("audio", {
		"master_volume": volume_slider.value,
	})
	CFG.set_values("controls", {
		"mouse_sensitivity": sensitivity_slider.value,
	})


func _reset_settings() -> void:
	mono_slider.set_value_no_signal(1.0)
	volume_slider.set_value_no_signal(0.65)
	sensitivity_slider.set_value_no_signal(1.0)
	crt_check.set_pressed_no_signal(true)
	crt_overlay.visible = true
	mono_value.text = "100 %"
	volume_value.text = "65 %"
	sensitivity_value.text = "1.0x"
	_apply_master_volume(volume_slider.value)
	_glitch(0.4)
	_save_settings()


func _on_mono_changed(value: float) -> void:
	mono_value.text = "%d %%" % roundi(value * 100.0)
	_save_timer.start()


func _on_volume_changed(value: float) -> void:
	volume_value.text = "%d %%" % roundi(value * 100.0)
	_apply_master_volume(value)
	_save_timer.start()


func _on_sensitivity_changed(value: float) -> void:
	sensitivity_value.text = "%.1fx" % value
	_save_timer.start()


func _on_fullscreen_toggled(enabled: bool) -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN if enabled
			else DisplayServer.WINDOW_MODE_WINDOWED
		)
	_save_timer.start()


func _on_crt_toggled(enabled: bool) -> void:
	crt_overlay.visible = enabled
	_save_timer.start()


func _apply_master_volume(value: float) -> void:
	var master := AudioServer.get_bus_index("Master")
	var clamped := clampf(value, 0.0, 1.0)
	AudioServer.set_bus_mute(master, clamped < 0.001)
	AudioServer.set_bus_volume_db(master, linear_to_db(maxf(clamped, 0.001)))


func _tick_telemetry() -> void:
	_clock_seconds += 1
	_update_clock()

	_temperature = clampf(_temperature + _rng.randf_range(-0.25, 0.35), 296.0, 314.0)
	temperature_value.text = "%.1f °C" % _temperature

	_radiation = clampf(_radiation + _rng.randf_range(-0.02, 0.035), 3.30, 4.90)
	radiation_value.text = "%.2f мЗв/ч" % _radiation


func _update_clock() -> void:
	var hours := int(_clock_seconds / 3600.0) % 24
	var minutes := int(_clock_seconds / 60.0) % 60
	var seconds := _clock_seconds % 60
	clock_label.text = "СМЕНА 04  //  %02d:%02d:%02d" % [hours, minutes, seconds]


func _glitch(amount: float) -> void:
	if _crt_material == null:
		return
	var tween := create_tween()
	tween.tween_method(_set_glitch, amount, 0.0, 0.35)


func _set_glitch(value: float) -> void:
	_crt_material.set_shader_parameter("glitch", value)


func _play_click(pitch: float = 1.0, volume_db: float = -6.0) -> void:
	if click_player.stream == null:
		return
	click_player.pitch_scale = pitch
	click_player.volume_db = volume_db
	click_player.play()


# --- Звук -------------------------------------------------------------------

func _build_audio() -> void:
	ambient_player.stream = _create_ambient_stream()
	ambient_player.volume_db = -3.0
	ambient_player.play()

	click_player.stream = _create_click_stream()
	click_player.volume_db = -8.0
	click_player.max_polyphony = 4


func _create_ambient_stream() -> AudioStreamWAV:
	const RATE := 22050
	const SECONDS := 8.0
	var frames := int(RATE * SECONDS)
	var mix := PackedFloat32Array()
	mix.resize(frames)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7404

	# Гул реактора и вентиляции. Частоты кратны длине петли, поэтому она бесшовная.
	for i in frames:
		var t := float(i) / RATE
		var hum := sin(TAU * 50.0 * t) * 0.055
		hum += sin(TAU * 100.0 * t + 0.7) * 0.018
		hum += sin(TAU * 25.0 * t) * 0.025
		hum *= 0.80 + 0.20 * sin(TAU * 0.125 * t)
		hum += rng.randf_range(-1.0, 1.0) * 0.006
		mix[i] = hum

	# Щелчки дозиметра.
	for c in 48:
		var start := int(rng.randf_range(0.10, SECONDS - 0.40) * RATE)
		var length := int(RATE * rng.randf_range(0.004, 0.012))
		var amp := rng.randf_range(0.06, 0.16)
		for j in length:
			if start + j >= frames:
				break
			var env := 1.0 - float(j) / float(length)
			mix[start + j] += rng.randf_range(-1.0, 1.0) * amp * env * env

	# Далёкие удары металла.
	for c in 3:
		var start := int(rng.randf_range(0.60, SECONDS - 1.60) * RATE)
		var length := int(RATE * 1.20)
		var base := rng.randf_range(120.0, 190.0)
		for j in length:
			if start + j >= frames:
				break
			var t := float(j) / RATE
			var env := exp(-t * 3.5)
			var tone := sin(TAU * base * t) * 0.50
			tone += sin(TAU * base * 2.7 * t) * 0.22
			tone += sin(TAU * base * 4.3 * t) * 0.12
			mix[start + j] += tone * env * 0.025

	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in frames:
		data.encode_s16(i * 2, int(clampf(mix[i], -1.0, 1.0) * 32767.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frames
	return stream


func _create_click_stream() -> AudioStreamWAV:
	const RATE := 22050
	var frames := int(RATE * 0.11)
	var mix := PackedFloat32Array()
	mix.resize(frames)
	var rng := RandomNumberGenerator.new()
	rng.seed = 112

	for i in frames:
		var t := float(i) / RATE
		var env := exp(-t * 42.0)
		var body := sin(TAU * 1450.0 * t) * 0.40
		body += sin(TAU * 260.0 * t) * 0.25
		var noise := rng.randf_range(-1.0, 1.0) * 0.30 * exp(-t * 90.0)
		mix[i] = (body + noise) * env * 0.30

	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in frames:
		data.encode_s16(i * 2, int(clampf(mix[i], -1.0, 1.0) * 32767.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	return stream
