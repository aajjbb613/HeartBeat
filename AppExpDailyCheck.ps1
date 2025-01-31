$ClientId = "XXX"
$TenantId = "XXX"
$ClientSecret = "XXX"

# Convert the client secret to a secure string
$ClientSecretPass = ConvertTo-SecureString -String $ClientSecret -AsPlainText -Force

# Define the URL to get an access token
$tokenUrl = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"

# Define the body for the token request
$body = @{
    client_id     = $ClientId
    client_secret = $ClientSecret
    scope         = "https://graph.microsoft.com/.default"
    grant_type    = "client_credentials"
}

# Retrieve the access token
$tokenResponse = Invoke-RestMethod -Method Post -Uri $tokenUrl -ContentType "application/x-www-form-urlencoded" -Body $body
$token = $tokenResponse.access_token

# Set the Graph API URL to get all applications
$graphApiUri = "https://graph.microsoft.com/v1.0/applications"

# Send a request to Microsoft Graph to retrieve all applications
$applications = Invoke-RestMethod -Method Get -Uri $graphApiUri -Headers @{ Authorization = "Bearer $token" }

# Prepare an array to store applications with their expiration dates
$appExpirations = @()

$currentDate = Get-Date

# Further processing logic for $applications can go here

# Loop through each application
foreach ($app in $applications.value) {
    # Initialize expiration details
    $appName = $app.displayName
    $appId = $app.appId

    # Process key credentials (certificates)
    if ($app.keyCredentials) {
        foreach ($key in $app.keyCredentials) {
            $date = get-date $key.endDateTime
            if($date -le $currentDate.AddDays(30)){
                $expDetails = [PSCustomObject]@{
                    AppName    = $appName
                    AppId      = $appId
                    Type       = "Certificate"
                    Expiration = $key.endDatetime
                }
                $appExpirations += $expDetails
                $email = $true
            }
        }
    }

    # Process password credentials (secrets)
    if ($app.passwordCredentials) {
        foreach ($secret in $app.passwordCredentials) {
            $date = get-date $secret.endDateTime
            if($date -le $currentDate.AddDays(30)){
                $expDetails = [PSCustomObject]@{
                    AppName    = $appName
                    AppId      = $appId
                    Type       = "Secret"
                    Expiration = $secret.endDatetime
                }
                $appExpirations += $expDetails
                $email = $true
            }
        }
    }
}

if ($email) {
    $body = "The following Azure AD App Registrations have credentials expiring within the next 30 days:`n`n"
    
    foreach ($cred in $expDetails) {
        $body += "App Name: $($cred.AppName)`n"
        $body += "App IP: $($cred.AppId)`n"
        $body += "Credential Type: $($cred.Type)`n"
        $body += "Expiry Date: $($cred.Expiration)`n"
        $body += "`n"
    }

    #old send
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
        Subject = "Service Status Alert"
        Credential = $cred
    }

    Send-MailMessage @mailParams -Body $body | Write-Host

    Write-Host "Email sent with details of expiring credentials."
} else {
    Write-Host "No credentials expiring within the next 30 days."
}

# Output the expiration details for all apps
$appExpirations | Format-Table -AutoSize
