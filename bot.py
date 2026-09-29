#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Telegram-бот авторизации и генерации уникальных ключей для приложения SATAN.
Бот: @XenophobBot
Токен: 8347665816:AAEcv9eHrBqOp1WKBTDploa4KXdtU2knERM

Работает на стандартной библиотеке Python (не требует сторонних pip-пакетов).
Привязывает лицензионный ключ к уникальному аппаратному Device ID устройства.
"""

import os
import sys
import json
import time
import hashlib
import datetime
import urllib.request
import urllib.parse
import urllib.error

# Поддержка UTF-8 на консолях Windows
try:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    if hasattr(sys.stderr, "reconfigure"):
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

TOKEN = "8347665816:AAEcv9eHrBqOp1WKBTDploa4KXdtU2knERM"
API_URL = f"https://api.telegram.org/bot{TOKEN}/"
SECRET_SALT = "SATAN_CYBER_666_XENOPHOB_SECRET_SALT_2026"
DB_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "bot_keys.json")

# Состояния пользователей (ожидание ввода Device ID)
user_states = {}


def load_database() -> dict:
    if os.path.exists(DB_FILE):
        try:
            with open(DB_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception as e:
            print(f"[!] Ошибка загрузки базы: {e}")
    return {"users": {}}


def save_database(data: dict) -> None:
    try:
        with open(DB_FILE, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
    except Exception as e:
        print(f"[!] Ошибка сохранения базы: {e}")


def generate_key(device_id: str) -> str:
    """Генерация уникального крипто-ключа, привязанного к Device ID."""
    clean_id = device_id.strip().upper()
    raw = f"{clean_id}:{SECRET_SALT}".encode("utf-8")
    hash_hex = hashlib.sha256(raw).hexdigest().upper()
    return f"SATAN-{hash_hex[0:4]}-{hash_hex[4:8]}-{hash_hex[8:12]}-{hash_hex[12:16]}"


def api_request(method: str, params: dict = None) -> dict:
    url = API_URL + method
    data = None
    headers = {"Content-Type": "application/json"}
    if params is not None:
        data = json.dumps(params).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=45) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8")
        print(f"[HTTP {e.code}] {method} -> {err_body}")
        return {"ok": False, "description": err_body}
    except Exception as e:
        print(f"[Request Error] {method}: {e}")
        return {"ok": False, "description": str(e)}


def send_message(chat_id: int, text: str, reply_markup: dict = None, parse_mode: str = "Markdown") -> dict:
    payload = {
        "chat_id": chat_id,
        "text": text,
        "parse_mode": parse_mode
    }
    if reply_markup:
        payload["reply_markup"] = reply_markup
    return api_request("sendMessage", payload)


def answer_callback_query(callback_query_id: str, text: str = None) -> dict:
    payload = {"callback_query_id": callback_query_id}
    if text:
        payload["text"] = text
    return api_request("answerCallbackQuery", payload)


def get_main_keyboard() -> dict:
    return {
        "keyboard": [
            [{"text": "🔑 Получить ключ"}],
            [{"text": "📋 Мои активные ключи"}, {"text": "❓ Как узнать Device ID"}]
        ],
        "resize_keyboard": True,
        "persistent": True
    }


def issue_key_for_device(chat_id: int, user_id_str: str, username: str, first_name: str, device_id: str):
    clean_id = device_id.strip()
    if len(clean_id) < 4:
        send_message(
            chat_id,
            "❌ *Некорректный Device ID!*\nПожалуйста, скопируйте полный идентификатор из приложения SATAN.",
            reply_markup=get_main_keyboard()
        )
        return

    key = generate_key(clean_id)
    now_iso = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    # Формируем профиль Telegram
    user_tag = f"@{username}" if username else f"@{first_name.replace(' ', '_')}"
    full_key = f"{key}:{user_tag}"

    # Сохраняем в базу
    db = load_database()
    if user_id_str not in db["users"]:
        db["users"][user_id_str] = {
            "username": username,
            "first_name": first_name,
            "devices": {}
        }

    db["users"][user_id_str]["devices"][clean_id] = {
        "key": full_key,
        "raw_key": key,
        "created_at": now_iso
    }
    save_database(db)

    print(f"[+] Ключ выдан для {user_tag} (ID: {user_id_str}) | Device: {clean_id} -> Key: {full_key}")

    msg = (
        "✅ *КЛЮЧ АКТИВАЦИИ УСПЕШНО СГЕНЕРИРОВАН!*\n\n"
        f"📱 *Device ID устройства:*\n`{clean_id}`\n\n"
        f"🔑 *Ваш уникальный ключ:*\n`{full_key}`\n\n"
        "_(Нажмите на ключ выше, чтобы скопировать его в буфер)_\n\n"
        "───────────────\n"
        "📌 *Как активировать приложение:*\n"
        "1. Скопируйте полученный ключ.\n"
        "2. Откройте приложение *SATAN*.\n"
        "3. Нажмите кнопку «ВСТАВИТЬ» и затем «АКТИВИРОВАТЬ».\n\n"
        "⚠️ *Важно:* данный ключ привязан строго к вашему текущему устройству и не будет работать на других устройствах!"
    )
    send_message(chat_id, msg, reply_markup=get_main_keyboard())


def handle_update(update: dict):
    # Обработка Inline-кнопок
    if "callback_query" in update:
        cq = update["callback_query"]
        cq_id = cq["id"]
        from_user = cq["from"]
        user_id_str = str(from_user["id"])
        username = from_user.get("username", "")
        first_name = from_user.get("first_name", "")
        data = cq.get("data", "")
        chat_id = cq["message"]["chat"]["id"]

        answer_callback_query(cq_id)

        if data.startswith("gen_key:"):
            target_device_id = data.split("gen_key:", 1)[1]
            issue_key_for_device(chat_id, user_id_str, username, first_name, target_device_id)
        return

    # Обработка сообщений
    if "message" not in update:
        return

    message = update["message"]
    chat_id = message["chat"]["id"]
    from_user = message.get("from", {})
    user_id_str = str(from_user.get("id", chat_id))
    username = from_user.get("username", "")
    first_name = from_user.get("first_name", "Пользователь")
    text = message.get("text", "").strip()

    # Deep Link /start <device_id>
    if text.startswith("/start"):
        parts = text.split(maxsplit=1)
        if len(parts) > 1 and parts[1].strip():
            device_param = parts[1].strip()
            # Устройство передано прямо из приложения!
            welcome_text = (
                f"👋 Приветствуем, *{first_name}*!\n\n"
                "📱 *Обнаружено устройство из приложения SATAN:*\n"
                f"`{device_param}`\n\n"
                "Нажмите кнопку ниже, чтобы получить персональный ключ для этого устройства:"
            )
            inline_kb = {
                "inline_keyboard": [
                    [{"text": "⚡ Выдать ключ для этого устройства", "callback_data": f"gen_key:{device_param}"}]
                ]
            }
            send_message(chat_id, welcome_text, reply_markup=inline_kb)
            return

        # Обычный /start
        welcome_text = (
            f"👋 Добро пожаловать в систему активации *SATAN*, *{first_name}*!\n\n"
            "Здесь вы можете получить персональный ключ лицензии, "
            "привязанный к вашему устройству.\n\n"
            "Выберите действие в меню ниже:"
        )
        send_message(chat_id, welcome_text, reply_markup=get_main_keyboard())
        return

    # Меню: Получить ключ
    if text == "🔑 Получить ключ" or text == "/key":
        user_states[user_id_str] = "WAITING_DEVICE_ID"
        prompt_text = (
            "📱 *Введите ваш Device ID:*\n\n"
            "Скопируйте его на экране активации в приложении *SATAN* "
            "(кнопка «СКОПИРОВАТЬ ID») и отправьте сообщением сюда."
        )
        send_message(chat_id, prompt_text, reply_markup=get_main_keyboard())
        return

    # Меню: Как узнать Device ID
    if text == "❓ Как узнать Device ID" or text == "/help":
        help_text = (
            "📖 *Как узнать ваш Device ID:*\n\n"
            "1. Запустите приложение *SATAN* на вашем iPhone или компьютере.\n"
            "2. После загрузочного экрана откроется окно активации.\n"
            "3. В блоке «ВАШ УНИКАЛЬНЫЙ DEVICE ID» нажмите кнопку *«СКОПИРОВАТЬ ID»*.\n"
            "4. Также вы можете просто нажать кнопку *«ПЕРЕЙТИ В TELEGRAM БОТА»* — "
            "и ваш Device ID определится автоматически!"
        )
        send_message(chat_id, help_text, reply_markup=get_main_keyboard())
        return

    # Меню: Мои ключи
    if text == "📋 Мои активные ключи" or text == "/mykeys":
        db = load_database()
        user_data = db.get("users", {}).get(user_id_str, {})
        devices = user_data.get("devices", {})
        if not devices:
            send_message(chat_id, "ℹ️ У вас пока нет сгенерированных ключей. Нажмите *«🔑 Получить ключ»*.")
            return

        reply_lines = ["📋 *Ваши привязанные ключи:*\n"]
        for did, info in devices.items():
            k = info.get("key", "")
            d = info.get("created_at", "")
            reply_lines.append(f"• *Устройство:* `{did}`\n  *Ключ:* `{k}`\n  *Дата:* _{d}_\n")
        send_message(chat_id, "\n".join(reply_lines), reply_markup=get_main_keyboard())
        return

    # Если пользователь вводил Device ID
    if user_states.get(user_id_str) == "WAITING_DEVICE_ID" or len(text) >= 8:
        user_states.pop(user_id_str, None)
        issue_key_for_device(chat_id, user_id_str, username, first_name, text)
        return

    # Ответ на неизвестное сообщение
    send_message(
        chat_id,
        "❓ Неизвестная команда. Пожалуйста, воспользуйтесь кнопками меню ниже.",
        reply_markup=get_main_keyboard()
    )


def main():
    print("=" * 60)
    print("      SATAN TELEGRAM BOT — SYSTEM ONLINE")
    print("      Бот: @XenophobBot")
    print("      Токен: " + TOKEN[:12] + "..." + TOKEN[-5:])
    print("=" * 60)

    # Проверка подключения
    me = api_request("getMe")
    if not me.get("ok"):
        print(f"[!] Ошибка подключения к Telegram API: {me}")
        sys.exit(1)

    bot_info = me["result"]
    print(f"[OK] Успешно авторизован: @{bot_info.get('username')} ({bot_info.get('first_name')})")
    print("[OK] Бот ожидает запросы пользователей. Для остановки нажмите Ctrl+C.\n")

    offset = 0
    while True:
        try:
            updates_resp = api_request("getUpdates", {"offset": offset, "timeout": 25})
            if not updates_resp.get("ok"):
                time.sleep(2)
                continue

            updates = updates_resp.get("result", [])
            for upd in updates:
                offset = max(offset, upd["update_id"] + 1)
                try:
                    handle_update(upd)
                except Exception as ex:
                    print(f"[!] Ошибка при обработке сообщения: {ex}")

        except KeyboardInterrupt:
            print("\n[!] Остановка бота пользователем.")
            break
        except Exception as e:
            print(f"[!] Непредвиденная ошибка цикла: {e}")
            time.sleep(3)


if __name__ == "__main__":
    main()
