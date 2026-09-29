@echo off
setlocal
set "PYTHONIOENCODING=utf-8"
title SATAN Bot Server - @XenophobBot
color 0F
cls
echo ========================================================
echo        SATAN APP - TELEGRAM BOT SERVER
echo        Bot: @XenophobBot
echo ========================================================
echo.

where py >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Python Launcher found. Starting bot...
    echo.
    py -u bot.py
    goto :end
)

where python >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Python found. Starting bot...
    echo.
    python -u bot.py
    goto :end
)

echo [ERROR] Python not found in system!
echo Please install Python from https://python.org
echo.

:end
echo.
echo [!] Process finished.
pause