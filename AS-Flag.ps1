function AS-Flag {
    param(
        [Parameter(Mandatory)][string]$FlagName,
        [switch]$Remove
    )

    $flagPath = "C:\Flags\$FlagName"

    if ($Remove) {
        if (Test-Path $flagPath) {
            Remove-Item $flagPath -Force
        }
        return
    }

    if (Test-Path $flagPath) {
        # File already exists → consecutive failure
        return "[HIGH]"
    }
    else {
        # First failure → create flag file
        New-Item -Path $flagPath -ItemType File -Force | Out-Null
        return "[LOW]"
    }
}
