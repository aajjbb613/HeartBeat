#URLCheck_High.ps1
#This script hits a list of URLs looking for successfull responses. alerts on errors. 
#Created by: Anthony Bradt


#Revamp complete

<# Minimal site checker using FLAGS ONLY for severity

- Success: HTTP 2xx/3xx (redirects OK)
- Failure: 4xx/5xx or request error (DNS/TLS/timeout)
- Flags (per site):
    * Create C:\Scripts\flags\sitecheck\<site>.fail on failure
    * If flag exists next run and site is still failing => [HIGH]
    * Remove flag when site is healthy
- Email: ALWAYS on failure (LOW or HIGH)
#>

. \\XXX\c$\Scripts\AS-CallBryce.ps1 
. \\XXX\c$\Scripts\AS-SendEmail.ps1 

# ======== Config ========
$TimeoutSec = 30
$FlagDir    = 'C:\Scripts\flags\sitecheck'
$hostname = hostname
$scriptname = "URLCheck_High"

$Sites = @(
    'https://XXX.com',
    'https://XXX.ca',
    'https://api.tms.XXX.com:8081/index.html',
    'https://api.rates.XXX.com:8081/index.html',
    'https://api.rates.XXX.com:443',
    'http://XXX/#/queues'
 )


# ======== Helpers ========
function Ensure-FlagDir { if (-not (Test-Path $FlagDir)) { New-Item -ItemType Directory -Path $FlagDir -Force | Out-Null } }

function Check-One([string]$Url, [int]$TimeoutSec) {
  $ua = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Safari/537.36'
  $start = Get-Date
  try {
    $resp = Invoke-WebRequest -Uri $Url -Method GET -TimeoutSec $TimeoutSec -ErrorAction Stop -Headers @{ 'User-Agent' = $ua }
    $code  = [int]$resp.StatusCode
    $final = $Url; try { $final = $resp.BaseResponse.ResponseUri.AbsoluteUri } catch { }
    $latMs = [int]((Get-Date) - $start).TotalMilliseconds
    $ok    = ($code -ge 200 -and $code -lt 400)  # 2xx/3xx ok
    return [pscustomobject]@{
      Url=$Url; FinalUrl=$final; StatusCode=$code; Reason=$resp.StatusDescription
      IsFailure = [bool](-not $ok)   # force boolean
      LatencyMs=$latMs; ErrorMessage=$null
    }
  }
  catch [System.Net.WebException] {
    $we = $_.Exception
    $code = $null; $reason = $null; $final = $Url
    if ($we.Response -and $we.Response -is [System.Net.HttpWebResponse]) {
      $code   = [int]$we.Response.StatusCode
      $reason = $we.Response.StatusDescription
      try { $final = $we.Response.ResponseUri.AbsoluteUri } catch { }
    }
    $latMs = [int]((Get-Date) - $start).TotalMilliseconds
    return [pscustomobject]@{
      Url=$Url; FinalUrl=$final; StatusCode=$code
      Reason=($(if ($reason) {$reason} else {'Request failed'}))
      IsFailure = $true
      LatencyMs=$latMs; ErrorMessage=$we.Message
    }
  }
  catch {
    $latMs = [int]((Get-Date) - $start).TotalMilliseconds
    return [pscustomobject]@{
      Url=$Url; FinalUrl=$Url; StatusCode=$null
      Reason='Unhandled error'; IsFailure=$true; LatencyMs=$latMs; ErrorMessage=$_.Exception.Message
    }
  }
}

# ======== Main ========
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Ensure-FlagDir

Write-Host "Checking $($Sites.Count) sites..."

$results = @()
foreach ($u in $Sites) {
  Write-Host "[INFO] $u"
  $r = Check-One -Url $u -TimeoutSec $TimeoutSec
  if ($r.IsFailure) {
    Write-Warning ("[FAIL] {0} -> {1} {2} ({3}ms) {4}" -f $r.Url, $r.StatusCode, $r.Reason, $r.LatencyMs, $(if ($r.FinalUrl -ne $r.Url) {"Final: $($r.FinalUrl)"} else {""}))
    if ($r.ErrorMessage) { Write-Warning "       Error: $($r.ErrorMessage)" }
  } else {
    Write-Host   ("[OK]   {0} -> {1} {2} ({3}ms) {4}" -f $r.Url, $r.StatusCode, $r.Reason, $r.LatencyMs, $(if ($r.FinalUrl -ne $r.Url) {"Final: $($r.FinalUrl)"} else {""}))
  }
  $results += $r
}

# ----- Flags & severity (FLAGS ONLY) -----
$failures = @($results | Where-Object { $_.IsFailure })  # robust filter
Write-Host "DEBUG: failures detected = $($failures.Count)"

# Remove flags for recovered sites
$healthy = $results | Where-Object { -not $_.IsFailure }
foreach ($h in $healthy) {
  $flagName = ($h.Url -replace '[^A-Za-z0-9._-]','_')
  $flagPath = Join-Path $FlagDir ($flagName + '.fail')
  if (Test-Path $flagPath) { try { Remove-Item $flagPath -Force -ErrorAction SilentlyContinue } catch { } }
}

if ($failures.Count -gt 0) {
  $lines = @()
  $anyRepeat = $false

  foreach ($f in $failures) {
    $flagName = ($f.Url -replace '[^A-Za-z0-9._-]','_')
    $flagPath = Join-Path $FlagDir ($flagName + '.fail')
    $wasFail  = Test-Path $flagPath

    $codeTxt  = if ($null -ne $f.StatusCode) { $f.StatusCode } else { 'N/A' }
    $finalTxt = if ($f.FinalUrl -and $f.FinalUrl -ne $f.Url) { " | Final: $($f.FinalUrl)" } else { "" }
    $errTxt   = if ($f.ErrorMessage) { " | Error: $($f.ErrorMessage)" } else { "" }
    $repeatTxt= if ($wasFail) { " | Repeat" } else { "" }
    $lines += "- $($f.Url) -> Status: $codeTxt ($($f.Reason)) | Latency: $($f.LatencyMs)ms$finalTxt$errTxt$repeatTxt"

    if ($wasFail) { $anyRepeat = $true }

    # ensure flag exists on failure
    try { Set-Content -Path $flagPath -Value ("Failed at " + (Get-Date)) -Encoding ASCII -Force } catch { }
  }

  # flags-only severity: HIGH if any repeat, else LOW
  $prefix = if ($anyRepeat) { "[HIGH]" } else { "[LOW]" }

  $body = "The following sites failed health check:`r`n`r`n" +
          ($lines -join "`r`n") +
          "`r`n`r`n--`r`nChecked: " + ($Sites -join ', ') +
          "`r`nTimestamp: " + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') +
          "`r`nTimeout: ${TimeoutSec}s"

  Write-Host "Sending email with subject prefix $prefix (failures: $($failures.Count))"
  try {
    AS-SendEmail -Subject "$prefix : $scriptname : $hostname : Site Health Check Failures" -Body $body
    Write-Host "Email sent."
    if ($prefix -eq "[HIGH]"){
        write-host "Sending call"
        AS-CallBryce -Message "Failed Sites: $lines" -NOQT
    }
  } catch {
    Write-Error "Failed to send alert email: $($_.Exception.Message)"
  }

  exit 2
}
else {
  Write-Host "[OK] All sites healthy."
  AS-CallBryce -Resolved
  exit 0
}
