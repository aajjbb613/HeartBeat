$stoppedServices = @()

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
        $stoppedServices += $_
    }
    Write-host $_
}

$hostname = hostname 

if ($stoppedServices.Count -gt 0) {
    $emailBody = "The following services are stopped:`n"
    $stoppedServices | ForEach-Object {
        $emailBody += "Name: $($_.Name), DisplayName: $($_.DisplayName)`n"
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
else{write-host "clear"}
