# Agent Instructions - Windows-Super-Smooth

## Repository Overview

**Name**: Windows-Super-Smooth
**Type**: PowerShell kernel orchestration suite for Windows optimization
**Primary Language**: PowerShell 5.1+, Python 3.11+ (GUI)
**Package Manager**: PowerShell modules, pip

## Architecture Overview

```
Windows-Super-Smooth/
├── WindowsSuperSmooth.ps1     # Main orchestration script (52 KB)
├── WindowsSuperSmoothGUI.py   # Tkinter GUI (30 KB, TO BE MIGRATED)
├── profiles.json              # Declarative tuning profiles (NEW)
├── SECURITY.md                # Security policy
├── LICENSE                    # MIT License
├── profiles/
│   ├── Low-Latency Dev.json
│   ├── WSL2-Docker Safe Mode.json
│   ├── Audio-DAW Real-Time.json
│   └── Laptop Battery Safe.json
├── .github/workflows/ci.yml   # CI pipeline
└── README.md
```

## Architecture - Profile System (NEW)

```json
{
  "profiles": {
    "Low-Latency Dev": { "safeForWSL2": false, "safeForDocker": false, "tweaks": {...} },
    "WSL2-Docker Safe Mode": { "safeForWSL2": true, "safeForDocker": true, "tweaks": {...} },
    "Audio-DAW Real-Time": { "safeForWSL2": false, "safeForDocker": false, "tweaks": {...} },
    "Laptop Battery Safe": { "safeForWSL2": true, "safeForDocker": true, "tweaks": {...} }
  },
  "profileSelection": {
    "autoDetectWSL2": true,
    "autoDetectDocker": true,
    "autoDetectHyperV": true,
    "warnOnIncompatible": true,
    "defaultProfile": "WSL2-Docker Safe Mode"
  }
}
```

## Key Components

| Component | Path | Description |
|-----------|------|-------------|
| Main Orchestration | WindowsSuperSmooth.ps1 | 52 KB PowerShell script with backup/rollback |
| GUI | WindowsSuperSmoothGUI.py | Tkinter GUI (30 KB, TO BE MIGRATED) |
| Profiles | profiles.json | 4 declarative tuning profiles |
| BackupEngine | toolkit/backup-engine/powershell/ | Shared backup/rollback module |

## Development Commands

```bash
# Run main script (elevated)
powershell -NoProfile -ExecutionPolicy Bypass -File WindowsSuperSmooth.ps1

# Run GUI
python WindowsSuperSmoothGUI.py

# Run CI validation
powershell -NoProfile -ExecutionPolicy Bypass -File .github/workflows/ci.ps1

# Apply profile
powershell -NoProfile -ExecutionPolicy Bypass -File WindowsSuperSmooth.ps1 -Profile "WSL2-Docker Safe Mode"
```

## Code Style & Conventions

- **PowerShell**: PSScriptAnalyzer, strict mode, backup/rollback on all changes
- **Python**: ruff for lint/formatting (when GUI migrated)
- **JSON Profiles**: Declarative, versioned, with compatibility metadata
- **Commit Messages**: Conventional Commits

## Profile System Invariants (Non-Negotiable)

1. **Mandatory Checkpoint**: EVERY operation MUST create System Restore Point + BCD export first
2. **WSL2/Docker Safety**: Profiles MUST declare `safeForWSL2`, `safeForDocker`, `safeForHyperV`
3. **Auto-Detection**: MUST auto-detect WSL2/Docker/Hyper-V and warn on incompatible profiles
4. **Declarative Profiles**: All tweaks in JSON, NOT hardcoded in PowerShell
5. **Rollback**: Every tweak MUST be reversible via BackupEngine

## CI/CD Pipeline

- **Provider**: GitHub Actions (`.github/workflows/ci.yml`)
- **Jobs**: PSScriptAnalyzer, ruff (Python), profile validation
- **Artifacts**: Profile validation reports

## Security Considerations

- **Checkpoint Mandatory**: System Restore Point + BCD export BEFORE any kernel/registry changes
- **WSL2/Docker Safe Mode**: Default profile, preserves virtualization
- **Admin Required**: All operations require elevation with UAC
- **BackupEngine**: All changes backed up with rollback capability

## Architecture Invariants (Non-Negotiable)

1. **Checkpoint-Computer + bcdedit /export**: MUST run before ANY kernel/registry tweaks
2. **Profile Compatibility**: MUST check WSL2/Docker/Hyper-V and warn/block incompatible profiles
3. **Declarative Tweaks**: All registry/BCD/service tweaks in JSON, NOT hardcoded
4. **BackupEngine Integration**: Every change via Invoke-WithBackup with rollback

## Common Tasks

### Applying a Profile
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File WindowsSuperSmooth.ps1 -Profile "WSL2-Docker Safe Mode"
```

### Running GUI
```bash
python WindowsSuperSmoothGUI.py
```

### Running CI Validation
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .github/workflows/ci.ps1
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| WSL2 breaks after tweaks | Use "WSL2-Docker Safe Mode" profile |
| Docker fails to start | Ensure profile has `safeForDocker: true` |
| Hyper-V fails | Ensure profile has `safeForHyperV: true` |
| No restore point created | Run as Administrator, check System Protection enabled |

## Useful Links

- **Repo**: `https://github.com/theyonecodes/Windows-Super-Smooth`
- **Issues**: `https://github.com/theyonecodes/Windows-Super-Smooth/issues`
- **CI**: `https://github.com/theyonecodes/Windows-Super-Smooth/actions`
- **Security**: `https://github.com/theyonecodes/Windows-Super-Smooth/security/advisories`