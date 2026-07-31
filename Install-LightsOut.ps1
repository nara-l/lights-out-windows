[CmdletBinding()]
param(
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$runtimeScript = Join-Path $projectRoot "LightsOut.ps1"
$runtimeLauncher = Join-Path $projectRoot "LightsOutLauncher.vbs"
$taskFolder = "\Lights Out\"
$countdownTaskName = "Countdown"
$guardTaskName = "Boundary Guard"
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

if (-not (Test-Path -LiteralPath $runtimeScript)) {
    throw "LightsOut.ps1 is missing from $projectRoot."
}
if (-not (Test-Path -LiteralPath $runtimeLauncher)) {
    throw "LightsOutLauncher.vbs is missing from $projectRoot."
}

$hibernateStates = (& powercfg.exe /a | Out-String)
if ($hibernateStates -notmatch "(?im)^\s*Hibernate\s*$") {
    throw "Hibernate is not available on this laptop. Enable it before installing Lights Out."
}

$action = New-ScheduledTaskAction `
    -Execute "$env:SystemRoot\System32\wscript.exe" `
    -Argument "`"$runtimeLauncher`""
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Hours 12)
$principal = New-ScheduledTaskPrincipal -UserId $currentUser -LogonType Interactive -RunLevel Limited

$countdownTriggers = @()
foreach ($day in @("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday")) {
    $countdownTriggers += New-ScheduledTaskTrigger -Weekly -DaysOfWeek $day -At "9:30 PM"
}
foreach ($day in @("Monday", "Tuesday", "Wednesday", "Thursday", "Friday")) {
    $countdownTriggers += New-ScheduledTaskTrigger -Weekly -DaysOfWeek $day -At "11:30 AM"
}

$nightGuardTrigger = New-ScheduledTaskTrigger `
    -Weekly `
    -DaysOfWeek Sunday, Monday, Tuesday, Wednesday, Thursday `
    -At "9:59 PM"
$nightGuardTrigger.Repetition = New-CimInstance `
    -ClassName MSFT_TaskRepetitionPattern `
    -Namespace "Root/Microsoft/Windows/TaskScheduler" `
    -ClientOnly `
    -Property @{
        Interval = "PT5M"
        Duration = "PT8H1M"
        StopAtDurationEnd = $false
    }

$lunchGuardTrigger = New-ScheduledTaskTrigger `
    -Weekly `
    -DaysOfWeek Monday, Tuesday, Wednesday, Thursday, Friday `
    -At "11:45 AM"
$lunchGuardTrigger.Repetition = New-CimInstance `
    -ClassName MSFT_TaskRepetitionPattern `
    -Namespace "Root/Microsoft/Windows/TaskScheduler" `
    -ClientOnly `
    -Property @{
        Interval = "PT5M"
        Duration = "PT1H45M"
        StopAtDurationEnd = $false
    }

$guardTriggers = @($nightGuardTrigger, $lunchGuardTrigger)

foreach ($taskName in @($countdownTaskName, $guardTaskName)) {
    $existing = Get-ScheduledTask -TaskPath $taskFolder -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existing -and -not $Force) {
        throw "Task '$taskFolder$taskName' already exists. Re-run with -Force to replace it."
    }
    if ($existing) {
        Unregister-ScheduledTask -TaskPath $taskFolder -TaskName $taskName -Confirm:$false
    }
}

Register-ScheduledTask `
    -TaskPath $taskFolder `
    -TaskName $countdownTaskName `
    -Description "Shows the Lights Out countdown before the lunch and night boundaries." `
    -Action $action `
    -Trigger $countdownTriggers `
    -Settings $settings `
    -Principal $principal | Out-Null

Register-ScheduledTask `
    -TaskPath $taskFolder `
    -TaskName $guardTaskName `
    -Description "Re-hibernates this laptop when it is used during lunch or night Lights Out hours." `
    -Action $action `
    -Trigger $guardTriggers `
    -Settings $settings `
    -Principal $principal | Out-Null

Write-Output "Lights Out installed for $currentUser."
Write-Output "Lunch boundary: Monday-Friday, warning at 11:30 AM, hibernate from 11:45 AM-1:30 PM."
Write-Output "Night boundary: Sunday-Thursday, warning at 9:30 PM, hibernate from 9:59 PM-6:00 AM."
Write-Output "Run .\LightsOut.ps1 -Mode Preview to see the 15-second safe preview."
