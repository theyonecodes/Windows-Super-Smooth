@echo off
title SystemCare - All-in-One System Tool
mode con cols=72 lines=42
color 0F
setlocal EnableDelayedExpansion

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo  Requesting admin privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:MAINMENU
cls
echo.
echo  ============================================
echo         SYSTEMCARE - SYSTEM TOOL
echo  ============================================
echo.
echo   [1] Quick Status
echo   [2] Fix System Lag
echo   [3] NVIDIA Cleanup
echo   [4] Windows 11 Optimize
echo   [5] Defenders
echo   [6] Advanced
echo   [7] Diagnostics
echo   [8] System Flush (Maintenance)
echo   [9] Kernel Deep Tune (Super Smooth)
echo.
echo   [0] Exit
echo.
echo  ============================================
echo.
choice /c 1234567890 /n /m "  Select: "
set "sel=%errorlevel%"
if %sel%==1 goto QUICKSTATUS
if %sel%==2 goto FIXLAG
if %sel%==3 goto NVIDIA
if %sel%==4 goto WIN11
if %sel%==5 goto DEFENDERS
if %sel%==6 goto ADVANCED
if %sel%==7 goto DIAG
if %sel%==8 goto FLUSH
if %sel%==9 goto KERNEL
if %sel%==10 goto EXIT
goto MAINMENU
:QUICKSTATUS
cls
echo.
echo  ============================================
echo           QUICK STATUS
echo  ============================================
echo.
powershell -NoProfile -Command "Get-CimInstance Win32_Processor | ForEach-Object { Write-Host ('   CPU: ' + $_.CurrentClockSpeed + ' MHz Load: ' + $_.LoadPercentage + '%%') }"
powershell -NoProfile -Command "try { nvidia-smi --query-gpu=temperature.gpu,utilization.gpu,power.draw --format=csv,noheader 2>$null | ForEach-Object { Write-Host ('   GPU: ' + $_) } } catch {}"
powershell -NoProfile -Command "$r=Get-CimInstance Win32_OperatingSystem;$u=[math]::Round(($r.TotalVisibleMemorySize-$r.FreePhysicalMemory)/1MB,1);$t=[math]::Round($r.TotalVisibleMemorySize/1MB,1);$p=[math]::Round($u/$t*100,0);Write-Host ('   RAM: ' + $u + ' / ' + $t + ' GB (' + $p + '%%)')"
echo.
echo   TOP 10 CPU PROCESSES:
powershell -NoProfile -Command "Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 -Property @{N='Process';E={$_.Name}},@{N='CPU';E={[math]::Round($_.CPU,1)}},@{N='MB';E={[math]::Round($_.WorkingSet64/1MB,0)}} | Format-Table -AutoSize | Out-String -Width 58" 2>nul
echo.
pause
goto MAINMENU

:FIXLAG
cls
echo.
echo  ============================================
echo           FIXING SYSTEM LAG
echo  ============================================
echo.
echo   [1/13] High Performance power plan...
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
echo   [2/13] CPU minimum 100...
powercfg /change processor-minimum-state-percentage 100 >nul 2>&1
echo   [3/13] Disabling SysMain...
powershell -NoProfile -Command "Stop-Service SysMain -Force -EA SilentlyContinue;Set-Service SysMain -StartupType Disabled" >nul 2>&1
echo   [4/13] Disabling spike tasks...
powershell -NoProfile -Command "Disable-ScheduledTask -TaskName 'Microsoft Compatibility Appraiser Exp' -EA SilentlyContinue;Disable-ScheduledTask -TaskName 'Microsoft-Windows-DiskDiagnosticDataCollector' -EA SilentlyContinue;Disable-ScheduledTask -TaskName 'WsSwapAssessmentTask' -EA SilentlyContinue;Disable-ScheduledTask -TaskName 'ProcessMemoryDiagnosticEvents' -EA SilentlyContinue" >nul 2>&1
echo   [5/13] Killing NVIDIA App...
powershell -NoProfile -Command "Get-Process 'NVIDIA App' -EA SilentlyContinue | Stop-Process -Force" >nul 2>&1
echo   [6/13] Disabling NVIDIA FrameView...
powershell -NoProfile -Command "Stop-Service FvSvc -Force -EA SilentlyContinue;Set-Service FvSvc -StartupType Disabled" >nul 2>&1
echo   [7/13] Disabling Game Mode...
reg add "HKCU\Software\Microsoft\GameBar" /v AllowAutoGameMode /t REG_DWORD /d 0 /f >nul 2>&1
echo   [8/13] Disabling Game DVR...
reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v AppCaptureEnabled /t REG_DWORD /d 0 /f >nul 2>&1
echo   [9/13] Disabling Delivery Optimization...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v DODownloadMode /t REG_DWORD /d 0 /f >nul 2>&1
echo   [10/13] Disabling Search Indexer...
powershell -NoProfile -Command "Stop-Service WSearch -Force -EA SilentlyContinue;Set-Service WSearch -StartupType Disabled" >nul 2>&1
echo   [11/13] Disabling Print Spooler...
powershell -NoProfile -Command "Stop-Service Spooler -Force -EA SilentlyContinue;Set-Service Spooler -StartupType Disabled" >nul 2>&1
echo   [12/13] Disabling transparency...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f >nul 2>&1
echo   [13/13] Best performance visuals...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f >nul 2>&1
echo.
echo  ============================================
echo   ALL LAG FIXES APPLIED!
echo  ============================================
echo.
pause
goto MAINMENU

:NVIDIA
cls
echo.
echo  ============================================
echo           NVIDIA CLEANUP
echo  ============================================
echo.
echo   [1] Kill NVIDIA App
echo   [2] Stop NVIDIA services
echo   [3] Clean NVIDIA cache
echo   [4] All of the above
echo   [0] Back
echo.
choice /c 12340 /n /m "  Select: "
set "nvsel=%errorlevel%"
if %nvsel%==1 (
    powershell -NoProfile -Command "Get-Process 'NVIDIA App' -EA SilentlyContinue | Stop-Process -Force" >nul 2>&1
    echo   Done.
)
if %nvsel%==2 (
    powershell -NoProfile -Command "Stop-Service FvSvc -Force -EA SilentlyContinue;Set-Service FvSvc -StartupType Disabled" >nul 2>&1
    echo   Done.
)
if %nvsel%==3 (
    if exist "%LOCALAPPDATA%\NVIDIA\DXCache" rd /s /q "%LOCALAPPDATA%\NVIDIA\DXCache" >nul 2>&1
    if exist "%LOCALAPPDATA%\NVIDIA\GLCache" rd /s /q "%LOCALAPPDATA%\NVIDIA\GLCache" >nul 2>&1
    if exist "%LOCALAPPDATA%\NVIDIA\ComputeCache" rd /s /q "%LOCALAPPDATA%\NVIDIA\ComputeCache" >nul 2>&1
    echo   Done.
)
if %nvsel%==4 (
    powershell -NoProfile -Command "Get-Process 'NVIDIA App' -EA SilentlyContinue | Stop-Process -Force" >nul 2>&1
    powershell -NoProfile -Command "Stop-Service FvSvc -Force -EA SilentlyContinue;Set-Service FvSvc -StartupType Disabled" >nul 2>&1
    if exist "%LOCALAPPDATA%\NVIDIA\DXCache" rd /s /q "%LOCALAPPDATA%\NVIDIA\DXCache" >nul 2>&1
    if exist "%LOCALAPPDATA%\NVIDIA\GLCache" rd /s /q "%LOCALAPPDATA%\NVIDIA\GLCache" >nul 2>&1
    if exist "%LOCALAPPDATA%\NVIDIA\ComputeCache" rd /s /q "%LOCALAPPDATA%\NVIDIA\ComputeCache" >nul 2>&1
    echo   Done.
)
if %nvsel%==5 goto MAINMENU
echo.
pause
goto NVIDIA

:WIN11
cls
echo.
echo  ============================================
echo         WINDOWS 11 DEEP OPTIMIZE
echo  ============================================
echo.
echo   [1] Disable Telemetry
echo   [2] Disable Widgets
echo   [3] Disable Copilot
echo   [4] Disable Mouse Trails
echo   [5] All of the above
echo   [0] Back
echo.
choice /c 123450 /n /m "  Select: "
set "wsel=%errorlevel%"
if %wsel%==1 (
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f >nul 2>&1
    echo   Done.
)
if %wsel%==2 (
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v AllowNewsAndInterests /t REG_DWORD /d 0 /f >nul 2>&1
    echo   Done.
)
if %wsel%==3 (
    reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f >nul 2>&1
    echo   Done.
)
if %wsel%==4 (
    reg add "HKCU\Control Panel\Desktop" /v MouseTrails /t REG_SZ /d 0 /f >nul 2>&1
    echo   Done.
)
if %wsel%==5 (
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v AllowNewsAndInterests /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKCU\Control Panel\Desktop" /v MouseTrails /t REG_SZ /d 0 /f >nul 2>&1
    echo   Done.
)
if %wsel%==6 goto MAINMENU
echo.
pause
goto WIN11

:DEFENDERS
cls
echo.
echo  ============================================
echo           DEFENDERS
echo  ============================================
echo.
echo   [1] Stop Defender real-time
echo   [2] Start Defender real-time
echo   [3] Adaptive Monitor (separate window)
echo   [4] Add exclusion: Downloads
echo   [5] Check Defender status
echo   [0] Back
echo.
choice /c 123450 /n /m "  Select: "
set "dsel=%errorlevel%"
if %dsel%==1 (
    powershell -NoProfile -Command "Set-MpPreference -DisableRealtimeMonitoring True" >nul 2>&1
    echo   Done.
)
if %dsel%==2 (
    powershell -NoProfile -Command "Set-MpPreference -DisableRealtimeMonitoring False" >nul 2>&1
    echo   Done.
)
if %dsel%==3 (
    start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0DefenderMonitor.ps1"
    echo   Monitor opened in new window.
)
if %dsel%==4 (
    powershell -NoProfile -Command "Add-MpPreference -ExclusionPath '%USERPROFILE%\Downloads'" >nul 2>&1
    echo   Done.
)
if %dsel%==5 (
    powershell -NoProfile -Command "Get-MpPreference | Select-Object DisableRealtimeMonitoring,ExclusionPath | Format-List"
)
if %dsel%==6 goto MAINMENU
echo.
pause
goto DEFENDERS

:ADVANCED
cls
echo.
echo  ============================================
echo           ADVANCED
echo  ============================================
echo.
echo   [1] Kill all NVIDIA processes
echo   [2] Disable all spike tasks
echo   [3] Set power plan High Performance
echo   [4] Disable all services (Safe)
echo   [5] EXTREME PERFORMANCE (Everything)
echo   [0] Back
echo.
choice /c 123450 /n /m "  Select: "
set "asel=%errorlevel%"
if %asel%==1 (
    powershell -NoProfile -Command "Get-Process | Where-Object {$_.Name -like '*nvidia*' -or $_.Name -like '*nv*'} | Stop-Process -Force -EA SilentlyContinue" >nul 2>&1
    echo   Done.
)
if %asel%==2 (
    powershell -NoProfile -Command "Disable-ScheduledTask -TaskName 'Microsoft Compatibility Appraiser Exp' -EA SilentlyContinue;Disable-ScheduledTask -TaskName 'Microsoft-Windows-DiskDiagnosticDataCollector' -EA SilentlyContinue;Disable-ScheduledTask -TaskName 'WsSwapAssessmentTask' -EA SilentlyContinue;Disable-ScheduledTask -TaskName 'ProcessMemoryDiagnosticEvents' -EA SilentlyContinue" >nul 2>&1
    echo   Done.
)
if %asel%==3 (
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
    powercfg /change processor-minimum-state-percentage 100 >nul 2>&1
    echo   Done.
)
if %asel%==4 (
    powershell -NoProfile -Command "Stop-Service SysMain -Force -EA SilentlyContinue;Set-Service SysMain -StartupType Disabled;Stop-Service WSearch -Force -EA SilentlyContinue;Set-Service WSearch -StartupType Disabled;Stop-Service Spooler -Force -EA SilentlyContinue;Set-Service Spooler -StartupType Disabled;Stop-Service FvSvc -Force -EA SilentlyContinue;Set-Service FvSvc -StartupType Disabled" >nul 2>&1
    echo   Done.
)
if %asel%==5 goto EXTREME
if %asel%==6 goto MAINMENU
echo.
pause
goto ADVANCED

:EXTREME
cls
echo.
echo  ============================================
echo     APPLYING EXTREME PERFORMANCE
echo  ============================================
echo.
echo   [1/13] Power plan...
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
echo   [2/13] CPU min 100...
powercfg /change processor-minimum-state-percentage 100 >nul 2>&1
echo   [3/13] SysMain...
powershell -NoProfile -Command "Stop-Service SysMain -Force -EA SilentlyContinue;Set-Service SysMain -StartupType Disabled" >nul 2>&1
echo   [4/13] Spike tasks...
powershell -NoProfile -Command "Disable-ScheduledTask -TaskName 'Microsoft Compatibility Appraiser Exp' -EA SilentlyContinue;Disable-ScheduledTask -TaskName 'Microsoft-Windows-DiskDiagnosticDataCollector' -EA SilentlyContinue;Disable-ScheduledTask -TaskName 'WsSwapAssessmentTask' -EA SilentlyContinue;Disable-ScheduledTask -TaskName 'ProcessMemoryDiagnosticEvents' -EA SilentlyContinue" >nul 2>&1
echo   [5/13] NVIDIA App...
powershell -NoProfile -Command "Get-Process 'NVIDIA App' -EA SilentlyContinue | Stop-Process -Force" >nul 2>&1
echo   [6/13] FrameView...
powershell -NoProfile -Command "Stop-Service FvSvc -Force -EA SilentlyContinue;Set-Service FvSvc -StartupType Disabled" >nul 2>&1
echo   [7/13] Game Mode...
reg add "HKCU\Software\Microsoft\GameBar" /v AllowAutoGameMode /t REG_DWORD /d 0 /f >nul 2>&1
echo   [8/13] Game DVR...
reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v AppCaptureEnabled /t REG_DWORD /d 0 /f >nul 2>&1
echo   [9/13] Transparency...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f >nul 2>&1
echo   [10/13] Visual effects...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f >nul 2>&1
echo   [11/13] Mouse trails...
reg add "HKCU\Control Panel\Desktop" /v MouseTrails /t REG_SZ /d 0 /f >nul 2>&1
echo   [12/13] Search Indexer...
powershell -NoProfile -Command "Stop-Service WSearch -Force -EA SilentlyContinue;Set-Service WSearch -StartupType Disabled" >nul 2>&1
echo   [13/13] Print Spooler...
powershell -NoProfile -Command "Stop-Service Spooler -Force -EA SilentlyContinue;Set-Service Spooler -StartupType Disabled" >nul 2>&1
echo.
echo  ============================================
echo   ALL 13 FIXES APPLIED!
echo  ============================================
echo.
pause
goto MAINMENU

:DIAG
cls
echo.
echo  ============================================
echo       DIAGNOSTICS - FIND CULPRIT
echo  ============================================
echo.
echo   [1] Quick Snapshot
echo   [2] CPU Tracker (Live)
echo   [3] Full Diagnostic
echo   [4] View Log
echo   [0] Back
echo.
choice /c 12340 /n /m "  Select: "
set "dsel=%errorlevel%"
if %dsel%==1 goto DIAGSNAP
if %dsel%==2 goto DIAGTRACK
if %dsel%==3 goto DIAGFULL
if %dsel%==4 goto DIAGLOG
if %dsel%==5 goto MAINMENU
goto DIAG

:DIAGSNAP
cls
echo.
echo  ============================================
echo           QUICK SNAPSHOT
echo  ============================================
echo.
powershell -NoProfile -Command "Get-CimInstance Win32_Processor | ForEach-Object { Write-Host ('   CPU: ' + $_.CurrentClockSpeed + ' MHz Load: ' + $_.LoadPercentage + '%%') }"
powershell -NoProfile -Command "try { nvidia-smi --query-gpu=temperature.gpu,utilization.gpu,power.draw --format=csv,noheader 2>$null | ForEach-Object { Write-Host ('   GPU: ' + $_) } } catch {}"
powershell -NoProfile -Command "$r=Get-CimInstance Win32_OperatingSystem;$u=[math]::Round(($r.TotalVisibleMemorySize-$r.FreePhysicalMemory)/1MB,1);$t=[math]::Round($r.TotalVisibleMemorySize/1MB,1);$p=[math]::Round($u/$t*100,0);Write-Host ('   RAM: ' + $u + ' / ' + $t + ' GB (' + $p + '%%)')"
echo.
echo   TOP 10 CPU PROCESSES:
powershell -NoProfile -Command "Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 -Property @{N='Process';E={$_.Name}},@{N='CPU';E={[math]::Round($_.CPU,1)}},@{N='MB';E={[math]::Round($_.WorkingSet64/1MB,0)}} | Format-Table -AutoSize | Out-String -Width 58" 2>nul
echo.
echo   DISK I/O:
powershell -NoProfile -Command "try{$c=Get-Counter '\PhysicalDisk(_Total)\Disk Bytes/sec' -EA 1;$mb=[math]::Round($c.CounterSamples.CookedValue/1MB,2);Write-Host ('   ' + $mb + ' MB/s')}catch{Write-Host '   N/A'}"
echo.
pause
goto DIAG

:DIAGTRACK
cls
echo.
echo  ============================================
echo         CPU TRACKER - LIVE
echo  ============================================
echo.
echo   Monitoring every 2 seconds...
echo   Press Ctrl+C to stop.
echo.
powershell -NoProfile -File "%~dp0CpuTracker.ps1"
goto DIAG

:DIAGFULL
cls
echo.
echo  ============================================
echo         FULL DIAGNOSTIC
echo  ============================================
echo.
echo   [1/7] CPU Analysis...
powershell -NoProfile -Command "$c=Get-CimInstance Win32_Processor;Write-Host ('        Load: ' + $c.LoadPercentage + '%% | Clock: ' + $c.CurrentClockSpeed + ' MHz');if($c.CurrentClockSpeed -lt 2000){Write-Host '        WARNING: Thermal throttling!' -F Red}else{Write-Host '        Clock normal' -F Green}"
echo.
echo   [2/7] Top CPU Consumers...
powershell -NoProfile -Command "Get-Process | Sort-Object CPU -Desc | Select-Object -First 5 -Property @{N='Process';E={$_.Name}},@{N='CPU';E={[math]::Round($_.CPU,1)}},@{N='MB';E={[math]::Round($_.WorkingSet64/1MB,0)}} | Format-Table -AutoSize | Out-String -Width 58" 2>nul
echo.
echo   [3/7] Top Memory Consumers...
powershell -NoProfile -Command "Get-Process | Sort-Object WorkingSet64 -Desc | Select-Object -First 5 -Property @{N='Process';E={$_.Name}},@{N='MB';E={[math]::Round($_.WorkingSet64/1MB,0)}} | Format-Table -AutoSize | Out-String -Width 58" 2>nul
echo.
echo   [4/7] Disk Activity...
powershell -NoProfile -Command "try{$c=Get-Counter '\PhysicalDisk(_Total)\Disk Bytes/sec','\PhysicalDisk(_Total)\%% Disk Time' -EA 1;$io=[math]::Round($c.CounterSamples[0].CookedValue/1MB,2);$dt=[math]::Round($c.CounterSamples[1].CookedValue,1);Write-Host ('        I/O: ' + $io + ' MB/s | Disk Time: ' + $dt + '%%')}catch{Write-Host '        N/A'}"
echo.
echo   [5/7] Heavy Services...
powershell -NoProfile -Command "Get-Process svchost -EA SilentlyContinue | Sort-Object CPU -Desc | Select-Object -First 3 -Property @{N='PID';E={$_.Id}},@{N='CPU';E={[math]::Round($_.CPU,1)}},@{N='MB';E={[math]::Round($_.WorkingSet64/1MB,0)}} | Format-Table -AutoSize | Out-String -Width 58" 2>nul
echo.
echo   [6/7] Network...
powershell -NoProfile -Command "Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1 | ForEach-Object { Write-Host ('        ' + $_.Name + ': ' + $_.LinkSpeed) }"
echo.
echo   [7/7] Analysis...
powershell -NoProfile -Command "$i=@();$c=Get-CimInstance Win32_Processor;if($c.LoadPercentage -gt 80){$i+='HIGH CPU: Check top consumers'};if($c.CurrentClockSpeed -lt 2000){$i+='THERMAL THROTTLING'};$r=Get-CimInstance Win32_OperatingSystem;$p=[math]::Round((($r.TotalVisibleMemorySize-$r.FreePhysicalMemory)/$r.TotalVisibleMemorySize)*100,0);if($p -gt 80){$i+='HIGH RAM'};if(Get-Process 'NVIDIA App' -EA SilentlyContinue){$i+='NVIDIA APP running'};if((Get-Service SysMain -EA SilentlyContinue).Status -eq 'Running'){$i+='SYSMAIN running'};if($i.Count -eq 0){Write-Host '        No issues detected' -F Green}else{$i | ForEach-Object {Write-Host ('        ' + $_) -F Yellow}}"
echo.
pause
goto DIAG

:DIAGLOG
cls
echo.
echo  ============================================
echo            VIEW LOG
echo  ============================================
echo.
set "logfile=%USERPROFILE%\Downloads\cpu-tracker.log"
if exist "%logfile%" (
    echo   Last 10 alerts:
    powershell -NoProfile -Command "Get-Content '%logfile%' -Tail 10 | ForEach-Object {Write-Host ('  ' + $_)}"
) else (
    echo   No log found. Run CPU Tracker first.
)
echo.
pause
goto DIAG

:FLUSH
cls
echo.
echo  ============================================
echo         SYSTEM FLUSH (MAINTENANCE)
echo  ============================================
echo.
echo  Run this when system feels "heavy" or slow.
echo.
echo   [1/4] Flushing DNS Resolver Cache...
ipconfig /flushdns >nul 2>&1
echo   [2/4] Purging temp files...
del /q /f /s "%TEMP%\*" >nul 2>&1
del /q /f /s "C:\Windows\Temp\*" >nul 2>&1
echo   [3/4] Clearing Windows Update cache...
net stop wuauserv >nul 2>&1
del /q /f /s "C:\Windows\SoftwareDistribution\Download\*" >nul 2>&1
net start wuauserv >nul 2>&1
echo   [4/4] Resetting Windows Shell...
taskkill /F /IM explorer.exe >nul 2>&1
start explorer.exe
echo.
echo  ============================================
echo   SYSTEM FLUSHED AND MEMORY RECLAIMED!
echo  ============================================
echo.
pause
goto MAINMENU

:KERNEL
cls
echo.
echo  ============================================
echo     KERNEL DEEP TUNE (SUPER SMOOTH)
echo  ============================================
echo.
echo  WARNING: This modifies kernel parameters.
echo  Create a restore point first (Main menu option not shown).
echo.
choice /c YN /n /m "  Continue? (Y/N): "
if %errorlevel%==2 goto MAINMENU

echo.
echo  [1/7] Kernel and Memory Subsystem Tuning...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "DisablePagingExecutive" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "LargeSystemCache" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "IoPageLockLimit" /t REG_DWORD /d 536870912 /f >nul
fsutil behavior set disablelastaccess 1 >nul 2>&1
powercfg -h off >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v "PowerThrottlingOff" /t REG_DWORD /d 1 /f >nul
echo   Done.

echo   [2/7] Disabling VBS and Hypervisor Security...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /t REG_DWORD /d 0 /f >nul
echo   Done.

echo   [3/7] CPU Scheduling and MMCSS Tuning...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" /t REG_DWORD /d 4294967295 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d 38 /f >nul
echo   Done.

echo   [4/7] Ultimate Power and GPU Pipeline...
powercfg -duplicatescheme 99999999-9999-9999-9999-9999-999999999999 >nul 2>&1
powercfg /setactive 99999999-9999-9999-9999-9999-999999999999 >nul
reg add "HKCU\Software\Microsoft\GameBar" /v "AllowAutoGameMode" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "HwSchMode" /t REG_DWORD /d 2 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Scheduler" /v "EnablePreemption" /t REG_DWORD /d 0 /f >nul
echo   Done.

echo   [5/7] Network Stack Unshackling...
powershell -NoProfile -Command "Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object { $regPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\' + $_.InterfaceGuid; if (Test-Path $regPath) { New-ItemProperty -Path $regPath -Name 'TcpAckFrequency' -PropertyType DWORD -Value 1 -Force | Out-Null; New-ItemProperty -Path $regPath -Name 'TCPNoDelay' -PropertyType DWORD -Value 1 -Force | Out-Null } }"
echo   Done.

echo   [6/7] Telemetry and UWP Lockdown...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v "GlobalUserDisabled" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\Software\Policies\Microsoft\Windows\AppPrivacy" /v "LetAppsRunInBackground" /t REG_DWORD /d 2 /f >nul
sc config "DiagTrack" start= disabled >nul 2>&1
sc stop "DiagTrack" >nul 2>&1
sc config "dmwappushservice" start= disabled >nul 2>&1
sc stop "dmwappushservice" >nul 2>&1
sc config "SysMain" start= disabled >nul 2>&1
sc stop "SysMain" >nul 2>&1
powershell -NoProfile -Command "Get-ScheduledTask | Where-Object { $_.TaskPath -match 'Microsoft\\Windows\\Application Experience' -or $_.TaskPath -match 'Microsoft\\Windows\\Customer Experience Improvement Program' } | Disable-ScheduledTask -ErrorAction SilentlyContinue"
echo   Done.

echo   [7/7] UI Optimizations...
reg add "HKCU\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d "0" /f >nul
echo   Done.

echo.
echo  ============================================
echo   KERNEL DEEP TUNE APPLIED!
echo   RESTART REQUIRED for changes to take effect.
echo  ============================================
echo.
pause
goto MAINMENU

:SYSINFO
cls
echo.
echo  ============================================
echo           SYSTEM INFO
echo  ============================================
echo.
powershell -NoProfile -Command "$cpu=Get-CimInstance Win32_Processor;Write-Host '  CPU:';Write-Host ('    ' + $cpu.Name);Write-Host ('    ' + $cpu.CurrentClockSpeed + ' MHz');Write-Host ('    ' + $cpu.NumberOfCores + ' cores / ' + $cpu.NumberOfLogicalProcessors + ' threads');Write-Host '';Write-Host '  GPU:';try{$g=nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader 2>$null;Write-Host ('    ' + $g)}catch{Write-Host '    N/A'};Write-Host '';Write-Host '  RAM:';$r=Get-CimInstance Win32_PhysicalMemory;$t=($r | Measure-Object -Property Capacity -Sum).Sum/1GB;Write-Host ('    ' + $t + ' GB (' + $r.Count + ' DIMMs)');Write-Host '';Write-Host '  DISKS:';Get-PhysicalDisk | ForEach-Object {Write-Host ('    ' + $_.FriendlyName + ' (' + [math]::Round($_.Size/1GB,0) + ' GB) - ' + $_.HealthStatus)};Write-Host '';Write-Host '  MOTHERBOARD:';Get-CimInstance Win32_BaseBoard | ForEach-Object {Write-Host ('    ' + $_.Manufacturer + ' ' + $_.Product)};Write-Host '';Write-Host '  BIOS:';Get-CimInstance Win32_BIOS | ForEach-Object {Write-Host ('    ' + $_.SMBIOSBIOSVersion)}"
echo.
pause
goto MAINMENU

:EXIT
cls
echo.
echo  ============================================
echo           GOODBYE!
echo  ============================================
echo.
timeout /t 2 >nul
exit /b
