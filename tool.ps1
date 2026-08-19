Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'SilentlyContinue'

# --- SELF ELEVATION ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $args = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process powershell.exe -Verb RunAs -ArgumentList $args
    exit
}

# --- LOGGING ---
$logPath = Join-Path $env:USERPROFILE 'Downloads\systemcare.log'
function Log($msg) { "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | $msg" | Out-File $logPath -Append }

# --- COLOR SCHEME ---
$bg = [ConsoleColor]::Black
$accent = [ConsoleColor]::Cyan
$dim = [ConsoleColor]::DarkGray
$ok = [ConsoleColor]::Green
$warn = [ConsoleColor]::Yellow
$err = [ConsoleColor]::Red
$title = [ConsoleColor]::Cyan

function Set-Theme {
    [Console]::BackgroundColor = $bg
    [Console]::ForegroundColor = [ConsoleColor]::White
    $host.UI.RawUI.WindowTitle = 'Windows Super Smooth v2.0'
}

function Draw-Header {
    param([string]$Text)
    $w = [Console]::WindowWidth - 2
    $line = '=' * $w
    Write-Host ''
    Write-Host "  $line" -F $dim
    Write-Host "  $($Text.ToUpper())" -F $title
    Write-Host "  $line" -F $dim
    Write-Host ''
}

function Draw-Section {
    param([string]$Text)
    Write-Host "  --- $Text ---" -F $dim
    Write-Host ''
}

function Draw-Menu {
    param([hashtable[]]$Items)
    for ($i = 0; $i -lt $Items.Count; $i++) {
        $item = $Items[$i]
        $num = "[$($i + 1)]"
        Write-Host "  $num " -F $accent -NoNewline
        Write-Host $item.Name -F White -NoNewline
        if ($item.Desc) {
            $pad = 40 - $item.Name.Length - $num.Length
            if ($pad -gt 0) { Write-Host (' ' * $pad) -NoNewline }
            Write-Host " $($item.Desc)" -F $dim
        } else {
            Write-Host ''
        }
    }
    Write-Host ''
    Write-Host "  [0] Back" -F $dim
    Write-Host ''
}

function Do-Choice {
    param([int]$Max)
    Write-Host "  Select: " -F $accent -NoNewline
    $key = [Console]::ReadKey($true)
    Write-Host $key.KeyChar
    $num = 0
    if ([int]::TryParse($key.KeyChar, [ref]$num) -and $num -ge 0 -and $num -le $Max) {
        return $num
    }
    return -1
}

function Run-Task {
    param([string]$Label, [scriptblock]$Code)
    Write-Host "  > $Label" -F $warn -NoNewline
    try {
        & $Code
        Write-Host " [OK]" -F $ok
        Log "OK: $Label"
    } catch {
        Write-Host " [SKIP]" -F $dim
        Log "SKIP: $Label - $($_.Exception.Message)"
    }
}

function Wait-User {
    Write-Host ''
    Write-Host '  Press any key to continue...' -F $dim
    [void][Console]::ReadKey($true)
}

# ============================================
#  SYSTEM INFO
# ============================================
function Show-SystemInfo {
    Clear-Host
    Draw-Header 'SYSTEM INFORMATION'
    
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $ram = Get-CimInstance Win32_OperatingSystem
    $gpu = Get-CimInstance Win32_VideoController | Select-Object -First 1
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
    
    $usedGB = [math]::Round(($ram.TotalVisibleMemorySize - $ram.FreePhysicalMemory) / 1MB, 1)
    $totalGB = [math]::Round($ram.TotalVisibleMemorySize / 1MB, 1)
    $cpuLoad = $cpu.LoadPercentage
    $cpuClock = $cpu.CurrentClockSpeed
    $cpuMax = $cpu.MaxClockSpeed
    $health = 'OPTIMAL'
    $hColor = $ok
    if ($cpuLoad -gt 70 -or $cpuClock -lt ($cpuMax * 0.8)) { $health = 'DEGRADED'; $hColor = $warn }
    if ($cpuLoad -gt 90 -or $cpuClock -lt ($cpuMax * 0.6)) { $health = 'CRITICAL'; $hColor = $err }
    
    $gpuTemp = try { nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader 2>$null } catch { 'N/A' }
    $gpuUtil = try { nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader 2>$null } catch { 'N/A' }
    
    $plan = (powercfg /getactivescheme 2>$null) -replace '.*\((.*)\).*','$1'
    $sysMain = (Get-Service SysMain -EA SilentlyContinue).Status
    
    Write-Host "  Health: " -F White -NoNewline; Write-Host " $health" -F $hColor
    Write-Host ''
    Write-Host "  CPU:     $($cpu.Name)" -F White
    Write-Host "  Clock:   $cpuClock / $cpuMax MHz" -F White
    Write-Host "  Load:    $cpuLoad%" -F $(if ($cpuLoad -gt 80) { $err } elseif ($cpuLoad -gt 50) { $warn } else { $ok })
    Write-Host "  RAM:     $usedGB / $totalGB GB ($([math]::Round($usedGB/$totalGB*100,0))%)" -F White
    Write-Host "  GPU:     $($gpu.Name)" -F White
    if ($gpuTemp -ne 'N/A') {
        Write-Host "  GPU Temp: $gpuTemp C  Util: $gpuUtil" -F White
    }
    Write-Host "  Disk:    $([math]::Round($disk.FreeSpace/1GB,1)) GB free of $([math]::Round($disk.Size/1GB,1)) GB" -F White
    Write-Host ''
    Write-Host "  Power:   $plan" -F $(if ($plan -match 'High') { $ok } else { $warn })
    Write-Host "  SysMain: $sysMain" -F $(if ($sysMain -eq 'Running') { $warn } else { $ok })
    Write-Host "  Thermal: $(
        $vrm = try { (Get-CimInstance MSAcpi_ThermalZoneTemperature -Namespace 'root/wmi' -EA SilentlyContinue | Select-Object -First 1).CurrentTemperature / 10 } catch { 'N/A' }
        if ($vrm -ne 'N/A') { "$([math]::Round($vrm,0)) C" } else { 'N/A (check BIOS)' }
    )" -F White
    Write-Host ''
    Log "SystemInfo: CPU=$cpuLoad% RAM=$usedGB/$totalGB Clock=$cpuClock Health=$health"
    Wait-User
}

# ============================================
#  DEBLOAT - REMOVE BLOATWARE
# ============================================
function Invoke-Debloat {
    Clear-Host
    Draw-Header 'DEBLOAT WINDOWS'
    Write-Host '  Remove pre-installed bloatware and telemetry.' -F $dim
    Write-Host ''
    
    $apps = @(
        'Microsoft.3DBuilder'
        'Microsoft.BingFinance'
        'Microsoft.BingNews'
        'Microsoft.BingSports'
        'Microsoft.BingWeather'
        'Microsoft.GetHelp'
        'Microsoft.Getstarted'
        'Microsoft.MicrosoftSolitaireCollection'
        'Microsoft.People'
        'Microsoft.SkypeApp'
        'Microsoft.MicrosoftOfficeHub'
        'Microsoft.WindowsMaps'
        'Microsoft.WindowsFeedbackHub'
        'Microsoft.ZuneMusic'
        'Microsoft.ZuneVideo'
        'king.com.*'
        'king.com.CandyCrush*'
        'Disney.*'
        'Clipchamp.*'
        'SpotifyAB.SpotifyMusic'
        'Facebook.*'
        'Twitter.*'
        'BytedancePte.Ltd.TikTok*'
        'Disney.365*'
        'MicrosoftTeams'
        'Microsoft.PowerAutomateDesktop'
    )
    
    $count = 0
    foreach ($app in $apps) {
        $pkgs = Get-AppxPackage -Name $app -AllUsers -EA SilentlyContinue
        foreach ($pkg in $pkgs) {
            Write-Host "  Removing $($pkg.Name)..." -F $dim -NoNewline
            Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -EA SilentlyContinue 2>$null
            if ($?) { Write-Host ' [OK]' -F $ok; $count++; Log "Debloat: Removed $($pkg.Name)" }
            else { Write-Host ' [SKIP]' -F $dim }
        }
    }
    
    # Disable provisioning packages
    Get-AppxProvisionedPackage -Online -EA SilentlyContinue | Where-Object {
        $apps | Where-Object { $_.PackageName -like $_ }
    } | ForEach-Object {
        Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -EA SilentlyContinue
        $count++
    }
    
    Write-Host ''
    Write-Host "  Removed $count bloatware packages." -F $ok
    Wait-User
}

# ============================================
#  PERFORMANCE TWEAKS
# ============================================
function Invoke-PerformanceTweaks {
    Clear-Host
    Draw-Header 'PERFORMANCE TWEAKS'
    Write-Host '  Applying permanent performance optimizations...' -F $warn
    Write-Host ''
    
    $n = 0
    
    # Disable services
    Draw-Section 'SERVICES'
    $svcs = @{
        'wuauserv'='Windows Update'
        'bits'='Background Transfer'
        'DiagTrack'='Telemetry'
        'dmwappushservice'='WAP Push'
        'WerSvc'='Error Reporting'
        'Fax'='Fax'
        'Spooler'='Print Spooler'
        'RemoteRegistry'='Remote Registry'
        'MapsBroker'='Maps Manager'
        'SharedAccess'='ICS'
        'lfsvc'='Geolocation'
        'RetailDemo'='Retail Demo'
        'WMPNetworkSvc'='Media Sharing'
        'XblAuthManager'='Xbox Auth'
        'XblGameSave'='Xbox Save'
        'XboxNetApiSvc'='Xbox Network'
        'XboxGipSvc'='Xbox Accessory'
        'BthServ'='Bluetooth'
        'AJRouter'='AllJoyn'
        'NetTcpPortSharing'='Net.TCP'
        'TabletInputService'='Touch Keyboard'
    }
    foreach ($svc in $svcs.GetEnumerator()) {
        $s = Get-Service $svc.Key -EA SilentlyContinue
        if ($s) {
            if ($s.Status -eq 'Running') { Stop-Service $svc.Key -Force -EA SilentlyContinue }
            if ($s.StartType -ne 'Disabled') {
                Set-Service $svc.Key -StartupType Disabled -EA SilentlyContinue
                Write-Host "  Disabled $($svc.Value)" -F $dim
                $n++
            }
        }
    }
    
    # Disable scheduled tasks
    Draw-Section 'SCHEDULED TASKS'
    $tasks = @(
        '\Microsoft\Windows\DiskCleanup\SilentCleanup'
        '\Microsoft\Windows\Defrag\ScheduledDefrag'
        '\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector'
        '\Microsoft\Windows\Customer Experience Improvement Program\Consolidator'
        '\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip'
        '\Microsoft\Windows\Maps\MapsUpdateTask'
        '\Microsoft\Windows\Shell\FamilySafetyMonitor'
        '\Microsoft\Windows\Windows Error Reporting\QueueReporting'
        '\Microsoft\Office\OfficeTelemetryAgentFallBack'
        '\Microsoft\Office\OfficeTelemetryAgentLogOn'
    )
    foreach ($t in $tasks) {
        $parts = $t.Split('/')
        $taskName = $parts[-1]
        $taskPath = ($parts[0..($parts.Count-2)] -join '/') + '/'
        Disable-ScheduledTask -TaskPath $taskPath -TaskName $taskName -EA SilentlyContinue | Out-Null
        if ($?) { Write-Host "  Disabled $taskName" -F $dim; $n++ }
    }
    
    # Registry tweaks
    Draw-Section 'REGISTRY'
    $tweaks = @(
        @('HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters', 'TcpAckFrequency', 1)
        @('HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters', 'TCPNoDelay', 1)
        @('HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters', 'DefaultTTL', 64)
        @('HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters', 'MaxUserPort', 65534)
        @('HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters', 'TcpTimedWaitDelay', 30)
        @('HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters', 'SackOpts', 1)
        @('HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters', 'Tcp1323Opts', 3)
        @('HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem', 'NtfsDisableLastAccessUpdate', 1)
        @('HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem', 'NtfsDisable8dot3NameCreation', 1)
        @('HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem', 'NtfsMemoryUsage', 2)
        @('HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management', 'LargeSystemCache', 0)
        @('HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management', 'DisablePagingExecutive', 1)
        @('HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management', 'ClearPageFileAtShutdown', 0)
        @('HKLM:\SYSTEM\CurrentControlSet\Control\Power', 'HibernateEnabled', 0)
        @('HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl', 'Win32PrioritySeparation', 38)
        @('HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile', 'SystemResponsiveness', 0)
        @('HKCU:\Control Panel\Desktop', 'MenuShowDelay', '0')
        @('HKCU:\Control Panel\Desktop', 'WaitToKillAppTimeout', '2000')
        @('HKCU:\Control Panel\Desktop', 'HungAppTimeout', '1000')
        @('HKCU:\Control Panel\Desktop', 'AutoEndTasks', '1')
        @('HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager', 'SubscribedContent-338389Enabled', 0)
        @('HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager', 'SubscribedContent-338388Enabled', 0)
        @('HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager', 'SoftLandingEnabled', 0)
    )
    foreach ($t in $tweaks) {
        $path = $t[0]; $name = $t[1]; $val = $t[2]
        if (!(Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name $name -Value $val -Type DWord -EA SilentlyContinue
        Write-Host "  Set $name = $val" -F $dim
        $n++
    }
    
    # MMCSS Games profile
    $mmcss = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'
    if (!(Test-Path $mmcss)) { New-Item -Path $mmcss -Force | Out-Null }
    Set-ItemProperty -Path $mmcss -Name 'GPU Priority' -Value 8 -Type DWord -EA SilentlyContinue
    Set-ItemProperty -Path $mmcss -Name 'Priority' -Value 6 -Type DWord -EA SilentlyContinue
    Set-ItemProperty -Path $mmcss -Name 'Scheduling Category' -Value 'High' -Type String -EA SilentlyContinue
    Set-ItemProperty -Path $mmcss -Name 'SFIO Priority' -Value 'High' -Type String -EA SilentlyContinue
    $n += 4
    
    # Disable memory compression
    Write-Host ''
    Write-Host '  Disabling memory compression...' -F $dim -NoNewline
    Disable-MMAgent -MemoryCompression -EA SilentlyContinue
    Get-Process 'Memory Compression' -EA SilentlyContinue | Stop-Process -Force -EA SilentlyContinue
    $n++; Write-Host ' [OK]' -F $ok
    
    # Disable power throttling
    Write-Host '  Disabling power throttling...' -F $dim -NoNewline
    $tp = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling'
    if (!(Test-Path $tp)) { New-Item -Path $tp -Force | Out-Null }
    Set-ItemProperty -Path $tp -Name 'PowerThrottlingOff' -Value 1 -Type DWord -EA SilentlyContinue
    $n++; Write-Host ' [OK]' -F $ok
    
    # Power plan
    Write-Host '  Setting High Performance plan...' -F $dim -NoNewline
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
    powercfg /change monitor-timeout-ac 0 2>$null
    powercfg /change standby-timeout-ac 0 2>$null
    powercfg /change hibernate-timeout-ac 0 2>$null
    powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PERFBOOSTMODE 2 2>$null
    powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PERFBOOSTPOL 100 2>$null
    powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 4876c0e8-2c04-4ce8-b5ac-2b30b084b0ed 0 2>$null
    powercfg /setactive SCHEME_CURRENT 2>$null
    $n++; Write-Host ' [OK]' -F $ok
    
    # Network
    Draw-Section 'NETWORK'
    netsh int tcp set global autotuninglevel=normal 2>$null
    netsh int tcp set global chimney=enabled 2>$null
    netsh int tcp set global dca=enabled 2>$null
    netsh int tcp set global netdma=enabled 2>$null
    netsh int tcp set global timestamps=disabled 2>$null
    netsh int tcp set global rss=enabled 2>$null
    $n += 6; Write-Host '  TCP stack optimized' -F $dim
    
    # Flush
    ipconfig /flushdns 2>$null | Out-Null
    $n++
    
    Write-Host ''
    Write-Host "  Applied $n optimizations." -F $ok
    Log "PerfTweaks: Applied $n tweaks"
    Wait-User
}

# ============================================
#  GAMING MODE
# ============================================
function Invoke-GamingMode {
    Clear-Host
    Draw-Header 'GAMING MODE'
    Write-Host '  Optimizing for maximum gaming performance...' -F $warn
    Write-Host ''
    
    # Kill background processes
    Draw-Section 'KILLING BACKGROUND PROCESSES'
    $hogs = @('NVIDIA App','OneDrive','Teams','Discord','EpicGamesLauncher','Steam','Spotify','Chrome','Edge','Firefox')
    foreach ($h in $hogs) {
        Get-Process $h -EA SilentlyContinue | ForEach-Object {
            Write-Host "  Stopping $($_.ProcessName)..." -F $dim -NoNewline
            Stop-Process $_ -Force -EA SilentlyContinue
            Write-Host ' [OK]' -F $ok
        }
    }
    
    # Gaming registry tweaks
    Draw-Section 'GAMING REGISTRY'
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' -Name 'SystemResponsiveness' -Value 0 -Type DWord -EA SilentlyContinue
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' -Name 'GPU Priority' -Value 8 -Type DWord -EA SilentlyContinue
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' -Name 'Priority' -Value 6 -Type DWord -EA SilentlyContinue
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' -Name 'SFIO Priority' -Value 'High' -Type String -EA SilentlyContinue
    Write-Host '  MMCSS tuned for gaming' -F $dim
    
    # Disable GameBar and GameDVR
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR' -Name 'AppCaptureEnabled' -Value 0 -Type DWord -EA SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_Enabled' -Value 0 -Type DWord -EA SilentlyContinue
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' -Name 'AllowGameDVR' -Value 0 -Type DWord -EA SilentlyContinue
    Write-Host '  GameBar/GameDVR disabled' -F $dim
    
    # NVIDIA max performance
    $nvidiaSmi = 'C:\Windows\System32\nvidia-smi.exe'
    if (Test-Path $nvidiaSmi) {
        & $nvidiaSmi -pl 100 2>$null
        Write-Host '  NVIDIA set to max power' -F $dim
    }
    
    # Power plan
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
    powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PERFBOOSTMODE 2 2>$null
    powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PERFBOOSTPOL 100 2>$null
    powercfg /setactive SCHEME_CURRENT 2>$null
    Write-Host '  High Performance power plan' -F $dim
    
    # Set process priority
    $gameExes = @('cs2','dota2','fortnite','valorant','gta5','r5apex','cod')
    foreach ($exe in $gameExes) {
        Get-Process $exe -EA SilentlyContinue | ForEach-Object {
            $_.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
            Write-Host "  Set $exe to High priority" -F $dim
        }
    }
    
    # Flush DNS and RAM
    ipconfig /flushdns 2>$null | Out-Null
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    Write-Host '  Flushed DNS and garbage collected' -F $dim
    
    Write-Host ''
    Write-Host '  Gaming mode active. Launch your game now.' -F $ok
    Log "GamingMode: Activated"
    Wait-User
}

# ============================================
#  PRIVACY
# ============================================
function Invoke-PrivacyTweaks {
    Clear-Host
    Draw-Header 'PRIVACY'
    Write-Host '  Disabling telemetry and tracking...' -F $warn
    Write-Host ''
    
    $n = 0
    
    # Disable telemetry
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowTelemetry' -Value 0 -Type DWord -EA SilentlyContinue
    Stop-Service DiagTrack -Force -EA SilentlyContinue
    Set-Service DiagTrack -StartupType Disabled -EA SilentlyContinue
    Stop-Service dmwappushservice -Force -EA SilentlyContinue
    Set-Service dmwappushservice -StartupType Disabled -EA SilentlyContinue
    Write-Host '  Telemetry disabled' -F $dim; $n += 3
    
    # Disable advertising ID
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo' -Name 'Enabled' -Value 0 -Type DWord -EA SilentlyContinue
    Write-Host '  Advertising ID disabled' -F $dim; $n++
    
    # Disable location tracking
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' -Name 'DisableLocation' -Value 1 -Type DWord -EA SilentlyContinue
    Stop-Service lfsvc -Force -EA SilentlyContinue
    Set-Service lfsvc -StartupType Disabled -EA SilentlyContinue
    Write-Host '  Location tracking disabled' -F $dim; $n += 2
    
    # Disable Cortana
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'AllowCortana' -Value 0 -Type DWord -EA SilentlyContinue
    Write-Host '  Cortana disabled' -F $dim; $n++
    
    # Disable activity history
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'EnableActivityFeed' -Value 0 -Type DWord -EA SilentlyContinue
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'PublishUserActivities' -Value 0 -Type DWord -EA SilentlyContinue
    Write-Host '  Activity history disabled' -F $dim; $n += 2
    
    # Disable tips and suggestions
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-338389Enabled' -Value 0 -Type DWord -EA SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-338388Enabled' -Value 0 -Type DWord -EA SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-310093Enabled' -Value 0 -Type DWord -EA SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SoftLandingEnabled' -Value 0 -Type DWord -EA SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowSyncProviderNotifications' -Value 0 -Type DWord -EA SilentlyContinue
    Write-Host '  Tips and suggestions disabled' -F $dim; $n += 5
    
    # Disable feedback
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Siuf\Rules' -Name 'NumberOfSIUFInPeriod' -Value 0 -Type DWord -EA SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Siuf\Rules' -Name 'PeriodInNanoSeconds' -Value 0 -Type DWord -EA SilentlyContinue
    Write-Host '  Feedback prompts disabled' -F $dim; $n += 2
    
    # Disable error reporting
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting' -Name 'Disabled' -Value 1 -Type DWord -EA SilentlyContinue
    Stop-Service WerSvc -Force -EA SilentlyContinue
    Set-Service WerSvc -StartupType Disabled -EA SilentlyContinue
    Write-Host '  Error reporting disabled' -F $dim; $n += 2
    
    Write-Host ''
    Write-Host "  Applied $n privacy tweaks." -F $ok
    Log "Privacy: Applied $n tweaks"
    Wait-User
}

# ============================================
#  MAINTENANCE
# ============================================
function Invoke-Maintenance {
    Clear-Host
    Draw-Header 'MAINTENANCE'
    Write-Host '  Cleaning and refreshing system...' -F $warn
    Write-Host ''
    
    # Flush DNS
    Write-Host '  Flushing DNS cache...' -F $dim -NoNewline
    ipconfig /flushdns 2>$null | Out-Null
    Clear-DnsClientCache -EA SilentlyContinue
    Write-Host ' [OK]' -F $ok
    
    # Clean temp files
    Write-Host '  Cleaning temp files...' -F $dim -NoNewline
    $tempFolders = @($env:TEMP, 'C:\Windows\Temp', 'C:\Windows\Prefetch')
    $freed = 0
    foreach ($f in $tempFolders) {
        if (Test-Path $f) {
            $size = (Get-ChildItem $f -Recurse -EA SilentlyContinue | Measure-Object Length -Sum).Sum
            Remove-Item "$f\*" -Recurse -Force -EA SilentlyContinue
            $freed += $size
        }
    }
    Write-Host " [OK] Freed $([math]::Round($freed/1MB,1)) MB" -F $ok
    
    # Reset Windows Update cache
    Write-Host '  Resetting Windows Update cache...' -F $dim -NoNewline
    Stop-Service wuauserv -Force -EA SilentlyContinue
    Remove-Item 'C:\Windows\SoftwareDistribution\Download' -Recurse -Force -EA SilentlyContinue
    Start-Service wuauserv -EA SilentlyContinue
    Write-Host ' [OK]' -F $ok
    
    # Clear event logs
    Write-Host '  Clearing event logs...' -F $dim -NoNewline
    wevtutil el | ForEach-Object { wevtutil cl $_ 2>$null }
    Write-Host ' [OK]' -F $ok
    
    # Rebuild icon cache
    Write-Host '  Rebuilding icon cache...' -F $dim -NoNewline
    Stop-Process -Name explorer -Force -EA SilentlyContinue
    Remove-Item "$env:LOCALAPPDATA\IconCache.db" -Force -EA SilentlyContinue
    Start-Process explorer.exe
    Write-Host ' [OK]' -F $ok
    
    # RAM cleanup
    Write-Host '  Running garbage collection...' -F $dim -NoNewline
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    Write-Host ' [OK]' -F $ok
    
    # Restart BITS
    Restart-Service BITS -EA SilentlyContinue
    
    Write-Host ''
    Write-Host '  System cleaned and refreshed.' -F $ok
    Log "Maintenance: Cleaned system"
    Wait-User
}

# ============================================
#  UNINSTALLER
# ============================================
function Invoke-Uninstaller {
    Clear-Host
    Draw-Header 'UNINSTALL BLOATWARE'
    Write-Host '  Select packages to remove:' -F $dim
    Write-Host ''
    
    $apps = Get-AppxPackage | Where-Object { $_.Name -notmatch 'Microsoft.Windows计算器|Microsoft.WindowsTerminal|Microsoft.WindowsStore|Microsoft.Windows.Photos|Microsoft.WindowsCamera|Microsoft.ScreenSketch|Microsoft.WindowsAlarms|Microsoft.WindowsStickyNotes|Microsoft.WindowsSoundRecorder|Microsoft.WindowsNotepad|Microsoft.Paint|Windows.ClientCBS' } | Sort-Object Name
    
    for ($i = 0; $i -lt [Math]::Min($apps.Count, 30); $i++) {
        Write-Host "  [$($i+1)] $($apps[$i].Name)" -F White
    }
    Write-Host ''
    Write-Host "  [A] Remove ALL listed" -F $warn
    Write-Host "  [0] Back" -F $dim
    Write-Host ''
    
    $choice = Do-Choice -Max $apps.Count
    if ($choice -eq 0) { return }
    if ($choice -eq -1 -and $key.KeyChar -eq 'a') {
        foreach ($app in $apps) {
            Remove-AppxPackage -Package $app.PackageFullName -AllUsers -EA SilentlyContinue 2>$null
            Write-Host "  Removed $($app.Name)" -F $dim
        }
        Log "Uninstaller: Removed all bloatware"
    } elseif ($choice -gt 0 -and $choice -le $apps.Count) {
        $app = $apps[$choice - 1]
        Remove-AppxPackage -Package $app.PackageFullName -AllUsers -EA SilentlyContinue 2>$null
        Write-Host "  Removed $($app.Name)" -F $ok
        Log "Uninstaller: Removed $($app.Name)"
    }
    Wait-User
}

# ============================================
#  MAIN MENU
# ============================================
Set-Theme
Log "Launched Windows Super Smooth v2.0"

while ($true) {
    Clear-Host
    $w = [Console]::WindowWidth - 2
    $line = '=' * $w
    
    Write-Host ''
    Write-Host "  $line" -F $dim
    Write-Host '  WINDOWS SUPER SMOOTH v2.0' -F $title
    Write-Host "  For old machines that need a boost" -F $dim
    Write-Host "  $line" -F $dim
    Write-Host ''
    
    $menu = @(
        @{ Name = 'System Info'; Desc = 'CPU, RAM, GPU, health status' }
        @{ Name = 'Performance Tweaks'; Desc = 'Services, registry, network' }
        @{ Name = 'Debloat'; Desc = 'Remove bloatware' }
        @{ Name = 'Gaming Mode'; Desc = 'Max FPS, kill hogs' }
        @{ Name = 'Privacy'; Desc = 'Disable telemetry' }
        @{ Name = 'Maintenance'; Desc = 'Clean temp, flush DNS' }
        @{ Name = 'Start AutoPilot'; Desc = 'Background monitor' }
    )
    
    Draw-Menu -Items $menu
    Write-Host "  [S] Shutdown PC" -F $dim
    Write-Host "  [R] Restart PC" -F $dim
    Write-Host "  [X] Exit" -F $dim
    Write-Host ''
    
    Write-Host "  Select: " -F $accent -NoNewline
    $key = [Console]::ReadKey($true)
    $ch = $key.KeyChar.ToString().ToLower()
    Write-Host $ch
    
    switch ($ch) {
        '1' { Show-SystemInfo }
        '2' { Invoke-PerformanceTweaks }
        '3' { Invoke-Debloat }
        '4' { Invoke-GamingMode }
        '5' { Invoke-PrivacyTweaks }
        '6' { Invoke-Maintenance }
        '7' {
            $enginePath = Join-Path $env:TEMP 'sc\engine.ps1'
            if (Test-Path $enginePath) {
                Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$enginePath`""
                Write-Host '  AutoPilot started in new window.' -F $ok
            } else {
                Write-Host '  Engine not found. Run from main menu first.' -F $err
            }
            Start-Sleep -Seconds 2
        }
        's' { Stop-Computer -Force }
        'r' { Restart-Computer -Force }
        'x' { exit }
    }
}
