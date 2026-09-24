[CmdletBinding()]
param (
    $CurrentVersion,
    [string]
    $Url,
    [object]
    $FileName,
    # The version behind $Url, when the caller knows it. Without it every run counts as new.
    [string]
    $Version,
    [switch]
    $CheckOnly
)

$HasNewVersion = & "$PSScriptRoot\_Version-Compare.ps1" -CurrentVersion $CurrentVersion -NewVersion $Version;
if (!$HasNewVersion) {
    Write-Host "No new version found. Current version ($CurrentVersion) is up to date.";
    return @{
        HasNewVersion = $false
        LatestVersion = $Version
    }
}

if ($CheckOnly) {
    return @{
        HasNewVersion = $true
        LatestVersion = $Version
    }
}

$downloadPath = & "$PSScriptRoot\_Downloader.ps1" -Url $Url -FileName $FileName -Version $Version;

return @{
    HasNewVersion = $HasNewVersion
    LatestVersion = $Version
    DownloadPath  = $downloadPath
}
