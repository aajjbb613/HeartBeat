

#Call AD Sync
Invoke-Command -Computername "XXX" -ScriptBlock{  
    Start-ADSyncSyncCycle -Policytype Delta
}