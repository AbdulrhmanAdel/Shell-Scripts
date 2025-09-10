[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    $Url,
    $VersionPattern = "v",
    $VersionPatternName = "Version",
    $CurrentVersion
)

$html = Invoke-WebRequest -Uri $Url;
if (-not ($html.Content -match $VersionPattern)) {
    return @{
        Success = $false
        Message = "Can't Extract the version from the provide URL"
    }
}

$newVersion = $Matches[$VersionPatternName]
$HasNewVersion = & "$PSScriptRoot\_Version-Compare.ps1" -CurrentVersion $CurrentVersion -NewVersion $newVersion;
if (!$HasNewVersion) {
    Write-Host "No new version found. Current version ($CurrentVersion) is up to date.";
    return @{
        HasNewVersion = $false
        DownloadPath  = $null
    }
}


