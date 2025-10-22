#PNPMCheck.ps1
#This script checks the server to verify that pnpm is running on port 3000, if not it trys to start it and sends an alert
#Created by: Anthony Bradt


# =========================
# Pricer Auto-Start
# =========================

. \\XXX\c$\Scripts\AS-SendEmail.ps1 

$portToCheck = 3000
$startScript = "C:\scripts\start.ps1"
$flagDir     = "C:\scripts\flags"
$flagFile    = Join-Path $flagDir "last-start.flag"
$scriptname = "PNPMCheck"

# Ensure flag dir exists
if (-not (Test-Path $flagDir)) {
    New-Item -ItemType Directory -Path $flagDir -Force | Out-Null
}

# Check if port 3000 is in use
$portInUse = Get-NetTCPConnection -LocalPort $portToCheck -ErrorAction SilentlyContinue

if (-not $portInUse) {
    Write-Host "Port $portToCheck is free. Running $startScript ..."

    # Run start.ps1
    Start-Process -FilePath "powershell.exe" -ArgumentList @("-ExecutionPolicy","Bypass","-File",$startScript) -WindowStyle Hidden

    # Decide severity
    $severity = if (Test-Path $flagFile) { "[HIGH]" } else { "[LOW]" }

    # Update flag
    (Get-Date).ToString("s") | Out-File -FilePath $flagFile -Encoding ascii -Force

    write-output "Sending email"


    $emailBody = "Startup triggered at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') on $env:COMPUTERNAME.`nPort: $portToCheck was free.`nScript: $startScript"
    $subject    = "$severity : $scriptname : $env:COMPUTERNAME : PNPM started on $env:COMPUTERNAME"

    AS-SendEmail -Body $emailBody -Subject $subject
    Write-Host $emailBody
}
else {
    Write-Host "Port $portToCheck is in use. No action taken."

    # Clear flag so next start returns to [LOW]
    if (Test-Path $flagFile) {
        Remove-Item $flagFile -Force
    }
}
