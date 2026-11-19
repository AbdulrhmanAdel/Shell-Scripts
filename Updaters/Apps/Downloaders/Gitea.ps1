[CmdletBinding()]
param (
    # The repo's page, e.g. https://git.magicbean.dev/MagicBeanDev/Longshot (a /releases link works too)
    $Repo,
    # Or the parts, for a server other than the one in $Repo
    $Server,
    $RepoOwner,
    $RepoName,
    # Removed from the tag (or name/body) to get the version, e.g. '^nightly-' for "nightly-170-6c9edffe"
    [Alias("VersionPattern")]
    $VersionExtractPattern = "^v",
    [ValidateSet("name", "tag_name", "body")]
    $VersionSearchLocation = "tag_name",
    [Alias("ReleasePattern")]
    $ReleaseAssetSearchPattern = ".*\.zip$",
    # Only releases whose name matches, e.g. one channel of several
    [string]
    $ReleaseNamePattern,
    # Also take pre-releases. Gitea's "latest" skips them, which is every release of a nightly-only project.
    [switch]
    $Prerelease,
    $CurrentVersion,
    [switch]
    $CheckOnly
)

# Works for any Gitea or Forgejo server (Codeberg too), their API is the same
if ($Repo) {
    $uri = [uri]($Repo -replace '/releases.*$', '').TrimEnd('/');
    $Server = "$($uri.Scheme)://$($uri.Authority)";
    $RepoOwner, $RepoName = $uri.AbsolutePath.Trim('/') -split '/', 2;
}
$Server = "$Server".TrimEnd('/');

function Get-ReleaseVersion {
    param ($Release)

    $version = $Release.$VersionSearchLocation;
    foreach ($pattern in @($VersionExtractPattern)) {
        $version = $version -replace $pattern, '';
    }
    return "$version".Trim();
}

Write-Host "INFO: " -ForegroundColor Blue -NoNewline; Write-Host "Using Gitea Downloader ($Server)";
$headers = @{ "Accept" = "application/json" };
# Only for private repos or a server that limits anonymous requests
if ($env:GITEA_TOKEN) {
    $headers.Authorization = "token $env:GITEA_TOKEN";
}

$baseUrl = "$Server/api/v1/repos/$RepoOwner/$RepoName/releases";
try {
    # Newest first. Drafts are only listed for the repo's writers, skip them anyway.
    $release = Invoke-RestMethod -Uri "$($baseUrl)?limit=50&draft=false$($Prerelease ? '' : '&pre-release=false')" -Headers $headers -ErrorAction Stop |
        ForEach-Object { $_ } |
        Where-Object {
            !$_.draft -and
            ($Prerelease -or !$_.prerelease) -and
            (!$ReleaseNamePattern -or $_.name -match $ReleaseNamePattern) -and
            ($_.assets.name -match $ReleaseAssetSearchPattern)
        } |
        Select-Object -First 1;
}
catch {
    return @{
        HasNewVersion = $false
        Message       = "Gitea request failed for $Server/$RepoOwner/$RepoName`: $($_.Exception.Message)"
    }
}

if (!$release) {
    return @{
        HasNewVersion = $false
        Message       = "No $($Prerelease ? '' : 'stable ')release of $RepoOwner/$RepoName$($ReleaseNamePattern ? " matches '$ReleaseNamePattern'" : '') with an asset matching '$ReleaseAssetSearchPattern'."
    }
}

$releaseVersion = Get-ReleaseVersion $release;
Write-Host "Latest Release Version: $releaseVersion";
$HasNewVersion = & "$PSScriptRoot/_Version-Compare.ps1" -CurrentVersion $CurrentVersion -NewVersion $releaseVersion;
if (!$HasNewVersion) {
    Write-Host "No new version found. Current version ($CurrentVersion); Latest Version $releaseVersion";
    return @{
        HasNewVersion = $false
        LatestVersion = $releaseVersion
    }
}

$releaseAsset = $release.assets | Where-Object { $_.name -match $ReleaseAssetSearchPattern } | Select-Object -First 1;

if ($CheckOnly) {
    return @{
        HasNewVersion = $true
        LatestVersion = $releaseVersion
    }
}

$downloadPath = & "$PSScriptRoot/_Downloader.ps1" `
    -Url $releaseAsset.browser_download_url `
    -FileName $releaseAsset.name `
    -Version $releaseVersion `
    -ExpectedSize $releaseAsset.size;
return @{
    HasNewVersion = $true
    LatestVersion = $releaseVersion
    DownloadPath  = $downloadPath
}
