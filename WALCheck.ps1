#WALCheck.ps1
#This script connects to Postgres-ND6 and checks the size of the wal folder. If the folder is using more then 10GB send alerts
#Created by: Anthony Bradt


# ================= CONFIG =================
$LinuxHost = "XXX"
$LinuxUser = "XXX"
$WalDir    = "/var/lib/postgresql/16/main/pg_wal"
$Threshold = 10GB   # alert threshold
$scriptname = "WALCheck"

. \\XXX\c$\Scripts\AS-SendEmail.ps1 
# ===========================================

# Run sudo du over SSH (no password; -n makes sudo fail fast if misconfigured)
$out = ssh -o BatchMode=yes "$LinuxUser@$LinuxHost" "sudo -n /usr/bin/du -sb $WalDir" 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "SSH/sudo failed:`n$out"
    Write-Host "If you see 'sudo: a password is required', fix the sudoers entry on XXX."
    exit 1
}

# du prints: "<bytes>\t/path"
$firstField = ($out -split '\s+')[0]
if (-not [int64]::TryParse($firstField, [ref]([long]0))) {
    Write-Host "Unexpected du output: $out"
    exit 1
}
$walBytes = [int64]$firstField
$walGB = [math]::Round($walBytes / 1GB, 2)

if ($walBytes -gt $Threshold) {
    $emailBody = "The WAL directory $WalDir on $LinuxHost is ${walGB}GB, which is above the threshold of $Threshold.`n"

    Write-Output "Sending email"
    AS-SendEmail -Body $emailBody -Subject "[HIGH] : $scriptname : $env:COMPUTERNAME : WAL Size Alert: $LinuxHost"
    Write-Host $emailBody
} else {
    Write-Host "OK: WAL size is ${walGB}GB, under threshold."
}