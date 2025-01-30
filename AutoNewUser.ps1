# First time setup (Run these commands as admin)

#Add-WindowsCapability -Online -Name "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0"
#Add-WindowsCapability -Online -Name "Rsat.RemoteDesktop.Services.Tools~~~~0.0.1.0"
#powershell Set-ExecutionPolicy RemoteSigned
#Install-Module -name sqlserver
#Install-Module -name Microsoft.Graph.Authentication
#Install-Module -name Microsoft.Graph.Identity.DirectoryManagement
#Install-Module -Name Microsoft.Graph.Users
#Install-Module -Name Microsoft.Graph.Users.Actions


# KSYS Requires "C:\Scripts\AutoHotKey\WMS.ahk" to be present on local system
# Download/install Version 2         https://www.autohotkey.com/download/
# Place WMS.ahk into local system    https://autoshack.atlassian.net/wiki/spaces/DT/pages/2019164161/Onboarding+Script 

Import-Module ActiveDirectory
Import-Module SqlServer
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.Identity.DirectoryManagement
Import-Module Microsoft.Graph.Users
Import-Module Microsoft.Graph.Users.Actions
#TODO Change this portion to use require

#Set up files
#Define the directory and file paths
$directoryPath = "C:\scripts"
$filePath = "C:\scripts\NewUser.txt"

# Check if the directory exists
if (-not (Test-Path -Path $directoryPath)) {
    # If the directory does not exist, create it
    New-Item -Path $directoryPath -ItemType Directory
    Write-Host "Directory created: $directoryPath"
} else {
    Write-Host "Directory already exists: $directoryPath"
}

# Check if the file exists
if (-not (Test-Path -Path $filePath)) {
    # If the file does not exist, create it
    New-Item -Path $filePath -ItemType File
    Write-Host "File created: $filePath"
} else {
    Write-Host "File already exists: $filePath"
}

#print this to seperator for previous output:
write-host("==========================================")
write-host("")
write-host("")

# Define the target AD server
$domainController = "XXX"

# Define the user parameters
$firstName = Read-Host "Enter the first name"
$lastName = Read-Host "Enter the last name"
$PCName = Read-Host "Enter the PC name"

Read-Host "Confirm PC"

$PC = Get-ADComputer -Identity $PCName -Properties *
write-host $PC.Description
write-host $PC.CanonicalName
write-host $PC.ObjectGUID

do {
    Write-Host "Select an option:"
    Write-Host "1. Autoshack"
    Write-Host "2. OffShore"
    Write-Host "3. Exit"
    
    $choice = Read-Host "Enter the number of your choice"
    $choice = $choice.Trim()
} while ($choice -ne "1" -and $choice -ne "2" -and $choice -ne "3" -and $choice -ne "4")

switch ($choice) {
    "1" {
        Write-Host "Creating an Autoshack Employee"
        $username = ($firstName.Substring(0, 1) + $lastName).ToLower()
        $RanGen = -join ((97..122) | Get-Random -Count 10 | ForEach-Object {[char]$_})
        $RanGen += "@123"
        $password = ConvertTo-SecureString -String $RanGen -AsPlainText -Force
        $domain = "@autoshack.com"
        $Postion = Read-Host "What is the user position?"
        
        do {
            Write-Host "Select an option:"
            Write-Host "1. Accounting"
            Write-Host "2. CSR"
            Write-Host "3. Dev"
            Write-Host "4. Management"
            Write-Host "5. Purchasing"
            Write-Host "6. Data"
            Write-Host "7. Retail"
            Write-Host "8. Warehouse"
            Write-Host "9. Warehouse Office"
            Write-Host "10. Human Resources"
            Write-Host "11. Marketing"
            
            
    
            $choice = Read-Host "Enter the number of your choice"
            $choice = $choice.Trim()
        } while ($choice -ne "1" -and $choice -ne "2" -and $choice -ne "3" -and $choice -ne "4" -and $choice -ne "5" -and $choice -ne "6" -and $choice -ne "7" -and $choice -ne "8" -and $choice -ne "9" -and $choice -ne "10" -and $choice -ne "11")
        
        switch ($choice) {
            "1" {
                Write-Host "Adding user to Accounting"
                $ou = "OU=Accounting,OU=Users,OU=_KAP Head Office,DC=kap"
                $pcou = "OU=WS - Accounting,OU=Workstations,OU=_KAP Head Office,DC=kap"

                # Create the user
                New-ADUser -SamAccountName $username -UserPrincipalName "$username$domain" -GivenName $firstName -Surname $lastName -Name "$firstName $lastName" -Enabled $true -AccountPassword $password -ChangePasswordAtLogon $true -Path $ou -Server $domainController -EmailAddress $username$domain -StreetAddress "201 Iber Road" -City "Sittsville" -State "Ontario" -PostalCode "K2S 1E7" -Company "Autoshack" -displayname "$firstname $lastname" -Description $Postion -Title $Postion -HomeDrive "M:" -HomeDirectory "\\svr-fs-02\home folders\$username" -Country "ca" 
                Write-Host "New user created successfully."
                Write-Host $username$domain
                Write-host $RanGen

                Start-Sleep -s 10

                Add-ADGroupMember -Identity "Accounting" -Members $username
                Add-ADGroupMember -Identity "carrierclaims" -Members $username
                Add-ADGroupMember -Identity "Office" -Members $username
                Add-ADGroupMember -Identity "paypal@primechoice.ca" -Members $username
                Add-ADGroupMember -Identity "paypal@primechoice.com" -Members $username
                Add-ADGroupMember -Identity "SuperSpecialPeople" -Members $username
                Add-ADGroupMember -Identity "Warehouse Group" -Members $username
                Add-ADGroupMember -Identity "MFA" -Members $username

                $group = "accounting"

            }
            "2" {
                Write-Host "Adding user to CSR"
                $ou = "OU=CSR,OU=Users,OU=_KAP Head Office,DC=kap"
                $pcou = "OU=WS - CSR,OU=Workstations,OU=_KAP Head Office,DC=kap"
               

                # Create the user
                New-ADUser -SamAccountName $username -UserPrincipalName "$username$domain" -GivenName $firstName -Surname $lastName -Name "$firstName $lastName" -Enabled $true -AccountPassword $password -ChangePasswordAtLogon $true -Path $ou -Server $domainController -EmailAddress $username$domain -StreetAddress "201 Iber Road" -City "Sittsville" -State "Ontario" -PostalCode "K2S 1E7" -Company "Autoshack" -displayname "$firstname $lastname" -Description $Postion -Title $Postion -HomeDrive "M:" -HomeDirectory "\\svr-fs-02\home folders\$username" -Country "ca" 
                Write-Host "New user created successfully."
                Write-Host $username$domain
                Write-host $RanGen

                Start-Sleep -s 10

                Add-ADGroupMember -Identity "carrierclaims" -Members $username
                Add-ADGroupMember -Identity "Contact Center Ottawa" -Members $username
                Add-ADGroupMember -Identity "CSR Printer" -Members $username
                Add-ADGroupMember -Identity "CSRs" -Members $username
                Add-ADGroupMember -Identity "Customer Contact Center" -Members $username
                Add-ADGroupMember -Identity "Customer Reviews" -Members $username
                Add-ADGroupMember -Identity "Customer Service Faxes" -Members $username
                Add-ADGroupMember -Identity "Ebay - PC" -Members $username
                Add-ADGroupMember -Identity "Ebay - PC.COM" -Members $username
                Add-ADGroupMember -Identity "Office" -Members $username
                Add-ADGroupMember -Identity "Warehouse RGA" -Members $username
                Add-ADGroupMember -Identity "Marketplace OTP" -Members $username
                Add-ADGroupMember -Identity "MFA" -Members $username


            }
            "3" {
                Write-Host "Adding user to Dev"
                $ou = "OU=Dev,OU=Users,OU=_KAP Head Office,DC=kap"
                $pcou = "OU=WS - Dev,OU=Workstations,OU=_KAP Head Office,DC=kap"
                
                # Create the user
                New-ADUser -SamAccountName $username -UserPrincipalName "$username$domain" -GivenName $firstName -Surname $lastName -Name "$firstName $lastName" -Enabled $true -AccountPassword $password -ChangePasswordAtLogon $true -Path $ou -Server $domainController -EmailAddress $username$domain -StreetAddress "201 Iber Road" -City "Sittsville" -State "Ontario" -PostalCode "K2S 1E7" -Company "Autoshack" -displayname "$firstname $lastname" -Description $Postion -Title $Postion -HomeDrive "M:" -HomeDirectory "\\svr-fs-02\home folders\$username" -Country "ca" 
                Write-Host "New user created successfully."
                Write-Host $username$domain
                Write-host $RanGen

                Start-Sleep -s 10

                Add-ADGroupMember -Identity "Database Administrators" -Members $username
                Add-ADGroupMember -Identity "DevAdmin" -Members $username
                Add-ADGroupMember -Identity "IT Dept" -Members $username
                Add-ADGroupMember -Identity "IT Development" -Members $username
                Add-ADGroupMember -Identity "ITStaff" -Members $username
                Add-ADGroupMember -Identity "Purchasing Group" -Members $username
                Add-ADGroupMember -Identity "SuperSpecialPeople" -Members $username
                Add-ADGroupMember -Identity "Upstairs Printer" -Members $username
                Add-ADGroupMember -Identity "VPN Users" -Members $username
                Add-ADGroupMember -Identity "MFA" -Members $username


            }
            "4" {
                Write-Host "Adding user to Management"
                $ou = "OU=Managment,OU=Users,OU=_KAP Head Office,DC=kap"
                $pcou = "OU=WS - Managment,OU=Workstations,OU=_KAP Head Office,DC=kap"
                
                # Create the user
                New-ADUser -SamAccountName $username -UserPrincipalName "$username$domain" -GivenName $firstName -Surname $lastName -Name "$firstName $lastName" -Enabled $true -AccountPassword $password -ChangePasswordAtLogon $true -Path $ou -Server $domainController -EmailAddress $username$domain -StreetAddress "201 Iber Road" -City "Sittsville" -State "Ontario" -PostalCode "K2S 1E7" -Company "Autoshack" -displayname "$firstname $lastname" -Description $Postion -Title $Postion -HomeDrive "M:" -HomeDirectory "\\svr-fs-02\home folders\$username" -Country "ca" 
                Write-Host "New user created successfully."
                Write-Host $username$domain
                Write-host $RanGen


           
            }
            "5" {
                Write-Host "Adding user to Purchasing"
                $ou = "OU=Purchasing,OU=Users,OU=_KAP Head Office,DC=kap"
                $pcou = "OU=WS - Purchasing,OU=Workstations,OU=_KAP Head Office,DC=kap"
                
                # Create the user
                New-ADUser -SamAccountName $username -UserPrincipalName "$username$domain" -GivenName $firstName -Surname $lastName -Name "$firstName $lastName" -Enabled $true -AccountPassword $password -ChangePasswordAtLogon $true -Path $ou -Server $domainController -EmailAddress $username$domain -StreetAddress "201 Iber Road" -City "Sittsville" -State "Ontario" -PostalCode "K2S 1E7" -Company "Autoshack" -displayname "$firstname $lastname" -Description $Postion -Title $Postion -HomeDrive "M:" -HomeDirectory "\\svr-fs-02\home folders\$username" -Country "ca" 
                Write-Host "New user created successfully."
                Write-Host $username$domain
                Write-host $RanGen

                Start-Sleep -s 10

                Add-ADGroupMember -Identity "Data - Full Control" -Members $username
                Add-ADGroupMember -Identity "Data Processing" -Members $username
                Add-ADGroupMember -Identity "Data Processing Printer" -Members $username
                Add-ADGroupMember -Identity "Imports Group Member" -Members $username
                Add-ADGroupMember -Identity "Logistics" -Members $username
                Add-ADGroupMember -Identity "Office" -Members $username
                Add-ADGroupMember -Identity "Purchasing" -Members $username
                Add-ADGroupMember -Identity "Purchasing Group" -Members $username
                Add-ADGroupMember -Identity "Purchasing Users" -Members $username
                Add-ADGroupMember -Identity "SuperSpecialPeople" -Members $username
                Add-ADGroupMember -Identity "MFA" -Members $username
   
            }
            "6" {
                Write-Host "Adding user to Data"
                $ou = "OU=Data,OU=Users,OU=_KAP Head Office,DC=kap"
                $pcou = "OU=WS - Data,OU=Workstations,OU=_KAP Head Office,DC=kap"
                
                # Create the user
                New-ADUser -SamAccountName $username -UserPrincipalName "$username$domain" -GivenName $firstName -Surname $lastName -Name "$firstName $lastName" -Enabled $true -AccountPassword $password -ChangePasswordAtLogon $true -Path $ou -Server $domainController -EmailAddress $username$domain -StreetAddress "201 Iber Road" -City "Sittsville" -State "Ontario" -PostalCode "K2S 1E7" -Company "Autoshack" -displayname "$firstname $lastname" -Description $Postion -Title $Postion -HomeDrive "M:" -HomeDirectory "\\svr-fs-02\home folders\$username" -Country "ca" 
                Write-Host "New user created successfully."
                Write-Host $username$domain
                Write-host $RanGen

                Start-Sleep -s 10

                Add-ADGroupMember -Identity "Data - Full Control" -Members $username
                Add-ADGroupMember -Identity "Data Processing" -Members $username
                Add-ADGroupMember -Identity "Data Processing Printer" -Members $username
                Add-ADGroupMember -Identity "DataMessages" -Members $username
                Add-ADGroupMember -Identity "Office" -Members $username
                Add-ADGroupMember -Identity "Purchasing Group" -Members $username
                Add-ADGroupMember -Identity "Purchasing Users" -Members $username
                Add-ADGroupMember -Identity "SuperSpecialPeople" -Members $username
                Add-ADGroupMember -Identity "Upstairs Printer" -Members $username
                Add-ADGroupMember -Identity "MFA" -Members $username


  
            }
            "7" {
                Write-Host "Adding user to Retail"
                $ou = "OU=Retail,OU=Users,OU=_KAP Head Office,DC=kap"
                $pcou = "OU=WS - Retail,OU=Workstations,OU=_KAP Head Office,DC=kap"
                
                # Create the user
                New-ADUser -SamAccountName $username -UserPrincipalName "$username$domain" -GivenName $firstName -Surname $lastName -Name "$firstName $lastName" -Enabled $true -AccountPassword $password -ChangePasswordAtLogon $true -Path $ou -Server $domainController -EmailAddress $username$domain -StreetAddress "201 Iber Road" -City "Sittsville" -State "Ontario" -PostalCode "K2S 1E7" -Company "Autoshack" -displayname "$firstname $lastname" -Description $Postion -Title $Postion -HomeDrive "M:" -HomeDirectory "\\svr-fs-02\home folders\$username" -Country "ca" 
                Write-Host "New user created successfully."
                Write-Host $username$domain
                Write-host $RanGen

                Start-Sleep -s 10

                Add-ADGroupMember -Identity "Office" -Members $username
                Add-ADGroupMember -Identity "PC Store - Plain" -Members $username
                Add-ADGroupMember -Identity "PC Store Printer" -Members $username
                Add-ADGroupMember -Identity "PCIber" -Members $username
                Add-ADGroupMember -Identity "PrimeChoiceStores" -Members $username
                Add-ADGroupMember -Identity "Retail_Store" -Members $username
                Add-ADGroupMember -Identity "RetailStore" -Members $username
                Add-ADGroupMember -Identity "MFA" -Members $username
         
            }
            "8" {
                Write-Host "Adding user to Warehouse"
                $ou = "OU=Warehouse,OU=Users,OU=_KAP Head Office,DC=kap"
                $pcou = "OU=WS - Warehouse,OU=Workstations,OU=_KAP Head Office,DC=kap"
                
                # Create the user
                New-ADUser -SamAccountName $username -UserPrincipalName "$username$domain" -GivenName $firstName -Surname $lastName -Name "$firstName $lastName" -Enabled $true -AccountPassword $password -ChangePasswordAtLogon $true -Path $ou -Server $domainController -EmailAddress $username$domain -StreetAddress "201 Iber Road" -City "Sittsville" -State "Ontario" -PostalCode "K2S 1E7" -Company "Autoshack" -displayname "$firstname $lastname" -Description $Postion -Title $Postion -HomeDrive "M:" -HomeDirectory "\\svr-fs-02\home folders\$username" -Country "ca" 
                Write-Host "New user created successfully."
                Write-Host $username$domain
                Write-host $RanGen

                Start-Sleep -s 10

                Add-ADGroupMember -Identity "Office" -Members $username
                Add-ADGroupMember -Identity "Shipping Printer" -Members $username
                Add-ADGroupMember -Identity "WarehouseEmail" -Members $username
                Add-ADGroupMember -Identity "Warehouse Group" -Members $username
                Add-ADGroupMember -Identity "Warehouse Supervisors" -Members $username
                Add-ADGroupMember -Identity "MFA" -Members $username
           
            }
            "9" {
                Write-Host "Adding user to Warehouse Office"
                $ou = "OU=Warehouse Office,OU=Users,OU=_KAP Head Office,DC=kap"
                $pcou = "OU=WS - ShippingOffice,OU=Workstations,OU=_KAP Head Office,DC=kap"
                
                # Create the user
                New-ADUser -SamAccountName $username -UserPrincipalName "$username$domain" -GivenName $firstName -Surname $lastName -Name "$firstName $lastName" -Enabled $true -AccountPassword $password -ChangePasswordAtLogon $true -Path $ou -Server $domainController -EmailAddress $username$domain -StreetAddress "201 Iber Road" -City "Sittsville" -State "Ontario" -PostalCode "K2S 1E7" -Company "Autoshack" -displayname "$firstname $lastname" -Description $Postion -Title $Postion -HomeDrive "M:" -HomeDirectory "\\svr-fs-02\home folders\$username" -Country "ca" 
                Write-Host "New user created successfully."
                Write-Host $username$domain
                Write-host $RanGen

                Start-Sleep -s 10

                Add-ADGroupMember -Identity "Office" -Members $username
                Add-ADGroupMember -Identity "Operations" -Members $username
                Add-ADGroupMember -Identity "Purchasing Group" -Members $username
                Add-ADGroupMember -Identity "Purchasing Users" -Members $username
                Add-ADGroupMember -Identity "usreturns@primechoice.com" -Members $username
                Add-ADGroupMember -Identity "WarehouseEmail" -Members $username
                Add-ADGroupMember -Identity "Warehouse Group" -Members $username
                Add-ADGroupMember -Identity "Warehouse Managers" -Members $username
                Add-ADGroupMember -Identity "WarehouseAdmin" -Members $username
                Add-ADGroupMember -Identity "MFA" -Members $username
             

             }
             "10" {
                Write-Host "Adding user to Human Resources"
                $ou = "OU=HR,OU=Users,OU=_KAP Head Office,DC=kap"
                $pcou = "OU=WS - HR,OU=Workstations,OU=_KAP Head Office,DC=kap"
                
                # Create the user
                New-ADUser -SamAccountName $username -UserPrincipalName "$username$domain" -GivenName $firstName -Surname $lastName -Name "$firstName $lastName" -Enabled $true -AccountPassword $password -ChangePasswordAtLogon $true -Path $ou -Server $domainController -EmailAddress $username$domain -StreetAddress "201 Iber Road" -City "Sittsville" -State "Ontario" -PostalCode "K2S 1E7" -Company "Autoshack" -displayname "$firstname $lastname" -Description $Postion -Title $Postion -HomeDrive "M:" -HomeDirectory "\\svr-fs-02\home folders\$username" -Country "ca" 
                Write-Host "New user created successfully."
                Write-Host $username$domain
                Write-host $RanGen

                Start-Sleep -s 10

                Add-ADGroupMember -Identity "Data - Full Control" -Members $username
                Add-ADGroupMember -Identity "Data Processing" -Members $username
                Add-ADGroupMember -Identity "Data Processing Printer" -Members $username
                Add-ADGroupMember -Identity "DataMessages" -Members $username
                Add-ADGroupMember -Identity "Logistics" -Members $username
                Add-ADGroupMember -Identity "Office" -Members $username
                Add-ADGroupMember -Identity "Purchasing" -Members $username
                Add-ADGroupMember -Identity "Purchasing Group" -Members $username
                Add-ADGroupMember -Identity "Purchasing Users" -Members $username
                Add-ADGroupMember -Identity "SuperSpecialPeople" -Members $username
                Add-ADGroupMember -Identity "Upstairs Printer" -Members $username
                Add-ADGroupMember -Identity "MFA" -Members $username

            }
            "11" {
                Write-Host "Adding user to Marketing"
                $ou = "OU=Marketing,OU=Users,OU=_KAP Head Office,DC=kap"
                $pcou = "OU=WS - Marketing,OU=Workstations,OU=_KAP Head Office,DC=kap"
                
                # Create the user
                New-ADUser -SamAccountName $username -UserPrincipalName "$username$domain" -GivenName $firstName -Surname $lastName -Name "$firstName $lastName" -Enabled $true -AccountPassword $password -ChangePasswordAtLogon $true -Path $ou -Server $domainController -EmailAddress $username$domain -StreetAddress "201 Iber Road" -City "Sittsville" -State "Ontario" -PostalCode "K2S 1E7" -Company "Autoshack" -displayname "$firstname $lastname" -Description $Postion -Title $Postion -HomeDrive "M:" -HomeDirectory "\\svr-fs-02\home folders\$username" -Country "ca" 
                Write-Host "New user created successfully."
                Write-Host $username$domain
                Write-host $RanGen

                Start-Sleep -s 10

                Add-ADGroupMember -Identity "Data - Full Control" -Members $username
                Add-ADGroupMember -Identity "Data Processing" -Members $username
                Add-ADGroupMember -Identity "Data Processing Printer" -Members $username
                Add-ADGroupMember -Identity "Imports Group Member" -Members $username
                Add-ADGroupMember -Identity "Office" -Members $username
                Add-ADGroupMember -Identity "Purchasing Group" -Members $username
                Add-ADGroupMember -Identity "Purchasing Users" -Members $username
                Add-ADGroupMember -Identity "SuperSpecialPeople" -Members $username
                Add-ADGroupMember -Identity "MFA" -Members $username
            }
        }
        #Move the PC
        Move-ADObject -Identity $PC.ObjectGUID -TargetPath $pcou
        Start-Sleep -Seconds 1
        $PC = Get-ADComputer -Identity $PCName -Properties *
        write-host $PC.Description
        write-host $PC.CanonicalName
        write-host $PC.ObjectGUID
    }
    "2" {
        Write-Host "Creating an Offshore Employee"

        $email = Read-Host "Enter the Email of the offshore"
        $parts = $email -split "@"
        $username = $parts[0]
        $domain = "@" + $parts[1]
        Write-Host "Username: $username"
        Write-Host "Domain: $domain"


        $RanGen = -join ((97..122) | Get-Random -Count 10 | ForEach-Object {[char]$_})
        $RanGen += "@123"
        $password = ConvertTo-SecureString -String $RanGen -AsPlainText -Force
        $ou = "OU=Offshore,OU=Users,OU=_KAP Head Office,DC=kap"

        #Create the offshore
        New-ADUser -SamAccountName $username -UserPrincipalName "$username$domain" -GivenName $firstName -Surname $lastName -Name "$firstName $lastName" -Enabled $true -AccountPassword $password -ChangePasswordAtLogon $false -Path $ou -Server $domainController -EmailAddress $username$domain -displayname "$firstname $lastname"

        Write-Host "New user created successfully."
        Write-Host $username$domain
        Write-host $RanGen
    }
    "3" {
        Write-Host "Exiting script"
        exit
    }
}
Invoke-Command -Computername "SVR-DC-04" -ScriptBlock{  
    Start-ADSyncSyncCycle -Policytype Delta
}



do { #OLD WMS 
    $response = Read-Host "old WMS? (yes/no)"
    $response = $response.ToLower().Trim()
} while ($response -ne "yes" -and $response -ne "y" -and $response -ne "no" -and $response -ne "n")

if ($response -eq "yes" -or $response -eq "y") {
    Write-Host "Creating old WMS user"

    $RanGen2 = -join ((97..122) | Get-Random -Count 10 | ForEach-Object {[char]$_})
    $RanGen2 += "@456"
    #$password2 = ConvertTo-SecureString -String $RanGen2 -AsPlainText -Force

    Write-Host "WMS PW: $RanGen2"

    $serverName = "XXX"
    $databaseName = "XXX"
    $credentials = Get-Credential -credential KAP\abradt  # Enter your database credentials when prompted

    $query = @"
       INSERT INTO dbo.[user] (username, password, first_name, last_name, pick_high, pick_heavy, expired, email, isGarysStore, default_warehouse_id, isDriver)
       VALUES ('$username', '$RanGen2', '$firstname', '$lastname', '0', '0', '0', '$username$domain', '0', '1', '0')
"@


    Invoke-Sqlcmd -ServerInstance $serverName -Database $databaseName -Query $query -TrustServerCertificate

    $query = @"
    INSERT INTO wmsKAPDB.dbo.user_x_permission
    SELECT (SELECT [user_id] FROM wmsAllDB.dbo.[user] WHERE username = '$username')
      ,permission_id
     FROM wmsKAPDB.dbo.user_x_permission p
    WHERE [user_id] = 1966

"@

    Invoke-Sqlcmd -ServerInstance $serverName -Database $databaseName -Query $query -TrustServerCertificate
 
    Write-Host "Old WMS user created"

} else {
    Write-Host "No old WMS created"
    # Add any cleanup or exit logic here
}


do { #KSYS
    $response = Read-Host "KSYS? (yes/no)"
    $response = $response.ToLower().Trim()
} while ($response -ne "yes" -and $response -ne "y" -and $response -ne "no" -and $response -ne "n")

if ($response -eq "yes" -or $response -eq "y") {
    Write-host "Creating KSYS User"
    $firstname | Out-File -filePath C:\scripts\NewUser.txt
    $Lastname | Out-File -filePath C:\scripts\NewUser.txt -Append
    "$Username$domain" | Out-File -filePath C:\scripts\NewUser.txt -Append
    $RanGen | Out-File -filePath C:\scripts\NewUser.txt -Append
    $RanGen | Out-File -filePath C:\scripts\NewUser.txt -Append
    "$Username$domain" | Out-File -filePath C:\scripts\NewUser.txt -Append
    Start-Process "https://wms.autoshack.com/"
    Read-Host "Verify logged in.. Enter to continue"
    Start-Process -Filepath "C:\Scripts\AutoHotKey\WMS.ahk"



} else {
    Write-Host "No KSYS created"
    # Add any cleanup or exit logic here
}



do { #Azure License
    $response = Read-Host "License? (yes/no)"
    $response = $response.ToLower().Trim()
} while ($response -ne "yes" -and $response -ne "y" -and $response -ne "no" -and $response -ne "n")

if ($response -eq "yes" -or $response -eq "y") {
    Write-Host "Adding License."
    Connect-MgGraph -Scopes User.ReadWrite.All, Organization.Read.All
    Write-Host "Waiting for sync to complete"
    #Start-Sleep -s 60
    #$user = Get-MGUser -Filter "Userprincipalname eq '$username$domain'"
    $id = Get-MgUser -Filter "Userprincipalname eq '$username$domain'"
    Update-MgUser -UserId $id.Id -UsageLocation CA
    #Update-MgUser testuser29@autoshack.com -DisplayName "edited"
    $o365Sku = Get-MgSubscribedSku -All | Where SkuPartNumber -eq 'O365_BUSINESS_PREMIUM' #is actually Microsoft 365 Business Standard
    try{
        Set-MgUserLicense -UserId $id.Id -AddLicenses @{SkuId = $o365Sku.SkuId} -RemoveLicenses @()
    }
    catch {
        write-host "error on license assignment, contact Intellisyn"
        Write-host "Creating email for new rogers user"
        $recipient = "support@intellisyn.com"
        $subject = "Autoshack MS Licensing"
        $body = 
        "Hello Intellisyn, we need another Microsoft 365 Business Standard license, 

Thanks, have a great day!"
        $outlook = New-Object -ComObject Outlook.Application

        $mail = $outlook.CreateItem(0)

        $mail.To = $recipient
        $mail.Subject = $subject
        $mail.Body = $body

        $mail.Display()
    }
   
    Write-Host "Assigned Microsoft 365 Business Standard to $username$domain"
} else {
    Write-Host "No License added"
}

<#
if($group -eq "accounting"){
    Write-Host "adding user to shared mailbox"
    Add-MailboxPermission -Identity "Accoutning" -User "$username" -AccessRights FullAccess -InheritanceType All
}
#>

do { #Rogers
    $response = Read-Host "Rogers Phone? (yes/no)"
    $response = $response.ToLower().Trim()
} while ($response -ne "yes" -and $response -ne "y" -and $response -ne "no" -and $response -ne "n")

if ($response -eq "yes" -or $response -eq "y") {

    Start-Process "https://mybusinesshub.rogers.com/dashboard"
    Write-host "Creating email for new rogers user"
    $recipient = "rogers.businesssupport@rci.rogers.com  "
    $subject = "New user on rogers phone"
    $body = 
    "Hello, this is XXX from XXX we are on boarding a new user and need a soft phone setup for them with the following info:

Account number: XXX
Firstname: $firstname
Lastname: $lastname
Email: $username$domain
Phone#: XXX-XXX-XXXX

Thanks, have a great day! 
    "
    $outlook = New-Object -ComObject Outlook.Application

    $mail = $outlook.CreateItem(0)

    $mail.To = $recipient
    $mail.Subject = $subject
    $mail.Body = $body

    $mail.Display()

    # Clean up the Outlook application object
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($mail) | Out-Null
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($outlook) | Out-Null
    Remove-Variable outlook -ErrorAction SilentlyContinue
} else {
    Write-Host "No Rogers phone created"
    # Add any cleanup or exit logic here
}

do { #NetSuite
    $response = Read-Host "NetSuite? (yes/no)"
    $response = $response.ToLower().Trim()
} while ($response -ne "yes" -and $response -ne "y" -and $response -ne "no" -and $response -ne "n")

if ($response -eq "yes" -or $response -eq "y") {
    Write-Host "Creating NetSuite user"
    $firstname | Out-File -filePath C:\scripts\NewUserNS.txt
    $Lastname | Out-File -filePath C:\scripts\NewUserNS.txt -Append
    "$Username$domain" | Out-File -filePath C:\scripts\NewUserNS.txt -Append
    $RanGen | Out-File -filePath C:\scripts\NewUserNS.txt -Append
    Start-process C:\scripts\NewUserNS.txt
    Start-Process "https://4200237.app.netsuite.com/app/common/entity/employee.nl?whence="
    Read-host "Verify logged in.. Enter to continue (Currently your last automated step)"


} else {
    Write-Host "No NetSuite created"
    # Add any cleanup or exit logic here
}

read-host “Press ENTER to continue...”
