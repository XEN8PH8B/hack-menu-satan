extends Control

## Главный экран приложения SATAN:
## - Главное меню (Профиль, Заметки, Баланс, Утилита)
## - Профиль (привязанный Telegram, Device ID, статус)
## - Заметки (список с закреплением наверху, сохранение, копирование)
## - Баланс (игровой счет, статистика, история)
## - Утилита взлома (4 стадии: доступ к банку, взлом пароля, баланс, перевод)
## - Всплывающие iOS-уведомления о переводах сверху экрана

@onready var views_container: Control = $SafeArea/ViewsContainer

# Главные экраны (Views)
@onready var main_menu_view: VBoxContainer = $SafeArea/ViewsContainer/MainMenuView
@onready var profile_view: VBoxContainer = $SafeArea/ViewsContainer/ProfileView
@onready var notes_view: VBoxContainer = $SafeArea/ViewsContainer/NotesView
@onready var balance_view: VBoxContainer = $SafeArea/ViewsContainer/BalanceView
@onready var utility_hub_view: VBoxContainer = $SafeArea/ViewsContainer/UtilityHubView
@onready var bank_access_view: VBoxContainer = $SafeArea/ViewsContainer/BankAccessView
@onready var password_hack_view: VBoxContainer = $SafeArea/ViewsContainer/PasswordHackView
@onready var show_balance_view: VBoxContainer = $SafeArea/ViewsContainer/ShowBalanceView
@onready var transfer_view: VBoxContainer = $SafeArea/ViewsContainer/TransferView

# Верхний баннер уведомлений
@onready var top_notification: PanelContainer = $TopNotificationBanner
@onready var top_notif_title: Label = $TopNotificationBanner/Margin/HBox/VBox/NotifTitle
@onready var top_notif_body: Label = $TopNotificationBanner/Margin/HBox/VBox/NotifBody
@onready var fade_overlay: ColorRect = $FadeOverlay

# Хедер главного меню
@onready var header_profile_chip: Label = $SafeArea/ViewsContainer/MainMenuView/TopBar/ProfileChip
@onready var header_balance_chip: Label = $SafeArea/ViewsContainer/MainMenuView/TopBar/BalanceChip

# Профиль UI
@onready var prof_tg_label: Label = $SafeArea/ViewsContainer/ProfileView/Card/Margin/VBox/TgLabel
@onready var prof_device_label: Label = $SafeArea/ViewsContainer/ProfileView/Card/Margin/VBox/DeviceLabel
@onready var prof_stats_label: Label = $SafeArea/ViewsContainer/ProfileView/StatsCard/Margin/VBox/StatsLabel

# Заметки UI
@onready var note_input: LineEdit = $SafeArea/ViewsContainer/NotesView/InputBox/NoteInput
@onready var notes_list_container: VBoxContainer = $SafeArea/ViewsContainer/NotesView/Scroll/NotesList

# Баланс UI
@onready var bal_amount_label: Label = $SafeArea/ViewsContainer/BalanceView/MainCard/Margin/VBox/AmountLabel
@onready var bal_stats_label: Label = $SafeArea/ViewsContainer/BalanceView/StatsCard/Margin/VBox/StatsLabel
@onready var bal_history_container: VBoxContainer = $SafeArea/ViewsContainer/BalanceView/HistoryScroll/HistoryList

# Утилита Hub UI
@onready var util_target_info: Label = $SafeArea/ViewsContainer/UtilityHubView/TargetCard/Margin/VBox/TargetInfo
@onready var btn_step_bank: Button = $SafeArea/ViewsContainer/UtilityHubView/StepsVBox/BtnStepBank
@onready var btn_step_pass: Button = $SafeArea/ViewsContainer/UtilityHubView/StepsVBox/BtnStepPass
@onready var btn_step_bal: Button = $SafeArea/ViewsContainer/UtilityHubView/StepsVBox/BtnStepBal
@onready var btn_step_trans: Button = $SafeArea/ViewsContainer/UtilityHubView/StepsVBox/BtnStepTrans

# Доступ к банку UI
@onready var bank_terminal_label: Label = $SafeArea/ViewsContainer/BankAccessView/TerminalCard/Margin/TerminalLabel
@onready var bank_progress_bar: ProgressBar = $SafeArea/ViewsContainer/BankAccessView/ProgressBar
@onready var bank_start_btn: Button = $SafeArea/ViewsContainer/BankAccessView/StartBruteBtn
@onready var bank_result_box: VBoxContainer = $SafeArea/ViewsContainer/BankAccessView/ResultBox
@onready var bank_result_email: Label = $SafeArea/ViewsContainer/BankAccessView/ResultBox/ResultEmailLabel
@onready var bank_copy_btn: Button = $SafeArea/ViewsContainer/BankAccessView/ResultBox/CopyEmailBtn

# Взлом пароля UI
@onready var dial_minigame: LockpickDial = $SafeArea/ViewsContainer/PasswordHackView/DialContainer/Dial
@onready var pass_step_label: Label = $SafeArea/ViewsContainer/PasswordHackView/StepLabel
@onready var pass_stop_btn: Button = $SafeArea/ViewsContainer/PasswordHackView/StopBtn
@onready var pass_result_box: VBoxContainer = $SafeArea/ViewsContainer/PasswordHackView/ResultBox
@onready var pass_result_label: Label = $SafeArea/ViewsContainer/PasswordHackView/ResultBox/ResultPassLabel
@onready var pass_copy_btn: Button = $SafeArea/ViewsContainer/PasswordHackView/ResultBox/CopyPassBtn

# Показать баланс UI
@onready var show_bal_victim_label: Label = $SafeArea/ViewsContainer/ShowBalanceView/Card/Margin/VBox/VictimLabel
@onready var show_bal_amount_label: Label = $SafeArea/ViewsContainer/ShowBalanceView/Card/Margin/VBox/AmountLabel
@onready var show_bal_badge: Label = $SafeArea/ViewsContainer/ShowBalanceView/Card/Margin/VBox/MillionaireBadge

# Перевести себе UI
@onready var trans_avail_label: Label = $SafeArea/ViewsContainer/TransferView/Card/Margin/VBox/AvailLabel
@onready var trans_input: LineEdit = $SafeArea/ViewsContainer/TransferView/Card/Margin/VBox/AmountInput
@onready var trans_exec_btn: Button = $SafeArea/ViewsContainer/TransferView/Card/Margin/VBox/ExecTransferBtn
@onready var trans_new_session_btn: Button = $SafeArea/ViewsContainer/TransferView/NewSessionBtn

var current_active_view: Control = null
var is_bruteforcing: bool = false
var notif_tween: Tween = null


func _ready() -> void:
	SatanGame.ensure_loaded()

	# Инициализация всех экранов (прячем всё кроме главного меню)
	var all_views := [
		main_menu_view, profile_view, notes_view, balance_view,
		utility_hub_view, bank_access_view, password_hack_view,
		show_balance_view, transfer_view
	]
	for v in all_views:
		v.visible = false
		v.modulate.a = 0.0

	_switch_view(main_menu_view, false)

	# Плавное появление экрана
	fade_overlay.color = Color(0, 0, 0, 1)
	var t := create_tween()
	t.tween_property(fade_overlay, "color:a", 0.0, 0.4)

	_setup_signals()
	_update_hub_chips()


func _setup_signals() -> void:
	# Главное меню
	$SafeArea/ViewsContainer/MainMenuView/MenuButtons/BtnProfile.pressed.connect(func(): _open_profile())
	$SafeArea/ViewsContainer/MainMenuView/MenuButtons/BtnNotes.pressed.connect(func(): _open_notes())
	$SafeArea/ViewsContainer/MainMenuView/MenuButtons/BtnBalance.pressed.connect(func(): _open_balance())
	$SafeArea/ViewsContainer/MainMenuView/MenuButtons/BtnUtility.pressed.connect(func(): _open_utility_hub())
	$SafeArea/ViewsContainer/MainMenuView/ResetLicBtn.pressed.connect(_on_reset_license_pressed)

	# Кнопки "Выход / Назад" во всех вкладках
	$SafeArea/ViewsContainer/ProfileView/BackBtn.pressed.connect(func(): _switch_view(main_menu_view))
	$SafeArea/ViewsContainer/NotesView/BackBtn.pressed.connect(func(): _switch_view(main_menu_view))
	$SafeArea/ViewsContainer/BalanceView/BackBtn.pressed.connect(func(): _switch_view(main_menu_view))
	$SafeArea/ViewsContainer/UtilityHubView/BackBtn.pressed.connect(func(): _switch_view(main_menu_view))
	$SafeArea/ViewsContainer/BankAccessView/BackBtn.pressed.connect(func(): _open_utility_hub())
	$SafeArea/ViewsContainer/PasswordHackView/BackBtn.pressed.connect(func(): _open_utility_hub())
	$SafeArea/ViewsContainer/ShowBalanceView/BackBtn.pressed.connect(func(): _open_utility_hub())
	$SafeArea/ViewsContainer/TransferView/BackBtn.pressed.connect(func(): _open_utility_hub())

	# Заметки
	$SafeArea/ViewsContainer/NotesView/InputBox/AddNoteBtn.pressed.connect(_on_add_note_pressed)
	$SafeArea/ViewsContainer/NotesView/InputBox/PasteNoteBtn.pressed.connect(_on_paste_note_pressed)
	note_input.text_submitted.connect(func(_t): _on_add_note_pressed())

	# Утилита Hub шаги
	btn_step_bank.pressed.connect(_open_bank_access)
	btn_step_pass.pressed.connect(_open_password_hack)
	btn_step_bal.pressed.connect(_open_show_balance)
	btn_step_trans.pressed.connect(_open_transfer)
	$SafeArea/ViewsContainer/UtilityHubView/NewSessionBtn.pressed.connect(_on_new_session_pressed)

	# Стадия 1: Доступ к банку
	bank_start_btn.pressed.connect(_start_bruteforce)
	bank_copy_btn.pressed.connect(_copy_bank_email)

	# Стадия 2: Взлом пароля
	dial_minigame.step_succeeded.connect(_on_dial_step_succeeded)
	dial_minigame.step_failed.connect(_on_dial_step_failed)
	dial_minigame.minigame_completed.connect(_on_dial_completed)
	pass_stop_btn.pressed.connect(func(): dial_minigame.attempt_stop())
	pass_copy_btn.pressed.connect(_copy_password)

	# Стадия 3: Баланс
	$SafeArea/ViewsContainer/ShowBalanceView/Card/Margin/VBox/GoToTransferBtn.pressed.connect(_open_transfer)

	# Стадия 4: Перевод
	$SafeArea/ViewsContainer/TransferView/Card/Margin/VBox/QuickBtns/Btn25.pressed.connect(func(): _set_transfer_percent(0.25))
	$SafeArea/ViewsContainer/TransferView/Card/Margin/VBox/QuickBtns/Btn50.pressed.connect(func(): _set_transfer_percent(0.50))
	$SafeArea/ViewsContainer/TransferView/Card/Margin/VBox/QuickBtns/Btn100.pressed.connect(func(): _set_transfer_percent(1.00))
	trans_exec_btn.pressed.connect(_execute_transfer)
	trans_new_session_btn.pressed.connect(_on_new_session_pressed)


# ========================================================
#                  ПЕРЕКЛЮЧЕНИЕ ЭКРАНОВ
# ========================================================

func _switch_view(target_view: Control, animated: bool = true) -> void:
	if current_active_view == target_view:
		return

	if animated and current_active_view:
		var prev := current_active_view
		var tween := create_tween()
		tween.tween_property(prev, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_QUAD)
		tween.tween_callback(func():
			prev.visible = false
			_show_new_view(target_view)
		)
	else:
		if current_active_view:
			current_active_view.visible = false
			current_active_view.modulate.a = 0.0
		_show_new_view(target_view)


func _show_new_view(target_view: Control) -> void:
	current_active_view = target_view
	target_view.visible = true
	target_view.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(target_view, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_QUAD)
	_update_hub_chips()


func _update_hub_chips() -> void:
	header_profile_chip.text = "👤 " + SatanLicense.tg_profile
	header_balance_chip.text = "💳 %s ₴" % _format_number(SatanGame.balance)


# ========================================================
#                        ПРОФИЛЬ
# ========================================================

func _open_profile() -> void:
	prof_tg_label.text = SatanLicense.tg_profile
	prof_device_label.text = SatanLicense.device_id
	prof_stats_label.text = "Взломано счетов: %d\nВсего заработано: %s ₴" % [
		SatanGame.hacks_count,
		_format_number(SatanGame.total_earned)
	]
	_switch_view(profile_view)


# ========================================================
#                        ЗАМЕТКИ
# ========================================================

func _open_notes() -> void:
	_render_notes_list()
	_switch_view(notes_view)


func _render_notes_list() -> void:
	for child in notes_list_container.get_children():
		child.queue_free()

	var sorted_notes := SatanGame.get_sorted_notes()
	for note in sorted_notes:
		var card := _create_note_card(note)
		notes_list_container.add_child(card)


func _create_note_card(note: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	var is_pinned: bool = note.get("is_pinned", false)
	var note_id: int = int(note.get("id", 0))
	var text: String = note.get("text", "")
	var date: String = note.get("created_at", "")

	# Стиль карточки
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.09, 0.09, 0.95) if not is_pinned else Color(0.14, 0.14, 0.14, 0.98)
	sb.border_width_left = 3 if is_pinned else 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(1.0, 1.0, 1.0, 0.85) if is_pinned else Color(0.25, 0.25, 0.25, 1.0)
	sb.set_corner_radius_all(10)
	card.add_theme_stylebox_override("panel", sb)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	card.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.theme_override_constants.separation = 12
	margin.add_child(hbox)

	# Кнопка закрепления (Pin)
	var pin_btn := Button.new()
	pin_btn.text = "📌" if is_pinned else "📍"
	pin_btn.flat = true
	pin_btn.add_theme_font_size_override("font_size", 24)
	pin_btn.pressed.connect(func():
		SatanGame.toggle_pin(note_id)
		_render_notes_list()
	)
	hbox.add_child(pin_btn)

	# Текст заметки
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var text_lbl := Label.new()
	text_lbl.text = text
	text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_lbl.add_theme_font_size_override("font_size", 22)
	vbox.add_child(text_lbl)

	var date_lbl := Label.new()
	date_lbl.text = (("📌 ЗАКРЕПЛЕНО | " if is_pinned else "") + date)
	date_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1.0))
	date_lbl.add_theme_font_size_override("font_size", 16)
	vbox.add_child(date_lbl)
	hbox.add_child(vbox)

	# Кнопка скопировать
	var copy_btn := Button.new()
	copy_btn.text = "📋"
	copy_btn.flat = true
	copy_btn.add_theme_font_size_override("font_size", 22)
	copy_btn.pressed.connect(func():
		DisplayServer.clipboard_set(text)
		show_notification("✓ Скопировано", "Заметка скопирована в буфер обмена")
	)
	hbox.add_child(copy_btn)

	# Кнопка удалить
	var del_btn := Button.new()
	del_btn.text = "🗑"
	del_btn.flat = true
	del_btn.add_theme_font_size_override("font_size", 22)
	del_btn.pressed.connect(func():
		SatanGame.delete_note(note_id)
		_render_notes_list()
	)
	hbox.add_child(del_btn)

	return card


func _on_add_note_pressed() -> void:
	var txt := note_input.text.strip_edges()
	if not txt.is_empty():
		SatanGame.add_note(txt)
		note_input.text = ""
		_render_notes_list()


func _on_paste_note_pressed() -> void:
	var clip := DisplayServer.clipboard_get().strip_edges()
	if not clip.is_empty():
		note_input.text = clip


# ========================================================
#                        БАЛАНС
# ========================================================

func _open_balance() -> void:
	bal_amount_label.text = "%s ₴" % _format_number(SatanGame.balance)
	bal_stats_label.text = "Всего заработано: %s ₴\nВзломано учетных записей: %d" % [
		_format_number(SatanGame.total_earned),
		SatanGame.hacks_count
	]

	for child in bal_history_container.get_children():
		child.queue_free()

	if SatanGame.transactions.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "История транзакций пуста.\nИспользуйте Утилиту для перевода средств."
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1.0))
		bal_history_container.add_child(empty_lbl)
	else:
		for tx in SatanGame.transactions:
			var card := PanelContainer.new()
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0.08, 0.08, 0.08, 0.9)
			sb.set_corner_radius_all(8)
			card.add_theme_stylebox_override("panel", sb)

			var m := MarginContainer.new()
			m.add_theme_constant_override("margin_left", 14)
			m.add_theme_constant_override("margin_right", 14)
			m.add_theme_constant_override("margin_top", 10)
			m.add_theme_constant_override("margin_bottom", 10)
			card.add_child(m)

			var h := HBoxContainer.new()
			m.add_child(h)

			var v := VBoxContainer.new()
			v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var src := Label.new()
			src.text = str(tx.get("source", "Перевод SATAN PAY"))
			src.add_theme_font_size_override("font_size", 20)
			v.add_child(src)

			var tm := Label.new()
			tm.text = str(tx.get("time", ""))
			tm.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1.0))
			tm.add_theme_font_size_override("font_size", 16)
			v.add_child(tm)
			h.add_child(v)

			var am := Label.new()
			am.text = "+ %s ₴" % _format_number(int(tx.get("amount", 0)))
			am.add_theme_color_override("font_color", Color(0.0, 1.0, 0.45, 1.0))
			am.add_theme_font_size_override("font_size", 24)
			h.add_child(am)

			bal_history_container.add_child(card)

	_switch_view(balance_view)


# ========================================================
#                    УТИЛИТА (ХАБ И ШАГИ)
# ========================================================

func _open_utility_hub() -> void:
	var stage := SatanGame.session_stage
	var remaining := SatanGame.get_remaining_victim_balance()

	util_target_info.text = "ТЕКУЩАЯ ЦЕЛЬ: %s\nСТАТУС СЕССИИ: %s" % [
		SatanGame.target_email if stage > SatanGame.Stage.BANK_ACCESS else "НЕ ИДЕНТИФИЦИРОВАНА",
		"ЗАВЕРШЕНА (СРЕДСТВА ВЫВЕДЕНЫ)" if (stage >= SatanGame.Stage.AUTHORIZED and remaining == 0) else "АКТИВНА"
	]

	# Шаг 1: Доступ к банку
	if stage == SatanGame.Stage.BANK_ACCESS:
		btn_step_bank.text = "1. Доступ к банку [ДОСТУПНО]"
		btn_step_bank.disabled = false
	else:
		btn_step_bank.text = "1. Доступ к банку ✓ [ВЫПОЛНЕНО]"
		btn_step_bank.disabled = false

	# Шаг 2: Взлом пароля
	if stage < SatanGame.Stage.PASSWORD_HACK:
		btn_step_pass.text = "2. Взлом пароля 🔒"
		btn_step_pass.disabled = true
	elif stage == SatanGame.Stage.PASSWORD_HACK:
		btn_step_pass.text = "2. Взлом пароля [ДОСТУПНО]"
		btn_step_pass.disabled = false
	else:
		btn_step_pass.text = "2. Взлом пароля ✓ [ВЫПОЛНЕНО]"
		btn_step_pass.disabled = false

	# Шаги 3 и 4: Баланс и Перевод
	if stage < SatanGame.Stage.AUTHORIZED:
		btn_step_bal.text = "3. Показать баланс 🔒"
		btn_step_bal.disabled = true
		btn_step_trans.text = "4. Перевести себе 🔒"
		btn_step_trans.disabled = true
	else:
		btn_step_bal.text = "3. Показать баланс" + (" ✓" if SatanGame.balance_revealed else " [ДОСТУПНО]")
		btn_step_bal.disabled = false
		btn_step_trans.text = "4. Перевести себе [ДОСТУПНО]"
		btn_step_trans.disabled = false

	_switch_view(utility_hub_view)


# --- Стадия 1: Доступ к банку ---

func _open_bank_access() -> void:
	if SatanGame.session_stage > SatanGame.Stage.BANK_ACCESS:
		# Уже взломано ранее в этой сессии
		bank_terminal_label.text = "[+] ХОСТ: auth.bank-core.net\n[+] ДОСТУП АВТОРИЗОВАН\nПочта жертвы: %s" % SatanGame.target_email
		bank_progress_bar.value = 100.0
		bank_start_btn.visible = false
		bank_result_box.visible = true
		bank_result_email.text = SatanGame.target_email
	else:
		bank_terminal_label.text = "СИСТЕМА BRUTEFORCE ГОТОВА К ЗАПУСКУ.\nНажмите «Начать подбор» для перехвата почты..."
		bank_progress_bar.value = 0.0
		bank_start_btn.visible = true
		bank_start_btn.disabled = false
		bank_result_box.visible = false
	_switch_view(bank_access_view)


func _start_bruteforce() -> void:
	if is_bruteforcing:
		return
	is_bruteforcing = true
	bank_start_btn.disabled = true

	var tween := create_tween()
	var chars := "0123456789ABCDEFabcdef!#$%&@*"

	# Несколько рандомных этапов анимации матрицы/терминала
	for i in range(12):
		var target_val: float = float(i + 1) * (100.0 / 12.0)
		var delay: float = randf_range(0.12, 0.28)
		tween.tween_callback(func():
			var scramble := ""
			for r in range(4):
				var line := ">>> 0x%04X: " % randi_range(0x1000, 0xFFFF)
				for c in range(16):
					line += chars[randi() % chars.length()]
				scramble += line + "\n"
			bank_terminal_label.text = scramble
		)
		tween.tween_property(bank_progress_bar, "value", target_val, delay)

	# Финальный результат подбора
	tween.tween_callback(func():
		is_bruteforcing = false
		SatanGame.complete_bank_access()
		bank_terminal_label.text = "[+] ХОСТ НАЙДЕН: auth.bank-core.net\n[+] УСПЕШНЫЙ ПЕРЕХВАТ!\nПочта: %s" % SatanGame.target_email
		bank_result_box.visible = true
		bank_result_email.text = SatanGame.target_email
		bank_start_btn.visible = false
		show_notification("⚡ Доступ к банку получен!", "Почта перехвачена. Скопируйте её для перехода к взлому пароля.")
	)


func _copy_bank_email() -> void:
	DisplayServer.clipboard_set(SatanGame.target_email)
	show_notification("✓ Почта скопирована!", "Данные в буфере обмена. Разблокирован шаг «Взлом пароля».")
	var t := create_tween()
	t.tween_interval(0.6)
	t.tween_callback(func(): _open_utility_hub())


# --- Стадия 2: Взлом пароля ---

func _open_password_hack() -> void:
	if SatanGame.session_stage > SatanGame.Stage.PASSWORD_HACK:
		# Уже взломан в этой сессии
		dial_minigame.visible = false
		pass_stop_btn.visible = false
		pass_step_label.text = "✓ ПАРОЛЬ УСПЕШНО РАСШИФРОВАН"
		pass_result_box.visible = true
		pass_result_label.text = SatanGame.target_password
	else:
		dial_minigame.visible = true
		pass_stop_btn.visible = true
		pass_result_box.visible = false
		dial_minigame.start_game()
		pass_step_label.text = "ОСТАНОВИТЕ ИНДИКАТОР В ЦЕЛЕВОЙ ЗОНЕ (Шаг 1 из %d)" % dial_minigame.total_steps
	_switch_view(password_hack_view)


func _on_dial_step_succeeded(cur: int, total: int) -> void:
	pass_step_label.text = "✓ ТОЧНО! (Шаг %d из %d)" % [cur, total]


func _on_dial_step_failed() -> void:
	pass_step_label.text = "❌ ПРОМАХ! Попробуйте снова..."


func _on_dial_completed(_pwd: String) -> void:
	SatanGame.complete_password_hack()
	pass_step_label.text = "✓ ЗАЩИТА ВЗЛОМАНА! ХЭШ РАСШИФРОВАН:"
	dial_minigame.visible = false
	pass_stop_btn.visible = false
	pass_result_box.visible = true
	pass_result_label.text = SatanGame.target_password
	show_notification("🔓 Пароль взломан!", "Хэш расшифрован. Скопируйте пароль или сохраните в заметках.")


func _copy_password() -> void:
	DisplayServer.clipboard_set(SatanGame.target_password)
	show_notification("✓ Пароль скопирован!", "Вы можете выйти в Заметки для сохранения или перейти к балансу.")
	var t := create_tween()
	t.tween_interval(0.8)
	t.tween_callback(func(): _open_utility_hub())


# --- Стадия 3: Показать баланс ---

func _open_show_balance() -> void:
	var bal := SatanGame.reveal_balance()
	show_bal_victim_label.text = "Владелец счета: " + SatanGame.target_email
	show_bal_amount_label.text = "%s ₴" % _format_number(bal)
	show_bal_badge.visible = SatanGame.is_millionaire
	_switch_view(show_balance_view)


# --- Стадия 4: Перевести себе ---

func _open_transfer() -> void:
	var remaining := SatanGame.get_remaining_victim_balance()
	trans_avail_label.text = "Доступно для вывода: %s ₴" % _format_number(remaining)
	trans_input.text = str(remaining)
	trans_new_session_btn.visible = (remaining == 0)
	_switch_view(transfer_view)


func _set_transfer_percent(fraction: float) -> void:
	var remaining := SatanGame.get_remaining_victim_balance()
	var amt := int(round(float(remaining) * fraction))
	trans_input.text = str(amt)


func _execute_transfer() -> void:
	var text_amt := trans_input.text.strip_edges()
	var amt := int(text_amt)
	if amt <= 0:
		show_notification("❌ Ошибка перевода", "Укажите сумму перевода больше 0 ₴")
		return

	var available := SatanGame.get_remaining_victim_balance()
	if amt > available:
		amt = available

	var transferred := SatanGame.transfer_funds(amt)
	if transferred > 0:
		show_notification(
			"🔔 SATAN PAY: Зачисление средств",
			"+%s ₴ успешно зачислены на ваш баланс!" % _format_number(transferred)
		)
		var remaining := SatanGame.get_remaining_victim_balance()
		trans_avail_label.text = "Доступно для вывода: %s ₴" % _format_number(remaining)
		trans_input.text = str(remaining)
		trans_new_session_btn.visible = (remaining == 0)
		_update_hub_chips()


func _on_new_session_pressed() -> void:
	SatanGame.start_new_session()
	show_notification("🔄 Новая сессия начата", "Сгенерирована новая цель для взлома.")
	_open_utility_hub()


# ========================================================
#                    ВСПЛЫВАЮЩИЙ БАННЕР
# ========================================================

func show_notification(title: String, message: String) -> void:
	top_notif_title.text = title
	top_notif_body.text = message

	if notif_tween and notif_tween.is_valid():
		notif_tween.kill()

	top_notification.visible = true
	top_notification.position.y = -140

	notif_tween = create_tween()
	# Плавный выезд сверху
	notif_tween.tween_property(top_notification, "position:y", 20.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	notif_tween.tween_interval(2.6)
	# Плавный откат наверх
	notif_tween.tween_property(top_notification, "position:y", -140.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	notif_tween.tween_callback(func(): top_notification.visible = false)


# ========================================================
#                   СБРОС ЛИЦЕНЗИИ
# ========================================================

func _on_reset_license_pressed() -> void:
	SatanLicense.deactivate()
	var tween := create_tween()
	tween.tween_property(fade_overlay, "color:a", 1.0, 0.4)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://activation.tscn"))


# ========================================================
#                 ФОРМАТИРОВАНИЕ ЧИСЕЛ
# ========================================================

func _format_number(num: int) -> String:
	var s := str(num)
	var res := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		count += 1
		if count % 3 == 0 and i > 0:
			res = " " + res
	return res
