class_name LockpickDial
extends Control

## Мини-игра взлома пароля: круговой индикатор с движущейся зеленой полоской.
## Пользователь должен вовремя остановить полоску в целевой зоне от 3 до 6 раз.

signal minigame_completed(password: String)
signal step_succeeded(current: int, total: int)
signal step_failed()

@export var radius: float = 130.0
@export var line_width: float = 16.0
@export var rotation_speed: float = 3.6 # радиан в секунду

var is_running: bool = false
var current_angle: float = 0.0
var target_angle: float = 0.0
var target_arc_size: float = deg_to_rad(36.0) # размер зоны попадания ~36 градусов
var needle_arc_size: float = deg_to_rad(14.0) # ширина полоски

var total_steps: int = 4
var current_step: int = 0
var direction: float = 1.0

var flash_color: Color = Color(0, 0, 0, 0)
var flash_timer: float = 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(320, 320)
	set_process(true)


func start_game(p_total_steps: int = -1) -> void:
	if p_total_steps <= 0:
		total_steps = randi_range(3, 6)
	else:
		total_steps = p_total_steps

	current_step = 0
	current_angle = 0.0
	direction = 1.0
	_spawn_new_target()
	is_running = true
	queue_redraw()


func _spawn_new_target() -> void:
	# Случайная позиция зоны попадания на расстоянии от текущей
	var offset := randf_range(deg_to_rad(80.0), deg_to_rad(280.0))
	target_angle = fmod(current_angle + offset, TAU)
	if target_angle < 0:
		target_angle += TAU


func _process(delta: float) -> void:
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0:
			flash_color = Color(0, 0, 0, 0)
		queue_redraw()

	if not is_running:
		return

	current_angle = fmod(current_angle + direction * rotation_speed * delta, TAU)
	if current_angle < 0:
		current_angle += TAU
	queue_redraw()


## Проверка попадания при нажатии
func attempt_stop() -> bool:
	if not is_running:
		return false

	# Разница углов по кратчайшей дуге
	var diff := absf(wrapf(current_angle - target_angle, -PI, PI))
	var hit_threshold := (target_arc_size / 2.0) + (needle_arc_size / 2.0)

	if diff <= hit_threshold:
		# УСПЕХ: Попадание в зону
		current_step += 1
		flash_color = Color(0.0, 1.0, 0.4, 0.35)
		flash_timer = 0.22
		step_succeeded.emit(current_step, total_steps)

		if current_step >= total_steps:
			is_running = false
			queue_redraw()
			minigame_completed.emit(SatanGame.target_password)
			return true
		else:
			# Меняем направление и слегка увеличиваем скорость для азарта
			direction = -direction
			rotation_speed = randf_range(3.4, 4.4)
			_spawn_new_target()
			return true
	else:
		# ПРОМАХ
		flash_color = Color(1.0, 0.2, 0.2, 0.35)
		flash_timer = 0.25
		step_failed.emit()
		return false


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		attempt_stop()
	elif event is InputEventScreenTouch and event.pressed:
		attempt_stop()


func _draw() -> void:
	var center := size / 2.0

	# Вспышка успеха/ошибки
	if flash_color.a > 0:
		draw_circle(center, radius + 24.0, flash_color)

	# Фоновый круг (толстый контур без заливки)
	draw_arc(center, radius, 0, TAU, 64, Color(0.18, 0.18, 0.18, 1.0), line_width, true)

	# Внутренний декоративный тонкий контур
	draw_arc(center, radius - line_width / 2.0 - 6.0, 0, TAU, 64, Color(0.28, 0.28, 0.28, 0.5), 1.5, true)
	draw_arc(center, radius + line_width / 2.0 + 6.0, 0, TAU, 64, Color(0.28, 0.28, 0.28, 0.5), 1.5, true)

	if is_running or current_step < total_steps:
		# Целевая зона (куда нужно попасть)
		var t_start := target_angle - target_arc_size / 2.0
		var t_end := target_angle + target_arc_size / 2.0
		draw_arc(center, radius, t_start, t_end, 32, Color(0.9, 0.7, 0.2, 0.85), line_width + 4.0, true)

		# Зеленая движущаяся полоска
		var n_start := current_angle - needle_arc_size / 2.0
		var n_end := current_angle + needle_arc_size / 2.0
		draw_arc(center, radius, n_start, n_end, 16, Color(0.0, 1.0, 0.45, 1.0), line_width + 6.0, true)
	else:
		# Финал: весь круг загорается зеленым
		draw_arc(center, radius, 0, TAU, 64, Color(0.0, 1.0, 0.45, 1.0), line_width + 2.0, true)
