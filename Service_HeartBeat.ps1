
$stoppedServices = @()
$recoveredServices = @()
$hostname = hostname
$flagBasePath = "C:\Scripts\flags\$hostname"

# Create the flags directory structure if it doesn't exist
if (-not (Test-Path $flagBasePath)) {
    New-Item -ItemType Directory -Path $flagBasePath -Force | Out-Null
}

Get-Service | Where-Object {
    $_.Name -like '*KAP*' -or
    $_.Name -like '*KSYS*' -or
    $_.Name -like '*W3SVC*' -or
    $_.Name -like '*Ksys*' -or
    $_.Name -like '*ADSI*' -or
    $_.Name -like '*KapSys*' -or
    $_.Name -like 'MSSQLSERVER'
} | ForEach-Object {
    if ($_.Status -eq 'Stopped' -and $_.StartType -ne 'Disabled' -and $_.StartType -ne 'Manual') {
        $serviceFlagPath = Join-Path $flagBasePath $_.Name
        $flagFile = Join-Path $serviceFlagPath "stopped.flag"
        
        # Create service directory if it doesn't exist
        if (-not (Test-Path $serviceFlagPath)) {
            New-Item -ItemType Directory -Path $serviceFlagPath -Force | Out-Null
        }
        
        # Only try to start the service if there's no existing flag
        if (-not (Test-Path $flagFile)) {
            Write-Host "Attempting to start service: $($_.Name)"
            try {
                Start-Service -Name $_.Name -ErrorAction Stop
                # Wait a moment to check if service started successfully
                Start-Sleep -Seconds 5
                $service = Get-Service -Name $_.Name
                if ($service.Status -eq 'Running') {
                    Write-Host "Successfully started service: $($_.Name)"
                    $recoveredServices += $_
                }
                else {
                    # Service failed to start, create flag and add to stopped services
                    Set-Content -Path $flagFile -Value (Get-Date)
                    $stoppedServices += $_
                }
            }
            catch {
                Write-Host "Failed to start service $($_.Name): $_"
                # Service failed to start, create flag and add to stopped services
                Set-Content -Path $flagFile -Value (Get-Date)
                $stoppedServices += $_
            }
        }
        else {
            # Flag exists, add to stopped services
            $stoppedServices += $_
        }
    }
    Write-host $_
}

if ($stoppedServices.Count -gt 0 -or $recoveredServices.Count -gt 0) {
    $emailBody = ""
    
    if ($stoppedServices.Count -gt 0) {
        $emailBody += "The following services are stopped:`n"
        $stoppedServices | ForEach-Object {
            $emailBody += "Name: $($_.Name), DisplayName: $($_.DisplayName)`n"
        }
        $emailBody += "`n"
    }
    
    if ($recoveredServices.Count -gt 0) {
        $emailBody += "The following services were automatically recovered:`n"
        $recoveredServices | ForEach-Object {
            $emailBody += "Name: $($_.Name), DisplayName: $($_.DisplayName)`n"
        }
    }

    Write-Output "Sending email"

    $username = "HeartBeat@autoshack.com"
    $password = "XXX"
    $myPwd = ConvertTo-SecureString -string $password -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential -argumentlist $username, $myPwd

    $mailParams = @{
        SmtpServer = 'smtp.office365.com'
        Port = '587'
        UseSSL = $true
        From = 'HeartBeat@AutoShack.com'
        To = 'HeartBeatGroup@autoshack.com'
        #To = 'abradt@autoshack.com'
        Subject = "Service Status Alert: $hostname"
        Credential = $cred
    }

    Send-MailMessage @mailParams -Body $emailBody | Write-Host
    Write-Host $emailBody
}
else {
    # If no services are stopped, remove any existing flag files
    if (Test-Path $flagBasePath) {
        Remove-Item -Path $flagBasePath -Recurse -Force
    }
    write-host "clear"
}
