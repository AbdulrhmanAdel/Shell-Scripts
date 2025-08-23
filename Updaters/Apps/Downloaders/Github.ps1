[CmdletBinding()]
param (
    $RepoOwner,
    $RepoName,
    [Alias("VersionPattern")]
    $VersionExtractPattern = "v",
    [Alias("ReleasePattern")]
    $ReleaseAssetSearchPattern = ".*\.zip$",
    $CurrentVersion
)

$releaseResponse = curl -L `
    -H "Accept: application/vnd.github+json" `
    -H "X-GitHub-Api-Version: 2022-11-28" `
    "https://api.github.com/repos/$RepoOwner/$RepoName/releases/latest";

$latestReleasesData = $releaseResponse | ConvertFrom-Json;
$releaseVersion = $latestReleasesData.tag_name -replace $VersionExtractPattern, '';
$releaseAsset = $latestReleasesData.assets | Where-Object { $_.name -match $releaseAssetSearchPattern } | Select-Object -First 1;

$HasNewVersion = & "$PSScriptRoot\_Version-Compare.ps1" -CurrentVersion $CurrentVersion -NewVersion $releaseVersion;
if (!$HasNewVersion) {
    Write-Host "No new version found. Current version ($CurrentVersion) is up to date.";
    return @{
        HasNewVersion = $false
        DownloadPath  = $null
    }
}
$downloadPath = & "$PSScriptRoot\_DOwnloader.ps1" -Url $releaseAsset.browser_download_url -FileName $releaseAsset.name;
return @{
    HasNewVersion = $HasNewVersion
    DownloadPath  = $downloadPath
}
