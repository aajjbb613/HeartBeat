<# 
.SYNOPSIS
  Send new Inbox & Sent Items emails to Graylog (GELF UDP), deduped by a local state file.

.REQUIREMENTS
  - App Registration with Graph Application permissions:
      Mail.Read (Application)
  - Admin consent granted
  - Client ID, Client Secret, Tenant ID
  - Mailbox UPN to read (the target mailbox; app must have access)
  - Network reachability to Graylog UDP 12201 (or your chosen port)

.NOTES
  - Built for Windows PowerShell 5.x (no '??' null-coalescing)
  - State file prevents duplicates and tracks last processed timestamps
#>

# ====================== USER CONFIG ======================
# ---- Azure AD / Graph App (Client Credentials) ----
$TenantId     = "XXX"
$ClientId     = "XXX"
$ClientSecret = "XXX"

# Mailbox to read (UPN or ID). Example: "X@XXX"
$MailboxUpn   = "X@XXX.com"

# ---- Graylog GELF UDP ----
$GraylogHost  = "XXX"   # change to your Graylog IP/hostname
$GraylogPort  = 12201

# ---- Run parameters ----
$PageSize             = 50         # Messages per page (Graph cap typically <= 1000 but be kind)
$MaxProcessedIdBuffer = 2000       # Keep last N processed IDs in state to avoid dupes around clock skew
$InitialLookbackHours = 24         # If no state file exists, start from this many hours ago
$StateFilePath        = "C:\Flags\Graylog\email-gelf-state.json"
# =========================================================


# -------------------- Helpers --------------------

function Get-PlainTextFromBody {
    param([object]$Message)
    # Prefer bodyPreview (already plain text & short), fallback to body.content (HTML or text)
    $text = $null
    if ($Message.bodyPreview) {
        $text = [string]$Message.bodyPreview
    } elseif ($Message.body -and $Message.body.content) {
        $text = [string]$Message.body.content
        # If it's HTML, strip tags quickly (best-effort) and decode entities
        if ($Message.body.contentType -and $Message.body.contentType -match '^html$') {
            $text = ($text -replace '<[^>]+>', ' ')
            try { $text = [System.Web.HttpUtility]::HtmlDecode($text) } catch {}
        }
    }
    if ([string]::IsNullOrWhiteSpace($text)) { $text = '' }
    # Collapse whitespace
    $text = ($text -replace '\s+', ' ').Trim()
    return $text
}

function Trim-ForGelf {
    param([string]$Value, [int]$MaxChars = 700)
    if ([string]::IsNullOrEmpty($Value)) { return $Value }
    if ($Value.Length -le $MaxChars) { return $Value }
    return ($Value.Substring(0, $MaxChars) + '…')
}


function Ensure-Directory {
    param([string]$Path)
    $dir = [System.IO.Path]::GetDirectoryName($Path)
    if (-not [string]::IsNullOrWhiteSpace($dir) -and -not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

function Load-State {
    param([string]$Path)
    if (Test-Path $Path) {
        try {
            $raw = Get-Content -Path $Path -Raw -ErrorAction Stop
            $obj = $null
            if (-not [string]::IsNullOrWhiteSpace($raw)) {
                $obj = $raw | ConvertFrom-Json
            }
            if ($obj) { return $obj }
        } catch { }
    }
    # Default state (lookback start)
    $dt = (Get-Date).ToUniversalTime().AddHours(-1 * [int]$InitialLookbackHours).ToString("o")
    return [pscustomobject]@{
        LastInboxTime = $dt
        LastSentTime  = $dt
        ProcessedIds  = @()
    }
}

function Save-State {
    param([string]$Path, [object]$State, [int]$MaxIds)
    Ensure-Directory -Path $Path
    # Cap ProcessedIds length
    if ($State.ProcessedIds -and $State.ProcessedIds.Count -gt $MaxIds) {
        $State.ProcessedIds = $State.ProcessedIds[-$MaxIds..($State.ProcessedIds.Count-1)]
    }
    ($State | ConvertTo-Json -Depth 6) | Set-Content -Path $Path -Encoding UTF8
}

function Get-GraphToken {
    param(
        [string]$TenantId,
        [string]$ClientId,
        [string]$ClientSecret
    )
    $tokenUrl = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
    $body = @{
        client_id     = $ClientId
        client_secret = $ClientSecret
        scope         = "https://graph.microsoft.com/.default"
        grant_type    = "client_credentials"
    }
    $resp = Invoke-RestMethod -Method Post -Uri $tokenUrl -Body $body -ContentType "application/x-www-form-urlencoded"
    return $resp.access_token
}

function Invoke-Graph {
    param(
        [string]$Url,
        [string]$Token
    )
    $headers = @{ Authorization = "Bearer $Token" }
    $retries = 3
    for ($i=0; $i -lt $retries; $i++) {
        try {
            return Invoke-RestMethod -Method Get -Uri $Url -Headers $headers -ErrorAction Stop
        } catch {
            # Respect simple backoff on 429/5xx
            Start-Sleep -Seconds ([Math]::Pow(2, $i) * 2)
        }
    }
    throw "Failed to GET $Url after $retries attempts."
}

function New-GelfUdpClient {
    param([string]$Hostname, [int]$Port)
    $udp = New-Object System.Net.Sockets.UdpClient
    $udp.Connect($Hostname, $Port)
    return $udp
}

function Send-GelfMessage {
    param(
        [System.Net.Sockets.UdpClient]$UdpClient,
        [string]$ShortMessage,
        [hashtable]$Fields
    )
    write-host "$ShortMessage"
    if ($ShortMessage -like "Message from*") {
        write-host "stoped from transmiting" 
        return
    }
    # not so working
    $lvl = 6 #info
    if ($ShortMessage.StartsWith("[HIGH]")){
        $lvl = 3 #error
    }
    if (-not $Fields) { $Fields = @{} }
    $payload = @{
        version       = "1.1"
        host      = $env:COMPUTERNAME
        short_message = $ShortMessage
        level         = $lvl
        timestamp = [double]([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())
    }

    # Attach as GELF additional fields (prefixed underscore)
    foreach ($k in $Fields.Keys) {
        $payload["_$k"] = $Fields[$k]
    }

    $json  = $payload | ConvertTo-Json -Compress
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
    [void]$UdpClient.Send($bytes, $bytes.Length)
    write-host "sent $payload"
}

function New-QueryUrl {
    param(
        [string]$Mailbox,
        [string]$Folder,          # "inbox" or "sentitems"
        [string]$SinceIso,        # ISO8601 timestamp
        [int]$Top,
        [switch]$Inbox
    )
    if ($Inbox.IsPresent) {
        $timeField = "receivedDateTime"
    }
    else {
        $timeField = "sentDateTime"
    }
    # Select minimal useful fields for Graylog enrichment (+ body fields)
    $select = "id,$timeField,sentDateTime,receivedDateTime,subject,from,toRecipients,internetMessageId,body"


    # $filter and $orderby (ASC so we can safely bump last processed time)
    $base = "https://graph.microsoft.com/v1.0/users/$Mailbox/mailFolders/$Folder/messages" +
            "?`$select=$select&`$orderby=$timeField asc&`$top=$Top&`$count=true"
    if (-not [string]::IsNullOrWhiteSpace($SinceIso)) {
        $base += "&`$filter=$timeField ge $([uri]::EscapeDataString($SinceIso))"
    }
    return $base
}

function Enumerate-Messages {
    param(
        [string]$Mailbox,
        [string]$Folder,
        [string]$SinceIso,
        [int]$Top,
        [string]$Token,
        [switch]$Inbox
    )
    $url = New-QueryUrl -Mailbox $Mailbox -Folder $Folder -SinceIso $SinceIso -Top $Top -Inbox:$Inbox

    while ($true) {
        $data = Invoke-Graph -Url $url -Token $Token

        if ($data.value) { 
            foreach ($m in $data.value) { 
                $m
            }
        }

        if ($data.'@odata.nextLink') {
            $url = $data.'@odata.nextLink'
        } else {
            break
        }
    }
}

# -------------------- Main --------------------

try {
    # Load & prep state
    $state = Load-State -Path $StateFilePath
    if (-not $state.ProcessedIds) { $state.ProcessedIds = @() }
    $processedSet = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($id in $state.ProcessedIds) { [void]$processedSet.Add($id) }

    # Get token
    $token = Get-GraphToken -TenantId $TenantId -ClientId $ClientId -ClientSecret $ClientSecret

    # UDP client
    $udp = New-GelfUdpClient -Hostname $GraylogHost -Port $GraylogPort

    # Track max times as we go
    $maxInboxTime = [DateTime]::Parse($state.LastInboxTime).ToUniversalTime()
    $maxSentTime  = [DateTime]::Parse($state.LastSentTime).ToUniversalTime()

    # -------- INBOX (received) --------
    Write-Host "Fetching Inbox since $($state.LastInboxTime) ..."
    $inboxMsgs = Enumerate-Messages -Mailbox $MailboxUpn -Folder "inbox" -SinceIso $state.LastInboxTime -Top $PageSize -Token $token -Inbox

    foreach ($m in $inboxMsgs) {
        $id   = $m.id
        Write-Host $id
        if ($processedSet.Contains($id)) { continue }

        # Get the message time
        $receivedStr = $m.receivedDateTime
        $received    = $null
        if (-not [string]::IsNullOrWhiteSpace($receivedStr)) {
            $received = [DateTime]::Parse($receivedStr).ToUniversalTime()
        } else {
            # Fallback: use current UTC
            $received = (Get-Date).ToUniversalTime()
        }

        # Update max time
        if ($received -gt $maxInboxTime) { $maxInboxTime = $received }

        # Build fields for Graylog
        $from = $null
        if ($m.from -and $m.from.emailAddress -and $m.from.emailAddress.address) {
            $from = $m.from.emailAddress.address
        }
        $toList = @()
        if ($m.toRecipients) {
            foreach ($t in $m.toRecipients) {
                if ($t.emailAddress -and $t.emailAddress.address) {
                    $toList += $t.emailAddress.address
                }
            }
        }

        $bodyText = Get-PlainTextFromBody -Message $m
        $bodyTrim = Trim-ForGelf -Value $bodyText -MaxChars 700

        $fields = @{
            direction          = "received"
            folder             = "Inbox"
            message_id         = $id
            internetMessageId  = $m.internetMessageId
            from               = $from
            to                 = ($toList -join ";")
            receivedDateTime   = $m.receivedDateTime
            sentDateTime       = $m.sentDateTime
            body               = $bodyTrim
        }

        $subject = $m.subject
        if ([string]::IsNullOrWhiteSpace($subject)) { $subject = "(no subject)" }

        Send-GelfMessage -UdpClient $udp -ShortMessage $subject -Fields $fields

        # Record processed
        [void]$processedSet.Add($id)
    }

    # -------- SENT ITEMS (sent) --------
    Write-Host "Fetching Sent Items since $($state.LastSentTime) ..."
    $sentMsgs = Enumerate-Messages -Mailbox $MailboxUpn -Folder "sentitems" -SinceIso $state.LastSentTime -Top $PageSize -Token $token

    foreach ($m in $sentMsgs) {
        $id = $m.id
        Write-Host $id
        if ($processedSet.Contains($id)) { continue }

        $sentStr = $m.sentDateTime
        $sentDt  = $null
        if (-not [string]::IsNullOrWhiteSpace($sentStr)) {
            $sentDt = [DateTime]::Parse($sentStr).ToUniversalTime()
        } else {
            $sentDt = (Get-Date).ToUniversalTime()
        }

        if ($sentDt -gt $maxSentTime) { $maxSentTime = $sentDt }

        $from = $null
        if ($m.from -and $m.from.emailAddress -and $m.from.emailAddress.address) {
            $from = $m.from.emailAddress.address
        }
        $toList = @()
        if ($m.toRecipients) {
            foreach ($t in $m.toRecipients) {
                if ($t.emailAddress -and $t.emailAddress.address) {
                    $toList += $t.emailAddress.address
                }
            }
        }

        $bodyText = Get-PlainTextFromBody -Message $m
        $bodyTrim = Trim-ForGelf -Value $bodyText -MaxChars 700

        $fields = @{
            direction          = "sent"
            folder             = "Sent Items"
            message_id         = $id
            internetMessageId  = $m.internetMessageId
            from               = $from
            to                 = ($toList -join ";")
            receivedDateTime   = $m.receivedDateTime
            sentDateTime       = $m.sentDateTime
            body               = $bodyTrim
        }

        $subject = $m.subject
        if ([string]::IsNullOrWhiteSpace($subject)) { $subject = "(no subject)" }

        Send-GelfMessage -UdpClient $udp -ShortMessage $subject -Fields $fields

        [void]$processedSet.Add($id)
    }

    # Cleanup
    $udp.Close()

    # Save updated state
    $state.LastInboxTime = $maxInboxTime.ToString("o")
    $state.LastSentTime  = $maxSentTime.ToString("o")
    $state.ProcessedIds  = @($processedSet.GetEnumerator())
    Save-State -Path $StateFilePath -State $state -MaxIds $MaxProcessedIdBuffer

    Write-Host "Done. State saved to $StateFilePath"
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    throw
}
