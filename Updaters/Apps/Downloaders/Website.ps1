[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    $Url,
    $VersionPattern = "v",
    $VersionPatternName = "Version",
    $CurrentVersion,
    [switch]
    $CheckOnly
)

# Only detects the version for now, it has no way to find the download link yet
$html = Invoke-WebRequest -Uri $Url;
if (-not ($html.Content -match $VersionPattern)) {
    return @{
        HasNewVersion = $false
        Message       = "Can't extract the version from $Url"
    }
}

$newVersion = $Matches[$VersionPatternName]
$HasNewVersion = & "$PSScriptRoot\_Version-Compare.ps1" -CurrentVersion $CurrentVersion -NewVersion $newVersion;
if (!$HasNewVersion) {
    Write-Host "No new version found. Current version ($CurrentVersion) is up to date.";
    return @{
        HasNewVersion = $false
        LatestVersion = $newVersion
    }
}

return @{
    HasNewVersion = $true
    LatestVersion = $newVersion
    Message       = $CheckOnly ? $null : "The Website downloader can only detect versions, download $newVersion manually from $Url"
}
