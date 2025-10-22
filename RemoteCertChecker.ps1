# List of websites to check
$websites = @(
    "https://www.XXX.com",
    "https://www.XXX.ca",
    "https://XXX.com",
    "https://XXX.ca"
)

# Define alert threshold (days before expiry)
$thresholdDays = 30

# Email configuration
$username = "XXX@XXX.com"
$password = "XXX"
$myPwd = ConvertTo-SecureString -String $password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential -ArgumentList $username, $myPwd

$mailParams = @{
    SmtpServer = 'smtp.office365.com'
    Port = '587'
    UseSSL = $true
    From = 'XXX@XXX.com'
    To = 'XXXGroup@XXX.com'
    Subject = "[HIGH] : RemoteCertChecker.ps1 : XXX: XXX SSL Certificate Issue Detected"
    Credential = $cred
}

function Check-SSLCertificates {
    param($sites)

    $expiringCertificates = @()

    foreach ($site in $sites) {
        try {
            Write-Host "Checking SSL certificate for $site"

            $request  = [System.Net.HttpWebRequest]::Create($site)
            $response = $request.GetResponse()
            $response.Dispose()

            # Minimal fix: wrap in X509Certificate2 and use NotAfter (DateTime)
            $cert2 = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($request.ServicePoint.Certificate)
            $expiryDate = $cert2.NotAfter
            $daysRemaining = ($expiryDate - (Get-Date)).Days

            Write-Host "$site expires on $expiryDate ($daysRemaining days remaining)"
            if ($daysRemaining -le $thresholdDays) {
                Write-Host "hit"
                $expiringCertificates += "$site - Expiry Date: $expiryDate ($daysRemaining days remaining)"
            }
        }
        catch {
            Write-Host "Error checking SSL certificate for $site - $_"
            $expiringCertificates += "$site - Error retrieving SSL certificate."
        }
    }
    Write-Host $expiringCertificates
    return $expiringCertificates
}


# First check
$firstCheckResults = Check-SSLCertificates -sites $websites

# If issues found, wait 1 minute and check again
if ($firstCheckResults.Count -gt 0) {
    Write-Output "SSL certificate issues detected. Waiting 1 minute before rechecking..."
    write-Output "firstcheck:" + $firstCheckResults
    Start-Sleep -Seconds 60
    
    $secondCheckResults = Check-SSLCertificates -sites $websites
    
    # Only send alert if issues persist after second check
    if ($secondCheckResults.Count -gt 0) {
        $emailBody = "The following sites have SSL certificate issues (confirmed after retry):`n`n" + ($secondCheckResults -join "`n")

        Write-Output "Sending alert email..."
        #Send-MailMessage @mailParams -Body $emailBody
        Write-Output $emailBody
    } else {
        Write-Output "SSL certificate issues resolved on retry. No alert sent."
    }
} else {
    Write-Output "All SSL certificates are valid."
}
