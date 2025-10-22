#StorageSpaceCheck_PW
#This script checks the remaining drive space on each windows server, on low space sends alerts
#Created by: Anthony Bradt


. \\XXX\c$\Scripts\AS-CallBryce.ps1 
. \\XXX\c$\Scripts\AS-SendEmail.ps1 

# Get the current day of the week (0 = Sunday, 6 = Saturday)
$dayOfWeek = (Get-Date).DayOfWeek
 
$SubjectTag = "[LOW]"
$scriptname = "StorageCheck"
# 

# Check if today is Saturday or Sunday
$isWeekend = ($dayOfWeek -eq "Saturday" -or $dayOfWeek -eq "Sunday")
 
#Write-Output "Is it the weekend?: $isWeekend"
If($isWeekend){
    $Threshold = 97
}else{$Threshold = 95}


$lowStorageDrives = @()

Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    $freeSpaceGB = [math]::round($_.FreeSpace / 1GB, 2)
    $totalSpaceGB = [math]::round($_.Size / 1GB, 2)
    $usedPercent = [math]::round((1 - ($_.FreeSpace / $_.Size)) * 100, 2)
    
    if ($usedPercent -gt $Threshold) {  # Threshold for low storage
        Write-Output "Drive Letter: $($_.DeviceID) is running low on storage."
        Write-Output "Free Space: $freeSpaceGB GB / Total Space: $totalSpaceGB GB ($usedPercent% used)"
        
        $lowStorageDrives += "Drive Letter: $($_.DeviceID) is running low on storage. Free Space: $freeSpaceGB GB / Total Space: $totalSpaceGB GB ($usedPercent% used)"
    }
    else {
        Write-Output "Drive Letter: $($_.DeviceID) has sufficient storage."
        Write-Output "Free Space: $freeSpaceGB GB / Total Space: $totalSpaceGB GB ($usedPercent% used)"
    }
    if ($usedPercent -gt 98){
        $SubjectTag = "[HIGH]"
    }
}

if ($lowStorageDrives.Count -gt 0) {

    $Subject = "$SubjectTag : $scriptname : $env:COMPUTERNAME : Storage Low"
    AS-SendEmail -Body ($lowStorageDrives -join "`n")
    Write-Host $lowStorageDrives
}
if ($SubjectTag -eq "[HIGH]"){
    AS-CallBryce -Message "STORAGE ISSUES, $lowStorageDrives"
}else{
    As-CallBryce -Resolved
}
