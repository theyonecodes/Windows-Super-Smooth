Write-Host ""
Write-Host "  ADAPTIVE DEFENDER MONITOR" -ForegroundColor Cyan
Write-Host ""
$lastScan = Get-Date
$cooldown = 30
while ($true) {
    $cpu = (Get-CimInstance Win32_Processor).LoadPercentage
    $proc = (Get-Process | Sort-Object CPU -Descending | Select-Object -First 1).Name
    $ts = Get-Date -Format "HH:mm:ss"
    if ($cpu -gt 60 -and $proc -eq "MsMpEng" -and ((Get-Date) - $lastScan).TotalSeconds -gt $cooldown) {
        Stop-Process -Name MsMpEng -Force -EA SilentlyContinue
        Write-Host "[$ts] PAUSED Defender ($cpu%)" -ForegroundColor Yellow
        $lastScan = Get-Date
    } elseif ($cpu -lt 25 -and $proc -ne "MsMpEng" -and ((Get-Date) - $lastScan).TotalSeconds -gt $cooldown) {
        Start-Process MpCmdRun.exe -EA SilentlyContinue
        Write-Host "[$ts] RESUMED Defender ($cpu%)" -ForegroundColor Green
        $lastScan = Get-Date
    } else {
        Write-Host "[$ts] CPU: $cpu% | Top: $proc" -ForegroundColor Gray
    }
    Start-Sleep -Seconds 10
}