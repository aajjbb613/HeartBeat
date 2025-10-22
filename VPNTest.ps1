#VPNTest.ps1
#This script tests the VPN by connecting from XXX to XXX, alerts on error
#Created by: Anthony Bradt


$server = "XXX"
$scriptname = "VPNCheck"

. \\XXX\c$\Scripts\AS-SendEmail.ps1

# Ping function
function Test-Ping {
    param ($target)
    $ping = Test-Connection -ComputerName $target -Count 1 -Quiet -ErrorAction SilentlyContinue
    return $ping
}

# First attempt
if (-not (Test-Ping $server)) {
    Write-Host "$server unreachable. Waiting 5 minutes before retrying..."
    Start-Sleep -Seconds 300

    # Second attempt
    if (-not (Test-Ping $server)) {
        Write-Host "$server still unreachable. Sending email..."
        $Subject = "[High] : $scriptname : $env:COMPUTERNAME : VPN Failure"
        $Body = "Ping to from XXX to XXX failed twice. Please investigate network or system availability."
        AS-SendEmail -Body $Body -Subject $Subject
    }
    else {
        Write-Host "$server reachable on second attempt."
    }
}
else {
    Write-Host "$server reachable on first attempt."
}
