@echo off
:: =========================================================================
:: 🚀 WINDOWS SUPER SMOOTH - ADVANCED ONE-TIME SETUP
:: WARNING: This utilizes deep kernel scheduling, MMCSS tuning, and 
:: disables Virtualization-Based Security (VBS) for absolute peak performance.
:: =========================================================================
title Windows Super Smooth - Setup
echo [!] Verifying Administrator Privileges...
net session >nul 2>&1
if %errorLevel% NEQ 0 ( echo [ERROR] Run as Administrator. & pause & exit /b )

echo.
echo [1/7] Bare-Metal Kernel ^& Memory Subsystem Tuning...
:: 1. Force Kernel to remain in RAM (Disable Paging Executive)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "DisablePagingExecutive" /t REG_DWORD /d 1 /f >nul
:: 2. Enable Large System Cache (Prioritizes File System Cache over background apps)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "LargeSystemCache" /t REG_DWORD /d 1 /f >nul
:: 3. Maximize I/O Page Lock Limit (512MB Buffer for massive code builds)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "IoPageLockLimit" /t REG_DWORD /d 536870912 /f >nul
:: 4. Disable NTFS Last Access Time
fsutil behavior set disablelastaccess 1 >nul
:: 5. Disable Kernel Hibernation (Frees up massive disk space and IO)
powercfg -h off >nul
:: 6. Disable Power Throttling globally
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v "PowerThrottlingOff" /t REG_DWORD /d 1 /f >nul
echo [OK] Kernel pinned to RAM, Cache maximized, and hibernation disabled.

echo.
echo [2/7] The Unshackling: Disabling VBS ^& Hypervisor Security Overhead...
:: Disables Memory Integrity (HVCI) and Virtualization-Based Security to reclaim 10-15%% CPU performance
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /t REG_DWORD /d 0 /f >nul
echo [OK] VBS/HVCI Security Overhead Removed. CPU has direct metal access.

echo.
echo [3/7] CPU Scheduling ^& MMCSS Tuning...
:: 1. System Responsiveness: 0 (Allocates 100%% CPU to active apps, 0%% reserved for background)
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d 0 /f >nul
:: 2. Network Throttling Index: ffffffff (Disables network throttling)
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" /t REG_DWORD /d 4294967295 /f >nul
:: 3. Win32PrioritySeparation: 38 Decimal (Optimizes thread quanta for short foreground bursts)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d 38 /f >nul
echo [OK] Thread scheduler and MMCSS prioritized for foreground.

echo.
echo [4/7] Ultimate Power ^& GPU Pipeline...
powercfg -duplicatescheme 99999999-9999-9999-9999-9999-999999999999 >nul 2>&1
powercfg /setactive 99999999-9999-9999-9999-9999-999999999999 >nul
reg add "HKCU\Software\Microsoft\GameBar" /v "AllowAutoGameMode" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "HwSchMode" /t REG_DWORD /d 2 /f >nul
:: Disable Preemption (Advanced GPU scheduling reduction of latency)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Scheduler" /v "EnablePreemption" /t REG_DWORD /d 0 /f >nul
echo [OK] Power states locked and GPU preemption disabled.

echo.
echo [5/7] Network Stack Unshackling (TCP NoDelay / AckFrequency)...
powershell -NoProfile -Command "Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object { $regPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\' + $_.InterfaceGuid; if (Test-Path $regPath) { New-ItemProperty -Path $regPath -Name 'TcpAckFrequency' -PropertyType DWORD -Value 1 -Force | Out-Null; New-ItemProperty -Path $regPath -Name 'TCPNoDelay' -PropertyType DWORD -Value 1 -Force | Out-Null } }"
echo [OK] Nagle's Algorithm bypassed.

echo.
echo [6/7] Scorched-Earth Telemetry ^& Universal App Lockdown...
:: Global freeze on all background Universal Apps (UWP)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Software\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsRunInBackground" /t REG_DWORD /d 2 /f >nul
:: Stop specific services
sc config "DiagTrack" start= disabled >nul 2>&1
sc stop "DiagTrack" >nul 2>&1
sc config "dmwappushservice" start= disabled >nul 2>&1
sc stop "dmwappushservice" >nul 2>&1
sc config "SysMain" start= disabled >nul 2>&1
sc stop "SysMain" >nul 2>&1
:: Disabling Scheduled Tasks across the board for Telemetry/Experience
powershell -NoProfile -Command "Get-ScheduledTask | Where-Object { $_.TaskPath -match 'Microsoft\\Windows\\Application Experience' -or $_.TaskPath -match 'Microsoft\\Windows\\Customer Experience Improvement Program' } | Disable-ScheduledTask -ErrorAction SilentlyContinue"
echo [OK] Background noise eradicated and UWP apps frozen.

echo.
echo [7/7] Visuals ^& UI Explorer Optimizations...
:: Disable 400ms artificial menu delay
reg add "HKCU\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d "0" /f >nul
echo [OK] UI delays removed.

echo.
echo =========================================================================
echo [COMPLETE] BARE-METAL ONE-TIME SETUP APPLIED.
echo You must RESTART your computer to initialize the VBS shutdown, 
echo large system cache, new kernel parameters, and network stack.
echo =========================================================================
pause
