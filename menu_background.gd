extends Control
## Процедурный фон главного меню: аварийный машинный зал энергоблока.
## Ни одного внешнего ассета — всё рисуется кодом, поэтому фон легко менять.

const ACCENT := Color(0.72, 0.19, 0.16, 1.0)
const BONE := Color(0.82, 0.84, 0.78, 1.0)

var _time := 0.0
var _flicker := 1.0
var _dust: Array[Vector2] = []
var _dust_speed: Array[float] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.seed = 730417
	for i in 80:
		_dust.append(Vector2(_rng.randf(), _rng.randf()))
		_dust_speed.append(_rng.randf_range(0.004, 0.018))


func _process(delta: float) -> void:
	_time += delta
	_flicker = 0.88 + 0.06 * sin(_time * 11.0) + 0.04 * sin(_time * 37.0)
	if fmod(_time, 9.7) < 0.18:
		_flicker *= 0.30

	for i in _dust.size():
		var p := _dust[i]
		p.y -= _dust_speed[i] * delta
		p.x += sin(_time * 0.22 + float(i)) * 0.00008
		if p.y < -0.02:
			p.y = 1.02
		if p.x < -0.02:
			p.x = 1.02
		elif p.x > 1.02:
			p.x = -0.02
		_dust[i] = p

	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var s := minf(w / 1920.0, h / 1080.0)

	_draw_gradient(w, h)
	_draw_hall(w, h)
	_draw_reactor(w, h, s)
	_draw_lamp(w, h, s)
	_draw_dust(w, h, s)
	_draw_console(w, h, s)
	_draw_grain(w, h, s)


func _draw_gradient(w: float, h: float) -> void:
	var top := Color(0.030, 0.038, 0.036)
	var bottom := Color(0.078, 0.086, 0.081)
	for i in 64:
		var k := float(i) / 63.0
		draw_rect(Rect2(0.0, h * k, w, h / 64.0 + 1.0), top.lerp(bottom, k))

	# Мертвенный отсвет лампы в верхней части зала.
	for i in 7:
		draw_circle(
			Vector2(w * 0.40, h * 0.09),
			(120.0 + i * 90.0) * (w / 1920.0),
			Color(0.72, 0.80, 0.72, 0.010)
		)


func _draw_hall(w: float, h: float) -> void:
	var vp := Vector2(w * 0.55, h * 0.57)
	var line_color := Color(0.58, 0.63, 0.58, 0.075)

	# Перспектива коридора.
	draw_line(Vector2(0.0, 0.0), vp, line_color, 1.0)
	draw_line(Vector2(w, 0.0), vp, line_color, 1.0)
	draw_line(Vector2(0.0, h), vp, line_color, 1.0)
	draw_line(Vector2(w, h), vp, line_color, 1.0)

	# Плиты пола, уходящие в глубину.
	for i in 10:
		var k := pow(float(i) / 9.0, 1.75)
		var y := lerpf(vp.y, h * 1.08, k)
		var half := lerpf(0.0, w * 0.78, k)
		draw_line(
			Vector2(vp.x - half, y),
			Vector2(vp.x + half, y),
			Color(0.58, 0.63, 0.58, 0.050),
			1.0
		)
	for i in 9:
		var x := lerpf(vp.x - w * 0.78, vp.x + w * 0.78, float(i) / 8.0)
		draw_line(vp, Vector2(x, h * 1.08), Color(0.58, 0.63, 0.58, 0.045), 1.0)

	# Лампы на потолке, уходящие к дальней стене.
	for i in 6:
		var k := pow(float(i) / 6.0, 1.4)
		var y := lerpf(h * 0.06, vp.y - h * 0.10, k)
		var half := lerpf(w * 0.13, w * 0.018, k)
		var alpha := lerpf(0.16, 0.040, k) * _flicker
		draw_rect(
			Rect2(vp.x - half, y, half * 2.0, maxf(2.0, h * 0.009 * (1.0 - k * 0.7))),
			Color(0.78, 0.83, 0.76, alpha)
		)

	# Бетонные опоры.
	for i in 3:
		var x := lerpf(w * 0.06, w * 0.40, float(i) / 2.0)
		draw_rect(
			Rect2(x, h * 0.20, w * 0.018, h * 0.60),
			Color(0.042, 0.049, 0.046, 0.65)
		)
		draw_line(
			Vector2(x, h * 0.20),
			Vector2(x, h * 0.80),
			Color(0.50, 0.55, 0.50, 0.14),
			1.0
		)


func _draw_reactor(w: float, h: float, s: float) -> void:
	var cx := w * 0.80
	var top := h * 0.21
	var bottom := h * 0.91
	var half := w * 0.105
	var body := Color(0.050, 0.058, 0.055)
	var rim := Color(0.48, 0.54, 0.49, 0.32)

	# Корпус реактора.
	draw_rect(Rect2(cx - half, top + half * 0.55, half * 2.0, bottom - top - half * 0.55), body)
	draw_circle(Vector2(cx, top + half * 0.55), half, body, true)
	draw_rect(Rect2(cx - half, top + half * 0.55, half * 2.0, h * 0.012), Color(0.075, 0.085, 0.078, 0.9))

	# Римлайт слева.
	draw_arc(
		Vector2(cx, top + half * 0.55),
		half,
		PI * 0.52,
		PI * 1.30,
		28,
		rim,
		2.0
	)
	draw_line(
		Vector2(cx - half, top + half * 0.55),
		Vector2(cx - half, bottom),
		rim,
		1.5
	)

	# Сварные швы и кольца.
	for i in 6:
		var y := lerpf(top + half, bottom, float(i) / 5.0)
		draw_line(
			Vector2(cx - half, y),
			Vector2(cx + half, y),
			Color(0.52, 0.58, 0.52, 0.15),
			1.0
		)
	for i in 5:
		var x := cx - half + half * 2.0 * float(i) / 4.0
		draw_line(
			Vector2(x, top + half * 0.55),
			Vector2(x, bottom),
			Color(0.52, 0.58, 0.52, 0.06),
			1.0
		)

	# Тусклый знак радиации на корпусе.
	_draw_trefoil(Vector2(cx, h * 0.55), 86.0 * s, Color(0.78, 0.82, 0.75, 0.10))

	# Аварийный маяк на крышке реактора.
	var pulse := 0.45 + 0.55 * (0.5 + 0.5 * sin(_time * 1.6))
	for i in 5:
		draw_circle(
			Vector2(cx, top + half * 0.42),
			(24.0 + i * 22.0) * s,
			Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.012 * (1.0 - float(i) / 5.0) * pulse)
		)
	draw_circle(
		Vector2(cx, top + half * 0.42),
		7.0 * s,
		Color(0.92, 0.24, 0.19, 0.65 * pulse)
	)

	# Трубы под потолком.
	var pipe := Color(0.085, 0.096, 0.090, 0.95)
	var pipe_light := Color(0.50, 0.55, 0.50, 0.24)
	var path := PackedVector2Array([
		Vector2(w * 0.99, h * 0.10),
		Vector2(w * 0.90, h * 0.11),
		Vector2(w * 0.86, h * 0.17),
		Vector2(w * 0.86, h * 0.25),
	])
	draw_polyline(path, pipe, 18.0 * s, true)
	var highlight := PackedVector2Array()
	for point in path:
		highlight.append(point + Vector2(-5.0 * s, -5.0 * s))
	draw_polyline(highlight, pipe_light, 2.0 * s, true)

	var pipe2 := PackedVector2Array([
		Vector2(w * 0.99, h * 0.16),
		Vector2(w * 0.93, h * 0.17),
		Vector2(w * 0.91, h * 0.22),
		Vector2(w * 0.91, h * 0.31),
	])
	draw_polyline(pipe2, pipe, 11.0 * s, true)

	# Фланцы.
	for point in [Vector2(w * 0.90, h * 0.11), Vector2(w * 0.86, h * 0.20)]:
		draw_rect(
			Rect2(point - Vector2(12.0, 4.0) * s, Vector2(24.0, 8.0) * s),
			Color(0.13, 0.14, 0.13, 1.0)
		)


func _draw_trefoil(center: Vector2, radius: float, color: Color) -> void:
	draw_circle(center, radius * 0.22, color)
	for i in 3:
		var base := -PI * 0.5 + TAU * float(i) / 3.0
		var points := PackedVector2Array()
		for j in 13:
			var angle := base - deg_to_rad(30.0) + deg_to_rad(60.0) * float(j) / 12.0
			points.append(center + Vector2(cos(angle), sin(angle)) * radius)
		for j in 13:
			var angle := base + deg_to_rad(30.0) - deg_to_rad(60.0) * float(j) / 12.0
			points.append(center + Vector2(cos(angle), sin(angle)) * radius * 0.22)
		draw_colored_polygon(points, color)


func _draw_lamp(w: float, h: float, s: float) -> void:
	var lamp := Vector2(w * 0.40, h * 0.055)
	var glow := Color(0.86, 0.91, 0.83, 0.07 * _flicker)

	# Пыльный конус света.
	for i in 8:
		var k := float(i) / 7.0
		var spread := lerpf(0.045, 0.34, k) * w
		var alpha := 0.024 * _flicker * (1.0 - k * 0.30)
		var points := PackedVector2Array([
			Vector2(lamp.x - 18.0 * s, lamp.y + 10.0 * s),
			Vector2(lamp.x + 18.0 * s, lamp.y + 10.0 * s),
			Vector2(lamp.x + spread, h * 1.06),
			Vector2(lamp.x - spread, h * 1.06),
		])
		draw_colored_polygon(points, Color(0.80, 0.86, 0.79, alpha))

	# Пятно на полу.
	var pool := PackedVector2Array()
	for i in 36:
		var angle := TAU * float(i) / 36.0
		pool.append(Vector2(
			lamp.x + cos(angle) * 300.0 * s,
			h * 0.97 + sin(angle) * 52.0 * s
		))
	draw_colored_polygon(pool, Color(0.80, 0.86, 0.79, 0.050 * _flicker))

	# Арматура и сама лампа.
	draw_line(Vector2(lamp.x, 0.0), Vector2(lamp.x, lamp.y - 8.0 * s), Color(0.10, 0.11, 0.10, 1.0), 3.0 * s)
	draw_rect(
		Rect2(lamp.x - 52.0 * s, lamp.y - 6.0 * s, 104.0 * s, 9.0 * s),
		Color(0.10, 0.11, 0.10, 1.0)
	)
	draw_circle(lamp, 40.0 * s, glow)
	draw_circle(lamp, 13.0 * s, Color(0.95, 0.97, 0.88, 0.75 * _flicker))


func _draw_dust(w: float, h: float, s: float) -> void:
	var lamp_x := w * 0.40
	for i in _dust.size():
		var p := _dust[i]
		var px := p.x * w
		var py := p.y * h
		var spread := lerpf(0.035, 0.34, p.y) * w
		var distance := absf(px - lamp_x)
		if distance < spread:
			var alpha := 0.20 * _flicker * (1.0 - distance / spread) * (1.0 - p.y * 0.45)
			draw_circle(Vector2(px, py), 1.4 * s, Color(0.86, 0.89, 0.82, alpha))
		elif i % 6 == 0:
			draw_circle(Vector2(px, py), 1.0 * s, Color(0.70, 0.74, 0.68, 0.07))


func _draw_console(w: float, h: float, s: float) -> void:
	var deck := h * 0.795

	# Корпус пульта.
	draw_rect(Rect2(0.0, deck, w, h - deck), Color(0.022, 0.028, 0.026, 0.97))
	draw_line(
		Vector2(0.0, deck),
		Vector2(w, deck),
		Color(0.50, 0.55, 0.50, 0.40),
		1.5
	)
	draw_line(
		Vector2(0.0, deck + 5.0 * s),
		Vector2(w, deck + 5.0 * s),
		Color(0.30, 0.34, 0.31, 0.28),
		1.0
	)

	# Панельные швы.
	for i in 9:
		var x := w * float(i) / 8.0
		draw_line(
			Vector2(x, deck + 8.0 * s),
			Vector2(x, h),
			Color(0.45, 0.50, 0.46, 0.14),
			1.0
		)

	# Ряды мелких индикаторов.
	for i in 46:
		var x := w * (0.03 + 0.94 * float(i) / 45.0)
		var y := deck + (18.0 + float(i % 5) * 12.0) * s
		var is_on := fmod(_time * 1.3 + float(i) * 0.37, 7.3) < 2.1
		var color := Color(0.76, 0.84, 0.74, 0.55) if is_on else Color(0.24, 0.28, 0.25, 0.50)
		draw_rect(Rect2(x, y, 4.5 * s, 4.5 * s), color)

	# Аварийные красные индикаторы.
	for i in 7:
		var x := w * (0.10 + 0.11 * float(i))
		var pulse := 0.45 + 0.55 * maxf(0.0, sin(_time * 2.2 + float(i) * 0.9))
		draw_rect(Rect2(x, deck + 52.0 * s, 5.0 * s, 5.0 * s), Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.85 * pulse))

	# Тумблеры и кнопки.
	for i in 18:
		var x := w * (0.055 + 0.027 * float(i))
		var y := deck + (86.0 + float(i % 3) * 13.0) * s
		draw_rect(Rect2(x, y, 9.0 * s, 5.0 * s), Color(0.22, 0.25, 0.23, 0.9))
		if i % 4 == 0:
			draw_rect(Rect2(x + 1.0 * s, y + 1.0 * s, 3.0 * s, 3.0 * s), Color(0.62, 0.67, 0.62, 0.65))

	# Приборы.
	for i in 3:
		_draw_gauge(Vector2(w * (0.565 + 0.072 * float(i)), h * 0.875), 38.0 * s, i)


func _draw_gauge(center: Vector2, radius: float, index: int) -> void:
	draw_circle(center, radius, Color(0.008, 0.014, 0.012, 0.96))
	draw_arc(
		center,
		radius,
		PI * 0.75,
		PI * 2.25,
		28,
		Color(0.50, 0.55, 0.50, 0.42),
		1.2
	)
	for i in 9:
		var angle := lerpf(PI * 0.75, PI * 2.25, float(i) / 8.0)
		var inner := center + Vector2(cos(angle), sin(angle)) * radius * 0.76
		var outer := center + Vector2(cos(angle), sin(angle)) * radius * 0.92
		draw_line(inner, outer, Color(0.55, 0.60, 0.54, 0.38), 1.0)

	var needle := lerpf(PI * 0.86, PI * 2.14, 0.38 + 0.14 * sin(_time * (0.8 + index * 0.23) + index))
	draw_line(
		center,
		center + Vector2(cos(needle), sin(needle)) * radius * 0.70,
		Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.8),
		1.6
	)
	draw_circle(center, 3.0 * radius / 38.0, Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.8))


func _draw_grain(w: float, h: float, s: float) -> void:
	for i in 120:
		var point := Vector2(_rng.randf() * w, _rng.randf() * h)
		var alpha := _rng.randf_range(0.010, 0.038)
		draw_rect(Rect2(point, Vector2(1.5, 1.5) * s), Color(0.85, 0.88, 0.82, alpha))
