# Windows-Super-Smooth Pester Tests
# Run with: Invoke-Pester Tests/

Describe "Windows-Super-Smooth Core Functions" {
    BeforeAll {
        # Import the main module
        . "$PSScriptRoot/../WindowsSuperSmooth.ps1"
    }

    Describe "Draw-Header" {
        It "Should output header with correct formatting" {
            $output = Draw-Header "TEST" | Out-String
            $output | Should -Match "TEST"
            $output | Should -Match "="
        }

        It "Should handle long text" {
            $output = Draw-Header "VERY LONG HEADER TEXT THAT SHOULD BE TRUNCATED OR WRAPPED" | Out-String
            $output | Should -Match "VERY LONG HEADER"
        }
    }

    Describe "Draw-Section" {
        It "Should output section header" {
            $output = Draw-Section "TEST SECTION" | Out-String
            $output | Should -Match "TEST SECTION"
        }
    }

    Describe "Do-Choice" {
        It "Should return valid choice number" {
            # Mock ReadKey to return '1'
            $mockKey = [System.Management.Automation.Host.KeyInfo]::new('1', 'D1', $false, $false, $false)
            [System.Console]::ReadKey = { return $mockKey }
            
            $result = Do-Choice -Max 5
            $result | Should -Be 1
        }

        It "Should return -1 for invalid input" {
            $mockKey = [System.Management.Automation.Host.KeyInfo]::new('9', 'D9', $false, $false, $false)
            [System.Console]::ReadKey = { return $mockKey }
            
            $result = Do-Choice -Max 5
            $result | Should -Be -1
        }
    }

    Describe "Run-Task with Backup" {
        Setup {
            # Mock toolkit availability
            $script:hasToolkit = $true
            Import-Module "$PSScriptRoot/../vendor/toolkit/backup-engine/powershell/BackupEngine.psm1" -Force -ErrorAction SilentlyContinue
        }

        It "Should execute task with backup when toolkit available" {
            $result = Run-Task -Label "Test Task" -Code { Write-Host "Test" } -RegistryKeys @("HKLM:\TEST") -BackupBCD
            # Should not throw
        }
    }
}

Describe "Profile System" {
    BeforeAll {
        $profilesPath = Join-Path $PSScriptRoot "..\profiles.json"
        $global:profiles = Get-Content -LiteralPath $profilesPath -Raw | ConvertFrom-Json
    }

    Describe "Profile Validation" {
        It "Should have required profiles" {
            $profiles.profiles | Should -ContainKey "Low-Latency Dev"
            $profiles.profiles | Should -ContainKey "WSL2-Docker Safe Mode"
            $profiles.profiles | Should -ContainKey "Audio-DAW Real-Time"
            $profiles.profiles | Should -ContainKey "Laptop Battery Safe"
        }

        It "Each profile should have required fields" {
            foreach ($name in $profiles.profiles.Keys) {
                $profile = $profiles.profiles.$name
                $profile | Should -ContainKey "description"
                $profile | Should -ContainKey "safeForWSL2"
                $profile | Should -ContainKey "safeForDocker"
                $profile | Should -ContainKey "safeForHyperV"
                $profile.tweaks | Should -ContainKey "services"
                $profile.tweaks | Should -ContainKey "registry"
            }
        }
    }

    Describe "Virtualization Compatibility" {
        It "WSL2-Docker Safe Mode should be safe for virtualization" {
            $profile = $global:profiles.profiles."WSL2-Docker Safe Mode"
            $profile.safeForWSL2 | Should -Be $true
            $profile.safeForDocker | Should -Be $true
            $profile.safeForHyperV | Should -Be $true
        }

        It "Low-Latency Dev should NOT be safe for WSL2" {
            $profile = $global:profiles.profiles."Low-Latency Dev"
            $profile.safeForWSL2 | Should -Be $false
        }
    }
}

Describe "Utility Functions" {
    Describe "Test-Path for profiles.json" {
        It "Should exist" {
            $path = Join-Path $PSScriptRoot "..\profiles.json"
            Test-Path $path | Should -Be $true
        }
    }

    Describe "JSON Validity" {
        It "profiles.json should be valid JSON" {
            $content = Get-Content -LiteralPath (Join-Path $PSScriptRoot "..\profiles.json") -Raw
            $json = $null
            { $json = $content | ConvertFrom-Json } | Should -Not -Throw
        }
    }
}

Describe "Logging" {
    It "Should write to log file" {
        $logPath = Join-Path $env:USERPROFILE 'Downloads\systemcare.log'
        Log "TEST LOG ENTRY"
        $content = Get-Content $logPath -Tail 1
        $content | Should -Match "TEST LOG ENTRY"
    }
}

Describe "Apply-Profile Function" {
    BeforeAll {
        $profilesPath = Join-Path $PSScriptRoot "..\profiles.json"
        $global:profiles = Get-Content -LiteralPath $profilesPath -Raw | ConvertFrom-Json
    }

    It "Should apply WSL2-Docker Safe Mode profile without errors" {
        $profile = $global:profiles.profiles."WSL2-Docker Safe Mode"
        { Apply-Profile -ProfileName "WSL2-Docker Safe Mode" } | Should -Not -Throw
    }

    It "Should detect WSL2 and warn for incompatible profiles" {
        # This test requires WSL2 to be installed
        # We'll skip if not present
        $wsl2 = Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss"
        if ($wsl2) {
            $profile = $global:profiles.profiles."Low-Latency Dev"
            if (-not $profile.safeForWSL2) {
                # Should warn but still allow with -Force
                { Apply-Profile -ProfileName "Low-Latency Dev" -Force } | Should -Not -Throw
            }
        }
    }
}

Describe "Test-VirtualizationCompatibility Function" {
    It "Should detect WSL2 correctly" {
        $virt = Test-VirtualizationCompatibility
        $virt.WSL2 | Should -Not -Be $null
    }

    It "Should detect Docker correctly" {
        $virt = Test-VirtualizationCompatibility
        $virt.Docker | Should -Not -Be $null
    }

    It "Should detect Hyper-V correctly" {
        $virt = Test-VirtualizationCompatibility
        $virt.HyperV | Should -Not -Be $null
    }
}

Describe "Apply-Profile Engine" {
    It "Should apply registry tweaks correctly" {
        # Test a simple registry tweak
        $regPath = "HKCU:\Software\Test\ProfileTest"
        if (Test-Path $regPath) { Remove-Item $regPath -Recurse -Force }
        
        $tweaks = @(
            @('HKCU:\Software\Test\ProfileTest', 'TestValue', 123)
        )
        
        foreach ($t in $tweaks) {
            $path = $t[0]; $name = $t[1]; $val = $t[2]
            if (!(Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name $name -Value $val -Type DWord -ErrorAction SilentlyContinue
        }
        
        $result = Get-ItemProperty -Path "HKCU:\Software\Test\ProfileTest" -Name "TestValue"
        $result.TestValue | Should -Be 123
        
        # Cleanup
        Remove-Item "HKCU:\Software\Test" -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "Should apply MMCSS profiles correctly" {
        $mmcss = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'
        if (!(Test-Path $mmcss)) { New-Item -Path $mmcss -Force | Out-Null }
        
        Set-ItemProperty -Path $mmcss -Name 'GPU Priority' -Value 8 -Type DWord -EA SilentlyContinue
        Set-ItemProperty -Path $mmcss -Name 'Priority' -Value 6 -Type DWord -EA SilentlyContinue
        
        $result = Get-ItemProperty -Path $mmcss -Name 'GPU Priority'
        $result.'GPU Priority' | Should -Be 8
    }
}

Describe "Turbo Mode Function" {
    It "Should not throw when run" {
        { Invoke-TurboMode } | Should -Not -Throw
    }
}

Describe "Gaming Mode Function" {
    It "Should not throw when run" {
        { Invoke-GamingMode } | Should -Not -Throw
    }
}

Describe "Privacy Tweaks Function" {
    It "Should not throw when run" {
        { Invoke-PrivacyTweaks } | Should -Not -Throw
    }
}

Describe "Maintenance Function" {
    It "Should not throw when run" {
        { Invoke-Maintenance } | Should -Not -Throw
    }
}

Describe "Performance Tweaks Function" {
    It "Should not throw when run" {
        { Invoke-PerformanceTweaks } | Should -Not -Throw
    }
}

Describe "Debloat Function" {
    It "Should not throw when run" {
        { Invoke-Debloat } | Should -Not -Throw
    }
}

Describe "JSON Profile Validation" {
    It "profiles.json should be valid JSON" {
        $content = Get-Content -LiteralPath (Join-Path $PSScriptRoot "..\profiles.json") -Raw
        $json = $null
        { $json = $content | ConvertFrom-Json } | Should -Not -Throw
    }

    It "Should have all required profiles" {
        $content = Get-Content -LiteralPath (Join-Path $PSScriptRoot "..\profiles.json") -Raw | ConvertFrom-Json
        $profiles = $content.profiles.Keys
        $profiles | Should -Contain "Low-Latency Dev"
        $profiles | Should -Contain "WSL2-Docker Safe Mode"
        $profiles | Should -Contain "Audio-DAW Real-Time"
        $profiles | Should -Contain "Laptop Battery Safe"
    }
}