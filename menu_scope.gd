extends Control
## Маленький осциллограф в панели состояния реактора.

var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y

	draw_rect(Rect2(Vector2.ZERO, size), Color(0.007, 0.014, 0.011, 0.94))

	var grid := Color(0.24, 0.44, 0.32, 0.16)
	for i in range(1, 6):
		var y := h * float(i) / 6.0
		draw_line(Vector2(0.0, y), Vector2(w, y), grid, 1.0)
	for i in range(1, 8):
		var x := w * float(i) / 8.0
		draw_line(Vector2(x, 0.0), Vector2(x, h), grid, 1.0)

	var points := PackedVector2Array()
	for i in 96:
		var x := w * float(i) / 95.0
		var phase := float(i) * 0.42 + _time * 2.4
		var spike := 1.0 if fmod(_time * 3.0 + float(i) * 0.071, 5.7) < 0.08 else 0.0
		var y := h * 0.5 + sin(phase) * h * 0.11 + sin(phase * 0.31 - _time * 1.2) * h * 0.07
		y -= spike * h * 0.26
		points.append(Vector2(x, clampf(y, 2.0, h - 2.0)))

	draw_polyline(points, Color(0.36, 0.68, 0.48, 0.13), 5.0, true)
	draw_polyline(points, Color(0.58, 0.86, 0.66, 0.62), 1.6, true)

	draw_rect(Rect2(Vector2.ZERO, size), Color(0.38, 0.56, 0.44, 0.34), false, 1.0)
