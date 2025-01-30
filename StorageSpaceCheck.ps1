$lowStorageDrives = @()

Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    $freeSpaceGB = [math]::round($_.FreeSpace / 1GB, 2)
    $totalSpaceGB = [math]::round($_.Size / 1GB, 2)
    $usedPercent = [math]::round((1 - ($_.FreeSpace / $_.Size)) * 100, 2)
    
    if ($usedPercent -gt 94) {  # Threshold for low storage
        Write-Output "Drive Letter: $($_.DeviceID) is running low on storage."
        Write-Output "Free Space: $freeSpaceGB GB / Total Space: $totalSpaceGB GB ($usedPercent% used)"
        
        $lowStorageDrives += "Drive Letter: $($_.DeviceID) is running low on storage. Free Space: $freeSpaceGB GB / Total Space: $totalSpaceGB GB ($usedPercent% used)"
    }
    else {
        Write-Output "Drive Letter: $($_.DeviceID) has sufficient storage."
        Write-Output "Free Space: $freeSpaceGB GB / Total Space: $totalSpaceGB GB ($usedPercent% used)"
    }
}
$hostname = hostname

if ($lowStorageDrives.Count -gt 0) {
    $username = "HeartBeat@autoshack.com"
    $password = "XXX"
    $myPwd = ConvertTo-SecureString -string $password -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential -argumentlist $username, $myPwd

    $mailParams = @{
        SmtpServer = 'smtp.office365.com'
        Port = '587'
        UseSSL = $true
        From = 'HeartBeat@AutoShack.com'
        To = 'HeartBeatGroup@AutoShack.com'
        #To = "abradt@autoshack.com"
        Subject = "Storage Low $hostname"
        Credential = $cred
    }

    Send-MailMessage @mailParams -Body ($lowStorageDrives -join "`n") | Write-Host
    Write-Host $lowStorageDrives
}
