Write-Host "`nWelcome to Autoshacks Offboarding script"
Write-Host "Written by Anthony Bradt and Lukas Millar"
Write-Host "Version 1.1`n"

$UPN = Read-Host "`n `n Enter the user's email"

do {
    $user = Get-ADUser -Filter "UserPrincipalName -eq '$UPN'" -Properties msExchHideFromAddressLists
    $user
    if ($user) {
        $name = $user.Name
        $SAM = $user.SamAccountName
        Write-Host "`n `n `n You are about to disable '$name'"
        $response = Read-Host "Are you sure? (y/n)"
        $response = $response.ToLower().Trim()
    } else {
        Write-Host "`n User with email '$UPN' not found."
        $response = "n"
    }
} while ($response -ne "yes" -and $response -ne "y" -and $response -ne "no" -and $response -ne "n")

# Remove groups and disable user
if ($response -eq "yes" -or $response -eq "y") {
    Write-Host "`ndisabling user account"
    $user.Enabled = $false
    Set-ADUser -instance $user

    Write-Host "`nremoving groups"
    $groups = Get-ADUser -Identity $user | Get-ADPrincipalGroupMembership
    foreach ($group in $groups) {
        if ($group.Name -ne "Domain Users") {
            Remove-ADGroupMember -Identity $group -Members $user -Confirm:$false
            Write-Host "`nRemoved $username from $($group.Name)"
        } else {
            Write-Host "`nSkipped Removing $username from Domain Users"
        }
    }

    Write-Host "`nMoving user to disabled OU"
    Move-ADObject -Identity $user -TargetPath "OU=Deactivated,OU=Users,OU=_KAP Head Office,DC=kap"

    #wait for a while to sync everything in AD

    Write-Host "Waiting for 8 seconds for AD to sync..."
    Start-Sleep -Seconds 8
    Write-Host "Done!"

    $user = Get-ADUser -Filter "UserPrincipalName -eq '$UPN'" -Properties msExchHideFromAddressLists

    if ($user) {
        Write-Host "`n Hiding user from address book"
        Set-ADUser -Identity $user -Replace @{msExchHideFromAddressLists = $true}
    } else {
        Write-Host "`n Error - User object not found after moving to disabled OU `n"
    }
    #Write-Host "`n Hiding user from address book"
    #Set-ADUser -Identity $user -Replace @{msExchHideFromAddressLists = $true}
    #Get-ADUser -Filter "UserPrincipalName -eq '$UPN'" -Properties msExchHideFromAddressLists

# Remove Licenses
# Ask if you want to remove licenses
    $removeLicenses = Read-Host "*********************** `n `n Do you want to remove licenses from the user? (y/n)"
    $removeLicenses = $removeLicenses.ToLower().Trim()

    if ($removeLicenses -eq "yes" -or $removeLicenses -eq "y") {
        Write-Host "`nRemoving licenses"
        try {
            Connect-MgGraph -Scopes "User.ReadWrite.All"
            $user = Get-MgUser -Filter "userPrincipalName eq '$UPN'"
            
            if ($user) {
                $licenses = Get-MgUserLicenseDetail -userId $user.Id

                if ($licenses) {
                    foreach ($license in $licenses) {
                        Set-MgUserLicense -UserId $user.Id -AddLicenses @() -RemoveLicenses @($license.SkuId)
                        Write-Host "License $($license.SkuId) removed from $UPN"
                    }
                } else {
                    Write-Host "No licenses found for $UPN"
                }
            }
        } catch {
            Write-Host "An Error occurred: $_"
        }
    } else {
        Write-Host "`n `n Skipping license removal"
        write-host "`n The user $UPN has been removed! "
    }
}
else {
Write-Host "`n Wow that was a close one"}

