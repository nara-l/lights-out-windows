[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptPath = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "LightsOut.ps1"
$cases = @(
    @{ At = "2026-08-02 21:29"; Expected = "Open" },
    @{ At = "2026-08-02 21:30"; Expected = "Countdown" },
    @{ At = "2026-08-02 21:58"; Expected = "Countdown" },
    @{ At = "2026-08-02 21:59"; Expected = "Blocked" },
    @{ At = "2026-08-03 05:59"; Expected = "Blocked" },
    @{ At = "2026-08-03 06:00"; Expected = "Open" },
    @{ At = "2026-08-03 11:29"; Expected = "Open" },
    @{ At = "2026-08-03 11:30"; Expected = "Countdown" },
    @{ At = "2026-08-03 11:44"; Expected = "Countdown" },
    @{ At = "2026-08-03 11:45"; Expected = "Blocked" },
    @{ At = "2026-08-03 13:29"; Expected = "Blocked" },
    @{ At = "2026-08-03 13:30"; Expected = "Open" },
    @{ At = "2026-08-08 12:00"; Expected = "Open" },
    @{ At = "2026-08-07 21:59"; Expected = "Open" },
    @{ At = "2026-08-08 23:00"; Expected = "Open" },
    @{ At = "2026-08-09 22:00"; Expected = "Blocked" }
)

$failed = @()
foreach ($case in $cases) {
    $result = & $scriptPath -Mode Status -Now ([datetime]$case.At)
    if ($result.State -ne $case.Expected) {
        $failed += "$($case.At): expected $($case.Expected), got $($result.State)"
    }
}

if ($failed.Count -gt 0) {
    $failed | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Output "Passed $($cases.Count) schedule boundary tests."
