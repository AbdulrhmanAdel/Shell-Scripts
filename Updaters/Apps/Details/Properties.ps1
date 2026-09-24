[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $Path,
    # Optional regex with a "Version" group, for exes whose FileVersion carries extra parts
    # e.g. Brave "154.1.96.59" (chromium major + brave version) -> '^\d+\.(?<Version>.+)$'
    [string]
    $VersionPattern
)

if (-not (Test-Path -LiteralPath $Path)) {
    return @{
        Version = $null
    }
}

$itemInfo = Get-ItemProperty -LiteralPath $Path;
$version = $itemInfo.VersionInfo.FileVersion;
if ($VersionPattern -and $version -match $VersionPattern) {
    $version = $Matches.Version;
}

return @{
    Version = $version
}
