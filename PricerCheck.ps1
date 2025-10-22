# --- Config ---
$ServerInstance   = "XXX"   # change as needed
$Database         = "Pricing"
$SqlUser          = "XXX"
$SqlPassword      = "XXX"
$TimeoutSeconds   = 30

$connectionString = "Server=$ServerInstance;Database=$Database;User ID=$SqlUser;Password=$SqlPassword;Connect Timeout=$TimeoutSeconds;Encrypt=True;TrustServerCertificate=True"

# --- Query ---
$query = @"
SELECT TOP (1) [Status]
FROM [Pricing].[dbo].[PriceUploads]
ORDER BY [Id] DESC;
"@

# --- Run Query using ADO.NET ---
$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connectionString

$command = $connection.CreateCommand()
$command.CommandText = $query

$connection.Open()
$result = $command.ExecuteScalar()
$connection.Close()

# --- Output the latest Status ---
Write-Host "Latest Status:" $result

if ($result -ne 3){
    . \\svr-pdq-01\c$\Scripts\AS-SendEmail.ps1
    AS-SendEmail -Subject "[HIGH] Pricer upload failed" -Body "Pricing DB on XXX has reported an issue with the most recent pricer update. Current status: $result"
}
