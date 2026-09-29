extends Control

## Сцена активации приложения SATAN.
## Плавное появление инструкции, кнопки перехода в Telegram-бота,
## отображение Device ID, ввод и валидация персонального ключа устройства.

@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var header_label: Label = $SafeArea/MarginContainer/VBoxContainer/HeaderLabel
@onready var instruction_label: Label = $SafeArea/MarginContainer/VBoxContainer/InstructionLabel
@onready var tg_bot_button: Button = $SafeArea/MarginContainer/VBoxContainer/TgBotButton
@onready var device_container: PanelContainer = $SafeArea/MarginContainer/VBoxContainer/DeviceContainer
@onready var device_id_label: Label = $SafeArea/MarginContainer/VBoxContainer/DeviceContainer/Margin/VBox/DeviceIDLabel
@onready var copy_id_button: Button = $SafeArea/MarginContainer/VBoxContainer/DeviceContainer/Margin/VBox/CopyIDButton
@onready var input_container: PanelContainer = $SafeArea/MarginContainer/VBoxContainer/InputContainer
@onready var key_edit: LineEdit = $SafeArea/MarginContainer/VBoxContainer/InputContainer/Margin/VBox/KeyEdit
@onready var paste_button: Button = $SafeArea/MarginContainer/VBoxContainer/InputContainer/Margin/VBox/ButtonsHBox/PasteButton
@onready var activate_button: Button = $SafeArea/MarginContainer/VBoxContainer/InputContainer/Margin/VBox/ButtonsHBox/ActivateButton
@onready var status_label: Label = $SafeArea/MarginContainer/VBoxContainer/StatusLabel


func _ready() -> void:
	# Инициализация текста устройства
	device_id_label.text = SatanLicense.device_id
	status_label.text = ""

	# Начальная невидимость элементов для плавного появления
	fade_overlay.color = Color(0, 0, 0, 1)
	header_label.modulate.a = 0.0
	instruction_label.modulate.a = 0.0
	tg_bot_button.modulate.a = 0.0
	device_container.modulate.a = 0.0
	input_container.modulate.a = 0.0

	# Сигналы кнопок
	tg_bot_button.pressed.connect(_on_tg_bot_button_pressed)
	copy_id_button.pressed.connect(_on_copy_id_button_pressed)
	paste_button.pressed.connect(_on_paste_button_pressed)
	activate_button.pressed.connect(_on_activate_button_pressed)
	key_edit.text_submitted.connect(func(_text): _on_activate_button_pressed())

	_start_intro_animation()


func _start_intro_animation() -> void:
	var tween := create_tween()

	# Плавное растворение черного экрана перехода
	tween.tween_property(fade_overlay, "color:a", 0.0, 0.5)

	# 1. Появление заголовка SATAN
	tween.tween_property(header_label, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# 2. Плавное появление надписи "Для активации приложения перейдите в тг бота"
	tween.tween_property(instruction_label, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# 3. Ниже плавно появляется кнопка перехода в бота
	tween.tween_property(tg_bot_button, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# 4. Появление блока с Device ID и полем ввода ключа
	tween.tween_property(device_container, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(input_container, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_QUAD)


func _on_tg_bot_button_pressed() -> void:
	# Копируем ID в буфер обмена для удобства
	DisplayServer.clipboard_set(SatanLicense.device_id)
	status_label.text = "✓ Device ID скопирован. Открываем бота..."
	status_label.modulate = Color(0.8, 0.8, 0.8, 1.0)
	SatanLicense.open_bot()


func _on_copy_id_button_pressed() -> void:
	DisplayServer.clipboard_set(SatanLicense.device_id)
	copy_id_button.text = "СКОПИРОВАНО! ✓"
	var t := create_tween()
	t.tween_interval(2.0)
	t.tween_callback(func(): copy_id_button.text = "СКОПИРОВАТЬ ID")


func _on_paste_button_pressed() -> void:
	var text_from_clipboard := DisplayServer.clipboard_get().strip_edges()
	if not text_from_clipboard.is_empty():
		key_edit.text = text_from_clipboard
		status_label.text = "Ключ вставлен из буфера."
		status_label.modulate = Color(0.8, 0.8, 0.8, 1.0)
	else:
		status_label.text = "Буфер обмена пуст."
		status_label.modulate = Color(0.7, 0.7, 0.7, 1.0)


func _on_activate_button_pressed() -> void:
	var key_text := key_edit.text.strip_edges()
	if key_text.is_empty():
		_show_error("Пожалуйста, введите или вставьте ключ!")
		return

	var result := SatanLicense.activate(key_text)
	if result["success"]:
		_show_success()
	else:
		_show_error(result["error"])


func _show_error(msg: String) -> void:
	status_label.text = "❌ " + msg
	status_label.modulate = Color(1.0, 0.35, 0.35, 1.0) # Красный акцент ошибки

	# Эффект легкого потряхивания поля ввода при ошибке
	var original_x := input_container.position.x
	var shake_tween := create_tween()
	for i in range(3):
		shake_tween.tween_property(input_container, "position:x", original_x - 10, 0.04)
		shake_tween.tween_property(input_container, "position:x", original_x + 10, 0.04)
	shake_tween.tween_property(input_container, "position:x", original_x, 0.04)


func _show_success() -> void:
	status_label.text = "✓ Ключ подтвержден! Запуск приложения..."
	status_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	activate_button.disabled = true
	key_edit.editable = false

	# Плавное затемнение и переход на основную сцену
	var tween := create_tween()
	tween.tween_interval(0.8)
	tween.tween_property(fade_overlay, "color:a", 1.0, 0.6)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://home.tscn"))
