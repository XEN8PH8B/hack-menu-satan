class_name SatanGame
extends RefCounted

## Центральный менеджер данных игры SATAN:
## - Заметки (с закреплением)
## - Игровой баланс и профиль
## - Сессия утилиты взлома (4 стадии: доступ, пароль, баланс, перевод)
## - Уведомления

const NOTES_PATH := "user://satan_notes.json"
const PROFILE_PATH := "user://satan_profile.json"
const SESSION_PATH := "user://satan_session.json"

enum Stage {
	BANK_ACCESS = 0,
	PASSWORD_HACK = 1,
	AUTHORIZED = 2
}

# --- Данные профиля ---
static var balance: int = 0
static var total_earned: int = 0
static var hacks_count: int = 0
static var transactions: Array = []
static var _profile_loaded: bool = false

# --- Данные заметок ---
static var notes: Array = []
static var _notes_loaded: bool = false

# --- Данные текущей сессии утилиты ---
static var session_stage: int = Stage.BANK_ACCESS
static var target_email: String = ""
static var target_password: String = ""
static var target_balance: int = 0
static var balance_revealed: bool = false
static var transferred_amount: int = 0
static var is_millionaire: bool = false
static var _session_loaded: bool = false


# ========================================================
#                ИНИЦИАЛИЗАЦИЯ И ЗАГРУЗКА
# ========================================================

static func ensure_loaded() -> void:
	if not _profile_loaded:
		load_profile()
	if not _notes_loaded:
		load_notes()
	if not _session_loaded:
		load_session()


# ========================================================
#                  ПРОФИЛЬ И БАЛАНС
# ========================================================

static func load_profile() -> void:
	_profile_loaded = true
	if FileAccess.file_exists(PROFILE_PATH):
		var file := FileAccess.open(PROFILE_PATH, FileAccess.READ)
		if file:
			var data = JSON.parse_string(file.get_as_text())
			if typeof(data) == TYPE_DICTIONARY:
				balance = int(data.get("balance", 0))
				total_earned = int(data.get("total_earned", 0))
				hacks_count = int(data.get("hacks_count", 0))
				transactions = data.get("transactions", [])
			file.close()


static func save_profile() -> void:
	var file := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if file:
		var data := {
			"balance": balance,
			"total_earned": total_earned,
			"hacks_count": hacks_count,
			"transactions": transactions
		}
		file.store_string(JSON.stringify(data, "\t"))
		file.close()


static func add_balance(amount: int, source: String = "") -> void:
	ensure_loaded()
	balance += amount
	total_earned += amount
	var tx := {
		"amount": amount,
		"source": source,
		"time": Time.get_datetime_string_from_system(false, true)
	}
	transactions.push_front(tx)
	if transactions.size() > 50:
		transactions.resize(50)
	save_profile()


# ========================================================
#                       ЗАМЕТКИ
# ========================================================

static func load_notes() -> void:
	_notes_loaded = true
	if FileAccess.file_exists(NOTES_PATH):
		var file := FileAccess.open(NOTES_PATH, FileAccess.READ)
		if file:
			var data = JSON.parse_string(file.get_as_text())
			if typeof(data) == TYPE_ARRAY:
				notes = data
			file.close()
	if notes.is_empty():
		# Начальная приветственная памятка
		notes.append({
			"id": 1,
			"text": "SATAN SYSTEM ONLINE\nСохраняйте здесь почты и пароли взломанных целей.",
			"is_pinned": true,
			"created_at": Time.get_datetime_string_from_system(false, true)
		})
		save_notes()


static func save_notes() -> void:
	var file := FileAccess.open(NOTES_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(notes, "\t"))
		file.close()


static func get_sorted_notes() -> Array:
	ensure_loaded()
	var pinned: Array = []
	var unpinned: Array = []
	for note in notes:
		if note.get("is_pinned", false):
			pinned.append(note)
		else:
			unpinned.append(note)
	# Закрепленные в самом верху списка
	var result := []
	result.append_array(pinned)
	result.append_array(unpinned)
	return result


static func add_note(text: String, is_pinned: bool = false) -> Dictionary:
	ensure_loaded()
	var new_id := int(Time.get_unix_time_from_system() * 1000)
	var note := {
		"id": new_id,
		"text": text.strip_edges(),
		"is_pinned": is_pinned,
		"created_at": Time.get_datetime_string_from_system(false, true)
	}
	notes.push_front(note)
	save_notes()
	return note


static func toggle_pin(note_id: int) -> bool:
	ensure_loaded()
	for note in notes:
		if int(note.get("id", 0)) == note_id:
			var current: bool = note.get("is_pinned", false)
			note["is_pinned"] = not current
			save_notes()
			return note["is_pinned"]
	return false


static func delete_note(note_id: int) -> void:
	ensure_loaded()
	for i in range(notes.size()):
		if int(notes[i].get("id", 0)) == note_id:
			notes.remove_at(i)
			break
	save_notes()


# ========================================================
#                    СЕССИЯ УТИЛИТЫ
# ========================================================

static func load_session() -> void:
	_session_loaded = true
	if FileAccess.file_exists(SESSION_PATH):
		var file := FileAccess.open(SESSION_PATH, FileAccess.READ)
		if file:
			var data = JSON.parse_string(file.get_as_text())
			if typeof(data) == TYPE_DICTIONARY:
				session_stage = int(data.get("session_stage", Stage.BANK_ACCESS))
				target_email = str(data.get("target_email", ""))
				target_password = str(data.get("target_password", ""))
				target_balance = int(data.get("target_balance", 0))
				balance_revealed = bool(data.get("balance_revealed", false))
				transferred_amount = int(data.get("transferred_amount", 0))
				is_millionaire = bool(data.get("is_millionaire", false))
			file.close()

	if target_email.is_empty():
		_init_new_target()


static func save_session() -> void:
	var file := FileAccess.open(SESSION_PATH, FileAccess.WRITE)
	if file:
		var data := {
			"session_stage": session_stage,
			"target_email": target_email,
			"target_password": target_password,
			"target_balance": target_balance,
			"balance_revealed": balance_revealed,
			"transferred_amount": transferred_amount,
			"is_millionaire": is_millionaire
		}
		file.store_string(JSON.stringify(data, "\t"))
		file.close()


static func _init_new_target() -> void:
	session_stage = Stage.BANK_ACCESS
	target_email = generate_random_email()
	target_password = generate_random_password()
	balance_revealed = false
	transferred_amount = 0

	# 97% обычный баланс от 500 до 30 000 грн, 3% миллионер
	var roll := randi() % 100
	if roll < 3:
		is_millionaire = true
		target_balance = (randi_range(1000, 3500) * 1000) + (randi_range(1, 99) * 10)
	else:
		is_millionaire = false
		target_balance = randi_range(500, 30000)
	save_session()


static func start_new_session() -> void:
	_init_new_target()


static func complete_bank_access() -> void:
	ensure_loaded()
	if session_stage < Stage.PASSWORD_HACK:
		session_stage = Stage.PASSWORD_HACK
		save_session()


static func complete_password_hack() -> void:
	ensure_loaded()
	if session_stage < Stage.AUTHORIZED:
		session_stage = Stage.AUTHORIZED
		hacks_count += 1
		save_profile()
		save_session()


static func reveal_balance() -> int:
	ensure_loaded()
	balance_revealed = true
	save_session()
	return target_balance


static func get_remaining_victim_balance() -> int:
	ensure_loaded()
	return maxi(0, target_balance - transferred_amount)


static func transfer_funds(amount: int) -> int:
	ensure_loaded()
	var available := get_remaining_victim_balance()
	var actual := clampi(amount, 0, available)
	if actual > 0:
		transferred_amount += actual
		add_balance(actual, "Взлом счёта: " + target_email)
		save_session()
	return actual


# ========================================================
#                 ГЕНЕРАТОРЫ ДАННЫХ
# ========================================================

static func generate_random_email() -> String:
	var first_names: Array[String] = [
		"vlad", "alex", "dmitry", "artem", "oleg", "maxim", "ivan",
		"bogdan", "yaroslav", "andrey", "sergey", "nikita", "roman",
		"taras", "yuriy", "igor", "denis", "kirill", "anton", "stanislav"
	]
	var last_names: Array[String] = [
		"melnyk", "shevchenko", "boyko", "koval", "bondar", "tkachenko",
		"moroz", "kravchenko", "oliynyk", "shevchuk", "polishchuk",
		"lysenko", "rud", "savchenko", "marchenko", "vasylenko"
	]
	var domains: Array[String] = ["gmail.com", "ukr.net", "icloud.com", "meta.ua", "yahoo.com"]

	var fn: String = first_names[randi() % first_names.size()]
	var ln: String = last_names[randi() % last_names.size()]
	var separators: Array[String] = ["_", ".", ""]
	var sep: String = separators[randi() % separators.size()]
	var num := str(randi_range(10, 999))
	var dom: String = domains[randi() % domains.size()]

	return "%s%s%s%s@%s" % [fn, sep, ln, num, dom]


static func generate_random_password() -> String:
	var chars := "abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ23456789!#$@%"
	var length := randi_range(9, 13)
	var password_str := ""
	for i in range(length):
		password_str += chars[randi() % chars.length()]
	return password_str
