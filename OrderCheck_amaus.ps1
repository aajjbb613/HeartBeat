# OrderCheck_amaus.ps1
#This script checks XXX for the most recent order on its set sales channel
#Created by: Anthony Bradt


$stateFile = "C:\Temp\OrderMonitorState_amaus.json"
$script = "/usr/local/bin/get_orders_amaus.sh"
$time = 30  #time = low, time*2 = high time*3 = ignore qt
$saleschannel = "Amazon US" #common name, only used for emails
$scriptname = "OrderCheck_amaus"

. \\XXX\c$\Scripts\AS-CallBryce.ps1 
. \\XXX\c$\Scripts\AS-SendEmail.ps1 

# --- Tracking File ---

if (-not (Test-Path $stateFile)) {
    @{ LastId = 0; LastSeen = (Get-Date).ToString("o") } | ConvertTo-Json | Set-Content $stateFile
}

# --- Run Script from SSH ---
$output = ssh XXX@XXX $script
if (-not $output) { 
    Write-Host "No output from query"
    $subject = "[HIGH] : $scriptname : $env:COMPUTERNAME : XXX failed to query"
    $body = "Last OrderId with status=3 was $lastId at $lastSeen on sales channel $saleschannel."
    AS-SendEmail -Subject $subject -Body $body
    Write-Host $body
    write-host "Sending call"
    AS-CallBryce -Message "XXX failed to query"
    exit
}


# If we got here, $num is safe to use
$currentId = $num

$currentId = [int]($output.Trim())

# --- Load Last State ---
$state = Get-Content $stateFile | ConvertFrom-Json
$lastId = [int]$state.LastId
$lastSeen = [datetime]::Parse($state.LastSeen)

if ($currentId -gt $lastId) {
    # New order found → update state
    $state.LastId = $currentId
    $state.LastSeen = (Get-Date).ToString("o")
    $state | ConvertTo-Json | Set-Content $stateFile
    Write-Host "New order detected: $currentId"
    exit
}

# --- No new orders → check elapsed time ---
$elapsed = (New-TimeSpan -Start $lastSeen -End (Get-Date)).TotalMinutes
$hourNow = (Get-Date).Hour
$quietHours = ($hourNow -ge 22.9 -or $hourNow -lt 5.1)   # 11pm–5am
$elapsed = [Math]::Round($elapsed)

if ($elapsed -ge 90) {  #bypass quitetimes 
    $subject = "[HIGH] : $scriptname : $env:COMPUTERNAME : Calls muted No new orders in $saleschannel"
    $body = "Last OrderId with status=3 was $elapsed min ago $lastId at $lastSeen on sales channel $saleschannel."
    AS-SendEmail -Subject $subject -Body $body
    Write-Host $body
    write-host "Sending call"
    #AS-CallBryce -Message "EMERGENCY EMERGENCY NO ORDERS IN POSTGRES ND6 on sales channel $saleschannel" -NoCallStartHour 0 -NoCallEndHour 1
}
elseif ($elapsed -ge 35 -and -not $quietHours) {
    $subject = "[HIGH] : $scriptname : $env:COMPUTERNAME :Calls muted No new orders in $saleschannel"
    $body = "Last OrderId with status=3 was $elapsed min ago $lastId at $lastSeen on sales channel $saleschannel."
    AS-SendEmail -Subject $subject -Body $body
    Write-Host $body
    write-host "Sending call"
    #AS-CallBryce -Message "No new orders in postgres ND6 with status of 3 on sales channel $saleschannel"
}
elseif ($elapsed -ge 20) {
    $subject = "[LOW] : $scriptname : $env:COMPUTERNAME : No new orders in $saleschannel"
    $body = "Last OrderId with status=3 was $elapsed min ago $lastId at $lastSeen on sales channel $saleschannel."
    AS-SendEmail -Subject $subject -Body $body
    Write-Host $body
}
else {
    Write-Host "Orders are flowing normally. Last ID=$lastId, $([math]::Round($elapsed,1)) min since last."
    AS-CallBryce -Resolved
}
