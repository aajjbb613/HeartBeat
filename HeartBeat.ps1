$IP = '10.0.0.1' , '192.168.0.2' , '192.168.21.2' , '192.168.21.3' , '192.168.23.2' , '192.168.27.2' , '192.168.23.253' , '192.168.27.12'     , '192.168.27.2' , '192.168.27.3' , '192.168.24.13' , '192.168.24.2'          , '192.168.24.49' , '192.168.24.70' , '192.168.23.5' , '192.168.24.51' , '192.168.24.52' , '192.168.25.79' , '192.168.21.52'
$Name = 'Sophos' , 'Core'        , 'MainOffice1'  , 'MainOffice2'  , 'MainOffice3'  , 'CSROffice1'   , 'CSROffice4'     , 'NetGear Camera SW' ,'Warehouse1'    , 'Warehouse2'   , 'Man-rack2'     , 'Dell PowerConnect 2848','Lenovo DB610s'  , 'MGMT-SW1'      , 'CSRCameras'   , 'KAP-HV-01'     , 'KAP-HV-02'     , 'KAP-HV-03'     , 'Test Workstation'

#Add in your own Private IPs youd like to monitor then the hostname as well below
#Replace all 'XXX' with your info and switch file paths used


$Failed = ""  
$I = 0
$IP | ForEach-Object {
    $PingResults = ""
    $PingResults = ping $PSItem -n 2 | Select-String -Pattern "Reply"
    if ([string]::IsNullOrEmpty($PingResults)){
        Write-Output $PSItem
        if (Test-path -path C:\Users\abradt\Documents\HeartBeat\$PSItem.txt){

        }
        else{
            Out-File -FilePath C:\Users\abradt\Documents\HeartBeat\$PSItem.txt
            $Failed = $Failed + $Name[$I] + " " +$PSItem + "    " 
        }
    }
    else{
        if (Test-path -path C:\Users\abradt\Documents\HeartBeat\$PSItem.txt){
            Remove-Item -path C:\Users\abradt\Documents\HeartBeat\$PSItem.txt
        }
    }
    $I++
}

if ([string]::IsNullOrEmpty($Failed)){
    Write-Output "Heartbeat passed"
}
else{

    $username = "xxx"
    $password = "xxx"
    $myPwd = ConvertTo-SecureString -string $password -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential -argumentlist $username, $myPwd


    $mailParams = @{
        SmtpServer = 'smtp.office365.com'
        Port = '587'
        UseSSL = $true
        From = 'xxx@xxx.com'
        To = 'xxx@xxx.com'
        #To = 'xxx@xxx.com'
        Subject = "HeartBeat Failure"
        # Body = "Failed IPs: $IP"
        Credential = $cred
    }


    Send-MailMessage @mailParams -Body "Pings Failed: $Failed"
}
