#AutoNewUser.ps1
#Created by: Anthony Bradt
#Modifications by: Lukas Millar

# First time setup (Run these commands as admin)
<#
Add-WindowsCapability -Online -Name "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0"
Add-WindowsCapability -Online -Name "Rsat.RemoteDesktop.Services.Tools~~~~0.0.1.0"
powershell Set-ExecutionPolicy RemoteSigned
Install-Module -name sqlserver
Install-Module -name Microsoft.Graph.Authentication
Install-Module -name Microsoft.Graph.Identity.DirectoryManagement
Install-Module -Name Microsoft.Graph.Users
Install-Module -Name Microsoft.Graph.Users.Actions
#>

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


### Function to Create Home Folder and assign Permissions ###

function New-UserHomeFolder {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Username
    )

    # Construct full user identity
    $fullUser = "XXX\$Username"

    # Define folder path
    $folderPath = "\\XXX\Home Folders\$Username"

    # Create the folder if it doesn't already exist
    if (-Not (Test-Path -Path $folderPath)) {
        try {
            New-Item -Path $folderPath -ItemType Directory -Force | Out-Null
            Write-Output "✅ Folder created successfully at: $folderPath"
        } catch {
            Write-Error "❌ Failed to create folder: $_"
            return
        }
    } else {
        Write-Output "ℹ️ Folder already exists at: $folderPath"
    }

    # Grant Modify (Edit) permissions to the user
    try {
        $acl = Get-Acl -Path $folderPath

        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $fullUser,
            "Modify",
            "ContainerInherit,ObjectInherit",
            "None",
            "Allow"
        )

        $acl.AddAccessRule($accessRule)
        Set-Acl -Path $folderPath -AclObject $acl

        Write-Output "✅ Granted 'Modify' permissions to $fullUser on $folderPath"
    } catch {
        Write-Error "❌ Failed to set permissions: $_"
    }
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
    Write-Host "1. XXX"
    Write-Host "2. OffShore"
    Write-Host "3. Exit"
    
    $choice = Read-Host "Enter the number of your choice"
    $choice = $choice.Trim()
} while ($choice -ne "1" -and $choice -ne "2" -and $choice -ne "3" -and $choice -ne "4")

switch ($choice) {
    "1" {
        Write-Host "Creating an XXX Employee"
        $username = ($firstName.Substring(0, 1) + $lastName).ToLower()
        $RanGen = -join ((97..122) | Get-Random -Count 10 | ForEach-Object {[char]$_})
        $RanGen += "@123"
        $password = ConvertTo-SecureString -String $RanGen -AsPlainText -Force
        $domain = "@XXX.com"
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
                Write-host "manually add accounting shared mailbox to user"
                $ou = "OU=Accounting,OU=Users,OU=_XXX Head Office,DC=XXX"
                $pcou = "OU=WS - Accounting,OU=Workstations,OU=_XXX Head Office,DC=XXX"

                # Create the user
                New-ADUser -SamAccountName $username -UserPrincipalName "$username$domain" -GivenName $firstName -Surname $lastName -Name "$firstName $lastName" -Enabled $true -AccountPassword $password -ChangePasswordAtLogon $true -Path $ou -Server $domainController -EmailAddress $username$domain -StreetAddress "115 Journeyman Street" -City "Kanata" -State "Ontario" -PostalCode "K2T 0N7" -Company "Autoshack" -displayname "$firstname $lastname" -Description $Postion -Title $Postion -HomeDrive "M:" -HomeDirectory "\\svr-fs-02\home folders\$username" -Country "ca" 
                Write-Host "New user created successfully."
                Write-Host $username$domain
                Write-host $RanGen

                Start-Sleep -s 10

                Add-ADGroupMember -Identity "Accounting" -Members $username
                Add-ADGroupMember -Identity "Office" -Members $username

                $group = "accounting"

                New-UserHomeFolder -Username $username

            }
            "2" {
                Write-Host "Adding user to CSR"
                $ou = "OU=CSR,OU=Users,OU=_XXX Head Office,DC=XXX"
                $pcou = "OU=WS - CSR,OU=Workstations,OU=_XXX Head Office,DC=XXX"
               

                # Create the user
                New-ADUser -SamAccountName $username -UserPrincipalName "$username$domain" -GivenName $firstName -Surname $lastName -Name "$firstName $lastName" -Enabled $true -AccountPassword $password -ChangePasswordAtLogon $true -Path $ou -Server $domainController -EmailAddress $username$domain -StreetAddress "115 Journeyman Street" -City "Kanata" -State "Ontario" -PostalCode "K2T 0N7" -Company "Autoshack" -displayname "$firstname $lastname" -Description $Postion -Title $Postion -HomeDrive "M:" -HomeDirectory "\\svr-fs-02\home folders\$username" -Country "ca" 
                Write-Host "New user created successfully."
                Write-Host $username$domain
                Write-host $RanGen

                Start-Sleep -s 10

                Add-ADGroupMember -Identity "carrierclaims" -Members $username
                Add-ADGroupMember -Identity "Contact Center Ottawa" -Members $username
                Add-ADGroupMember -Identity "CSR Printer" -Members $username
                Add-ADGroupMember -Identity "CSRs" -Members $username


                New-UserHomeFolder -Username $username
            }
            "3" {
                Write-Host "Adding user to Dev"
                $ou = "OU=Dev,OU=Users,OU=_XXX Head Office,DC=XXX"
                $pcou = "OU=WS - Dev,OU=Workstations,OU=_XXX Head Office,DC=XXX"
                
                # Create the user
                New-ADUser -SamAccountName $username -UserPrincipalName "$username$domain" -GivenName $firstName -Surname $lastName -Name "$firstName $lastName" -Enabled $true -AccountPassword $password -ChangePasswordAtLogon $true -Path $ou -Server $domainController -EmailAddress $username$domain -StreetAddress "115 Journeyman Street" -City "Kanata" -State "Ontario" -PostalCode "K2T 0N7" -Company "Autoshack" -displayname "$firstname $lastname" -Description $Postion -Title $Postion -HomeDrive "M:" -HomeDirectory "\\svr-fs-02\home folders\$username" -Country "ca" 
                Write-Host "New user created successfully."
                Write-Host $username$domain
                Write-host $RanGen

                Start-Sleep -s 10

                Add-ADGroupMember -Identity "Database Administrators" -Members $username
                Add-ADGroupMember -Identity "DevAdmin" -Members $username
                Add-ADGroupMember -Identity "IT Dept" -Members $username


                New-UserHomeFolder -Username $username

            }
            "4" {
                Write-Host "Adding user to Management"
                $ou = "OU=Managment,OU=Users,OU=_XXX Head Office,DC=XXX"
                $pcou = "OU=WS - Managment,OU=Workstations,OU=_XXX Head Office,DC=XXX"
                
                # Create the user
                New-ADUser -SamAccountName $username -UserPrincipalName "$username$domain" -GivenName $firstName -Surname $lastName -Name "$firstName $lastName" -Enabled $true -AccountPassword $password -ChangePasswordAtLogon $true -Path $ou -Server $domainController -EmailAddress $username$domain -StreetAddress "115 Journeyman Street" -City "Kanata" -State "Ontario" -PostalCode "K2T 0N7" -Company "Autoshack" -displayname "$firstname $lastname" -Description $Postion -Title $Postion -HomeDrive "M:" -HomeDirectory "\\svr-fs-02\home folders\$username" -Country "ca" 
                Write-Host "New user created successfully."
                Write-Host $username$domain
                Write-host $RanGen

                New-UserHomeFolder -Username $username
           
            }
            "5" {
                Write-Host "Adding user to Purchasing"
                $ou = "OU=Purchasing,OU=Users,OU=_XXX Head Office,DC=XXX"
                $pcou = "OU=WS - Purchasing,OU=Workstations,OU=_XXX Head Office,DC=XXX"
                
                # Create the user
                New-ADUser -SamAccountName $username -UserPrincipalName "$username$domain" -GivenName $firstName -Surname $lastName -Name "$firstName $lastName" -Enabled $true -AccountPassword $password -ChangePasswordAtLogon $true -Path $ou -Server $domainController -EmailAddress $username$domain -StreetAddress "115 Journeyman Street" -City "Kanata" -State "Ontario" -PostalCode "K2T 0N7" -Company "Autoshack" -displayname "$firstname $lastname" -Description $Postion -Title $Postion -HomeDrive "M:" -HomeDirectory "\\svr-fs-02\home folders\$username" -Country "ca" 
                Write-Host "New user created successfully."
                Write-Host $username$domain
                Write-host $RanGen

                Start-Sleep -s 10

                Add-ADGroupMember -Identity "Data - Full Control" -Members $username
                Add-ADGroupMember -Identity "Data Processing" -Members $username
                Add-ADGroupMember -Identity "Data Processing Printer" -Members $username


                New-UserHomeFolder -Username $username
   
            }
            "6" {
                Write-Host "Adding user to Data"
                $ou = "OU=Data,OU=Users,OU=_XXX Head Office,DC=XXX"
                $pcou = "OU=WS - Data,OU=Workstations,OU=_XXX Head Office,DC=XXX"
                
                # Create the user
                New-ADUser -SamAccountName $username -UserPrincipalName "$username$domain" -GivenName $firstName -Surname $lastName -Name "$firstName $lastName" -Enabled $true -AccountPassword $password -ChangePasswordAtLogon $true -Path $ou -Server $domainController -EmailAddress $username$domain -StreetAddress "115 Journeyman Street" -City "Kanata" -State "Ontario" -PostalCode "K2T 0N7" -Company "Autoshack" -displayname "$firstname $lastname" -Description $Postion -Title $Postion -HomeDrive "M:" -HomeDirectory "\\svr-fs-02\home folders\$username" -Country "ca" 
                Write-Host "New user created successfully."
                Write-Host $username$domain
                Write-host $RanGen

                Start-Sleep -s 10

                Add-ADGroupMember -Identity "Data - Full Control" -Members $username
                Add-ADGroupMember -Identity "Data Processing" -Members $username
                Add-ADGroupMember -Identity "Data Processing Printer" -Members $username


                New-UserHomeFolder -Username $username


  
            }
            "7" {
                Write-Host "Adding user to Retail"
                $ou = "OU=Retail,OU=Users,OU=_XXX Head Office,DC=XXX"
                $pcou = "OU=WS - Retail,OU=Workstations,OU=_XXX Head Office,DC=XXX"
                
                # Create the user
                New-ADUser -SamAccountName $username -UserPrincipalName "$username$domain" -GivenName $firstName -Surname $lastName -Name "$firstName $lastName" -Enabled $true -AccountPassword $password -ChangePasswordAtLogon $true -Path $ou -Server $domainController -EmailAddress $username$domain -StreetAddress "115 Journeyman Street" -City "Kanata" -State "Ontario" -PostalCode "K2T 0N7" -Company "Autoshack" -displayname "$firstname $lastname" -Description $Postion -Title $Postion -HomeDrive "M:" -HomeDirectory "\\svr-fs-02\home folders\$username" -Country "ca" 
                Write-Host "New user created successfully."
                Write-Host $username$domain
                Write-host $RanGen

                Start-Sleep -s 10

                Add-ADGroupMember -Identity "Office" -Members $username
                Add-ADGroupMember -Identity "PC Store - Plain" -Members $username
                Add-ADGroupMember -Identity "PC Store Printer" -Members $username


                New-UserHomeFolder -Username $username
         
            }
            "8" {
                Write-Host "Adding user to Warehouse"
                $ou = "OU=Warehouse,OU=Users,OU=_XXX Head Office,DC=XXX"
                $pcou = "OU=WS - Warehouse,OU=Workstations,OU=_XXX Head Office,DC=XXX"
                
                # Create the user
                New-ADUser -SamAccountName $username -UserPrincipalName "$username$domain" -GivenName $firstName -Surname $lastName -Name "$firstName $lastName" -Enabled $true -AccountPassword $password -ChangePasswordAtLogon $true -Path $ou -Server $domainController -EmailAddress $username$domain -StreetAddress "115 Journeyman Street" -City "Kanata" -State "Ontario" -PostalCode "K2T 0N7" -Company "Autoshack" -displayname "$firstname $lastname" -Description $Postion -Title $Postion -HomeDrive "M:" -HomeDirectory "\\svr-fs-02\home folders\$username" -Country "ca" 
                Write-Host "New user created successfully."
                Write-Host $username$domain
                Write-host $RanGen

                Start-Sleep -s 10

                Add-ADGroupMember -Identity "Office" -Members $username
                Add-ADGroupMember -Identity "Shipping Printer" -Members $username
                Add-ADGroupMember -Identity "WarehouseEmail" -Members $username


                New-UserHomeFolder -Username $username
           
            }
            "9" {
                Write-Host "Adding user to Warehouse Office"
                $ou = "OU=Warehouse Office,OU=Users,OU=_XXX Head Office,DC=XXX"
                $pcou = "OU=WS - ShippingOffice,OU=Workstations,OU=_XXX Head Office,DC=XXX"
                
                # Create the user
                New-ADUser -SamAccountName $username -UserPrincipalName "$username$domain" -GivenName $firstName -Surname $lastName -Name "$firstName $lastName" -Enabled $true -AccountPassword $password -ChangePasswordAtLogon $true -Path $ou -Server $domainController -EmailAddress $username$domain -StreetAddress "115 Journeyman Street" -City "Kanata" -State "Ontario" -PostalCode "K2T 0N7" -Company "Autoshack" -displayname "$firstname $lastname" -Description $Postion -Title $Postion -HomeDrive "M:" -HomeDirectory "\\svr-fs-02\home folders\$username" -Country "ca" 
                Write-Host "New user created successfully."
                Write-Host $username$domain
                Write-host $RanGen

                Start-Sleep -s 10

                Add-ADGroupMember -Identity "Office" -Members $username
                Add-ADGroupMember -Identity "Operations" -Members $username
                Add-ADGroupMember -Identity "Purchasing Group" -Members $username
                Add-ADGroupMember -Identity "Purchasing Users" -Members $username


                New-UserHomeFolder -Username $username
             

             }
             "10" {
                Write-Host "Adding user to Human Resources"
                $ou = "OU=HR,OU=Users,OU=_XXX Head Office,DC=XXX"
                $pcou = "OU=WS - HR,OU=Workstations,OU=_XXX Head Office,DC=XXX"
                
                # Create the user
                New-ADUser -SamAccountName $username -UserPrincipalName "$username$domain" -GivenName $firstName -Surname $lastName -Name "$firstName $lastName" -Enabled $true -AccountPassword $password -ChangePasswordAtLogon $true -Path $ou -Server $domainController -EmailAddress $username$domain -StreetAddress "115 Journeyman Street" -City "Kanata" -State "Ontario" -PostalCode "K2T 0N7" -Company "Autoshack" -displayname "$firstname $lastname" -Description $Postion -Title $Postion -HomeDrive "M:" -HomeDirectory "\\svr-fs-02\home folders\$username" -Country "ca" 
                Write-Host "New user created successfully."
                Write-Host $username$domain
                Write-host $RanGen

                Start-Sleep -s 10

                Add-ADGroupMember -Identity "Data - Full Control" -Members $username
                Add-ADGroupMember -Identity "Data Processing" -Members $username
                Add-ADGroupMember -Identity "Data Processing Printer" -Members $username


                New-UserHomeFolder -Username $username

            }
            "11" {
                Write-Host "Adding user to Marketing"
                $ou = "OU=Marketing,OU=Users,OU=_XXX Head Office,DC=XXX"
                $pcou = "OU=WS - Marketing,OU=Workstations,OU=_XXX Head Office,DC=XXX"
                
                # Create the user
                New-ADUser -SamAccountName $username -UserPrincipalName "$username$domain" -GivenName $firstName -Surname $lastName -Name "$firstName $lastName" -Enabled $true -AccountPassword $password -ChangePasswordAtLogon $true -Path $ou -Server $domainController -EmailAddress $username$domain -StreetAddress "115 Journeyman Street" -City "Kanata" -State "Ontario" -PostalCode "K2T 0N7" -Company "Autoshack" -displayname "$firstname $lastname" -Description $Postion -Title $Postion -HomeDrive "M:" -HomeDirectory "\\svr-fs-02\home folders\$username" -Country "ca" 
                Write-Host "New user created successfully."
                Write-Host $username$domain
                Write-host $RanGen

                Start-Sleep -s 10

                Add-ADGroupMember -Identity "Data - Full Control" -Members $username
                Add-ADGroupMember -Identity "Data Processing" -Members $username
                Add-ADGroupMember -Identity "Data Processing Printer" -Members $username


                New-UserHomeFolder -Username $username
            }
        }
        #Move the PC
        Move-ADObject -Identity $PC.ObjectGUID -TargetPath $pcou
        Start-Sleep -Seconds 1
        $PC = Get-ADComputer -Identity $PCName -Properties *
        write-host $PC.Description
        write-host $PC.CanonicalName
        write-host $PC.ObjectGUID

        Set-ADComputer -Identity $PCName -Description $username

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
        $ou = "OU=Offshore,OU=Users,OU=_XXX Head Office,DC=XXX"

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
Invoke-Command -Computername "XXX" -ScriptBlock{  
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
    $credentials = Get-Credential -credential XXX\me  # Enter your database credentials when prompted

    $query = @"
       INSERT INTO dbo.[user] (username, password, first_name, last_name, pick_high, pick_heavy, expired, email, XXX, default_warehouse_id, isDriver)
       VALUES ('$username', '$RanGen2', '$firstname', '$lastname', '0', '0', '0', '$username$domain', '0', '1', '0')
"@


    Invoke-Sqlcmd -ServerInstance $serverName -Database $databaseName -Query $query -TrustServerCertificate

    $query = @"
    INSERT INTO wmsXXXDB.dbo.user_x_permission
    SELECT (SELECT [user_id] FROM wmsAllDB.dbo.[user] WHERE username = '$username')
      ,permission_id
     FROM wmsXXXDB.dbo.user_x_permission p
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
    Start-Process "https://XXX.com/"
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
        write-host "error on license assignment, contact XXX"
        $recipient = "X@XX.com"
        $subject = "Autoshack MS Licensing"
        $body = 
        "Hello XXX, we need another Microsoft 365 Business Standard license, 

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
    $recipient = "X@XX.com  "
    $subject = "New user on rogers phone"
    $body = "
	
	make your own
	
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
    Start-Process "XXX"
    Read-host "Verify logged in.. Enter to continue (Currently your last automated step)"


} else {
    Write-Host "No NetSuite created"
    # Add any cleanup or exit logic here
}

read-host “Press ENTER to continue...”