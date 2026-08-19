@echo off
setlocal EnableDelayedExpansion

net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Create temp scripts at runtime
if not exist "%TEMP%\sc" mkdir "%TEMP%\sc"

:MAIN
cls
echo.
echo   ==========================================
echo         SYSTEMCARE AUTOPILOT
echo   ==========================================
echo.
echo   [1] Start AutoPilot
echo   [2] Live Status
echo   [3] View Log
echo   [0] Exit
echo.
echo   ==========================================
echo.
choice /c 120 /n /m "  Select: "
set "s=%errorlevel%"
if %s%==1 goto RUN
if %s%==2 goto STATUS
if %s%==3 goto LOG
if %s%==4 goto EXIT
goto MAIN

:RUN
echo Creating engine...
(
echo $log = "$env:USERPROFILE\Downloads\systemcare.log"
echo Write-Host ""
echo Write-Host "  ==========================================" -F Cyan
echo Write-Host "       AUTOPILOT ACTIVE" -F Cyan
echo Write-Host "  ==========================================" -F Cyan
echo Write-Host ""
echo Write-Host "  Monitoring every 30 seconds..." -F Gray
echo Write-Host "  Press Ctrl+C to stop." -F Gray
echo Write-Host ""
echo $n = 0
echo while^($true^) {
echo $n++
echo $c = ^(Get-CimInstance Win32_Processor^).LoadPercentage
echo $m = ^(Get-CimInstance Win32_Processor^).CurrentClockSpeed
echo $r = Get-CimInstance Win32_OperatingSystem
echo $rp = [math]::Round^(\(($r.TotalVisibleMemorySize - $r.FreePhysicalMemory\) / $r.TotalVisibleMemorySize\) * 100, 0^)
echo $t = Get-Process ^| Sort-Object CPU -Descending ^| Select-Object -First 1
echo $ts = Get-Date -Format "HH:mm:ss"
echo $issue = $false
echo if ^($c -gt 70^) { $issue = $true }
echo if ^($m -lt 2000^) { $issue = $true }
echo if ^($rp -gt 85^) { $issue = $true }
echo Get-Process "NVIDIA App" -EA SilentlyContinue ^| Stop-Process -Force -EA SilentlyContinue
echo $plan = powercfg /getactivescheme 2^>$null
echo if ^($plan -notmatch "8c5e7fda"^) { powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2^>$null }
echo $sm = Get-Service SysMain -EA SilentlyContinue
echo if ^($sm.Status -eq "Running"^) { Stop-Service SysMain -Force -EA SilentlyContinue; Set-Service SysMain -StartupType Disabled -EA SilentlyContinue }
echo if ^($n %% 10 -eq 0^) { ipconfig /flushdns ^| Out-Null }
echo Get-Process ^| Where-Object { $_.CPU -gt 150 -and $_.ProcessName -notin @("OpenCode","dwm","System","svchost","explorer"^) } ^| Stop-Process -Force -EA SilentlyContinue
echo if ^($issue^) {
echo Write-Host "[$ts] FIXING | CPU: $c%% | $m MHz | RAM: $rp%%" -F Yellow
echo "$ts | FIXING | CPU: $c%% | $m MHz | RAM: $rp%%" ^| Out-File $log -Append
echo } else {
echo Write-Host "[$ts] OK | CPU: $c%% | $m MHz | RAM: $rp%%" -F Green
echo "$ts | OK | CPU: $c%% | $m MHz | RAM: $rp%%" ^| Out-File $log -Append
echo }
echo Sleep 30
echo }
) > "%TEMP%\sc\engine.ps1"
start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%TEMP%\sc\engine.ps1"
echo.
echo   AutoPilot started!
echo.
pause
goto MAIN

:STATUS
echo Creating status view...
(
echo while^($true^) {
echo $c = Get-CimInstance Win32_Processor
echo $l = $c.LoadPercentage
echo $m = $c.CurrentClockSpeed
echo $r = Get-CimInstance Win32_OperatingSystem
echo $u = [math]::Round^\(($r.TotalVisibleMemorySize - $r.FreePhysicalMemory\) / 1MB, 1^\)
echo $t = [math]::Round^\($r.TotalVisibleMemorySize / 1MB, 1^\)
echo $p = [math]::Round^\($u / $t * 100, 0^\)
echo $tp = Get-Process ^| Sort-Object CPU -Descending ^| Select-Object -First 1
echo $nv = Get-Process "NVIDIA App" -EA SilentlyContinue
echo $g = try { nvidia-smi --query-gpu=temperature.gpu,utilization.gpu --format=csv,noheader 2^>$null } catch { "N/A" }
echo $h = "OPTIMAL"; $hc = "Green"
echo if ^($l -gt 70 -or $m -lt 2000^) { $h = "DEGRADED"; $hc = "Yellow" }
echo if ^($l -gt 90 -or $m -lt 1500^) { $h = "CRITICAL"; $hc = "Red" }
echo $b = "[" + ^("="#" * [math]::Floor\($l / 5\)^) + ^(" " * ^(^20 - [math]::Floor\($l / 5\)^)^) + "]"
echo $cc = if ^($l -gt 80^) { "Red" } elseif ^($l -gt 50^) { "Yellow" } else { "Green" }
echo Write-Host ""
echo Write-Host "  ==========================================" -F DarkGray
echo Write-Host "       SYSTEMCARE - LIVE STATUS" -F Cyan
echo Write-Host "  ==========================================" -F DarkGray
echo Write-Host ""
echo Write-Host "  Health: " -NoNewline -F White; Write-Host $h -F $hc
echo Write-Host ""
echo Write-Host "  CPU:  $l%% $b $m MHz" -F $cc
echo Write-Host "  RAM:  $u / $t GB ($p%%)"
echo if ^($g -ne "N/A"^) { Write-Host "  GPU:  $g" }
echo Write-Host ""
echo Write-Host "  ------------------------------------------" -F DarkGray
echo Write-Host "  Top: $($tp.ProcessName) ($($tp.CPU) CPU)" -F DarkGray
echo if ^($nv^) { Write-Host "  NVIDIA App: RUNNING" -F Red } else { Write-Host "  NVIDIA App: Off" -F Green }
echo Write-Host ""
echo Write-Host "  ==========================================" -F DarkGray
echo Write-Host "  Refreshing in 3s. Ctrl+C to exit." -F DarkGray
echo Start-Sleep -Seconds 3
echo cls
echo }
) > "%TEMP%\sc\status.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "%TEMP%\sc\status.ps1"
goto MAIN

:LOG
cls
echo.
echo   ==========================================
echo         ACTIVITY LOG
echo   ==========================================
echo.
set "lf=%USERPROFILE%\Downloads\systemcare.log"
if exist "%lf%" (
    powershell -NoProfile -Command "Get-Content '%lf%' -Tail 20 | ForEach-Object {Write-Host ('  ' + $_)}"
) else (
    echo   No activity yet.
)
echo.
pause
goto MAIN

:EXIT
exit /b