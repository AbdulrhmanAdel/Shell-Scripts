[CmdletBinding()]
param (
    $CurrentVersion,
    [string]
    $Url,
    [object]
    $FileName
)

$HasNewVersion = & "$PSScriptRoot\_Version-Compare.ps1" -CurrentVersion $CurrentVersion -NewVersion $releaseVersion;
if (!$HasNewVersion) {
    Write-Host "No new version found. Current version ($CurrentVersion) is up to date.";
    return @{
        HasNewVersion = $false
        DownloadPath  = $null
    }
}

$downloadPath = & "$PSScriptRoot\_DOwnloader.ps1" -Url $Url  -FileName $FileName;

return @{
    HasNewVersion = $HasNewVersion
    DownloadPath  = $downloadPath
}
