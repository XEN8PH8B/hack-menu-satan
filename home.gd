extends Control

## Главный экран приложения после успешной активации (пока пустая/базовая сцена).
## Содержит статус устройства и возможность сброса активации для тестирования.

@onready var device_id_label: Label = $SafeArea/MarginContainer/VBoxContainer/DeviceCard/Margin/VBox/DeviceIDLabel
@onready var reset_button: Button = $SafeArea/MarginContainer/VBoxContainer/ResetButton
@onready var fade_overlay: ColorRect = $FadeOverlay


func _ready() -> void:
	device_id_label.text = SatanLicense.device_id
	reset_button.pressed.connect(_on_reset_pressed)

	fade_overlay.color = Color(0, 0, 0, 1)
	var tween := create_tween()
	tween.tween_property(fade_overlay, "color:a", 0.0, 0.5)


func _on_reset_pressed() -> void:
	# Сброс для тестирования
	SatanLicense.deactivate()
	var tween := create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, 0.4)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://activation.tscn"))
