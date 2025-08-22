[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $Path
)

$itemInfo = Get-ItemProperty -LiteralPath $Path;
return @{
    Version     = $itemInfo.VersionInfo.FileVersion
}