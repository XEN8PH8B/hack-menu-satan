extends Control

## Загрузочный экран приложения в черно-белом стиле.
## Плавное появление надписи "SATAN", прогресс-бара и последующий переход на сцену активации/главную сцену.

@onready var title_label: Label = $SafeArea/CenterContainer/VBoxContainer/TitleLabel
@onready var progress_bar: ProgressBar = $SafeArea/CenterContainer/VBoxContainer/ProgressBar
@onready var status_label: Label = $SafeArea/CenterContainer/VBoxContainer/StatusLabel
@onready var anim_container: VBoxContainer = $SafeArea/CenterContainer/VBoxContainer
@onready var fade_overlay: ColorRect = $FadeOverlay

var target_scene: String = "res://activation.tscn"


func _ready() -> void:
	# Начальное скрытое состояние
	fade_overlay.color = Color(0, 0, 0, 1)
	title_label.modulate.a = 0.0
	progress_bar.modulate.a = 0.0
	status_label.modulate.a = 0.0
	progress_bar.value = 0.0

	# Проверяем лицензию на старте
	if SatanLicense.check_activation():
		target_scene = "res://home.tscn"
	else:
		target_scene = "res://activation.tscn"

	_start_splash_sequence()


func _start_splash_sequence() -> void:
	var tween := create_tween()

	# 1. Растворение черного оверлея
	tween.tween_property(fade_overlay, "color:a", 0.0, 0.6)

	# 2. Плавное появление названия "SATAN"
	tween.tween_property(title_label, "modulate:a", 1.0, 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# 3. Плавное появление статус-текста и прогресс-бара
	tween.parallel().tween_property(progress_bar, "modulate:a", 1.0, 0.8).set_delay(0.4)
	tween.parallel().tween_property(status_label, "modulate:a", 1.0, 0.8).set_delay(0.4)

	# 4. Анимация заполнения прогресс-бара с обновлением текста
	tween.tween_method(_update_progress, 0.0, 45.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func(): status_label.text = "ПРОВЕРКА ЛИЦЕНЗИИ...")
	tween.tween_method(_update_progress, 45.0, 85.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func(): status_label.text = "СИСТЕМА ГОТОВА")
	tween.tween_method(_update_progress, 85.0, 100.0, 0.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

	# 5. Задержка и плавный переход на следующую сцену
	tween.tween_interval(0.4)
	tween.tween_property(fade_overlay, "color:a", 1.0, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(_change_to_next_scene)


func _update_progress(val: float) -> void:
	progress_bar.value = val


func _change_to_next_scene() -> void:
	get_tree().change_scene_to_file(target_scene)
