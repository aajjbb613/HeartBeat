#AS-SendEmail.ps1

function AS-SendEmail {
    param(
        [Parameter(Mandatory)][string]$Subject,
        [Parameter(Mandatory)][string]$Body,
        [switch]$WhatIf
    )
    if($WhatIf){
        $To = "X@XX.com"
    }else {$To = "X@XX.com"}

    write-output "Sending email"

    $username = "X@XX.com"
    $password = "XXX"
    $myPwd = ConvertTo-SecureString -string $password -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential -argumentlist $username, $myPwd

    $mailParams = @{
        SmtpServer = 'smtp.office365.com'
        Port = '587'
        UseSSL = $true
        From = 'X@XX.com'
        To = $To
        Subject = $Subject
        Body = $Body
        Credential = $cred
    }

    Send-MailMessage @mailParams | Write-Host
    Write-Host "$Subject, $Body"
}