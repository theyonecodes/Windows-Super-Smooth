@echo off
title SystemCare AutoPilot
mode con cols=72 lines=35
color 0F
setlocal EnableDelayedExpansion

net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:MAIN
cls
echo.
echo  ==========================================
echo       SYSTEMCARE - AUTOPILOT
echo  ==========================================
echo.
echo   System is being managed automatically.
echo.
echo   [1] Start AutoPilot (Always-On)
echo   [2] View Live Status
echo   [3] View Log
echo.
echo   [0] Exit
echo.
echo  ==========================================
echo.
choice /c 120 /n /m "  Select: "
set "sel=%errorlevel%"
if %sel%==1 goto START
if %sel%==2 goto STATUS
if %sel%==3 goto LOG
if %sel%==4 goto EXIT
goto MAIN

:START
cls
echo.
echo  ==========================================
echo       AUTOPILOT ACTIVE
echo  ==========================================
echo.
echo   Monitoring system every 30 seconds.
echo   All optimizations applied automatically.
echo.
echo   Press Ctrl+C to stop.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0AutoPilot.ps1"
goto MAIN

:STATUS
cls
echo.
echo  ==========================================
echo       LIVE STATUS
echo  ==========================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%~dp0Status.ps1'"
echo.
pause
goto MAIN

:LOG
cls
echo.
echo  ==========================================
echo       ACTIVITY LOG
echo  ==========================================
echo.
set "logfile=%USERPROFILE%\Downloads\systemcare.log"
if exist "%logfile%" (
    powershell -NoProfile -Command "Get-Content '%logfile%' -Tail 20 | ForEach-Object {Write-Host ('  ' + $_)}"
) else (
    echo   No activity yet. Start AutoPilot first.
)
echo.
pause
goto MAIN

:EXIT
exit /b