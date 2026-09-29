class_name SatanLicense
extends Node

## Менеджер лицензий и привязки к уникальному устройству (Device ID).
## Реализует генерацию ключа, проверку аппаратной привязки,
## сохранение статуса активации и deep-link в Telegram-бота.

const SECRET_SALT := "SATAN_CYBER_666_XENOPHOB_SECRET_SALT_2026"
const LICENSE_PATH := "user://satan_license.json"
const DEVICE_CFG_PATH := "user://satan_device.cfg"
const BOT_BASE_URL := "https://t.me/XenophobBot"

static var device_id: String = "":
	get:
		if device_id.is_empty():
			device_id = _resolve_device_id()
		return device_id

static var is_active: bool = false


## Определение стабильного аппаратного идентификатора устройства
static func _resolve_device_id() -> String:
	var uid := OS.get_unique_id().strip_edges()
	# Если система не вернула аппаратный ID (например, на некоторых платформах)
	if uid.is_empty() or uid == "generic":
		var config := ConfigFile.new()
		if config.load(DEVICE_CFG_PATH) == OK:
			uid = config.get_value("device", "id", "")
		if uid.is_empty():
			# Генерируем постоянный UUID и сохраняем
			var crypto := Crypto.new()
			var bytes := crypto.generate_random_bytes(16)
			uid = bytes.hex_encode().to_upper()
			config.set_value("device", "id", uid)
			config.save(DEVICE_CFG_PATH)
	return uid


## Генерация уникального ключа активации для переданного device_id
static func generate_key(p_device_id: String) -> String:
	var clean_id := p_device_id.strip_edges().to_upper()
	var raw_str := "%s:%s" % [clean_id, SECRET_SALT]
	var hash_hex := raw_str.sha256_text().to_upper()
	return "SATAN-%s-%s-%s-%s" % [
		hash_hex.substr(0, 4),
		hash_hex.substr(4, 4),
		hash_hex.substr(8, 4),
		hash_hex.substr(12, 4)
	]


## Нормализация введенного пользователем ключа (очистка от пробелов)
static func normalize_key(input_key: String) -> String:
	var cleaned := input_key.strip_edges().to_upper()
	cleaned = cleaned.replace(" ", "").replace("\t", "").replace("\n", "").replace("\r", "")
	return cleaned


## Проверка валидности ключа для текущего устройства
static func validate_key(input_key: String) -> bool:
	var expected_key := generate_key(device_id)
	return normalize_key(input_key) == expected_key


## Активация приложения по введенному ключу
static func activate(input_key: String) -> Dictionary:
	if validate_key(input_key):
		is_active = true
		_save_license(normalize_key(input_key))
		return {"success": true, "error": ""}
	else:
		return {
			"success": false,
			"error": "Неверный ключ активации или ключ от другого устройства!"
		}


## Проверка сохраненного файла активации
static func check_activation() -> bool:
	if not FileAccess.file_exists(LICENSE_PATH):
		is_active = false
		return false

	var file := FileAccess.open(LICENSE_PATH, FileAccess.READ)
	if not file:
		is_active = false
		return false

	var json_str := file.get_as_text()
	file.close()

	var test_json = JSON.parse_string(json_str)
	if typeof(test_json) != TYPE_DICTIONARY:
		is_active = false
		return false

	var saved_key: String = test_json.get("key", "")
	var saved_device: String = test_json.get("device_id", "")

	# Ключ должен строго совпадать с текущим устройством
	if saved_device == device_id and validate_key(saved_key):
		is_active = true
		return true

	is_active = false
	return false


## Сохранение лицензии на диск
static func _save_license(p_key: String) -> void:
	var data := {
		"device_id": device_id,
		"key": p_key,
		"activated_at": Time.get_unix_time_from_system()
	}
	var file := FileAccess.open(LICENSE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()


## Сброс лицензии (для отладки/тестирования)
static func deactivate() -> void:
	is_active = false
	if FileAccess.file_exists(LICENSE_PATH):
		DirAccess.remove_absolute(LICENSE_PATH)


## Открытие Telegram-бота с deep-link параметром (передает Device ID)
static func open_bot() -> void:
	var url := "%s?start=%s" % [BOT_BASE_URL, device_id]
	OS.shell_open(url)
