[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $Path
)

if (-not (Test-Path -LiteralPath $Path)) {
    return @{
        Version = $null
    }
}

$itemInfo = Get-ItemProperty -LiteralPath $Path;
return @{
    Version = $itemInfo.VersionInfo.FileVersion
}