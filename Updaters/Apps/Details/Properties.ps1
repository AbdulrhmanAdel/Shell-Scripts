[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $Path,
    # Optional regex with a "Version" group, for exes whose FileVersion carries extra parts
    # e.g. Brave "154.1.96.59" (chromium major + brave version) -> '^\d+\.(?<Version>.+)$'
    [string]
    $VersionPattern,
    # For exes with no version at all (e.g. OpenRGB): a file holding the installed version, which the app's updater writes
    [string]
    $VersionFile
)

if (-not (Test-Path -LiteralPath $Path)) {
    return @{
        Version = $null
    }
}

$itemInfo = Get-ItemProperty -LiteralPath $Path;
$version = $itemInfo.VersionInfo.FileVersion;
# Some exes (e.g. TeraCopy) only have the numeric version, not the FileVersion string. 0.0.0.0 (OpenRGB) means none
if (!"$version".Trim()) {
    $raw = $itemInfo.VersionInfo.FileVersionRaw;
    $version = $raw -and $raw -ne [version]'0.0.0.0' ? "$raw" : $null;
}
elseif ($version -eq '0.0.0.0') {
    $version = $null;
}
if (!$version -and $VersionFile -and (Test-Path -LiteralPath $VersionFile)) {
    $version = (Get-Content -LiteralPath $VersionFile -TotalCount 1).Trim();
}
if ($VersionPattern -and $version -match $VersionPattern) {
    $version = $Matches.Version;
}

return @{
    Version = $version
}
