#URLRequestCheckAuth.ps1
#This script checks rates and returns for vaild returned data
#Created by: Anthony Bradt


# =========================
# URLRequestCheckAuth.ps1
# =========================
# Adds per-URL flagging:
# - First consecutive fail for a URL => [LOW]
# - Second consecutive fail for the same URL => [HIGH]
# - Success for a URL clears its flag

$ErrorActionPreference = 'Stop'


. \\XXX\c$\Scripts\AS-CallBryce.ps1 
. \\XXX\c$\Scripts\AS-SendEmail.ps1 

# --- Auth setup (unchanged) ---
$clientId = "XXX"
$clientSecret = "XXX"

$scriptname = "RateReturnsCheck"
# 

$headers = @{
    'Content-Type' = 'application/x-www-form-urlencoded'
}

$body = @{
    'grant_type'    = 'client_credentials'
    'client_id'     = $clientId
    'client_secret' = $clientSecret
}

$AccessToken = Invoke-RestMethod -Uri 'https://identity.XXX.com/connect/token' -Method Post -Headers $headers -Body $body

$headers = @{
    'accept' = '*/*'
    'Authorization' = ('Bearer ' + $AccessToken.access_token)
    'Content-Type' = 'application/json'
}

# --- Requests (unchanged) ---
$requests = @(
    @{ 
        Url = 'https://api.returns.XXX.com:8081/Returns/return/rate'
        Body = @{
            originalSalesOrderId = "6581368"
            returnAuthId = "1234567"
            parts = @(
                @{
                    partSKU = "PCD1623"
                    quantity = 1
                }
            )
        }
    }
    @{
        Url = 'https://api.rates.XXX.com:8081/api/Retail/availability'
        Body = @{
            customerZip = "K2S 1E7"
            products = @(
                @{
                    sku = "HB613123PR"
                    quantity = 1
                }
            )
        }
    }
)

# --- NEW: Flag storage (per-URL) ---
$FlagDir = 'C:\Scripts\flags\api-checks'
if (-not (Test-Path $FlagDir)) { New-Item -ItemType Directory -Path $FlagDir | Out-Null }

function Get-FlagPath {
    param([string]$url)
    # simple filesystem-safe filename using a hash for stability
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes($url)
        $hash  = [System.BitConverter]::ToString($sha.ComputeHash($bytes)).Replace('-','').Substring(0,12)
    } finally { $sha.Dispose() }
    $safe = ($url -replace '[:/\\?&=#\s]','_')
    Join-Path $FlagDir "$safe`__$hash.fail"
}

# --- Existing tracking (kept) ---
$failedRequests = @()
$allSuccess = $true

foreach ($request in $requests) {
    try {
        $response = Invoke-RestMethod -Uri $request.Url -Method 'Post' -Headers $headers -Body ($request.Body | ConvertTo-Json -Depth 5) -ContentType 'application/json'
        Write-Host "Request succeeded for URL: $($request.Url)" -ForegroundColor Green

        # NEW: clear flag for this URL on success
        $flag = Get-FlagPath -url $request.Url
        if (Test-Path $flag) { Remove-Item $flag -Force -ErrorAction SilentlyContinue }
    }
    catch {
        $allSuccess = $false
        $failedRequests += @{
            Url = $request.Url
            Error = $_.Exception.Message
            StatusCode = $_.Exception.Response.StatusCode.value__
        }
        Write-Host "Request failed for URL: $($request.Url)" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

if ($allSuccess -eq $true) {
    Write-Output "All requests successfully returned 200 status code."
}
else {
    Write-Output "One or more requests failed to return 200 status code."
    Write-Output "Sending email notification for failed requests."

    # NEW: compute LOW vs HIGH subject based on per-URL flags
    $anyHigh = $false
    foreach ($f in $failedRequests) {
        $flag = Get-FlagPath -url $f.Url
        if (Test-Path $flag) {
            # second consecutive failure => HIGH
            $anyHigh = $true
        }
        else {
            # first failure => create the flag, LOW
            New-Item -ItemType File -Path $flag -Force | Out-Null
        }
    }
    $subjectTag = if ($anyHigh) { "[HIGH]" } else { "[LOW]" }

    $Subject = "$subjectTag : $scriptname : $env:COMPUTERNAME : Failed Returns API Requests"
    # Body format preserved; just ensuring line breaks
    $body = ($failedRequests | ForEach-Object {
        "URL: $($_.Url)`nError: $($_.Error)`nStatus Code: $($_.StatusCode)`n"
    }) -join "`n"
    
    As-SendEmail -Body $body -Subject $Subject | Write-Host
    Write-Host $body

    if($subjectTag -eq "[HIGH]"){
        As-CallBryce -Message "$body"
    }
}
