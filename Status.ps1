# SystemCare Live Status
$host.UI.RawUI.WindowTitle = "SystemCare Status"

while ($true) {
    Clear-Host
    $cpu = Get-CimInstance Win32_Processor
    $clock = $cpu.CurrentClockSpeed
    $load = $cpu.LoadPercentage
    $ram = Get-CimInstance Win32_OperatingSystem
    $ramUsed = [math]::Round(($ram.TotalVisibleMemorySize - $ram.FreePhysicalMemory) / 1MB, 1)
    $ramTotal = [math]::Round($ram.TotalVisibleMemorySize / 1MB, 1)
    $ramPct = [math]::Round($ramUsed / $ramTotal * 100, 0)

    $topProc = Get-Process | Sort-Object CPU -Descending | Select-Object -First 1
    $nvApp = Get-Process "NVIDIA App" -EA SilentlyContinue
    $gpu = try { nvidia-smi --query-gpu=temperature.gpu,utilization.gpu --format=csv,noheader 2>$null } catch { "N/A" }

    # Health assessment
    $health = "OPTIMAL"
    $hColor = "Green"
    if ($load -gt 70 -or $clock -lt 2000) { $health = "DEGRADED"; $hColor = "Yellow" }
    if ($load -gt 90 -or $clock -lt 1500) { $health = "CRITICAL"; $hColor = "Red" }

    # CPU bar
    $bar = "[" + ("=" * [math]::Floor($load / 5)) + (" " * (20 - [math]::Floor($load / 5))) + "]"
    $cpuColor = if ($load -gt 80) { "Red" } elseif ($load -gt 50) { "Yellow" } else { "Green" }

    Write-Host ""
    Write-Host "  ==========================================" -ForegroundColor DarkGray
    Write-Host "       SYSTEMCARE - LIVE STATUS" -ForegroundColor Cyan
    Write-Host "  ==========================================" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Health: " -NoNewline -ForegroundColor White
    Write-Host $health -ForegroundColor $hColor
    Write-Host ""
    Write-Host "  CPU:  $load%% $bar $clock MHz" -ForegroundColor $cpuColor
    Write-Host "  RAM:  $ramUsed / $ramTotal GB ($ramPct%%)"
    if ($gpu -ne "N/A") { Write-Host "  GPU:  $gpu" }

    Write-Host ""
    Write-Host "  ------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Top: $($topProc.ProcessName) ($($topProc.CPU) CPU)" -ForegroundColor DarkGray
    if ($nvApp) {
        Write-Host "  NVIDIA App: RUNNING" -ForegroundColor Red
    } else {
        Write-Host "  NVIDIA App: Stopped" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "  ==========================================" -ForegroundColor DarkGray
    Write-Host "  Auto-refreshing every 3 seconds. Ctrl+C to exit." -ForegroundColor DarkGray

    Start-Sleep -Seconds 3
}