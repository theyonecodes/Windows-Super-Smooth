$log = "$env:USERPROFILE\Downloads\cpu-tracker.log"
while ($true) {
    $t = Get-Date -Format "HH:mm:ss"
    $c = Get-CimInstance Win32_Processor
    $l = $c.LoadPercentage
    $m = $c.CurrentClockSpeed
    $p = Get-Process | Sort-Object CPU -Descending | Select-Object -First 1
    $n = $p.Name
    $u = [math]::Round($p.CPU, 1)
    if ($l -gt 70) {
        $a = "$t - PEAK $l% | $m MHz | $n ($u CPU)"
        Write-Host $a -ForegroundColor Red
        Add-Content $log $a -EA SilentlyContinue
    } else {
        $color = if ($l -gt 50) { "Yellow" } else { "Green" }
        Write-Host "`r[$t] CPU: $l% | $m MHz | $n ($u CPU)" -NoNewline -ForegroundColor $color
    }
    Start-Sleep -Seconds 2
}