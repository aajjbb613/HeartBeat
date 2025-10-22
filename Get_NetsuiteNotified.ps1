#Get_NetsuiteNotified.ps1
#This scripts connects to XXX where it runs a bash script that checks the local DB for the most recent fulfillment that has notified netsuite. if lack of chanage fires alerts.
#Created by: Anthony Bradt


#Putting the fun in functions
. \\XXX\c$\Scripts\AS-CallBryce.ps1 
. \\XXX\c$\Scripts\AS-SendEmail.ps1 
. \\XXX\c$\Scripts\AS-Flag.ps1 

$script= "/usr/local/bin/get_note_ns.sh" 
$stateFile = "C:\Flags\get_note_ns.last"

#runs script
$current   = (ssh XXX@XXX $script).Trim()

$hostname = hostname
$scriptname = "Get_NetsuiteNotified"

if (-not $current) { 
    Write-Host "No output from query"
    AS-SendEmail -Subject "[HIGH] : $scriptname : $hostname : XXX failed to query" -body "XXX failed to query"
    AS-CallBryce -Message "XXX failed to query"
    exit
}

#Checks if results match last run.
if (Test-Path $stateFile) {
    $previous = Get-Content $stateFile
    if ($current -ne $previous -or $current -eq '0') {
        Write-Host "Changed: Prev=$previous, Curr=$current"
        AS-Flag -FlagName $scriptname -Remove
        AS-CallBryce -Resolved
    } else {
        Write-Host "No change: $current"
        $tag = AS-Flag -FlagName $scriptname
        if($tag -eq "[HIGH]"){
            AS-CallBryce -Message "$tag : $scriptname : $hostname : fulfillment push. $current hasnt notified source"
        }
        AS-SendEmail -Subject "$tag : $scriptname : $hostname : fulfillment push" -body "Order: $current hasnt notified Netsuite."
    }
} else {
    Write-Host "First run: $current"
}

$current | Out-File $stateFile -Encoding ascii -Force