#IISCheck_PW.ps1
#This script is ran against all servers, it checks for IIS, IIS Sites & thier certs. If the certs have issues or are close to exp send email alerts.
#Created by: Anthony Bradt
#Requested by: lukas's mistake, miss you bro :(

# Check if IIS is installed and running test
Import-Module ServerManager

. \\XXX\c$\Scripts\AS-CallBryce.ps1 
. \\XXX\c$\Scripts\AS-SendEmail.ps1 

$SubjectTag = "[LOW]"
$scriptname = "IISCheck"
# 

if (-not (Get-WindowsFeature -Name Web-Server).Installed) {
    Write-Output "IIS is not installed on this server. Exiting script."
    exit
}

# Check if IIS service is running
$service = Get-Service -Name W3SVC -ErrorAction SilentlyContinue
if ($service -eq $null -or $service.Status -ne 'Running') {
    Write-Output "IIS is not running. Please ensure IIS is installed and running before executing this script. Exiting script."
    exit
}

# Rest of your script goes here...
Write-Output "IIS is installed and running. Proceeding with the rest of the script..."

# Import the WebAdministration module to work with IIS
Import-Module WebAdministration

# Get the current day of the week (0 = Sunday, 6 = Saturday)
$dayOfWeek = (Get-Date).DayOfWeek
 
# Check if today is Saturday or Sunday
$isWeekend = ($dayOfWeek -eq "Saturday" -or $dayOfWeek -eq "Sunday")
 
#Write-Output "Is it the weekend?: $isWeekend"
If($isWeekend){
    $AlertsDays = 25
}else{$AlertsDays = 30}


# Get the list of all IIS websites
$sites = Get-Website
$failedSites = @()

foreach ($site in $sites) {
    Write-Output "Site: $($site.Name)"
    
    # Check if the site is running
    if ($site.State -ne 'Started') {
        #$failedSites += "Site: $($site.Name) - Not Running"
        Write-Output "WARNING: Site '$($site.Name)' is not running. Skipping this site."
        continue
    }

    # Get the bindings for each site
    foreach ($binding in $site.Bindings.Collection) {
        if ($binding.protocol -eq 'https') {
            Write-Output "  Binding Information: $($binding.bindingInformation)"
            Write-Output "  Certificate Thumbprint: $($binding.CertificateHash)"
            Write-Output "  Certificate Store Name: $($binding.CertificateStoreName)"
            
            # Find the certificate in the LocalMachine store using the thumbprint
            $cert = Get-ChildItem -Path Cert:\LocalMachine\$($binding.CertificateStoreName) | Where-Object { $_.Thumbprint -eq $binding.CertificateHash }
            
            $siteFailed = $false
            $failureReasons = @()

            if ($cert) {
                # Check if the certificate is expired or expiring within the next 30 days
                $daysUntilExpiration = ($cert.NotAfter - (Get-Date)).Days
                if ($daysUntilExpiration -le 0) {
                    $failureReasons += "Certificate has expired"
                    Write-Output "  WARNING: Certificate has expired!"
                    $siteFailed = $true
                    $SubjectTag = "[HIGH]"
                } 
                elseif ($daysUntilExpiration -le $AlertsDays) { 
                    $failureReasons += "Certificate is expiring in $daysUntilExpiration days"
                    Write-Output "  WARNING: Certificate is expiring in $daysUntilExpiration days!"
                    $siteFailed = $true
                } else {
                    Write-Output "  Certificate Expiration Date: $($cert.NotAfter)"
                }

                # Check if the certificate's subject matches the binding host name or has a matching SAN (Subject Alternative Name)
                $bindingHostName = $binding.HostHeader
                $sanExtension = $cert.Extensions | Where-Object { $_.Oid.FriendlyName -eq 'Subject Alternative Name' }
                $sanNames = if ($sanExtension) { $sanExtension.Format(0) -replace 'DNS Name=','' -split ', ' } else { @() }
                
                if ($cert.Subject -match $bindingHostName -or $sanNames -contains $bindingHostName) {
                    Write-Output "  Certificate matches the binding host name or SAN."
                } else {
                    $failureReasons += "Certificate does not match the binding host name or SAN"
                    Write-Output "  WARNING: Certificate does not match the binding host name or SAN!"
                    $siteFailed = $true
                    $SubjectTag = "[HIGH]"
                }
            } else {
                $failureReasons += "Certificate not found in LocalMachine store for thumbprint: $($binding.CertificateHash)"
                Write-Output "  Certificate not found in LocalMachine store for thumbprint: $($binding.CertificateHash)"
                $siteFailed = $true
                $SubjectTag = "[HIGH]"
            }

            if ($siteFailed) {
                $failedSites += "Site: $($site.Name), Binding: $($binding.bindingInformation), Reasons: $($failureReasons -join '; ')"
            }
        }
    }
    Write-Output ""
}

# Output summary of failed sites
if ($failedSites.Count -gt 0) {
    Write-Output "Summary of issues found:"
    foreach ($failedSite in $failedSites) {
        Write-Output $failedSite
    }
} else {
    Write-Output "All sites are running and have valid certificates."
}

$hostname = hostname

# Send an email with the list of failed sites if any
if ($failedSites.Count -gt 0) {
    Write-Output "Sending email"

    $Subject = "$SubjectTag : $scriptname : $env:COMPUTERNAME : SSL Certificate Issue Detected"
    $emailBody = "The following sites have SSL certificate issues:`n`n" + ($failedSites -join "`n")

    AS-SendEmail -Body $emailBody -Subject $Subject
}

if ($SubjectTag -eq "[HIGH]"){
    AS-CallBryce -Message "SSL Cert issues, $emailBody"
}else{
    AS-CallBryce -Resolved
}
