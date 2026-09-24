[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$Project,
    # Matched against the file path, e.g. "/Windows_Portable/hwi_834.zip"
    [Parameter(Mandatory)]
    [string]$ReleasePattern,
    # Regex on the file path with a "Version" group, or Major/Minor/Patch/Build groups that get
    # joined with dots (hwi_834.zip: 'hwi_(?<Major>\d)(?<Minor>\d+)\.zip' -> 8.34).
    # Without it every run counts as new.
    [string]$VersionPattern,
    $CurrentVersion,
    [switch]
    $CheckOnly
)

function Get-FileVersion {
    param ([string]$FilePath)

    if (!$VersionPattern -or $FilePath -notmatch $VersionPattern) {
        return $null;
    }
    if ($Matches.Version) {
        return $Matches.Version;
    }
    $parts = @('Major', 'Minor', 'Patch', 'Build') | Where-Object { $Matches.$_ } | ForEach-Object { $Matches.$_ };
    return $parts ? ($parts -join '.') : $null;
}

Write-Host "INFO: " -ForegroundColor Blue -NoNewline; Write-Host "Using SourceForge Downloader";
try {
    $data = Invoke-WebRequest -Uri "https://sourceforge.net/projects/$Project/rss?limit=100" -UseBasicParsing -ErrorAction Stop;
}
catch {
    return @{
        HasNewVersion = $false
        Message       = "SourceForge request failed for $Project`: $($_.Exception.Message)"
    }
}

$files = @(([xml]$data.Content).rss.channel.item |
        ForEach-Object { $_.title.InnerText } |
        Where-Object { $_ -match $ReleasePattern } |
        ForEach-Object { [pscustomobject]@{ Path = $_; Version = Get-FileVersion $_ } });
if (!$files) {
    return @{
        HasNewVersion = $false
        Message       = "No file matches '$ReleasePattern' in SourceForge project '$Project'."
    }
}

# Newest version when versions are known, otherwise the newest upload (the feed is newest first)
$latest = $VersionPattern `
    ? ($files | Where-Object Version | Sort-Object { [version]$_.Version } -Descending | Select-Object -First 1) `
    : $files[0];
Write-Host "Latest Release: $($latest.Path)";

$HasNewVersion = & "$PSScriptRoot\_Version-Compare.ps1" -CurrentVersion $CurrentVersion -NewVersion $latest.Version;
if (!$HasNewVersion) {
    Write-Host "No new version found. Current version ($CurrentVersion); Latest Version $($latest.Version)";
    return @{
        HasNewVersion = $false
        LatestVersion = $latest.Version
    }
}

if ($CheckOnly) {
    return @{
        HasNewVersion = $true
        LatestVersion = $latest.Version
    }
}

# downloads.sourceforge.net picks a working mirror; a non-browser agent gets the file instead of the HTML page
$downloadPath = & "$PSScriptRoot\_Downloader.ps1" `
    -Url "https://downloads.sourceforge.net/project/$Project$($latest.Path)" `
    -FileName (Split-Path $latest.Path -Leaf) `
    -Version $latest.Version `
    -UserAgent "Wget/1.21";

return @{
    HasNewVersion = $true
    LatestVersion = $latest.Version
    DownloadPath  = $downloadPath
}
