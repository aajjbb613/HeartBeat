#SQLCheck.ps1
#This script connects to every MSSQL DB, if it fails sends alerts. 
#Created by: Anthony Bradt
#Property of: AutoShack
#Revamp complete


param(
  [string]$ServerInstance = 'localhost',   # e.g. 'localhost' or 'localhost\SQLEXPRESS'
  [string]$Database       = 'master',
  [string]$SqlUser        = 'XXX',
  [string]$SqlPassword    = 'XXX',
  [int]$TimeoutSeconds    = 45
)

. \\XXX\c$\Scripts\AS-CallBryce.ps1 
. \\XXX\c$\Scripts\AS-SendEmail.ps1 

# ----- Paths & flag handling -----
$FlagDir  = 'C:\Scripts\flags'
$FlagFile = Join-Path $FlagDir 'mssql_conn_failed.flag'
if (-not (Test-Path $FlagDir)) { New-Item -ItemType Directory -Path $FlagDir -Force | Out-Null }

$scriptname = "SQLCheck"
# 

# Enforce TLS 1.2 for SMTP (legacy Send-MailMessage)
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

# ----- Build connection string -----
# TrustServerCertificate avoids TLS/cert validation problems on-box while keeping encrypt on.
$connectionString = "Server=$ServerInstance;Database=$Database;User ID=$SqlUser;Password=$SqlPassword;Connect Timeout=$TimeoutSeconds;Encrypt=True;TrustServerCertificate=True"

# ----- Attempt connection -----
$failed   = $false
$errMsg   = $null

try {
  Add-Type -AssemblyName System.Data
  $conn = New-Object System.Data.SqlClient.SqlConnection $connectionString
  $conn.Open()
  $cmd = $conn.CreateCommand()
  $cmd.CommandText = 'SELECT 1'
  [void]$cmd.ExecuteScalar()
  $conn.Close()
}
catch {
  $failed = $true
  $errMsg = ($_ | Out-String)
}

# ----- On success: clear flag and exit -----
if (-not $failed) {
    if (Test-Path $FlagFile) { Remove-Item $FlagFile -Force -ErrorAction SilentlyContinue }
    Write-Host "MSSQL connectivity OK to [$ServerInstance] / DB [$Database] as [$SqlUser]."
    AS-CallBryce -Resolved
    exit 0
}

# ----- On failure: determine severity from flag -----
$severity = if (Test-Path $FlagFile) { '[HIGH]' } else { '[LOW]' }
# Touch/create the flag to mark the failure
if (-not (Test-Path $FlagFile)) {
  New-Item -Path $FlagFile -ItemType File -Force | Out-Null
} else {
  (Get-Item $FlagFile).LastWriteTime = Get-Date
}


write-output "Sending email"

$Subject    = "$severity : $scriptname : $env:COMPUTERNAME : MSSQL connection failed ($ServerInstance | DB: $Database)"
# Body with quick diagnostics (PowerShell 5.1-safe null/empty checks)
$when       = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
$errDetails = if ([string]::IsNullOrWhiteSpace($errMsg)) { 'Unknown error' } else { $errMsg }

$emailBody = @(
  "Host: $env:COMPUTERNAME"
  "Instance: $ServerInstance"
  "Database: $Database"
  "SQL User: $SqlUser"
  "When: $when"
  ""
  "Error:"
  $errDetails
) -join [Environment]::NewLine

AS-SendEmail -Body $emailBody -Subject $Subject | Write-Host
Write-Host $emailBody

if ($severity == "[HIGH]"){
    AS-CallBryce -Message "SQL Connection issues: $emailBody"
}
#Start-Sleep -Seconds 900

exit 1
