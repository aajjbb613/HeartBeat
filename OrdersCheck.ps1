# OrderCheck.ps1
#This script checks XXX for the most recent order
#Created by: Anthony Bradt


<# get_orders.sh 
#!/bin/bash
sudo -u postgres psql -d kapsys.channelorders -tA -F ',' <<'SQL'
SELECT COALESCE(MAX("Id"),0)
FROM public.orders
WHERE "OrderStatusId" = 3
SQL
#>

# OrderCheck_amaca.ps1
$stateFile = "C:\Temp\OrderMonitorState.json"
$script = "/usr/local/bin/get_orders.sh"
$time = 15  #time = low, time*2 = high time*4 = ignore qt
$saleschannel = "main"
$scriptname = "OrderCheck"

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
    $body = "Last OrderId with status=3 was $lastId at $lastSeen."
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
$quietHours = ($hourNow -ge 21.9 -or $hourNow -lt 6.1)   # 10pm–6am
$elapsed = [Math]::Round($elapsed)

if ($elapsed -ge ($time*6)) {
    $subject = "[HIGH] : $scriptname : $env:COMPUTERNAME : No new orders in $saleschannel"
    $body = "Last OrderId with status=3 was $elapsed min ago $lastId at $lastSeen on sales channel $saleschannel."
    AS-SendEmail -Subject $subject -Body $body
    Write-Host $body
    write-host "Sending call"
    AS-CallBryce -Message "EMERGENCY EMERGENCY NO ORDERS IN POSTGRES ND6 on sales channel $saleschannel" -NOQT
}
elseif ($elapsed -ge ($time*2) -and -not $quietHours) {
    $subject = "[HIGH] : $scriptname : $env:COMPUTERNAME : No new orders in $saleschannel"
    $body = "Last OrderId with status=3 was $elapsed min ago $lastId at $lastSeen on sales channel $saleschannel."
    AS-SendEmail -Subject $subject -Body $body
    Write-Host $body
    write-host "Sending call"
    AS-CallBryce -Message "No new orders in postgres ND6 with status of 3 on sales channel $saleschannel"
}
elseif ($elapsed -ge $time) {
    $subject = "[LOW] : $scriptname : $env:COMPUTERNAME : No new orders in $saleschannel"
    $body = "Last OrderId with status=3 was $elapsed min ago $lastId at $lastSeen."
    AS-SendEmail -Subject $subject -Body $body
    Write-Host $body
}
else {
    Write-Host "Orders are flowing normally. Last ID=$lastId, $([math]::Round($elapsed,1)) min since last."
    AS-CallBryce -Resolved
}
