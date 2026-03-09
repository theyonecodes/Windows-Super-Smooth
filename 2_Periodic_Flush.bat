@echo off
:: =========================================================================
:: ⚡ WINDOWS SUPER SMOOTH - PERIODIC MAINTENANCE FLUSH
:: Run this every few days or when the system feels "heavy" or slow.
:: Clears temporary queues, stale DNS, and resets the UI memory footprint.
:: =========================================================================
title Windows Super Smooth - Flush
echo [!] Verifying Administrator Privileges...
net session >nul 2>&1
if %errorLevel% NEQ 0 ( echo [ERROR] Run as Administrator. & pause & exit /b )

echo.
echo [1/4] Flushing DNS Resolver Cache...
:: Clears outdated network routes
ipconfig /flushdns >nul

echo [2/4] Purging System and Application Temp Files...
:: Silently deletes temporary files safely
del /q /f /s "%TEMP%\*" >nul 2>&1
del /q /f /s "C:\Windows\Temp\*" >nul 2>&1

echo [3/4] Clearing Windows Update Stale Cache...
:: Stops the update service, clears downloaded junk, and restarts it
net stop wuauserv >nul 2>&1
del /q /f /s "C:\Windows\SoftwareDistribution\Download\*" >nul 2>&1
net start wuauserv >nul 2>&1

echo [4/4] Resetting Windows Shell (Freeing UI Memory Leaks)...
:: Kills and restarts the Explorer process to dump cached RAM from the UI
taskkill /F /IM explorer.exe >nul 2>&1
start explorer.exe

echo.
echo =========================================================================
echo [COMPLETE] System Flushed and Memory Reclaimed.
echo Your workspace should now feel instantly lighter and more responsive.
echo =========================================================================
timeout /t 5 >nul
