Write-Host "Welcome to autoshack's Create-A-ServiceAccount"
 
$SvrName = Read-Host "Enter the server name"

$DC = "svr-dc-04"
 
$pingResult = Test-Connection -ComputerName $SvrName -Count 1 -ErrorAction SilentlyContinue
if ($pingResult -ne $null) {
    Write-Host "Ping successful! Server is reachable."
    $Name = $SvrName -replace '^svr-', ''
    $Name = $Name -replace '-', ''
    $SaName = $Name + "-SA"
    if($SaName.Length > 14){
        $SaName = Write-Host "SA too long, enter manually"
    }
    Write-Host "Service account name: $SaName"
    $GpName = $Name + "-Group"
    Write-Host "Group account name: $GpName"
    $DNSName = $SaName + ".kap"
    Write-Host $DNSName
 
    
 
    Invoke-Command -ComputerName $DC -ScriptBlock{ 
        New-ADServiceAccount -name $Using:SaName -DNSHostName $Using:DNSName -Enabled $true -ManagedPasswordIntervalInDays 30
        Start-Sleep -Seconds 5
        Add-ADComputerServiceAccount -Identity $Using:SvrName -ServiceAccount $Using:SaName
        Start-Sleep -Seconds 5
        New-ADGroup -Name $Using:GpName  -GroupCategory Security -GroupScope Global
        Start-Sleep -Seconds 5
        $NewSvrName = $Using:SvrName + "$"
        Write-Host $NewSvrName
        Add-ADGroupMember -Identity $Using:GpName -Members $NewSvrName
        Start-Sleep -Seconds 5
        Set-ADServiceAccount -PrincipalsAllowedToRetrieveManagedPassword $Using:GpName -identity $Using:SaName
        Start-Sleep -Seconds 5
    }
 
    Invoke-Command -ComputerName $SvrName  -ScriptBlock{
        Add-WindowsFeature RSAT-AD-PowerShell,RSAT-AD-AdminCenter
        klist.exe -li 0x3e7 purge
        gpupdate /force
        Install-ADServiceAccount -Identity $Using:SaName
    }
 
} else {
    Write-Host "Ping failed. Server is unreachable."
}
