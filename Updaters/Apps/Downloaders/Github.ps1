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

# The latest release read from the github.com pages, which have no hourly limit. Only the tag and the
# asset names and links: no release name, body or asset sizes.
function Get-LatestReleaseFromPage {
    try {
        $page = Invoke-WebRequest -Uri "https://github.com/$RepoOwner/$RepoName/releases/latest" -UseBasicParsing -ErrorAction Stop;
        # Redirects to .../releases/tag/<tag>, or to .../releases when there is none
        $tag = "$($page.BaseResponse.RequestMessage.RequestUri.AbsolutePath)" -replace '^.*/releases/tag/', '';
        if (!$tag -or $tag -match '/releases/?$') {
            return $null;
        }
        $assetsPage = (Invoke-WebRequest -Uri "https://github.com/$RepoOwner/$RepoName/releases/expanded_assets/$tag" -UseBasicParsing -ErrorAction Stop).Content;
        $assets = @([regex]::Matches($assetsPage, 'href="(/[^"]+/releases/download/[^"]+)"') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique | ForEach-Object {
                [pscustomobject]@{ name = [uri]::UnescapeDataString(($_ -split '/')[-1]); browser_download_url = "https://github.com$_"; size = 0 }
            });
        return [pscustomobject]@{ tag_name = [uri]::UnescapeDataString($tag); name = $null; body = $null; assets = $assets };
    }
    catch {
        return $null;
    }
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
    $apiError = $_.Exception.Message;
    # Usually the hourly limit (60 without a token). The pages only show the latest release, so not
    # with ReleaseNamePattern or a version read from the release name/body.
    if (!$ReleaseNamePattern -and $VersionSearchLocation -eq 'tag_name') {
        $release = Get-LatestReleaseFromPage;
    }
    if (!$release) {
        return @{
            HasNewVersion = $false
            Message       = "GitHub request failed for $RepoOwner/$RepoName`: $apiError"
        }
    }
    Write-Host "[INFO] GitHub API failed ($apiError), read the release from github.com instead." -ForegroundColor DarkGray;
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
