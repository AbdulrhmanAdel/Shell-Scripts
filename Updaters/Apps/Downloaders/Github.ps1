[CmdletBinding()]
param (
    $Repo,
    $RepoOwner,
    $RepoName,
    [Alias("VersionPattern")]
    $VersionExtractPattern = "v",
    [ValidateSet("name", "tag_name", "body")]
    $VersionSearchLocation = "tag_name",
    [Alias("ReleasePattern")]
    $ReleaseAssetSearchPattern = ".*\.zip$",
    # Pick the newest release whose name matches instead of GitHub's "latest" flag, which some
    # projects set on older builds (e.g. Brave: '^Release v' = stable channel only)
    [string]
    $ReleaseNamePattern,
    $CurrentVersion,
    [switch]
    $CheckOnly
)

if ($Repo -and $Repo -ne "") {
    $Repo = $Repo -replace "https://github.com/", "";
    $RepoOwner, $RepoName = $Repo -split "/";
}

function Get-ReleaseVersion {
    param ($Release)

    $version = $Release.$VersionSearchLocation;
    foreach ($pattern in @($VersionExtractPattern)) {
        $version = $version -replace $pattern, '';
    }
    return "$version".Trim();
}

Write-Host "INFO: " -ForegroundColor Blue -NoNewline; Write-Host "Using Github Downloader";
$headers = @{
    "Accept"               = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
};
# Without a token GitHub allows 60 requests an hour
if ($env:GITHUB_TOKEN) {
    $headers.Authorization = "Bearer $env:GITHUB_TOKEN";
}

$baseUrl = "https://api.github.com/repos/$RepoOwner/$RepoName/releases";
try {
    if ($ReleaseNamePattern) {
        $release = Invoke-RestMethod -Uri "$($baseUrl)?per_page=50" -Headers $headers -ErrorAction Stop |
            ForEach-Object { $_ } |
            Where-Object { $_.name -match $ReleaseNamePattern -and ($_.assets.name -match $ReleaseAssetSearchPattern) } |
            Sort-Object { $v = Get-ReleaseVersion $_; ($v -match '\d+(\.\d+){1,3}') ? [version]$Matches[0] : [version]'0.0' } -Descending |
            Select-Object -First 1;
    }
    else {
        $release = Invoke-RestMethod -Uri "$baseUrl/latest" -Headers $headers -ErrorAction Stop;
    }
}
catch {
    return @{
        HasNewVersion = $false
        Message       = "GitHub request failed for $RepoOwner/$RepoName`: $($_.Exception.Message)"
    }
}

if (!$release) {
    return @{
        HasNewVersion = $false
        Message       = "No release of $RepoOwner/$RepoName matches '$ReleaseNamePattern' with an asset matching '$ReleaseAssetSearchPattern'."
    }
}

$releaseVersion = Get-ReleaseVersion $release;
Write-Host "Latest Release Version: $releaseVersion";
$HasNewVersion = & "$PSScriptRoot\_Version-Compare.ps1" -CurrentVersion $CurrentVersion -NewVersion $releaseVersion;
if (!$HasNewVersion) {
    Write-Host "No new version found. Current version ($CurrentVersion); Latest Version $releaseVersion";
    return @{
        HasNewVersion = $false
        LatestVersion = $releaseVersion
    }
}

$releaseAsset = $release.assets | Where-Object { $_.name -match $ReleaseAssetSearchPattern } | Select-Object -First 1;
if (!$releaseAsset) {
    return @{
        HasNewVersion = $true
        LatestVersion = $releaseVersion
        Message       = "No asset matches '$ReleaseAssetSearchPattern'. Assets: $($release.assets.name -join ', ')"
    }
}

if ($CheckOnly) {
    return @{
        HasNewVersion = $true
        LatestVersion = $releaseVersion
    }
}

$downloadPath = & "$PSScriptRoot\_Downloader.ps1" `
    -Url $releaseAsset.browser_download_url `
    -FileName $releaseAsset.name `
    -Version $releaseVersion `
    -ExpectedSize $releaseAsset.size;
return @{
    HasNewVersion = $true
    LatestVersion = $releaseVersion
    DownloadPath  = $downloadPath
}
