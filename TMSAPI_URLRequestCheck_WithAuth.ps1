$clientId = "XXX"
$clientSecret = "XXX"

$headers = @{
    'Content-Type' = 'application/x-www-form-urlencoded'
}

$body = @{
    'grant_type'    = 'client_credentials'
    'client_id'     = $clientId
    'client_secret' = $clientSecret
}

$AccessToken = Invoke-RestMethod -Uri 'https://identity.XXX.com' -Method Post -Headers $headers -Body $body

$headers = @{
    'accept' = '*/*'
    'Authorization' = ('Bearer ' + $AccessToken.access_token)
    'Content-Type' = 'application/json'
}

$requests = @(
    @{ Url = 'https://XXX'; Body = @{ customerAddress = @{ addressLine1 = "4410 Still Creek Dr"; city = "Nepean"; state = "ON"; country = "CA"; postalCode = "K2J 6S1" }; packages = @(@{ dimensions = "21.34X15.27X7.65"; weight = 32.41; parts = @(@{ productSKU = "SCD924"; quantity = 1; unitWeight = 3.64; unitPrice = 22.73; harmonizedTariffCode = "8708.80.1300" }) }) } }
    @{ Url = 'https://XXX'; Body = @{ customerAddress = @{ addressLine1 = "27080 MALLARD AVE"; addressLine2 = ""; city = "EUCLID"; state = "OH"; country = "US"; postalCode = "44132" }; packages = @(@{ dimensions = "21.34X15.27X7.65"; weight = 32.41; parts = @(@{ productSKU = "SCD924"; quantity = 1; unitWeight = 3.64; unitPrice = 22.73; harmonizedTariffCode = "8708.80.1300" }) }) } }
)

$failedRequests = @()
$allSuccess = $true

foreach ($request in $requests) {
    $response = Invoke-RestMethod -Uri $request.Url -Method 'Post' -Headers $headers -Body ($request.Body | ConvertTo-Json -Depth 5) -ContentType 'application/json'
    $response.rateResponses
    
    $hasValidRate = $false
    foreach ($rateInfo in $response.rateResponses) {
        if ($rateInfo.errorMessage -like "*Exception details: Got error response*") {
            Write-Host "Request succeeded with expected error for URL: $($request.Url)" -ForegroundColor Yellow
        }
        elseif ($rateInfo.success -eq $true -and $rateInfo.rate -ge 0) {
            $hasValidRate = $true
            break
        }
    }
    
    if (-not $hasValidRate) {
        $allSuccess = $false
        $failedRequests += $response.rateResponses
    } else {
        Write-Host "Request succeeded for URL: $($request.Url)" -ForegroundColor Green
    }
}

if ($allSuccess -eq $true) {
    Write-Output "All requests successfully retrieved valid shipping rates and met the conditions."
} else {
    Write-Output "One or more requests failed to meet the conditions."
    # Send email (you already have the code for the email)
    Write-Output "Sending email notification for failed requests."
    # Add your email sending code here

    $username = "XXX@XXX.com"
    $password = "XXX"
    $myPwd = ConvertTo-SecureString -string $password -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential -argumentlist $username, $myPwd

    $mailParams = @{
        SmtpServer = 'smtp.office365.com'
        Port = '587'
        UseSSL = $true
        From = 'XXX@XXX.com'
        To = 'XXXGroup@XXX.com'
        #To = 'XXX@XXX.com'
        Subject = "[HIGH] Failed Swagger Request"
        # Body = "Failed IPs: $IP"
        Credential = $cred
    }

    $body = ($failedRequests | ForEach-Object {
        $_ | Out-String
    }) -join "`n"
    Send-MailMessage @mailParams -Body $body | Write-Host
    Write-Host $body
    Write-Host $failedRequests
    #Start-Sleep -Seconds 900
}