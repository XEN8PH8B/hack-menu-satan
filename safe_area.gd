@tool
class_name SafeArea
extends MarginContainer

## MarginContainer, автоматически адаптирующий отступы (margins)
## под вырез экрана (Notch / Dynamic Island) и полосу Home (Home Indicator)
## на iOS (включая iPhone 12 Pro) и Android.

@export_group("Safe Area Settings")
## Применять отступ сверху (под вырез/чёлку и строку состояния)
@export var apply_top: bool = true:
	set(val):
		apply_top = val
		update_margins()

## Применять отступ снизу (под индикатор Home)
@export var apply_bottom: bool = true:
	set(val):
		apply_bottom = val
		update_margins()

## Применять отступ слева (для альбомной ориентации)
@export var apply_left: bool = true:
	set(val):
		apply_left = val
		update_margins()

## Применять отступ справа (для альбомной ориентации)
@export var apply_right: bool = true:
	set(val):
		apply_right = val
		update_margins()

@export_group("Desktop Simulation (iPhone 12 Pro)")
## Симулировать отступы iPhone 12 Pro на ПК и в редакторе Godot
@export var simulate_on_desktop: bool = true:
	set(val):
		simulate_on_desktop = val
		update_margins()

## Симулируемый отступ сверху для iPhone 12 Pro (47 pt * 3 = 141 px при 1170x2532)
@export var mock_top: int = 141:
	set(val):
		mock_top = val
		update_margins()

## Симулируемый отступ снизу для iPhone 12 Pro (34 pt * 3 = 102 px при 1170x2532)
@export var mock_bottom: int = 102:
	set(val):
		mock_bottom = val
		update_margins()

## Симулируемый отступ слева
@export var mock_left: int = 0:
	set(val):
		mock_left = val
		update_margins()

## Симулируемый отступ справа
@export var mock_right: int = 0:
	set(val):
		mock_right = val
		update_margins()


func _ready() -> void:
	# Подписываемся на изменение размера окна/ориентации
	var vp := get_viewport()
	if vp:
		if not vp.size_changed.is_connected(update_margins):
			vp.size_changed.connect(update_margins)
	update_margins()


func update_margins() -> void:
	if not is_inside_tree():
		return

	var is_mobile := OS.has_feature("mobile") or OS.has_feature("ios") or OS.has_feature("android")
	var safe_area := DisplayServer.get_display_safe_area()
	var screen_size := DisplayServer.screen_get_size()

	# Проверяем, вернула ли система реальный safe area (на мобильных устройствах)
	var has_real_safe_area: bool = (
		is_mobile
		and safe_area.size.x > 0
		and safe_area.size.y > 0
		and (safe_area.position != Vector2i.ZERO or safe_area.size != screen_size)
	)

	var m_top := 0
	var m_bottom := 0
	var m_left := 0
	var m_right := 0

	if has_real_safe_area:
		# Переводим координаты экрана в координаты Viewport с учётом масштабирования
		var vp := get_viewport()
		if vp:
			var final_xform := vp.get_final_transform()
			var det := final_xform.determinant()
			if not is_zero_approx(det):
				var xform: Transform2D = final_xform.affine_inverse()
				var safe_top_left := xform * Vector2(safe_area.position)
				var safe_bottom_right := xform * Vector2(safe_area.end)
				var vp_rect := vp.get_visible_rect()

				m_top = maxi(0, int(round(safe_top_left.y - vp_rect.position.y)))
				m_bottom = maxi(0, int(round(vp_rect.end.y - safe_bottom_right.y)))
				m_left = maxi(0, int(round(safe_top_left.x - vp_rect.position.x)))
				m_right = maxi(0, int(round(vp_rect.end.x - safe_bottom_right.x)))
			else:
				m_top = mock_top
				m_bottom = mock_bottom
	elif simulate_on_desktop:
		# Режим симуляции для тестирования интерфейса на ПК / в редакторе
		m_top = mock_top
		m_bottom = mock_bottom
		m_left = mock_left
		m_right = mock_right

	add_theme_constant_override("margin_top", m_top if apply_top else 0)
	add_theme_constant_override("margin_bottom", m_bottom if apply_bottom else 0)
	add_theme_constant_override("margin_left", m_left if apply_left else 0)
	add_theme_constant_override("margin_right", m_right if apply_right else 0)
