[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$taskFolder = "\Lights Out\"
$removed = 0

foreach ($taskName in @("Countdown", "Boundary Guard")) {
    $existing = Get-ScheduledTask -TaskPath $taskFolder -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existing) {
        Unregister-ScheduledTask -TaskPath $taskFolder -TaskName $taskName -Confirm:$false
        $removed++
    }
}

Write-Output "Removed $removed Lights Out scheduled task(s). No personal files or open work were changed."
