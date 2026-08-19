# SystemCare AutoPilot - Intelligent System Manager
$logFile = "$env:USERPROFILE\Downloads\systemcare.log"
$scanCount = 0

function Write-Log($msg) {
    $ts = Get-Date -Format "HH:mm:ss"
    "$ts | $msg" | Out-File -FilePath $logFile -Append -Encoding ASCII
    Write-Host "[$ts] $msg" -ForegroundColor Gray
}

function Optimize-System {
    # 1. Kill resource hogs
    $hogs = Get-Process | Where-Object { $_.CPU -gt 150 -and $_.ProcessName -notin @("OpenCode","dwm","System","svchost","explorer") }
    foreach ($hog in $hogs) {
        Write-Log "Killing hog: $($hog.ProcessName) ($([math]::Round($hog.CPU,0)) CPU)"
        Stop-Process -Id $hog.Id -Force -EA SilentlyContinue
    }

    # 2. Kill NVIDIA App
    Get-Process "NVIDIA App" -EA SilentlyContinue | ForEach-Object {
        Write-Log "Killing NVIDIA App"
        Stop-Process -Id $_.Id -Force -EA SilentlyContinue
    }

    # 3. Ensure high performance
    $currentPlan = powercfg /getactivescheme 2>$null
    if ($currentPlan -notmatch "8c5e7fda") {
        powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
        Write-Log "Set High Performance power plan"
    }

    # 4. Ensure SysMain is off
    $sysmain = Get-Service SysMain -EA SilentlyContinue
    if ($sysmain.Status -eq "Running") {
        Stop-Service SysMain -Force -EA SilentlyContinue
        Set-Service SysMain -StartupType Disabled -EA SilentlyContinue
        Write-Log "Disabled SysMain"
    }

    # 5. Flush DNS periodically
    if ($scanCount % 10 -eq 0) {
        ipconfig /flushdns | Out-Null
        Write-Log "Flushed DNS cache"
    }
}

function Get-SystemHealth {
    $cpu = (Get-CimInstance Win32_Processor).LoadPercentage
    $clock = (Get-CimInstance Win32_Processor).CurrentClockSpeed
    $ram = Get-CimInstance Win32_OperatingSystem
    $ramPct = [math]::Round((($ram.TotalVisibleMemorySize - $ram.FreePhysicalMemory) / $ram.TotalVisibleMemorySize) * 100, 0)
    $topProc = (Get-Process | Sort-Object CPU -Descending | Select-Object -First 1)

    $health = "GOOD"
    $issues = @()

    if ($cpu -gt 70) { $health = "DEGRADED"; $issues += "High CPU" }
    if ($clock -lt 2000) { $health = "CRITICAL"; $issues += "Throttled" }
    if ($ramPct -gt 85) { $health = "DEGRADED"; $issues += "High RAM" }

    return @{
        CPU = $cpu
        Clock = $clock
        RAM = $ramPct
        TopProc = $topProc.ProcessName
        TopCPU = [math]::Round($topProc.CPU, 0)
        Health = $health
        Issues = $issues
    }
}

# Main loop
Write-Log "=========================================="
Write-Log "AUTOPILOT ENGINE STARTED"
Write-Log "=========================================="

while ($true) {
    $scanCount++
    $health = Get-SystemHealth

    if ($health.Issues.Count -gt 0) {
        Write-Log "ISSUES: $($health.Issues -join ', ') | CPU: $($health.CPU)%% | $($health.TopProc)"
        Optimize-System
    } else {
        Write-Log "HEALTHY | CPU: $($health.CPU)%% | Clock: $($health.Clock) MHz | RAM: $($health.RAM)%%"
    }

    Start-Sleep -Seconds 30
}