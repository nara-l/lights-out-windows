[CmdletBinding()]
param(
    [ValidateSet("Run", "Status", "Preview")]
    [string]$Mode = "Run",
    [datetime]$Now = (Get-Date),
    [switch]$NoHibernate
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:LightsOutHour = 21
$script:LightsOutMinute = 59
$script:WakeHour = 6
$script:CountdownHour = 21
$script:CountdownMinute = 30

function Get-LightsOutState {
    param([datetime]$At)

    $minutes = ($At.Hour * 60) + $At.Minute
    $countdownStart = ($script:CountdownHour * 60) + $script:CountdownMinute
    $lightsOut = ($script:LightsOutHour * 60) + $script:LightsOutMinute
    $wake = $script:WakeHour * 60

    $isLightsOutEvening = $At.DayOfWeek -in @(
        [DayOfWeek]::Sunday,
        [DayOfWeek]::Monday,
        [DayOfWeek]::Tuesday,
        [DayOfWeek]::Wednesday,
        [DayOfWeek]::Thursday
    )
    $isBlockedMorning = $At.DayOfWeek -in @(
        [DayOfWeek]::Monday,
        [DayOfWeek]::Tuesday,
        [DayOfWeek]::Wednesday,
        [DayOfWeek]::Thursday,
        [DayOfWeek]::Friday
    )

    if ($isBlockedMorning -and $minutes -lt $wake) {
        return "Blocked"
    }
    if ($isLightsOutEvening -and $minutes -ge $lightsOut) {
        return "Blocked"
    }
    if ($isLightsOutEvening -and $minutes -ge $countdownStart -and $minutes -lt $lightsOut) {
        return "Countdown"
    }
    return "Open"
}

function Get-NextLightsOut {
    param([datetime]$At)

    for ($offset = 0; $offset -le 7; $offset++) {
        $candidateDate = $At.Date.AddDays($offset)
        if ($candidateDate.DayOfWeek -in @(
            [DayOfWeek]::Sunday,
            [DayOfWeek]::Monday,
            [DayOfWeek]::Tuesday,
            [DayOfWeek]::Wednesday,
            [DayOfWeek]::Thursday
        )) {
            $candidate = $candidateDate.AddHours($script:LightsOutHour).AddMinutes($script:LightsOutMinute)
            if ($candidate -gt $At) {
                return $candidate
            }
        }
    }
    throw "Unable to calculate the next lights-out time."
}

function Invoke-Hibernate {
    if ($NoHibernate) {
        Write-Output "Hibernate suppressed by -NoHibernate."
        return
    }
    Start-Process -FilePath "$env:SystemRoot\System32\shutdown.exe" -ArgumentList "/h" -WindowStyle Hidden
}

function Show-Countdown {
    param(
        [datetime]$Target,
        [switch]$IsPreview
    )

    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore

    $window = New-Object Windows.Window
    $window.Title = "Lights Out"
    $window.Width = 720
    $window.Height = 390
    $window.WindowStartupLocation = "CenterScreen"
    $window.Topmost = $true
    $window.ResizeMode = "NoResize"
    $window.Background = "#201A28"

    $panel = New-Object Windows.Controls.StackPanel
    $panel.Margin = "48"
    $panel.VerticalAlignment = "Center"

    $eyebrow = New-Object Windows.Controls.TextBlock
    $eyebrow.Text = "LIGHTS OUT"
    $eyebrow.Foreground = "#E9B7FF"
    $eyebrow.FontSize = 18
    $eyebrow.FontWeight = "SemiBold"
    $eyebrow.HorizontalAlignment = "Center"

    $message = New-Object Windows.Controls.TextBlock
    $message.Text = "Finish the current step. Tomorrow is where the next step belongs."
    $message.Foreground = "White"
    $message.FontSize = 25
    $message.TextAlignment = "Center"
    $message.TextWrapping = "Wrap"
    $message.Margin = "0,22,0,14"

    $clock = New-Object Windows.Controls.TextBlock
    $clock.Foreground = "White"
    $clock.FontSize = 76
    $clock.FontWeight = "Bold"
    $clock.HorizontalAlignment = "Center"

    $detail = New-Object Windows.Controls.TextBlock
    $detail.Text = if ($IsPreview) { "Preview only - hibernation is disabled." } else { "This laptop will hibernate at 9:59 PM." }
    $detail.Foreground = "#D7CEDB"
    $detail.FontSize = 16
    $detail.HorizontalAlignment = "Center"
    $detail.Margin = "0,12,0,0"

    [void]$panel.Children.Add($eyebrow)
    [void]$panel.Children.Add($message)
    [void]$panel.Children.Add($clock)
    [void]$panel.Children.Add($detail)
    $window.Content = $panel

    $timer = New-Object Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(250)
    $timer.Add_Tick({
        $remaining = $Target - (Get-Date)
        if ($IsPreview -and $remaining.TotalSeconds -le 0) {
            $timer.Stop()
            $window.Close()
            return
        }
        if (-not $IsPreview -and $remaining.TotalSeconds -le 0) {
            $timer.Stop()
            $window.Close()
            Invoke-Hibernate
            return
        }

        $totalSeconds = [Math]::Max(0, [Math]::Ceiling($remaining.TotalSeconds))
        $clock.Text = "{0:00}:{1:00}" -f [Math]::Floor($totalSeconds / 60), ($totalSeconds % 60)

        if ($remaining.TotalMinutes -le 5) {
            $window.Background = "#8B0000"
            $eyebrow.Foreground = "#FFD0D0"
        }
        elseif ($remaining.TotalMinutes -le 15) {
            $window.Background = "#6B2F00"
            $eyebrow.Foreground = "#FFD5A6"
        }
    })

    $window.Add_Closing({
        if (-not $IsPreview -and (Get-Date) -lt $Target) {
            $_.Cancel = $true
            $window.WindowState = "Minimized"
        }
    })

    $timer.Start()
    [void]$window.ShowDialog()
}

$state = Get-LightsOutState -At $Now

if ($Mode -eq "Status") {
    [pscustomobject]@{
        At = $Now
        State = $state
        NextLightsOut = Get-NextLightsOut -At $Now
        WakeTime = "{0:00}:00" -f $script:WakeHour
        LightsOutNights = "Sunday through Thursday"
    }
    exit 0
}

if ($Mode -eq "Preview") {
    Show-Countdown -Target (Get-Date).AddSeconds(15) -IsPreview
    exit 0
}

switch ($state) {
    "Countdown" {
        $target = $Now.Date.AddHours($script:LightsOutHour).AddMinutes($script:LightsOutMinute)
        Show-Countdown -Target $target
    }
    "Blocked" {
        Invoke-Hibernate
    }
    default {
        Write-Output "Lights Out is open at $($Now.ToString('dddd h:mm tt'))."
    }
}
