#ManhattanOrdersSyncCheck.ps1
#This script checks the Manhattan DB on XXX for the most recent order that has been verifyed in scale, alerts on lack of change.
#Created by: Anthony Bradt


#Dosnt run on saturdays
if ((Get-Date).DayOfWeek -eq 'Saturday') {
    write-host "script dosnt run on saturdays"
    return
}

$stateFile = "C:\Temp\ManhattanOrdersSyncCheck.json"
$scriptname = "ManhattanOrdersSyncCheck"

. \\XXX\c$\Scripts\AS-CallBryce.ps1 
. \\XXX\c$\Scripts\AS-SendEmail.ps1 

#SQL config
$ServerInstance = 'XXX'
$Database       = 'Manhattan'
$SqlUser        = 'XXX'
$SqlPassword    = 'XXX'
$TimeoutSeconds = 45

$connectionString = "Server=$ServerInstance;Database=$Database;User ID=$SqlUser;Password=$SqlPassword;Connect Timeout=$TimeoutSeconds;Encrypt=True;TrustServerCertificate=True"

# SQL query
$query = @"
SELECT TOP (1) [SalesOrderId]
FROM [Manhattan].[dbo].[SalesOrder]
WHERE [VerifiedInScale] IS NOT NULL
  AND SalesChannel NOT IN ('Canada : Wholesale', 'Canada : Retail')
ORDER BY [SalesOrderId] DESC;
"@
# Load .NET SQL Client
Add-Type -AssemblyName System.Data

# Create connection and command
$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connectionString

$command = $connection.CreateCommand()
$command.CommandText = $query

try {
    $connection.Open()

    # Execute query
    $output = $command.ExecuteScalar()
}
catch {
    Write-Error "Error querying database: $_"
}
finally {
    $connection.Close()
}

# SQL run query END



# Tracking File
if (-not (Test-Path $stateFile)) {
    @{ LastId = 0; LastSeen = (Get-Date).ToString("o") } | ConvertTo-Json | Set-Content $stateFile
}

$currentId = $num

$currentId = [int](([string]$output).Trim())

# Load Last State
$state = Get-Content $stateFile | ConvertFrom-Json
$lastId = [int]$state.LastId
$lastSeen = [datetime]::Parse($state.LastSeen)

if (-not $output) { 
    Write-Host "No output from query"
    $subject = "[HIGH] : $scriptname : $env:COMPUTERNAME : Manhattan failed to query"
    $body = "Last Order ID with VerifiedInScale was $lastId at $lastSeen"
    AS-SendEmail -Subject $subject -Body $body
    Write-Host $body
    write-host "Sending call"
    AS-CallBryce -Message $subject
    exit
}

if ($currentId -gt $lastId) {
    # New order found → update state
    $state.LastId = $currentId
    $state.LastSeen = (Get-Date).ToString("o")
    $state | ConvertTo-Json | Set-Content $stateFile
    Write-Host "New order detected: $currentId"
    exit
}

# Alert required detection
$elapsed = (New-TimeSpan -Start $lastSeen -End (Get-Date)).TotalMinutes
$hourNow = (Get-Date).Hour
$elapsed = [Math]::Round($elapsed) 

if ($elapsed -ge 90) {
    $subject = "[HIGH] : $scriptname : $env:COMPUTERNAME : No new orders VerifiedInScale"
    $body = "Last Order ID with VerifiedInScale was $elapsed min ago $lastId at $lastSeen."
    AS-SendEmail -Subject $subject -Body $body
    Write-Host $body
    write-host "Sending call"
    AS-CallBryce -Message $subject -NOQT
    }
elseif ($elapsed -ge 60) {
    $subject = "[LOW] : $scriptname : $env:COMPUTERNAME : No new orders VerifiedInScale"
    $body = "Last Order ID with VerifiedInScale was $elapsed min ago $lastId at $lastSeen."
    AS-SendEmail -Subject $subject -Body $body
    Write-Host $body
}
else {
    Write-Host "Orders are flowing normally. Last ID=$lastId, $([math]::Round($elapsed,1)) min since last."
    AS-CallBryce -Resolved
}
