# StorageSpaceCheck_linux
#This script checks the 5 linux nodes for their remaining drive space, on lack of space send alert
#Created by: Anthony Bradt


# ====== Config ======
$LinuxHosts = @(
    "XXX@XXX",
    "XXX@XXX",
    "XXX@XXX",
    "XXX@XXX",
    "XXX@XXX"
)

$scriptname = "StorageSpaceCheck_Linux"

. \\XXX\c$\Scripts\AS-CallBryce.ps1 
. \\XXX\c$\Scripts\AS-SendEmail.ps1 

$HitFlag = 0

# ====== Main ======
foreach ($hosts in $LinuxHosts) {
    $output = ssh $hosts "/usr/local/bin/get_disk.sh"
    write-host $output

    foreach ($line in $output) {
        # Expect: "36 /dev/sda2"
        $parts = $line -split ' '
        $used  = [int]$parts[0]
        $dev   = $parts[1]

        write-host $used "% used"

        if ($used -gt 90) {
            $HitFlag = 1
            $subject = "[HIGH] : $scriptname : $hostname : $hosts $dev at $used%"
            $body    = "Device $dev on $hosts is critically full ($used%)."
            AS-SendEmail -Subject $subject -Body $body
            AS-CallBryce -Message "Linux storage alert: [HIGH] $hosts $dev at $used%"
        }
        elseif ($used -gt 80) {
            $HitFlag =1
            $subject = "[LOW] : $scriptname : $hostname : $hosts $dev at $used%"
            $body    = "Device $dev on $hosts is getting full ($used%)."
            AS-SendEmail -Subject $subject -Body $body
        }
    }
}
if ($HitFlag -eq 0){
    AS-CallBryce -Resolved
}
