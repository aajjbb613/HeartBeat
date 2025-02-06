# List of websites to check
$websites = @(
    "https://www.autoshack.com",
    "https://www.autoshack.ca",
    "https://autoshack.com",
    "https://autoshack.ca"
)

# Define alert threshold (days before expiry)
$thresholdDays = 30

# Email configuration
$username = "HeartBeat@autoshack.com"
$password = "XXX"
$myPwd = ConvertTo-SecureString -String $password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential -ArgumentList $username, $myPwd

$mailParams = @{
    SmtpServer = 'smtp.office365.com'
    Port = '587'
    UseSSL = $true
    From = 'HeartBeat@AutoShack.com'
    To = 'HeartBeatGroup@autoshack.com'
    Subject = "SSL Certificate Issue Detected"
    Credential = $cred
}

$expiringCertificates = @()

foreach ($site in $websites) {
    try {
        Write-Output "Checking SSL certificate for $site"

        # Create request
        $request = [System.Net.HttpWebRequest]::Create($site)
        $response = $request.GetResponse()

        $response.Dispose()
        $certificate = $request.ServicePoint.Certificate
        $Certificate.Issuer

        # Get expiration date
        $expiryDate = [datetime]::ParseExact($certificate.GetExpirationDateString(), "yyyy-MM-dd h:mm:ss tt", $null)

        write-host $expiryDate

        $daysRemaining = ($expiryDate - (Get-Date)).Days

        Write-Output "$site expires on $expiryDate ($daysRemaining days remaining)"

        # Check if the certificate is expired or close to expiry
        if ($daysRemaining -le $thresholdDays) {
            $expiringCertificates += "$site - Expiry Date: $expiryDate ($daysRemaining days remaining)"
        }

        
    }
    catch {
        Write-Output "Error checking SSL certificate for $site - $_"
        $expiringCertificates += "$site - Error retrieving SSL certificate."
    }
}

# Send alert if any certificates are expiring
if ($expiringCertificates.Count -gt 0) {
    $emailBody = "The following sites have SSL certificate issues:`n`n" + ($expiringCertificates -join "`n")

    Write-Output "Sending alert email..."
    Send-MailMessage @mailParams -Body $emailBody
    Write-Output $emailBody
} else {
    Write-Output "All SSL certificates are valid."
}
