function AS-CallBryce {
    [CmdletBinding()]
    param(
        #[string]$PhoneNumber = "+XXX",    # Ben's phone number
        [string]$PhoneNumber = "+XXX",    # Bryce's phone number
        #[string]$PhoneNumber = "+1XXX",    # Anthony's phone number
        [string]$Message = "This is an automated call from AutoShack. Please check the system immediately. Custom error missing.",
        [int]$CooldownMinutes = 30,               # Minimum minutes between calls
        [int]$NoCallStartHour = 23,  #23             # Quiet hours start (23 = 11 PM)
        [int]$NoCallEndHour   = 5,   #5             # Quiet hours end   (5  = 5 AM)
        [switch]$Resolved,
        [switch]$SMSonly,
        [switch]$NOQT
    )

    # Twilio account info
    $sid    = "XXX"
    $token  = "XXX"
    $number = "+XXX"
    $url    = "https://api.twilio.com/2010-04-01/Accounts/$sid/Calls.json"

    # Shared files (network location so all scripts share state)
    $stateFile = "\\XXX\c$\Temp\CallbryceState.txt"
    $logFile   = "\\XXX\c$\Temp\CallbryceQueue.txt"
    $lockFile  = "\\XXX\c$\Temp\Callbryce.send.lock"

    # Build credential object (your original working style)
    $p = $token | ConvertTo-SecureString -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($sid, $p)

    # Identify this caller
    $hostName  = $env:COMPUTERNAME
    $scriptTag = if ($MyInvocation.ScriptName) { [IO.Path]::GetFileName($MyInvocation.ScriptName) } else { "Interactive" }
    $incidentKey = "$scriptTag script. running on, $hostName"

    # Ensure directory exists
    $tmpDir = Split-Path $stateFile -Parent
    if (-not (Test-Path $tmpDir)) { New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null }

    # If resolved, remove entry from queue and exit (super simple)
if ($Resolved) {
    if (Test-Path $logFile) {
        $lines = @(Get-Content -Path $logFile -ErrorAction SilentlyContinue)
        if ($lines.Count -gt 0) {
            # Keep lines that DO NOT contain the incidentKey
            $kept = $lines | Where-Object { $_ -and ($_ -notlike "*$incidentKey*") }

            if ($kept.Count -gt 0) {
                Set-Content -Path $logFile -Value $kept
            } else {
                # Truncate file if nothing remains
                [System.IO.File]::WriteAllText($logFile, "")
            }
        }
    }
    Write-Host "Removed any queued messages for [$incidentKey]."
    return
}

    if($NOQT){
        $timenow = (Get-Date).Hour
        if ($timenow -ge 20){
            $NoCallStartHour = 1
            $NoCallEndHour   = 2 
        }
        else {
            $NoCallStartHour = 21
            $NoCallEndHour   = 22
        }
    }


    # Add/update message in the queue
    $nowIso = (Get-Date -Format o)
    #$line   = "$nowIso | $incidentKey | $Message"
    $line   = "$nowIso | $Message | $incidentKey"
    if (Test-Path $logFile) {
        $existing = Get-Content $logFile -ErrorAction SilentlyContinue
        if ($existing) {
            $existing = $existing | Where-Object { $_ -and ($_ -notmatch [regex]::Escape($incidentKey)) }
            $existing + $line | Set-Content $logFile -NoNewline:$false
        } else {
            $line | Set-Content $logFile -NoNewline:$false
        }
    } else {
        $line | Set-Content $logFile -NoNewline:$false
    }

    # Quiet hours check
    function _InQuietHours([int]$start,[int]$end){
        $h = (Get-Date).Hour
        if ($start -eq $end) { return $true }
        if ($start -lt $end) { return ($h -ge $start -and $h -lt $end) }
        else { return ($h -ge $start -or  $h -lt $end) }
    }
    if (_InQuietHours -start $NoCallStartHour -end $NoCallEndHour) {
        Write-Host "Queued message for [$incidentKey]. Quiet hours active."
        return
    }

    # Cooldown check
    $lastCallTime = $null
    if (Test-Path $stateFile) {
        $raw = (Get-Content $stateFile -Raw).Trim()
        if ($raw) {
            try { $lastCallTime = [datetime]::ParseExact($raw,'o',[System.Globalization.CultureInfo]::InvariantCulture) } catch {}
        }
    }
    if ($lastCallTime -and ((Get-Date) - $lastCallTime).TotalMinutes -lt $CooldownMinutes) {
        Write-Host "Queued message for [$incidentKey]. Cooldown active ($CooldownMinutes min)."
        return
    }

    # Acquire send lock
    $lockStream = $null
    try {
        $lockStream = [System.IO.File]::Open($lockFile, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
    } catch {
        Write-Host "Another sender is active. Message queued for [$incidentKey]."
        return
    }

    try {
        # Double-check cooldown under lock
        $lastCallTime = $null
        if (Test-Path $stateFile) {
            $raw = (Get-Content $stateFile -Raw).Trim()
            if ($raw) {
                try { $lastCallTime = [datetime]::ParseExact($raw,'o',[System.Globalization.CultureInfo]::InvariantCulture) } catch {}
            }
        }
        if ($lastCallTime -and ((Get-Date) - $lastCallTime).TotalMinutes -lt $CooldownMinutes) {
            Write-Host "Cooldown re-confirmed under lock. Messages remain queued."
            return
        }

        # Read and sort queued messages (newest first)
        $entries = @()
        if (Test-Path $logFile) {
            $entries = Get-Content $logFile | Where-Object { $_.Trim() }
        }
        if (-not $entries -or $entries.Count -eq 0) {
            Write-Host "No queued messages to call."
            return
        }
        $parsed = foreach ($e in $entries) {
            $parts = $e -split '\s*\|\s*', 3
            if ($parts.Count -ge 3) {
                try {
                    [pscustomobject]@{
                        Time = [datetime]::ParseExact($parts[0],'o',[System.Globalization.CultureInfo]::InvariantCulture)
                        Key  = $parts[1]
                        Msg  = "Alert from " + $parts[2]
                        #Msg = $parts[2]
                    }
                } catch {
                    [pscustomobject]@{ Time = [datetime]::MinValue; Key = $parts[1]; Msg = $parts[2] }
                }
            }
        }
        $ordered = $parsed | Sort-Object Time -Descending

        # Build TwiML
        $sayBlocks = foreach ($item in $ordered) {
            $safe = [System.Security.SecurityElement]::Escape("$($item.Key): $($item.Msg)")
            "<Say voice='woman' rate='slow'>$safe</Say><Pause length='1'/>"  #Voices, man, woman, alice
        }
        $header = [System.Security.SecurityElement]::Escape("Automated Alert. Playing queued messages.")
        $twiml  = "<Response><Say voice='woman' rate='slow'>$header</Say>$($sayBlocks -join '')</Response>"

        $body   = @{ To = $PhoneNumber; From = $number; Twiml = $twiml }

        # ✅ Your original working request style
        if (-not $SMSonly){
            $response = Invoke-WebRequest $url -Method Post -Credential $credential -Body $body -UseBasicParsing | ConvertFrom-Json
            Write-Host "Call placed. SID: $($response.sid). Spoke $($ordered.Count) queued message(s)."
        }

        ##SMSCode
        # Build a human-readable SMS body from the same $ordered queue
        $lines   = foreach ($item in $ordered) { " $($item.Key): $($item.Msg)" }
        $smsText = "Automated Alert. Playing queued messages.`n`n" + ($lines -join "`n")

        # Send SMS via Twilio Messages API
        $smsUrl  = "https://api.twilio.com/2010-04-01/Accounts/$sid/Messages.json"

        # NOTE: For SMS you must send To, From, Body (no TwiML)
        $smsForm = @{
        To   = $PhoneNumber   # same destination you called
        From = $number        # your Twilio number
        Body = $smsText
        }

        # Use Invoke-RestMethod to get an object back directly
        $response2 = Invoke-RestMethod -Uri $smsUrl -Method Post -Credential $credential -Body $smsForm -ErrorAction Stop

        Write-Host "Text sent. SID: $($response2.sid). Included $($ordered.Count) queued message(s)."


        ##SMSCode


        # Clear queue and update cooldown
        if (-not $SMSonly){
            Clear-Content -Path $logFile -ErrorAction SilentlyContinue
            (Get-Date -Format o) | Set-Content $stateFile -NoNewline
        }
    }
    catch {
        Write-Error "Failed to place call: $_. Messages remain queued."
    }
    finally {
        if ($lockStream) { $lockStream.Dispose() }
    }
}